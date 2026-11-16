#ifndef WUWA_FEATURE12_INPUT_INCLUDED
#define WUWA_FEATURE12_INPUT_INCLUDED
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GlobalSamplers.hlsl"
TEXTURE2D(_BaseMap); TEXTURE2D(_FTM); TEXTURE2D(_RGID);
TEXTURE2D(_SkinRamp); TEXTURE2D(_FaceSDF); TEXTURE2D(_HairHM);
TEXTURE2D(_StarMark);
TEXTURE2D(_AlphaNoise); TEXTURE2D(_AlphaSparkle);
TEXTURE2D(_EyeEG); TEXTURE2D(_EyeEM); TEXTURE2D(_HET);
SAMPLER(sampler_EyeEG); SAMPLER(sampler_EyeEM); SAMPLER(sampler_HET); SAMPLER(sampler_BaseMap);
TEXTURE2D_X(_WuwaUnderDiffuse);
float4 _WuwaUnderDiffuseScale;
TEXTURE2D_X(_WuwaCharacterRawDepth);
float4 _WuwaCharacterDepthScale;
float _WuwaDepthRimReady;
TEXTURE2D_X(_WuwaBangsShadowMask);
float4 _WuwaBangsShadowMaskScale;
TEXTURE2D(_DetailNormalMap); TEXTURE2D(_MatCap);
TEXTURE2D(_HairHN); TEXTURE2D(_HairNoise); TEXTURE2D(_HairHR);
CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
float4 _BangsShadowOffsetOS;
float _OutlineEnabled, _OutlineWidth, _OutlineSmooth, _OutlineTextured;
float4 _OutlineColor;
float _DepthRimEnabled;
float _MaterialKind, _RampEnabled, _ValidationMode;
float _DetailNormalsEnabled, _DetailNormalStrength, _BodyGeometricNormalBlend;
float4 _WorldToCapture0, _WorldToCapture1, _WorldToCapture2;
float4 _FaceAxisA, _FaceAxisB;
float _EyeEffectsEnabled, _EyeParallaxEnabled, _CoverageEnabled;
float _Cull, _AlphaDitherEnabled, _DoubleSidedNormalsEnabled;
float _HairHMShift;
float _HairHighlightsEnabled, _HairIsBangs;
float _MatCapEnabled, _BodyMatCapVariant;
float _SparkleEnabled, _SparkleSourceTime;
float _StarMarkEnabled;
float _SceneShadowsEnabled;
float4 _ToonDarkColor;
float4 _BodyTint;
float4 _BodyDarkTint;
float4 _BodyLightTint;
float4 _BodyOverrideColor;
float4 _BodyBaseTint;
float4 _BodyViewColor1;
float4 _BodyViewColor2;
float _BodyNormalMask;
float _BodyOverrideScale;
float4 _BodySkinRange;
float _BodyColorGlobal;
float _BodyOcclusionStrength;
float _BodyAoTop;
float _BodyAoCap;
float _BodyAoDiv;
float _BodyAoMax;
float _BodyAoMin;
float _BodyAoRange;
float _BodyLightToggle;
float _BodyLightBlend;
float _BodyShadowBias;
float4 _BodyWidths0123;
float4 _BodyWidths4;
float _BodyWidthGlobal;
float _BodyWidthBlend;
float4 _BodyShadowLight;
float4 _BodyShadowDark;
float _BodyRampCap;
float4 _BodyRampRows0123;
float4 _BodyRampRows4;
float4 _BodyRampMix0123;
float4 _BodyRampMix4;
float _BodyDesaturate;
float _BodyAoViewStrength;
float _BodyCustomX;
float _BodyBaseIntensity;
float4 _BodyViewRange;
float _BodyViewBias1;
float _BodyViewWidth1;
float _BodyViewPower1;
float _BodyViewBias2;
float _BodyViewWidth2;
float _BodyViewPower2;
float _BodyViewBlend2;
float _BodyViewStrength;
float _BodyHasViewOverlay;
float _BodyRampAffectsBase;
CBUFFER_END
float3 WuwaWorldToCapture(float3 v) {
    return normalize(float3(dot(_WorldToCapture0.xyz,v),dot(_WorldToCapture1.xyz,v),dot(_WorldToCapture2.xyz,v)));
}
#endif
