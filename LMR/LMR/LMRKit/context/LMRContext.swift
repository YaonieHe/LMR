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
    private var _pipelineCache: NSCache<MTLRenderPipelineDescriptor, MTLRenderPipelineState>
    private var _depthStencilCache: NSCache<MTLDepthStencilDescriptor, MTLDepthStencilState>
    private var _funcCache: NSCache<NSString, MTLFunction>
    
    init() {
        device = MTLCreateSystemDefaultDevice()!
        commandQueue = device.makeCommandQueue()!
        library = device.makeDefaultLibrary()!
        textureLoader = MTKTextureLoader(device: device)
        
        _pipelineCache = NSCache<MTLRenderPipelineDescriptor, MTLRenderPipelineState>()
        _pipelineCache.countLimit = 50
        
        _depthStencilCache = NSCache<MTLDepthStencilDescriptor, MTLDepthStencilState>()
        _depthStencilCache.countLimit = 20
        
        _funcCache = NSCache<NSString, MTLFunction>()
        _funcCache.countLimit = 100
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
    
    open func generateDepthStencilState(descriptor: MTLDepthStencilDescriptor) -> MTLDepthStencilState? {
        let desc = descriptor.copy() as! MTLDepthStencilDescriptor
        if let result = _depthStencilCache.object(forKey: desc) {
            return result
        }
        if let state = device.makeDepthStencilState(descriptor: descriptor) {
            _depthStencilCache.setObject(state, forKey: desc)
            return state
        }
        return nil
    }
    
    open func generateRenderPipelineState(descriptor: MTLRenderPipelineDescriptor) throws -> MTLRenderPipelineState {
        let desc = descriptor.copy() as! MTLRenderPipelineDescriptor
        if let result = _pipelineCache.object(forKey: desc) {
            return result
        }
        let pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        _pipelineCache.setObject(pipelineState, forKey: desc)
        return pipelineState
    }
    
    open func generateFunction(name: String) -> MTLFunction? {
        let cacheKey = name as NSString
        if let function = _funcCache.object(forKey: cacheKey) {
            return function
        }
        if let function = library.makeFunction(name: name) {
            _funcCache.setObject(function, forKey: cacheKey)
            return function
        }
        return nil
    }
    
    open func generatePipelineDescriptor(vertexFunc: String?, fragmentFunc: String?, label: String? = nil) -> MTLRenderPipelineDescriptor {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        if let vertexName = vertexFunc {
            pipelineDescriptor.vertexFunction = self.generateFunction(name: vertexName)
        }
        if let fragmentName = fragmentFunc {
            pipelineDescriptor.fragmentFunction = self.generateFunction(name: fragmentName)
        }
        if let label = label {
            pipelineDescriptor.label = label
        }
        return pipelineDescriptor
    }
    
}
