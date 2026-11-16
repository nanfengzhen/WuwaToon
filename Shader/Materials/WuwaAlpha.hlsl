#ifndef WUWA_CAPTURE_ALPHA_INCLUDED
#define WUWA_CAPTURE_ALPHA_INCLUDED
// lili.rdc EID 2721 PS1281. Noise texture must be linear, repeat, bilinear,
// one mip. Its imported PNG has the same rows as the source RenderDoc export.
// coverageLuminance is max of source branch RGB luminances _1551/3/5 and
// _1372/6/80. It is a coverage input only; do not add it to visible emission.
float WuwaAlphaCoverage(float ftmR, float coverageLuminance)
{
    float x=saturate(max(ftmR,coverageLuminance));
    return x*x*(3.0-2.0*x);
}
float2 WuwaAlphaTopLeftPixel(float2 fragmentPosition)
{
    #if !UNITY_UV_STARTS_AT_TOP
        fragmentPosition.y=_ScaledScreenParams.y-fragmentPosition.y;
    #endif
    return fragmentPosition;
}
float WuwaAlphaClipValue(float ftmR,float coverageLuminance,float2 topLeftPixel,
                         float noiseR)
{
    // uint casts truncate the positive pixel-center coordinates. Capture
    // cb0[2528].x=6; view rect cb0[2144].xy=(0,0).
    uint2 tilePixel=(uint2)(topLeftPixel+6.0);
    uint tile=(tilePixel.x+2u*tilePixel.y)%5u;
    return WuwaAlphaCoverage(ftmR,coverageLuminance)-0.833300+
           (noiseR+(float)tile)*0.166667;
}
void WuwaApplyAlphaClip(float ftmR,float coverageLuminance,float2 fragmentPosition)
{
    float2 p=WuwaAlphaTopLeftPixel(fragmentPosition);
    // Source pixel coordinate convention is top-left. Unity PNG texture
    // coordinates increase upward, hence this flip affects the sample only.
    float2 uv=float2(p.x/64.0,1.0-p.y/64.0);
    float noise=SAMPLE_TEXTURE2D_LOD(_AlphaNoise,sampler_LinearRepeat,uv,0).r;
    clip(WuwaAlphaClipValue(ftmR,coverageLuminance,p,noise));
}
float3 WuwaAlphaFaceNormal(float3 detailedNormal,bool isFrontFace)
{
    // Source _357=View[2352].w*Primitive[64].w*faceSign; both CB values=1.
    // Multiply the final detail normal, preserving the unflipped geom normal.
    return detailedNormal*(isFrontFace ? 1.0:-1.0);
}
#endif
