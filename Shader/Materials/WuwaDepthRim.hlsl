#ifndef WUWA_DEPTH_RIM_INCLUDED
#define WUWA_DEPTH_RIM_INCLUDED

// EID3621 PS0571, capture-active model12 branch only.
// Include URP Core.hlsl before this file if using the Unity convenience helpers.
// Keep N, V, rimL and camera axes in the SAME capture Z-up coordinate system.
// rimL is View[4848].xyz in the source, not implicitly the Toon main-light vector.
// The source rimL=(-.7094064951,-.4967318177,.5) is consumed without normalization.
// Base color is the resolved material diffuse before Toon lighting, not final lit RGB.
// Return value is added after Toon lighting, alongside (not multiplied into) emission.

float WuwaRimCubic(float x)
{
    x = saturate(x);
    return x*x*(3.0-2.0*x);
}

float3 WuwaRimCubic3(float3 x)
{
    x = saturate(x);
    return x*x*(3.0-2.0*x);
}

// PS0939 L2893-2920 and L2970-2977: normalize, oct fold, [-1,1] to [0,1].
// The z==0 case follows the folded branch, matching source (_2950 > 0).
float2 WuwaRimEncodeOct(float3 captureN)
{
    float3 n = normalize(captureN);
    float2 p = n.xy / (abs(n.x)+abs(n.y)+abs(n.z));
    float2 signNotZero = float2(p.x < 0.0 ? -1.0 : 1.0,
                               p.y < 0.0 ? -1.0 : 1.0);
    float2 folded = (1.0-abs(p.yx))*signNotZero;
    float foldWeight = n.z > 0.0 ? 0.0 : 1.0;
    return (p+(folded-p)*foldWeight)*0.5+0.5;
}

// RT1=R10G10B10A2_UNORM. This is the storage conversion, not an extra effect.
float2 WuwaRimQuantizeOct10(float2 encoded)
{
    return round(saturate(encoded)*1023.0)/1023.0;
}

// PS0571 L132-165, then L233-236. Do not use a different oct-fold convention.
float3 WuwaRimDecodeOct(float2 encoded)
{
    float2 p = 2.0*encoded-1.0;
    float z = 1.0-abs(p.x)-abs(p.y);
    float t = max(-z,0.0);
    float2 unfoldSign = float2(p.x < 0.0 ? 1.0 : -1.0,
                              p.y < 0.0 ? 1.0 : -1.0);
    float3 n = normalize(float3(p+t*unfoldSign,z));
    return normalize(n); // Source consumer normalizes once more after its phi.
}

float3 WuwaRimCapturedNormal(float3 captureN)
{
    return WuwaRimDecodeOct(WuwaRimQuantizeOct10(WuwaRimEncodeOct(captureN)));
}

// RT6.r is an 8-bit UNorm channel. Primary materials .05 -> 13/255;
// BangsSmooth m=1 -> 1; Eye m=0 -> 0. No additional m==0 gate exists in source.
float WuwaRimCapturedMaterialParameter(float materialParameter)
{
    return round(saturate(materialParameter)*255.0)/255.0;
}

struct WuwaDepthRimSample
{
    // Viewport UV has positive Y UP. Source sampled texture coordinates are Y DOWN,
    // so source float2(1,-.5) becomes float2(1,+.5) here. Flip once at texture lookup.
    float2 offsetViewportUVYUp;
    float depthThresholdCm;
    float depthSoftWidthCm;
    float currentDepthCm;
    float3 colorBeforeDepthEdge;
};

WuwaDepthRimSample WuwaPrepareDepthRim(
    float3 captureN,
    float3 captureV,
    float3 captureRimL,
    float3 captureCameraRight,
    float3 captureCameraUp,
    float3 baseColor,
    float materialParameter,
    float viewDepthMeters,
    float horizontalFovRadians,
    float screenShadow)
{
    WuwaDepthRimSample result;
    float3 N = WuwaRimCapturedNormal(captureN);
    float3 V = normalize(captureV);
    float3 L = captureRimL;
    float m = WuwaRimCapturedMaterialParameter(materialParameter);
    float z = viewDepthMeters*100.0;
    float a = saturate(m-.1);
    float b = saturate(10.0*m);
    float width = 2.0*a+.8*b*.5; // Globals[0].x=.5
    result.depthThresholdCm = 1000.0*a;
    result.depthSoftWidthCm = 2000.0*a+50.0;
    result.currentDepthCm = z;

    float nl = dot(L,N);
    float lit = WuwaRimCubic((nl+.2)*5.0);
    float3 H = normalize(V+L);
    float h = saturate(dot(N,H));
    float h2 = h*h;
    float spec = .3/((3.14159-2.51327*h2)*(1.0-.8*h2));
    float lv = dot(L,V);
    float back = 1.0+WuwaRimCubic((-.5-lv)*2.0);
    float grazing = saturate(.8-saturate(dot(V,N)));

    float fov = clamp(horizontalFovRadians,0.0,1.74533)*.572958;
    float z0 = max(z,0.0);
    float distanceCurve = pow((3000.0-min(z0,3000.0))*.000333333,8.0)
                        +(50.0-min(z0,50.0))*.02-1.0;
    float distanceScale = 1.0+fov*distanceCurve*(1.0-a);
    float offsetScale = (.00375*(nl+1.0)+.0075)*grazing*back*distanceScale;
    float2 nViewXY = float2(dot(N,captureCameraRight),dot(N,captureCameraUp));
    float2 nOffset = normalize(nViewXY+.0001);
    result.offsetViewportUVYUp = nOffset*float2(1.0,.5)*width*offsetScale;

    // screenShadow=(Resource440.r*Resource440.b)^2*View[4592].z; source scale=1.
    float amplitude = ((.32*lit+.08)*(1.0-lv)+lit*screenShadow*spec)
                      *(.5*screenShadow+.5);
    float3 lightColor = float3(2.5999999046,3.4546399117,4.0); // View[4832]
    float luminance = dot(lightColor,float3(.3,.59,.11));
    float3 desaturated = luminance+.75*(lightColor-luminance);
    float3 rimLight = lerp(desaturated,lightColor,screenShadow)*amplitude;
    // View[4784].z=1 selects colorB exactly; Globals[16].rgb=(1,1,1).
    float3 rimColor = .1*baseColor*rimLight*(1.0+14.0*WuwaRimCubic3(1.0-1.2*baseColor));
    float farFade = (5000.0-min(max(z-10000.0,0.0),5000.0))*.0002;
    result.colorBeforeDepthEdge = farFade*rimColor;
    return result;
}

