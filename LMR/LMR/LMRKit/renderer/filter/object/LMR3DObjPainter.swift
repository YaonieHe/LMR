//  Created on 2022/7/5.

import Foundation
import Metal

class LMR3DObjPainter {
    var context: LMRContext
    var object: LMRObject
    var encoder: MTLRenderCommandEncoder
    var viewParam: LMR3DViewParams
    
    private var depthStencilState: MTLDepthStencilState
    private var renderPipeLineState: MTLRenderPipelineState
    
    init(context: LMRContext, object: LMRObject, encoder: MTLRenderCommandEncoder, viewParam: LMR3DViewParams) {
        self.context = context
        self.object = object
        self.encoder = encoder
        self.viewParam = viewParam
        
        let depthStateDescriptor = MTLDepthStencilDescriptor()
        depthStateDescriptor.depthCompareFunction = .less
        depthStateDescriptor.isDepthWriteEnabled = true
        
        self.depthStencilState = context.device.makeDepthStencilState(descriptor: depthStateDescriptor)!
        self.renderPipeLineState = try getRenderPipeLineState(vertFunc: "", fragFunc: "")
    }
    
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
    
    private enum BufferIndex: Int
    {
        case meshPositions = 0
        case viewParam
        case objParam
    }
    
    func draw() {
        let modelM = object.location.transform
        if let mesh = object.mesh {

           encoder.setRenderPipelineState(renderPipeLineState)
           encoder.setDepthStencilState(depthStencilState)

            for i in 0..<mesh.mtkMesh.vertexBuffers.count {
                let vertexBuffer = mesh.mtkMesh.vertexBuffers[i]
                encoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: i)
            }

            encoder.setVertexBytes(&viewParam, length: MemoryLayout<LMR3DViewParams>.stride, index: BufferIndex.viewParam.rawValue)

           for submesh in mesh.submeshes {
               var objParam = LMR3DObjParams(modelMatrix: modelM, diffuseColor: submesh.material.diffuse, specularColor: submesh.material.specular, shininess: submesh.material.shininess)
               encoder.setFragmentBytes(&objParam, length: MemoryLayout<LMR3DObjParams>.stride, index: BufferIndex.objParam.rawValue)

               let indexBuffer = submesh.mtkSubMesh.indexBuffer
               encoder.setTriangleFillMode(.fill)
               encoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.mtkSubMesh.indexCount, indexType: submesh.mtkSubMesh.indexType, indexBuffer: indexBuffer.buffer, indexBufferOffset: indexBuffer.offset)
           }
       }
    }
}
