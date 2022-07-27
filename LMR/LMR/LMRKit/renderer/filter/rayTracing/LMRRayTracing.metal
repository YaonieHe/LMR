//  Created on 2022/7/27.

#include <metal_stdlib>
#import "LMRRayTracing.h"

using namespace metal;


namespace LMRRT {
    constant unsigned int primes[] = {
        2,   3,  5,  7,
        11, 13, 17, 19,
        23, 29, 31, 37,
        41, 43, 47, 53,
    };
    
    float halton(unsigned int i, unsigned int d) {
        unsigned int b = primes[d];
        float f = 1.0;
        float invB = 1.0 / b;
        float r = 0;
        
        while (i > 0) {
            f = f * invB;
            r = r + f * (i % b);
            i = i / b;
        }
        return r;
    }
    
    kernel void rayKernel(uint2 tid [[thread_position_in_grid]],
                          constant LMRRTUniforms & uniforms,
                          device LMRRTRay *rays,
                          texture2d<unsigned int> randomTex,
                          texture2d<float, access::write> dstTex) {
        if (tid.x < uniforms.width && tid.y < uniforms.height) {
            unsigned int rayIdx = tid.y * uniforms.width + tid.x;
            
            device LMRRTRay & ray = rays[rayIdx];
            
            float2 pixel = (float2)tid;
            unsigned int offset = randomTex.read(tid).x;
            
            // 随机偏移抗锯齿
            pixel += float2(halton(offset + uniforms.frameIndex, 0), halton(offset + uniforms.frameIndex, 1));
            
            float2 uv = (float2)pixel / float2(uniforms.width, uniforms.height) * 2.0 - 1.0;
            
            constant LMRRTCamera & camera = uniforms.camera;
            
            ray.origin = camera.position;
            ray.direction = normalize(uv.x * camera.right + uv.y * camera.up + camera.forward);
            ray.mask = LMRRTRayMaskPrimary;
            ray.maxDidtance = INFINITY;
            ray.color = float3(1.0, 1.0, 1.0);
            
            dstTex.write(float4(0.0, 0.0, 0.0, 0.0), tid);
        }
    }
    
    template<typename T>
    inline T interpolateVertexAttribute(device T *attributes, LMRRTIntersection intersection) {
        float3 uvw;
        uvw.xy = intersection.coordinates;
        uvw.z = 1 - uvw.x - uvw.y;
        
        unsigned int index = intersection.primitiveIndex;
        
        T t0 = attributes[index * 3];
        T t1 = attributes[index * 3 + 1];
        T t2 = attributes[index * 3 + 2];
        
        return t0 * uvw.x + t1 * uvw.y + t2 * uvw.z;
    }
    
    inline void sampleAreaLight(constant LMRRTAreaLight & light,
                                float2 u,
                                float3 position,
                                thread float3 & lightDirection,
                                thread float3 & lightColor,
                                thread float & lightDistance) {
        u = u * 2.0 - 1.0;
        float3 samplePosition = light.position + light.right * u.x + light.up * u.y;
        lightDirection = samplePosition - position;
        lightDistance = length(lightDirection);
        float inverseLightDistance = 1.0 / max(lightDistance, 0.001);
        
        lightDirection *= inverseLightDistance;
        lightColor = light.color * (inverseLightDistance * inverseLightDistance) * saturate(dot(-lightDirection, light.forward));
    }
    
    inline float3 sampleCosineWeightHemisphere(float2 u) {
        float phi = 2.0 * M_PI_F * u.x;
        float cos_phi;
        float sin_phi = sincos(phi, cos_phi);
        
        float cos_theta = sqrt(u.y);
        float sin_theta = sqrt(1.0 - cos_theta * cos_theta);
        
        return float3(sin_theta * cos_phi, cos_theta, sin_theta * sin_phi);
    }
    
    inline float3 alignHemisphereWithNormal(float3 sample, float3 normal) {
        float3 up = normal;
        float3 right = normalize(cross(normal, float3(0.0072, 1.0, 0.0034)));
        float3 forward = cross(right, up);
        
        return sample.x * right + sample.y * up + sample.z * forward;
    }
    
