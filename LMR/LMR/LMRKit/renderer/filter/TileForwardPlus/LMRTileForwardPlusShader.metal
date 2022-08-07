//
//  LMRTileForwardPlusShader.metal
//  LMR
//
//  Created by hjp-Mic on 2022/8/7.
//

#include <metal_stdlib>
using namespace metal;

#include "../common/LMRShaderCommon.metal"

#include "LMRTileForwardPlusShader.h"

namespace LMR3D {
    typedef enum BufferIndex
    {
        BufferIndex_MeshPositions = 0,
        BufferIndex_View,
        BufferIndex_Obj,
        BufferIndex_Ambiant,
        BufferIndex_Light,
        BufferIndex_FrameData
    } BufferIndex;
    
    struct TFPColorData
    {
        half4 lighting [[color(0)]];
        float depth    [[color(1)]];
    } ;
    
    struct TFPTileData
    {
        atomic_int numLights;
        float minDepth;
        float maxDepth;
    };
    
    vertex PNTTBVertexOut vertexTFPPreDepth(PNTTBVertexIn in [[stage_in]],
                                            constant LMR3DViewParams &viewParam [[buffer(BufferIndex_View)]],
                                            constant LMR3DObjParams &objParam [[buffer(BufferIndex_Obj)]]) {
         PNTTBVertexOut out;
         float4 pos = objParam.modelMatrix * float4(in.position, 1);
         out.position = viewParam.viewProjectionMatrix * pos;
         out.pos = pos.xyz / pos.w;
         return out;
     }
    
    fragment TFPColorData fragmentTFPPreDepth(PNTTBVertexOut in [[stage_in]]) {
        TFPColorData out;
        out.depth = in.position.z;
//        out.lighting = half4(0, 1, in.position.z, 1);
        return out;
    }
    
    kernel void TFPBinCreate(imageblock<TFPColorData, imageblock_layout_implicit> imageBlock,
                             threadgroup TFPTileData *tileData [[threadgroup(LMRTFPThreadgroupIndices_TileData)]],
                             ushort2 thread_local_position [[thread_position_in_threadgroup]],
                             uint thread_linear_id [[thread_index_in_threadgroup]],
                             uint quad_lane_id [[thread_index_in_quadgroup]]) {
        TFPColorData f = imageBlock.read(thread_local_position);
        
        if (thread_linear_id == 0) {
            tileData -> minDepth = INFINITY;
            tileData -> maxDepth = 0.0;
        }
        
        threadgroup_barrier(mem_flags::mem_threadgroup);
        
        float minDepth = f.depth;
        minDepth = min(minDepth, quad_shuffle_xor(minDepth, 0x2));
        minDepth = min(minDepth, quad_shuffle_xor(minDepth, 0x1));
        
        float maxDepth = f.depth;
        maxDepth = max(maxDepth, quad_shuffle_xor(maxDepth, 0x2));
        maxDepth = max(maxDepth, quad_shuffle_xor(maxDepth, 0x1));
        
        if (quad_lane_id == 0) {
            atomic_fetch_min_explicit((threadgroup atomic_uint *)&tileData->minDepth, as_type<uint>(minDepth), memory_order_relaxed);
            atomic_fetch_max_explicit((threadgroup atomic_uint *)&tileData->maxDepth, as_type<uint>(maxDepth), memory_order_relaxed);
        }
    }
    
    static float unprojectDepth(constant LMRTFPFrameData & frameData, float depth) {
        const float2 unproject = frameData.depthUnproject;
        return unproject.y / (depth - unproject.x);
    }
    
    static float2 screen_to_view_at_z1(constant LMRTFPFrameData & frameData, ushort2 screen) {
        const float3 toView = frameData.screenToViewSpace;
        return float2(screen) * float2(toView.x, -toView.x) + float2(toView.y, -toView.z);
    }
    
    struct TFPPlane {
        float3 normal;
        float offset;
    };
    
    static float distance_point_plane(thread const TFPPlane & plane, float3 point) {
        return dot(plane.normal, point) - plane.offset;
    }
    
    kernel void TFPCullLights(imageblock<TFPColorData, imageblock_layout_implicit> imageBlock,
                              constant LMRTFPFrameData &frameData [[buffer(BufferIndex_FrameData)]],
                              device LMRTFPLightParam *lights [[buffer(BufferIndex_Light)]],
                              threadgroup int *visibleLights [[threadgroup(LMRTFPThreadgroupIndices_LightList)]],
                              threadgroup TFPTileData *tileData [[threadgroup(LMRTFPThreadgroupIndices_TileData)]],
                              ushort2 threadgroup_size [[threads_per_threadgroup]],
                              ushort2 threadgroup_id [[threadgroup_position_in_grid]],
                              uint thread_linear_id [[thread_index_in_threadgroup]]) {
        uint threadgroup_linear_size = threadgroup_size.x * threadgroup_size.y;
        
        if (thread_linear_id == 0) {
            atomic_store_explicit(&tileData->numLights, 0, memory_order_relaxed);
        }
        threadgroup_barrier(mem_flags::mem_threadgroup);
        
        float minDepthView = unprojectDepth(frameData, tileData->minDepth);
        float maxDepthView = unprojectDepth(frameData, tileData->maxDepth);
        
        float2 minTileViewAtZ1 = screen_to_view_at_z1(frameData, threadgroup_id * threadgroup_size);
        float2 maxTileViewAtZ1 = screen_to_view_at_z1(frameData, (threadgroup_id + 1) * threadgroup_size);
        
        TFPPlane tilePlanes[6] {
            {normalize(float3(1, 0, -maxTileViewAtZ1.x)), 0}, //  right
            {normalize(float3(0, 1, -minTileViewAtZ1.y)), 0}, // top
            {normalize(float3(-1, 0, minTileViewAtZ1.x)), 0}, // left
            {normalize(float3(0, -1, maxTileViewAtZ1.y)), 0}, // bottom
            {normalize(float3(0, 0, -1)), -minDepthView}, // near
            {normalize(float3(0, 0, 1)), maxDepthView}, // far
        };
        
        for (uint baseLightId = 0; baseLightId < frameData.lightCount; baseLightId += threadgroup_linear_size) {
            uint lightId= baseLightId + thread_linear_id;
            
            if (lightId >= frameData.lightCount) {
                break;
            }
            
            LMRTFPLightParam light = lights[lightId];
            
            float3 pos = light.position;
            float radius = light.radius;
            
            bool visible = true;
            
            for (int j = 0; j < 6; j++) {
                if (distance_point_plane(tilePlanes[j], pos) > radius) {
                    visible = false;
                    break;
                }
            }
            
            if (visible) {
                int slot = atomic_fetch_add_explicit(&tileData->numLights, 1, memory_order_relaxed);
                if (slot < frameData.maxLightPerTile) {
                    visibleLights[slot] = (int)lightId;
                }
            }
        }
    }
    
