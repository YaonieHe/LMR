//  Created on 2022/7/18.

#include <metal_stdlib>
using namespace metal;

#include "../common/LMRShaderCommon.metal"

namespace LMR3D {
    typedef enum BufferIndex
    {
        BufferIndex_MeshPositions = 0,
        BufferIndex_View,
        BufferIndex_Obj,
        BufferIndex_Ambiant,
        BufferIndex_Light,
        BufferIndex_MaxDepth
    } BufferIndex;
    
    struct PointShadowVertexOut {
        float4 position [[position]];
        float3 pos;
        uint layer [[render_target_array_index]];
    };
    
    struct PointShadowFragmentOut {
        float depth [[depth(less)]];
    };
    
    vertex PointShadowVertexOut vertexPointShadow(VertexIn in [[stage_in]],
                                             constant LMR3DViewParams *viewParam [[buffer(BufferIndex_View)]],
                                             constant LMR3DObjParams &objParam [[buffer(BufferIndex_Obj)]],
                                                                                 uint iid [[instance_id]]) {
        PointShadowVertexOut out;
        float4 pos = objParam.modelMatrix * float4(in.position, 1);
        out.position = viewParam[iid].viewProjectionMatrix * pos;
        out.pos = pos.xyz / pos.w;
        out.layer = iid;
        return out;
    }
    
    fragment PointShadowFragmentOut fragmentPointShadow(PointShadowVertexOut in [[stage_in]], constant LMR3DPointLightParams &light [[buffer(BufferIndex_Light)]], constant float &maxDepth [[buffer(BufferIndex_MaxDepth)]]) {
        PointShadowFragmentOut out;
        out.depth = length(in.pos - light.position) / maxDepth;
        return out;
    }
    
    
    float PointShadowCalculation(float3 pos, float3 light_pos, depthcube<float> map, float maxDepth) {
        float3 pos_to_light = pos - light_pos;
        pos_to_light.x *= -1;
        float closest_depth = map.sample(linearSampler, normalize(pos_to_light)) * maxDepth + 0.05;
        float current_depth = length(pos_to_light);
        if (current_depth < closest_depth) {
            return 0;
        }
        return 1.0;
    }
    
    fragment half4 fragmentPointShadowBlinnPhong(VertexOut in [[stage_in]],
                                                 texture2d<half> map_md [[texture(LMR3DTextureIndex_BaseColor)]],
                                                 depthcube<float> shadowCube [[texture(LMR3DTextureIndex_ShadowCube)]],
                                                 constant LMR3DViewParams &viewParam [[buffer(BufferIndex_View)]],
                                                 constant LMR3DObjParams &objParam [[buffer(BufferIndex_Obj)]],
                                                 constant float3 &ambientColor [[buffer(BufferIndex_Ambiant)]],
                                                 constant LMR3DPointLightParams &light [[buffer(BufferIndex_Light)]],
                                                 constant float &maxDepth [[buffer(BufferIndex_MaxDepth)]]) {
        float3 color = float3(0, 0, 0);
        float4 diffColor = getDiffColor(map_md, objParam, in.texture);
        float4 specularColor = objParam.specularColor;
        float3 ambient = ambientColor * diffColor.rgb;
        color += ambient;
        
        float3 lightDir = normalize(light.position - in.pos);
        float3 normal = normalize(in.normal);
        
        float diffFactor = max(dot(lightDir, normal), 0.0);
        float3 diffuse = diffFactor * light.color * diffColor.rgb;
        
        float3 viewDir = normalize(viewParam.cameraPos - in.pos);
        float3 h = normalize(viewDir + lightDir);
        float specFactor = pow(max(dot(normal, h), 0.0), objParam.shininess);
        float3 specular = specFactor * light.color * specularColor.rgb;
        
        float shadow = PointShadowCalculation(in.pos, light.position, shadowCube, maxDepth);
        
        color = color + clamp(diffuse + specular, 0, 1) * (1 - shadow);

        color = clamp(color, 0, 1);
        return half4(half3(color), 1) * diffColor.a;
    }
    
}

