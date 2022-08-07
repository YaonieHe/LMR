//
//  LMRTileForwardPlusShader.h
//  LMR
//
//  Created by hjp-Mic on 2022/8/7.
//

#ifndef LMRTileForwardPlusShader_h
#define LMRTileForwardPlusShader_h

#include "../common/LMRShaderCommon.h"

typedef enum LMRTFPThreadgroupIndices
{
    LMRTFPThreadgroupIndices_LightList  = 0,
    LMRTFPThreadgroupIndices_TileData  = 1,
} LMRTFPThreadgroupIndices;

typedef struct {
    vector_float3 color;
    vector_float3 position;
    float radius;
} LMRTFPLightParam;

typedef struct {
    vector_float2 depthUnproject;
    vector_float3 screenToViewSpace;
    vector_float3 ambient;
    uint lightCount;
    int maxLightPerTile;
} LMRTFPFrameData;

struct LMRTFPFairyParam
{
    int vertexCount;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
};

#endif /* LMRTileForwardPlusShader_h */
