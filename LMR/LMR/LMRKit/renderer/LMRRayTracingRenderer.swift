//  Created on 2022/7/27.

import UIKit

import MetalPerformanceShaders
import MetalKit

class LMRRayTracingRenderer: LMRRenderer {
    private var scene: Scene?
    private var rayIntersector: RayIntersector?
    
    private var size: CGSize = CGSize(width: 0, height: 0)
    
    static let maxFrames: Int = 3
    
    private var rayPipeline: MTLComputePipelineState?
    private var shadePipeline: MTLComputePipelineState?
    private var shadowPipeline: MTLComputePipelineState?
    private var accumulatePipeline: MTLComputePipelineState?
    private var copyPipeline: MTLRenderPipelineState?
    
    private var renderTargets: [MTLTexture] = [MTLTexture]()
    private var accumulationTargets: [MTLTexture] = [MTLTexture]()
    private var randomTexture: MTLTexture?
    
    private var frameIndex: UInt = 0
    
    private var sem: DispatchSemaphore = DispatchSemaphore(value: maxFrames)
    
    override init() {
        super.init()
        
        self.createScene()
        self.createRayIntersector()
        
        do {
           try self.createPipeline()
        } catch {
            assertionFailure("create pipeline error")
        }
    }
    
    private func createScene() {
        if scene != nil {
            return
        }
        
        let newScene = Scene()
        
        // light
        var transform = float4x4(translationBy: SIMD3<Float>(0, 1, 0)) * float4x4(scale: SIMD3<Float>(0.5, 1.98, 0.5))
        newScene.addCube(faceMask: [.top], color: SIMD3<Float>(1, 1, 1), transform: transform, inwardNormals: true, triangleMask: UInt32(LMRRTTriangleMaskLight))
        
        // wall
        transform = float4x4(translationBy: SIMD3<Float>(0, 1, 0)) * float4x4(scale: SIMD3<Float>(2, 2, 2))
        newScene.addCube(faceMask: [.bottom, .top, .back], color: SIMD3<Float>(0.725, 0.71, 0.68), transform: transform, inwardNormals: true, triangleMask: UInt32(LMRRTTriangleMaskGeometry))
        newScene.addCube(faceMask: [.left], color: SIMD3<Float>(0.63, 0.065, 0.05), transform: transform, inwardNormals: true, triangleMask: UInt32(LMRRTTriangleMaskGeometry))
        newScene.addCube(faceMask: [.right], color: SIMD3<Float>(0.14, 0.45, 0.091), transform: transform, inwardNormals: true, triangleMask: UInt32(LMRRTTriangleMaskGeometry))
        
        // box
        transform = float4x4(translationBy: SIMD3<Float>(0.3275, 0.3, 0.3725)) * float4x4(rotationAroundAxis: SIMD3<Float>(0, 1, 0), by: -0.3) * float4x4(scale: SIMD3<Float>(0.6, 0.6, 0.6))
        newScene.addCube(faceMask: Scene.FaceMask.all(), color: SIMD3<Float>(0.725, 0.71, 0.68), transform: transform, inwardNormals: false, triangleMask: UInt32(LMRRTTriangleMaskGeometry))
        
        transform = float4x4(translationBy: SIMD3<Float>(-0.335, 0.6, -0.29)) * float4x4(rotationAroundAxis: SIMD3<Float>(0, 1, 0), by: 0.3) * float4x4(scale: SIMD3<Float>(0.6, 1.2, 0.6))
        newScene.addCube(faceMask: Scene.FaceMask.all(), color: SIMD3<Float>(0.725, 0.71, 0.68), transform: transform, inwardNormals: false, triangleMask: UInt32(LMRRTTriangleMaskGeometry))
        
        newScene.updateBuffer(device: context.device)
        
        var camera = LMRRTCamera()
        camera.position = SIMD3<Float>(0, 1, 3.38)
        camera.forward = SIMD3<Float>(0, 0, -1)
        camera.right = SIMD3<Float>(1, 0, 0)
        camera.up = SIMD3<Float>(0, 1, 0)
        newScene.camera = camera
        
        var light = LMRRTAreaLight()
        light.position = SIMD3<Float>(0, 1.98, 0)
        light.forward = SIMD3<Float>(0, -1, 0)
        light.right = SIMD3<Float>(0.25, 0, 0)
        light.up = SIMD3<Float>(0, 0, 0.25)
        light.color = SIMD3<Float>(4.0, 4.0, 4.0)
        newScene.light = light
        
        scene = newScene
    }
    
