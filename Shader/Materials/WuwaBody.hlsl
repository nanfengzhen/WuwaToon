#include "WuwaBodyMatCap.hlsl"
#include "WuwaSparkle.hlsl"
#include "WuwaAlpha.hlsl"
#include "WuwaStarMark.hlsl"
// EIDs 2661/2691/2721/2761: captured material partition and Ramp.
struct BodyParams {
    float3 tint;
    float3 darkTint;
    float3 lightTint;
    float3 overrideColor;
    float3 baseTint;
    float3 viewColor1;
    float3 viewColor2;
    float normalMask;
    float overrideScale;
    float2 skinRange;
    float colorGlobal;
    float occlusionStrength;
    float aoTop;
    float aoCap;
    float aoDiv;
    float aoMax;
    float aoMin;
    float aoRange;
    float lightToggle;
    float lightBlend;
    float shadowBias;
    float widths[5];
    float widthGlobal;
    float widthBlend;
    float3 shadowLight;
    float3 shadowDark;
    float rampCap;
    float rampRows[5];
    float rampMix[5];
    float desaturate;
    float aoViewStrength;
    float customX;
    float baseIntensity;
    float2 viewRange;
    float viewBias1;
    float viewWidth1;
    float viewPower1;
    float viewBias2;
    float viewWidth2;
    float viewPower2;
    float viewBlend2;
    float viewStrength;
    bool hasViewOverlay;
    bool rampAffectsBase;
};

