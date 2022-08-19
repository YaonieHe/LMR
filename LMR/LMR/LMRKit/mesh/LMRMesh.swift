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
    
    convenience init(mdlMesh: MDLMesh, textureLoader: MTKTextureLoader, device: MTLDevice, vertexDescriptor: MDLVertexDescriptor, tangent: Bool = true) throws {
        if (tangent) {
            mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate, normalAttributeNamed: MDLVertexAttributeNormal, tangentAttributeNamed: MDLVertexAttributeTangent)
            mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate, tangentAttributeNamed: MDLVertexAttributeTangent, bitangentAttributeNamed: MDLVertexAttributeBitangent)
        }
        mdlMesh.vertexDescriptor = vertexDescriptor;
        
        try self.init(mdlMesh: mdlMesh, textureLoader: textureLoader, device: device)
    }
    
    class func createMeshes(object: MDLObject, vertexDescriptor: MDLVertexDescriptor, textureLoader: MTKTextureLoader, device: MTLDevice, tangent: Bool = true) throws -> [LMRMesh] {
        var result = [LMRMesh]()
        
        if object.isKind(of: MDLMesh.self) {
            let mdlMesh = object as! MDLMesh
            
            if (tangent) {
                mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate, normalAttributeNamed: MDLVertexAttributeNormal, tangentAttributeNamed: MDLVertexAttributeTangent)
                mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate, tangentAttributeNamed: MDLVertexAttributeTangent, bitangentAttributeNamed: MDLVertexAttributeBitangent)
            }
            
            mdlMesh.vertexDescriptor = vertexDescriptor;
            let lmrMesh = try LMRMesh(mdlMesh: mdlMesh, textureLoader: textureLoader, device: device)
            result.append(lmrMesh)
        }
        if object.children != nil {
            for child in object.children.objects {
                let subResult = try self.createMeshes(object: child, vertexDescriptor: vertexDescriptor, textureLoader: textureLoader, device: device, tangent: tangent)
                if subResult.count > 0 {
                    result.append(contentsOf: subResult)
                }
            }
        }
        
        return result
    }
    
    class func createMeshes(asset: MDLAsset, vertexDescriptor: MDLVertexDescriptor, textureLoader: MTKTextureLoader, device: MTLDevice, tangent: Bool = true) throws -> [LMRMesh] {
        var result = [LMRMesh]()
        for i in 0 ..< asset.count {
            let obj = asset.object(at: i)
            result.append(contentsOf: try self.createMeshes(object: obj, vertexDescriptor: vertexDescriptor, textureLoader: textureLoader, device: device, tangent: tangent))
        }
        return result
    }
}
