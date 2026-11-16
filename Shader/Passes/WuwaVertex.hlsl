#ifndef WUWA_VERTEX_INCLUDED
#define WUWA_VERTEX_INCLUDED
#include "../Core/WuwaInput.hlsl"
struct WuwaAttributes {float4 positionOS:POSITION;float3 normalOS:NORMAL;float4 tangentOS:TANGENT;float2 uv:TEXCOORD0;float2 sdfUV:TEXCOORD1;float2 alphaUV:TEXCOORD2;float4 color:COLOR;};
struct WuwaVaryings {float4 positionCS:SV_POSITION;float3 positionWS:TEXCOORD0;float3 normalWS:TEXCOORD1;float2 uv:TEXCOORD2;float2 sdfUV:TEXCOORD3;float4 tangentWS:TEXCOORD4;float2 alphaUV:TEXCOORD5;float eyeGreen:TEXCOORD6;};
WuwaVaryings WuwaVertex(WuwaAttributes input) {
    WuwaVaryings o; VertexPositionInputs p=GetVertexPositionInputs(input.positionOS.xyz);
    o.positionCS=p.positionCS;o.positionWS=p.positionWS;
    o.normalWS=TransformObjectToWorldNormal(input.normalOS);
    o.tangentWS=float4(TransformObjectToWorldDir(input.tangentOS.xyz),input.tangentOS.w*GetOddNegativeScale());
    o.uv=TRANSFORM_TEX(input.uv,_BaseMap);o.sdfUV=input.sdfUV;o.alphaUV=input.alphaUV;o.eyeGreen=input.color.g;return o;
}
// Unity tangents follow the imported V=1-sourceV; recover the source B direction.
float3 WuwaSourceBitangent(WuwaVaryings input) {
    return -cross(normalize(input.normalWS),normalize(input.tangentWS.xyz))*input.tangentWS.w;
}
#endif
