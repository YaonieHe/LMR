//  Created on 2022/7/5.

import Foundation
import ModelIO
import Metal

extension MDLVertexDescriptor {
    static func lmr_pntDesc() -> MDLVertexDescriptor {
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.vertexAttributes[0].name = MDLVertexAttributePosition
        vertexDescriptor.vertexAttributes[0].format = .float3
        vertexDescriptor.vertexAttributes[0].offset = 0
        vertexDescriptor.vertexAttributes[0].bufferIndex = 0
        vertexDescriptor.vertexAttributes[1].name = MDLVertexAttributeNormal
        vertexDescriptor.vertexAttributes[1].format = .float3
        vertexDescriptor.vertexAttributes[1].offset = MemoryLayout<Float>.size * 3
        vertexDescriptor.vertexAttributes[1].bufferIndex = 0
        vertexDescriptor.vertexAttributes[2].name = MDLVertexAttributeTextureCoordinate
        vertexDescriptor.vertexAttributes[2].format = .float2
        vertexDescriptor.vertexAttributes[2].offset = MemoryLayout<Float>.size * 6
        vertexDescriptor.vertexAttributes[2].bufferIndex = 0
        vertexDescriptor.bufferLayouts[0].stride = MemoryLayout<Float>.size * 8
        
        return vertexDescriptor
    }
}


extension MDLSubmesh {
    func lmr_setBaseColor(baseColor: SIMD4<Float>) {
        self.material?.setProperty(MDLMaterialProperty(name: "baseColor", semantic: .baseColor, float4: baseColor))
    }
    
    func lmr_setShininess(shininess: Float) {
        self.material?.setProperty(MDLMaterialProperty(name: "shininess", semantic: .metallic, float: shininess))
    }
}

extension MDLMesh {
    public var lmr_submeshes: [MDLSubmesh] {
        if let submeshes = self.submeshes {
            return submeshes as! [MDLSubmesh]
        } else {
            return [MDLSubmesh]()
        }
    }
}

extension MDLMesh {
    static func lmr_box(size: SIMD3<Float>, bufferAllocator: MDLMeshBufferAllocator?) -> MDLMesh {
        let mesh = MDLMesh(boxWithExtent: SIMD3<Float>(size.x, size.y, size.z), segments: SIMD3<UInt32>(1, 1, 1), inwardNormals: false, geometryType: .triangles, allocator: bufferAllocator)
        return mesh
    }
    
    func lmr_setBaseColor(baseColor: SIMD4<Float>) {
        for submesh in self.lmr_submeshes {
            submesh.lmr_setBaseColor(baseColor: baseColor)
        }
    }
    
    func lmr_setShininess(shininess: Float) {
        for submesh in self.lmr_submeshes {
            submesh.lmr_setShininess(shininess: shininess)
        }
    }
}

