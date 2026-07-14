Shader "OwenTheProgrammer/ReconstructionMethods"
{
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "Queue"="Transparent+80"
        }

        Cull Front
        ZWrite Off
        ZTest Always
        //ZClip False

        Pass
        {
            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
            // #pragma enable_d3d11_debug_symbols
            #include "UnityCG.cginc"

            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
            float4 _CameraDepthTexture_TexelSize;

            struct inputSig
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 screenPos : TEXCOORD0;
                float3 ws_viewRay : NORMAL;

                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(inputSig i)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float4 ws_camPos = float4(_WorldSpaceCameraPos, 1);
                float4 os_camPos = mul(unity_WorldToObject, ws_camPos);
                float3 ws_vpos = mul(unity_ObjectToWorld, i.vertex);

                o.vertex = UnityObjectToClipPos(i.vertex);
                o.screenPos = ComputeScreenPos(o.vertex).xy;
                o.ws_viewRay = ws_vpos - ws_camPos.xyz;

                return o;
            }

            float LinearEyeDepthVR(float2 screenPos, float z)
            {
                // Compute Normalized Device Coordinates (NDC)
                // We're using `unity_CameraInvProjection` which is
                // the inverse of unity_CameraProjection, not glstate_matrix_projection / UNITY_MATRIX_P.
                // `unity_CameraInvProjection` is OpenGL style, and only the main rendering camera.
                // This means we want to convert our `screenPos` and `z` values to OpenGL NDC space
                // which is (-1,-1,-1) to (+1,+1,+1)

                // screenPos [0 | 1] to [-1 | 1]
                screenPos = screenPos * 2 - 1;

            #ifdef UNITY_REVERSED_Z
                z = 1 - 2 * z;
            #else
                z = z * 2 - 1;
            #endif //UNITY_REVERSED_Z

                // NDC -> MV
                float4 clip = mul(unity_CameraInvProjection, float4(screenPos, z, 1));
                // Apply perspective division to the homogeneous system
                return -clip.z / clip.w;
            }

            // Cross product of partial derivatives method
            float3 method1(float2 uv, float3 viewRay)
            {
                // Technically you could compute this as
                // float4 clip = mul(INVERSE_VP, float4(screenPos, z, 1));
                // float3 ws_scenePos = clip.xyz / clip.w;
                float zDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
                float eyeDepth = LinearEyeDepthVR(uv, zDepth);
                float3 ws_scenePos = _WorldSpaceCameraPos + viewRay * eyeDepth; // MV -> M

                return normalize(-cross(ddx_fine(ws_scenePos), ddy_fine(ws_scenePos)));
            }

            // Ordinary Least Squares in view space method
            float3 method2(float2 uv)
            {
                float2 ts = _CameraDepthTexture_TexelSize.xy;
                #define T(x,y) SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv + ts * float2(x,y))
                float3x3 k = float3x3(
                    T(-1, +1), T( 0, +1), T(+1, +1),
                    T(-1,  0), T( 0,  0), T(+1,  0),
                    T(-1, -1), T( 0, -1), T(+1, -1)
                );
                #undef T

                float3 nx = float3(
                    k._m00 - k._m02,
                    k._m10 - k._m12,
                    k._m20 - k._m22
                );
                float3 nz = float3(
                    k._m00 + k._m01 + k._m02,
                    k._m10 + k._m11 + k._m12,
                    k._m20 + k._m21 + k._m22
                );

                float3 normal = float3(
                    nx.x + nx.y + nx.z,
                   -nz.x        + nz.z,
                    nz.x + nz.y + nz.z
                );
                normal.xy *= _CameraDepthTexture_TexelSize.zw;
                return mul((float3x3)UNITY_MATRIX_I_V, normalize(normal));
            }

            float3 method3(float2 screenPos)
            {
                float2 ts = 1 / _ScreenParams.xy;
                float2 ndxy = float2(2, 2*_ProjectionParams.x) * ts;
                float dx = ndxy.x, dy = ndxy.y;

                float z1 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos + float2(-1,-1) * ts);
                float z2 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos + float2( 0,-1) * ts);
                float z3 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos + float2(+1,-1) * ts);
                float z4 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos + float2(-1, 0) * ts);
                float z5 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos + float2( 0, 0) * ts);
                float z6 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos + float2(+1, 0) * ts);
                float z7 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos + float2(-1,+1) * ts);
                float z8 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos + float2( 0,+1) * ts);
                float z9 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos + float2(+1,+1) * ts);

                float nrm_a = (-z1+z3-z4+z6-z7+z9) / (6.0 * dx);
                float nrm_b = (-z1-z2-z3+z7+z8+z9) / (6.0 * dy);

                float3 nrm = normalize(float3(-nrm_a, -nrm_b, 1));

                float x0 = screenPos.x * 2 - 1;
                float y0 = (screenPos.y * 2 - 1) * _ProjectionParams.x;
                float D = -(nrm.x * x0 + nrm.y * y0 + nrm.z * z5);

                float4 lNDC = float4(nrm, D);
                float4 wsL = mul(transpose(UNITY_MATRIX_VP), lNDC);
                return normalize(wsL.xyz);
            }

            float3 method4(float2 screenPos)
            {
                float2 ts = 1 / _ScreenParams.xy;
                float2 ndxy = float2(2, 2*_ProjectionParams.x) * ts;
                float dx = ndxy.x, dy = ndxy.y;

                float z1 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos + float2(-1,-1) * ts);
                float z2 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos + float2( 0,-1) * ts);
                float z3 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos + float2(+1,-1) * ts);
                float z4 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos + float2(-1, 0) * ts);
                float z5 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos + float2( 0, 0) * ts);
                float z6 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos + float2(+1, 0) * ts);
                float z7 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos + float2(-1,+1) * ts);
                float z8 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos + float2( 0,+1) * ts);
                float z9 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos + float2(+1,+1) * ts);

                float rad = 0.0009;
                float sigma = 1 / (rad*rad);

                #define expw(n) float w##n = max(exp2(-pow(z##n - z5, 2) * sigma), 1e-6)
                expw(1); expw(2); expw(3);
                expw(4);          expw(6);
                expw(7); expw(8); expw(9);
                #undef expw

                float Mxx = dx * dx * (w1+w3+w4+w6+w7+w9);
                float Myy = dy * dy * (w1+w2+w3+w7+w8+w9);
                float Mxy = dx * dy * (w1-w3-w7+w9);

                float Bx = -dx * (w1*z1 - w3*z3 + w4*z4 - w6*z6 + w7*z7 - w9*z9 + z5 * (-w1+w3-w4+w6-w7+w9));
                float By = -dy * (w1*z1 + w2*z2 + w3*z3 - w7*z7 - w8*z8 - w9*z9 + z5 * (-w1-w2-w3+w7+w8+w9));

                float IdetM = 1 / (Mxx * Myy - Mxy * Mxy);
                float nrm_a = (Myy * Bx - Mxy * By) * IdetM;
                float nrm_b = (Mxx * By - Mxy * Bx) * IdetM;

                float3 nrm = normalize(float3(-nrm_a, -nrm_b, 1));

                float x0 = screenPos.x * 2 - 1;
                float y0 = (screenPos.y * 2 - 1) * _ProjectionParams.x;
                float D = -(nrm.x * x0 + nrm.y * y0 + nrm.z * z5);

                float4 lNDC = float4(nrm, D);
                float4 wsL = mul(transpose(UNITY_MATRIX_VP), lNDC);
                return normalize(wsL.xyz);
            }


            float3 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float2 screenPos = i.screenPos.xy / i.vertex.w;

                // i.vertex.w = distance from camera to fragment in viewspace
                // since i.ws_viewRay is computed as vertex (worldspace) - camera position (worldspace)
                // the distance to fragment should be the length of i.ws_viewRay, so we can simply
                // divide by i.vertex.w here.

                // normalize(i.ws_viewRay) = i.ws_viewRay / i.vertex.w
                float3 ws_viewRay = i.ws_viewRay / i.vertex.w;

                // return method1(screenPos, ws_viewRay);
                // return method2(screenPos);
                // return method3(screenPos);
                return method4(screenPos);
            }

            ENDCG
        }
    }
}