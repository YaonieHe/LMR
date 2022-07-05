//
//  MTKMesh+LMR.swift
//  LMR
//
//  Created by hjp-Mic on 2022/7/5.
//

import Foundation
import Metal

extension MTLVertexDescriptor {
    static func lmr_pntDesc() -> MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].offset = 0;
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].bufferIndex = 0
        
       vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 3;
       vertexDescriptor.attributes[1].format = .float3
       vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.attributes[2].offset = MemoryLayout<Float>.size * 6;
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 8
        return vertexDescriptor
    }
}
