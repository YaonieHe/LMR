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
                                            constant LMR3DViewParams &viewParam [[buffer(ObjectBufferIndex_View)]],
                                            constant LMR3DObjParams &objParam [[buffer(ObjectBufferIndex_Obj)]]) {
        VertexOut out;
        float4 pos = param.modelM * float4(in.position, 1);
        out.position = param.projectM * param.viewM * pos;
        out.pos = pos.xyz / pos.w;
        out.normal = param.normalM * in.normal;
        out.texture = in.texture;
        return out;
    }
    
}
