//  Created on 2022/8/31.

import Foundation
import Metal
import MetalKit

extension Dictionary {
    static func luc_textureOption(sRGB: Bool, mipmap: Bool,  mode: MTLResourceOptions = .storageModePrivate) -> [MTKTextureLoader.Option : Any] {
        return [
            .SRGB : sRGB,
            .generateMipmaps: mipmap,
            .textureUsage: [MTLTextureUsage.pixelFormatView, MTLTextureUsage.shaderRead],
            .textureStorageMode: mode
        ]
    }
}
