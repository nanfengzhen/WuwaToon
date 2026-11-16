#ifndef WUWA_RAMP_INCLUDED
#define WUWA_RAMP_INCLUDED
// Capture coordinates start at the PNG top row; Unity imports PNGs bottom-up.
// Mesh UVs are already converted by the model export. Procedural LUT UVs are not.
float3 WuwaSampleSkin(float2 captureUV) {
    return SAMPLE_TEXTURE2D_BIAS(_SkinRamp,sampler_LinearClamp,float2(captureUV.x,1-captureUV.y),-.883835852).rgb;
}
#endif
