#ifndef WUWA_CHARACTER_SHADOW_INCLUDED
#define WUWA_CHARACTER_SHADOW_INCLUDED
TEXTURE2D_SHADOW(_WuwaCharacterShadowmap);
SAMPLER_CMP(sampler_WuwaCharacterShadowmap);
float4x4 _WuwaWorldToCharacterShadow;
// xy: local shadow texel size, z: light shadow strength, w: ready for this camera.
float4 _WuwaCharacterShadowParams;

half WuwaCharacterSelfShadow(float3 positionWS)
{
    if(_WuwaCharacterShadowParams.w<.5) return 1.0;
    float3 coord=mul(_WuwaWorldToCharacterShadow,float4(positionWS,1)).xyz;
    if(any(coord<0.0)||any(coord>1.0)) return 1.0;
    float2 texel=_WuwaCharacterShadowParams.xy*.5;
    half visibility=0;
    visibility+=SAMPLE_TEXTURE2D_SHADOW(_WuwaCharacterShadowmap,sampler_WuwaCharacterShadowmap,float3(coord.xy+float2(-texel.x,-texel.y),coord.z));
    visibility+=SAMPLE_TEXTURE2D_SHADOW(_WuwaCharacterShadowmap,sampler_WuwaCharacterShadowmap,float3(coord.xy+float2( texel.x,-texel.y),coord.z));
    visibility+=SAMPLE_TEXTURE2D_SHADOW(_WuwaCharacterShadowmap,sampler_WuwaCharacterShadowmap,float3(coord.xy+float2(-texel.x, texel.y),coord.z));
    visibility+=SAMPLE_TEXTURE2D_SHADOW(_WuwaCharacterShadowmap,sampler_WuwaCharacterShadowmap,float3(coord.xy+float2( texel.x, texel.y),coord.z));
    return lerp(1.0,visibility*.25,_WuwaCharacterShadowParams.z);
}
#endif
