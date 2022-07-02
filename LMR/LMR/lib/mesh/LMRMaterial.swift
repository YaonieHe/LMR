//
//  LMRMaterial.swift
//  LMR
//
//  Created by hjp-Mic on 2022/6/26.
//

import UIKit
import simd

class LMRMaterial: NSObject {
    open var kd_color: SIMD4<Float> = SIMD4<Float>(0, 0, 0, 1)
    open var map_kd: String?
    open var diffuse: Float = 0.1
    open var specular: Float = 0.5
    open var shininess: Float = 1
}
