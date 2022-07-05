//
//  LMRScene.swift
//  LMR
//
//  Created by hjp-Mic on 2022/7/2.
//

import UIKit

class LMRScene {
    open var camera: LMRCamera = LMRCamera()
    open var objects: [LMRObject] = [LMRObject]()
    open var lights: [LMRLight] = [LMRLight]()
    open var ambientColor: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
}
