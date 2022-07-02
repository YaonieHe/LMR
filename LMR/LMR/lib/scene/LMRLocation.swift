//
//  LMRLocation.swift
//  LMR
//
//  Created by hjp-Mic on 2022/7/2.
//

import UIKit
import simd

class LMRLocation {
    open var position: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    /// x - 左右旋转， y 上下旋转
    open var rotate: SIMD2<Float> = SIMD2<Float>(0, 0)
    open var scale: Float = 1
    
    open var transform: float4x4 {
        var matrix = float4x4(translationBy: position)
        matrix = matrix * float4x4(rotationAroundAxis: SIMD3<Float>(1, 0, 0), by: rotate.y)
        matrix = matrix * float4x4(rotationAroundAxis: SIMD3<Float>(0, 1, 0), by: rotate.x)
        matrix = matrix * float4x4(scale: SIMD3<Float>(scale, scale, scale))
        return matrix
    }
}
