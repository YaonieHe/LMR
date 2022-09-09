//  Created on 2022/8/31.

#ifndef LMRMainlandShader_h
#define LMRMainlandShader_h

struct LMRTECameraUniforms {
    simd::float4x4      viewMatrix;
    simd::float4x4      projectionMatrix;
    simd::float4x4      viewProjectionMatrix;
    simd::float4x4      invOrientationProjectionMatrix;
    simd::float4x4      invViewProjectionMatrix;
    simd::float4x4      invProjectionMatrix;
    simd::float4x4      invViewMatrix;
    simd::float4        frustumPlanes[6];
};

struct LMRTEUniforms {
    LMRTECameraUniforms cameraUniforms;
    AAPLCameraUniforms  shadowCameraUniforms[3];
};

#endif /* LMRMainlandShader_h */
