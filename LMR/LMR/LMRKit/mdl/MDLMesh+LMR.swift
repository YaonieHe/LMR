//  Created on 2022/7/5.

import Foundation
import ModelIO

extension MDLMesh {
    static func lmr_box(size: SIMD3<Float>, bufferAllocator: MDLMeshBufferAllocator?) -> MDLMesh {
        let mesh = MDLMesh(boxWithExtent: SIMD3<Float>(size.x, size.y, size.z), segments: SIMD3<UInt32>(1, 1, 1), inwardNormals: false, geometryType: .triangles, allocator: bufferAllocator)
        return mesh
    }
}
