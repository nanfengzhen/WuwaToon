#ifndef WUWA_TOON_LIGHTING_INCLUDED
#define WUWA_TOON_LIGHTING_INCLUDED
// EID 3621 PS0571. Resource440 was replayed as RGBA=(1,1,1,1).
// Captured local light count is zero and exposure is one. Depth rim is resolved separately.
float WuwaCubic(float x) { x=saturate(x); return x*x*(3-2*x); }
float3 WuwaResolveToon(float3 baseColor,float3 shadowColor,float packedToon) {
    float3 B=baseColor;
    float3 R=saturate(shadowColor); // Direct value: omit GBuffer sqrt/square storage roundtrip.
    float3 dark=_ToonDarkColor.rgb;
    float separation=WuwaCubic(10*dot(abs(1-dark),float3(.3,.59,.11)));
    float t=WuwaCubic(2*packedToon-1)*separation;
    float3 aoPolynomial=((B*2.0404-.3324)+(.6417-B*4.7951))+(B*2.7552+.6903);
    float3 darkBase=dark*B*(.7+.3*WuwaCubic(2*packedToon))*max(1.0.xxx,aoPolynomial);
    return max(lerp(darkBase+.5*R*B,B,t),0);
}
#endif
