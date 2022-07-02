//
//  LMRObject.swift
//  LMR
//
//  Created by hjp-Mic on 2022/7/2.
//

import UIKit

class LMRObject {
    open var mesh: LMRMesh?
    open var location: LMRLocation = LMRLocation()
    
    init() {
    }
    
    init(mesh: LMRMesh) {
        self.mesh = mesh
    }
}
