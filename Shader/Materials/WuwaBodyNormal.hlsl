#ifndef WUWA_BODY_NORMAL_INCLUDED
#define WUWA_BODY_NORMAL_INCLUDED
// PS0939/0942/0945/1281: RG encodes tangent-plane offsets, not a unit normal.
// The source adds those offsets to Ng, then normalizes; texture B is not used.
float3 WuwaBodyDetailNormal(float3 geometricNormalWS,float4 tangentWS,
                            float2 uv,float4 ftm)
{
    float2 offsets=SAMPLE_TEXTURE2D_BIAS(_DetailNormalMap,sampler_LinearClamp,
                                        uv,-.883835852).rg*2-1;
    // The FBX has V=1-sourceV, and Unity reconstructs tangents from those UVs.
    // Both source B and Unity B follow their own increasing V. Reverse Unity B
    // to express the original PNG's G offset in the source V direction.
    float3 bitangentWS=-cross(geometricNormalWS,tangentWS.xyz)*tangentWS.w;
    float overrideWeight=saturate(_BodyOverrideScale*2.00803*
                                  (_BodyNormalMask*(ftm.b-.5)-.00199997));
    float3 delta=(offsets.x*tangentWS.xyz+offsets.y*bitangentWS)*_DetailNormalStrength;
    // Capture cb0[2304].w=1 for all four materials (detail globally enabled).
    float3 detail=normalize(geometricNormalWS+(1-overrideWeight)*delta);
    // Capture material geometric-normal blend is zero for all four materials.
    return lerp(detail,geometricNormalWS,_BodyGeometricNormalBlend);
}
#endif
