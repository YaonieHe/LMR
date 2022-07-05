//
//  LMRCamera.swift
//  LMR
//
//  Created by hjp-Mic on 2022/7/2.
//

import UIKit

import simd

class LMRCamera {
    open var position: SIMD3<Float> = SIMD3<Float>(0, 0, 1)
    open var up: SIMD3<Float> = SIMD3<Float>(0, 1, 0)
    open var target: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    
    open var viewMatrix: float4x4 {
        return float4x4.lookAtRightHand(eye: position, center: target, up: up)
    }
    
    open var nearZ: Float = 0.1
    open var farZ: Float = 100
    open var field: Float = radians_from_degrees(45)
    open var aspect: Float = 1
    
    open var projectMatrix: float4x4 {
        let matrix = float4x4(perspectiveRightHandWithFovy: field, aspectRatio: aspect, nearZ: nearZ, farZ: farZ)
        return matrix
    }
    
}