// Use the CURRENT Unity perspective camera _ZBufferParams for a Unity-device-depth RT.
// The texture stores raw device depth in R16_FLOAT; sample it with linear clamp FIRST.
// Do not reconstruct the neighboring depths before filtering, and do not compare raw Z.
float3 WuwaFinishDepthRim(WuwaDepthRimSample rim, float sampledRawDepth, float4 zBufferParams)
{
    float sampledDepthCm = rcp(zBufferParams.z*sampledRawDepth+zBufferParams.w)*100.0;
    float deltaCm = max(sampledDepthCm-rim.currentDepthCm,.0001);
    float edge = saturate(WuwaRimCubic((deltaCm-rim.depthThresholdCm)/rim.depthSoftWidthCm));
    return edge*rim.colorBeforeDepthEdge;
}

// signedViewportToTextureScale maps a Y-up viewport-UV displacement to texture UV.
// For a full-sized RT it is (1,+1) when texture V points up, (1,-1) when V points down.
// For source-sized padding it also includes viewportSize/textureSize, e.g. 1281/1284.
// textureUV is the CURRENT surface pixel UV in that same depth-RT texture convention.
float2 WuwaDepthRimTextureUV(float2 textureUV, float2 signedViewportToTextureScale,
                           WuwaDepthRimSample rim)
{
    return textureUV+rim.offsetViewportUVYUp*signedViewportToTextureScale;
}

// Convenience functions for the active perspective Unity camera. No radial-distance
// substitute: the source distance is view-axis depth. Runtime camera FOV remains live.
float WuwaRimViewDepthMeters(float3 positionWS)
{
    return -mul(UNITY_MATRIX_V,float4(positionWS,1.0)).z;
}

// View[2128].x=.8726645112 is HORIZONTAL FOV: source projection X scale
// 2.144506931 gives 2*atan(1/2.144506931)=.8726645112. Its Y angle is .5130384564.
float WuwaRimHorizontalFovRadians()
{
    return 2.0*atan(rcp(abs(UNITY_MATRIX_P._m00)));
}

// Integration order:
// 1. Prepare with source-material normal and capture-space camera axes.
// 2. uv=WuwaDepthRimTextureUV(currentDepthTextureUV,signedScale,rim).
// 3. raw=SAMPLE_TEXTURE2D(_WuwaCharacterRawDepth,sampler_LinearClamp,uv).r.
// 4. lit += WuwaFinishDepthRim(rim,raw,_ZBufferParams).
// Model13 outlines bypass this helper. Main model12 is additive; do not add model15's
// separate multiplication branch to the captured material implementation.

float3 WuwaEvaluateDepthRim(float3 captureN,float3 captureV,float3 baseColor,
                           float3 positionWS,float4 fragmentPosition,float materialParameter)
{
    float3 cameraRight=WuwaWorldToCapture(UNITY_MATRIX_V[0].xyz);
    float3 cameraUp=WuwaWorldToCapture(UNITY_MATRIX_V[1].xyz);
    WuwaDepthRimSample rim=WuwaPrepareDepthRim(captureN,captureV,
        float3(-.7094064951,-.4967318177,.5),cameraRight,cameraUp,baseColor,
        materialParameter,WuwaRimViewDepthMeters(positionWS),WuwaRimHorizontalFovRadians(),1.0);
    float2 scale=_WuwaCharacterDepthScale.xy;
    float2 signedScale=scale;
    signedScale.y*=sign(UNITY_MATRIX_P._m11);
#if UNITY_UV_STARTS_AT_TOP
    signedScale.y*=_ScaleBiasRt.x;
#endif
    float2 uv=GetNormalizedScreenSpaceUV(fragmentPosition)*scale;
    uv=WuwaDepthRimTextureUV(uv,signedScale,rim);
    float rawDepth=SAMPLE_TEXTURE2D_X(_WuwaCharacterRawDepth,sampler_LinearClamp,uv).r;
    return WuwaFinishDepthRim(rim,rawDepth,_ZBufferParams);
}
#endif