    private func createRayIntersector() {
        if rayIntersector != nil {
            return
        }
        guard let scene = scene else {
            return
        }
        
        let newRayIntersector = RayIntersector(device: self.context.device)
        newRayIntersector.accelerationStructure.vertexBuffer = scene.positionBuffer
        newRayIntersector.accelerationStructure.maskBuffer = scene.maskBuffer
        newRayIntersector.accelerationStructure.triangleCount = scene.triangleCount
        newRayIntersector.accelerationStructure.rebuild()
        
        rayIntersector = newRayIntersector
    }
    
    private func createPipeline() throws {
        if self.rayPipeline != nil {
            return
        }
        
        let computeDescriptor = MTLComputePipelineDescriptor()
        computeDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
        
        computeDescriptor.computeFunction = self.context.generateFunction(name: "LMRRT::rayKernel")
        rayPipeline = try self.context.device.makeComputePipelineState(descriptor: computeDescriptor, options: MTLPipelineOption(), reflection: nil)
        
        computeDescriptor.computeFunction = self.context.generateFunction(name: "LMRRT::shadeKernel")
        shadePipeline = try self.context.device.makeComputePipelineState(descriptor: computeDescriptor, options: MTLPipelineOption(), reflection: nil)
        
        computeDescriptor.computeFunction = self.context.generateFunction(name: "LMRRT::shadowKernel")
        shadowPipeline = try self.context.device.makeComputePipelineState(descriptor: computeDescriptor, options: MTLPipelineOption(), reflection: nil)
        
        computeDescriptor.computeFunction = self.context.generateFunction(name: "LMRRT::accumulateKernel")
        accumulatePipeline = try self.context.device.makeComputePipelineState(descriptor: computeDescriptor, options: MTLPipelineOption(), reflection: nil)
        
    }
    
    private func updateSize(size: CGSize) throws {
        if size == self.size {
            return
        }
        self.size = size
        if size.width == 0 || size.height == 0 {
            return
        }
        
        let rayCount = Int(size.width) * Int(size.height)
        self.rayIntersector?.updateRayCount(rayCount)
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .rgba32Float
        textureDescriptor.textureType = .type2D
        textureDescriptor.width = Int(size.width)
        textureDescriptor.height = Int(size.height)
        textureDescriptor.storageMode = .private
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        
        self.renderTargets.removeAll()
        self.accumulationTargets.removeAll()
        for _ in 0 ... 1 {
            if let texture = self.context.device.makeTexture(descriptor: textureDescriptor) {
                self.renderTargets.append(texture)
            } else {
                throw LMRError("make texture error")
            }
            if let texture = self.context.device.makeTexture(descriptor: textureDescriptor) {
                self.accumulationTargets.append(texture)
            } else {
                throw LMRError("make texture error")
            }
        }
        
        textureDescriptor.pixelFormat = .r32Uint
        textureDescriptor.usage = .shaderRead
        textureDescriptor.storageMode = .shared
        
        if let texture = self.context.device.makeTexture(descriptor: textureDescriptor) {
            randomTexture = texture
        } else {
            throw LMRError("make texture error")
        }
        
        var randValues = [UInt32]()
        
        for _ in 0 ..< rayCount {
            let value = arc4random() % (1024 * 1024)
            randValues.append(value)
        }
        
        randomTexture?.replace(region: MTLRegionMake2D(0, 0, Int(size.width), Int(size.height)), mipmapLevel: 0, withBytes: &randValues, bytesPerRow: Int(size.width) * MemoryLayout<UInt32>.stride)
        
        frameIndex = 0
    }
    
    private func getUniforms(camera: LMRRTCamera, light: LMRRTAreaLight) -> LMRRTUniforms {
        var uniform = LMRRTUniforms()
        uniform.camera = camera
        uniform.light = light
        uniform.width = UInt32(self.size.width)
        uniform.height = UInt32(self.size.height)
        uniform.frameIndex = UInt32(frameIndex)
        frameIndex += 1

        let field = 45.0 * Float.pi / 180
        let aspect = Float(self.size.width) / Float(self.size.height)
        let imagePlaneHeight = tanf(field / 2.0)
        let imagePlaneWidth = aspect * imagePlaneHeight
        
        uniform.camera.right *= imagePlaneWidth
        uniform.camera.up *= imagePlaneHeight
        
        return uniform
    }
    
    var renderLock: NSLock = NSLock()
    
