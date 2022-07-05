//  Created on 2022/7/5.

import UIKit
import MetalKit

class LMR3DRenderer: LMRRenderer {
    open var scene: LMRScene?
    
//    private var painter: LMR3DObjPainter?
    
    private func setupScene() throws {
        if self.scene != nil {
            return
        }
        
        let newScene = LMRScene()
        newScene.camera.position = SIMD3<Float>(0, 0, 5)
        
        let meshBufferAllocator = MTKMeshBufferAllocator(device: self.context.device)
        
        let mdlMesh = MDLMesh.lmr_box(size: SIMD3<Float>(1, 1, 1), bufferAllocator: meshBufferAllocator)
        mdlMesh.lmr_setBaseColor(baseColor: SIMD4<Float>(1, 1, 1, 1))
        mdlMesh.vertexDescriptor = MDLVertexDescriptor.lmr_pntDesc()
        let lmrMesh = try LMRMesh(mdlMesh: mdlMesh, textureLoader: self.context.textureLoader, device: self.context.device)
        
        let obj = LMRObject(mesh: lmrMesh)
        obj.location.rotate.x = Float.pi * 0.3
        newScene.objects.append(obj)
        
        self.scene = newScene
    }
    
    open func render(to mtkView: MTKView) throws {
        try self.setupScene()
        guard let scene = self.scene else {
            return
        }
        
        scene.camera.aspect = Float(mtkView.drawableSize.width / mtkView.drawableSize.height)
        
        guard let commandBuffer = self.context.commandQueue.makeCommandBuffer() else {return}
        guard let renderPassDescriptor = mtkView.currentRenderPassDescriptor else {return}
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}
        
        let viewM = scene.camera.viewMatrix
        let projectM = scene.camera.projectMatrix
        let viewParam = LMR3DViewParams(cameraPos: scene.camera.position, viewProjectionMatrix: projectM * viewM)
        
        for object in scene.objects {
            let painter = try LMR3DObjPainter(context: self.context, object: object, encoder: encoder, viewParam: viewParam)
            painter.sampleCount = mtkView.sampleCount
            painter.pixelFormat = mtkView.colorPixelFormat
            painter.depthStencilPixelFormat = mtkView.depthStencilPixelFormat
            try painter.draw()
        }
        
        encoder.endEncoding()
        if let drawable = mtkView.currentDrawable {
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
    }
}
