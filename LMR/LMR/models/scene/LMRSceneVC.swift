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
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var library: MTLLibrary!
    
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
        
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()
        library = device.makeDefaultLibrary()
        
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
    
    func _updateScene() {
        if self.scene == nil {
            let newScene = LMRScene()
            newScene.ambientColor = simd_make_float3(0.2, 0.2, 0.2)
            
            newScene.camera.position = simd_make_float3(0, 1.8, 8)
//            newScene.camera.position = simd_make_float3(0, 10, 0)
            newScene.camera.rotate.y = Float.pi * 0.01
            
            for _ in 0...0 {
                let light = LMRLight()
                light.color = simd_make_float3(0.6, 0.6, 0.6)
                light.position = simd_make_float3(Float((drand48() - 0.5) * 6), Float(2 + (drand48() - 0.5) * 1), Float((drand48() - 0.5) * 6))
                let lightObj  = LMRObject(mesh: LMRMesh.lmr_box())
                lightObj.location.scale = Float(drand48() * 0.4)
                lightObj.location.position = light.position;
                light.object = lightObj
                newScene.lights.append(light)
            }
            
            do {
                let mesh = LMRMesh.lmr_skyBox(mds: ["top.jpg", "bottom_1.jpg", "left.jpg", "right.jpg", "front.jpg", "back.jpg"], size: 60)
                for  submesh in mesh.submeshes {
                    submesh.material.diffuse = 0
                    submesh.material.specular = 0
                }
                let obj = LMRObject(mesh:mesh)
                obj.location.position = SIMD3<Float>(0, 59, 20)
                newScene.objects.append(obj)
            }
            
//
//            do {
//                let obj = LMRObject(mesh:LMRMesh.lmr_rect(size: SIMD2<Float>(20, 20), color: simd_make_float4(0.5, 0.4, 0.2, 1)))
//                obj.location.rotate.y = -Float.pi * 0.5
//                newScene.objects.append(obj)
//            }
            
//            do {
//                let obj = LMRObject(mesh:LMRMesh.lmr_rect(size: SIMD2<Float>(10, 10), color: simd_make_float4(0.5, 0.4, 0.6, 1)))
//                obj.location.position = SIMD3<Float>(0, 5, -8)
//                newScene.objects.append(obj)
//            }
            
            for _ in 0...5 {
                let size = Float(0.1 + drand48() * 0.8)
                let x = Float((drand48() - 0.5) * 6)
                let z = Float((drand48() - 0.5) * 6)
                let r = Float((drand48() - 0.5) * Double.pi)
                let obj = LMRObject(mesh:LMRMesh.lmr_box(color: simd_make_float4(0.4, 0.7, 0.8, 1), size: size))
                obj.location.position = SIMD3<Float>(x, size * 0.5, z)
                obj.location.rotate.x = r
                newScene.objects.append(obj)
            }
            
            self.scene = newScene
        }
        
        guard let scene = scene else {
            return
        }
        
        let c = Int(floor(time / 60))
        let p = time - Float(c) * 60

        scene.camera.rotate.x = (p - 30) / 180 * Float.pi * (c % 2 == 1 ? -1 : 1)
        
    }
    
    func _render(in encoder: MTLRenderCommandEncoder) throws {
        time += 0.2
        NSLog("%f", time)
        self._updateScene()
        
        guard let scene = self.scene else {
            return
        }
        
        let w = Float(view.bounds.size.width)
        let h = Float(view.bounds.size.height)
        
        scene.camera.aspect = w / h
        var view_pos = scene.camera.position
        let viewM = scene.camera.viewMatrix
        let projectM = scene.camera.projectMatrix
        
        var lightParams: [LMR3DFragLight] = [LMR3DFragLight]()
        for light in scene.lights {
            var lightParam = LMR3DFragLight(color: light.color, position: light.position)
            lightParams.append(lightParam)
            if let object = light.object {
                let modelM = object.location.transform
                if let mesh = object.mesh {
                    let normalM = float3x3(modelM.inverse.transpose)
                    var param = LMR3DVertexParam(projectM: projectM, viewM: viewM, modelM: modelM, normalM: normalM)
                    encoder.setRenderPipelineState(lightRenderPipeLineState)
                    encoder.setDepthStencilState(depthStencilState)
                    
                    let vertexBuffer = device.makeBuffer(bytes: mesh.vertexArray, length: MemoryLayout<LMRVertex>.stride * mesh.vertexCount)
                    encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                    
                    encoder.setVertexBytes(&param, length: MemoryLayout<LMR3DVertexParam>.stride, index: 1)
                    encoder.setFragmentBytes(&lightParam, length: MemoryLayout<LMR3DFragLight>.stride, index: 0)
                    
                    for submesh in mesh.submeshes {
                        let indexBuffer = device.makeBuffer(bytes: submesh.indexArray, length: MemoryLayout<Int>.stride * submesh.indexCount)!
                        encoder.setTriangleFillMode(.fill)
                        encoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0)
                    }
                }
            }
        }
        
        for object in scene.objects {
            let modelM = object.location.transform
            if let mesh = object.mesh {
                let normalM = float3x3(modelM.inverse.transpose)
                var param = LMR3DVertexParam(projectM: projectM, viewM: viewM, modelM: modelM, normalM: normalM)
                
                encoder.setRenderPipelineState(renderPipeLineState)
                encoder.setDepthStencilState(depthStencilState)
                
                let vertexBuffer = device.makeBuffer(bytes: mesh.vertexArray, length: MemoryLayout<LMRVertex>.stride * mesh.vertexCount)
                encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                
                encoder.setVertexBytes(&param, length: MemoryLayout<LMR3DVertexParam>.stride, index: 1)
                
                encoder.setFragmentBytes(&view_pos, length: MemoryLayout<SIMD3<Float>>.stride, index: 0)
                encoder.setFragmentBytes(&scene.ambientColor, length: MemoryLayout<SIMD3<Float>>.stride, index: 2)
                var lightCount = lightParams.count
                encoder.setFragmentBytes(&lightCount, length: MemoryLayout<Int>.stride, index: 3)
                if (lightCount == 0) {
                    lightParams.append(LMR3DFragLight(color: SIMD3<Float>(0, 0, 0), position: SIMD3<Float>(0, 0, 0)))
                }
                encoder.setFragmentBytes(&lightParams, length: MemoryLayout<LMR3DFragLight>.stride * lightParams.count, index: 4)
                
                for submesh in mesh.submeshes {
//                    var material = Material(color: submesh.material.md_color, diffuse: submesh.material.diffuse, specular: submesh.material.specular, shininess: submesh.material.shininess)
                    if let map_kd = submesh.material.map_kd {
                        let texture = try self.generateTexture(from: map_kd)
                        encoder.setFragmentTexture(texture, index: 0)
                    }
                    var material = LMR3DFragMaterial(isMapKd:(submesh.material.map_kd != nil), color: submesh.material.kd_color, diffuse: _diffuse, specular: _specular, shininess: _shininess)
                    encoder.setFragmentBytes(&material, length: MemoryLayout<LMR3DFragMaterial>.stride, index: 1)
                    
                    let indexBuffer = device.makeBuffer(bytes: submesh.indexArray, length: MemoryLayout<Int>.stride * submesh.indexCount)!
                    encoder.setTriangleFillMode(.fill)
                    encoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0)
                }
            }
        }
    }
    
    func draw(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {return}
        guard let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}
        do {
            try _render(in: renderCommandEncoder)
        } catch {
            return
        }
        renderCommandEncoder.endEncoding()
        
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
}

