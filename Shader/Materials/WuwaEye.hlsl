#ifndef WUWA_CAPTURE_EYE_FEATURE7_INCLUDED
#define WUWA_CAPTURE_EYE_FEATURE7_INCLUDED

// lili.rdc EID 2741 / PS 0814. Active capture specialization, before toon resolve.
// Input coordinates/basis are SOURCE coordinates. See feature7-derivation.md.
// PNG textures retain their image orientation: convert source V only at sampling.
float2 Eye7TextureUV(float2 sourceUV) { return float2(sourceUV.x, 1.0-sourceUV.y); }
float Eye7Smooth01(float x) { x=saturate(x); return x*x*(3.0-2.0*x); }

struct Eye7Result
{
    float3 diffuse;
    float3 maskEmission;
    float4 parallaxBase; // alpha feeds existing eye toon AO, not opacity
    float2 sourceParallaxUV;
    float2 sourceMaskUV;
    float2 sourceRayOffset;
};

float2 Eye7HeightIntersection(float2 sourceUV, float3 viewTS, float viewNormal,
    float rayDepth, Texture2D<float4> eyeEM, SamplerState emSampler)
{
    // PS _415..499. Reciprocal is of the FLOAT count, not floor(count).
    float count=4.0+4.0*saturate(abs(viewNormal));
    float dh=rcp(count);
    float2 ray=-viewTS.xy/viewTS.z*rayDepth;
    float2 stepUV=ray*dh;
    float2 dx=ddx_coarse(sourceUV)*float2(1,-1);
    float2 dy=ddy_coarse(sourceUV)*float2(1,-1);
    float2 offset=0;
    float rayHeight=1.0, previousRayHeight=1.0, previousHeight=1.0;
    int limit=(int)floor(count)+2;
    [loop] for(int i=0;i<limit;++i)
    {
        float height=eyeEM.SampleGrad(emSampler,Eye7TextureUV(sourceUV+offset),dx,dy).g;
        if(rayHeight<height)
        {
            // Linear intersection between the last two ray/height samples.
            float refinement=(height-rayHeight)/
                (previousRayHeight-rayHeight-previousHeight+height);
            return offset-refinement*stepUV;
        }
        previousRayHeight=rayHeight;
        previousHeight=height;
        rayHeight-=dh;
        offset+=stepUV;
    }
    return offset;
}

Eye7Result EvaluateEyeFeature7(float2 sourceUV, float vertexGreen,
    float3 sourceT, float3 sourceB, float3 sourceGeomN, float3 sourceView,
    Texture2D<float4> eyeEG, SamplerState egSampler,
    Texture2D<float4> eyeEM, SamplerState emSampler,
    Texture2D<float4> eyeBase, SamplerState baseSampler, bool enableParallax)
{
    Eye7Result o;
    const float bias=-0.8838358521461487;
    // PS _306,_320 are zero in this capture: animated motion amplitudes are zero.
    // PS _289..355: scale then rotate around a per-eye center, not atlas UV.
    float2 center=lerp(float2(.154999002814,.474287003279),
                       float2(.154999002814,.464763015509),vertexGreen)+float2(.05,0);
    float2 maskLocal=(sourceUV-center)/float2(.195165887475,.172904610634);
    float sn,cs;
    sincos(6.508337020874,sn,cs);
    o.sourceMaskUV=float2(cs*maskLocal.x-sn*maskLocal.y,
                         sn*maskLocal.x+cs*maskLocal.y)+.5;
    float3 mask=eyeEG.SampleBias(egSampler,Eye7TextureUV(o.sourceMaskUV),bias).rgb;

    // PS _368..415: EM.r drives added color, EM.g is POM height, EM.a gates it.
    float2 glowUV=(sourceUV-float2(.480951994658,.542858004570)) /
                  float2(.933951020241,.862639009953)+.5;
    float glowR=eyeEM.SampleBias(emSampler,Eye7TextureUV(glowUV),bias).r;
    float4 em=eyeEM.SampleBias(emSampler,Eye7TextureUV(sourceUV),bias);
    float glow=glowR*Eye7Smooth01((1.0-em.a)/.430952012539);
    float3 glowColor=float3(2.954217910767,2.46875,3.0)*(.050000000745*glow);

    // PS _416..445: source B=cross(N,T)*VS TEXCOORD11.w.
    // Both endpoints of the COLOR.g interpolation are (0,-.2,0) in the capture.
    float3 viewTS=float3(dot(sourceView,sourceT),dot(sourceView,sourceB),
                        dot(sourceView,sourceGeomN))+float3(0,-.200000002980,0);
    o.sourceRayOffset=0;
    if(enableParallax) o.sourceRayOffset=Eye7HeightIntersection(sourceUV,viewTS,
        dot(sourceView,sourceGeomN),.10000000149*(1.0-em.g),eyeEM,emSampler);
    float irisScale=lerp(1.0,.800000011921,Eye7Smooth01((.9-em.a)*1.428571428571));
    o.sourceParallaxUV=(sourceUV+o.sourceRayOffset-.5)*irisScale+.5;
    o.parallaxBase=eyeBase.SampleBias(baseSampler,Eye7TextureUV(o.sourceParallaxUV),bias);
    float3 baseColor=o.parallaxBase.rgb+glowColor;

    // PS _547..632: separate procedural disk/ring. The animated scale switch is off.
    float2 ringLocal=sourceUV-float2(.797618985176,.632048010826);
    float2 ringRotated=float2(dot(ringLocal,float2(-.999552249908,.029922397807)),
                             dot(ringLocal,float2(-.029922397807,-.999552249908)));
    float radius=length(ringRotated*float2(8.699999809265,15.433173179626));
    float disk=saturate(100000.0-200000.0*radius);
    float foldedRing=1.0-abs(2.0*(saturate(1.88679-2.90276*radius)-.5));
    float ring=Eye7Smooth01((foldedRing-.512000083923)/(.820000052452-.512000083923));
    float3 procedural=baseColor+disk+ring*(1.0-baseColor-disk);

    // PS _633..669: independent R/G layers, then 40% original-color restoration.
    float3 redLayer=lerp(procedural,float3(.502685010433,.512440979481,.517708003521),mask.r);
    float3 greenLayer=lerp(redLayer,float3(.039546001703,.023152999580,.234550997615),mask.g);
    o.diffuse=lerp(greenLayer,baseColor,.400000005960);
    // _367 -> _755,_760,_765 is the surviving active additive mask branch.
    o.maskEmission=(mask.b*(1.0-.400000005960)).xxx;
    return o;
}
#endif
