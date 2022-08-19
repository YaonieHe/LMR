//  Created on 2022/8/16.

#include <metal_stdlib>
using namespace metal;

#include "../common/LMRShaderCommon.metal"

#include "LMRReflectionShader.h"

namespace LMR3D {
    
    struct RFVertexOut
    {
        float4 position [[position]];
        float3 pos;
        float3 normal;
        float2 texture;
        float3 tangent;
        float3 bitangent;
        
        uint   face [[render_target_array_index]];
    };
    
    vertex RFVertexOut vertexReflection(const PNTTBVertexIn in [[ stage_in ]],
                                        const uint instanceId [[ instance_id ]],
                                        const device uint *instanceParam [[ buffer(LMRRFBufferIndex_Instance) ]],
                                        const device LMR3DObjParams& objParam [[ buffer(LMRRFBufferIndex_Obj) ]],
                                        constant LMR3DViewParams *viewParams [[ buffer(LMRRFBufferIndex_View) ]]) {
        RFVertexOut out;
        
        out.face = instanceParam[instanceId];
        
        float4 pos = objParam.modelMatrix * float4(in.position, 1);
        out.position = viewParams[out.face].viewProjectionMatrix * pos;
        out.pos = pos.xyz / pos.w;
        out.texture = in.texture;
        out.normal = normalize(objParam.normalMatrix * in.normal);
        out.tangent = normalize(objParam.normalMatrix * in.tangent);
        out.bitangent = normalize(objParam.normalMatrix * in.bitangent);
        
        return out;
    }
    
    fragment float4 fragmentRFObj(RFVertexOut in [[ stage_in ]],
                                  constant LMR3DObjParams& objParam [[ buffer(LMRRFBufferIndex_Obj) ]],
                                  constant LMRRFFrameParam& frameParam [[ buffer(LMRRFBufferIndex_Frame) ]],
                                  constant LMR3DViewParams* viewParams [[ buffer(LMRRFBufferIndex_View) ]],
                                  texture2d<half> map_md [[texture(LMR3DTextureIndex_BaseColor)]],
                                  texture2d<half> map_ks [[texture(LMR3DTextureIndex_Specular)]],
                                  texture2d<half> map_kn [[texture(LMR3DTextureIndex_Normal)]]) {
        float3 color = float3(0, 0, 0);
        float4 diffColor = getDiffColor(map_md, objParam, in.texture);
        float4 specularColor = getSpecularColor(map_ks, objParam, in.texture);
        
        float3 normal = normalize(in.normal);
        if (objParam.isNormalTexture) {
            float4 kn_sample = float4(map_kn.sample(linearSampler, in.texture));
            float3 tangent_normal = normalize((kn_sample.xyz * 2.0) - 1.0);
            normal = normalize(tangent_normal.x * in.tangent + tangent_normal.y * in.bitangent + tangent_normal.z * in.normal);
        }
        
        {
            float nDotL = saturate(dot(normal, frameParam.directionalLightInvDirection));
            float3 diffuseTerm = frameParam.directionalLightColor * nDotL;
            
            float3 eyeDir = normalize(viewParams[in.face].cameraPos - in.pos);
            float3 halfwayVector = normalize(frameParam.directionalLightInvDirection + eyeDir);
            
            float reflectionAmount = saturate(dot(normal, halfwayVector));
            float specularIntensity = powr(reflectionAmount, objParam.shininess);
            float3 specular = frameParam.directionalLightColor * specularIntensity * specularColor.xyz;
            float3 diff = (diffuseTerm + frameParam.ambientLightColor) * diffColor.xyz;
            
            color = diff + specular;
        }
        
        return float4(color, diffColor.a);
    }
    
    fragment float4 fragmentRFFloor(RFVertexOut in [[ stage_in ]],
                                    constant LMR3DViewParams* viewParams [[ buffer(LMRRFBufferIndex_View) ]]) {
        
        float onEdge;
        
        float2 onEdge2d = fract(float2(in.pos.xz) / 500);
        float2 offset2d = sign(onEdge2d) * -0.5 + 0.5;
        onEdge2d += offset2d;
        onEdge2d = step(0.03, onEdge2d);
        onEdge = min(onEdge2d.x, onEdge2d.y);
        
        float3 neutralColor = float3(0.9, 0.9, 0.9);
        float3 edgeColor = neutralColor * 0.2;
        float3 groundColor = mix(edgeColor, neutralColor, onEdge);
        return float4(groundColor, 1.0);
    }
    
    fragment float4 fragmentReflection(RFVertexOut in [[ stage_in ]],
                                       constant LMR3DViewParams* viewParams [[ buffer(LMRRFBufferIndex_View) ]],
                                       texturecube<half> cubeMap        [[ texture (0) ]]) {
        float3 eyeDir = normalize(viewParams[in.face].cameraPos - in.pos);
        float similiFresnel = dot(in.normal, eyeDir);
        similiFresnel = saturate(1 - similiFresnel);
        similiFresnel = 1;//min(1.0, similiFresnel * 0.6 + 0.45);
        
        float3 reflectionDir = reflect(-eyeDir, in.normal);
        float4 cubeRefl = (float4)cubeMap.sample(linearSampler, reflectionDir);
        if (cubeRefl.w <= 0) {
            discard_fragment();
        }
        return float4(cubeRefl.xyz * similiFresnel + 0.01, cubeRefl.w);
    }
}
