#ifndef WUWA_SHADOW_CASTER_INCLUDED
#define WUWA_SHADOW_CASTER_INCLUDED

#include "../Core/WuwaInput.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
#include "../Materials/WuwaAlpha.hlsl"

// Set by URP ShadowUtils.SetupShadowCasterConstantBuffer for each shadow draw.
float3 _LightDirection;
float3 _LightPosition;

struct WuwaShadowAttributes
{
    // SkinnedMeshRenderer supplies the deformed vertex stream, as for WuwaVertex.
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 uv : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct WuwaShadowVaryings
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

WuwaShadowVaryings WuwaShadowVertex(WuwaShadowAttributes input)
{
    WuwaShadowVaryings output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
#if defined(_CASTING_PUNCTUAL_LIGHT_SHADOW)
    float3 lightDirectionWS = normalize(_LightPosition - positionWS);
#else
    float3 lightDirectionWS = _LightDirection;
#endif

    // Match URP 14.0.11 ShadowCasterPass: normal/depth bias and near-plane clamp.
    output.positionCS = TransformWorldToHClip(
        ApplyShadowBias(positionWS, normalWS, lightDirectionWS));
#if UNITY_REVERSED_Z
    output.positionCS.z = min(output.positionCS.z, UNITY_NEAR_CLIP_VALUE);
#else
    output.positionCS.z = max(output.positionCS.z, UNITY_NEAR_CLIP_VALUE);
#endif
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    return output;
}

half4 WuwaShadowFragment(WuwaShadowVaryings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);

    if (_MaterialKind < 0.5 && _AlphaDitherEnabled > 0.5)
    {
        float ftmR = SAMPLE_TEXTURE2D_LOD(_FTM, sampler_LinearRepeat, input.uv, 0).r;

        // Shadow-map raster pixels replace camera pixels. Do not use
        // WuwaAlphaTopLeftPixel: _ScaledScreenParams describes the camera target,
        // not the directional cascade / punctual-light shadow atlas.
        float2 pixel = input.positionCS.xy;
        float2 noiseUV = float2(pixel.x / 64.0, 1.0 - pixel.y / 64.0);
        float noiseR = SAMPLE_TEXTURE2D_LOD(
            _AlphaNoise, sampler_LinearRepeat, noiseUV, 0).r;

        // View-dependent reflection/sparkle coverage has no unique light-space
        // equivalent. Use FTM.R alone, retaining the existing five-phase dither.
        clip(WuwaAlphaClipValue(ftmR, 0.0, pixel, noiseR));
    }

    // Hair, face and eyes cast their mesh silhouette. Camera-only ordered hair,
    // HET coverage, bangs projection, outline and validation modes do not clip it.
    return 0;
}

#endif
