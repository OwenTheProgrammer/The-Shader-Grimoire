Shader "ShaderGrimoire/CRT 2D/Wave Effect"
{
    Properties
    {
        _Frequency("Band Frequency", Vector) = (0.8, 1.0, 1.3, 0.0)
        _Offset("Band Phase", Vector) = (0, 1, 2, 0)
        _Width("Band Width", Vector) = (0.2, 0.2, 0.2, 0)
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
            Name "CRT Wave Effect"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "CRTStandard2D.cginc"

            float4 _Frequency;
            float4 _Offset;
            float4 _Width;

            crt_v2f vert(CRT_INPUT_ARGS)
            {
                crt_v2f o;
                float4 coords = _CRT_COMPUTE_VT(vid);
                o.vertex = _CRT_VT_VPOS(coords);
                o.crt_uv = _CRT_VT_UV_NORM(coords);
                o.crt_uv.zw *= CRT_RESOLUTION;

                return o;
            }

            // Slightly modified version of: https://www.shadertoy.com/view/3fySDD
            float4 frag(crt_v2f i) : SV_Target
            {
                // UV coordinates
                float2 uv = i.crt_uv.xy;
                // Pixel coordinates
                float2 pixel = i.crt_uv.zw;

                float noise = dot(pixel, sin(pixel.yx));
                noise = frac(noise * 10) * 0.1; //fmod(noise, 0.1);

                float3 t = _Time.y + noise + uv.x * _Frequency + _Offset;
                float3 color = tanh( _Width / (0.01 + abs(uv.y + 0.2 * cos(t))) );

                // sRGB to Linear
                color = pow(color, 2.2);
                return float4(color, 1);
            }

            ENDCG
        }
    }
}
