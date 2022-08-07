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
    
    var tfpLightParam: LMRTFPLightParam {
        return LMRTFPLightParam(color: color, position: position, radius: distance)
    }
}

class LMRTileForwardPlusRenderer: LMRRenderer {
    open var scene: LMRScene?
    
    let numLights: Int = 1024
    let tileWidth: Int = 16
    let tileHeight: Int = 16
    let maxLightPerTile: Int = 64
    
    let tileDataSize: Int = 256
    
    var threadgroupBufferSize: Int {
        return max(maxLightPerTile, tileWidth * tileHeight) * MemoryLayout<UInt32>.stride
    }
    
    enum BufferIndex: Int
    {
        case MeshPositions = 0
        case view
        case obj
        case ambiant
        case light
        case frameData
    }
    
    private func setupScene() throws {
        if self.scene != nil {
            return
        }
        
        let newScene = LMRScene()
        newScene.ambientColor = SIMD3<Float>(0.2, 0.2, 0.2);
        newScene.camera.position = SIMD3<Float>(0, 400, 1000)
        newScene.camera.target = SIMD3<Float>(0, 0, 0)
        newScene.camera.nearZ = 1
        newScene.camera.farZ = 1500
        newScene.camera.field = Float.pi * 65.0 / 180.0
        
        let modelUrl = Bundle.main.url(forResource: "Temple.obj", withExtension: nil)
        let bufferAllocator = MTKMeshBufferAllocator(device: self.context.device)
        let mdlAsset = MDLAsset(url: modelUrl, vertexDescriptor: nil, bufferAllocator: bufferAllocator)
        
        mdlAsset.lmr_setShininess(shininess: 32)
        
        let lmrMeshArray = try LMRMesh.createMeshes(asset: mdlAsset, vertexDescriptor: MDLVertexDescriptor.lmr_pnttbDesc(), textureLoader: self.context.textureLoader, device: self.context.device, tangent: true)
        
        for lmrMesh in lmrMeshArray {
            let obj = LMRObject(mesh: lmrMesh)
//            obj.location.rotate.y = 0.5
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
                r = Float.random(in: Range<Float>(uncheckedBounds: (lower: 40, upper: 41)))
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
//        for obj in scene.objects {
//            obj.location.rotate.x += 0.01
//        }
//        let angle = Float(frameIdx) * 0.01
//        scene.camera.position = SIMD3<Float>(x: 1000 * sinf(angle), y: 75, z: 1000 * cosf(angle))
    }
    
    var renderPassDescriptor: MTLRenderPassDescriptor?
    
    private func getRenderPassDescriptor(mtkView: MTKView) -> MTLRenderPassDescriptor {
        if let renderPassDescriptor = renderPassDescriptor {
            return renderPassDescriptor
        }
        
        let numSamples = mtkView.sampleCount
        
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[1].loadAction = .clear
        descriptor.colorAttachments[1].storeAction = .dontCare
        
        descriptor.depthAttachment.loadAction = .clear
        descriptor.depthAttachment.storeAction = .dontCare
        descriptor.stencilAttachment.loadAction = .clear
        descriptor.stencilAttachment.storeAction = .dontCare
        descriptor.depthAttachment.clearDepth = 1
        descriptor.stencilAttachment.clearStencil = 0
        
        descriptor.tileWidth = tileWidth
        descriptor.tileHeight = tileHeight
        descriptor.threadgroupMemoryLength = threadgroupBufferSize + tileDataSize
        
        if numSamples > 1 {
            descriptor.colorAttachments[0].storeAction = .multisampleResolve
        } else {
            descriptor.colorAttachments[0].storeAction = .store
        }
        
        let size = mtkView.drawableSize
        let textureDescriptor  = MTLTextureDescriptor()
        textureDescriptor.width = Int(size.width)
        textureDescriptor.height = Int(size.height)
        textureDescriptor.usage = .renderTarget
        textureDescriptor.storageMode = .memoryless
        
        if numSamples > 1 {
            textureDescriptor.sampleCount = numSamples
            textureDescriptor.textureType = .type2DMultisample
            textureDescriptor.pixelFormat = mtkView.colorPixelFormat
            
            let msaa = self.context.device.makeTexture(descriptor: textureDescriptor)
            descriptor.colorAttachments[0].texture = msaa
        } else {
            textureDescriptor.textureType = .type2D
        }
        
        textureDescriptor.pixelFormat = .depth32Float
        descriptor.depthAttachment.texture = self.context.device.makeTexture(descriptor: textureDescriptor)
        
        textureDescriptor.pixelFormat = .r32Float
        descriptor.colorAttachments[1].texture = self.context.device.makeTexture(descriptor: textureDescriptor)
        
        self.renderPassDescriptor = descriptor
        return descriptor
    }
    
    private var depthPrePassState: MTLRenderPipelineState?
    private func getDepthPrePassState(mtkView: MTKView) throws -> MTLRenderPipelineState {
        if let depthPrePassState = depthPrePassState {
            return depthPrePassState
        }
        let descriptor = self.context.generatePipelineDescriptor(vertexFunc: "LMR3D::vertexTFPPreDepth", fragmentFunc: "LMR3D::fragmentTFPPreDepth", label: "pre depth")
        descriptor.sampleCount = mtkView.sampleCount
        descriptor.vertexDescriptor = MTLVertexDescriptor.lmr_pnttbDesc()
        descriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        descriptor.colorAttachments[1].pixelFormat = .r32Float
        descriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        let state = try self.context.generateRenderPipelineState(descriptor: descriptor)
        depthPrePassState = state
        return state
    }
    
    private var binCreationState: MTLRenderPipelineState?
    
    private func getBinCreationPipelineState(mtkView: MTKView) throws -> MTLRenderPipelineState {
        if let binCreationState = binCreationState {
            return binCreationState
        }
        
        let descriptor = MTLTileRenderPipelineDescriptor()
        descriptor.rasterSampleCount = mtkView.sampleCount
        descriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        descriptor.colorAttachments[1].pixelFormat = .r32Float
        descriptor.threadgroupSizeMatchesTileSize = true
        descriptor.tileFunction = self.context.generateFunction(name: "LMR3D::TFPBinCreate")!
        
        let state = try self.context.device.makeRenderPipelineState(tileDescriptor: descriptor, options: [], reflection: nil)
        binCreationState = state
        return state
    }
    
    private var lightCullState: MTLRenderPipelineState?
    
    private func getLightCullPipelineState(mtkView: MTKView) throws -> MTLRenderPipelineState {
        if let lightCullState = lightCullState {
            return lightCullState
        }
        
        let descriptor = MTLTileRenderPipelineDescriptor()
        descriptor.rasterSampleCount = mtkView.sampleCount
        descriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        descriptor.colorAttachments[1].pixelFormat = .r32Float
        descriptor.threadgroupSizeMatchesTileSize = true
        descriptor.tileFunction = self.context.generateFunction(name: "LMR3D::TFPCullLights")!
        
        let state = try self.context.device.makeRenderPipelineState(tileDescriptor: descriptor, options: [], reflection: nil)
        lightCullState = state
        return state
    }
    
    private var forwardPipelineState: MTLRenderPipelineState?
    private func getForwardPipelineState(mtkView: MTKView) throws -> MTLRenderPipelineState {
        if let forwardPipelineState = forwardPipelineState {
            return forwardPipelineState
        }
        let descriptor = self.context.generatePipelineDescriptor(vertexFunc: "LMR3D::vertexFTPForwardLight", fragmentFunc: "LMR3D::fragmentFTPForwardLight", label: "forward")
        descriptor.sampleCount = mtkView.sampleCount
        descriptor.vertexDescriptor = MTLVertexDescriptor.lmr_pnttbDesc()
        descriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        descriptor.colorAttachments[1].pixelFormat = .r32Float
        descriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        let state = try self.context.generateRenderPipelineState(descriptor: descriptor)
        forwardPipelineState = state
        return state
    }
    
    private var fairyPipelineState: MTLRenderPipelineState?
    private func getFairyPipelineState(mtkView: MTKView) throws -> MTLRenderPipelineState {
        if let fairyPipelineState = fairyPipelineState {
            return fairyPipelineState
        }
        let descriptor = self.context.generatePipelineDescriptor(vertexFunc: "LMR3D::vertexTFPfairy", fragmentFunc: "LMR3D::fragmentTFPFairy", label: "fairy")
        descriptor.sampleCount = mtkView.sampleCount
        descriptor.vertexDescriptor = MTLVertexDescriptor.lmr_pnttbDesc()
        descriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        descriptor.colorAttachments[1].pixelFormat = .r32Float
        descriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        let state = try self.context.generateRenderPipelineState(descriptor: descriptor)
        fairyPipelineState = state
        return state
    }
    
    private func getFrameData(scene: LMRScene, drawableSize: CGSize) -> LMRTFPFrameData {
        let far = scene.camera.farZ
        let near = scene.camera.nearZ
        let fov = scene.camera.field
        
        var result = LMRTFPFrameData()
        
        result.maxLightPerTile = Int32(maxLightPerTile)
        
        result.ambient = scene.ambientColor;
        
        result.lightCount = UInt32(scene.lights.count)
        
        result.depthUnproject = SIMD2<Float>(far / (far - near), (-far * near) / (far - near))
       
        let fovScale = tanf(0.5 * fov) * 2.0
        let aspectRatio = Float(drawableSize.width / drawableSize.height)
        result.screenToViewSpace = SIMD3<Float>(fovScale / Float(drawableSize.height), -fovScale * 0.5 * aspectRatio, -fovScale * 0.5)
        
        return result
    }
    
    private func drawObjs(scene: LMRScene, at encoder: MTLRenderCommandEncoder) {
        for obj in scene.objects {
            guard let mesh = obj.mesh else { continue }
            for i in 0 ..< mesh.mtkMesh.vertexBuffers.count {
                let vertexBuffer = mesh.mtkMesh.vertexBuffers[i]
                encoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: i)
            }
            let modelM = obj.location.transform
            for submesh in mesh.submeshes {
                var objParam = LMR3DObjParams(modelMatrix: modelM, diffuseColor: submesh.material.diffuse, specularColor: submesh.material.specular, shininess: submesh.material.shininess)
                if let diffTexture = submesh.diffuseTexture {
                    objParam.isDiffuseTexture = 1
                    encoder.setFragmentTexture(diffTexture, index: Int(LMR3DTextureIndex_BaseColor.rawValue))
                }
                if let specularTexture = submesh.specularTexture {
                    objParam.isSpecularTexture = 1
                    encoder.setFragmentTexture(specularTexture, index: Int(LMR3DTextureIndex_Specular.rawValue))
                }
                
                encoder.setVertexBytes(&objParam, length: MemoryLayout<LMR3DObjParams>.stride, index: BufferIndex.obj.rawValue)
                encoder.setFragmentBytes(&objParam, length: MemoryLayout<LMR3DObjParams>.stride, index: BufferIndex.obj.rawValue)
                let indexBuffer = submesh.mtkSubMesh.indexBuffer
                encoder.setTriangleFillMode(.fill)
                encoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.mtkSubMesh.indexCount, indexType: submesh.mtkSubMesh.indexType, indexBuffer: indexBuffer.buffer, indexBufferOffset: indexBuffer.offset)
            }
        }
    }
    
    private var lightBuffer: MTLBuffer?
    
    private func getLightBuffer(scene: LMRScene) throws -> MTLBuffer {
        var lightParams = [LMRTFPLightParam]()
        for light in scene.lights {
            if let tfpLight = light as? LMRTFPLight {
                lightParams.append(tfpLight.tfpLightParam)
            }
        }
        if let buffer = self.context.device.makeBuffer(bytes: &lightParams, length:  MemoryLayout<LMRTFPLightParam>.stride * lightParams.count) {
            return buffer
        }
        throw LMRError("create buffer error")
//        if lightBuffer == nil {
//            lightBuffer = self.context.device.makeBuffer(length: MemoryLayout<LMRTFPLightParam>.stride * lightParams.count, options: .storageModeShared)
//        }
//
//        guard let buffer = lightBuffer else {
//            throw LMRError("create buffer error")
//        }
        
        
    }
    
    
    private var size: CGSize = CGSize.zero
    
    private func setupSize(_ newSize: CGSize) {
        if newSize == size {
            return
        }
        size = newSize
        self.renderPassDescriptor = nil
    }
    
    var lock: NSLock = NSLock()
    
    open func render(to mtkView: MTKView) throws {
        self.setupSize(mtkView.drawableSize)
        try self.setupScene()
        
        guard let scene = self.scene else { return }
        scene.camera.aspect = Float(mtkView.drawableSize.width / mtkView.drawableSize.height);
        self.moveStep(scene: scene)
        
        lock.lock()
        
        guard let commandBuffer = self.context.commandQueue.makeCommandBuffer() else { return }
        
        commandBuffer.addCompletedHandler { _ in
            self.lock.unlock()
        }

        let renderPassDescriptor = self.getRenderPassDescriptor(mtkView: mtkView)
        if mtkView.sampleCount > 1 {
            renderPassDescriptor.colorAttachments[0].resolveTexture = mtkView.currentDrawable?.texture
        } else {
            renderPassDescriptor.colorAttachments[0].texture = mtkView.currentDrawable?.texture
        }

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
//        encoder.setCullMode(.back)
        
        guard let depthState =
                context.generateDepthStencilState(descriptor: MTLDepthStencilDescriptor.lmr_init()) else { return }
        
        guard let relaxdDepthState = context.generateDepthStencilState(descriptor: MTLDepthStencilDescriptor.lmr_init(compare: .lessEqual, write: false)) else { return }
        
        var viewParam = LMR3DViewParams(cameraPos: scene.camera.position, viewProjectionMatrix: scene.camera.projectMatrix * scene.camera.viewMatrix)
        var frameData = getFrameData(scene: scene, drawableSize: mtkView.drawableSize)
        let lightsData = try getLightBuffer(scene: scene)

        
        let depthPrePassPipelineState = try getDepthPrePassState(mtkView: mtkView)
        encoder.setRenderPipelineState(depthPrePassPipelineState)
        encoder.setDepthStencilState(depthState)
        encoder.setVertexBytes(&viewParam, length: MemoryLayout<LMR3DViewParams>.stride, index: BufferIndex.view.rawValue)
        self.drawObjs(scene: scene, at: encoder)

        let binCreationState = try getBinCreationPipelineState(mtkView: mtkView)
        encoder.setRenderPipelineState(binCreationState)
        encoder.setThreadgroupMemoryLength(tileDataSize, offset: threadgroupBufferSize, index: Int(LMRTFPThreadgroupIndices_TileData.rawValue))
        encoder.dispatchThreadsPerTile(MTLSize(width: tileWidth, height: tileHeight, depth: 1))

        let lightCullState = try getLightCullPipelineState(mtkView: mtkView)
        encoder.setRenderPipelineState(lightCullState)
        encoder.setThreadgroupMemoryLength(threadgroupBufferSize, offset: 0, index: Int(LMRTFPThreadgroupIndices_LightList.rawValue))
        encoder.setThreadgroupMemoryLength(tileDataSize, offset: threadgroupBufferSize, index: Int(LMRTFPThreadgroupIndices_TileData.rawValue))
        encoder.setTileBytes(&frameData, length: MemoryLayout<LMRTFPFrameData>.stride, index: BufferIndex.frameData.rawValue)
        encoder.setTileBuffer(lightsData, offset: 0, index: BufferIndex.light.rawValue)
        encoder.dispatchThreadsPerTile(MTLSize(width: tileWidth, height: tileHeight, depth: 1))

        let forwardState = try getForwardPipelineState(mtkView: mtkView)
        encoder.setRenderPipelineState(forwardState)
        encoder.setDepthStencilState(relaxdDepthState)
        encoder.setThreadgroupMemoryLength(threadgroupBufferSize, offset: 0, index: Int(LMRTFPThreadgroupIndices_LightList.rawValue))
        encoder.setThreadgroupMemoryLength(tileDataSize, offset: threadgroupBufferSize, index: Int(LMRTFPThreadgroupIndices_TileData.rawValue))
        encoder.setVertexBytes(&viewParam, length: MemoryLayout<LMR3DViewParams>.stride, index: BufferIndex.view.rawValue)
        encoder.setFragmentBuffer(lightsData, offset: 0, index: BufferIndex.light.rawValue)
        encoder.setFragmentBytes(&frameData, length: MemoryLayout<LMRTFPFrameData>.stride, index: BufferIndex.frameData.rawValue)
        encoder.setFragmentBytes(&viewParam, length: MemoryLayout<LMR3DViewParams>.stride, index: BufferIndex.view.rawValue)
        drawObjs(scene: scene, at: encoder)
        
        let fairyState = try getFairyPipelineState(mtkView: mtkView)
        var fairyParam = LMRTFPFairyParam(vertexCount: 7, viewMatrix: scene.camera.viewMatrix, projectionMatrix: scene.camera.projectMatrix)
        encoder.setRenderPipelineState(fairyState)
        encoder.setDepthStencilState(depthState)
        encoder.setVertexBytes(&fairyParam, length: MemoryLayout<LMRTFPFairyParam>.stride, index: BufferIndex.view.rawValue)
        encoder.setVertexBuffer(lightsData, offset: 0, index: BufferIndex.light.rawValue)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 7, instanceCount: Int(frameData.lightCount))
        
        encoder.endEncoding()
        
        if let drawable = mtkView.currentDrawable {
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
    }
}
