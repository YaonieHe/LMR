//
//  LMR3DBox.swift
//  LMR
//
//  Created by hjp-Mic on 2022/6/26.
//

import UIKit
import simd

extension LMRMesh  {
    class func lmr_box(color: SIMD3<Float> = SIMD3<Float>(0, 0, 0), size: Float = 1) -> LMRMesh {
        let mesh = LMRMesh()
        let submesh = LMRSubmesh()
        submesh.material.md_color = color
        
        do { // 上
            let index = UInt32(mesh.vertexCount)
            
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, size, -size), normal: SIMD3<Float>(0, 1, 0), texture: SIMD2<Float>(0, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, size, -size), normal: SIMD3<Float>(0, 1, 0), texture: SIMD2<Float>(1, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, size, size), normal: SIMD3<Float>(0, 1, 0), texture: SIMD2<Float>(0, 1)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, size, size), normal: SIMD3<Float>(0, 1, 0), texture: SIMD2<Float>(1, 1)))
            
            submesh.indexArray.append(contentsOf: [index + 0, index + 1, index + 2, index + 1, index + 3, index + 2])
        }
        
        do { // 下
            let index = UInt32(mesh.vertexCount)
            
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, -size, size), normal: SIMD3<Float>(0, -1, 0), texture: SIMD2<Float>(0, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, -size, size), normal: SIMD3<Float>(0, -1, 0), texture: SIMD2<Float>(1, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, -size, -size), normal: SIMD3<Float>(0, -1, 0), texture: SIMD2<Float>(0, 1)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, -size, -size), normal: SIMD3<Float>(0, -1, 0), texture: SIMD2<Float>(1, 1)))
            
            submesh.indexArray.append(contentsOf: [index + 0, index + 1, index + 2, index + 1, index + 3, index + 2])
        }
        
        do { // 左
            let index = UInt32(mesh.vertexCount)
            
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, size, -size), normal: SIMD3<Float>(-1, 0, 0), texture: SIMD2<Float>(0, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, size, size), normal: SIMD3<Float>(-1, 0, 0), texture: SIMD2<Float>(1, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, -size, -size), normal: SIMD3<Float>(-1, 0, 0), texture: SIMD2<Float>(0, 1)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, -size, size), normal: SIMD3<Float>(-1, 0, 0), texture: SIMD2<Float>(1, 1)))
            
            submesh.indexArray.append(contentsOf: [index + 0, index + 1, index + 2, index + 1, index + 3, index + 2])
        }
        
        do { // 右
            let index = UInt32(mesh.vertexCount)
            
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, size, size), normal: SIMD3<Float>(1, 0, 0), texture: SIMD2<Float>(0, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, size, -size), normal: SIMD3<Float>(1, 0, 0), texture: SIMD2<Float>(1, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, -size, size), normal: SIMD3<Float>(1, 0, 0), texture: SIMD2<Float>(0, 1)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, -size, -size), normal: SIMD3<Float>(1, 0, 0), texture: SIMD2<Float>(1, 1)))
            
            submesh.indexArray.append(contentsOf: [index + 0, index + 1, index + 2, index + 1, index + 3, index + 2])
        }
        
        do { // 前
            let index = UInt32(mesh.vertexCount)
            
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, size, size), normal: SIMD3<Float>(0, 0, 1), texture: SIMD2<Float>(0, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, size, size), normal: SIMD3<Float>(0, 0, 1), texture: SIMD2<Float>(1, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, -size, size), normal: SIMD3<Float>(0, 0, 1), texture: SIMD2<Float>(0, 1)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, -size, size), normal: SIMD3<Float>(0, 0, 1), texture: SIMD2<Float>(1, 1)))
            
            submesh.indexArray.append(contentsOf: [index + 0, index + 1, index + 2, index + 1, index + 3, index + 2])
        }
        
        do { // 后
            let index = UInt32(mesh.vertexCount)
            
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, size, -size), normal: SIMD3<Float>(0, 0, -1), texture: SIMD2<Float>(0, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, size, -size), normal: SIMD3<Float>(0, 0, -1), texture: SIMD2<Float>(1, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, -size, -size), normal: SIMD3<Float>(0, 0, -1), texture: SIMD2<Float>(0, 1)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, -size, -size), normal: SIMD3<Float>(0, 0, -1), texture: SIMD2<Float>(1, 1)))
            
            submesh.indexArray.append(contentsOf: [index + 0, index + 1, index + 2, index + 1, index + 3, index + 2])
        }
        
        mesh.submeshes.append(submesh)
        return mesh
    }
    
    /// 顺序：上下左右前后
    class func lmr_skyBox(mds: [String], size: Float = 1) -> LMRMesh {
        
        let mesh = LMRMesh()
        
        do { // 上
            let index = UInt32(mesh.vertexCount)
            let submesh = LMRSubmesh()
            
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, size, -size), normal: SIMD3<Float>(0, 1, 0), texture: SIMD2<Float>(0, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, size, -size), normal: SIMD3<Float>(0, 1, 0), texture: SIMD2<Float>(1, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, size, size), normal: SIMD3<Float>(0, 1, 0), texture: SIMD2<Float>(0, 1)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, size, size), normal: SIMD3<Float>(0, 1, 0), texture: SIMD2<Float>(1, 1)))
            
            submesh.indexArray.append(contentsOf: [index + 0, index + 1, index + 2, index + 1, index + 3, index + 2])
            submesh.material.map_md = mds[0]
            
            mesh.submeshes.append(submesh)
        }
        
        do { // 下
            let index = UInt32(mesh.vertexCount)
            let submesh = LMRSubmesh()
            
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, -size, size), normal: SIMD3<Float>(0, -1, 0), texture: SIMD2<Float>(0, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, -size, size), normal: SIMD3<Float>(0, -1, 0), texture: SIMD2<Float>(1, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, -size, -size), normal: SIMD3<Float>(0, -1, 0), texture: SIMD2<Float>(0, 1)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, -size, -size), normal: SIMD3<Float>(0, -1, 0), texture: SIMD2<Float>(1, 1)))
            
            submesh.indexArray.append(contentsOf: [index + 0, index + 1, index + 2, index + 1, index + 3, index + 2])
            submesh.material.map_md = mds[1]
            
            mesh.submeshes.append(submesh)
        }
        
        do { // 左
            let index = UInt32(mesh.vertexCount)
            let submesh = LMRSubmesh()
            
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, size, -size), normal: SIMD3<Float>(-1, 0, 0), texture: SIMD2<Float>(0, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, size, size), normal: SIMD3<Float>(-1, 0, 0), texture: SIMD2<Float>(1, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, -size, -size), normal: SIMD3<Float>(-1, 0, 0), texture: SIMD2<Float>(0, 1)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, -size, size), normal: SIMD3<Float>(-1, 0, 0), texture: SIMD2<Float>(1, 1)))
            
            submesh.indexArray.append(contentsOf: [index + 0, index + 1, index + 2, index + 1, index + 3, index + 2])
            submesh.material.map_md = mds[2]
            
            mesh.submeshes.append(submesh)
        }
        
        do { // 右
            let index = UInt32(mesh.vertexCount)
            let submesh = LMRSubmesh()
            
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, size, size), normal: SIMD3<Float>(1, 0, 0), texture: SIMD2<Float>(0, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, size, -size), normal: SIMD3<Float>(1, 0, 0), texture: SIMD2<Float>(1, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, -size, size), normal: SIMD3<Float>(1, 0, 0), texture: SIMD2<Float>(0, 1)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, -size, -size), normal: SIMD3<Float>(1, 0, 0), texture: SIMD2<Float>(1, 1)))
            
            submesh.indexArray.append(contentsOf: [index + 0, index + 1, index + 2, index + 1, index + 3, index + 2])
            submesh.material.map_md = mds[3]
            
            mesh.submeshes.append(submesh)
        }
        
        do { // 前
            let index = UInt32(mesh.vertexCount)
            let submesh = LMRSubmesh()
            
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, size, size), normal: SIMD3<Float>(0, 0, 1), texture: SIMD2<Float>(0, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, size, size), normal: SIMD3<Float>(0, 0, 1), texture: SIMD2<Float>(1, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, -size, size), normal: SIMD3<Float>(0, 0, 1), texture: SIMD2<Float>(0, 1)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, -size, size), normal: SIMD3<Float>(0, 0, 1), texture: SIMD2<Float>(1, 1)))
            
            submesh.indexArray.append(contentsOf: [index + 0, index + 1, index + 2, index + 1, index + 3, index + 2])
            submesh.material.map_md = mds[4]
            
            mesh.submeshes.append(submesh)
        }
        
        do { // 后
            let index = UInt32(mesh.vertexCount)
            let submesh = LMRSubmesh()
            
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, size, -size), normal: SIMD3<Float>(0, 0, -1), texture: SIMD2<Float>(0, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, size, -size), normal: SIMD3<Float>(0, 0, -1), texture: SIMD2<Float>(1, 0)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(size, -size, -size), normal: SIMD3<Float>(0, 0, -1), texture: SIMD2<Float>(0, 1)))
            mesh.vertexArray.append(LMRVertex(position: SIMD3<Float>(-size, -size, -size), normal: SIMD3<Float>(0, 0, -1), texture: SIMD2<Float>(1, 1)))
            
            submesh.indexArray.append(contentsOf: [index + 0, index + 1, index + 2, index + 1, index + 3, index + 2])
            submesh.material.map_md = mds[5]
            
            mesh.submeshes.append(submesh)
        }
        
        return mesh
    }
}
