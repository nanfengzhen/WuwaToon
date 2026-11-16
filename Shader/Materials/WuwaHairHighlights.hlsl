#ifndef WUWA_FEATURE5_HAIR_INCLUDED
#define WUWA_FEATURE5_HAIR_INCLUDED
// PS0796, EID2836(Bangs) / EID2847(Hair), current-capture specialization.
// No cloud dissolve, outline, POM, MatCap, screen rim or new light model.
// N,V,L,cameraRight,cameraForward,headUp are unit vectors in SAME Z-up capture basis.
// V points from pixel to camera, L from pixel to light. cameraForward points into scene.
// HN, HM, HairNoise, HairHR are LINEAR DATA textures (source UNorm, not UNorm_sRGB).
// Source HR V rows .125/.375/.875 map to Unity imported PNG V .875/.625/.125.
// Noise V=.5 is invariant. HN/HM use the existing mesh UV convention, not an extra flip.
struct HairFeature5Params
{
    float2 cameraShift;       // cb4[448].xy
    float2 grazingShift;      // cb4[464].xy
    float2 bandCenter;        // cb4[480].xy
    float2 noiseSwitch;       // cb4[512].xy, both captures (0,0)
    float2 noiseBase;         // cb4[544].xy
    float2 widthViewMix;      // cb4[608].xy
    float2 widthMin;          // cb4[624].xy
    float2 width;             // cb4[640].xy
    float2 noiseAbove;        // cb4[656].xy
    float2 noiseBelow;        // cb4[672].xy
    float2 noiseFalloff;      // cb4[688].xy
    float noiseScaleA;        // cb4[1808].w
    float noiseOffsetA;       // cb4[1824].x
    float noiseAmplitudeA;    // cb4[1824].y
    float noiseScaleB;        // cb4[1824].z
    float noiseOffsetB;       // cb4[1824].w
    float noiseAmplitudeB;    // cb4[1840].x
    float hmToonShift;        // cb4[2000].w, also Feature1/2 input
};

HairFeature5Params GetCapturedHairFeature5Params(bool bangs)
{
    HairFeature5Params p;
    p.cameraShift=bangs ? float2(.20000000298,0) : float2(.20000000298,.15000000596);
    p.grazingShift=bangs ? float2(-.17000000179,0) : float2(-.15000000596,0);
    p.bandCenter=bangs ? float2(.47142800689,.5) : float2(.48095199466,.46190500259);
    p.noiseSwitch=float2(0,0);
    p.noiseBase=bangs ? float2(0,0) : float2(1,0);
    p.widthViewMix=bangs ? float2(.08571399748,0) : float2(.07619100064,0);
    p.widthMin=bangs ? float2(.04761900008,1) : float2(0,.19047600031);
    p.width=bangs ? float2(.20000000298,0) : float2(.15000000596,.19523899257);
    p.noiseAbove=bangs ? float2(-.27000001073,1) : float2(-.15000000596,-.07999999821);
    p.noiseBelow=bangs ? float2(.40000000596,1) : float2(.15000000596,.07999999821);
    p.noiseFalloff=bangs ? float2(1,0) : float2(1,1);
    p.noiseScaleA=bangs ? .15714299679 : .60000002384;
    p.noiseOffsetA=bangs ? .80476200581 : 2.48595595360;
    p.noiseAmplitudeA=bangs ? 2.20000004768 : 1.20000004768;
    p.noiseScaleB=bangs ? 1.0 : .20000000298;
    p.noiseOffsetB=bangs ? 0.0 : .52380901575;
    p.noiseAmplitudeB=bangs ? 0.0 : 2.0;
    p.hmToonShift=bangs ? .20000000298 : .25;
    return p;
}

struct HairFeature5Coordinates
{
    float2 bandU;  // source _724,_725: HR row0 and row1 U
    float ndv;     // source _533: HR row3 U
    float3 hueRGB; // source _499..501, phase-driven color used by first band
    float toonGate;// source _1088, BEFORE .5 packing and BEFORE viewAO
};

