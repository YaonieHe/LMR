//  Created on 2022/8/15.

import UIKit
import ModelIO
import MetalKit

class LMRReflectionRenderer: LMRRenderer {
    open var scene: LMRScene?
    open var rfCamera: LMRCameraProbe = LMRCameraProbe()
    open var rfObj: LMRRFObject = LMRRFObject()
    
    open var frameParam: LMRRFFrameParam = LMRRFFrameParam()
    
    private func setupScene() throws {
        if self.scene != nil {
            return
        }
        
        let newScene = LMRScene()
        newScene.camera.leftHand = true
        newScene.camera.nearZ = 50
        newScene.camera.farZ = 3000
        newScene.camera.position = SIMD3<Float>(0, 400, 800)
        newScene.camera.field = radians_from_degrees(65)
        
        rfCamera.near = newScene.camera.nearZ
        rfCamera.far = newScene.camera.farZ
        
        let modelUrl = Bundle.main.url(forResource: "Temple.obj", withExtension: nil)
        let bufferAllocator = MTKMeshBufferAllocator(device: self.context.device)
        let mdlAsset = MDLAsset(url: modelUrl, vertexDescriptor: nil, bufferAllocator: bufferAllocator)
        mdlAsset.lmr_setShininess(shininess: 32)
        let mdlAABB = mdlAsset.boundingBox
        
        let meshes = try LMRMesh.createMeshes(asset: mdlAsset, vertexDescriptor: MDLVertexDescriptor.lmr_pnttbDesc(), textureLoader: self.context.textureLoader, device: self.context.device, tangent: true)
        let sphere = LMRRFSphere(boundBox: mdlAABB)
        
        // 4个模型
        do {
            let obj = LMRRFObject()
            obj.meshes = meshes
            obj.sphere = sphere
            obj.location.position = SIMD3<Float>(-1000, -150, 1000)
            newScene.objects.append(obj)
        }
        do {
            let obj = LMRRFObject()
            obj.meshes = meshes
            obj.sphere = sphere
            obj.location.position = SIMD3<Float>(1000, -150, 1000)
            newScene.objects.append(obj)
        }
        do {
            let obj = LMRRFObject()
            obj.meshes = meshes
            obj.sphere = sphere
            obj.location.position = SIMD3<Float>(1150, -150, -400)
            newScene.objects.append(obj)
        }
        do {
            let obj = LMRRFObject()
            obj.meshes = meshes
            obj.sphere = sphere
            obj.location.position = SIMD3<Float>(-1200, -150, -300)
            newScene.objects.append(obj)
        }
        
        do { // 地板
            let mdlGround = MDLMesh.newPlane(withDimensions: SIMD2<Float>(100000, 100000), segments: SIMD2<UInt32>(1, 1), geometryType: .triangles, allocator: bufferAllocator)
            let groundMeshes = try LMRMesh.createMeshes(object: mdlGround, vertexDescriptor: MDLVertexDescriptor.lmr_pnttbDesc(), textureLoader: self.context.textureLoader, device: self.context.device, tangent: true)
            
            let obj = LMRRFObject()
            obj.meshes = groundMeshes
            obj.sphere.radius = 1415
            obj.location.position = SIMD3<Float>(0, -200, 0)
            obj.floor = true
            newScene.objects.append(obj)
        }
        
        do { // 反射球
            let r: Float = 200
            let mdlSphere = MDLMesh.newEllipsoid(withRadii: SIMD3<Float>(r, r, r), radialSegments: 50, verticalSegments: 50, geometryType: .triangles, inwardNormals: false, hemisphere: false, allocator: bufferAllocator)
            self.rfObj.meshes = try LMRMesh.createMeshes(object: mdlSphere, vertexDescriptor: MDLVertexDescriptor.lmr_pnttbDesc(), textureLoader: self.context.textureLoader, device: self.context.device, tangent:true)
            self.rfObj.sphere.radius = r
            self.rfObj.location.position = SIMD3<Float>(100, 0, 0);
        }
        
        self.scene = newScene
        
        frameParam.ambientLightColor = SIMD3<Float>(0.2, 0.2, 0.2)
        frameParam.directionalLightColor = SIMD3<Float>(0.75, 0.75, 0.75)
        frameParam.directionalLightInvDirection = -normalize(SIMD3<Float>(1.0, -1.0, 1.0))
    }
    
