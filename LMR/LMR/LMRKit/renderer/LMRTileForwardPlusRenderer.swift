//  Created on 2022/8/5.

import UIKit

import MetalKit

class LMRTileForwardPlusRenderer: LMRRenderer {
    open var scene: LMRScene?
    
    private func setupScene() throws {
        if self.scene != nil {
            return
        }
        
        let newScene = LMRScene()
        newScene.ambientColor = SIMD3<Float>(0.05, 0.05, 0.05);
        newScene.camera.position = SIMD3<Float>(0, 0, 8)
        newScene.camera.target = SIMD3<Float>(0, 0, 0)
        
        let modelUrl = Bundle.main.url(forResource: "Temple.mtl", withExtension: nil)
        let bufferAllocator = MTKMeshBufferAllocator(device: self.context.device)
        let mdlAsset = MDLAsset(url: modelUrl, vertexDescriptor: nil, bufferAllocator: bufferAllocator)
        
        let lmrMeshArray = try LMRMesh.createMeshes(asset: mdlAsset, vertexDescriptor: MDLVertexDescriptor.lmr_pnttbDesc(), textureLoader: self.context.textureLoader, device: self.context.device, tangent: true)
        
        for lmrMesh in lmrMeshArray {
            let obj = LMRObject(mesh: lmrMesh)
            newScene.objects.append(obj)
        }
        
        scene = newScene
    }
}
