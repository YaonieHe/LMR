//  Created on 2022/7/5.

import UIKit
import MetalKit

extension LMRMesh {
    class func lmr_box(size: SIMD3<Float>, baseColor: SIMD4<Float>, context: LMRContext, shininess: Float = 32) throws -> LMRMesh {
        let meshBufferAllocator = MTKMeshBufferAllocator(device: context.device)
        
        let mdlMesh = MDLMesh.lmr_box(size: size, bufferAllocator: meshBufferAllocator)
        mdlMesh.lmr_setBaseColor(baseColor: baseColor)
        mdlMesh.lmr_setShininess(shininess: shininess)
        mdlMesh.vertexDescriptor = MDLVertexDescriptor.lmr_pntDesc()
        let lmrMesh = try LMRMesh(mdlMesh: mdlMesh, textureLoader: context.textureLoader, device: context.device)
        
        return lmrMesh
    }
}

class LMR3DRenderer: LMRRenderer {
    open var scene: LMRScene?
    
//    private var painter: LMR3DObjPainter?
    
    private func setupScene() throws {
        if self.scene != nil {
            return
        }
        
        let newScene = LMRScene()
        newScene.ambientColor = SIMD3<Float>(0.05, 0.05, 0.05);
        newScene.camera.position = SIMD3<Float>(0, 1.5, 8)
        newScene.camera.target = SIMD3<Float>(0, 1, 0)
        
        let light = LMRLight()
        light.color = SIMD3<Float>(0.6, 0.6, 0.6)
        light.position = SIMD3<Float>(-0.2, 1.5, -2)
        let lightObj = LMRObject(mesh: try LMRMesh.lmr_box(size: SIMD3<Float>(1, 1, 1), baseColor: SIMD4<Float>(light.color, 1), context: self.context))
        lightObj.location.scale = 0.4;
        lightObj.location.position = light.position
        light.object = lightObj
        newScene.lights.append(light)
        
        do {
            let obj = LMRObject(mesh: try LMRMesh.lmr_box(size: SIMD3<Float>(20, 20, 0.01), baseColor: SIMD4<Float>(0.5, 0.4, 0.2, 1), context: self.context))
            obj.location.rotate.y = -Float.pi * 0.5
            newScene.objects.append(obj)
        }
        
        do {
            let obj = LMRObject(mesh: try LMRMesh.lmr_box(size: SIMD3<Float>(5, 5, 0.01), baseColor: SIMD4<Float>(0.1, 0.2, 0.7, 1), context: self.context))
            obj.location.position.z = -3
            newScene.objects.append(obj)
        }
        
        for _ in 0...5 {
            let size = Float(0.1 + drand48() * 0.8)
            let obj = LMRObject(mesh: try LMRMesh.lmr_box(size: SIMD3<Float>(size, size, size), baseColor: SIMD4<Float>(0.3, 0.5, 0.8, 1), context: self.context))
            obj.location.position = SIMD3<Float>(Float((drand48() - 0.5) * 6), size * 0.5, Float((drand48() - 0.5) * 6))
            obj.location.rotate.x = Float((drand48() - 0.5) * Double.pi)
            newScene.objects.append(obj)
        }
        
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
        
        for light in scene.lights {
            let painter = try LMR3DLightPainter(context: self.context, encoder: encoder, viewParam: viewParam)
            painter.sampleCount = mtkView.sampleCount
            painter.pixelFormat = mtkView.colorPixelFormat
            painter.depthStencilPixelFormat = mtkView.depthStencilPixelFormat
            try painter.draw(light)
        }
        
//        for object in scene.objects {
//            let painter = try LMR3DObjPainter(context: self.context, encoder: encoder, viewParam: viewParam)
//            painter.sampleCount = mtkView.sampleCount
//            painter.pixelFormat = mtkView.colorPixelFormat
//            painter.depthStencilPixelFormat = mtkView.depthStencilPixelFormat
//            try painter.draw(object)
//        }
        
        for object in scene.objects {
            let painter = try LMR3DLightPainter(context: self.context, encoder: encoder, viewParam: viewParam)
            painter.sampleCount = mtkView.sampleCount
            painter.pixelFormat = mtkView.colorPixelFormat
            painter.depthStencilPixelFormat = mtkView.depthStencilPixelFormat
            try painter.drawBlinnPhong(object, lights: scene.lights, ambient: scene.ambientColor)
        }
        
        encoder.endEncoding()
        if let drawable = mtkView.currentDrawable {
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
    }
}
