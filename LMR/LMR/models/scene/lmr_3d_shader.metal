//
//  lmr_3d_shader.metal
//  LMR
//
//  Created by hjp-Mic on 2022/7/2.
//

#include <metal_stdlib>
using namespace metal;


namespace lmr_3d {
    struct VertexIn {
        float3 position [[attribute(0)]];
        float3 normal   [[attribute(1)]];
        float2 texture  [[attribute(2)]];
    };
    
    struct VertexParam {
        float4x4 projectM;
        float4x4 viewM;
        float4x4 modelM;
        float3x3 normalM;
    };
    
    struct VertexOut {
        float4 position [[position]];
        float3 pos;
        float3 normal;
        float2 texture;
    };
    
    struct Material {
        bool map_md;
        float4 color;
        float diffuse;
        float specular;
        float shininess;
    };
    
    struct Light {
        float3 color;
        float3 position;
    };
    
    constexpr sampler sampler (mag_filter::linear,
                                          min_filter::linear);
    
    float4 get_md_color(texture2d<half> map_md, constant Material &m, float2 texture) {
        if (m.map_md) {
            return float4(map_md.sample(sampler, texture));
        } else {
            return m.color;
        }
    }
    
    vertex VertexOut obj_v(VertexIn in [[stage_in]],
                           constant VertexParam &param [[buffer(1)]]) {
//                         ushort iid [[instance_id]]
        VertexOut out;
        float4 pos = param.modelM * float4(in.position, 1);
        out.position = param.projectM * param.viewM * pos;
        out.pos = pos.xyz / pos.w;
        out.normal = param.normalM * in.normal;
        out.texture = in.texture;
        return out;
    }
    
    
    float shadow_calculation(float3 pos, float3 light_pos, texturecube<float> map) {
        float3 pos_to_light = pos - light_pos;
        float closest_depth = map.sample(sampler, pos_to_light).r;
        float current_depth = length(pos_to_light);
        return closest_depth;//current_depth -  closest_depth > 0.01 ? 1.0 : 0.0;
    }
    
    
    fragment half4 obj_f_phong(VertexOut in [[stage_in]],
                         texture2d<half> map_md [[texture(0)]],
                         texturecube<float> shadow_depth [[texture(1)]],
                         constant float3 &view_pos [[buffer(0)]],
                         constant Material &m [[buffer(1)]],
                         constant float3 &ambient_color [[buffer(2)]],
                         constant int &light_count [[buffer(3)]],
                         constant Light *lights [[buffer(4)]]) {
        float3 color = float3(0, 0, 0);
        float4 md = get_md_color(map_md, m, in.texture);
        float3 ambient = ambient_color * md.rgb;
        color += ambient;
        
        for (int i = 0; i < light_count; i++) {
            Light light = lights[i];
            
            float shadow = shadow_calculation(in.pos, light.position, shadow_depth);
            
            float3 lightDir = normalize(light.position - in.pos);
            float3 normal = normalize(in.normal);
            
            float diffFactor = max(dot(lightDir, normal), 0.0);
            float3 diffuse = m.diffuse * diffFactor * light.color * md.rgb;
            
            float3 reflectDir = normalize(reflect(-lightDir, normal));
            float3 viewDir = normalize(view_pos - in.pos);
            float specFactor = pow(max(dot(reflectDir, viewDir), 0.0), m.shininess);
            float3 specular = m.specular * specFactor * light.color * md.rgb;
            
            color = color + clamp(diffuse + specular, 0, 1)  * (1 - shadow);
        }
        color = clamp(color, 0, 1);
        return half4(half3(color), md.a);
    }
    
    fragment half4 obj_f_blinn_phong(VertexOut in [[stage_in]],
                         texture2d<half> map_md [[texture(0)]],
                         texturecube<float> shadow_depth [[texture(1)]],
                         constant float3 &view_pos [[buffer(0)]],
                         constant Material &m [[buffer(1)]],
                         constant float3 &ambient_color [[buffer(2)]],
                         constant int &light_count [[buffer(3)]],
                         constant Light *lights [[buffer(4)]]) {
        float3 color = float3(0, 0, 0);
        float4 md = get_md_color(map_md, m, in.texture);
        
        float3 ambient = ambient_color * md.rgb;
        color += ambient;
        
        for (int i = 0; i < light_count; i++) {
            Light light = lights[i];
            
            
            return half4(half(shadow_depth.sample(sampler, in.pos - light.position).a), 0, 0, 1);
            float shadow = shadow_calculation(in.pos, light.position, shadow_depth);
            
            float3 lightDir = normalize(light.position - in.pos);
            float3 normal = normalize(in.normal);
            
            float diffFactor = max(dot(lightDir, normal), 0.0);
            float3 diffuse = m.diffuse * diffFactor * light.color * md.rgb;
            
            float3 viewDir = normalize(view_pos - in.pos);
            float3 h = normalize(viewDir + lightDir);
            float specFactor = pow(max(dot(normal, h), 0.0), m.shininess);
            float3 specular = m.specular * specFactor * light.color * md.rgb;
            
            color = color + clamp(diffuse + specular, 0, 1) * (1 - shadow);
        }
        color = clamp(color, 0, 1);
        return half4(half3(color), md.a);
    }
    
    fragment half4 light_f(VertexOut in [[stage_in]], texture2d<half> map_md [[texture(0)]],
                           constant Light &light [[buffer(0)]]) {
        half3 color = half3(light.color);
        return half4(color, 1);
    }
    
    struct ShadowVertexOut {
        float4 position [[position]];
        float3 pos;
        uint layer [[render_target_array_index]];
    };
    
    struct ShadowFragmentOut {
        float depth [[depth(less)]];
    };
    
    vertex ShadowVertexOut shadow_depth_v(VertexIn in [[stage_in]],
                          constant float4x4 &modelM [[buffer(1)]],
                          constant float4x4 &viewM [[buffer(2)]],
                          constant float4x4 &projectM [[buffer(3)]],
                          uint iid [[instance_id]]) {
        ShadowVertexOut out;
        float4 pos = viewM[iid] * modelM * float4(in.position, 1);
        out.position = projectM * pos;
        out.pos = pos.xyz / pos.w;
        out.layer = iid;
        return out;
    }
    
    fragment ShadowFragmentOut shadow_depth_f(ShadowVertexOut in [[stage_in]]) {
        ShadowFragmentOut out;
        out.depth = 0.5;//length(in.pos);
        return out;
    }
}
