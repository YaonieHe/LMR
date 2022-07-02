//
//  LMRCamera.swift
//  LMR
//
//  Created by hjp-Mic on 2022/7/2.
//

import UIKit

import simd

class LMRCamera {
    open var position: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    /// x - 左右旋转， y 上下旋转
    open var rotate: SIMD2<Float> = SIMD2<Float>(0, 0)
    
    open var viewMatrix: float4x4 {
        var matrix = matrix_identity_float4x4
        matrix = matrix * float4x4(rotationAroundAxis: SIMD3<Float>(1, 0, 0), by: -rotate.y)
        matrix = matrix * float4x4(rotationAroundAxis: SIMD3<Float>(0, 1, 0), by: -rotate.x)
        matrix = matrix * float4x4(translationBy: -position)
        return matrix
    }
    
    open var nearZ: Float = 0.1
    open var farZ: Float = 100
    open var field: Float = radians_from_degrees(45)
    open var aspect: Float = 1
    
    open var projectMatrix: float4x4 {
        let matrix = float4x4(perspectiveProjectionRHFovY: field, aspectRatio: aspect, nearZ: nearZ, farZ: farZ)
        return matrix
    }
    
}