    func render(to mtkView: MTKView) throws {
        renderLock.lock()
        try self.updateSize(size: mtkView.drawableSize)
        
        guard let scene = self.scene else { return }
        guard let rayIntersector = self.rayIntersector else { return }
        
        var uniform = self.getUniforms(camera: scene.camera, light: scene.light)
        
        
        guard let commandBuffer = self.context.commandQueue.makeCommandBuffer() else { return }
        
        do {
            guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
            self.renderRay(encoder: computeEncoder, uniforms: &uniform)
            computeEncoder.endEncoding()
        }

        for bounce in 0 ..< 3 {
            rayIntersector.rtShade(commandBuffer: commandBuffer)

            do {
                guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
                self.renderShade(encoder: computeEncoder, uniforms: &uniform, bounce: bounce)
                computeEncoder.endEncoding()
            }
            
            rayIntersector.rtShadow(commandBuffer: commandBuffer)
            do {
                guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
                self.renderShadow(encoder: computeEncoder, uniforms: &uniform, bounce: bounce)
                computeEncoder.endEncoding()
                swapRenderTarget(targets: &renderTargets)
            }
        }
        
        do {
            guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
            self.renderAccumulate(encoder: computeEncoder, uniforms: &uniform)
            computeEncoder.endEncoding()
            swapRenderTarget(targets: &accumulationTargets)
        }
        
        do {
            guard let renderPassDescriptor = mtkView.currentRenderPassDescriptor else { return }
            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
            try self.renderCopy(encoder: renderEncoder, mtkView: mtkView)
            renderEncoder.endEncoding()
        }
        
        if let drawable = mtkView.currentDrawable {
            commandBuffer.present(drawable)
        }
        
        commandBuffer.commit()
        renderLock.unlock()
        
    }
    
    private func swapRenderTarget(targets: inout [MTLTexture]) {
        if targets.count == 2 {
            let tmp = targets[0]
            targets[0] = targets[1]
            targets[1] = tmp
        }
    }
    
    private var threadsPerThreadGroup: MTLSize {
        return MTLSizeMake(8, 8, 1)
    }
    
    private var threadGroups: MTLSize {
        let w = Int(self.size.width)
        let h = Int(self.size.height)
        let perGroup = threadsPerThreadGroup
        return MTLSize(width: (w + perGroup.width - 1) / perGroup.width, height: (h + perGroup.height - 1) / perGroup.height, depth: 1)
    }
    
