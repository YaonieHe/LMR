//  Created on 2022/7/6.

#include <metal_stdlib>
using namespace metal;

#include "../common/LMRShaderCommon.metal"

namespace LMR3D {
    typedef enum LightBufferIndex
    {
        LightBufferIndex_MeshPositions = 0,
        LightBufferIndex_View,
        LightBufferIndex_Obj,
        LightBufferIndex_Ambiant,
        LightBufferIndex_Light,
        LightBufferIndex_lightCount
    } ObjectBufferIndex;

    typedef enum ObjectTextureIndex
    {
        ObjectTextureIndex_BaseColor = 0,
    } ObjectTextureIndex;
    
    vertex VertexOut vertexLightObject(VertexIn in [[stage_in]],
                                            constant LMR3DViewParams &viewParam [[buffer(LightBufferIndex_View)]],
                                            constant LMR3DObjParams &objParam [[buffer(LightBufferIndex_Obj)]]) {
        VertexOut out;
        float4 pos = objParam.modelMatrix * float4(in.position, 1);
        out.position = viewParam.viewProjectionMatrix * pos;
        out.pos = pos.xyz / pos.w;
        out.normal = objParam.normalMatrix * in.normal;
        out.texture = in.texture;
        return out;
    }
    
    constexpr sampler linearSampler (mag_filter::linear,
                                          min_filter::linear);
    
    float4 getDiffColor(texture2d<half> map_md, constant LMR3DObjParams &obj, float2 texcoord) {
        if (obj.isDiffuseTexture) {
            return float4(map_md.sample(linearSampler, texcoord));
        } else {
            return obj.diffuseColor;
        }
    }
    
    fragment half4 fragmentLight(VertexOut in [[stage_in]],
                           constant LMR3DPointLightParams &light [[buffer(LightBufferIndex_Light)]]) {
        half3 color = half3(light.color);
        return half4(color, 1);
    }
    
    fragment half4 fragmentPhongLight(VertexOut in [[stage_in]],
                                      texture2d<half> map_md [[texture(LMR3DTextureIndex_BaseColor)]],
                                      constant LMR3DViewParams &viewParam [[buffer(LightBufferIndex_View)]],
                                      constant LMR3DObjParams &objParam [[buffer(LightBufferIndex_Obj)]],
                                      constant float3 &ambientColor [[buffer(LightBufferIndex_Ambiant)]],
                                      constant int &lightCount [[buffer(LightBufferIndex_lightCount)]],
                                      constant LMR3DPointLightParams *lights [[buffer(LightBufferIndex_Light)]]) {
        float3 color = float3(0, 0, 0);
        float4 diffColor = getDiffColor(map_md, objParam, in.texture);
        float4 specularColor = objParam.specularColor;
        float3 ambient = ambientColor * diffColor.rgb;
        color += ambient;
        
        for (int i = 0; i < lightCount; i++) {
            LMR3DPointLightParams light = lights[i];
            
            float3 lightDir = normalize(light.position - in.pos);
            float3 normal = normalize(in.normal);
            
            float diffFactor = max(dot(lightDir, normal), 0.0);
            float3 diffuse = diffFactor * light.color * diffColor.rgb;
            
            float3 reflectDir = normalize(reflect(-lightDir, normal));
            float3 viewDir = normalize(viewParam.cameraPos - in.pos);
            float specFactor = pow(max(dot(reflectDir, viewDir), 0.0), objParam.shininess);
            float3 specular = specFactor * light.color * specularColor.rgb;
            
            color = color + clamp(diffuse + specular, 0, 1);
        }
        color = clamp(color, 0, 1);
        return half4(half3(color), 1) * diffColor.a;
    }
    
    fragment half4 fragmentBlinnPhong(VertexOut in [[stage_in]],
                                      texture2d<half> map_md [[texture(LMR3DTextureIndex_BaseColor)]],
                                      constant LMR3DViewParams &viewParam [[buffer(LightBufferIndex_View)]],
                                      constant LMR3DObjParams &objParam [[buffer(LightBufferIndex_Obj)]],
                                      constant float3 &ambientColor [[buffer(LightBufferIndex_Ambiant)]],
                                      constant int &lightCount [[buffer(LightBufferIndex_lightCount)]],
                                      constant LMR3DPointLightParams *lights [[buffer(LightBufferIndex_Light)]]) {
        float3 color = float3(0, 0, 0);
        float4 diffColor = getDiffColor(map_md, objParam, in.texture);
        float4 specularColor = objParam.specularColor;
        float3 ambient = ambientColor * diffColor.rgb;
        color += ambient;
        
        for (int i = 0; i < lightCount; i++) {
            LMR3DPointLightParams light = lights[i];
            
            float3 lightDir = normalize(light.position - in.pos);
            float3 normal = normalize(in.normal);
            
            float diffFactor = max(dot(lightDir, normal), 0.0);
            float3 diffuse = diffFactor * light.color * diffColor.rgb;
            
            float3 viewDir = normalize(viewParam.cameraPos - in.pos);
            float3 h = normalize(viewDir + lightDir);
            float specFactor = pow(max(dot(normal, h), 0.0), objParam.shininess);
            float3 specular = specFactor * light.color * specularColor.rgb;
            
            color = color + clamp(diffuse + specular, 0, 1);
        }
        color = clamp(color, 0, 1);
        return half4(half3(color), 1) * diffColor.a;
    }
    
}
