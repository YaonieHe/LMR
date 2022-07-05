//  Created on 2022/7/5.

import UIKit

import MetalKit

class LMRSubmesh {
    struct LMRMaterial {
        var diffuse: SIMD4<Float>
        var specular: SIMD4<Float>
        var shininess: Float
        init() {
            diffuse = SIMD4<Float>(0, 0, 0, 1)
            specular = SIMD4<Float>(0, 0, 0, 1)
            shininess = 1
        }
    };
    
    open private(set) var mtkSubMesh: MTKSubmesh
    open private(set) var material: LMRMaterial
    open private(set) var diffuseTexture: MTLTexture?
    
    init(mdlSubmesh: MDLSubmesh, mtkSubmesh: MTKSubmesh, textureLoader: MTKTextureLoader, device: MTLDevice) throws {
        self.mtkSubMesh = mtkSubmesh
        
        self.material = LMRMaterial()
    
        guard let mdlMaterial = mdlSubmesh.material else {
            return
        }
        
        if let baseColor = try LMRSubmesh.readMdlMatrialFloat4Color(mdlMaterial: mdlMaterial, semattic: .baseColor) {
            self.material.diffuse = baseColor
            self.material.specular = baseColor
        }
        if let specularColor = try LMRSubmesh.readMdlMatrialFloat4Color(mdlMaterial: mdlMaterial, semattic: .specular) {
            self.material.specular = specularColor
        }
        if let shiness = try LMRSubmesh.readMdlMatrialFloatValue(mdlMaterial: mdlMaterial, semattic: .metallic) {
            self.material.shininess = shiness
        }
        
        if let diffuseTexture = try LMRSubmesh.readMdlMatrialTexture(mdlMaterial: mdlMaterial, semattic: .baseColor, textureLoader: textureLoader) {
            self.diffuseTexture = diffuseTexture
        }
    }
    
    class func readMdlMatrialFloatValue(mdlMaterial: MDLMaterial, semattic: MDLMaterialSemantic) throws -> Float? {
        let properties = mdlMaterial.properties(with: semattic)
        
        for property in properties {
            try LMRAssert(property.semantic == semattic, "LMRSubMesh read matrial error")
            if property.type == .float {
                return property.floatValue
            }
        }
        return nil
    }
    
    class func readMdlMatrialFloat4Color(mdlMaterial: MDLMaterial, semattic: MDLMaterialSemantic) throws -> SIMD4<Float>? {
        let properties = mdlMaterial.properties(with: semattic)
        
        for property in properties {
            try LMRAssert(property.semantic == semattic, "LMRSubMesh read matrial error")
            if property.type == .float4 {
                return property.float4Value
            } else if property.type == .float3 {
                return SIMD4<Float>(property.float3Value, 1)
            }
        }
        return nil
    }
    
    class func readMdlMatrialTexture(mdlMaterial: MDLMaterial, semattic: MDLMaterialSemantic, textureLoader: MTKTextureLoader) throws -> MTLTexture? {
        let properties = mdlMaterial.properties(with: semattic)
        
        
        for property in properties {
            try LMRAssert(property.semantic == semattic, "LMRSubMesh read matrial error")
            
            var textureUrl: URL? = nil
            if property.type == .URL {
                textureUrl = property.urlValue
            } else if property.type == .string {
                if let str = property.stringValue {
                    textureUrl = URL(fileURLWithPath: str)
                }
            }
            
            if let url = textureUrl {
                return try textureLoader.newTexture(URL: url)
            }
        }
        return nil
    }
}