    private func renderRay(encoder: MTLComputeCommandEncoder, uniforms: inout LMRRTUniforms) {
        guard let rayPipeline else { return }
        
        encoder.setComputePipelineState(rayPipeline)
        
        encoder.setBytes(&uniforms, length: MemoryLayout<LMRRTUniforms>.stride, index: 0)
        encoder.setBuffer(rayIntersector?.rayBuffer, offset: 0, index: 1)
        
        encoder.setTexture(randomTexture, index: 0)
        encoder.setTexture(renderTargets[0], index: 1)
        
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadsPerThreadGroup)
    }
    
    private func renderShade(encoder: MTLComputeCommandEncoder, uniforms: inout LMRRTUniforms, bounce: Int) {
        guard let shadePipeline else { return }
        encoder.setComputePipelineState(shadePipeline)
        
        encoder.setBytes(&uniforms, length: MemoryLayout<LMRRTUniforms>.stride, index: 0)
        encoder.setBuffer(rayIntersector?.rayBuffer, offset: 0, index: 1)
        encoder.setBuffer(rayIntersector?.shadowBuffer, offset: 0, index: 2)
        encoder.setBuffer(rayIntersector?.intersectionBuffer, offset: 0, index: 3)
        encoder.setBuffer(scene?.colorBuffer, offset: 0, index: 4)
        encoder.setBuffer(scene?.normalBuffer, offset: 0, index: 5)
        encoder.setBuffer(scene?.maskBuffer, offset: 0, index: 6)
        var index = bounce
        encoder.setBytes(&index, length: MemoryLayout<Int>.stride, index: 7)
        
        encoder.setTexture(randomTexture, index: 0)
        encoder.setTexture(renderTargets[0], index: 1)
        
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadsPerThreadGroup)
    }
    
    private func renderShadow(encoder: MTLComputeCommandEncoder, uniforms: inout LMRRTUniforms, bounce: Int) {
        guard let shadowPipeline else { return }
        encoder.setComputePipelineState(shadowPipeline)
        
        encoder.setBytes(&uniforms, length: MemoryLayout<LMRRTUniforms>.stride, index: 0)
        encoder.setBuffer(rayIntersector?.shadowBuffer, offset: 0, index: 1)
        encoder.setBuffer(rayIntersector?.intersectionBuffer, offset: 0, index: 2)
        
        encoder.setTexture(renderTargets[0], index: 0)
        encoder.setTexture(renderTargets[1], index: 1)
        
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadsPerThreadGroup)
    }
    
    private func renderAccumulate(encoder: MTLComputeCommandEncoder, uniforms: inout LMRRTUniforms) {
        guard let accumulatePipeline else { return }
        encoder.setComputePipelineState(accumulatePipeline)
        
        encoder.setBytes(&uniforms, length: MemoryLayout<LMRRTUniforms>.stride, index: 0)
        
        encoder.setTexture(renderTargets[0], index: 0)
        encoder.setTexture(accumulationTargets[0], index: 1)
        encoder.setTexture(accumulationTargets[1], index: 2)
        
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadsPerThreadGroup)
    }
    
    private func renderCopy(encoder: MTLRenderCommandEncoder, mtkView: MTKView) throws {
        let renderDescriptor = self.context.generatePipelineDescriptor(vertexFunc: "LMRRT::copyVertex", fragmentFunc: "LMRRT::copyFragment")
        renderDescriptor.sampleCount = mtkView.sampleCount
        renderDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        
        let pipeline = try self.context.generateRenderPipelineState(descriptor: renderDescriptor)
        
        encoder.setRenderPipelineState(pipeline)
        
        encoder.setFragmentTexture(accumulationTargets[0], index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}


extension LMRRayTracingRenderer {
    private class Scene {
        private var vertices: [SIMD3<Float>] = [SIMD3<Float>]()
        private var normals: [SIMD3<Float>] = [SIMD3<Float>]()
        private var colors: [SIMD3<Float>] = [SIMD3<Float>]()
        private var masks: [UInt32] = [UInt32]()
        
        private(set) var positionBuffer: MTLBuffer?
        private(set) var colorBuffer: MTLBuffer?
        private(set) var normalBuffer: MTLBuffer?
        private(set) var maskBuffer: MTLBuffer?
        
        var triangleCount : Int {
            return vertices.count / 3
        }
        
        var camera: LMRRTCamera = LMRRTCamera()
        var light: LMRRTAreaLight = LMRRTAreaLight()
        
        enum FaceMask: Int {
            case left = 1
            case right
            case bottom
            case top
            case back
            case front
            static func all() -> [FaceMask] {
                return [.left, .right, .bottom, .top, .back, .front]
            }
        }
        
        func updateBuffer(device: MTLDevice) {
            positionBuffer = device.makeBuffer(bytes: &vertices, length: MemoryLayout<SIMD3<Float>>.stride * vertices.count)
            normalBuffer = device.makeBuffer(bytes: &normals, length: MemoryLayout<SIMD3<Float>>.stride * normals.count)
            colorBuffer = device.makeBuffer(bytes: &colors, length: MemoryLayout<SIMD3<Float>>.stride * colors.count)
            maskBuffer = device.makeBuffer(bytes: &masks, length: MemoryLayout<UInt32>.stride * masks.count)
        }
        
        func addCube(faceMask: [FaceMask], color: SIMD3<Float>, transform: float4x4, inwardNormals: Bool, triangleMask: UInt32) {
            var cube = [SIMD3<Float>]()
            for p in defaultCube {
                let tp = transform * SIMD4<Float>(p, 1)
                cube.append(tp.xyz)
            }
            
            for fm in faceMask {
                addCubeFace(faceVertices: getFaceVertices(faceMask: fm, cube: cube), color: color, inwardNormals: inwardNormals, triangleMask: triangleMask)
            }
        }
        
        private func getFaceVertices(faceMask: FaceMask, cube: [SIMD3<Float>]) -> [SIMD3<Float>] {
            var indexs = [Int]()
            switch faceMask {
            case .left:
                indexs = [0, 4, 6, 2]
            case .right:
                indexs = [1, 3, 7, 5]
            case .bottom:
                indexs = [0, 1, 5, 4]
            case .top:
                indexs = [2, 6, 7, 3]
            case .back:
                indexs = [0, 2, 3, 1]
            case .front:
                indexs = [4, 5, 7, 6]
            }
            
            var result = [SIMD3<Float>]()
            
            for i in indexs {
                result.append(cube[i])
            }
            return result
        }
        
        private let defaultCube = [
            SIMD3<Float>(-0.5, -0.5, -0.5),
            SIMD3<Float>(0.5, -0.5, -0.5),
            SIMD3<Float>(-0.5, 0.5, -0.5),
            SIMD3<Float>(0.5, 0.5, -0.5),
            SIMD3<Float>(-0.5, -0.5, 0.5),
            SIMD3<Float>(0.5, -0.5, 0.5),
            SIMD3<Float>(-0.5, 0.5, 0.5),
            SIMD3<Float>(0.5, 0.5, 0.5)
        ]
        
        private func addCubeFace(faceVertices: [SIMD3<Float>], color: SIMD3<Float>, inwardNormals: Bool, triangleMask: UInt32) {
            let v0 = faceVertices[0]
            let v1 = faceVertices[1]
            let v2 = faceVertices[2]
            let v3 = faceVertices[3]
            
            let n0 = getTriangleNormal(v0: v0, v1: v1, v2: v2) * (inwardNormals ? -1 : 1)
            let n1 = getTriangleNormal(v0: v0, v1: v2, v2: v3) * (inwardNormals ? -1 : 1)
            
            vertices.append(contentsOf: [v0, v1, v2, v0, v2, v3])
            normals.append(contentsOf: [n0, n0, n0, n1, n1, n1])
            colors.append(contentsOf: [color, color, color, color, color, color])
            masks.append(contentsOf: [triangleMask, triangleMask])
        }
        
        private func getTriangleNormal(v0: SIMD3<Float>, v1: SIMD3<Float>, v2: SIMD3<Float>) -> SIMD3<Float> {
            let e1 = simd_normalize(v1 - v0)
            let e2 = simd_normalize(v2 - v0)
            
            return simd_cross(e1, e2)
        }
    }
}

extension LMRRayTracingRenderer {
    private class RayIntersector {
        private var device: MTLDevice
        private(set) var intersector: MPSRayIntersector
        private(set) var accelerationStructure: MPSTriangleAccelerationStructure
        
        private(set) var rayBuffer: MTLBuffer?
        private(set) var shadowBuffer: MTLBuffer?
        private(set) var intersectionBuffer: MTLBuffer?
        
        private var rayCount: Int = 0
        
        var rayStride: Int {
            get {
                return MemoryLayout<MPSRayOriginMaskDirectionMaxDistance>.stride + MemoryLayout<SIMD3<Float>>.stride
            }
        }
        
        var intersectionStride: Int {
            get {
                return MemoryLayout<MPSIntersectionDistancePrimitiveIndexCoordinates>.stride
            }
        }
        
        init(device: MTLDevice) {
            self.device = device
            self.intersector = MPSRayIntersector(device: device)
            self.accelerationStructure = MPSTriangleAccelerationStructure(device: device)
            
            self.intersector.rayDataType = .originMaskDirectionMaxDistance
            self.intersector.rayStride = self.rayStride
            self.intersector.rayMaskOptions = .primitive
        }
        
        func updateRayCount(_ count: Int) {
            if rayCount == count {
                return
            }
            rayCount = count
            
            if count == 0 {
                rayBuffer = nil
                shadowBuffer = nil
                intersectionBuffer = nil
            } else {
                rayBuffer = device.makeBuffer(length: rayStride * count, options: .storageModeShared)
                shadowBuffer = device.makeBuffer(length: rayStride * count, options: .storageModeShared)
                intersectionBuffer = device.makeBuffer(length: intersectionStride * count, options: .storageModeShared)
            }
        }
        
        func rtShade(commandBuffer: MTLCommandBuffer) {
            guard let rayBuffer = rayBuffer else { return }
            guard let intersectionBuffer = intersectionBuffer else { return }
            intersector.intersectionDataType = .distancePrimitiveIndexCoordinates
            intersector.encodeIntersection(commandBuffer: commandBuffer, intersectionType: .nearest, rayBuffer: rayBuffer, rayBufferOffset: 0, intersectionBuffer: intersectionBuffer, intersectionBufferOffset: 0, rayCount: rayCount, accelerationStructure: accelerationStructure)
        }
        
        func rtShadow(commandBuffer: MTLCommandBuffer) {
            guard let shadowBuffer = shadowBuffer else { return }
            guard let intersectionBuffer = intersectionBuffer else { return }
            intersector.intersectionDataType = .distance
            intersector.encodeIntersection(commandBuffer: commandBuffer, intersectionType: .any, rayBuffer: shadowBuffer, rayBufferOffset: 0, intersectionBuffer: intersectionBuffer, intersectionBufferOffset: 0, rayCount: rayCount, accelerationStructure: accelerationStructure)
        }
        
    }
}