float Hair5Pow(float x,float exponent)
{
    return x<=2.98023e-8 ? 0.0 : exp2(log2(x)*exponent);
}
float3 Hair5HueRotate(float3 color,float angle)
{
    // Original Rodrigues rotation about gray axis, constants preserved.
    float gray=dot(float3(.577350,.577350,.577350),color)*.577350;
    float3 difference=float3(color.z-color.y,color.x-color.z,color.y-color.x);
    return gray + (color-gray)*cos(angle) + difference*(sin(angle)*.577350);
}

HairFeature5Coordinates Hair5CoordinatesFromSamples(
    HairFeature5Params p,float2 hnRG,float4 hm,float noiseRawA,float noiseRawB,
    float baseAlpha,float3 N,float3 V,float3 L,
    float3 cameraRight,float3 cameraForward,float3 headUp)
{
    HairFeature5Coordinates o;
    // Source _427..501: hue mode is 1; exponent1, invert0, freq3,
    // coordinateMix1 cancels uv.x, phase=.9, hueStrength1, cb4[336] tint.
    float viewHue=dot(normalize(V+float3(0,0,1)),N);
    viewHue=saturate(Hair5Pow(abs(viewHue),1.0));
    float angle=(.89999997616+3.0*viewHue)*6.28319;
    o.hueRGB=Hair5HueRotate(float3(.58055502176,.52061802149,.921875),angle);
    // Source cb0[192..224] and [320..352] are WORLD->CAMERA direction matrices.
    // The camera-space Y is discarded for N only, not for V.
    float2 nPlane=float2(dot(N,cameraRight),dot(N,cameraForward));
    nPlane*=rsqrt(max(dot(nPlane,nPlane),1e-12));
    float2 vPlane=float2(dot(V,cameraRight),dot(V,cameraForward));
    float viewPlane=dot(nPlane,vPlane); // _521; no sat/abs and no normalize(vPlane)
    float cameraHead=dot(-cameraForward,headUp); // _531; not per-pixel -V
    o.ndv=saturate(dot(V,N));
    float2 bandPosition=hnRG.y-p.cameraShift*cameraHead+p.grazingShift*(1-o.ndv);
    float2 above=step(p.bandCenter,bandPosition);
    float2 noiseBlend=above*p.noiseSwitch+p.noiseBase;
    float n0=(noiseRawA*2-1)*p.noiseAmplitudeA;
    float n1=(noiseRawB*2-1)*p.noiseAmplitudeB;
    float2 noise=lerp(n0.xx,n1.xx,noiseBlend);
    float2 widthFactor=min(max(lerp((1-viewPlane).xx,viewPlane.xx,p.widthViewMix),p.widthMin),1);
    float2 delta=bandPosition-p.bandCenter;
    // Source performs exp2(log2(saturate(abs(delta)/width))) (exponent exactly1).
    // Bangs y width=0 and falloff=0: that inactive ratio contributes no attenuation.
    float2 attenuation=float2(1,1);
    if(p.noiseFalloff.x!=0)
        attenuation.x=1+(saturate(abs(delta.x)/p.width.x)-1)*p.noiseFalloff.x;
    if(p.noiseFalloff.y!=0)
        attenuation.y=1+(saturate(abs(delta.y)/p.width.y)-1)*p.noiseFalloff.y;
    float2 signedAmplitude=lerp(p.noiseBelow,p.noiseAbove,above);
    float2 numerator=delta+p.width*widthFactor+signedAmplitude*noise*attenuation;
    o.bandU=saturate(numerator/max(.0001,2*p.width*widthFactor));
    float hmShift=p.hmToonShift*Hair5Pow(hm.g,1.0);
    float h=.5+.5*dot(N,L)+hmShift;
    float q=saturate((h-.7+.03)/(.03+.03));
    float ao=saturate(baseAlpha/.4);
    o.toonGate=q*q*(3-2*q)*ao;
    return o;
}

struct HairFeature5Result
{
    float3 diffuse;       // source _1260..1262 -> GBuffer Target3, linear
    float3 additive;      // source _1240..1242 -> Target0, linear HDR contribution
    float3 unboundedBase; // source _1201..1203 for readback
    float2 bandU;
    float ndv;
    float toonGate;
};

