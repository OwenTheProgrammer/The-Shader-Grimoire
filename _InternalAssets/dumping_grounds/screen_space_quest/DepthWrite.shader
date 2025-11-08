Shader "OwenTheProgrammer/SSQuest/DepthWriter (Unlit)" {
    Properties {
        _MainTex("Texture", 2D) = "white" {}
    }
    SubShader {
        Tags {
            "RenderType"="Opaque"
        }
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma only_renderers framebufferfetch
            #include "UnityCG.cginc"

            struct inputData {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert(inputData i) {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(i, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(i.vertex);
                o.uv = TRANSFORM_TEX(i.uv, _MainTex);
                return o;
            }

            void frag(v2f i, inout half4 fragColor : SV_Target) {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float3 color = tex2D(_MainTex, i.uv);

                // #if UNITY_REVERSED_Z
                //     float depth = i.vertex.z;
                // #else //UNITY_REVERSED_Z
                //     float depth = 1 - i.vertex.z;
                // #endif //UNITY_REVERSED_Z

                fragColor = half4(color, i.vertex.z);
            }
            ENDCG
        }
    }
}