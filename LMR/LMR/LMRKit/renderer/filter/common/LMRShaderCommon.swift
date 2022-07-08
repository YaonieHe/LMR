//  Created on 2022/7/5.

import UIKit

import simd

enum LMR3DVertexAttribute: Int {
    case position  = 0
    case normal    = 1
    case texcoord  = 2
}

enum LMR3DTextureIndex: Int {
    case baseColor = 0
    case specular  = 1
    case normal    = 2
    case shadowCube = 3
}

struct LMR3DViewParams {
    var cameraPos: SIMD3<Float>;
    var viewProjectionMatrix: float4x4;
}

struct LMR3DObjParams {
    var modelMatrix: float4x4;
    var normalMatrix: float3x3;
    var diffuseColor: SIMD4<Float>;
    var specularColor: SIMD4<Float>;
    var shininess: Float;
    
    init(modelMatrix: float4x4, diffuseColor: SIMD4<Float>, specularColor: SIMD4<Float>, shininess: Float) {
        self.modelMatrix = modelMatrix
        self.diffuseColor = diffuseColor
        self.specularColor = specularColor
        self.shininess = shininess
        
        self.normalMatrix = float3x3(modelMatrix.inverse.transpose)
    }
}

struct LMR3DPointLightParams {
    var color: SIMD3<Float>;
    var position: SIMD3<Float>;
};
