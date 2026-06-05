Shader "OwenTheProgrammer/CRT Example (V2)"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "PreviewType"="Skybox"
        }

        Blend One Zero
        Lighting Off
        ZTest Off
        ZWrite Off

        Pass
        {
            Name "CRT Test"
            CGPROGRAM
            #pragma target 5.0
            #pragma vertex crt_vert
            #pragma fragment frag
            #include "CRTStandard2Dv2.cginc"

            float4 frag(crt_v2f i) : SV_Target
            {
                float2 uv01 = i.crt_uv.xy; // 0 to 1
                float2 uvNorm = i.crt_uv.zw; // -1 to 1
                return float4(uv01, 0, 1);
            }

            ENDCG
        }
    }
}