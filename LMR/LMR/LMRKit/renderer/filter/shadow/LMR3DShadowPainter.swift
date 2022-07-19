//  Created on 2022/7/18.

import UIKit

fileprivate enum BufferIndex: Int
{
    case mesh = 0
    case view
    case obj
    case ambiant
    case light
    case maxDepth
}

class LMR3DShadowPainter {
    var context: LMRContext
    var encoder: MTLRenderCommandEncoder {
        didSet {
            hasSetShadowEncoder = false
        }
    }
    
    var depthStencilPixelFormat: MTLPixelFormat = .depth32Float {
        didSet {
            hasSetShadowEncoder = false
        }
    }
    
    var light: LMRLight {
        didSet {
            self.updateCubeViewParams()
        }
    }
    
    var nearZ: Float = 0.1 {
        didSet {
            self.updateCubeViewParams()
        }
    }
    var farZ: Float = 100 {
        didSet {
            self.updateCubeViewParams()
        }
    }
    
    var maxDepth: Float = 200
    
    private var viewParams: [LMR3DViewParams] = [LMR3DViewParams]()
    private var hasSetShadowEncoder: Bool = false
    
    
    init(context: LMRContext, encoder: MTLRenderCommandEncoder, light: LMRLight) {
        self.context = context
        self.encoder = encoder
        self.light = light
        
        self.updateCubeViewParams()
    }
    
    private func updateCubeViewParams() {
        let position = light.position;
        let projectM = float4x4(perspectiveRightHandWithFovy: Float.pi * 0.5, aspectRatio: 1, nearZ: self.nearZ, farZ: self.farZ)
        var params = [LMR3DViewParams]()
        for i in 0 ... 5 {
            let viewM = float4x4.look_at_cube(eye: position, face: i)
            params.append(LMR3DViewParams(cameraPos: position, viewProjectionMatrix: projectM * viewM))
        }
        viewParams = params
    }
    
    func setShadowEncoder() throws {
        if hasSetShadowEncoder {
            return
        }
        hasSetShadowEncoder = true
        
        let pipelineDescriptor = self.context.generatePipelineDescriptor(vertexFunc: "LMR3D::vertexPointShadow", fragmentFunc: "LMR3D::fragmentPointShadow")
        pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.lmr_pntDesc()
        pipelineDescriptor.inputPrimitiveTopology = .triangle
        pipelineDescriptor.depthAttachmentPixelFormat = self.depthStencilPixelFormat
        
        let renderPipeLineState = try self.context.generateRenderPipelineState(descriptor: pipelineDescriptor)
        
        let depthStencilState = context.generateDepthStencilState(descriptor: MTLDepthStencilDescriptor.lmr_init())
        
        encoder.setRenderPipelineState(renderPipeLineState)
        encoder.setDepthStencilState(depthStencilState)
    }
    
    func drawShadow(_ object: LMRObject) throws {
        guard let mesh = object.mesh else { return }
        
        try self.setShadowEncoder()
        
        var lightParam = LMR3DPointLightParams(color: light.color, position: light.position)
        
        encoder.setVertexBytes(&viewParams, length: MemoryLayout<LMR3DViewParams>.stride * 6, index: BufferIndex.view.rawValue)
        encoder.setFragmentBytes(&lightParam, length: MemoryLayout<LMR3DPointLightParams>.stride, index: BufferIndex.light.rawValue)
        encoder.setFragmentBytes(&maxDepth, length: MemoryLayout<Float>.stride, index: BufferIndex.maxDepth.rawValue)
        
        for i in 0..<mesh.mtkMesh.vertexBuffers.count {
            let vertexBuffer = mesh.mtkMesh.vertexBuffers[i]
            encoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: i)
        }
        
        let modelM = object.location.transform
        
        for submesh in mesh.submeshes {
            var objParam = LMR3DObjParams(modelMatrix: modelM, diffuseColor: submesh.material.diffuse, specularColor: submesh.material.specular, shininess: submesh.material.shininess)
            encoder.setVertexBytes(&objParam, length: MemoryLayout<LMR3DObjParams>.stride, index: BufferIndex.obj.rawValue)
            
            let indexBuffer = submesh.mtkSubMesh.indexBuffer
            encoder.setTriangleFillMode(.fill)
            encoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.mtkSubMesh.indexCount, indexType: submesh.mtkSubMesh.indexType, indexBuffer: indexBuffer.buffer, indexBufferOffset: indexBuffer.offset, instanceCount: 6)
        }
    }
}


class LMR3DShadowObjPainter: LMR3DPainter {

    var maxDepth: Float = 200
    
    func draw(_ object: LMRObject, at light: LMRLight, ambient: SIMD3<Float>, shadow: MTLTexture) throws {
        guard let mesh = object.mesh else { return }
        
        let modelM = object.location.transform
        
        var lightParam = LMR3DPointLightParams(color: light.color, position: light.position)
        
        try self.normal_setRenderPipeline("LMR3D::vertexLightObject", "LMR3D::fragmentPointShadowBlinnPhong")
        self.normal_setDepthStencil()
        
        for i in 0..<mesh.mtkMesh.vertexBuffers.count {
            let vertexBuffer = mesh.mtkMesh.vertexBuffers[i]
            encoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: i)
        }
        
        encoder.setVertexBytes(&viewParam, length: MemoryLayout<LMR3DViewParams>.stride, index: BufferIndex.view.rawValue)
        
        encoder.setFragmentBytes(&viewParam, length: MemoryLayout<LMR3DViewParams>.stride, index: BufferIndex.view.rawValue)
        
        encoder.setFragmentBytes(&lightParam, length: MemoryLayout<LMR3DPointLightParams>.stride, index: BufferIndex.light.rawValue)
        
        encoder.setFragmentBytes(&maxDepth, length: MemoryLayout<Float>.stride, index: BufferIndex.maxDepth.rawValue)
        
        encoder.setFragmentTexture(shadow, index: Int(LMR3DTextureIndex_ShadowCube.rawValue))
        
        var ambientColor = ambient
        encoder.setFragmentBytes(&ambientColor, length: MemoryLayout<SIMD3<Float>>.stride, index: BufferIndex.ambiant.rawValue)
        
        for submesh in mesh.submeshes {
            var objParam = LMR3DObjParams(modelMatrix: modelM, diffuseColor: submesh.material.diffuse, specularColor: submesh.material.specular, shininess: submesh.material.shininess)
            encoder.setVertexBytes(&objParam, length: MemoryLayout<LMR3DObjParams>.stride, index: BufferIndex.obj.rawValue)
            encoder.setFragmentBytes(&objParam, length: MemoryLayout<LMR3DObjParams>.stride, index: BufferIndex.obj.rawValue)
            
            let indexBuffer = submesh.mtkSubMesh.indexBuffer
            encoder.setTriangleFillMode(.fill)
            encoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.mtkSubMesh.indexCount, indexType: submesh.mtkSubMesh.indexType, indexBuffer: indexBuffer.buffer, indexBufferOffset: indexBuffer.offset)
        }
    }
    
}
