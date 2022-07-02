//
//  LMRMesh+Rect.swift
//  LMR
//
//  Created by hjp-Mic on 2022/7/2.
//

import UIKit

import simd

extension LMRMesh {
    class func lmr_rect(size: SIMD2<Float> = SIMD2<Float>(1, 1), color: SIMD4<Float> = SIMD4<Float>(0, 0, 0, 1)) -> LMRMesh {
        let mesh = LMRMesh()
        let submesh = LMRSubmesh()
        submesh.material.kd_color = color
        
        let w = size.x * 0.5
        let h = size.y * 0.5
        
        mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-w, h, 0), normal: SIMD3<Float>(0, 0, 1), texture: SIMD2<Float>(0, 0)))
        mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(w, h, 0), normal: SIMD3<Float>(0, 0, 1), texture: SIMD2<Float>(1, 0)))
        mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-w, -h, 0), normal: SIMD3<Float>(0, 0, 1), texture: SIMD2<Float>(0, 1)))
        mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(w, -h, 0), normal: SIMD3<Float>(0, 0, 1), texture: SIMD2<Float>(1, 1)))
        
        submesh.indexArray.append(contentsOf: [0, 1, 2, 1, 3, 2])
        
        mesh.submeshes.append(submesh)
        
        return mesh
    }
}
