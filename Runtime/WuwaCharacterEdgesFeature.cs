using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Wuwa.Rendering
{
    // The captured RT5 depth is independent of the inverted-hull outline.
    public sealed class WuwaCharacterEdgesFeature : ScriptableRendererFeature
    {
        public bool enableOutline = true;
        public bool enableDepthRim = true;
        private readonly List<SkinnedMeshRenderer> actors = new List<SkinnedMeshRenderer>();
        private CharacterDepthPass depthPass;
        private OutlinePass outlinePass;

        public override void Create()
        {
            if (depthPass != null) depthPass.Dispose();
            depthPass = new CharacterDepthPass(actors);
            outlinePass = new OutlinePass(actors);
        }

        private static bool Accept(in CameraData data)
        {
            return data.renderType == CameraRenderType.Base &&
                (data.cameraType == CameraType.Game || data.cameraType == CameraType.SceneView);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData data)
        {
            actors.Clear();
            if (!Accept(data.cameraData)) return;
            foreach (var driver in Object.FindObjectsOfType<WuwaFaceSDFDriver>())
            {
                var actor = driver.GetComponent<SkinnedMeshRenderer>();
                if (!driver.isActiveAndEnabled || actor == null || !actor.enabled || actor.forceRenderingOff ||
                    !actor.gameObject.activeInHierarchy || actor.sharedMesh == null ||
                    (data.cameraData.camera.cullingMask & (1 << actor.gameObject.layer)) == 0) continue;
                var materials = actor.sharedMaterials;
                if (materials.Length != 8 || actor.sharedMesh.subMeshCount != 8) continue;
                bool ready = true;
                foreach (var material in materials)
                    if (material == null || material.shader == null || material.shader.name != "Wuwa/Character/PartitionToonRamp" ||
                        material.FindPass("CharacterDepth") < 0 || material.FindPass("GeometryOutline") < 0)
                    { ready = false; break; }
                if (!ready) continue;
#if UNITY_EDITOR
                foreach (var material in materials)
                    for (int index = 0; index < material.passCount; ++index)
                        if (!UnityEditor.ShaderUtil.IsPassCompiled(material, index))
                            UnityEditor.ShaderUtil.CompilePass(material, index, true);
#endif
                actors.Add(actor);
            }
            if (actors.Count == 0) return;
            depthPass.enabled = enableDepthRim;
            renderer.EnqueuePass(depthPass);
            if (enableOutline) renderer.EnqueuePass(outlinePass);
        }

        public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData data)
        {
            if (Accept(data.cameraData) && actors.Count > 0)
                outlinePass.SetTargets(renderer.cameraColorTargetHandle, renderer.cameraDepthTargetHandle);
        }

        protected override void Dispose(bool disposing)
        {
            if (depthPass != null) depthPass.Dispose();
            actors.Clear();
        }

        private static void Draw(CommandBuffer cmd, SkinnedMeshRenderer actor, int slot, string pass)
        {
            var material = actor.sharedMaterials[slot];
            cmd.DrawRenderer(actor, material, slot, material.FindPass(pass));
        }

        private sealed class CharacterDepthPass : ScriptableRenderPass
        {
            private readonly List<SkinnedMeshRenderer> actors;
            private RTHandle rawDepth, depthStencil;
            public bool enabled;
            public CharacterDepthPass(List<SkinnedMeshRenderer> actors)
            {
                this.actors = actors;
                renderPassEvent = RenderPassEvent.BeforeRenderingOpaques;
            }
            public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData data)
            {
                var descriptor = data.cameraData.cameraTargetDescriptor;
                descriptor.msaaSamples = 1;
                descriptor.depthBufferBits = 0;
                descriptor.depthStencilFormat = GraphicsFormat.None;
                descriptor.graphicsFormat = GraphicsFormat.R16_SFloat;
                descriptor.useMipMap = false;
                descriptor.autoGenerateMips = false;
                descriptor.memoryless = RenderTextureMemoryless.None;
                RenderingUtils.ReAllocateIfNeeded(ref rawDepth, descriptor, FilterMode.Bilinear,
                    TextureWrapMode.Clamp, name: "_WuwaCharacterRawDepth");
                descriptor.graphicsFormat = GraphicsFormat.None;
                descriptor.depthStencilFormat = GraphicsFormat.D24_UNorm_S8_UInt;
                RenderingUtils.ReAllocateIfNeeded(ref depthStencil, descriptor, FilterMode.Point,
                    TextureWrapMode.Clamp, name: "_WuwaCharacterDepthStencil");
                ConfigureTarget(rawDepth, depthStencil);
                ConfigureClear(ClearFlag.All, SystemInfo.usesReversedZBuffer ? Color.clear : Color.white);
            }
            public override void Execute(ScriptableRenderContext context, ref RenderingData data)
            {
                var cmd = CommandBufferPool.Get("Wuwa captured character depth");
                try
                {
                    cmd.SetGlobalFloat("_WuwaDepthRimReady", enabled ? 1 : 0);
                    if (enabled)
                    {
                        foreach (var actor in actors)
                        {
                            // Base passes -> HET (depth/stencil only) -> opaque bangs -> hair -> smooth bangs.
                            foreach (int slot in new[] { 2, 5, 4, 6, 7, 3 }) Draw(cmd, actor, slot, "CharacterDepth");
                            Draw(cmd, actor, 2, "HETDepthStencil");
                            Draw(cmd, actor, 7, "HETDepthStencil");
                            Draw(cmd, actor, 0, "CharacterDepthBangsOpaque");
                            Draw(cmd, actor, 1, "CharacterDepth");
                            Draw(cmd, actor, 0, "CharacterDepthBangsSmooth");
                        }
                        cmd.SetGlobalTexture("_WuwaCharacterRawDepth", rawDepth.nameID);
                        Vector4 scale = rawDepth.useScaling ? rawDepth.rtHandleProperties.rtHandleScale : Vector4.one;
                        cmd.SetGlobalVector("_WuwaCharacterDepthScale", new Vector4(scale.x, scale.y, 0, 0));
                    }
                    context.ExecuteCommandBuffer(cmd);
                }
                finally { CommandBufferPool.Release(cmd); }
            }
            public void Dispose()
            {
                if (rawDepth != null) rawDepth.Release();
                if (depthStencil != null) depthStencil.Release();
            }
        }

        private sealed class OutlinePass : ScriptableRenderPass
        {
            private readonly List<SkinnedMeshRenderer> actors;
            private RTHandle color, depth;
            public OutlinePass(List<SkinnedMeshRenderer> actors)
            {
                this.actors = actors;
                renderPassEvent = (RenderPassEvent)((int)RenderPassEvent.AfterRenderingOpaques + 1);
            }
            public void SetTargets(RTHandle color, RTHandle depth) { this.color = color; this.depth = depth; }
            public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData data) { ConfigureTarget(color, depth); }
            public override void Execute(ScriptableRenderContext context, ref RenderingData data)
            {
                var cmd = CommandBufferPool.Get("Wuwa UV1 inverted hull outline");
                try
                {
                    foreach (var actor in actors)
                        foreach (int slot in new[] { 4, 5, 6, 0, 3, 1, 2 })
                            Draw(cmd, actor, slot, "GeometryOutline");
                    context.ExecuteCommandBuffer(cmd);
                }
                finally { CommandBufferPool.Release(cmd); }
            }
        }
    }
}
