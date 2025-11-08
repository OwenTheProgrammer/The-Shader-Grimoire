Shader "OwenTheProgrammer/SSQuest/DepthViewer" {
    Properties {
    }
    CGINCLUDE
    #include "UnityCG.cginc"
    #include "SSQ.cginc"

    struct inputData {
        float4 vertex : POSITION;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct v2f {
        float4 vertex : SV_POSITION;
        float2 screenPos : TEXCOORD0;
        float3 worldRay : TEXCOORD1;
        UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
    };

    v2f vert(inputData i) {
        v2f o;

        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_INITIALIZE_OUTPUT(v2f, o);
        UNITY_TRANSFER_INSTANCE_ID(i, o);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

        o.vertex = UnityObjectToClipPos(i.vertex);
        o.screenPos = ComputeScreenPosVR(o.vertex);
        o.worldRay = mul(unity_ObjectToWorld, i.vertex) - _WorldSpaceCameraPos;

        return o;
    }
    ENDCG

    SubShader {
        Tags {
            "RenderType"="Opaque"
            "ForceNoShadowCasting"="True"
        }
        Pass {
            Name "DepthViewer PC"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_pc
            #pragma exclude_renderers framebufferfetch

            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

            fixed4 frag_pc(v2f i) : SV_Target {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float iw = 1.0 / i.vertex.w;
                float2 screenPos = i.screenPos.xy * iw;

                float3 rayDir = normalize(i.worldRay);

                float perspFactor = length(i.worldRay) * iw;
                float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos);
                return float4(rawDepth.rrr, 1);
                //float eyeDepth = LinearEyeDepthVR(screenPos, rawDepth) * perspFactor;

                // return float4(eyeDepth.rrr / 20.0, 1);
            }
            ENDCG
        }
    }
    SubShader {
        Tags {
            "RenderType"="Opaque"
            "ForceNoShadowCasting"="True"
        }
        Pass {
            Name "DepthViewer Quest"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_quest
            #pragma multi_compile_instancing
            #pragma only_renderers framebufferfetch

            void frag_quest(v2f i, inout half4 fragColor : SV_Target) {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                fragColor.rgb = fragColor.aaa;

                // float3 rayDir = normalize(i.worldRay);

                // float perspFactor = length(i.worldRay) * iw;
                // float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos);
                // float eyeDepth = LinearEyeDepthVR(screenPos, rawDepth) * perspFactor;

                // return float4(eyeDepth.rrr / 20.0, 1);
            }
            ENDCG
        }
    }
}