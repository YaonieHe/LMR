//  Created on 2022/7/5.

import UIKit

import MetalKit

class LMRMeshInitError: LMRError {
    init() {
        super.init("lmrmesh init error")
    }
}

class LMRMesh {
    open private(set) var mtkMesh: MTKMesh
    open private(set) var submeshes: [LMRSubmesh]
    
    init(mdlMesh: MDLMesh, textureLoader: MTKTextureLoader, device: MTLDevice) throws {
        let mtkMesh = try MTKMesh(mesh: mdlMesh, device: device)
        
        if mtkMesh.submeshes.count != mdlMesh.submeshes?.count {
            throw LMRMeshInitError()
        }
        
        self.mtkMesh = mtkMesh
        
        var submeshArray = [LMRSubmesh]()
        
        for i in 0..<mtkMesh.submeshes.count {
            guard let mdlSubmesh = (mdlMesh.submeshes?[i] as? MDLSubmesh) else {
                throw LMRMeshInitError()
            }
            let mtkSubmesh = mtkMesh.submeshes[i]
            let submesh = try LMRSubmesh(mdlSubmesh: mdlSubmesh, mtkSubmesh: mtkSubmesh, textureLoader: textureLoader, device: device)
            submeshArray.append(submesh)
        }
        self.submeshes = submeshArray
    }
}