BodyParams GetBodyParams() {
    BodyParams p;
    p.tint = _BodyTint.xyz;
    p.darkTint = _BodyDarkTint.xyz;
    p.lightTint = _BodyLightTint.xyz;
    p.overrideColor = _BodyOverrideColor.xyz;
    p.baseTint = _BodyBaseTint.xyz;
    p.viewColor1 = _BodyViewColor1.xyz;
    p.viewColor2 = _BodyViewColor2.xyz;
    p.normalMask = _BodyNormalMask;
    p.overrideScale = _BodyOverrideScale;
    p.skinRange = _BodySkinRange.xy;
    p.colorGlobal = _BodyColorGlobal;
    p.occlusionStrength = _BodyOcclusionStrength;
    p.aoTop = _BodyAoTop;
    p.aoCap = _BodyAoCap;
    p.aoDiv = _BodyAoDiv;
    p.aoMax = _BodyAoMax;
    p.aoMin = _BodyAoMin;
    p.aoRange = _BodyAoRange;
    p.lightToggle = _BodyLightToggle;
    p.lightBlend = _BodyLightBlend;
    p.shadowBias = _BodyShadowBias;
    p.widths[0] = _BodyWidths0123.x;
    p.widths[1] = _BodyWidths0123.y;
    p.widths[2] = _BodyWidths0123.z;
    p.widths[3] = _BodyWidths0123.w;
    p.widths[4] = _BodyWidths4.x;
    p.widthGlobal = _BodyWidthGlobal;
    p.widthBlend = _BodyWidthBlend;
    p.shadowLight = _BodyShadowLight.xyz;
    p.shadowDark = _BodyShadowDark.xyz;
    p.rampCap = _BodyRampCap;
    p.rampRows[0] = _BodyRampRows0123.x;
    p.rampRows[1] = _BodyRampRows0123.y;
    p.rampRows[2] = _BodyRampRows0123.z;
    p.rampRows[3] = _BodyRampRows0123.w;
    p.rampRows[4] = _BodyRampRows4.x;
    p.rampMix[0] = _BodyRampMix0123.x;
    p.rampMix[1] = _BodyRampMix0123.y;
    p.rampMix[2] = _BodyRampMix0123.z;
    p.rampMix[3] = _BodyRampMix0123.w;
    p.rampMix[4] = _BodyRampMix4.x;
    p.desaturate = _BodyDesaturate;
    p.aoViewStrength = _BodyAoViewStrength;
    p.customX = _BodyCustomX;
    p.baseIntensity = _BodyBaseIntensity;
    p.viewRange = _BodyViewRange.xy;
    p.viewBias1 = _BodyViewBias1;
    p.viewWidth1 = _BodyViewWidth1;
    p.viewPower1 = _BodyViewPower1;
    p.viewBias2 = _BodyViewBias2;
    p.viewWidth2 = _BodyViewWidth2;
    p.viewPower2 = _BodyViewPower2;
    p.viewBlend2 = _BodyViewBlend2;
    p.viewStrength = _BodyViewStrength;
    p.hasViewOverlay = _BodyHasViewOverlay>0.5;
    p.rampAffectsBase = _BodyRampAffectsBase>0.5;
    return p;
}
float BodyRange(float id,float2 lowerUpper) {
    return (id+0.5 >= lowerUpper.x && lowerUpper.y >= id-0.5) ? 1.0 : 0.0;
}
float BodyPow(float x,float exponent) {
    return x <= 2.98023e-8 ? 0.0 : exp2(log2(x)*exponent);
}
struct BodyToonData {
    float coverageLuminance;
    float3 additive;
    float3 diffuse;
    float3 shadow;
    float toonPacked;
    float customX;
    float2 rampUV;
    int materialID;
};
// Base and mask samples are supplied externally with original color-space conventions.
// Packed RGID sample must be point sampled and linear. Ramp is linearSampler t6/t7/t10/t8.
BodyToonData EvaluateBodyFeatures12(
    BodyParams p, float4 base, float4 mask, float rgidR,
    float3 N, float3 V, float3 lightDirection672, float3 lightDirection368,
    float3 geomN,float3 detailN,float3 tangentN,float normalAlpha,
    float3 cameraRight,float3 cameraUp,float3 cameraForward,float2 sourceUV0,float2 sourceUV2,
    float cameraAnchorDistance,
    Texture2D<float4> skinRamp, SamplerState rampSampler, float collectionRampGate,
    bool enableSkinRamp) {
    BodyToonData o;
    int packed=(int)(rgidR*255.5);
    int lo=packed&15, hi=packed>>4;
    int id=(hi>0 && mask.a>=0.5) ? hi:lo;
    float overrideWeight=saturate(p.overrideScale*2.00803*
                                 (p.normalMask*(mask.b-0.5)-0.00199997));
    float skinOrOverride=max(BodyRange(id,p.skinRange),overrideWeight);
    float colorWeight=lerp(p.colorGlobal,1.0,skinOrOverride);
    float maskB=p.normalMask*(mask.b-0.5)+0.5;
    float whitening=saturate(1-p.occlusionStrength*(1-saturate(2*maskB)));
    float3 localTint=lerp(p.darkTint,p.lightTint,skinOrOverride);
    float3 basePartition=lerp(localTint,1.0.xxx,whitening)
                       *lerp(1.0.xxx,p.tint,colorWeight)*p.baseTint
                       *lerp(base.rgb,p.overrideColor,overrideWeight);
    float ndv=dot(N,V);
    if(p.hasViewOverlay) {
        float a=BodyPow(saturate((ndv-p.viewBias1)/p.viewWidth1),p.viewPower1);
        float3 t=lerp(p.viewColor1,0.5.xxx,a);
        // Captured Cloth has inactive width2=0, blend2=0; specialize that inactive branch.
        if(p.viewBlend2!=0) {
            float b=BodyPow(saturate((ndv-p.viewBias2)/p.viewWidth2),p.viewPower2);
            t=lerp(t,lerp(p.viewColor2,t,b),p.viewBlend2);
        }
        float3 blendColor=0.5+(t-0.5)*p.viewStrength;
        float3 overlay=lerp(2*basePartition*blendColor,
                            1-2*(1-basePartition)*(1-blendColor),step(0.5,blendColor));
        basePartition=lerp(basePartition,overlay,
                          min(BodyRange(id,p.viewRange),1-overrideWeight));
    }
    // All snapshots cb1[48].z=0 and cb2[432].y=0. No local-light branch is active.
    float3 L=normalize(lerp(lightDirection672,lightDirection368,
                           p.lightBlend*step(0.5,p.lightToggle)));
    float ndl=dot(N,L);
    float ao=clamp(base.a,0,p.aoTop)/p.aoTop;
    ao=min(ao,p.aoCap)/p.aoDiv;
    ao=(clamp(ao,p.aoMin,p.aoMax)-p.aoMin)/p.aoRange;
    float viewShift=(((1-abs(V.z))*dot(L,V)+1)*0.25-0.1)*(1-saturate(ndv));
    float boundary=p.shadowBias+viewShift;
    float unoccluded=saturate(0.5*ndl+1-boundary);
    float rampX=lerp(min(unoccluded,p.rampCap),unoccluded,ao);
    float rampY=0, rampStrength=0, widthById=0;
    [unroll] for(int i=0;i<5;++i) {
        float idWeight=id==i ? 1.0:0.0;
        float w=i==0 ? max(idWeight,overrideWeight):min(idWeight,1-overrideWeight);
        rampY+=(p.rampRows[i]*0.2+0.1)*w;
        rampStrength+=p.rampMix[i]*w;
        widthById+=idWeight*p.widths[i];
    }
    rampStrength*=step(0.05,collectionRampGate)*(enableSkinRamp ? 1.0:0.0);
    float3 partitionShadow=lerp(p.shadowDark,p.shadowLight,colorWeight);
    float3 ramp=partitionShadow;
    if(enableSkinRamp) ramp=WuwaSampleSkin(float2(rampX,rampY));
    float3 shadow=lerp(partitionShadow,ramp,rampStrength);
    shadow=lerp(shadow,dot(shadow,float3(.3,.59,.11)).xxx,p.desaturate);
    float width=p.widthGlobal*lerp(1.0,widthById,p.widthBlend);
    float q=saturate((0.5*ndl+0.5-boundary+width)/(2*width));
    float toonSmooth=q*q*(3-2*q);
    o.additive=0;o.coverageLuminance=0;
    if(_MatCapEnabled>.5 || _AlphaDitherEnabled>.5 || _SparkleEnabled>.5) {
        BodyMatCapResult reflection=ApplyBodyMatCap(basePartition,geomN,detailN,N,V,L,tangentN,
            id,mask,normalAlpha,ao*toonSmooth,colorWeight,overrideWeight,cameraRight,cameraUp,cameraForward);
        float3 sparkle=0;
        if(_SparkleEnabled>.5 || _AlphaDitherEnabled>.5)
            sparkle=WuwaBodySparkle(_BodyMatCapVariant,sourceUV0,sourceUV2,V,basePartition,
                reflection.sparkleCoverageGate,_SparkleSourceTime,cameraAnchorDistance);
        if(_AlphaDitherEnabled>.5) o.coverageLuminance=max(reflection.coverageLuminance,
            dot(sparkle,float3(.3,.59,.11)));
        if(_MatCapEnabled>.5) {basePartition=reflection.baseColor;o.additive=reflection.overflow;}
        // Source emission only clamps the combined lower bound; retain HDR sparkle.
        if(_SparkleEnabled>.5) o.additive=max(o.additive+sparkle,0);

    }
    float3 diffuse=basePartition*p.baseIntensity;
    // PS0945 _1953.._1959: apply the active black base mark after reflection,
    // before the original Ramp-to-base mix. Captured emission remains zero.
    if(_StarMarkEnabled>.5 && _BodyMatCapVariant>1.5 && _BodyMatCapVariant<2.5)
        diffuse*=1.0-WuwaStarMarkMask(sourceUV0);
    if(p.rampAffectsBase) diffuse=lerp(diffuse,ramp,0.5*rampStrength*colorWeight);
    diffuse=saturate(diffuse);
    diffuse=lerp(diffuse,dot(diffuse,float3(.3,.59,.11)).xxx,p.desaturate);

    float hd=WuwaHorizontalDot(L,V);
    float horizontal=(clamp(hd,-1.0,-0.25)+1)*(4.0/3.0);
    float aoView=1-(1-ao)*(1-horizontal*horizontal)*p.aoViewStrength;
    o.diffuse=diffuse;
    o.shadow=shadow;
    o.toonPacked=(0.5+0.5*ao*toonSmooth)*aoView;
    o.customX=p.customX;
    o.rampUV=float2(rampX,rampY);
    o.materialID=id;
    return o;
}
// Raw source regular GBuffer: Target2.rgb=sqrt(saturate(o.shadow));
// Target3.rgb=o.diffuse; Target1.z=o.toonPacked; Target6.x=o.customX.
// Final light composition must use the independently derived KuroToon resolve.
