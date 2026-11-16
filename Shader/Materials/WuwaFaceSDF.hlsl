#ifndef WUWA_FACE_SDF_INCLUDED
#define WUWA_FACE_SDF_INCLUDED
// PS0793 _1318..1386: A is head BACK, B is the physical high-U side.
// Both axes and the direction toward the light use the capture coordinate basis.
// The head-bone driver supplies current world axes; the forward pass converts them.
void FHFaceSDFCoordinates(float2 uv, float3 L, float3 axisA, float3 axisB,
                          out float2 sdfUV, out float theta)
{
    float2 headLight = WuwaNormalizePlane(float2(dot(L,axisA),dot(L,axisB)));
    theta = (1.0-headLight.x)*0.5;
    sdfUV = float2(headLight.y>0.0 ? uv.x : 1.0-uv.x,uv.y);
}
#endif
