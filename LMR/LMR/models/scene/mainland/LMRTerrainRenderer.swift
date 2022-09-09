//  Created on 2022/8/24.

import UIKit
import MetalKit

fileprivate let LMRTerrainHabitatVaritationCount: Int = 4

fileprivate class HabitatTextures {
    var diffSpec: MTLTexture
    var normal: MTLTexture
    
    init(diffUrl: URL, normalUrl: URL, context: LMRContext, count: Int) throws {
        let diff = try context.textureLoader.newTexture(URL: diffUrl, options: .luc_textureOption(sRGB: false, mipmap: false))
        diffSpec = diff.makeTextureView(pixelFormat: .rgba8Unorm_srgb)!
        normal = try context.textureLoader.newTexture(URL: diffUrl, options: .luc_textureOption(sRGB: false, mipmap: false))
        if diffSpec.arrayLength != count || normal.arrayLength != count {
            throw LMRError("texture error")
        }
    }
}

class LMRTerrainRenderer: LMRRenderer {
    private var terrainTextures: [HabitatTextures] = [HabitatTextures]()
    private var terrainParamsBuffer: MTLBuffer!
    override init() {
        super.init()
        do {
            for habitatNams in ["sand", "grass", "rock", "snow"] {
                let diffUrl = Bundle.main.url(forResource: "Terrain/Textures/terrain_\(habitatNams)_diffspec_array.ktx", withExtension: nil)!
                let normalUrl = Bundle.main.url(forResource: "Terrain/Textures/terrain_\(habitatNams)_normal_array.ktx", withExtension: nil)!
                let habitat = try HabitatTextures(diffUrl: diffUrl, normalUrl: normalUrl, context: context, count: LMRTerrainHabitatVaritationCount)
                terrainTextures.append(habitat)
            }
            
            let terrainShadingFunc = context.generateFunction(name: "LMRML::terrain_fragment")!
            let paramsEncoder = terrainShadingFunc.makeArgumentEncoder(bufferIndex: 1)
            terrainParamsBuffer = context.device.makeBuffer(length: paramsEncoder.encodedLength, options: .storageModeShared)
            paramsEncoder.setArgumentBuffer(terrainParamsBuffer, offset: 0)

        } catch {
            assertionFailure("error: \(error)")
        }
    }
}
