//  Created on 2022/7/5.

#include <metal_stdlib>
using namespace metal;

#include "../common/LMRShaderCommon.metal"

namespace LMR3D {
    typedef enum ObjectBufferIndex
    {
        ObjectBufferIndex_MeshPositions = 0,
        ObjectBufferIndex_View,
        ObjectBufferIndex_Obj,
    } ObjectBufferIndex;

    typedef enum ObjectTextureIndex
    {
        ObjectTextureIndex_BaseColor = 0,
    } ObjectTextureIndex;
    
    vertex VertexOut vertexObject(VertexIn in [[stage_in]],
                        constant LMR3DViewParams &viewParam [[buffer(ObjectBufferIndex_View)]],
                        constant LMR3DObjParams &objParam [[buffer(ObjectBufferIndex_Obj)]]) {
        VertexOut out;
        out.position = viewParam.viewProjectionMatrix * objParam.modelMatrix * float4(in.position, 1);
        out.texture = in.texture;
        return out;
    }
    
    fragment half4 fragmentObjectColor(VertexOut in [[stage_in]],
                                       constant LMR3DObjParams &objParam [[buffer(ObjectBufferIndex_Obj)]]) {
        return half4(objParam.diffuseColor);
    }
}
