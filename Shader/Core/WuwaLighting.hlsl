#ifndef WUWA_LIGHTING_INCLUDED
#define WUWA_LIGHTING_INCLUDED
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

// The static capture had nonzero horizontal projections. A movable sun can be
// directly overhead; its zero azimuth has a neutral projection, not a NaN.
float2 WuwaNormalizePlane(float2 v) { return v * rsqrt(max(dot(v,v),1e-8)); }
float WuwaHorizontalDot(float3 a,float3 b) {
    return dot(WuwaNormalizePlane(a.xy),WuwaNormalizePlane(b.xy));
}
float3 WuwaMainLightDirection() {
    // URP direction points from the surface toward the main directional light.
    return WuwaWorldToCapture(GetMainLight().direction);
}
float3 WuwaAlternateLightDirection(float3 lightDirection) {
    // Captured LightB is the normalized horizontal projection of LightA.
    return float3(WuwaNormalizePlane(lightDirection.xy),0);
}
#endif
