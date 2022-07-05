//
//  LMRContext.swift
//  LMR
//
//  Created by hjp-Mic on 2022/7/3.
//

import Foundation

import MetalKit

class LMRContext {
    open var device: MTLDevice
    open var commandQueue: MTLCommandQueue
    open var library: MTLLibrary
    
    open var textureLoader: MTKTextureLoader
    private var textureMap: [String: MTLTexture] = [String: MTLTexture]()
    
    init() {
        device = MTLCreateSystemDefaultDevice()!
        commandQueue = device.makeCommandQueue()!
        library = device.makeDefaultLibrary()!
        textureLoader = MTKTextureLoader(device: device)
    }
    
    open func generateTexture(from imageName: String) throws -> MTLTexture {
        
        if let texture = textureMap[imageName] {
            return texture
        }
        
        let path = Bundle.main.path(forResource: imageName, ofType: nil)!

        let loader = MTKTextureLoader(device: device)
        
        let texture = try loader.newTexture(URL: URL.init(fileURLWithPath: path))
        
        textureMap[imageName] = texture
        
        return texture
    }
}
