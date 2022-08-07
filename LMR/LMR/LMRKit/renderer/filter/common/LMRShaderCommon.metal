//  Created on 2022/7/5.

#include <metal_stdlib>

#include "LMRShaderCommon.h"

using namespace metal;

namespace LMR3D {
    struct VertexIn {
        float3 position [[attribute(LMR3DVertexAttribute_Position)]];
        float3 normal   [[attribute(LMR3DVertexAttribute_Normal)]];
        float2 texture  [[attribute(LMR3DVertexAttribute_Texcoord)]];
    };
    
    struct VertexOut {
        float4 position [[position]];
        float3 pos;
        float3 normal;
        float2 texture;
    };
    
    struct PNTTBVertexIn {
        float3 position [[attribute(LMR3DVertexAttribute_Position)]];
        float3 normal   [[attribute(LMR3DVertexAttribute_Normal)]];
        float2 texture  [[attribute(LMR3DVertexAttribute_Texcoord)]];
        float3 tangent   [[attribute(LMR3DVertexAttribute_Tangent)]];
        float3 bitangent [[attribute(LMR3DVertexAttribute_Bitangent)]];
    };
    
    struct PNTTBVertexOut {
        float4 position [[position]];
        float3 pos;
        float3 normal;
        float2 texture;
        float3 tangent;
        float3 bitangent;
    };
    
    static constexpr sampler linearSampler (mag_filter::linear,
                                          min_filter::linear);
    
    static float4 getDiffColor(texture2d<half> map_md, constant LMR3DObjParams &obj, float2 texcoord) {
        if (obj.isDiffuseTexture) {
            return float4(map_md.sample(linearSampler, texcoord));
        } else {
            return obj.diffuseColor;
        }
    }
    
    static float4 getSpecularColor(texture2d<half> map_ks, constant LMR3DObjParams &obj, float2 texcoord) {
        if (obj.isSpecularTexture) {
            return float4(map_ks.sample(linearSampler, texcoord));
        } else {
            return obj.specularColor;
        }
    }
    
    static float3 getNormal(texture2d<half> map_kn, constant LMR3DObjParams &obj, PNTTBVertexOut in [[stage_in]]) {
        float3 normal = normalize(in.normal);
        if (obj.isNormalTexture) {
            float4 kn_sample = float4(map_kn.sample(linearSampler, in.texture));
            float3 tangent_normal = normalize((kn_sample.xyz * 2.0) - 1.0);
            normal = normalize(tangent_normal.x * in.tangent + tangent_normal.y * in.bitangent + tangent_normal.z * in.normal);
        }
        return normal;
    }
}
