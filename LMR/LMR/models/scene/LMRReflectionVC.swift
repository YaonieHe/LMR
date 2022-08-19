//  Created on 2022/8/16.

import UIKit

import MetalKit
import simd

class LMRReflectionVC: UIViewController, MTKViewDelegate {
    var mtkView: MTKView {view as! MTKView}
    var renderer: LMRReflectionRenderer = LMRReflectionRenderer()
    
    override func loadView() {
        super.loadView()
        if view is MTKView {
            return
        }
        view = MTKView(frame: view.frame)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mtkView.device = self.renderer.context.device
        mtkView.sampleCount = 1
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        mtkView.depthStencilPixelFormat = .depth32Float
        mtkView.delegate = self
    }
    
    func draw(in view: MTKView) {
        do {
            try self.renderer.render(to: view)
        } catch {
           assert(false)
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }

}
