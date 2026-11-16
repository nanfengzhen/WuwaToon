Shader "Wuwa/Character/PartitionToonRamp" {
    Properties {
        [HideInInspector] _BangsShadowOffsetOS ("Captured Bangs Shadow Offset (Metres)", Vector) = (0,-.005,-.003,0)
        [Toggle] _OutlineEnabled ("Geometry Outline", Float) = 0
        _OutlineWidth ("Captured Outline Width", Float) = 1
        _OutlineSmooth ("Captured Outline Smoothing", Float) = 1.5
        [HideInInspector] _OutlineTextured ("Outline Base Texture Modulation", Float) = 1
        _OutlineColor ("Captured Outline Color Multiplier", Vector) = (.4,.4,.4,1)
        [Toggle] _DepthRimEnabled ("Screen Depth Rim Light", Float) = 0
        [MainTexture] _BaseMap ("Base Color", 2D) = "white" {}
        _FTM ("Material Mask", 2D) = "white" {}
        _RGID ("Packed Region IDs", 2D) = "black" {}
        _SkinRamp ("Captured Skin Ramp", 2D) = "white" {}
        _FaceSDF ("Face SDF Shadow", 2D) = "white" {}
        _HairHM ("Hair Toon Control", 2D) = "black" {}
        [Toggle] _SceneShadowsEnabled ("Receive Scene Shadows", Float) = 1
        [Toggle] _StarMarkEnabled ("Captured Chest Star Mark", Float) = 0
        _StarMark ("Captured Star Mark", 2D) = "white" {}
        [Toggle] _SparkleEnabled ("Clothing Sparkle", Float) = 0
        [HideInInspector] _SparkleSourceTime ("Captured Sparkle Time", Float) = 838.5994873
        _AlphaNoise ("Captured 64x64 Coverage Noise", 2D) = "gray" {}
        _AlphaSparkle ("Captured Sparkle Mask", 2D) = "black" {}
        [Toggle] _AlphaDitherEnabled ("Thin Surface Dither Cutout", Float) = 0
        [Toggle] _DoubleSidedNormalsEnabled ("Thin Surface Backface Normals", Float) = 0
        _EyeEG ("Eye Layer Mask (EG)", 2D) = "black" {}
        _EyeEM ("Eye Height and Layer Controls (EM)", 2D) = "black" {}
        _HET ("Face / Eye Hair Coverage (HET)", 2D) = "black" {}
        [Toggle] _EyeEffectsEnabled ("Eye Parallax and Color Layers", Float) = 0
        [Toggle] _EyeParallaxEnabled ("Eye Height Ray March", Float) = 1
        [HideInInspector] _CoverageEnabled ("Ordered Hair Coverage", Float) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull Mode", Float) = 2
        _MatCap ("Captured Material Reflection (MC)", 2D) = "black" {}
        [Toggle] _MatCapEnabled ("Material MatCap Reflection", Float) = 0
        [HideInInspector] _BodyMatCapVariant ("Captured Reflection Material", Float) = 0
        _HairHN ("Hair Band Coordinates (HN)", 2D) = "gray" {}
        _HairNoise ("Hair Band Noise", 2D) = "gray" {}
        _HairHR ("Hair Band Color Table (HR)", 2D) = "gray" {}
        [Toggle] _HairHighlightsEnabled ("Hair Bands and Highlights", Float) = 0
        [HideInInspector] _HairIsBangs ("Captured Bangs Parameters", Float) = 0
        _DetailNormalMap ("Body Detail Normal (Raw RG)", 2D) = "bump" {}
        [Toggle] _DetailNormalsEnabled ("Body Detail Normals", Float) = 1
        _DetailNormalStrength ("Body Detail Normal Strength", Float) = 1
        [HideInInspector] _BodyGeometricNormalBlend ("Body Geometric Normal Blend", Float) = 0
        [Toggle] _RampEnabled ("Skin Ramp", Float) = 1
        [Enum(Body,0,Hair,1,Face,2,Eye,3)] _MaterialKind ("Material Kind", Float) = 0
        _HairHMShift ("Hair Toon Shift", Float) = .2
        _ToonDarkColor ("Capture Toon Dark Color", Vector) = (.3,.405086,.5,1)
        [HideInInspector] _WorldToCapture0 ("World to Capture Row 0", Vector) = (1,0,0,0)
        [HideInInspector] _WorldToCapture1 ("World to Capture Row 1", Vector) = (0,0,1,0)
        [HideInInspector] _WorldToCapture2 ("World to Capture Row 2", Vector) = (0,1,0,0)
        [HideInInspector] _FaceAxisA ("Head Back Axis (World)", Vector) = (0,0,-1,0)
        [HideInInspector] _FaceAxisB ("Head High U Axis (World)", Vector) = (-1,0,0,0)
        [HideInInspector] _ValidationMode ("Validation View", Float) = 0
        [HideInInspector] _BodyTint ("tint", Vector) = (0,0,0,0)
        [HideInInspector] _BodyDarkTint ("darkTint", Vector) = (0,0,0,0)
        [HideInInspector] _BodyLightTint ("lightTint", Vector) = (0,0,0,0)
        [HideInInspector] _BodyOverrideColor ("overrideColor", Vector) = (0,0,0,0)
        [HideInInspector] _BodyBaseTint ("baseTint", Vector) = (0,0,0,0)
        [HideInInspector] _BodyViewColor1 ("viewColor1", Vector) = (0,0,0,0)
        [HideInInspector] _BodyViewColor2 ("viewColor2", Vector) = (0,0,0,0)
        [HideInInspector] _BodyNormalMask ("normalMask", Float) = 0
        [HideInInspector] _BodyOverrideScale ("overrideScale", Float) = 0
        [HideInInspector] _BodySkinRange ("skinRange", Vector) = (0,0,0,0)
        [HideInInspector] _BodyColorGlobal ("colorGlobal", Float) = 0
        [HideInInspector] _BodyOcclusionStrength ("occlusionStrength", Float) = 0
        [HideInInspector] _BodyAoTop ("aoTop", Float) = 0
        [HideInInspector] _BodyAoCap ("aoCap", Float) = 0
        [HideInInspector] _BodyAoDiv ("aoDiv", Float) = 0
        [HideInInspector] _BodyAoMax ("aoMax", Float) = 0
        [HideInInspector] _BodyAoMin ("aoMin", Float) = 0
        [HideInInspector] _BodyAoRange ("aoRange", Float) = 0
        [HideInInspector] _BodyLightToggle ("lightToggle", Float) = 0
        [HideInInspector] _BodyLightBlend ("lightBlend", Float) = 0
        [HideInInspector] _BodyShadowBias ("shadowBias", Float) = 0
        [HideInInspector] _BodyWidths0123 ("widths0123", Vector) = (0,0,0,0)
        [HideInInspector] _BodyWidths4 ("widths4", Vector) = (0,0,0,0)
        [HideInInspector] _BodyWidthGlobal ("widthGlobal", Float) = 0
        [HideInInspector] _BodyWidthBlend ("widthBlend", Float) = 0
        [HideInInspector] _BodyShadowLight ("shadowLight", Vector) = (0,0,0,0)
        [HideInInspector] _BodyShadowDark ("shadowDark", Vector) = (0,0,0,0)
        [HideInInspector] _BodyRampCap ("rampCap", Float) = 0
        [HideInInspector] _BodyRampRows0123 ("rampRows0123", Vector) = (0,0,0,0)
        [HideInInspector] _BodyRampRows4 ("rampRows4", Vector) = (0,0,0,0)
        [HideInInspector] _BodyRampMix0123 ("rampMix0123", Vector) = (0,0,0,0)
        [HideInInspector] _BodyRampMix4 ("rampMix4", Vector) = (0,0,0,0)
        [HideInInspector] _BodyDesaturate ("desaturate", Float) = 0
        [HideInInspector] _BodyAoViewStrength ("aoViewStrength", Float) = 0
        [HideInInspector] _BodyCustomX ("customX", Float) = 0
        [HideInInspector] _BodyBaseIntensity ("baseIntensity", Float) = 0
        [HideInInspector] _BodyViewRange ("viewRange", Vector) = (0,0,0,0)
        [HideInInspector] _BodyViewBias1 ("viewBias1", Float) = 0
        [HideInInspector] _BodyViewWidth1 ("viewWidth1", Float) = 0
        [HideInInspector] _BodyViewPower1 ("viewPower1", Float) = 0
        [HideInInspector] _BodyViewBias2 ("viewBias2", Float) = 0
        [HideInInspector] _BodyViewWidth2 ("viewWidth2", Float) = 0
        [HideInInspector] _BodyViewPower2 ("viewPower2", Float) = 0
        [HideInInspector] _BodyViewBlend2 ("viewBlend2", Float) = 0
        [HideInInspector] _BodyViewStrength ("viewStrength", Float) = 0
        [HideInInspector] _BodyHasViewOverlay ("hasViewOverlay", Float) = 0
        [HideInInspector] _BodyRampAffectsBase ("rampAffectsBase", Float) = 0
    }
    SubShader {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
        Pass {
            Name "PartitionToonRamp"
            Tags {"LightMode"="UniversalForwardOnly"}
            Cull [_Cull] ZWrite On ZTest LEqual
            Stencil { Ref 2 ReadMask 2 WriteMask 250 Comp Always Pass Replace }
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex WuwaVertex
            #pragma fragment WuwaFragment
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #include "Passes/WuwaForward.hlsl"
            ENDHLSL
        }
        Pass {
            Name "UnderlyingDiffuse"
            Tags {"LightMode"="WuwaUnderlyingDiffuse"}
            Cull Back ZWrite Off ZTest LEqual ColorMask RGBA
            
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex WuwaVertex
            #pragma fragment WuwaFragment
            #define WUWA_ORDERED_HAIR 1
            #define WUWA_DIFFUSE_OUTPUT 1
            #include "Passes/WuwaForward.hlsl"
            ENDHLSL
        }
        Pass {
            Name "HETDepthStencil"
            Tags {"LightMode"="WuwaHETDepthStencil"}
            Cull Back ZWrite On ZTest LEqual ColorMask 0
            Stencil { Ref 6 ReadMask 30 WriteMask 254 Comp Always Pass Replace }
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex WuwaVertex
            #pragma fragment WuwaHETFragment
            #include "Passes/WuwaHET.hlsl"
            ENDHLSL
        }
        Pass {
            Name "BangsOpaque"
            Tags {"LightMode"="WuwaBangsOpaque"}
            Cull Back ZWrite On ZTest LEqual ColorMask RGBA
            Stencil { Ref 6 ReadMask 30 WriteMask 250 Comp NotEqual Pass Replace }
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex WuwaVertex
            #pragma fragment WuwaFragment
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #define WUWA_ORDERED_HAIR 1
            #include "Passes/WuwaForward.hlsl"
            ENDHLSL
        }
        Pass {
            Name "HairOrdered"
            Tags {"LightMode"="WuwaHairOrdered"}
            Cull Back ZWrite On ZTest LEqual ColorMask RGBA
            Stencil { Ref 2 ReadMask 2 WriteMask 250 Comp Always Pass Replace }
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex WuwaVertex
            #pragma fragment WuwaFragment
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #define WUWA_ORDERED_HAIR 1
            #include "Passes/WuwaForward.hlsl"
            ENDHLSL
        }
        Pass {
            Name "BangsSmooth"
            Tags {"LightMode"="WuwaBangsSmooth"}
            Cull Back ZWrite On ZTest LEqual ColorMask RGBA
            Stencil { Ref 6 ReadMask 4 WriteMask 254 Comp Equal Pass Keep }
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex WuwaVertex
            #pragma fragment WuwaFragment
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #define WUWA_ORDERED_HAIR 1
            #define WUWA_BANGS_SMOOTH 1
            #include "Passes/WuwaForward.hlsl"
            ENDHLSL
        }
        Pass {
            Name "CharacterDepth"
            Tags {"LightMode"="WuwaCharacterDepth"}
            Cull [_Cull] ZWrite On ZTest LEqual ColorMask R
            Stencil { Ref 2 ReadMask 2 WriteMask 250 Comp Always Pass Replace }
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex WuwaVertex
            #pragma fragment WuwaFragment
            #define WUWA_ORDERED_HAIR 1
            #define WUWA_DEPTH_OUTPUT 1
            #include "Passes/WuwaForward.hlsl"
            ENDHLSL
        }
        Pass {
            Name "CharacterDepthBangsOpaque"
            Tags {"LightMode"="WuwaCharacterDepthBangsOpaque"}
            Cull Back ZWrite On ZTest LEqual ColorMask R
            Stencil { Ref 6 ReadMask 30 WriteMask 250 Comp NotEqual Pass Replace }
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex WuwaVertex
            #pragma fragment WuwaFragment
            #define WUWA_ORDERED_HAIR 1
            #define WUWA_DEPTH_OUTPUT 1
            #include "Passes/WuwaForward.hlsl"
            ENDHLSL
        }
        Pass {
            Name "CharacterDepthBangsSmooth"
            Tags {"LightMode"="WuwaCharacterDepthBangsSmooth"}
            Cull Back ZWrite On ZTest LEqual ColorMask R
            Stencil { Ref 6 ReadMask 4 WriteMask 254 Comp Equal Pass Keep }
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex WuwaVertex
            #pragma fragment WuwaFragment
            #define WUWA_ORDERED_HAIR 1
            #define WUWA_DEPTH_OUTPUT 1
            #include "Passes/WuwaForward.hlsl"
            ENDHLSL
        }
        Pass {
            Name "GeometryOutline"
            Tags {"LightMode"="WuwaGeometryOutline"}
            Cull Front ZWrite On ZTest LEqual
            Stencil { Ref 2 ReadMask 2 WriteMask 250 Comp Always Pass Replace }
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex WuwaOutlineVertex
            #pragma fragment WuwaOutlineFragment
            #include "Passes/WuwaOutline.hlsl"
            ENDHLSL
        }
        Pass {
            Name "BangsShadowMask"
            Tags {"LightMode"="WuwaBangsShadowMask"}
            Cull Back ZWrite Off ZTest LEqual ColorMask R
            Stencil { Ref 2 ReadMask 26 WriteMask 0 Comp Equal Pass Keep }
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex WuwaBangsShadowVertex
            #pragma fragment WuwaBangsShadowFragment
            #include "Passes/WuwaBangsShadow.hlsl"
            ENDHLSL
        }
        Pass {
            Name "BangsShadowResolve"
            Tags {"LightMode"="WuwaBangsShadowResolve"}
            Cull [_Cull] ZWrite Off ZTest Equal
            Stencil { Ref 2 ReadMask 26 WriteMask 0 Comp Equal Pass Keep }
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex WuwaVertex
            #pragma fragment WuwaFragment
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #define WUWA_PROJECTED_SHADOW_RESOLVE 1
            #include "Passes/WuwaForward.hlsl"
            ENDHLSL
        }
        Pass {
            Name "ShadowCaster"
            Tags {"LightMode"="ShadowCaster"}
            Cull [_Cull] ZWrite On ZTest LEqual ColorMask 0
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex WuwaShadowVertex
            #pragma fragment WuwaShadowFragment
            #pragma multi_compile_instancing
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #include "Passes/WuwaShadowCaster.hlsl"
            ENDHLSL
        }
    }
}
