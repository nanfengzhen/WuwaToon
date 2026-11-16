using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Wuwa.Rendering
{
    // Captured order: underlying face/eye -> projected bangs shadow -> HET -> Bangs opaque -> Hair -> Bangs smooth.
    public sealed class WuwaHairCoverageFeature : ScriptableRendererFeature
    {
        public bool enableProjectedShadow = true;
        public bool enableHET = true;
        public bool enableSmooth = true;
        private readonly List<SkinnedMeshRenderer> actors = new List<SkinnedMeshRenderer>();
        private CoveragePass pass;
        private SceneShadowReceivePass sceneShadowReceivePass;

        public override void Create()
        {
            if (pass != null) pass.Dispose();
            if (sceneShadowReceivePass != null) sceneShadowReceivePass.Dispose();
            pass = new CoveragePass(actors);
            sceneShadowReceivePass = new SceneShadowReceivePass(actors);
        }

        private static bool Accept(in CameraData data)
        {
            return data.renderType == CameraRenderType.Base &&
                (data.cameraType == CameraType.Game || data.cameraType == CameraType.SceneView);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData data)
        {
            actors.Clear();
            Shader.SetGlobalVector("_WuwaSceneReceiveShadowParams", Vector4.zero);
            if (!Accept(data.cameraData)) return;
            var camera = data.cameraData.camera;
            foreach (var driver in Object.FindObjectsOfType<WuwaFaceSDFDriver>())
            {
                var actor = driver.GetComponent<SkinnedMeshRenderer>();
                if (!driver.isActiveAndEnabled || actor == null || !actor.enabled || actor.forceRenderingOff ||
                    !actor.gameObject.activeInHierarchy || actor.sharedMesh == null ||
                    (camera.cullingMask & (1 << actor.gameObject.layer)) == 0) continue;
                var materials = actor.sharedMaterials;
                if (materials.Length != 8 || actor.sharedMesh.subMeshCount != 8) continue;
                bool ready = true;
                foreach (var material in materials)
                {
                    if (material == null || material.shader == null || material.shader.name != "Wuwa/Character/PartitionToonRamp" ||
                        material.FindPass("HETDepthStencil") < 0) { ready = false; break; }
                }
                if (!ready || materials[0].GetFloat("_CoverageEnabled") < .5f || materials[1].GetFloat("_CoverageEnabled") < .5f) continue;
#if UNITY_EDITOR
                // CommandBuffer pass indices cannot target Unity's temporary async-loading shader.
                foreach (var material in materials)
                    for (int index = 0; index < material.passCount; ++index)
                        if (!UnityEditor.ShaderUtil.IsPassCompiled(material, index))
                            UnityEditor.ShaderUtil.CompilePass(material, index, true);
#endif
                actors.Add(actor);
            }
            if (actors.Count == 0) return;
            if (data.shadowData.supportsMainLightShadows && data.lightData.mainLightIndex >= 0)
                renderer.EnqueuePass(sceneShadowReceivePass);
            pass.enableProjectedShadow = enableProjectedShadow;
            pass.enableHET = enableHET;
            pass.enableSmooth = enableSmooth;
            renderer.EnqueuePass(pass);
        }

        public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData data)
        {
            if (Accept(data.cameraData) && actors.Count > 0)
                pass.SetTargets(renderer.cameraColorTargetHandle, renderer.cameraDepthTargetHandle);
        }

        protected override void Dispose(bool disposing)
        {
            if (pass != null) pass.Dispose();
            if (sceneShadowReceivePass != null) sceneShadowReceivePass.Dispose();
            actors.Clear();
        }

        // Receive only external scene casters; the character never self-shadows here.
        // URP's existing atlas still handles casting onto the scene and Cube.
        private sealed class SceneShadowReceivePass : ScriptableRenderPass
        {
            private const int Resolution = 2048;
            private readonly List<SkinnedMeshRenderer> actors;
            private RTHandle shadowmap;
            private readonly List<Renderer> externalCasters = new List<Renderer>();

            public SceneShadowReceivePass(List<SkinnedMeshRenderer> actors)
            {
                this.actors = actors;
                renderPassEvent = RenderPassEvent.AfterRenderingShadows;
            }

            public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData data)
            {
                ShadowUtils.ShadowRTReAllocateIfNeeded(ref shadowmap, Resolution, Resolution, 32,
                    name: "_WuwaSceneReceiveShadowmap");
                ConfigureTarget(shadowmap);
                ConfigureClear(ClearFlag.Depth, Color.black);
            }

            public override void Execute(ScriptableRenderContext context, ref RenderingData data)
            {
                int lightIndex = data.lightData.mainLightIndex;
                var light = data.lightData.visibleLights[lightIndex];
                if (light.light == null || light.lightType != LightType.Directional ||
                    light.light.shadows == LightShadows.None || actors.Count == 0) return;

                Bounds bounds = actors[0].bounds;
                for (int i = 1; i < actors.Count; i++) bounds.Encapsulate(actors[i].bounds);
                float padding = Mathf.Max(.01f, bounds.size.magnitude * .01f);
                Vector3 eye = bounds.center - light.light.transform.forward * (bounds.extents.magnitude + padding * 2);
                Matrix4x4 view = Matrix4x4.Scale(new Vector3(1, 1, -1)) *
                    Matrix4x4.TRS(eye, light.light.transform.rotation, Vector3.one).inverse;
                Vector3 minimum = Vector3.one * float.PositiveInfinity;
                Vector3 maximum = Vector3.one * float.NegativeInfinity;
                for (int corner = 0; corner < 8; corner++)
                {
                    Vector3 point = bounds.center + Vector3.Scale(bounds.extents,
                        new Vector3((corner & 1) == 0 ? -1 : 1,
                                    (corner & 2) == 0 ? -1 : 1,
                                    (corner & 4) == 0 ? -1 : 1));
                    point = view.MultiplyPoint(point);
                    minimum = Vector3.Min(minimum, point);
                    maximum = Vector3.Max(maximum, point);
                }
                // External geometry (including the scene Cube) casts into the same
                // precise receiver map. Keep XY fitted to the character; extend Z only.
                externalCasters.Clear();
                foreach (var caster in Object.FindObjectsOfType<Renderer>())
                {
                    if (!caster.enabled || caster.forceRenderingOff || !caster.gameObject.activeInHierarchy ||
                        caster.shadowCastingMode == ShadowCastingMode.Off ||
                        (light.light.cullingMask & (1 << caster.gameObject.layer)) == 0 ||
                        (caster is SkinnedMeshRenderer skinned && actors.Contains(skinned))) continue;
                    Bounds casterBounds = caster.bounds;
                    Vector3 casterMinimum = Vector3.one * float.PositiveInfinity;
                    Vector3 casterMaximum = Vector3.one * float.NegativeInfinity;
                    for (int corner = 0; corner < 8; corner++)
                    {
                        Vector3 point = casterBounds.center + Vector3.Scale(casterBounds.extents,
                            new Vector3((corner & 1) == 0 ? -1 : 1,
                                        (corner & 2) == 0 ? -1 : 1,
                                        (corner & 4) == 0 ? -1 : 1));
                        point = view.MultiplyPoint(point);
                        casterMinimum = Vector3.Min(casterMinimum, point);
                        casterMaximum = Vector3.Max(casterMaximum, point);
                    }
                    if (casterMaximum.x < minimum.x || casterMinimum.x > maximum.x ||
                        casterMaximum.y < minimum.y || casterMinimum.y > maximum.y ||
                        casterMaximum.z < minimum.z) continue;
                    externalCasters.Add(caster);
                    maximum.z = Mathf.Max(maximum.z, casterMaximum.z);
                }
                // Square XY keeps the caster's world-space bias isotropic.
                Vector3 center = (minimum + maximum) * .5f;
                float half = Mathf.Max(maximum.x - minimum.x, maximum.y - minimum.y) * .5f + padding;
                Matrix4x4 projection = Matrix4x4.Ortho(center.x - half, center.x + half,
                    center.y - half, center.y + half, -maximum.z - padding, -minimum.z + padding);
                Matrix4x4 sampleProjection = projection;
                if (SystemInfo.usesReversedZBuffer)
                    for (int column = 0; column < 4; column++) sampleProjection[2, column] = -sampleProjection[2, column];
                Matrix4x4 scaleBias = Matrix4x4.identity;
                scaleBias.m00 = scaleBias.m11 = scaleBias.m22 = .5f;
                scaleBias.m03 = scaleBias.m13 = scaleBias.m23 = .5f;

                var cmd = CommandBufferPool.Get("Wuwa external scene shadow reception");
                try
                {
                    CoreUtils.SetRenderTarget(cmd, shadowmap, ClearFlag.Depth, Color.black);
                    cmd.SetViewport(new Rect(0, 0, Resolution, Resolution));
                    cmd.DisableShaderKeyword("_CASTING_PUNCTUAL_LIGHT_SHADOW");
                    Vector4 bias = ShadowUtils.GetShadowBias(ref light, lightIndex,
                        ref data.shadowData, projection, Resolution);
                    ShadowUtils.SetupShadowCasterConstantBuffer(cmd, ref light, bias);
                    cmd.SetGlobalDepthBias(1, 2.5f);
                    cmd.SetViewProjectionMatrices(view, projection);
                    foreach (var caster in externalCasters)
                    {
                        var materials = caster.sharedMaterials;
                        for (int slot = 0; slot < materials.Length; slot++)
                        {
                            var material = materials[slot];
                            if (material == null) continue;
                            int shadowPass = material.FindPass("ShadowCaster");
                            if (shadowPass >= 0) cmd.DrawRenderer(caster, material, slot, shadowPass);
                        }
                    }
                    cmd.SetGlobalDepthBias(0, 0);
                    cmd.SetGlobalTexture("_WuwaSceneReceiveShadowmap", shadowmap.nameID);
                    cmd.SetGlobalMatrix("_WuwaWorldToSceneReceiveShadow", scaleBias * sampleProjection * view);
                    cmd.SetGlobalVector("_WuwaSceneReceiveShadowParams",
                        new Vector4(1f / Resolution, 1f / Resolution, light.light.shadowStrength, 1));
                    context.ExecuteCommandBuffer(cmd);
                }
                finally { CommandBufferPool.Release(cmd); }
            }

            public void Dispose() { shadowmap?.Release(); }
        }

        private sealed class CoveragePass : ScriptableRenderPass
        {
            private readonly List<SkinnedMeshRenderer> actors;
            private RTHandle color, depth, underDiffuse, shadowMask;
            private static readonly int UnderDiffuse = Shader.PropertyToID("_WuwaUnderDiffuse");
            private static readonly int UnderScale = Shader.PropertyToID("_WuwaUnderDiffuseScale");
            public bool enableProjectedShadow, enableHET, enableSmooth;

            public CoveragePass(List<SkinnedMeshRenderer> actors)
            {
                this.actors = actors;
                renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
                ConfigureInput(ScriptableRenderPassInput.Color | ScriptableRenderPassInput.Depth);
            }

            public void SetTargets(RTHandle color, RTHandle depth) { this.color = color; this.depth = depth; }

            public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData data)
            {
                ConfigureTarget(color, depth);
                var descriptor = data.cameraData.cameraTargetDescriptor;
                descriptor.depthBufferBits = 0;
                descriptor.depthStencilFormat = GraphicsFormat.None;
                descriptor.graphicsFormat = GraphicsFormat.R16G16B16A16_SFloat;
                descriptor.useMipMap = false;
                descriptor.autoGenerateMips = false;
                descriptor.memoryless = RenderTextureMemoryless.None;
                // Match the camera attachment sample count when sharing its depth.
                RenderingUtils.ReAllocateIfNeeded(ref underDiffuse, descriptor, FilterMode.Point,
                    TextureWrapMode.Clamp, name: "_WuwaUnderDiffuse");
                descriptor.graphicsFormat = GraphicsFormat.R8_UNorm;
                RenderingUtils.ReAllocateIfNeeded(ref shadowMask, descriptor, FilterMode.Point,
                    TextureWrapMode.Clamp, name: "_WuwaBangsShadowMask");
            }

            private static void Draw(CommandBuffer cmd, SkinnedMeshRenderer actor, int slot, string name)
            {
                var material = actor.sharedMaterials[slot];
                cmd.DrawRenderer(actor, material, slot, material.FindPass(name));
            }

            public override void Execute(ScriptableRenderContext context, ref RenderingData data)
            {
                var cmd = CommandBufferPool.Get("Wuwa HET and ordered bangs");
                try
                {
                    foreach (var actor in actors)
                    {
                        if (enableProjectedShadow)
                        {
                            // Source EID2793 runs before HET and later hair overwrites.
                            CoreUtils.SetRenderTarget(cmd, shadowMask, depth, ClearFlag.Color, Color.clear);
                            Draw(cmd, actor, 0, "BangsShadowMask");
                            CoreUtils.SetRenderTarget(cmd, color, depth, ClearFlag.None);
                            cmd.SetGlobalTexture("_WuwaBangsShadowMask", shadowMask.nameID);
                            Vector4 maskScale = shadowMask.useScaling ? shadowMask.rtHandleProperties.rtHandleScale : Vector4.one;
                            cmd.SetGlobalVector("_WuwaBangsShadowMaskScale", new Vector4(maskScale.x, maskScale.y, 0, 0));
                            // Re-evaluate only the current visible receiver pixels. Preserve diffuse,
                            // emission and rim; clamp only the Toon scalar as the source Min blend does.
                            foreach (int slot in new[] { 2, 5, 4, 6, 7, 3 })
                                Draw(cmd, actor, slot, "BangsShadowResolve");
                        }
                        // Save unlit material color, not already-lit camera color. The source blends only GBuffer3 RGB.
                        CoreUtils.SetRenderTarget(cmd, underDiffuse, depth, ClearFlag.Color, Color.clear);
                        Draw(cmd, actor, 2, "UnderlyingDiffuse");
                        Draw(cmd, actor, 7, "UnderlyingDiffuse");
                        CoreUtils.SetRenderTarget(cmd, color, depth, ClearFlag.None);
                        if (enableHET)
                        {
                            Draw(cmd, actor, 2, "HETDepthStencil");
                            Draw(cmd, actor, 7, "HETDepthStencil");
                        }
                        Draw(cmd, actor, 0, "BangsOpaque");
                        Draw(cmd, actor, 1, "HairOrdered");
                        if (enableSmooth)
                        {
                            // Hair may lie between Face/Eye and Bangs. Source RT3 already contains that Hair color.
                            CoreUtils.SetRenderTarget(cmd, underDiffuse, depth, ClearFlag.None);
                            Draw(cmd, actor, 1, "UnderlyingDiffuse");
                            CoreUtils.SetRenderTarget(cmd, color, depth, ClearFlag.None);
                            cmd.SetGlobalTexture(UnderDiffuse, underDiffuse.nameID);
                            Vector4 scale = underDiffuse.useScaling ? underDiffuse.rtHandleProperties.rtHandleScale : Vector4.one;
                            cmd.SetGlobalVector(UnderScale, new Vector4(scale.x, scale.y, 0, 0));
                            Draw(cmd, actor, 0, "BangsSmooth");
                        }
                    }
                    context.ExecuteCommandBuffer(cmd);
                }
                finally { CommandBufferPool.Release(cmd); }
            }

            public void Dispose() { if (underDiffuse != null) underDiffuse.Release(); if (shadowMask != null) shadowMask.Release(); }
        }
    }
}
