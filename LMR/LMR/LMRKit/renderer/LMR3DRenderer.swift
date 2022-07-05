//  Created on 2022/7/5.

import UIKit
import MetalKit

class LMR3DRenderer: LMRRenderer {
    open var scene: LMRScene?
    
    private func setupScene() {
        
    }
    
    open func render(to mtkView: MTKView) throws {
        guard let scene = self.scene else {
            return
        }
        
        
    }
}
