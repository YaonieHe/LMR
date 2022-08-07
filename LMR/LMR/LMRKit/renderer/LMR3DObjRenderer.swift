//
//  LMR3DObjRenderer.swift
//  LMR
//
//  Created by hjp-Mic on 2022/8/6.
//

import Foundation

import MetalKit

class LMR3DObjRenderer: LMR3DRenderer {    
    private func setupScene() throws {
        if self.scene != nil {
            return
        }
        
        let newScene = LMRScene()
        newScene.ambientColor = SIMD3<Float>(0.1, 0.1, 0.1);
        newScene.camera.position = SIMD3<Float>(0, 400, 1000)
        newScene.camera.target = SIMD3<Float>(0, 0, 0)
        newScene.camera.nearZ = 1
        newScene.camera.farZ = 1500
        newScene.camera.field = Float.pi * 65.0 / 180.0
        
        let light = LMRLight()
        light.color = SIMD3<Float>(0.6, 0.6, 0.6)
        light.position = SIMD3<Float>(-600, 600, 200)
        let lightObj = LMRObject(mesh: try LMRMesh.lmr_box(size: SIMD3<Float>(1, 1, 1), baseColor: SIMD4<Float>(light.color, 1), context: self.context))
        lightObj.location.scale = 40;
        lightObj.location.position = light.position
        light.object = lightObj
        newScene.lights.append(light)
        
        let modelUrl = Bundle.main.url(forResource: "Temple.obj", withExtension: nil)
        let bufferAllocator = MTKMeshBufferAllocator(device: self.context.device)
        let mdlAsset = MDLAsset(url: modelUrl, vertexDescriptor: nil, bufferAllocator: bufferAllocator)
        
        mdlAsset.lmr_setShininess(shininess: 32)
        
        let lmrMeshArray = try LMRMesh.createMeshes(asset: mdlAsset, vertexDescriptor: MDLVertexDescriptor.lmr_pnttbDesc(), textureLoader: self.context.textureLoader, device: self.context.device, tangent: true)
        
        for lmrMesh in lmrMeshArray {
            let obj = LMRObject(mesh: lmrMesh)
            obj.location.rotate.y = 0.5
            newScene.objects.append(obj)
        }
        
        scene = newScene;
    }
    
    override func render(to mtkView: MTKView) throws {
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

        for object in scene.objects {
            object.location.rotate.x += 0.01;
            let painter = try LMR3DLightPainter(context: self.context, encoder: encoder, viewParam: viewParam)
            painter.sampleCount = mtkView.sampleCount
            painter.pixelFormat = mtkView.colorPixelFormat
            painter.depthStencilPixelFormat = mtkView.depthStencilPixelFormat
            try painter.drawPNTTBBlinnPhong(object, lights: scene.lights, ambient: scene.ambientColor)
        }
        
        encoder.endEncoding()
        if let drawable = mtkView.currentDrawable {
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
    }
    
}
