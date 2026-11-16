#ifndef FACE_HAIR_FEATURE12_INCLUDED
#define FACE_HAIR_FEATURE12_INCLUDED
#include "WuwaFaceSDF.hlsl"

// Captured Face0793 / Hair0796 / Eye0814 Feature1+2 specialization.
// All positions/directions use Unreal's Z-up basis. L points toward the light.
// Base texture RGB and Skin RGB must use their original linear shader values.
// SDF, mask and HM are data textures. Never sRGB-decode their channels.
// Face/Hair sampler1 is linear clamp; Eye's SDF sampler0 is linear wrap.
// See face_hair_ramp_derivation.md for cbuffer offsets and source SSA evidence.
struct FaceHairToonData
{
    float3 diffuse;
    float3 shadow;
    float toonPacked;
    float customX;
    float2 rampUV;
    int materialID;
};

float FHToonSmooth(float x, float threshold, float width)
{
    float q = saturate((x - threshold + width) / (2.0 * width));
    return q * q * (3.0 - 2.0 * q);
}

float FHViewAO(float ao, float3 L, float3 V, float strength)
{
    float horizontalDot = WuwaHorizontalDot(L,V);
    float t = (clamp(horizontalDot, -1.0, -0.25) + 1.0) * (4.0 / 3.0);
    return 1.0 - strength * (1.0 - ao) * (1.0 - t * t);
}

FaceHairToonData EvaluateFaceFeatures12(
    float4 baseSample, float4 maskSample, float2 uv,
    float3 N, float3 V, float3 L, float3 axisA, float3 axisB,
    Texture2D<float4> faceSDF, SamplerState sdfSampler,
    Texture2D<float4> skinRamp, SamplerState rampSampler,
    float collectionRampGate, bool enableSkinRamp)
{
    FaceHairToonData o;
    L = normalize(L);
    int id = (int)floor(min(maskSample.a, 0.99) * 5.0);
    float skinRegion = id == 0 ? 1.0 : 0.0;
    // C[1232].z=0: blue-channel override and local darkening are inactive.
    float3 partitionBase = baseSample.rgb * lerp(float3(1,1,1),
        float3(.9427080154,.8895170093,.8445090055), skinRegion);
    float3 partitionShadow = lerp(float3(.4967690110,.4882380068,.515625),
        float3(.9479169846,.7357339859,.7010639906), skinRegion);

    float2 sdfUV;
    float theta;
    FHFaceSDFCoordinates(uv, L, axisA, axisB, sdfUV, theta);
    float4 sdf = faceSDF.Sample(sdfSampler, sdfUV);
    float bluePower = sdf.b <= 2.98023e-8 ? 0.0 : exp2(log2(sdf.b) * 1.5);
    float unoccluded = saturate(0.5 * (bluePower + theta));
    float ao = saturate(baseSample.a / 0.1);
    float rampU = lerp(min(unoccluded, 0.3), unoccluded, ao);
    float rampV = id == 0 ? .1 : id == 1 ? .3 : id == 2 ? .5 : .9;
    float rampWeight = (id == 0 || id == 4) ? .1 : 1.0;
    rampWeight *= step(0.05, collectionRampGate) * (enableSkinRamp ? 1.0 : 0.0);
    float3 ramp = partitionShadow;
    if (enableSkinRamp)
        ramp = WuwaSampleSkin(float2(rampU,rampV));

    o.diffuse = saturate(lerp(partitionBase, ramp, 0.5 * rampWeight * skinRegion));
    o.shadow = lerp(partitionShadow, ramp, rampWeight);
    float h = 0.25 * (sdf.r + sdf.a) + 0.5 * theta;
    o.toonPacked = (0.5 + 0.5 * ao * FHToonSmooth(h, .5, .03))
                 * FHViewAO(ao, L, V, .2);
    o.customX = .05;
    o.rampUV = float2(rampU, rampV);
    o.materialID = id;
    return o;
}

FaceHairToonData EvaluateHairFeatures12(
    float4 baseSample, float4 maskSample, float hmG,
    float3 N, float3 V, float3 L, float hmShift,
    Texture2D<float4> skinRamp, SamplerState rampSampler,
    float collectionRampGate, bool enableSkinRamp)
{
    FaceHairToonData o;
    L = normalize(L);
    N = normalize(N);
    int id = (int)floor(min(maskSample.a, .99) * 5.0);
    // Region range5..5 does not match id0..4. Blue override=0.
    // This is the original partition base before the deliberately omitted HR chain.
    o.diffuse = saturate(baseSample.rgb);
    float3 partitionShadow = float3(.8332020044,.7376170158,.859375);
    // HM.g is a core Toon/Ramp dependency, NOT an HR-highlight contribution.
    // EID2836 hmShift=.2; EID2847 hmShift=.25. HM gain=power=1 in both.
    float h = .5 + .5 * dot(N, L) + hmShift * hmG;
    float ao = saturate(baseSample.a / .4);
    float unoccluded = saturate(h - .2);
    float rampU = lerp(min(unoccluded, .2), unoccluded, ao);
    float rampWeight = .3 * step(.05, collectionRampGate)
                       * (enableSkinRamp ? 1.0 : 0.0);
    float3 ramp = partitionShadow;
    if (enableSkinRamp)
        ramp = WuwaSampleSkin(float2(rampU,.3));
    o.shadow = lerp(partitionShadow, ramp, rampWeight);
    o.toonPacked = (.5 + .5 * ao * FHToonSmooth(h, .7, .03))
                 * FHViewAO(ao, L, V, .1);
    o.customX = .05;
    o.rampUV = float2(rampU, .3);
    o.materialID = id;
    return o;
}

// Eye has no Skin resource. baseSample is the caller's minimal eye base sample.
// Feature7 supplies the parallax base alpha and replaces diffuse with layered color.
// sdfUVInput must be the SECOND mesh UV (source TEXCOORD0[1]), not base UV.
FaceHairToonData EvaluateEyeCoreFeatures12(
    float4 baseSample, float2 sdfUVInput, float3 L, float3 axisA, float3 axisB,
    Texture2D<float4> faceSDF, SamplerState sdfSampler)
{
    FaceHairToonData o;
    L = normalize(L);
    float2 sdfUV;
    float theta;
    FHFaceSDFCoordinates(sdfUVInput, L, axisA, axisB, sdfUV, theta);
    float4 sdf = faceSDF.SampleBias(sdfSampler, sdfUV,-.883835852146);
    float a = min(baseSample.a, .2);
    float ao = a / max(a, .01);
    float gate = saturate((ao - .9) / .1);
    float h = .25 * (sdf.r + sdf.a) + .5 * theta;
    o.diffuse = saturate(baseSample.rgb);
    o.shadow = float3(.4,.4,.4);
    o.toonPacked = (.5 + .5 * gate * FHToonSmooth(h, .5, .03)) * ao;
    o.customX = 0;
    o.rampUV = float2(0,0);
    o.materialID = 0;
    return o;
}

// All outputs are LINEAR semantic channels, not final light composition.
// Original GBuffer: Target2.rgb=sqrt(saturate(shadow)), Target3.rgb=diffuse,
// Target1.z=toonPacked, Target6.x=customX. Never apply that sqrt in a forward port.
// Compose using the independently derived deferred-lighting resolve.
#endif
