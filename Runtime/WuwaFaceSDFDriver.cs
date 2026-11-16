using UnityEngine;
using UnityEngine.Rendering;

namespace Wuwa.Rendering
{
    [ExecuteAlways]
    [DisallowMultipleComponent]
    public sealed class WuwaFaceSDFDriver : MonoBehaviour
    {
        [SerializeField] private SkinnedMeshRenderer targetRenderer;
        [SerializeField] private Transform headBone;
        [SerializeField] private Vector3 headBackLocal;
        [SerializeField] private Vector3 headHighULocal;

        private static readonly int AxisA = Shader.PropertyToID("_FaceAxisA");
        private static readonly int AxisB = Shader.PropertyToID("_FaceAxisB");
        private MaterialPropertyBlock block;
        private static readonly int SparkleTime = Shader.PropertyToID("_SparkleSourceTime");
        private double sparkleStartTime;
        private const double CapturedSparkleTime = 838.5994873046875;

        public Transform HeadBone => headBone;

        public void Configure(SkinnedMeshRenderer renderer, Transform head,
                              Vector3 backLocal, Vector3 highULocal)
        {
            targetRenderer = renderer;
            headBone = head;
            headBackLocal = backLocal;
            headHighULocal = highULocal;
            UpdateHeadAxes();
        }

        private void OnEnable()
        {
            sparkleStartTime = Time.realtimeSinceStartupAsDouble;
            RenderPipelineManager.beginCameraRendering += BeforeCameraRender;
            UpdateHeadAxes();
        }

        private void OnDisable()
        {
            RenderPipelineManager.beginCameraRendering -= BeforeCameraRender;
        }

        private void BeforeCameraRender(ScriptableRenderContext context, Camera camera)
        {
            UpdateHeadAxes();
        }

        public void UpdateHeadAxes()
        {
            // OnEnable precedes Configure when the component is first added.
            if (targetRenderer == null || headBone == null) return;
            if (block == null) block = new MaterialPropertyBlock();
            Vector3 back = headBone.TransformDirection(headBackLocal).normalized;
            Vector3 highU = headBone.TransformDirection(headHighULocal).normalized;
            // Begin at this capture's phase. Material speeds remain 0 / -.03 / 0.
            float sourceTime = (float)(CapturedSparkleTime + Time.realtimeSinceStartupAsDouble - sparkleStartTime);
            int materialCount = targetRenderer.sharedMaterials.Length;
            for (int slot = 0; slot < materialCount; ++slot)
            {
                targetRenderer.GetPropertyBlock(block, slot);
                block.SetFloat(SparkleTime, sourceTime);
                block.SetVector(AxisA, new Vector4(back.x, back.y, back.z, 0));
                block.SetVector(AxisB, new Vector4(highU.x, highU.y, highU.z, 0));
                targetRenderer.SetPropertyBlock(block, slot);
            }
        }
    }
}
