//  Created on 2022/7/6.

import UIKit

class LMR3DLightPainter: LMR3DPainter {
    
    private enum LightBufferIndex: Int
    {
        case meshPositions = 0
        case view
        case obj
        case ambiant
        case light
        case lightCount
    }
    
    func draw(_ light: LMRLight) throws {
        guard let object = light.object else { return }
        guard let mesh = object.mesh else { return }
        
        let modelM = object.location.transform
        
        var lightParam = LMR3DPointLightParams(color: light.color, position: light.position)
        
        try self.normal_setRenderPipeline("LMR3D::vertexLightObject", "LMR3D::fragmentLight")
        self.normal_setDepthStencil()
        
        for i in 0..<mesh.mtkMesh.vertexBuffers.count {
            let vertexBuffer = mesh.mtkMesh.vertexBuffers[i]
            encoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: i)
        }

        encoder.setVertexBytes(&viewParam, length: MemoryLayout<LMR3DViewParams>.stride, index: LightBufferIndex.view.rawValue)
        
        encoder.setFragmentBytes(&lightParam, length: MemoryLayout<LMR3DPointLightParams>.stride, index: LightBufferIndex.light.rawValue)
        
        for submesh in mesh.submeshes {
            var objParam = LMR3DObjParams(modelMatrix: modelM, diffuseColor: submesh.material.diffuse, specularColor: submesh.material.specular, shininess: submesh.material.shininess)
            encoder.setVertexBytes(&objParam, length: MemoryLayout<LMR3DObjParams>.stride, index: LightBufferIndex.obj.rawValue)
            
            let indexBuffer = submesh.mtkSubMesh.indexBuffer
            encoder.setTriangleFillMode(.fill)
            encoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.mtkSubMesh.indexCount, indexType: submesh.mtkSubMesh.indexType, indexBuffer: indexBuffer.buffer, indexBufferOffset: indexBuffer.offset)
        }
    }
    
    func drawPhong(_ object: LMRObject, lights: [LMRLight], ambient: SIMD3<Float> = SIMD3<Float>(0, 0, 0)) throws {
        try self.drawLight(object, lights: lights, ambient: ambient, lightFunc: "LMR3D::fragmentPhongLight")
    }
    
    func drawBlinnPhong(_ object: LMRObject, lights: [LMRLight], ambient: SIMD3<Float> = SIMD3<Float>(0, 0, 0)) throws {
        try self.drawLight(object, lights: lights, ambient: ambient, lightFunc: "LMR3D::fragmentBlinnPhong")
    }
    
    private func drawLight(_ object: LMRObject, lights: [LMRLight], ambient: SIMD3<Float>, lightFunc: String) throws {
        guard let mesh = object.mesh else { return }
        
        let modelM = object.location.transform
        
        var lightParams = [LMR3DPointLightParams]()
        
        for light in lights {
            let param = LMR3DPointLightParams(color: light.color, position: light.position)
            lightParams.append(param)
        }
        
        var lightCount = lightParams.count
        if lightCount == 0 {
            lightParams.append(LMR3DPointLightParams())
        }
        
        try self.normal_setRenderPipeline("LMR3D::vertexLightObject", lightFunc)
        self.normal_setDepthStencil()
        
        encoder.setVertexBytes(&viewParam, length: MemoryLayout<LMR3DViewParams>.stride, index: LightBufferIndex.view.rawValue)
        encoder.setFragmentBytes(&viewParam, length: MemoryLayout<LMR3DViewParams>.stride, index: LightBufferIndex.view.rawValue)
        encoder.setFragmentBytes(&lightParams, length: MemoryLayout<LMR3DPointLightParams>.stride * lightParams.count, index: LightBufferIndex.light.rawValue)
        encoder.setFragmentBytes(&lightCount, length: MemoryLayout<Int>.stride, index: LightBufferIndex.lightCount.rawValue)
        var ambientColor = ambient
        encoder.setFragmentBytes(&ambientColor, length: MemoryLayout<SIMD3<Float>>.stride, index: LightBufferIndex.ambiant.rawValue)
        
        for i in 0..<mesh.mtkMesh.vertexBuffers.count {
            let vertexBuffer = mesh.mtkMesh.vertexBuffers[i]
            encoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: i)
        }
        
        for submesh in mesh.submeshes {
            var objParam = LMR3DObjParams(modelMatrix: modelM, diffuseColor: submesh.material.diffuse, specularColor: submesh.material.specular, shininess: submesh.material.shininess)
            encoder.setVertexBytes(&objParam, length: MemoryLayout<LMR3DObjParams>.stride, index: LightBufferIndex.obj.rawValue)
            encoder.setFragmentBytes(&objParam, length: MemoryLayout<LMR3DObjParams>.stride, index: LightBufferIndex.obj.rawValue)
            
            let indexBuffer = submesh.mtkSubMesh.indexBuffer
            encoder.setTriangleFillMode(.fill)
            encoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.mtkSubMesh.indexCount, indexType: submesh.mtkSubMesh.indexType, indexBuffer: indexBuffer.buffer, indexBufferOffset: indexBuffer.offset)
        }
    }
}
