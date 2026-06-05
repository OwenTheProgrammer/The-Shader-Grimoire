Shader "OwenTheProgrammer/Templates/Raymarch 2D (Cube)"
{
    Properties
    {
        // There are other options, other than "white"!
        // https://github.com/cnlohr/shadertrixx?tab=readme-ov-file#default-texture-parameters
        _MainTex("2D Texture", 2D) = "black" {}
        _Color("Color", Color) = (1,1,1,1)

        [IntRange] _RayStep("Ray Steps", Range(0, 128)) = 64

        [Toggle(USE_CAMERA_DEPTH)] _UseCameraDepth("Use Camera Depth", Float) = 1

        [Header(Blend Operations)][Space(5)]
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc("Blend Source", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendDst("Blend Destination", Float) = 10
        [Enum(UnityEngine.Rendering.CompareFunction)] _DepthTestMode("Depth Test Mode", Float) = 10
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "Queue"="Transparent+40"

            // This object is transparent and volumetric.
            // Without doing heavy *heavy* light radiocity,
            // there's no way to tell unity how shadows should be "cast"
            // so we disable the feature entirely.
            "ForceNoShadowCasting"="True"

            // Unity may take a bunch of our simple cube meshes
            // and combine them to reduce the geometry count.
            // We want each cube to have its own object/local coordinates
            // which requires dynamic batching to be disabled.
            "DisableBatching"="True"

            // Projectors are not compatible with semi-transparent objects,
            // so we choose to ignore them for this shader. Feel free to
            // comment this line out if it doesn't suit your needs.
            "IgnoreProjector"="True"

            // This changes the way unity displays the material preview in
            // the editor/inspector panel. Skybox gives you a cube
            "PreviewType"="Skybox"
        }

        // We want to view the inside faces of the mesh at all times
        // to make the mesh visible when you're both inside and outside the mesh.
        // https://docs.unity3d.com/2022.3/Documentation/Manual/SL-Cull.html
        Cull Front

        // We are rendering a transparent effect, and volumetrics doesnt have an
        // inherent "depth" to write anyway, so we disable writing to the depth buffer.
        // https://docs.unity3d.com/2022.3/Documentation/Manual/SL-ZWrite.html
        ZWrite Off

        // We dont want to clip/cull parts of the mesh if they are slightly outside our
        // cameras near-far plane viewing frustum. Disabling ZClip clamps the vertex
        // depth to be within the near and far planes of the camera when it falls outside;
        // very useful for skybox-like and avatar-like effects.
        // https://docs.unity3d.com/2022.3/Documentation/Manual/SL-ZClip.html
        ZClip False

        // We want to render parts of the mesh that are LESS far than
        // objects currently rendered to the screen; i.e. we only
        // want to render parts of the cube that sit closer to the camera
        // and in front of previously rendered objects.
        // https://docs.unity3d.com/2022.3/Documentation/Manual/SL-ZTest.html
        ZTest [_DepthTestMode]

        // https://docs.unity3d.com/2022.3/Documentation/Manual/SL-Blend.html
        Blend [_BlendSrc] [_BlendDst]

        Pass
        {
            // You can name shader passes to find them better when debugging
            Name "OwenTheProgrammer/Testing/CubeRaymarch"

            CGPROGRAM
            // SM5.0 (Shader Model 5.0) runs on anything that supports DirectX11 and above
            // Unless your hardware is older than 2009 era, your graphics card can support target 5.0
            // (Yes, even the quest supports this.)
            #pragma target 5.0

            // Tell the unity shader compiler what the vertex functions name is
            // Which in 99% of cases will be "vert" which you'll find below
            #pragma vertex vert
            // Tell the unity shader compiler what the fragment/pixel functions name is
            // Once again, "frag" is standard practice for FRAGment shader.
            #pragma fragment frag

            // Tell unity to compile support for instancing as a potential shader variant.
            // This is what gives you the "Enable GPU Instancing" toggle on a material
            #pragma multi_compile_instancing

            #pragma shader_feature USE_CAMERA_DEPTH

            // Include unitys common shader shenanigans
            #include "UnityCG.cginc"

        #if USE_CAMERA_DEPTH
            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
        #endif //USE_CAMERA_DEPTH

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _RayStep;

            static const float RAY_STEP = _RayStep;
            static const float RAY_DX = 1.0 / RAY_STEP;

            // -W to +W size of your cube, unity default cube is +- 0.5
            #define BASE_CUBE_SIZE 0.5

            // Common practice is to call this struct "appdata" becuase
            // the vertex stage and fragment stage of a shader are technically
            // individual "shader programs" or "shader applications" to the ears of graphics
            // API developers. Unity stuck with that nomenclature, and thus people still call it
            // APPlication DATA.
            // I dont enjoy that naming scheme as it feels disjoint from its actual purpose:
            // defining the layout of your models vertex "attributes", so I name this struct
            // "inputData" since your mesh vertex is the INPUT to the vert function
            struct inputData
            {
                // We need the vertex position of course
                float4 vertex : POSITION;

                // We need this unity macro if we want instancing.
                // UNITY_VERTEX_INPUT_INSTANCE_ID includes the index of the GPU instance (for the target platform)
                // currently being rendered when you have gpu instancing enabled.
                // If your vertex function executes differently for each instance,
                // (which it 100% will your object to world matrices and such are different per instance)
                // You need to include this in your struct.
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            // v2f is short for Vertex 2 Fragment.
            // This struct holds the results of the vertex stage
            // that go forward to the fragment stage.
            struct v2f
            {
                // SV_POSITION: SV stands for System-Value
                // denoting "vertex" as the mesh vertex coordinate to the rasterizer stage.
                // https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-semantics#system-value-semantics
                float4 vertex       : SV_POSITION;
                float4 os_camPos    : TEXCOORD0;
                float3 os_vpos      : TEXCOORD1;

            #if USE_CAMERA_DEPTH
                float2 screenPos    : TEXCOORD2;
                float3 ws_rayDir    : NORMAL;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            #endif //USE_CAMERA_DEPTH

                // Carry the VR stereo eye index to the fragment stage
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float3 rayToCube(float3 camPos, float3 vpos, float isOutside)
            {
                float3 ray = camPos - vpos;
                float3 ir = rcp(abs(ray));
                //float3 parts = ir - ir * abs(camPos);
                float3 parts = (BASE_CUBE_SIZE - abs(camPos)) * ir;
                float t = min(parts.x, min(parts.y, parts.z));
                return camPos + isOutside * (t * ray);
            }

            float2 VR_ComputeScreenPos(float4 clipPos)
            {
                // -1 or 1 depending if the projection matrix is reversed
                float flip = _ProjectionParams.x;

                // Convert [-1 | +1] -> [0 | 1]
                float2 uv = clipPos.xy * float2(0.5, 0.5 * flip);

                // Handle VR scale and offset
                return TransformStereoScreenSpaceTex(uv + 0.5 * clipPos.w, clipPos.w);
            }

            // LinearEyeDepth doesnt work in VR because the _ZBufferParams dont work for VR mirrors and things
            // that dont use the typical unity projection matrix (like orthographic cameras)
            float VR_LinearEyeDepth(float2 screenPos, float depth)
            {
                // Everything starts in Normalized Device Coordinate (NDC) space
                // which is a -1 to 1 cube, making triangle culling easier in hardware.
                // NDC is the last stage in the coordinate pipeline, so we want to undo some things.

                // screenPos : [-1 | +1]
                // depth : [0 | 1]
                float4 ndc = float4(screenPos, depth, 1);

                // Convert all to [-1 | +1] depending on the graphics API

            #ifdef UNITY_REVERSED_Z
                ndc.xyz = ndc.xyz * float3(2,2,-2) + float3(-1,-1,1);
            #else
                ndc.xyz = ndx.xyz * 2 - 1;
            #endif //UNITY_REVERSED_Z

                // MVP inverse(P) gives us MV, which is world to view space
                float4 clip = mul(unity_CameraInvProjection, ndc);
                // Apply the perspective division to dehomogenize the coordinate plane
                return -clip.z / clip.w;
            }

            v2f vert(inputData i)
            {
                v2f o;

                // UNITY_SETUP_INSTANCE_ID:
                // Does internal platform setup to actually do gpu instancing when its enabled.
                // Object matrices become arrays with gpu instancing, and a bunch of other things happen here.
                UNITY_SETUP_INSTANCE_ID(i);

                // This fills the v2f struct with zeros, which I dont like because it removes
                // warnings when you havent set all parts of your v2f struct
                // UNITY_INITIALIZE_OUTPUT(v2f, o);

            #if USE_CAMERA_DEPTH
                // Copy the SV_InstanceID from the inputData to the v2f
                UNITY_TRANSFER_INSTANCE_ID(i, o);
            #endif //USE_CAMERA_DEPTH

                // Setup stereo eye index stuff for VR
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(i.vertex);

                float4 ws_camPos = float4(_WorldSpaceCameraPos.xyz, 1);
                o.os_camPos.xyz = mul(unity_WorldToObject, ws_camPos);
                o.os_camPos.w = any(abs(o.os_camPos.xyz) > BASE_CUBE_SIZE);

                o.os_vpos = i.vertex;

            #if USE_CAMERA_DEPTH
                o.screenPos = VR_ComputeScreenPos(o.vertex);
                o.ws_rayDir = mul(unity_ObjectToWorld, float4(i.vertex.xyz, 1)) - ws_camPos.xyz;
            #endif //USE_CAMERA_DEPTH

                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
            #if USE_CAMERA_DEPTH
                UNITY_SETUP_INSTANCE_ID(i);
            #endif //USE_CAMERA_DEPTH

                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                // Calculate the ray-cube intersection for a -W to +W cube
                float outside_cube = i.os_camPos.w;
                float3 ray_start = rayToCube(i.os_camPos.xyz, i.os_vpos, outside_cube);
                float3 ray_end = i.os_vpos;

            #if USE_CAMERA_DEPTH
                {
                    // Pre-compute the perspective division factor for the vertex distance
                    // i.vertex.w: The distance from the camera to the mesh vertex in viewspace
                    float iw = rcp(i.vertex.w);

                    // Perform the perspective division to get the viewport screen coordinates.
                    // i.screenPos can be computed in vertex because vertex interpolators blend over fragments
                    float2 screenPos = i.screenPos.xy * iw;

                    // Sample the camera depth texture [near | far] range
                    float raw_depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos);

                    // Linearize the depth buffer value to be in world distance values
                    float lin_depth = VR_LinearEyeDepth(screenPos, raw_depth);

                    // Check if the depth buffer has an object closer than the distance to the fragment
                    if(lin_depth < i.vertex.w)
                    {
                        // Remove the fragment distance aspect and just get the world space linear depth
                        float norm_dist = lin_depth * iw;

                        // Compute the depth buffers world space position
                        float3 worldPos = _WorldSpaceCameraPos + i.ws_rayDir * norm_dist;

                        // Transform the world space position into object space
                        ray_end = mul(unity_WorldToObject, float4(worldPos, 1));

                        // Early out if the ray exit point is outside the fog volume.
                        // not ideal but it works
                        if(any(abs(ray_end) > BASE_CUBE_SIZE))
                        {
                            return 0;
                        }
                    }
                }
            #endif //USE_CAMERA_DEPTH

                // Convert the ray from [-BASE_CUBE_SIZE | +BASE_CUBE_SIZE] -> [0 | 1]
                float3 norm_start = ray_start * (1.0/(2.0 * BASE_CUBE_SIZE)) + 0.5;
                float3 norm_end = ray_end * (1.0/(2.0 * BASE_CUBE_SIZE)) + 0.5;

                // Compute the raymarch step size for each raymarch loop
                float3 ray_dx = RAY_DX * (norm_end - norm_start);

                float4 color = 0;
                float3 ray_pos = norm_start;

                [loop]
                for(uint s = 0; s < (uint)RAY_STEP; s++)
                {
                    /* == RAYMARCH LOOP START == */
                    {
                        float2 uv = ray_pos.xz * _MainTex_ST.xy + _MainTex_ST.zw;
                        float4 texColor = tex2Dlod(_MainTex, float4(uv, 0, 0));
                        color += texColor;
                    }
                    /* == RAYMARCH LOOP END == */

                    ray_pos += ray_dx;
                }

                color *= RAY_DX;

                return color * _Color;
            }

            ENDCG
        }
    }
}