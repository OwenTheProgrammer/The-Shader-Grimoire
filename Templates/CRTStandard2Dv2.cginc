#ifndef CRTSTANDARD2D_INCLUDED
#define CRTSTANDARD2D_INCLUDED

uniform float4 _CustomRenderTextureInfo;

#define CRT_WIDTH       _CustomRenderTextureInfo.x
#define CRT_HEIGHT      _CustomRenderTextureInfo.y
#define CRT_RESOLUTION  _CustomRenderTextureInfo.xy

#define CRT_VID         vertexID
#define CRT_INPUT_ARGS  uint CRT_VID : SV_VertexID
#define CRT_V2F_ARGS    float4 vertex : SV_POSITION; float4 crt_uv : TEXCOORD0;

struct crt_v2f { CRT_V2F_ARGS };

crt_v2f crt_vert(CRT_INPUT_ARGS)
{
    crt_v2f o;

    uint2 vd = (uint2(38, 44) >> CRT_VID) & 1u;

#if UNITY_UV_STARTS_AT_TOP
    // DirectX style
    o.vertex = (vd.xyxx != 0) ? float4(-1, -1,  0, 1) : float4( 1, 1, 0,  1);
    o.crt_uv = (vd.xyxy != 0) ? float4( 0,  1, -1, 1) : float4( 1, 0, 1, -1);
#else
    // OpenGL style
    o.vertex = (vd.xyxx != 0) ? float4( 1, -1, 0,  1) : float4(-1, 1,  0, 1);
    o.crt_uv = (vd.xyxy != 0) ? float4( 1,  0, 1, -1) : float4( 0, 1, -1, 1);
#endif //UNITY_UV_STARTS_AT_TOP

    return o;
}

#endif //CRTSTANDARD2D_INCLUDED