extension LMRSceneVC {
    func getRenderPipeLineState(vertFunc: String, fragFunc: String) throws -> MTLRenderPipelineState {
        let vertexFunc = library.makeFunction(name: vertFunc)
        let fragFunc = library.makeFunction(name: fragFunc)
       
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
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<LMRVertex>.stride
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunc
        pipelineDescriptor.fragmentFunction = fragFunc
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.sampleCount = mtkView.sampleCount
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat

        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
   }
    
   func getDepthStencilState() -> MTLDepthStencilState {
       let depthStateDescriptor = MTLDepthStencilDescriptor()
       depthStateDescriptor.depthCompareFunction = .less
       depthStateDescriptor.isDepthWriteEnabled = true
       return device.makeDepthStencilState(descriptor: depthStateDescriptor)!
   }
    
    func generateTexture(from imageName: String) throws -> MTLTexture {
        
        if let texture = _textureMap[imageName] {
            return texture
        }
        
        let path = Bundle.main.path(forResource: imageName, ofType: nil)!
//        let image = UIImage.init(contentsOfFile: path)!
        
        let loader = MTKTextureLoader(device: device)
        
        let texture = try loader.newTexture(URL: URL.init(fileURLWithPath: path))
        
        _textureMap[imageName] = texture
        
        return texture
    }
}
