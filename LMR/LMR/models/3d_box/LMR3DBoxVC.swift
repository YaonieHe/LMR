//  Created on 2022/6/22.

import UIKit

import MetalKit
import simd


struct LMR3DBoxError: Error {
    var description: String
}

struct LMR3DBoxVertexParam {
    var projectM: float4x4
    var viewM: float4x4
    var modelM: float4x4
};

class LMR3DBoxVC: UIViewController, MTKViewDelegate {

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
        let vertexFunc = library.makeFunction(name: "lmr_smaple3dbox::vertex_main")
        let fragFunc = library.makeFunction(name: "lmr_smaple3dbox::fragment_main")
       
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].offset = 0;
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].bufferIndex = 0
        
       vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride;
       vertexDescriptor.attributes[1].format = .float3
       vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.attributes[2].offset = MemoryLayout<SIMD3<Float>>.stride * 2;
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<LMDVertex>.stride
        
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
    
    func generateTexture(from imageName: String) throws -> MTLTexture {
        let path = Bundle.main.path(forResource: imageName, ofType: nil)!
//        let image = UIImage.init(contentsOfFile: path)!
        
        let loader = MTKTextureLoader(device: device)
        
        let texture = try loader.newTexture(URL: URL.init(fileURLWithPath: path))
        return texture
    }
    
    var r: Float = 0
    
   func _render(in encoder: MTLRenderCommandEncoder) throws {
       encoder.setRenderPipelineState(try renderPipeLineState())
       encoder.setDepthStencilState(depthStencilState())
       
       let box = LMDMesh .lmr_skyBox(mds: ["top.jpg", "bottom.jpg", "left.jpg", "right.jpg", "front.jpg", "back.jpg"], size: 10)
       
       r += 0.01
       
       let modelM = float4x4(rotationAroundAxis: SIMD3<Float>(0, 1, 0), by: r)
       let viewM = float4x4(translationBy: SIMD3<Float>(0, 0, 0))
       
       let field = radians_from_degrees(65)
   
       let nearZ: Float = 0.1
       let farZ: Float = 100
       let w = Float(view.bounds.size.width)
       let h = Float(view.bounds.size.height)
       let aspect = w / h
       let projectM = float4x4(perspectiveRightHandWithFovy: field, aspectRatio: aspect, nearZ: nearZ, farZ: farZ)
       
       var param = LMR3DBoxVertexParam(projectM: projectM, viewM: viewM, modelM: modelM)
       encoder.setVertexBytes(&param, length: MemoryLayout<LMRSample3DVertexParam>.stride, index: 1)
       
       let vertexBuffer = device.makeBuffer(bytes: box.vertexArray, length: MemoryLayout<LMDVertex>.stride * box.vertexCount)
       encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
       
       
       for submesh in box.submeshes {
           let texture = try self.generateTexture(from: submesh.material.map_kd!)
           encoder.setFragmentTexture(texture, index: 0)
           let indexBuffer = device.makeBuffer(bytes: submesh.indexArray, length: MemoryLayout<Int>.stride * submesh.indexCount)!
           encoder.setTriangleFillMode(.fill)
           encoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0)
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