    private func moveStep(scene: LMRScene) {
        
        func _rotate2d(position: SIMD3<Float>, angle: Float) -> SIMD3<Float> {
            var pos2d = SIMD2<Float>(position.x, position.z)
            let rotate = float2x2(SIMD2<Float>(cos(angle), -sin(angle)), SIMD2<Float>(sin(angle), cos(angle)))
            pos2d = rotate * pos2d
            return SIMD3<Float>(pos2d.x, position.y, pos2d.y)
        }
        
        for obj in scene.objects {
            if let rfobj = obj as? LMRRFObject {
                if rfobj.floor {
                    continue
                }
            }
            obj.location.rotate.x += 0.01
            obj.location.position = _rotate2d(position: obj.location.position, angle: 0.015);
        }
        rfObj.location.position = _rotate2d(position: rfObj.location.position, angle: -0.013);
        
        rfCamera.position = self.rfObj.location.position
    }
    
    static let CubemapResolution: Int = 256
    var rfCubeMap: MTLTexture?
    var rfCubeMapDepth: MTLTexture?
    var rfPassDesc: MTLRenderPassDescriptor?
    
    var depthState: MTLDepthStencilState?
    
    var objPipeline: MTLRenderPipelineState?
    var floorPipeline: MTLRenderPipelineState?
    var reflectionPipeline: MTLRenderPipelineState?
    
    private func setupMetal(mtkView: MTKView) throws {
        if rfCubeMap == nil {
            let desc = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .bgra8Unorm_srgb, size: LMRReflectionRenderer.CubemapResolution, mipmapped: false)
            desc.storageMode = .private
            desc.usage = [.renderTarget, .shaderRead]
            rfCubeMap = context.device.makeTexture(descriptor: desc)
        }
        
