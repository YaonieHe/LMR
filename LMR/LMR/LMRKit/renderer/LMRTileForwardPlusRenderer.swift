//  Created on 2022/8/5.

import UIKit

import MetalKit

class LMRTFPLight: LMRLight {
    var r: Float = 0
    var angle: Float = 0
    var speed: Float = 0
    var height: Float = 0
    var distance: Float = 1
    
    override var position: SIMD3<Float> {
        get {
            return SIMD3<Float>(x: r * sinf(angle), y: height, z: r * cosf(angle))
        }
        
        set {
            
        }
    }
}

class LMRTileForwardPlusRenderer: LMRRenderer {
    open var scene: LMRScene?
    
    let numLights: Int = 1024
    
    private func setupScene() throws {
        if self.scene != nil {
            return
        }
        
        let newScene = LMRScene()
        newScene.ambientColor = SIMD3<Float>(0.05, 0.05, 0.05);
        newScene.camera.position = SIMD3<Float>(0, 75, 1000)
        newScene.camera.target = SIMD3<Float>(0, 0, 0)
        newScene.camera.nearZ = 1
        newScene.camera.farZ = 1500
        newScene.camera.field = Float.pi * 65.0 / 180.0
        
        let modelUrl = Bundle.main.url(forResource: "Temple.mtl", withExtension: nil)
        let bufferAllocator = MTKMeshBufferAllocator(device: self.context.device)
        let mdlAsset = MDLAsset(url: modelUrl, vertexDescriptor: nil, bufferAllocator: bufferAllocator)
        
        let lmrMeshArray = try LMRMesh.createMeshes(asset: mdlAsset, vertexDescriptor: MDLVertexDescriptor.lmr_pnttbDesc(), textureLoader: self.context.textureLoader, device: self.context.device, tangent: true)
        
        for lmrMesh in lmrMeshArray {
            let obj = LMRObject(mesh: lmrMesh)
            newScene.objects.append(obj)
        }
        
        for i in 0 ..< numLights {
            let light = LMRTFPLight()
            var r: Float = 0
            var height: Float = 0
            if i < numLights/4 {
                r = Float.random(in: Range<Float>(uncheckedBounds: (lower: 140, upper: 260)))
                height = Float.random(in: Range<Float>(uncheckedBounds: (lower: 140, upper: 150)))
            } else if i < numLights * 3 / 4 {
                r = Float.random(in: Range<Float>(uncheckedBounds: (lower: 350, upper: 362)))
                height = Float.random(in: Range<Float>(uncheckedBounds: (lower: 140, upper: 400)))
            } else if i < numLights * 15 / 16 {
                r = Float.random(in: Range<Float>(uncheckedBounds: (lower: 400, upper: 480)))
                height = Float.random(in: Range<Float>(uncheckedBounds: (lower: 68, upper: 80)))
            } else {
                r = Float.random(in: Range<Float>(uncheckedBounds: (lower: 40, upper: 40)))
                height = Float.random(in: Range<Float>(uncheckedBounds: (lower: 220, upper: 350)))
            }
            
            light.r = r
            light.height = height
            light.angle = Float.random(in: Range<Float>(uncheckedBounds: (lower: 0, upper: Float.pi * 2)))
            light.distance = Float.random(in: Range<Float>(uncheckedBounds: (lower: 25, upper: 35)))
            light.speed = Float.random(in: Range<Float>(uncheckedBounds: (lower: 0.003, upper: 0.015)))
            let colorId = Int.random(in: Range<Int>(uncheckedBounds: (lower: 0, upper: 30000))) % 3
            if colorId == 0 {
                light.color = SIMD3<Float>(x: Float.random(in: Range<Float>(uncheckedBounds: (lower: 2, upper: 3))),
                                           y: Float.random(in: Range<Float>(uncheckedBounds: (lower: 0, upper: 2))),
                                           z: Float.random(in: Range<Float>(uncheckedBounds: (lower: 0, upper: 2))))
            } else if colorId == 1 {
                light.color = SIMD3<Float>(x: Float.random(in: Range<Float>(uncheckedBounds: (lower: 0, upper: 2))),
                                           y: Float.random(in: Range<Float>(uncheckedBounds: (lower: 2, upper: 3))),
                                           z: Float.random(in: Range<Float>(uncheckedBounds: (lower: 0, upper: 2))))
            } else {
                light.color = SIMD3<Float>(x: Float.random(in: Range<Float>(uncheckedBounds: (lower: 0, upper: 2))),
                                           y: Float.random(in: Range<Float>(uncheckedBounds: (lower: 0, upper: 2))),
                                           z: Float.random(in: Range<Float>(uncheckedBounds: (lower: 2, upper: 3))))
            }
            
            newScene.lights.append(light)
        }
        
        scene = newScene
    }
    
    var frameIdx: Int = 0
    
    private func moveStep(scene: LMRScene) {
        frameIdx += 1
        for light in scene.lights {
            if let tfpLight = light as? LMRTFPLight {
                tfpLight.angle += tfpLight.speed
            }
        }
        let angle = Float(frameIdx) * 0.01
        scene.camera.position = SIMD3<Float>(x: 1000 * sinf(angle), y: 75, z: 1000 * cosf(angle))
    }
    
    open func render(to mtkView: MTKView) throws {
        try self.setupScene()
        
        guard let scene else { return }
        self.moveStep(scene: scene)
        
        
    }
}
