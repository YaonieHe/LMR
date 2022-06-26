//
//  LMRMaterial.swift
//  LMR
//
//  Created by hjp-Mic on 2022/6/26.
//

import UIKit
import simd

class LMRMaterial: NSObject {
    open var md_color: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    open var map_md: String?
    open var shininess: Float = 128
}
