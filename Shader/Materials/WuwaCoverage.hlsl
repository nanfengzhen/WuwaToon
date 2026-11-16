#ifndef WUWA_CAPTURE_COVERAGE8_INCLUDED
#define WUWA_CAPTURE_COVERAGE8_INCLUDED
// Include feature7-eye.hlsl first: shared Eye7HeightIntersection and Eye7TextureUV.
// All UVs / TBN are SOURCE conventions; no implicit bitangent sign assumption.
// eyeEM is shared T_HDMF_EM (313032), sRGB, bilinear + clamp, point mip.
// het is Face_HET or Eye_HET, sRGB, bilinear + repeat, point mip.
// Sampler mip bias=0; explicit sample bias below matches capture.
float2 Coverage8HETUV(float2 sourceUV, bool eye,
    float3 sourceT, float3 sourceB, float3 sourceN, float3 sourceView,
    Texture2D<float4> eyeEM, SamplerState emSampler)
{
    float2 offset=0;
    if(eye)
    {
        // Unlike full-eye shading, HET uses NO view bias and depth=.15.
        float3 viewTS=float3(dot(sourceView,sourceT),dot(sourceView,sourceB),dot(sourceView,sourceN));
        offset=Eye7HeightIntersection(sourceUV,viewTS,viewTS.z,.150000005960,eyeEM,emSampler);
    }
    float sharedAlpha=eyeEM.SampleBias(emSampler,Eye7TextureUV(sourceUV),-.883835852146).a;
    float t=saturate((.9-sharedAlpha)*1.42857);
    float scale=lerp(1.0,.800000011921,t*t*(3.0-2.0*t));
    return (sourceUV+offset-.5)*scale+.5;
}
void Coverage8ClipHET(float2 sourceHETUV,Texture2D<float4> het,SamplerState hetSampler)
{
    float red=het.SampleBias(hetSampler,Eye7TextureUV(sourceHETUV),-.883835852146).r;
    clip(red-.3333);
}
float Coverage8BangsAlpha(float ftmRed)
{
    float t=saturate(ftmRed);
    return t*t*(3.0-2.0*t);
}
// FTM sample remains SampleLevel -0.883835852146 with linear+repeat/point mip.
// Composite this diffuse before lighting, preserving hair's other material data:
float3 Coverage8CompositeDiffuse(float3 underDiffuse,float3 bangsDiffuse,float ftmRed)
{
    return lerp(underDiffuse,bangsDiffuse,Coverage8BangsAlpha(ftmRed));
}
#endif
