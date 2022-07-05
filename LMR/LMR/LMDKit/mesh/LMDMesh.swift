//
//  LMDMesh.swift
//  LMR
//
//  Created by hjp-Mic on 2022/6/26.
//

import UIKit

class LMDMesh {
    open var vertexArray: [LMDVertex] = [LMDVertex]()
    open var vertexCount: Int {
        return vertexArray.count
    }
    open var submeshes: [LMDSubmesh] = [LMDSubmesh]()
}
