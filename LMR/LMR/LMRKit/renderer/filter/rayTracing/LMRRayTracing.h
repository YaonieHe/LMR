//  Created on 2022/7/27.

#ifndef LMRRayTracing_h
#define LMRRayTracing_h

#include <simd/simd.h>

#define LMRRTTriangleMaskGeometry 1
#define LMRRTTriangleMaskLight 2

#define LMRRTRayMaskPrimary 3
#define LMRRTRayMaskShadow 1
#define LMRRTRayMaskSecondary 1

struct LMRRTRay {
    vector_float3 origin;
    uint mask;
    vector_float3 direction;
    float maxDidtance;
    vector_float3 color;
};

struct LMRRTIntersection {
    float distance;
    int primitiveIndex;
    vector_float2 coordinates;
};

typedef struct {
    vector_float3 position;
    vector_float3 right;
    vector_float3 up;
    vector_float3 forward;
} LMRRTCamera;

typedef struct {
    vector_float3 position;
    vector_float3 forward;
    vector_float3 right;
    vector_float3 up;
    vector_float3 color;
} LMRRTAreaLight;

struct LMRRTUniforms {
    unsigned int width;
    unsigned int height;
    unsigned int frameIndex;
    LMRRTCamera camera;
    LMRRTAreaLight light;
};

#endif /* LMRRayTracing_h */
