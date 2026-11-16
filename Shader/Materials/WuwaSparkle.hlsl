#ifndef WUWA_CAPTURE_SPARKLE_INCLUDED
#define WUWA_CAPTURE_SPARKLE_INCLUDED
// lili.rdc: Up PS0942, Down PS0945, Alpha PS1281. Cloth PS0939 has no sparkle branch.
// Caller declares _AlphaSparkle and sampler_LinearRepeat. Source texture: 9118,
// linear UNorm, 256x256, one mip. Each sample converts source top-down texture V.
// Input UVs and V are source conventions; V is normalized capture Z-up view direction.
float3 WuwaSparkleRGB(float2 sourceUV,float3 V,float3 basePartition,float gate,
                     float scale,float speed,float distanceFactor,float hueStrength,
                     float threshold,float3 tint,float sourceTime)
{
    float2 uv=sourceUV*scale;
    float2 sample0=SAMPLE_TEXTURE2D_LOD(_AlphaSparkle,sampler_LinearRepeat,
                                      float2(uv.x,1.0-uv.y),0).rg;
    float2 uv1=uv+V.xy*.2+.4+float2(0,speed*sourceTime);
    float2 sample1=SAMPLE_TEXTURE2D_LOD(_AlphaSparkle,sampler_LinearRepeat,
                                      float2(uv1.x,1.0-uv1.y),0).rg;
    float active=sample0.x*sample0.x*sample1.x*distanceFactor < threshold ? 0.0:1.0;
    float3 c=basePartition*tint*active;
    float theta=sample0.y*sample0.y*6.28319*sample1.y*hueStrength*distanceFactor;
    float average=dot(float3(.577350,.577350,.577350),c)*.577350;
    float3 differences=float3(c.z-c.y,c.x-c.z,c.y-c.x);
    float3 rotated=(c-average)*cos(theta)+average+
                   (.577350*sin(theta))*differences;
    // Captured intensity blend cb4[1824/2208/1952].w=0; source intensity is 32.23.
    return rotated*(distanceFactor*gate*32.2300);
}

float3 WuwaAlphaSparkleRGB(float2 sourceUV2,float3 V,float3 basePartition,float gate)
{
    return WuwaSparkleRGB(sourceUV2,V,basePartition,gate,13.0,0.0,5.0,
        .0299999993,.300000012,float3(.911687016,.776041985,1.0),0.0);
}

// sourceTime: source cb0[2368].z, captured 838.5994873 seconds.
// cameraAnchorDistance: source centimeters from camera to Primitive*(0,0,80,1).
// Variant matches BodyMatCap: Cloth=0, Up=1, Down=2, Alpha=3.
float3 WuwaBodySparkle(float variant,float2 sourceUV0,float2 sourceUV2,float3 V,
                      float3 basePartition,float gate,float sourceTime,
                      float cameraAnchorDistance)
{
    if(variant<.5) return 0.0;
    float distanceFactor=1.0+2.0*saturate(cameraAnchorDistance*.001);
    if(variant<1.5)
        return WuwaSparkleRGB(sourceUV0,V,basePartition,gate,9.0,0.0,distanceFactor,
            .0299999993,.0599999987,float3(1,1,1),sourceTime);
    if(variant<2.5)
        return WuwaSparkleRGB(sourceUV0,V,basePartition,gate,20.0,-.0299999993,
            distanceFactor,0.0,.00499999989,float3(1,.947306991,.590619028),sourceTime);
    return WuwaAlphaSparkleRGB(sourceUV2,V,basePartition,gate);
}
#endif
