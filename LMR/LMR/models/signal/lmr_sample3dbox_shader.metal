//  Created on 2022/6/22.

#include <metal_stdlib>
using namespace metal;


namespace lmr_smaple3dbox {
    struct VertexIn {
        float3 position [[attribute(0)]];
        float3 normal   [[attribute(1)]];
        float2 texture  [[attribute(2)]];
    };
    
    struct VertexParam {
        float4x4 projectM;
        float4x4 viewM;
        float4x4 modelM;
    };

    struct VertexOut {
        float4 position [[position]];
        float3 normal;
        float2 texture;
    };
    
    vertex VertexOut vertex_main(VertexIn in [[stage_in]], constant VertexParam &param [[buffer(1)]]) {
        VertexOut out;
        out.position = param.projectM * param.viewM * param.modelM * float4(in.position, 1);
        out.normal = (param.viewM * param.modelM * float4(in.normal, 0)).xyz;
        out.texture = in.texture;
        return out;
    }
    
    fragment half4 fragment_main(VertexOut in [[stage_in]], texture2d<half> map_md [[texture(0)]]) {
//        return half4(1, 1, 0, 1);
        constexpr sampler sampler (mag_filter::linear,
                                              min_filter::linear);
        half4 color = map_md.sample(sampler, in.texture);
        return color;//half4(in.texture[0], in.texture[1], 0, 1);
    }
}
