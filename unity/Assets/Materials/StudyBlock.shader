Shader "BlockLab/Study Block"
{
    Properties { _Color ("Color",Color)=(1,1,1,1) }
    SubShader {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        Pass {
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            struct Attributes { float4 positionOS:POSITION; float3 normalOS:NORMAL; };
            struct Varyings { float4 positionCS:SV_POSITION; float3 normalWS:TEXCOORD0; };
            CBUFFER_START(UnityPerMaterial)
                half4 _Color;
            CBUFFER_END
            Varyings Vert(Attributes input) {
                Varyings output;output.positionCS=TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS=TransformObjectToWorldNormal(input.normalOS);return output;
            }
            half4 Frag(Varyings input):SV_Target {
                // Shadow-free color with restrained face shading to retain depth.
                half shade=.88h+.12h*saturate(dot(normalize(input.normalWS),normalize(float3(.3,1,.4))));
                return half4(_Color.rgb*shade,1);
            }
            ENDHLSL
        }
    }
}
