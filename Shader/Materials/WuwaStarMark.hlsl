#ifndef WUWA_CAPTURE_STAR_MARK_INCLUDED
#define WUWA_CAPTURE_STAR_MARK_INCLUDED
// EID2691 / PS0945: t4 Star (sRGB).
// Captured cb4[1744].xz=0, cb4[1792].x=0: retain the base mask,
// omit the zero-weight pulse. cb4[400/480].rgb=0 only removes emission;
// PS _1950.._1959 still blends the diffuse result towards black.
float WuwaStarMarkMask(float2 sourceUV0)
{
    float2 uv=(sourceUV0-.5)*float2(15.1175537109375,11.0)+.5
              -float2(-1.0400300025939941,-2.4800000190734863);
    float4 star=SAMPLE_TEXTURE2D_BIAS(_StarMark,sampler_LinearClamp,
                                     float2(uv.x,1.0-uv.y),-.883835852);
    // Captured cb4[1744].w=-.2: the G threshold is -.1-offset,
    // offset=.009524-noise*.057143. UNorm noise in [0,1] makes the
    // threshold <=-.052381, while Star.G>=0, so PS _838 is always zero.
    // The active mask is static: no SoundNoise or time sample is needed.
    float mark=1.0-star.r;
    float inside=(uv.x>=.01 && uv.x<=.99 && uv.y>=.01 && uv.y<=.99) ? 1.0:0.0;
    // PS _925=1: captured cb4[1792].w=cb4[1808].y=0.
    return saturate(mark*star.a*inside);
}
#endif
