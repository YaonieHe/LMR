//  Created on 2022/7/5.

#include <metal_stdlib>

#include "LMRShaderCommon.h"

using namespace metal;

namespace LMR3D {
    struct VertexIn {
        float3 position [[attribute(LMR3DVertexAttribute_Position)]];
        float2 texture  [[attribute(LMR3DVertexAttribute_Texcoord)]];
        float3 normal   [[attribute(LMR3DVertexAttribute_Normal)]];
    };
    
    struct VertexOut {
        float4 position [[position]];
        float3 pos;
        float3 normal;
        float2 texture;
    };
}
