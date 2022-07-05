//
//  LMRSceneVV.swift
//  LMR
//
//  Created by hjp-Mic on 2022/7/2.
//

import UIKit

import MetalKit
import simd

class LMRSceneVC: UIViewController, MTKViewDelegate {
    var mtkView: MTKView {view as! MTKView}
    var context: LMRContext = LMRContext()
    var device: MTLDevice {
        return context.device
    }
    var depthStencilState: MTLDepthStencilState!
    var renderPipeLineState: MTLRenderPipelineState!
    var lightRenderPipeLineState: MTLRenderPipelineState!
    var scene: LMRScene?
    var time: Float = 0
    
    var _textureMap: [String: MTLTexture] = [String: MTLTexture]()
    
    override func loadView() {
        super.loadView()
        if view is MTKView {
            return
        }
        view = MTKView(frame: view.frame)
    }
    
    @objc func clickLightBtn(btn: UIButton) {
        btn.isSelected = !btn.isSelected
        do {
            if btn.isSelected {
                renderPipeLineState = try getRenderPipeLineState(vertFunc: "lmr_3d::obj_v", fragFunc: "lmr_3d::obj_f_blinn_phong")
            } else {
                renderPipeLineState = try getRenderPipeLineState(vertFunc: "lmr_3d::obj_v", fragFunc: "lmr_3d::obj_f_phong")
            }
        } catch {
            
        }
    }
    
    @objc func changeDiffuseSlider(slider: UISlider) {
        _diffuse = slider.value
    }
    @objc func changeSpecularSlider(slider: UISlider) {
        _specular = slider.value
    }
    @objc func changeShininessSlider(slider: UISlider) {
        _shininess = slider.value
    }
    
