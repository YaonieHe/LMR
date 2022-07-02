//
//  lmr_3d_param.swift
//  LMR
//
//  Created by hjp-Mic on 2022/7/2.
//

import Foundation
import simd

struct LMR3DError: Error {
    var description: String
}

struct LMR3DVertexParam {
    var projectM: float4x4
    var viewM: float4x4
    var modelM: float4x4
    var normalM: float3x3
};

struct LMR3DFragLight {
    var color: SIMD3<Float>
    var position: SIMD3<Float>
};

struct LMR3DFragMaterial {
    var isMapKd: Bool
    var color: SIMD4<Float>
    var diffuse: Float
    var specular: Float
    var shininess: Float
};
