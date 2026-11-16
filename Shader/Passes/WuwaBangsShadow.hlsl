#ifndef WUWA_BANGS_SHADOW_INCLUDED
#define WUWA_BANGS_SHADOW_INCLUDED
#include "WuwaVertex.hlsl"

float4 WuwaBangsShadowVertex(WuwaAttributes input) : SV_POSITION
{
    // EID2793 VS0783: Material[48].xyz is a post-skin, object-space translation.
    // Source centimetres -> Unity metres. This capture has no light-vector input.
    return TransformObjectToHClip(input.positionOS.xyz + _BangsShadowOffsetOS.xyz);
}

float4 WuwaBangsShadowFragment() : SV_Target
{
    // A binary footprint. The separate receiver resolve applies min(toon,.5).
    return 1;
}
#endif