HairFeature5Result Hair5ComposeFromSamples(
    float3 partitionBase,float4 hm,HairFeature5Coordinates c,
    float3 hrRow0,float3 hrRow1,float2 hrRow3)
{
    HairFeature5Result o;
    // cb4[1872].z=1: hue affects only first band. Third band does not feed output.
    float bandTriangle=1-saturate(abs(c.bandU.x-.5)*2);
    float3 hue=1+bandTriangle*(c.hueRGB-1);
    // cb4[1872].w=cb4[1888].x=0 chooses row3.R (not row3.G).
    // cb4[1888].z=0 chooses HM.R; .w=1 chooses HM.B.
    float mask0=hm.r*hrRow3.r;
    float mask1=hm.b*hrRow3.r;
    float gate0=lerp(.5,1.0,c.toonGate); // C752.x=.5, C736.x=1
    // Second band gate is constant1: C752.y=C736.y=1.
    // Exact source per-channel rule: raw HR>=.5 uses additive/screen branch.
    // cb4[2016].w=1 selects addition. Darker HR uses multiplicative branch.
    float3 multiply0=partitionBase*(1+mask0*(2*hrRow0*hue-1));
    float3 addition0=partitionBase+mask0*hue*(2*hrRow0-1)*gate0;
    float3 band0=lerp(multiply0,addition0,step(.5,hrRow0));
    float3 multiply1=band0*(1+mask1*(2*hrRow1-1));
    float3 addition1=band0+mask1*(2*hrRow1-1);
    float3 finalBase=lerp(multiply1,addition1,step(.5,hrRow1));
    o.unboundedBase=finalBase;
    // C2032.x=1 retains >1 overflow; C288/C1312/C1328 and override are0.
    o.additive=max(finalBase-1,0);
    // C2208.x=1; C2224.xy=0 (desaturations), z=1. Cloud controls are0.
    o.diffuse=saturate(finalBase);
    o.bandU=c.bandU;
    o.ndv=c.ndv;
    o.toonGate=c.toonGate;
    return o;
}

HairFeature5Result EvaluateHairFeature5(
    HairFeature5Params p,float3 partitionBase,float baseAlpha,float2 uv,
    float3 N,float3 V,float3 L,float3 cameraRight,float3 cameraForward,float3 headUp,
    Texture2D<float4> hnTexture,Texture2D<float4> hmTexture,
    Texture2D<float4> hairNoise,Texture2D<float4> hairHR,
    SamplerState linearClamp,SamplerState linearRepeat)
{
    N=normalize(N); V=normalize(V); L=normalize(L);
    // Source sampler mip bias=-.883835852; HN has mips; HM/HR/Noise one mip.
    float2 hn=hnTexture.SampleBias(linearClamp,uv,-.883835852).rg;
    float4 hm=hmTexture.SampleBias(linearClamp,uv,-.883835852);
    float n0=hairNoise.Sample(linearRepeat,float2(hn.r*p.noiseScaleA+p.noiseOffsetA,.5)).r;
    float n1=hairNoise.Sample(linearRepeat,float2(hn.r*p.noiseScaleB+p.noiseOffsetB,.5)).r;
    HairFeature5Coordinates c=Hair5CoordinatesFromSamples(p,hn,hm,n0,n1,baseAlpha,
        N,V,L,cameraRight,cameraForward,headUp);
    float3 hr0=hairHR.Sample(linearClamp,float2(c.bandU.x,1-.125)).rgb;
    float3 hr1=hairHR.Sample(linearClamp,float2(c.bandU.y,1-.375)).rgb;
    float2 hr3=hairHR.Sample(linearClamp,float2(c.ndv,1-.875)).rg;
    return Hair5ComposeFromSamples(partitionBase,hm,c,hr0,hr1,hr3);
}

// Integration: first get existing Feature1/2 Hair output h (shadow/toon unchanged).
// Evaluate feature5 with partitionBase=base.rgb, NOT with final lit color.
// h.diffuse=f5.diffuse;
// finalRGB=WuwaResolveToon(h.diffuse,h.shadow,h.toonPacked)+f5.additive;
// The source extra color is Target0, not another factor in shadow or Ramp UV.
#endif

