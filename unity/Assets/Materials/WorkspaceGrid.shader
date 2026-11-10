Shader "BlockLab/Workspace Grid"
{
    Properties {
        _Background ("Background", Color) = (0.9,0.93,0.98,1)
        _Line ("Grid lines", Color) = (0.6,0.67,0.77,1)
    }
    SubShader {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        Pass {
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            struct Attributes { float4 positionOS:POSITION; };
            struct Varyings { float4 positionCS:SV_POSITION; float3 world:TEXCOORD0; };
            CBUFFER_START(UnityPerMaterial)
                half4 _Background, _Line;
            CBUFFER_END
            Varyings Vert(Attributes input) {
                Varyings output;
                output.world=TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS=TransformWorldToHClip(output.world);
                return output;
            }
            half4 Frag(Varyings input):SV_Target {
                float2 cell=input.world.xz;
                float2 distance=abs(frac(cell-0.5)-0.5)/max(fwidth(cell),0.0001);
                float gridAmount=1-saturate(min(distance.x,distance.y));
                return lerp(_Background,_Line,gridAmount);
            }
            ENDHLSL
        }
    }
}
