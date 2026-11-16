#ifndef WUWA_OUTLINE_INCLUDED
#define WUWA_OUTLINE_INCLUDED
#include "WuwaVertex.hlsl"

struct WuwaOutlineVaryings
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float vertexAlpha : TEXCOORD1;
};

float3 WuwaOutlineDirection(WuwaAttributes input, float3 N, float3 T)
{
    // Signed octahedral coordinates: source UV1 is not remapped from [0,1].
    float2 u = float2(input.sdfUV.x, 1.0-input.sdfUV.y);
    float z = 1.0-abs(u.x)-abs(u.y);
    float t = saturate(-z);
    float2 q = u+float2(u.x>=0 ? -t:t, u.y>=0 ? -t:t);
    float3 B = -cross(N,T)*input.tangentOS.w*GetOddNegativeScale();
    return normalize(T*q.x+B*q.y+N*z);
}

WuwaOutlineVaryings WuwaOutlineVertex(WuwaAttributes input)
{
    WuwaOutlineVaryings o;
    float3 p = TransformObjectToWorld(input.positionOS.xyz);
    float3 N = TransformObjectToWorldNormal(input.normalOS);
    float3 T = TransformObjectToWorldDir(input.tangentOS.xyz);
    float3 direction = WuwaOutlineDirection(input,N,T);
    float4 pCS = TransformWorldToHClip(p);
    float2 projected = mul((float3x3)UNITY_MATRIX_VP,direction).xy;
    projected *= rsqrt(max(dot(projected,projected),1e-12));
    float invXX = abs(UNITY_MATRIX_I_P._m00);
    float invYY = abs(UNITY_MATRIX_I_P._m11);
    float fovFix = .767327/invYY;
    float aspectFix = invYY/(invXX*.5625);
    float3 objectScale = float3(length(unity_ObjectToWorld._m00_m10_m20),
        length(unity_ObjectToWorld._m01_m11_m21),length(unity_ObjectToWorld._m02_m12_m22));
    float2 d = _OutlineWidth*input.color.g*objectScale.xy*projected*.001*fovFix*aspectFix;
    float2 pixelStep = 2*pCS.w/_ScaledScreenParams.xy*.667;
    float2 ratio = saturate(abs(d)/(_OutlineSmooth*.1*pixelStep));
    float2 cubic = ratio*ratio*(3-2*ratio);
    float2 magnitude = lerp(abs(d),min(max(abs(d),pixelStep),999*pixelStep),cubic);
    d = float2(d.x>0 ? 1:-1,d.y>0 ? 1:-1)*magnitude;
    float3 deltaWS = mul(UNITY_MATRIX_I_VP,float4(d,0,0)).xyz;
    // Ordinary captured variants: -0.01 * B * 500 * .5 source centimetres.
    p += deltaWS+GetWorldSpaceNormalizeViewDir(p)*(-.025*input.color.b);
    o.positionCS = TransformWorldToHClip(p);
    o.uv = TRANSFORM_TEX(input.uv,_BaseMap);
    o.vertexAlpha = input.color.a;
    return o;
}

float4 WuwaOutlineFragment(WuwaOutlineVaryings input) : SV_Target
{
    clip(_OutlineEnabled-.5);
    if (_BodyMatCapVariant>2.5) clip(input.vertexAlpha-.3333);
    float3 color = _OutlineColor.rgb;
    if (_OutlineTextured>.5) {
        // Source sampler: bilinear within a mip, nearest mip, Repeat, captured bias.
        float lod=_BaseMap.CalculateLevelOfDetailUnclamped(sampler_LinearRepeat,input.uv)-.883835852;
        color *= SAMPLE_TEXTURE2D_LOD(_BaseMap,sampler_LinearRepeat,input.uv,round(max(lod,0))).rgb;
    }
    // PS0571 shading model 13 bypasses the toon and depth-rim branches.
    return float4(max(_ToonDarkColor.rgb*color,0),1);
}
#endif
