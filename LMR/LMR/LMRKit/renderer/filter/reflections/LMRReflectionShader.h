//  Created on 2022/8/16.

#ifndef LMRReflectionShader_h
#define LMRReflectionShader_h

typedef enum LMRRFBufferIndex
{
    LMRRFBufferIndex_MeshPositions = 0,
    LMRRFBufferIndex_View,
    LMRRFBufferIndex_Obj,
    LMRRFBufferIndex_Instance,
    LMRRFBufferIndex_Frame
} LMRRFBufferIndex;

typedef struct {
    vector_float3 ambientLightColor;
    vector_float3 directionalLightInvDirection;
    vector_float3 directionalLightColor;
} LMRRFFrameParam;

#endif /* LMRReflectionShader_h */
