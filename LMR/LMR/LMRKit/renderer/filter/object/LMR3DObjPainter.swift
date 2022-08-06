//  Created on 2022/7/5.

import Foundation
import Metal

class LMR3DObjPainter: LMR3DPainter {
    private enum BufferIndex: Int
    {
        case meshPositions = 0
        case viewParam
        case objParam
    }
    
    open var vertexDescriptor:  MTLVertexDescriptor?
    
    func draw(_ object: LMRObject) throws {
        let modelM = object.location.transform
        if let mesh = object.mesh {
            let depthStencilState = context.generateDepthStencilState(descriptor: MTLDepthStencilDescriptor.lmr_init())
            
            let pipelineDescriptor = self.context.generatePipelineDescriptor(vertexFunc: "LMR3D::vertexObject", fragmentFunc: "LMR3D::fragmentObjectColor")
            if let vertexDescriptor = vertexDescriptor {
                pipelineDescriptor.vertexDescriptor = vertexDescriptor
            } else {
                pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.lmr_pntDesc()
            }
            pipelineDescriptor.sampleCount = self.sampleCount
            pipelineDescriptor.colorAttachments[0].pixelFormat = self.pixelFormat
            pipelineDescriptor.depthAttachmentPixelFormat = self.depthStencilPixelFormat
            
            let renderPipeLineState = try self.context.generateRenderPipelineState(descriptor: pipelineDescriptor)
            
           encoder.setRenderPipelineState(renderPipeLineState)
           encoder.setDepthStencilState(depthStencilState)

            for i in 0..<mesh.mtkMesh.vertexBuffers.count {
                let vertexBuffer = mesh.mtkMesh.vertexBuffers[i]
                encoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: i)
            }

            encoder.setVertexBytes(&viewParam, length: MemoryLayout<LMR3DViewParams>.stride, index: BufferIndex.viewParam.rawValue)

           for submesh in mesh.submeshes {
               var objParam = LMR3DObjParams(modelMatrix: modelM, diffuseColor: submesh.material.diffuse, specularColor: submesh.material.specular, shininess: submesh.material.shininess)
               if let diffTexture = submesh.diffuseTexture {
                   objParam.isDiffuseTexture = 1
                   encoder.setFragmentTexture(diffTexture, index: 0)
               }
               encoder.setVertexBytes(&objParam, length: MemoryLayout<LMR3DObjParams>.stride, index: BufferIndex.objParam.rawValue)
               
               encoder.setFragmentBytes(&objParam, length: MemoryLayout<LMR3DObjParams>.stride, index: BufferIndex.objParam.rawValue)

               let indexBuffer = submesh.mtkSubMesh.indexBuffer
               encoder.setTriangleFillMode(.fill)
               encoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.mtkSubMesh.indexCount, indexType: submesh.mtkSubMesh.indexType, indexBuffer: indexBuffer.buffer, indexBufferOffset: indexBuffer.offset)
           }
       }
    }
}
