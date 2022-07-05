//  Created on 2022/7/5.

#ifndef LMRShaderCommon_h
#define LMRShaderCommon_h

#include <simd/simd.h>

typedef enum LMR3DVertexAttribute {
    LMR3DVertexAttribute_Position  = 0,
    LMR3DVertexAttribute_Texcoord  = 1,
    LMR3DVertexAttribute_Normal    = 2
} LMR3DVertexAttribute;

typedef enum LMR3DTextureIndex {
    LMR3DTextureIndex_BaseColor = 0,
    LMR3DTextureIndex_Specular  = 1,
    LMR3DTextureIndex_Normal    = 2,
    LMR3DTextureIndex_ShadowCube   = 3
} LMR3DTextureIndex;

typedef struct  {
    vector_float3 cameraPos;
    matrix_float4x4 viewProjectionMatrix;
} LMR3DViewParams;

typedef struct  {
    matrix_float4x4 modelMatrix;
    vector_float4 diffuseColor;
    vector_float4 specularColor;
    float shininess;
} LMR3DObjParams;

#endif /* LMRShaderCommon_h */
