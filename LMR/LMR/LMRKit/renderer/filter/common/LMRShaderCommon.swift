//  Created on 2022/7/5.

import UIKit

import simd

enum LMR3DVertexAttribute: Int {
    case position  = 0
    case texcoord  = 1
    case normal    = 2
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
    var diffuseColor: SIMD4<Float>;
    var specularColor: SIMD4<Float>;
    var shininess: Float;
}
