//  Created on 2022/6/22.

#include <metal_stdlib>
using namespace metal;

namespace lmr_smaple {
    struct VertexIn {
        float3 position [[attribute(0)]];
        float2 texture   [[attribute(1)]];
    };

    struct VertexOut {
        float4 position [[position]];
        float2 texture;
    };
    
    vertex VertexOut vertex_main(VertexIn in [[stage_in]]) {
        VertexOut out;
        out.position = float4(in.position, 1);
        out.texture = in.texture;
        return out;
    }
    
    fragment half4 fragment_main(VertexOut in [[stage_in]]) {
        return half4(in.texture[0], in.texture[1], 0, 1);
    }
}



