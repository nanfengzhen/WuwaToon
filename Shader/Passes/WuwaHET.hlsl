#ifndef WUWA_HET_PASS_INCLUDED
#define WUWA_HET_PASS_INCLUDED
#include "WuwaVertex.hlsl"
#include "../Materials/WuwaEye.hlsl"
#include "../Materials/WuwaCoverage.hlsl"
float4 WuwaHETFragment(WuwaVaryings input):SV_Target {
    float3 N=WuwaWorldToCapture(normalize(input.normalWS));
    float3 V=WuwaWorldToCapture(GetWorldSpaceNormalizeViewDir(input.positionWS));
    float2 uv=Coverage8HETUV(float2(input.uv.x,1-input.uv.y),_MaterialKind>2.5,
        WuwaWorldToCapture(normalize(input.tangentWS.xyz)),WuwaWorldToCapture(WuwaSourceBitangent(input)),N,V,
        _EyeEM,sampler_EyeEM);
    Coverage8ClipHET(uv,_HET,sampler_HET);
    return 0;
}
#endif
