#ifndef WUWA_FEATURE12_FORWARD_INCLUDED
#define WUWA_FEATURE12_FORWARD_INCLUDED
#include "../Core/WuwaInput.hlsl"
#include "../Core/WuwaLighting.hlsl"
#include "../Core/WuwaRamp.hlsl"
#include "../Materials/WuwaBody.hlsl"
#include "../Materials/WuwaBodyNormal.hlsl"
#include "../Materials/WuwaFaceHair.hlsl"
#include "../Materials/WuwaHairHighlights.hlsl"
#include "../Materials/WuwaEye.hlsl"
#include "../Materials/WuwaCoverage.hlsl"
#include "../Core/WuwaToonLighting.hlsl"
#include "WuwaVertex.hlsl"
#include "../Materials/WuwaDepthRim.hlsl"
#include "../Core/WuwaSceneLighting.hlsl"
float4 WuwaFragment(WuwaVaryings input, FRONT_FACE_TYPE frontFace:FRONT_FACE_SEMANTIC):SV_Target {
#ifdef WUWA_PROJECTED_SHADOW_RESOLVE
    float2 shadowUV=GetNormalizedScreenSpaceUV(input.positionCS)*_WuwaBangsShadowMaskScale.xy;
    clip(SAMPLE_TEXTURE2D_X(_WuwaBangsShadowMask,sampler_PointClamp,shadowUV).r-.5);
#endif
#ifndef WUWA_ORDERED_HAIR
    if(_CoverageEnabled>.5 && _MaterialKind>.5 && _MaterialKind<1.5) clip(-1);
#endif
    float3 N=WuwaWorldToCapture(normalize(input.normalWS));
    float3 geomN=N;
    float3 V=WuwaWorldToCapture(GetWorldSpaceNormalizeViewDir(input.positionWS));
    float3 L=WuwaMainLightDirection();
    float3 alternateL=WuwaAlternateLightDirection(L);
    float3 faceBack=WuwaWorldToCapture(_FaceAxisA.xyz);
    float3 faceHighU=WuwaWorldToCapture(_FaceAxisB.xyz);
    float4 base= SAMPLE_TEXTURE2D_BIAS(_BaseMap,sampler_LinearClamp,input.uv,-.883835852);
    float4 mask= SAMPLE_TEXTURE2D_LOD(_FTM,sampler_LinearRepeat,input.uv,0);
    float3 additive=0;
    float3 cameraRight=WuwaWorldToCapture(UNITY_MATRIX_V[0].xyz);
    float3 cameraUp=WuwaWorldToCapture(UNITY_MATRIX_V[1].xyz);
    float3 cameraForward=WuwaWorldToCapture(-UNITY_MATRIX_V[2].xyz);
    float3 diffuse,shadow;float toon;float2 rampUV;int materialID;
    bool rampEnabled=_RampEnabled>.5;
    if(_MaterialKind<.5) {
        if(_DetailNormalsEnabled>.5)
            N=WuwaWorldToCapture(WuwaBodyDetailNormal(input.normalWS,input.tangentWS,input.uv,mask));
        if(_DoubleSidedNormalsEnabled>.5) N=WuwaAlphaFaceNormal(N,IS_FRONT_VFACE(frontFace,true,false));
        float rgid=SAMPLE_TEXTURE2D_LOD(_RGID,sampler_PointRepeat,input.uv,0).r;
        BodyToonData b=EvaluateBodyFeatures12(GetBodyParams(),base,mask,rgid,N,V,L,alternateL,
            geomN,N,WuwaWorldToCapture(normalize(input.tangentWS.xyz)),
            SAMPLE_TEXTURE2D_BIAS(_DetailNormalMap,sampler_LinearClamp,input.uv,-.883835852).a,
            cameraRight,cameraUp,cameraForward,float2(input.uv.x,1-input.uv.y),float2(input.alphaUV.x,1-input.alphaUV.y),
            distance(GetCameraPositionWS(),TransformObjectToWorld(float3(0,0,.8)))*100.0,_SkinRamp,sampler_LinearClamp,3,rampEnabled);
        if(_AlphaDitherEnabled>.5) WuwaApplyAlphaClip(mask.r,b.coverageLuminance,input.positionCS.xy);
        additive=b.additive;
        diffuse=b.diffuse;shadow=b.shadow;toon=b.toonPacked;rampUV=b.rampUV;materialID=b.materialID;
    } else {
        FaceHairToonData s;
        if(_MaterialKind<1.5) {
            float hm=SAMPLE_TEXTURE2D_BIAS(_HairHM,sampler_LinearClamp,input.uv,-.883835852).g;
            s=EvaluateHairFeatures12(base,mask,hm,N,V,L,_HairHMShift,_SkinRamp,sampler_LinearClamp,3,rampEnabled);
            if(_HairHighlightsEnabled>.5) {
                float3 headUp=WuwaWorldToCapture(normalize(cross(_FaceAxisA.xyz,_FaceAxisB.xyz)));
                HairFeature5Result h=EvaluateHairFeature5(GetCapturedHairFeature5Params(_HairIsBangs>.5),base.rgb,base.a,input.uv,
                    N,V,L,cameraRight,cameraForward,headUp,_HairHN,_HairHM,_HairNoise,_HairHR,sampler_LinearClamp,sampler_LinearRepeat);
                s.diffuse=h.diffuse;additive=h.additive;
            }
        } else if(_MaterialKind<2.5) {
            s=EvaluateFaceFeatures12(base,mask,input.uv,N,V,L,faceBack,faceHighU,_FaceSDF,sampler_LinearClamp,_SkinRamp,sampler_LinearClamp,3,rampEnabled);
        } else {
            if(_EyeEffectsEnabled>.5) {
                Eye7Result eye=EvaluateEyeFeature7(float2(input.uv.x,1-input.uv.y),input.eyeGreen,
                    WuwaWorldToCapture(normalize(input.tangentWS.xyz)),WuwaWorldToCapture(WuwaSourceBitangent(input)),N,V,
                    _EyeEG,sampler_EyeEG,_EyeEM,sampler_EyeEM,_BaseMap,sampler_BaseMap,_EyeParallaxEnabled>.5);
                s=EvaluateEyeCoreFeatures12(eye.parallaxBase,input.sdfUV,L,faceBack,faceHighU,_FaceSDF,sampler_LinearClamp);
                s.diffuse=eye.diffuse;additive=eye.maskEmission;
                if(_ValidationMode>5.5 && _ValidationMode<6.5) return float4(eye.sourceParallaxUV,0,1);
            } else s=EvaluateEyeCoreFeatures12(base,input.sdfUV,L,faceBack,faceHighU,_FaceSDF,sampler_LinearClamp);
        }
        diffuse=s.diffuse;shadow=s.shadow;toon=s.toonPacked;rampUV=s.rampUV;materialID=s.materialID;
    }
#ifdef WUWA_DEPTH_OUTPUT
    return input.positionCS.zzzz;
#endif
#ifdef WUWA_DIFFUSE_OUTPUT
    return float4(diffuse,1);
#endif
#ifdef WUWA_BANGS_SMOOTH
    float2 screenUV=GetNormalizedScreenSpaceUV(input.positionCS)*_WuwaUnderDiffuseScale.xy;
    float3 under=SAMPLE_TEXTURE2D_X(_WuwaUnderDiffuse,sampler_PointClamp,screenUV).rgb;
    diffuse=Coverage8CompositeDiffuse(under,diffuse,mask.r);
#endif
#ifdef WUWA_PROJECTED_SHADOW_RESOLVE
    // Original RT1.B Min blend is applied before deferred Toon lighting.
    toon=min(toon,.5);
#endif
    if(_ValidationMode>.5 && _ValidationMode<1.5) return float4(frac(float3(.37,.61,.83)*(materialID+1)),1);
    if(_ValidationMode>1.5 && _ValidationMode<2.5) return float4(rampUV,0,1);
    if(_ValidationMode>2.5 && _ValidationMode<3.5) return float4(saturate(shadow),1);
    if(_ValidationMode>4.5) return float4(N*.5+.5,1);
    if(_ValidationMode>3.5) return float4(toon.xxx,1);
    float3 rim=0;
    if(_DepthRimEnabled>.5 && _WuwaDepthRimReady>.5) {
        float rimMaterial=_MaterialKind>2.5 ? 0.0 : .05;
#ifdef WUWA_BANGS_SMOOTH
        rimMaterial=1.0;
#endif
        rim=WuwaEvaluateDepthRim(N,V,diffuse,input.positionWS,input.positionCS,rimMaterial);
    }
    float3 lit=WuwaResolveSceneShadows(diffuse,shadow,toon,input.positionWS);
    return float4(lit+rim+additive,1);
}
#endif
