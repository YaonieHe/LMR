//  Created on 2022/7/19.

import UIKit

import MetalKit
import simd

class LMRTileForwardPlusVC: UIViewController, MTKViewDelegate {
    var mtkView: MTKView {view as! MTKView}
    var renderer: LMRTileForwardPlusRenderer = LMRTileForwardPlusRenderer()
    
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
        mtkView.sampleCount = 4
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        mtkView.depthStencilPixelFormat = .depth32Float
        mtkView.delegate = self
    }
    
    func draw(in view: MTKView) {
        do {
            try self.renderer.render(to: view)
        } catch {
            
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
}
