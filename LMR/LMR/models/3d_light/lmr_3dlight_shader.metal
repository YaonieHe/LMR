//  Created on 2022/6/22.

#include <metal_stdlib>
using namespace metal;


namespace lmr_3dlight {
    struct VertexIn {
        float3 position [[attribute(0)]];
        float3 normal   [[attribute(1)]];
        float2 texture  [[attribute(2)]];
    };
    
    struct VertexParam {
        float4x4 projectM;
        float4x4 viewM;
        float4x4 modelM;
        float3x3 frag_normalM;
    };

    struct VertexOut {
        float4 position [[position]];
        float3 frag_pos;
        float3 frag_normal;
        float3 normal;
        float2 texture;
    };
    
    struct Material {
        float3 color;
        float shininess;
    };
    
    struct Light {
        float ambient;
        float specular;
        float3 color;
        float3 position;
    };
    
    vertex VertexOut vertex_main(VertexIn in [[stage_in]], constant VertexParam &param [[buffer(1)]]) {
        VertexOut out;
        float4 frag_pos = param.modelM * float4(in.position, 1);
        out.position = param.projectM * param.viewM * frag_pos;
        out.normal = (param.viewM * param.modelM * float4(in.normal, 0)).xyz;
        out.texture = in.texture;
        out.frag_pos = frag_pos.xyz;
        out.frag_normal = param.frag_normalM * in.normal;
        return out;
    }
    
    fragment half4 fragment_main(VertexOut in [[stage_in]], texture2d<half> map_md [[texture(0)]], constant Light &light [[buffer(2)]], constant Material &m [[buffer(3)]], constant float3 &view_pos [[buffer(4)]]) {
        float3 ambient = light.ambient * light.color * m.color;
        
        float3 lightDir = normalize(light.position - in.frag_pos);
        float3 normal = normalize(in.frag_normal);
        
        float diffFactor = max(dot(lightDir, normal), 0.0);
        float3 diffuse = diffFactor * light.color * m.color;
        
        float3 reflectDir = normalize(reflect(-lightDir, normal));
        float3 viewDir = normalize(view_pos - in.frag_pos);
        float specFactor = pow(max(dot(reflectDir, viewDir), 0.0), m.shininess);
        float3 specular = light.specular * specFactor * light.color * m.color;
        
        half3 color = half3(ambient + diffuse + specular);
        return half4(color, 1);
    }
    
    fragment half4 f_light(VertexOut in [[stage_in]], texture2d<half> map_md [[texture(0)]], constant Light &light [[buffer(2)]]) {
        half3 color = half3(light.color);
        return half4(color, 1);
    }
}
