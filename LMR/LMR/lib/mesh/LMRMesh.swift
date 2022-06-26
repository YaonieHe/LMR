//
//  LMRMesh.swift
//  LMR
//
//  Created by hjp-Mic on 2022/6/26.
//

import UIKit

class LMRMesh {
    open var vertexArray: [LMRVertex] = [LMRVertex]()
    open var vertexCount: Int {
        return vertexArray.count
    }
    open var submeshes: [LMRSubmesh] = [LMRSubmesh]()
}
