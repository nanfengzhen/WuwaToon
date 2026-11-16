#ifndef WUWA_SCENE_SHADOW_RECEIVE_INCLUDED
#define WUWA_SCENE_SHADOW_RECEIVE_INCLUDED
TEXTURE2D_SHADOW(_WuwaSceneReceiveShadowmap);
SAMPLER_CMP(sampler_WuwaSceneReceiveShadowmap);
float4x4 _WuwaWorldToSceneReceiveShadow;
// xy: local shadow texel size, z: light shadow strength, w: ready for this camera.
float4 _WuwaSceneReceiveShadowParams;

half WuwaReceiveSceneShadow(float3 positionWS)
{
    if(_WuwaSceneReceiveShadowParams.w<.5) return 1.0;
    float3 coord=mul(_WuwaWorldToSceneReceiveShadow,float4(positionWS,1)).xyz;
    if(any(coord<0.0)||any(coord>1.0)) return 1.0;
    float2 texel=_WuwaSceneReceiveShadowParams.xy*.5;
    half visibility=0;
    visibility+=SAMPLE_TEXTURE2D_SHADOW(_WuwaSceneReceiveShadowmap,sampler_WuwaSceneReceiveShadowmap,float3(coord.xy+float2(-texel.x,-texel.y),coord.z));
    visibility+=SAMPLE_TEXTURE2D_SHADOW(_WuwaSceneReceiveShadowmap,sampler_WuwaSceneReceiveShadowmap,float3(coord.xy+float2( texel.x,-texel.y),coord.z));
    visibility+=SAMPLE_TEXTURE2D_SHADOW(_WuwaSceneReceiveShadowmap,sampler_WuwaSceneReceiveShadowmap,float3(coord.xy+float2(-texel.x, texel.y),coord.z));
    visibility+=SAMPLE_TEXTURE2D_SHADOW(_WuwaSceneReceiveShadowmap,sampler_WuwaSceneReceiveShadowmap,float3(coord.xy+float2( texel.x, texel.y),coord.z));
    return lerp(1.0,visibility*.25,_WuwaSceneReceiveShadowParams.z);
}
#endif
