//  Created on 2022/7/6.

import Foundation
import Metal

extension MTLDepthStencilDescriptor {
    static func lmr_init(compare: MTLCompareFunction = .less, write: Bool = true) -> MTLDepthStencilDescriptor  {
        let depthStateDescriptor = MTLDepthStencilDescriptor()
        depthStateDescriptor.depthCompareFunction = compare
        depthStateDescriptor.isDepthWriteEnabled = write
        return depthStateDescriptor
    }
}
