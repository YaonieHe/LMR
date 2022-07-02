//
//  LMRLight.swift
//  LMR
//
//  Created by hjp-Mic on 2022/7/2.
//

import UIKit

class LMRLight: NSObject {
    open var position: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    open var color: SIMD3<Float> = SIMD3<Float>(1, 1, 1)
    open var object: LMRObject?
}
