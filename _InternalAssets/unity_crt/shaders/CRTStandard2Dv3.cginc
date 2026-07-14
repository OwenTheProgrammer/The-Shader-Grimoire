#ifndef LATRIX_CRT2D_INCLUDED
#define LATRIX_CRT2D_INCLUDED

uniform float4 _CustomRenderTextureInfo;

#define CRT_WIDTH       _CustomRenderTextureInfo.x
#define CRT_HEIGHT      _CustomRenderTextureInfo.y
#define CRT_RESOLUTION  (_CustomRenderTextureInfo.xy)

struct crt_v2f
{
    half4 vertex : SV_POSITION;
    noperspective float4 crt_uv : TEXCOORD0;
};

crt_v2f crt_vert(uint vertexID : SV_VertexID)
{
    crt_v2f o;

    const float NaN = asfloat(-1);
    bool3 mask = vertexID > uint3(0,1,2);

#if UNITY_UV_STARTS_AT_TOP
    // DirectX/Vulkan style
    o.vertex = (mask.xyzz) ? float4(-1,-3,NaN,1) : float4(3,1,0,1);
    o.crt_uv = (mask.xyxy) ? float4(0,2,-1,3) : float4(2,0,3,-1);
#else
    // OpenGL style
    o.vertex = (mask.xyzz) ? float4(1,-3,NaN,1) : float4(-3,1,0,1);
    o.crt_uv = (mask.xyxy) ? float4(1,-1,1,-3) : float4(-1,1,-3,1);
#endif //UNITY_UV_STARTS_AT_TOP

    return o;
}

#endif //LATRIX_CRT2D_INCLUDED