//
//  LMDSubmesh.swift
//  LMR
//
//  Created by hjp-Mic on 2022/6/26.
//

import UIKit

class LMDSubmesh {
    open var indexArray: [UInt32] = [UInt32]()
    open var indexCount: Int {
        return indexArray.count
    }
    open var material: LMDMaterial = LMDMaterial()
}
