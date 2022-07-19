//  Created on 2022/7/18.

import UIKit

import MetalKit

class LMR3DShadowRenderer: LMRRenderer {
    open var scene: LMRScene?
    
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
    
    private var depthTexture: MTLTexture?
    
    private func renderShadow(at commandBuffer: MTLCommandBuffer, scene: LMRScene) throws -> MTLTexture? {
        guard let light = scene.lights.first else { return nil }
        
        if depthTexture == nil {
            let textureDescriptor = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .depth32Float, size: 1000, mipmapped: false)
            textureDescriptor.storageMode = .shared
            textureDescriptor.usage = [.renderTarget, .shaderRead]
            
            depthTexture = context.device.makeTexture(descriptor: textureDescriptor)
        }
        
        guard let depthTexture = depthTexture else { return nil }
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.depthAttachment.texture = depthTexture
        renderPassDescriptor.depthAttachment.clearDepth = 1
        renderPassDescriptor.depthAttachment.storeAction = .store
        renderPassDescriptor.renderTargetArrayLength = 6
        
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return nil }
        
        let filter = LMR3DShadowPainter(context: context, encoder: encoder, light: light)
        filter.depthStencilPixelFormat = .depth32Float
        for object in scene.objects {
            try filter.drawShadow(object)
        }
        
        encoder.endEncoding()
        return depthTexture
    }
    
    open func render(to mtkView: MTKView) throws {
        try self.setupScene()
        guard let scene = self.scene else {
            return
        }
        
        scene.camera.aspect = Float(mtkView.drawableSize.width / mtkView.drawableSize.height)

        guard let light = scene.lights.first else { return }
        
        guard let commandBuffer = self.context.commandQueue.makeCommandBuffer() else {return}
        
        guard let depthTexture = try self.renderShadow(at: commandBuffer, scene: scene) else {
            commandBuffer.commit()
            return
        }
        
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

        let painter = try LMR3DShadowObjPainter(context: self.context, encoder: encoder, viewParam: viewParam)
        painter.sampleCount = mtkView.sampleCount
        painter.pixelFormat = mtkView.colorPixelFormat
        painter.depthStencilPixelFormat = mtkView.depthStencilPixelFormat

        for object in scene.objects {
            try painter.draw(object, at: light, ambient: scene.ambientColor, shadow: depthTexture)
        }

        encoder.endEncoding()
        
        if let drawable = mtkView.currentDrawable {
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
    }
}
