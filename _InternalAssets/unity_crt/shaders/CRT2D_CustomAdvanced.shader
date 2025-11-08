Shader "ShaderGrimoire/CRT 2D/Custom Vert (Advanced)"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
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
            Name "CRT Custom Vertex (Advanced)"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "CRTStandard2D.cginc"
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            float4 _MainTex_ST;

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 deriv : TEXCOORD1;

            };

            v2f vert(CRT_INPUT_ARGS)
            {
                v2f o;

                crt_v2f _init = _CRT_INIT_INTERNAL(vid);

                o.vertex = _init.vertex;
                o.uv = _init.crt_uv.xy;
                o.deriv = _init.crt_uv.zw / (_MainTex_ST.xy * _MainTex_TexelSize.zw);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 uv = floor(i.uv * _MainTex_ST.xy) / _MainTex_ST.xy;
                return tex2D(_MainTex, uv, ddx(i.deriv), ddy(i.deriv));
            }

            ENDCG
        }
    }
}
