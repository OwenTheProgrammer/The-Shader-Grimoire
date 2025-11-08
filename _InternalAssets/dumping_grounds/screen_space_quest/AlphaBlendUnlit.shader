Shader "OwenTheProgrammer/SSQuest/AlphaBlend (Unlit)" {
    Properties {
        _MainTex("Texture", 2D) = "white" {}
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Int) = 2
    }
    CGINCLUDE
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

    fixed4 frag(v2f i) {
        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

        float4 color = tex2D(_MainTex, i.uv);
        return float4(color.rgb, i.uv.x);
    }
    ENDCG

    SubShader {
        Tags {
            "RenderType"="Transparent"
            "Queue"="Transparent+20"
            "ForceNoShadowCasting"="True"
        }
        Pass {
            Blend SrcAlpha OneMinusSrcAlpha
            Name "AlphaBlend Unlit/PC"
            Cull [_Cull]

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_pc
            #pragma multi_compile_instancing
            #pragma exclude_renderers framebufferfetch

            fixed4 frag_pc(v2f i) : SV_TARGET {
                return frag(i);
            }
            ENDCG
        }
    }
    SubShader {
        Tags {
            "RenderType"="Transparent"
            "Queue"="Transparent+20"
            "ForceNoShadowCasting"="True"
        }
        Pass {
            Name "AlphaBlend Unlit/Quest"
            Cull [_Cull]

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_quest
            #pragma multi_compile_instancing
            #pragma only_renderers framebufferfetch

            void frag_quest(v2f i, inout half4 fragColor : SV_Target) {
                float4 shader = frag(i);
                fragColor.rgb = lerp(fragColor.rgb, shader.rgb, shader.a);
                #if UNITY_REVERSED_Z
                    float depth = i.vertex.z;
                #else //UNITY_REVERSED_Z
                    float depth = 1 - i.vertex.z;
                #endif //UNITY_REVERSED_Z
                fragColor.a = i.vertex.z;
            }
            ENDCG
        }
    }
}