    vertex PNTTBVertexOut vertexFTPForwardLight(PNTTBVertexIn in [[stage_in]],
                                       constant LMR3DViewParams &viewParam [[buffer(BufferIndex_View)]],
                                       constant LMR3DObjParams &objParam [[buffer(BufferIndex_Obj)]]) {
        PNTTBVertexOut out;
        float4 pos = objParam.modelMatrix * float4(in.position, 1);
        out.position = viewParam.viewProjectionMatrix * pos;
        out.pos = pos.xyz / pos.w;
        out.normal = normalize(objParam.normalMatrix * in.normal);
        out.texture = in.texture;
        out.tangent = normalize(objParam.normalMatrix * in.tangent);
        out.bitangent = -normalize(objParam.normalMatrix * in.bitangent);
        return out;
    }
    
    fragment half4 fragmentFTPForwardLight(PNTTBVertexOut in [[stage_in]],
                                           constant LMRTFPFrameData & frameData [[buffer(BufferIndex_FrameData)]],
                                           threadgroup int *visibleLights [[threadgroup(LMRTFPThreadgroupIndices_LightList)]],
                                           threadgroup TFPTileData *tileData [[threadgroup(LMRTFPThreadgroupIndices_TileData)]],
                                           device LMRTFPLightParam *lights [[buffer(BufferIndex_Light)]],
                                           constant LMR3DViewParams & viewParam [[buffer(BufferIndex_View)]],
                                           constant LMR3DObjParams & objParam [[buffer(BufferIndex_Obj)]],
                                           texture2d<half> map_kd [[texture(LMR3DTextureIndex_BaseColor)]],
                                           texture2d<half> map_ks [[texture(LMR3DTextureIndex_Specular)]],
                                           texture2d<half> map_kn [[texture(LMR3DTextureIndex_Normal)]]) {
        int numLights = min(atomic_load_explicit(&tileData->numLights, memory_order_relaxed), frameData.maxLightPerTile);
        
        float4 color = getDiffColor(map_kd, objParam, in.texture);
        float3 normal = getNormal(map_kn, objParam, in);
        float4 specilar = getSpecularColor(map_ks, objParam, in.texture);
        
        float3 out = color.xyz * frameData.ambient;
        
        float3 V = viewParam.cameraPos - in.pos;
        
        for (int i = 0; i < numLights; i++) {
            int lightId = visibleLights[i];
            
            device LMRTFPLightParam &light = lights[lightId];
            
            float3 toLight = light.position - in.pos;
            float3 H = normalize(toLight + V);
            
            float length_sq = dot(toLight, toLight);
            toLight = normalize(toLight);
            float attenuation = 1;//fmax(1.0 - sqrt(length_sq) / light.radius, 0);
            
            float diffuse = max(dot(normal, toLight), 0.0);
            out += light.color * color.xyz * diffuse * attenuation;
            
            out += powr(max(dot(normal, H), 0.0), objParam.shininess) * color.xyz * specilar.xyz * attenuation;
        }
        return half4(half3(out), 1.0);
    }

    struct TFPFairyOut
    {
        float4 position [[position]];
        half3 color;
    };

    vertex TFPFairyOut vertexTFPfairy(
                                   const device LMRTFPLightParam *light_data     [[ buffer(BufferIndex_Light) ]],
                                   uint iid                                    [[ instance_id ]],
                                   uint vid                                    [[ vertex_id ]],
                                   constant LMRTFPFairyParam & param          [[ buffer(BufferIndex_View) ]])
    {
        
        const device LMRTFPLightParam &light = light_data[iid];
        
        float angle = 2 * M_PI_F/ param.vertexCount;
        int point = vid % 2 ? (vid + 1) / 2 : -vid / 2;
        float3 vertex_position = float3(sin(angle * point), cos(angle * point), 0);
        
        float4 fairy_eye_pos = param.viewMatrix * float4(light.position ,1);
        
        TFPFairyOut out;
        out.position = param.projectionMatrix * float4(vertex_position + fairy_eye_pos.xyz,1);

        out.color = half3(light.color);

        return out;
    }

    fragment half4 fragmentTFPFairy(TFPFairyOut in [[ stage_in ]])
    {
        return half4(in.color.xyz, 1);
    }

    
}


