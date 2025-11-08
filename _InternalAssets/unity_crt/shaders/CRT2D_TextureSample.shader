Shader "ShaderGrimoire/CRT 2D/Texture Sampling"
{
    Properties
    {
        [NoScaleOffset] _MainTex("Texture", 2D) = "white" {}
        _Color("Color", Color) = (1,1,1,1)
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
            Name "CRT Texture Sampler"
            CGPROGRAM
            #pragma vertex crt_vert
            #pragma fragment frag
            #include "CRTStandard2D.cginc"

            sampler2D _MainTex;
            half4 _Color;

            fixed4 frag(crt_v2f i) : SV_Target
            {
                return tex2D(_MainTex, i.crt_uv.xy) * _Color;
            }

            ENDCG
        }
    }
}
