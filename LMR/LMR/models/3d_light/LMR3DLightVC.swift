//  Created on 2022/6/22.

import UIKit

import MetalKit
import simd


struct LMR3DLightError: Error {
    var description: String
}

struct LMR3DLightVertexParam {
    var projectM: float4x4
    var viewM: float4x4
    var modelM: float4x4
    var frag_normalM: float3x3
};

class LMR3DLightVC: UIViewController, MTKViewDelegate {

    var mtkView: MTKView {view as! MTKView}
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var library: MTLLibrary!
    
    var depthStencilState: MTLDepthStencilState!
    var renderPipeLineState: MTLRenderPipelineState!
    var lightRenderPipeLineState: MTLRenderPipelineState!
    
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
        
        do {
            renderPipeLineState = try getRenderPipeLineState(fragFunc: "lmr_3dlight::fragment_main")
            lightRenderPipeLineState = try getRenderPipeLineState(fragFunc: "lmr_3dlight::f_light")
            depthStencilState = getDepthStencilState()
        } catch {
            return
        }
        
    }
    
    func getRenderPipeLineState(fragFunc: String) throws -> MTLRenderPipelineState {
        let vertexFunc = library.makeFunction(name: "lmr_3dlight::vertex_main")
        let fragFunc = library.makeFunction(name: fragFunc)
       
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
    
   func getDepthStencilState() -> MTLDepthStencilState {
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
    
    struct Light {
        var ambient: Float
        var specular: Float
        var color: SIMD3<Float>
        var position: SIMD3<Float>
    };
    
    struct Material {
        var color: SIMD3<Float>
        var shininess: Float
    };
    
    
   func _render(in encoder: MTLRenderCommandEncoder) throws {
       var view_pos = SIMD3<Float>(0, 2, 20)
       let viewM = float4x4(translationBy: -view_pos)
       
       let field = radians_from_degrees(65)
       
       let nearZ: Float = 0.1
       let farZ: Float = 100
       let w = Float(view.bounds.size.width)
       let h = Float(view.bounds.size.height)
       let aspect = w / h
       let projectM = float4x4(perspectiveRightHandWithFovy: field, aspectRatio: aspect, nearZ: nearZ, farZ: farZ)
       
       
       let lightPosition = SIMD3<Float>(-10 * sin(2.23 * r), 1, -10 * cos(3.12 * r))
       var light = Light(ambient: 0.1, specular: 0.5, color: SIMD3<Float>(1, 1, 1), position: lightPosition)
       let lightMesh = LMDMesh.lmr_box()
       
       let lightModelM = float4x4(translationBy: lightPosition)
       
       do { // draw light
           encoder.setRenderPipelineState(lightRenderPipeLineState)
           encoder.setDepthStencilState(depthStencilState)
           let normalM = float3x3(lightModelM.inverse.transpose)
           var param = LMR3DLightVertexParam(projectM: projectM, viewM: viewM, modelM: lightModelM, frag_normalM: normalM)
           encoder.setVertexBytes(&param, length: MemoryLayout<LMR3DLightVertexParam>.stride, index: 1)
           encoder.setFragmentBytes(&light, length: MemoryLayout<Light>.stride, index: 2)
           
           let vertexBuffer = device.makeBuffer(bytes: lightMesh.vertexArray, length: MemoryLayout<LMDVertex>.stride * lightMesh.vertexCount)
           encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
           
           for submesh in lightMesh.submeshes {
               let indexBuffer = device.makeBuffer(bytes: submesh.indexArray, length: MemoryLayout<Int>.stride * submesh.indexCount)!
               encoder.setTriangleFillMode(.fill)
               encoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0)
           }
       }
       
       let box = LMDMesh.lmr_box(color: SIMD4<Float>(1, 1, 1, 1), size: 3)
       r += 0.01
       let modelM = float4x4(rotationAroundAxis: SIMD3<Float>(0, 1, 0), by: r)
       
       do {
           encoder.setRenderPipelineState(renderPipeLineState)
           encoder.setDepthStencilState(depthStencilState)
           let normalM = float3x3(modelM.inverse.transpose)
           var param = LMR3DLightVertexParam(projectM: projectM, viewM: viewM, modelM: modelM, frag_normalM: normalM)
           encoder.setVertexBytes(&param, length: MemoryLayout<LMR3DLightVertexParam>.stride, index: 1)
           encoder.setFragmentBytes(&light, length: MemoryLayout<Light>.stride, index: 2)
           encoder.setFragmentBytes(&view_pos, length: MemoryLayout<SIMD3<Float>>.stride, index: 3)
           
           let vertexBuffer = device.makeBuffer(bytes: box.vertexArray, length: MemoryLayout<LMDVertex>.stride * box.vertexCount)
           encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
           
           
           for submesh in box.submeshes {
               var material = Material(color: submesh.material.kd_color.xyz, shininess: submesh.material.shininess)
               encoder.setFragmentBytes(&material, length: MemoryLayout<Material>.stride, index: 3)
               encoder.setFragmentBytes(&view_pos, length: MemoryLayout<SIMD3<Float>>.stride, index: 4)
               let indexBuffer = device.makeBuffer(bytes: submesh.indexArray, length: MemoryLayout<Int>.stride * submesh.indexCount)!
               encoder.setTriangleFillMode(.fill)
               encoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0)
           }
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
