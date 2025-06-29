Shader "ShaderGrimoire/CRT 2D/Custom Vert"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Slider("UV Slider", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "PreviewType" = "Skybox"
        }

        Blend One Zero
        Lighting Off
        ZTest Always
        ZWrite Off

        Pass
        {
            Name "CRT Custom Vertex"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "CRTStandard2D.cginc"
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half _Slider;

            struct v2f
            {
                // Includes vertex and crt_uv
                CRT_V2F_ARGS
                float2 back_uv : TEXCOORD1;
            };

            v2f vert(CRT_INPUT_ARGS)
            {
                v2f o;
                // Initializes everything under CRT_V2F_ARGS
                CRT_INITIALIZE_OUTPUT(o);

                o.back_uv = TRANSFORM_TEX(o.crt_uv, _MainTex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 main_uv = i.crt_uv.xy;
                float2 back_uv = i.back_uv;
                return tex2D(_MainTex, lerp(main_uv, back_uv, _Slider));
            }

            ENDCG
        }
    }
}