        if rfCubeMapDepth == nil {
            let desc = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .depth32Float, size: LMRReflectionRenderer.CubemapResolution, mipmapped: false)
            desc.storageMode = .private
            desc.usage = .renderTarget
            rfCubeMapDepth = context.device.makeTexture(descriptor: desc)
        }
        
        if rfPassDesc == nil {
            let desc = MTLRenderPassDescriptor()
            desc.colorAttachments[0].clearColor = .init(red: 0, green: 0, blue: 0, alpha: 0)
            desc.colorAttachments[0].loadAction = .clear
            desc.colorAttachments[0].texture = rfCubeMap
            desc.depthAttachment.clearDepth = 1
            desc.depthAttachment.loadAction = .clear
            desc.depthAttachment.texture = rfCubeMapDepth
            desc.renderTargetArrayLength = 6
            
            rfPassDesc = desc
        }
        
        if depthState == nil {
            depthState = context.generateDepthStencilState(descriptor: MTLDepthStencilDescriptor.lmr_init(compare: .less, write: true))!
        }
        
        if objPipeline == nil {
            let desc = context.generatePipelineDescriptor(vertexFunc: "LMR3D::vertexReflection", fragmentFunc: "LMR3D::fragmentRFObj")
            desc.vertexDescriptor = MTLVertexDescriptor.lmr_pnttbDesc()
            desc.inputPrimitiveTopology = .triangle
            desc.sampleCount = mtkView.sampleCount
            desc.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
            desc.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
            
            objPipeline = try context.generateRenderPipelineState(descriptor: desc)
        }
        
        if floorPipeline == nil {
            let desc = context.generatePipelineDescriptor(vertexFunc: "LMR3D::vertexReflection", fragmentFunc: "LMR3D::fragmentRFFloor")
            desc.vertexDescriptor = MTLVertexDescriptor.lmr_pnttbDesc()
            desc.inputPrimitiveTopology = .triangle
            desc.sampleCount = mtkView.sampleCount
            desc.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
            desc.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
            
            floorPipeline = try context.generateRenderPipelineState(descriptor: desc)
        }
        
        if reflectionPipeline == nil {
            let desc = context.generatePipelineDescriptor(vertexFunc: "LMR3D::vertexReflection", fragmentFunc: "LMR3D::fragmentReflection")
            desc.vertexDescriptor = MTLVertexDescriptor.lmr_pnttbDesc()
            desc.inputPrimitiveTopology = .triangle
            desc.sampleCount = mtkView.sampleCount
            desc.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
            desc.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
            
            reflectionPipeline = try context.generateRenderPipelineState(descriptor: desc)
        }
    }
    
    open func render(to mtkView: MTKView) throws {
        try self.setupScene()
        
        guard let scene = self.scene else { return }
        scene.camera.aspect = Float(mtkView.drawableSize.width / mtkView.drawableSize.height)
        self.moveStep(scene: scene)
        
        try self.setupMetal(mtkView: mtkView)
        
        do {
            guard let commandBuffer = self.context.commandQueue.makeCommandBuffer() else { return }
            
            guard let rfPassDesc = self.rfPassDesc else { return }
            guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: rfPassDesc) else { return }
            self.drawReflectionMap(encoder: encoder, scene: scene)
            encoder.endEncoding()
            commandBuffer.commit()
        }
        
        do {
            guard let commandBuffer = self.context.commandQueue.makeCommandBuffer() else { return }
            
            guard let desc = mtkView.currentRenderPassDescriptor else {return}
            desc.renderTargetArrayLength = 1
            guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: desc) else { return }
            self.drawFinal(encoder: encoder, scene: scene)
            self.drawReflection(encoder: encoder, scene: scene)
            encoder.endEncoding()
            
            if let drawable = mtkView.currentDrawable {
                commandBuffer.present(drawable)
            }
            commandBuffer.commit()
        }
    }
    
    private func drawReflection(encoder: MTLRenderCommandEncoder, scene: LMRScene) {
        let projectM = scene.camera.projectMatrix
        let viewM = scene.camera.viewMatrix
        let viewParam = LMR3DViewParams(cameraPos: scene.camera.position, viewProjectionMatrix: projectM * viewM)
        var viewParams = [viewParam]
        
        encoder.setDepthStencilState(depthState)
        encoder.setRenderPipelineState(reflectionPipeline!)
        encoder.setFragmentBytes(&frameParam, length: MemoryLayout<LMRRFFrameParam>.stride, index: Int(LMRRFBufferIndex_Frame.rawValue))
        encoder.setVertexBytes(&viewParams, length: MemoryLayout<LMR3DViewParams>.stride, index: Int(LMRRFBufferIndex_View.rawValue))
        encoder.setFragmentBytes(&viewParams, length: MemoryLayout<LMR3DViewParams>.stride, index: Int(LMRRFBufferIndex_View.rawValue))
        encoder.setFragmentTexture(rfCubeMap, index: 0)
        var instances: [UInt32] = [0]
        self.drawRfObj(object: rfObj, encoder: encoder, instance: &instances)
    }
    
    private func drawReflectionMap(encoder: MTLRenderCommandEncoder, scene: LMRScene) {
        let projectM = rfCamera.getLeftProjectMatrix()
        var viewParams = [LMR3DViewParams]()
        var cullerProbe = [LMRFrustumCuller]()
        
        
        for i in 0 ..< 6 {
            let viewM = rfCamera.getLeftViewMatrix(face: i)
            let param = LMR3DViewParams(cameraPos: rfCamera.position, viewProjectionMatrix: projectM * viewM)
            viewParams.append(param)
            
            let culler = LMRFrustumCuller(viewmatrix: viewM, camera: rfCamera)
            cullerProbe.append(culler)
        }
        
        encoder.setDepthStencilState(depthState)
        encoder.setFragmentBytes(&frameParam, length: MemoryLayout<LMRRFFrameParam>.stride, index: Int(LMRRFBufferIndex_Frame.rawValue))
        encoder.setVertexBytes(&viewParams, length: MemoryLayout<LMR3DViewParams>.stride * 6, index: Int(LMRRFBufferIndex_View.rawValue))
        encoder.setFragmentBytes(&viewParams, length: MemoryLayout<LMR3DViewParams>.stride * 6, index: Int(LMRRFBufferIndex_View.rawValue))
        
        for obj in scene.objects {
            guard let rfObj = obj as? LMRRFObject else {
                continue
            }
            
            var instances = [UInt32]()
            for face in 0 ..< 6 {
                if cullerProbe[face].intersects(sphere: rfObj.sphere) {
                    instances.append(UInt32(face))
                }
            }
            if instances.count == 0 {
                continue
            }
            if rfObj.floor {
                encoder.setRenderPipelineState(floorPipeline!)
            } else {
                encoder.setRenderPipelineState(objPipeline!)
            }
            self.drawRfObj(object: rfObj, encoder: encoder, instance: &instances)
        }
    }
    
    private func drawFinal(encoder: MTLRenderCommandEncoder, scene: LMRScene) {
        let projectM = scene.camera.projectMatrix
        let viewM = scene.camera.viewMatrix
        let viewParam = LMR3DViewParams(cameraPos: scene.camera.position, viewProjectionMatrix: projectM * viewM)
        var viewParams = [viewParam]
        
        let culler = LMRFrustumCuller(camera: scene.camera)
        
        encoder.setDepthStencilState(depthState)
        encoder.setFragmentBytes(&frameParam, length: MemoryLayout<LMRRFFrameParam>.stride, index: Int(LMRRFBufferIndex_Frame.rawValue))
        encoder.setVertexBytes(&viewParams, length: MemoryLayout<LMR3DViewParams>.stride, index: Int(LMRRFBufferIndex_View.rawValue))
        encoder.setFragmentBytes(&viewParams, length: MemoryLayout<LMR3DViewParams>.stride, index: Int(LMRRFBufferIndex_View.rawValue))
        
        for obj in scene.objects {
            guard let rfObj = obj as? LMRRFObject else {
                continue
            }
            if !culler.intersects(sphere: rfObj.sphere) {
                continue
            }
            var instances: [UInt32] = [0]
            if rfObj.floor {
                encoder.setRenderPipelineState(floorPipeline!)
            } else {
                encoder.setRenderPipelineState(objPipeline!)
            }
            self.drawRfObj(object: rfObj, encoder: encoder, instance: &instances)
        }
        
    }
    
    private func drawRfObj(object: LMRRFObject, encoder: MTLRenderCommandEncoder, instance: inout [UInt32]) {
        let modelM = object.location.transform
        
        encoder.setVertexBytes(instance, length: MemoryLayout<UInt32>.stride * instance.count, index: Int(LMRRFBufferIndex_Instance.rawValue))
        
        for mesh in object.meshes {
            for i in 0 ..< mesh.mtkMesh.vertexBuffers.count {
                let vertexBuffer = mesh.mtkMesh.vertexBuffers[i]
                encoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: i)
            }
            
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
                if let normalTexture = submesh.normalTexture {
                    objParam.isNormalTexture = 1
                    encoder.setFragmentTexture(normalTexture, index: Int(LMR3DTextureIndex_Normal.rawValue))
                }
                encoder.setVertexBytes(&objParam, length: MemoryLayout<LMR3DObjParams>.stride, index: Int(LMRRFBufferIndex_Obj.rawValue))
                encoder.setFragmentBytes(&objParam, length: MemoryLayout<LMR3DObjParams>.stride, index: Int(LMRRFBufferIndex_Obj.rawValue))
                
                let indexBuffer = submesh.mtkSubMesh.indexBuffer
                encoder.setTriangleFillMode(.fill)
                encoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.mtkSubMesh.indexCount, indexType: submesh.mtkSubMesh.indexType, indexBuffer: indexBuffer.buffer, indexBufferOffset: indexBuffer.offset, instanceCount: instance.count)
            }
        }
    }
}
