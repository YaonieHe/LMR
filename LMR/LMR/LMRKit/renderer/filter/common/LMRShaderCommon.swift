import Metal

extension LMR3DObjParams {
    init(modelMatrix: float4x4, diffuseColor: SIMD4<Float>, specularColor: SIMD4<Float>, shininess: Float) {
        let normalMatrix = float3x3(modelMatrix.inverse.transpose)
        self.init(modelMatrix: modelMatrix, normalMatrix: normalMatrix, isDiffuseTexture: 0, diffuseColor: diffuseColor, specularColor: specularColor, shininess: shininess)
    }
}


class LMR3DPainter {
    var context: LMRContext
    var encoder: MTLRenderCommandEncoder
    var viewParam: LMR3DViewParams
    
    var sampleCount: Int = 1
    var pixelFormat: MTLPixelFormat = .rgba8Unorm_srgb
    var depthStencilPixelFormat: MTLPixelFormat = .depth32Float
    
    init(context: LMRContext, encoder: MTLRenderCommandEncoder, viewParam: LMR3DViewParams) throws {
        self.context = context
        self.encoder = encoder
        self.viewParam = viewParam
    }
}

extension LMR3DPainter {
    func normal_setRenderPipeline(_ vertexFuncName: String, _ fragmentFuncName: String) throws {
        let pipelineDescriptor = self.context.generatePipelineDescriptor(vertexFunc: vertexFuncName, fragmentFunc: fragmentFuncName)
        pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.lmr_pntDesc()
        pipelineDescriptor.sampleCount = self.sampleCount
        pipelineDescriptor.colorAttachments[0].pixelFormat = self.pixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = self.depthStencilPixelFormat
        
        let renderPipeLineState = try self.context.generateRenderPipelineState(descriptor: pipelineDescriptor)
        
        encoder.setRenderPipelineState(renderPipeLineState)
    }
    
    func normal_setDepthStencil() {
        let depthStencilState = context.generateDepthStencilState(descriptor: MTLDepthStencilDescriptor.lmr_init())
        encoder.setDepthStencilState(depthStencilState)
    }
}
