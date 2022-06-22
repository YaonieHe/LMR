//  Created on 2022/6/22.

import UIKit

import MetalKit
import simd

class LMRSampleVC: UIViewController, MTKViewDelegate {
    var mtkView: MTKView {view as! MTKView}
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var library: MTLLibrary!
    
    override func loadView() {
        super.loadView()
        if view is MTKView {
            return
        }
        view = MTKView(frame: view.frame)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()
        library = device.makeDefaultLibrary()
        
        mtkView.device = device
        mtkView.sampleCount = 4
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        mtkView.delegate = self
    }
    
     func renderPipeLineState() throws -> MTLRenderPipelineState {
        let vertexFunc = library.makeFunction(name: "lmr_smaple::vertex_main")
        let fragFunc = library.makeFunction(name: "lmr_smaple::fragment_main")
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].offset = 0;
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride
         
        vertexDescriptor.attributes[1].offset = 0;
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].bufferIndex = 1
        vertexDescriptor.layouts[1].stride = MemoryLayout<SIMD2<Float>>.stride
         
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunc
        pipelineDescriptor.fragmentFunction = fragFunc
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.sampleCount = mtkView.sampleCount
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func _render(in encoder: MTLRenderCommandEncoder) throws {
        encoder.setRenderPipelineState(try renderPipeLineState())
        let p = [SIMD3<Float>(-0.5, -0.5, 0), SIMD3<Float>(0.5, 0.5, 0), SIMD3<Float>(-0.5, 0.5, 0), SIMD3<Float>(-0.5, -0.5, 0), SIMD3<Float>(0.5, 0.5, 0), SIMD3<Float>(0.5, -0.5, 0)]
        let t = [SIMD2<Float>(0, 0), SIMD2<Float>(1, 1), SIMD2<Float>(0, 1), SIMD2<Float>(0, 0), SIMD2<Float>(1, 1), SIMD2<Float>(1, 0)]
        encoder.setVertexBytes(p, length: MemoryLayout<SIMD3<Float>>.stride * 6, index: 0)
        encoder.setVertexBytes(t, length: MemoryLayout<SIMD2<Float>>.stride * 6, index: 1)
        encoder.setTriangleFillMode(.fill)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        
    }
    
    func draw(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {return}
        guard let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}
        do {
            try _render(in: renderCommandEncoder)
        } catch {
            return
        }
        renderCommandEncoder.endEncoding()
        
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
}
