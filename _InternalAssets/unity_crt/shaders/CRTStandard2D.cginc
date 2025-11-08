// A heavily stripped down version of the UnityCustomRenderTexture.cginc by OwenTheProgrammer
#ifndef CRT_STANDARD_2D_INCLUDED
#define CRT_STANDARD_2D_INCLUDED

float4 _CustomRenderTextureInfo;

#define CRT_WIDTH       _CustomRenderTextureInfo.x
#define CRT_HEIGHT      _CustomRenderTextureInfo.y
#define CRT_RESOLUTION  _CustomRenderTextureInfo.xy

#define CRT_INPUT_ARGS  uint vid : SV_VertexID
#define CRT_V2F_ARGS	float4 vertex : SV_POSITION; float4 crt_uv : TEXCOORD0;

struct crt_v2f { CRT_V2F_ARGS };

inline float4 _CRT_COMPUTE_VT(CRT_INPUT_ARGS)
{
    #if UNITY_UV_STARTS_AT_TOP
        return asfloat((127<<23) + (1<<31) * (uint4(38,44,38,19) >> vid)); // DirectX
    #else
        return asfloat((127<<23) + (1<<31) * (uint4(25,44,25,44) >> vid)); // OpenGL
    #endif
}

#define _CRT_VT_VPOS(coords) coords.xyxy * float4(1,1,0,0) + float4(0,0,0,1)
#define _CRT_VT_UV(coords) coords.zwzw * 0.5 + 0.5
#define _CRT_VT_UV_NORM(coords) coords.zwzw

inline crt_v2f _CRT_INIT_INTERNAL(CRT_INPUT_ARGS)
{
    crt_v2f o;
    float4 coords = _CRT_COMPUTE_VT(vid);
    o.vertex = _CRT_VT_VPOS(coords);
    o.crt_uv = _CRT_VT_UV(coords);
    o.crt_uv.zw *= CRT_RESOLUTION;
    return o;
}

crt_v2f crt_vert(CRT_INPUT_ARGS) { return _CRT_INIT_INTERNAL(vid); }

#define CRT_INITIALIZE_OUTPUT(o) { crt_v2f _init = crt_vert(vid); o.vertex = _init.vertex; o.crt_uv = _init.crt_uv; }

#endif //CRT_STANDARD_2D_INCLUDED