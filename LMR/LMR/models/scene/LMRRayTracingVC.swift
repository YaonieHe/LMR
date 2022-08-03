//  Created on 2022/7/27.

import UIKit

import MetalKit
import simd

class LMRRayTracingVC: UIViewController, MTKViewDelegate {
    var mtkView: MTKView = MTKView()
    var renderer: LMRRayTracingRenderer = LMRRayTracingRenderer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mtkView.frame = CGRect(x: 0, y: 0, width: 400, height: 400)
        view.addSubview(mtkView)
        
        mtkView.device = self.renderer.context.device
        mtkView.sampleCount = 4
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        mtkView.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mtkView.center = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
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
