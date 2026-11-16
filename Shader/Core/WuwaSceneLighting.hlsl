#ifndef WUWA_SCENE_LIGHTING_INCLUDED
#define WUWA_SCENE_LIGHTING_INCLUDED
#include "WuwaSceneShadowReceive.hlsl"

// Keep the captured Toon/Ramp result. Only external scene occlusion is added.
float3 WuwaResolveSceneShadows(float3 diffuse,float3 shadow,float toon,float3 positionWS)
{
    float visibility=_SceneShadowsEnabled>.5 ? WuwaReceiveSceneShadow(positionWS):1.0;
    float shadowedToon=lerp(min(toon,.5),toon,visibility);
    return WuwaResolveToon(diffuse,shadow,shadowedToon);
}
#endif
