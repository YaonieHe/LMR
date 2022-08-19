//  Created on 2022/8/15.

import Foundation
import ModelIO

class LMRRFSphere {
    var center: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    var radius: Float = 0
    
    init() {
    }
    
    init(boundBox: MDLAxisAlignedBoundingBox) {
        center = (boundBox.maxBounds + boundBox.minBounds) * 0.5
        radius = length(boundBox.maxBounds - boundBox.minBounds) * 0.5
    }
}

class LMRRFObject: LMRObject {
    open var meshes: [LMRMesh] = [LMRMesh]()
    open var sphere: LMRRFSphere = LMRRFSphere()
    
//    open var rfInstances: [Int] = [Int]()
    
    open var floor: Bool = false
}

class LMRCameraProbe {
    var position: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    var near: Float = 0
    var far: Float = 0
    
    func getLeftViewMatrix(face: Int) -> float4x4 {
        return float4x4.left_look_at_cube(eye: position, face: face)
    }
    
    func getLeftProjectMatrix() -> float4x4 {
        return float4x4(perspectiveLeftHandWithFovy: Float.pi * 0.5, aspectRatio: 1, nearZ: near, farZ: far)
    }
}

class LMRFrustumCuller {
    var position: SIMD3<Float>
    
    var norm_near: SIMD3<Float>
    var norm_left: SIMD3<Float>
    var norm_right: SIMD3<Float>
    var norm_bottom: SIMD3<Float>
    var norm_top: SIMD3<Float>
    
    var near: Float
    var far: Float
    
    init(leftHandViewMatrix viewMatrix: float4x4, position: SIMD3<Float>, aspect: Float, halfVFov: Float, near: Float, far: Float) {
        self.position = position
        self.near = near
        self.far = far
        
        let halfHFov = halfVFov * aspect
        let cameraRotationMatrix = float3x3(viewMatrix)
        
        self.norm_near = cameraRotationMatrix * SIMD3<Float>(0, 0, 1)
        self.norm_left = cameraRotationMatrix * SIMD3<Float>(cosf(halfHFov), 0, sinf(halfHFov))
        self.norm_bottom = cameraRotationMatrix * SIMD3<Float>(0, cosf(halfVFov), sinf(halfVFov))
        self.norm_right = -self.norm_left + norm_near * dot(self.norm_near, self.norm_left) * 2
        self.norm_top = -self.norm_bottom + norm_near * dot(self.norm_near, self.norm_bottom) * 2
    }
    
    convenience init(camera: LMRCamera) {
        assert(camera.leftHand)
        
        self.init(leftHandViewMatrix: camera.viewMatrix, position: camera.position, aspect: camera.aspect, halfVFov: camera.field * 0.5, near: camera.nearZ, far: camera.farZ)
    }
    
    convenience init(viewmatrix: float4x4, camera: LMRCameraProbe) {
        self.init(leftHandViewMatrix: viewmatrix, position: camera.position, aspect: 1, halfVFov: Float.pi * 0.5, near: camera.near, far: camera.far)
    }
    
    func intersects(center: SIMD3<Float>, radius: Float) -> Bool {
        let pos = center - self.position
        if dot(pos + self.norm_near * (radius - near), norm_near) < 0 {
            return false
        }
        if dot(pos - self.norm_near * (radius + far), -norm_near) < 0 {
            return false
        }
        if dot(pos + norm_left * radius, norm_left) < 0 {
            return false
        }
        if dot(pos + norm_right * radius, norm_right) < 0 {
            return false
        }
        if dot(pos + norm_bottom * radius, norm_bottom) < 0 {
            return false
        }
        if dot(pos + norm_top * radius, norm_top) < 0 {
            return false
        }
        return  true
    }
    
    func intersects(sphere: LMRRFSphere) -> Bool {
        return self.intersects(center: sphere.center, radius: sphere.radius)
    }
    
}
