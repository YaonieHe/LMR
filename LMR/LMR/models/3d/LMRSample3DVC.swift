//  Created on 2022/6/22.

import UIKit

import MetalKit
import simd


struct LMRSample3DError: Error {
    var description: String
}

struct LMRSample3DVertexParam {
    var projectM: float4x4
    var viewM: float4x4
    var modelM: float4x4
};

class LMRSample3DVC: UIViewController, MTKViewDelegate {

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
        mtkView.depthStencilPixelFormat = .depth32Float
        mtkView.delegate = self
    }
    
    func renderPipeLineState() throws -> MTLRenderPipelineState {
        let vertexFunc = library.makeFunction(name: "lmr_smaple3d::vertex_main")
        let fragFunc = library.makeFunction(name: "lmr_smaple3d::fragment_main")
       
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].offset = 0;
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].bufferIndex = 0
        
       vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 3;
       vertexDescriptor.attributes[1].format = .float3
       vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.attributes[2].offset = MemoryLayout<Float>.size * 6;
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 8
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunc
        pipelineDescriptor.fragmentFunction = fragFunc
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.sampleCount = mtkView.sampleCount
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat

        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
   }
   
   func depthStencilState() -> MTLDepthStencilState {
       let depthStateDescriptor = MTLDepthStencilDescriptor()
       depthStateDescriptor.depthCompareFunction = .less
       depthStateDescriptor.isDepthWriteEnabled = true
       return device.makeDepthStencilState(descriptor: depthStateDescriptor)!
   }
   
    func getBox() throws -> MTKMesh {
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.vertexAttributes[0].name = MDLVertexAttributePosition
        vertexDescriptor.vertexAttributes[0].format = .float3
        vertexDescriptor.vertexAttributes[0].offset = 0
        vertexDescriptor.vertexAttributes[0].bufferIndex = 0
        vertexDescriptor.vertexAttributes[1].name = MDLVertexAttributeNormal
        vertexDescriptor.vertexAttributes[1].format = .float3
        vertexDescriptor.vertexAttributes[1].offset = MemoryLayout<Float>.size * 3
        vertexDescriptor.vertexAttributes[1].bufferIndex = 0
        vertexDescriptor.vertexAttributes[2].name = MDLVertexAttributeTextureCoordinate
        vertexDescriptor.vertexAttributes[2].format = .float2
        vertexDescriptor.vertexAttributes[2].offset = MemoryLayout<Float>.size * 6
        vertexDescriptor.vertexAttributes[2].bufferIndex = 0
        vertexDescriptor.bufferLayouts[0].stride = MemoryLayout<Float>.size * 8
        
        let meshAllocator = MTKMeshBufferAllocator(device: device)
        let mdlMesh = MDLMesh(boxWithExtent: SIMD3<Float>(1, 1, 1), segments: SIMD3<UInt32>(1, 1, 1), inwardNormals: false, geometryType: .triangles, allocator: meshAllocator)
        mdlMesh.vertexDescriptor = vertexDescriptor
        
        return try! MTKMesh(mesh: mdlMesh, device: device)
    }
    
   func _render(in encoder: MTLRenderCommandEncoder) throws {
       encoder.setRenderPipelineState(try renderPipeLineState())
       encoder.setDepthStencilState(depthStencilState())
       
       let box = try getBox()
       let modelM = float4x4(rotationAroundAxis: SIMD3<Float>(1, 1, 0), by: 0.2)
       let viewM = float4x4(translationBy: SIMD3<Float>(0, 0, -15))
       
       let field = radians_from_degrees(65)
       let nearZ: Float = 0.1
       let farZ: Float = 100
       let w = Float(view.bounds.size.width)
       let h = Float(view.bounds.size.height)
       let aspect = w / h
       let projectM = float4x4(perspectiveProjectionRHFovY: field, aspectRatio: aspect, nearZ: nearZ, farZ: farZ)
       
       var param = LMRSample3DVertexParam(projectM: projectM, viewM: viewM, modelM: modelM)
       encoder.setVertexBytes(&param, length: MemoryLayout<LMRSample3DVertexParam>.stride, index: 1)
       
       if let buffer = box.vertexBuffers.first {
           encoder.setVertexBuffer(buffer.buffer, offset: buffer.offset, index: 0)
       }
       for submesh in box.submeshes {
           encoder.setTriangleFillMode(.fill)
           encoder.drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
       }

       
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