    kernel void shadeKernel(uint2 tid [[thread_position_in_grid]],
                            constant LMRRTUniforms & uniforms,
                            device LMRRTRay *rays,
                            device LMRRTRay *shadowRays,
                            device LMRRTIntersection *intersections,
                            device float3 *colors,
                            device float3 *normals,
                            device uint *masks,
                            constant unsigned int & bounce,
                            texture2d<unsigned int> randomTex,
                            texture2d<float, access::write> dstTex) {
        if (tid.x < uniforms.width && tid.y < uniforms.height) {
            unsigned int rayIdx = tid.y * uniforms.width + tid.x;
            device LMRRTRay & ray = rays[rayIdx];
            device LMRRTRay & shadowRay = shadowRays[rayIdx];
            device LMRRTIntersection & intersection = intersections[rayIdx];
            
            float3 color = ray.color;
            
            if (ray.maxDidtance >= 0.0 && intersection.distance >= 0.0) {
                uint mask = masks[intersection.primitiveIndex];
                
                if (mask == LMRRTTriangleMaskGeometry) {
                    float3 intersectionPoint = ray.origin + ray.direction * intersection.distance;
                    
                    float3 surfaceNormal = normalize(interpolateVertexAttribute(normals, intersection));
                    
                    unsigned int offset = randomTex.read(tid).x;
                    
                    float2 r = float2(halton(offset + uniforms.frameIndex, 2 + bounce * 4), halton(offset + uniforms.frameIndex, 2 + bounce * 4 + 1));
                    
                    float3 lightDirection;
                    float3 lightColor;
                    float lightDistance;
                    sampleAreaLight(uniforms.light, r, intersectionPoint, lightDirection, lightColor, lightDistance);
                    
                    lightColor *= saturate(dot(surfaceNormal, lightDirection));
                    
                    color *= interpolateVertexAttribute(colors, intersection);
                    
                    shadowRay.origin = intersectionPoint + surfaceNormal * 0.001;
                    shadowRay.direction = lightDirection;
                    shadowRay.mask = LMRRTRayMaskShadow;
                    shadowRay.maxDidtance = lightDistance - 0.001;
                    shadowRay.color = lightColor * color;
                    
                    r = float2(halton(offset + uniforms.frameIndex, 2 + bounce * 4 + 2), halton(offset + uniforms.frameIndex, 2 + bounce * 4 + 3));
                    
                    float3 sampleDirection = sampleCosineWeightHemisphere(r);
                    sampleDirection = alignHemisphereWithNormal(sampleDirection, surfaceNormal);
                    
                    ray.origin = intersectionPoint + surfaceNormal * 0.001;
                    ray.direction = sampleDirection;
                    ray.color = color;
                    ray.mask = LMRRTRayMaskSecondary;
                } else {
                    dstTex.write(float4(uniforms.light.color, 1.0), tid);
                    ray.maxDidtance = -1.0;
                    shadowRay.maxDidtance = -1.0;
                }
            } else {
                ray.maxDidtance = -1;
                shadowRay.maxDidtance = -1.0;
            }
        }
    }
    
    constant float2 quadVertices[] = {
        float2(-1, -1),
        float2(-1,  1),
        float2( 1,  1),
        float2(-1, -1),
        float2( 1,  1),
        float2( 1, -1)
    };
    
    struct CopyVertexOut {
        float4 position [[position]];
        float2 uv;
    };
    
    vertex CopyVertexOut copyVertex(unsigned short vid [[vertex_id]]) {
        float2 position = quadVertices[vid];
        
        CopyVertexOut out;
        
        out.position = float4(position, 0, 1);
        out.uv = position * 0.5f + 0.5f;
        
        return out;
    }
    
    fragment float4 copyFragment(CopyVertexOut in [[stage_in]],
                                 texture2d<float> tex)
    {
        constexpr sampler sam(min_filter::nearest, mag_filter::nearest, mip_filter::none);
        
        float3 color = tex.sample(sam, in.uv).xyz;
        
        // Apply a very simple tonemapping function to reduce the dynamic range of the
        // input image into a range which can be displayed on screen.
        color = color / (1.0f + color);
        
        return float4(color, 1.0f);
    }
}