    var _diffuse: Float = 0.1
    var _specular: Float = 0.5
    var _shininess: Float = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let btn = UIButton(frame: CGRect(x: 10, y: 50, width: 200, height: 40))
        btn.setTitle("灯光切换:phong", for: .normal)
        btn.setTitle("灯光切换:blinn_phong", for: .selected)
        btn.addTarget(self, action: #selector(clickLightBtn(btn:)), for: .touchUpInside)
        self.view .addSubview(btn)
        
        do {
            let slider = UISlider(frame: CGRect(x: 10, y: 100, width: 200, height: 40))
            slider.minimumValue = 0
            slider.maximumValue = 1
            slider.value = _diffuse
            slider.addTarget(self, action: #selector(changeDiffuseSlider(slider:)), for: .valueChanged)
            self.view.addSubview(slider)
        }
        do {
            let slider = UISlider(frame: CGRect(x: 10, y: 150, width: 200, height: 40))
            slider.minimumValue = 0
            slider.maximumValue = 1
            slider.value = _specular
            slider.addTarget(self, action: #selector(changeSpecularSlider(slider:)), for: .valueChanged)
            self.view.addSubview(slider)
        }
        do {
            let slider = UISlider(frame: CGRect(x: 10, y: 200, width: 200, height: 40))
            slider.minimumValue = 1
            slider.maximumValue = 128
            slider.value = _shininess
            slider.addTarget(self, action: #selector(changeShininessSlider(slider:)), for: .valueChanged)
            self.view.addSubview(slider)
        }

        mtkView.device = device
        mtkView.sampleCount = 4
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        mtkView.depthStencilPixelFormat = .depth32Float
        mtkView.delegate = self
        
        do {
            renderPipeLineState = try getRenderPipeLineState(vertFunc: "lmr_3d::obj_v", fragFunc: "lmr_3d::obj_f_phong")
            lightRenderPipeLineState = try getRenderPipeLineState(vertFunc: "lmr_3d::obj_v", fragFunc: "lmr_3d::light_f")
            depthStencilState = getDepthStencilState()
        } catch {
            return
        }
    }
    
//    func _updateScene() {
//        if self.scene == nil {
//            let newScene = LMRScene()
//            newScene.ambientColor = simd_make_float3(0.05, 0.05, 0.05)
//
//            newScene.camera.position = simd_make_float3(0, 1.5, 10)
//            newScene.camera.target = SIMD3<Float>(0, 1, 0)
//
//            for _ in 0...0 {
//                let light = LMRLight()
//                light.color = simd_make_float3(0.6, 0.6, 0.6)
//                light.position = SIMD3<Float>(-0.2, 1.5, -2)//simd_make_float3(Float((drand48() - 0.5) * 6), Float(2 + (drand48() - 0.5) * 1), Float((drand48() - 0.5) * 6))
//                let lightObj  = LMRObject(mesh: LMDMesh.lmr_box())
//                lightObj.location.scale = Float(drand48() * 0.4)
//                lightObj.location.position = light.position;
//                light.object = lightObj
//                newScene.lights.append(light)
//            }
//
////            do {
////                let mesh = LMDMesh.lmr_skyBox(mds: ["top.jpg", "bottom_1.jpg", "left.jpg", "right.jpg", "front.jpg", "back.jpg"], size: 60)
////                for  submesh in mesh.submeshes {
////                    submesh.material.diffuse = 0
////                    submesh.material.specular = 0
////                }
////                let obj = LMRObject(mesh:mesh)
////                obj.location.position = SIMD3<Float>(0, 59, 20)
////                newScene.objects.append(obj)
////            }
//
//
//            do {
//                let obj = LMRObject(mesh:LMDMesh.lmr_rect(size: SIMD2<Float>(20, 20), color: simd_make_float4(0.5, 0.4, 0.2, 1)))
//                obj.location.rotate.y = -Float.pi * 0.5
//                newScene.objects.append(obj)
//            }
////            do {
////                let obj = LMRObject(mesh:LMRMesh.lmr_rect(size: SIMD2<Float>(20, 20), color: simd_make_float4(0.5, 0.4, 0.2, 1)))
////                obj.location.position.y = 2;
////                obj.location.rotate.y = -Float.pi * 0.5
////                newScene.objects.append(obj)
////            }
////            do {
////                let obj = LMRObject(mesh:LMDMesh.lmr_rect(size: SIMD2<Float>(20, 20), color: simd_make_float4(0.5, 0.4, 0.2, 1)))
////                obj.location.position.x = 0.9;
////                obj.location.rotate.x = -Float.pi * 0.5
////                newScene.objects.append(obj)
////            }
////            do {
////                let obj = LMRObject(mesh:LMDMesh.lmr_rect(size: SIMD2<Float>(20, 20), color: simd_make_float4(0.5, 0.4, 0.2, 1)))
////                obj.location.position.x = -0.7;
////                obj.location.rotate.x = -Float.pi * 0.5
////                newScene.objects.append(obj)
////            }
////
////            do {
////                let mesh = LMDMesh.lmr_rect(size: SIMD2<Float>(2, 2), color: simd_make_float4(0.5, 0.4, 0.6, 1))
////                if let submesh = mesh.submeshes.first {
////                    submesh.material.map_kd = "kd_wall.jpeg"
////                }
////                let obj = LMRObject(mesh:mesh)
////                obj.location.position = SIMD3<Float>(0, 1, 3)
////                obj.location.rotate.x = Float.pi * 0.3
////                newScene.objects.append(obj)
////            }
//
//            for _ in 0...5 {
//                let size = Float(0.1 + drand48() * 0.8)
//                let x = Float((drand48() - 0.5) * 6)
//                let z = Float((drand48() - 0.5) * 6)
//                let r = Float((drand48() - 0.5) * Double.pi)
//                let mesh = LMDMesh.lmr_box(color: simd_make_float4(0.4, 0.7, 0.8, 1), size: size)
//                if let submesh = mesh.submeshes.first {
//                    submesh.material.map_kd = "kd_box.jpeg"
//                }
//                let obj = LMRObject(mesh:mesh)
//
//                obj.location.position = SIMD3<Float>(x, size * 0.5, z)
//                obj.location.rotate.x = r
//                newScene.objects.append(obj)
//            }
//
//            self.scene = newScene
//        }
//
//        guard let scene = scene else {
//            return
//        }
//
//        let c = Int(floor(time / 60))
//        let p = time - Float(c) * 60
//
////        scene.camera.target.x = (p - 30) / 18 * Float.pi * (c % 2 == 1 ? -1 : 1)
//
//    }
//
//    func _renderShadow(at commandBuffer: MTLCommandBuffer, scene: LMRScene) throws -> MTLTexture? {
//        guard let light = scene.lights.first  else {
//            return nil
//        }
//
//        let textureDescriptor = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .depth32Float, size: 1000, mipmapped: false)
//        textureDescriptor.storageMode = .shared
//        textureDescriptor.usage = [.renderTarget, .shaderRead]
//        let depthTexture = device.makeTexture(descriptor:textureDescriptor)
//
////        let textureDescriptor2 = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .bgra8Unorm_srgb, size: 1000, mipmapped: false)
////        textureDescriptor2.storageMode = .shared
////        textureDescriptor2.usage = .renderTarget
////        let colorTexture = device.makeTexture(descriptor:textureDescriptor2)
//
//        let renderPassDescriptor = MTLRenderPassDescriptor()
////        renderPassDescriptor.colorAttachments[0].texture = colorTexture
////        renderPassDescriptor.colorAttachments[0].loadAction = .clear
////        renderPassDescriptor.colorAttachments[0].storeAction = .store
//        renderPassDescriptor.depthAttachment.texture = depthTexture
//        renderPassDescriptor.depthAttachment.clearDepth = 1
//        renderPassDescriptor.depthAttachment.storeAction = .store
//        renderPassDescriptor.renderTargetArrayLength = 6
//
//        let view_pos = light.position
//        var projectM = float4x4(perspectiveRightHandWithFovy: Float.pi * 0.5, aspectRatio: 1, nearZ: 0.1, farZ: 100)
//        var viewMs = [float4x4]()
//        for i in 0...5 {
////            viewMs.append(scene.camera.viewMatrix)
//            viewMs.append(float4x4.look_at_cube(eye: view_pos, face: i))
//        }
////        var viewMs = [
////            scene.camera.viewMatrix,
////            scene.camera.viewMatrix,
////            scene.camera.viewMatrix,
////            scene.camera.viewMatrix,
////            scene.camera.viewMatrix,
////            scene.camera.viewMatrix
////        ]
//
//        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {throw LMR3DError(description: "create encoder fail")}
//        let renderPipeLineState = try self.getRenderPipeLineState(vertFunc: "lmr_3d::shadow_depth_v", fragFunc: "lmr_3d::shadow_depth_f", onlyDepth: true)
//
//        encoder.setRenderPipelineState(renderPipeLineState)
//        encoder.setDepthStencilState(depthStencilState)
//
//        for object in scene.objects {
//            var modelM = object.location.transform
//            if let mesh = object.mesh {
//
//                let vertexBuffer = device.makeBuffer(bytes: mesh.vertexArray, length: MemoryLayout<LMDVertex>.stride * mesh.vertexCount)
//                encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
//
//                encoder.setVertexBytes(&modelM, length: MemoryLayout<float4x4>.stride, index: 1)
//                encoder.setVertexBytes(&viewMs, length: MemoryLayout<float4x4>.stride * 6, index: 2)
//                encoder.setVertexBytes(&projectM, length: MemoryLayout<float4x4>.stride, index: 3)
//                for submesh in mesh.submeshes {
//                    let indexBuffer = device.makeBuffer(bytes: submesh.indexArray, length: MemoryLayout<Int>.stride * submesh.indexCount)!
//                    encoder.setTriangleFillMode(.fill)
//                    encoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: 6)
//                }
//            }
//        }
//        encoder.endEncoding()
//        return depthTexture
//    }
    
    func _render(view: MTKView, at commandBuffer: MTLCommandBuffer) throws {
//        time += 0.2
//        NSLog("%f", time)
//        self._updateScene()
//        
//        guard let scene = self.scene else {
//            return
//        }
//        
//        let depthTexture = try self._renderShadow(at: commandBuffer, scene: scene)
//        
//        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {return}
//        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}
//        
//        let w = Float(view.bounds.size.width)
//        let h = Float(view.bounds.size.height)
//        
//        scene.camera.aspect = w / h
//        var view_pos = scene.camera.position
//        let viewM = scene.camera.viewMatrix
//        let projectM = scene.camera.projectMatrix
//        
//        var lightParams: [LMR3DFragLight] = [LMR3DFragLight]()
//        for light in scene.lights {
//            var lightParam = LMR3DFragLight(color: light.color, position: light.position)
//            lightParams.append(lightParam)
//            if let object = light.object {
//                let modelM = object.location.transform
//                if let mesh = object.mesh {
//                    let normalM = float3x3(modelM.inverse.transpose)
//                    var param = LMR3DVertexParam(projectM: projectM, viewM: viewM, modelM: modelM, normalM: normalM)
//                    encoder.setRenderPipelineState(lightRenderPipeLineState)
//                    encoder.setDepthStencilState(depthStencilState)
//                    
//                    let vertexBuffer = device.makeBuffer(bytes: mesh.vertexArray, length: MemoryLayout<LMDVertex>.stride * mesh.vertexCount)
//                    encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
//                    
//                    encoder.setVertexBytes(&param, length: MemoryLayout<LMR3DVertexParam>.stride, index: 1)
//                    encoder.setFragmentBytes(&lightParam, length: MemoryLayout<LMR3DFragLight>.stride, index: 0)
//                    
//                    for submesh in mesh.submeshes {
//                        let indexBuffer = device.makeBuffer(bytes: submesh.indexArray, length: MemoryLayout<Int>.stride * submesh.indexCount)!
//                        encoder.setTriangleFillMode(.fill)
//                        encoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0)
//                    }
//                }
//            }
//        }
//        
//        encoder.setFragmentTexture(depthTexture, index: 1)
//        
//        for object in scene.objects {
//            let modelM = object.location.transform
//            if let mesh = object.mesh {
//                let normalM = float3x3(modelM.inverse.transpose)
//                var param = LMR3DVertexParam(projectM: projectM, viewM: viewM, modelM: modelM, normalM: normalM)
//                
//                encoder.setRenderPipelineState(renderPipeLineState)
//                encoder.setDepthStencilState(depthStencilState)
//                
//                let vertexBuffer = device.makeBuffer(bytes: mesh.vertexArray, length: MemoryLayout<LMDVertex>.stride * mesh.vertexCount)
//                encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
//                
//                encoder.setVertexBytes(&param, length: MemoryLayout<LMR3DVertexParam>.stride, index: 1)
//                
//                encoder.setFragmentBytes(&view_pos, length: MemoryLayout<SIMD3<Float>>.stride, index: 0)
//                encoder.setFragmentBytes(&scene.ambientColor, length: MemoryLayout<SIMD3<Float>>.stride, index: 2)
//                var lightCount = lightParams.count
//                encoder.setFragmentBytes(&lightCount, length: MemoryLayout<Int>.stride, index: 3)
//                if (lightCount == 0) {
//                    lightParams.append(LMR3DFragLight(color: SIMD3<Float>(0, 0, 0), position: SIMD3<Float>(0, 0, 0)))
//                }
//                encoder.setFragmentBytes(&lightParams, length: MemoryLayout<LMR3DFragLight>.stride * lightParams.count, index: 4)
//                
//                for submesh in mesh.submeshes {
////                    var material = Material(color: submesh.material.md_color, diffuse: submesh.material.diffuse, specular: submesh.material.specular, shininess: submesh.material.shininess)
//                    if let map_kd = submesh.material.map_kd {
//                        let texture = try self.context.generateTexture(from: map_kd)
//                        encoder.setFragmentTexture(texture, index: 0)
//                    }
//                    var material = LMR3DFragMaterial(isMapKd:(submesh.material.map_kd != nil), color: submesh.material.kd_color, diffuse: _diffuse, specular: _specular, shininess: _shininess)
//                    encoder.setFragmentBytes(&material, length: MemoryLayout<LMR3DFragMaterial>.stride, index: 1)
//                    
//                    let indexBuffer = device.makeBuffer(bytes: submesh.indexArray, length: MemoryLayout<Int>.stride * submesh.indexCount)!
//                    encoder.setTriangleFillMode(.fill)
//                    encoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0)
//                }
//            }
//        }
//        encoder.endEncoding()
    }
    
    func draw(in view: MTKView) {
        guard let commandBuffer = context.commandQueue.makeCommandBuffer() else {return}
        do {
            try self._render(view: view, at: commandBuffer)
        } catch {
            
        }
        
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
}

extension LMRSceneVC {
    func getRenderPipeLineState(vertFunc: String, fragFunc: String, onlyDepth: Bool = false) throws -> MTLRenderPipelineState {
        let vertexFunc = self.context.library.makeFunction(name: vertFunc)
        let fragFunc = self.context.library.makeFunction(name: fragFunc)
       
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].offset = 0;
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].bufferIndex = 0
        
       vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride;
       vertexDescriptor.attributes[1].format = .float3
       vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.attributes[2].offset = MemoryLayout<SIMD3<Float>>.stride * 2;
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<LMDVertex>.stride
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunc
        pipelineDescriptor.fragmentFunction = fragFunc
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        if !onlyDepth {
            pipelineDescriptor.sampleCount = mtkView.sampleCount
            pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        } else {
            pipelineDescriptor.inputPrimitiveTopology = .triangle
            pipelineDescriptor.sampleCount = 1
//            pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        }
        pipelineDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat

        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
   }
    
   func getDepthStencilState() -> MTLDepthStencilState {
       let depthStateDescriptor = MTLDepthStencilDescriptor()
       depthStateDescriptor.depthCompareFunction = .less
       depthStateDescriptor.isDepthWriteEnabled = true
       return device.makeDepthStencilState(descriptor: depthStateDescriptor)!
   }
}
