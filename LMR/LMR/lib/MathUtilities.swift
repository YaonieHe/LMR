
import Foundation
import simd

extension SIMD4 where Scalar == Float {
    init(_ v: SIMD3<Float>, _ w: Float) {
        self.init(x: v.x, y: v.y, z: v.z, w: w)
    }
    
    // RGB color from HSV color (all parameters in range [0, 1])
    init(hue: Float, saturation: Float, brightness: Float) {
        let c = brightness * saturation
        let x = c * (1 - fabsf(fmodf(hue * 6, 2) - 1))
        let m = brightness - saturation
        
        var r: Float = 0
        var g: Float = 0
        var b: Float = 0
        switch hue {
        case _ where hue < 0.16667:
            r = c; g = x; b = 0
        case _ where hue < 0.33333:
            r = x; g = c; b = 0
        case _ where hue < 0.5:
            r = 0; g = c; b = x
        case _ where hue < 0.66667:
            r = 0; g = x; b = c
        case _ where hue < 0.83333:
            r = x; g = 0; b = c
        case _ where hue <= 1.0:
            r = c; g = 0; b = x
        default:
            break
        }
        
        r += m; g += m; b += m
        self.init(x: r, y: g, z: b, w: 1)
    }
    
    var xyz: SIMD3<Float> {
        return SIMD3<Float>(x, y, z)
    }
}

extension float4x4 {
    init(rotationAroundAxis axis: SIMD3<Float>, by angle: Float) {
        let unitAxis = normalize(axis)
        let ct = cosf(angle)
        let st = sinf(angle)
        let ci = 1 - ct
        let x = unitAxis.x, y = unitAxis.y, z = unitAxis.z
        self.init(columns:(SIMD4<Float>(    ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
                           SIMD4<Float>(x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0),
                           SIMD4<Float>(x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0),
                           SIMD4<Float>(                  0,                   0,                   0, 1)))
    }
    
    init(translationBy v: SIMD3<Float>) {
        self.init(columns:(SIMD4<Float>(1, 0, 0, 0),
                           SIMD4<Float>(0, 1, 0, 0),
                           SIMD4<Float>(0, 0, 1, 0),
                           SIMD4<Float>(v.x, v.y, v.z, 1)))
    }
    
    init(scale s: SIMD3<Float>) {
        self.init(columns:(SIMD4<Float>(s.x, 0, 0, 0),
                           SIMD4<Float>(0, s.y, 0, 0),
                           SIMD4<Float>(0, 0, s.z, 0),
                           SIMD4<Float>(0, 0, 0, 1)))
    }
    
    init(perspectiveLeftHandWithFovy fovy: Float, aspectRatio: Float, nearZ: Float, farZ: Float) {
        let ys = 1 / tanf(fovy * 0.5)
        let xs = ys / aspectRatio
        let zs = farZ / (farZ - nearZ)
        self.init(columns:(SIMD4<Float>(xs,  0, 0,   0),
                           SIMD4<Float>( 0, ys, 0,   0),
                           SIMD4<Float>( 0,  0, zs, 1),
                           SIMD4<Float>( 0,  0, -nearZ * zs, 0)))
    }
    
    init(perspectiveRightHandWithFovy fovy: Float, aspectRatio: Float, nearZ: Float, farZ: Float) {
        let ys = 1 / tanf(fovy * 0.5)
        let xs = ys / aspectRatio
        let zs = farZ / (nearZ - farZ)
        self.init(columns:(SIMD4<Float>(xs,  0, 0,   0),
                           SIMD4<Float>( 0, ys, 0,   0),
                           SIMD4<Float>( 0,  0, zs, -1),
                           SIMD4<Float>( 0,  0, nearZ * zs, 0)))
    }
    
    static func lookAtLeftHand(eye: SIMD3<Float>, center: SIMD3<Float>, up: SIMD3<Float>) -> float4x4 {
        let z = normalize(center - eye);
        let x = normalize(cross(up, z));
        let y = cross(z, x);

        let P = SIMD4<Float>(x.x, y.x, z.x, 0);
        let Q = SIMD4<Float>(x.y, y.y, z.y, 0);
        let R = SIMD4<Float>(x.z, y.z, z.z, 0);
        let S = SIMD4<Float>(-dot(x, eye), -dot(y, eye), -dot(z, eye), 1);

        return float4x4(P, Q, R, S);
    }
    
    static func lookAtRightHand(eye: SIMD3<Float>, center: SIMD3<Float>, up: SIMD3<Float>) -> float4x4 {
        let z = normalize(eye - center);
        let x = normalize(cross(up, z));
        let y = cross(z, x);

        let P = SIMD4<Float>(x.x, y.x, z.x, 0);
        let Q = SIMD4<Float>(x.y, y.y, z.y, 0);
        let R = SIMD4<Float>(x.z, y.z, z.z, 0);
        let S = SIMD4<Float>(-dot(x, eye), -dot(y, eye), -dot(z, eye), 1);

        return float4x4(P, Q, R, S);
   }
    
    static func look_at_cube(eye: SIMD3<Float>, face: Int) -> float4x4 {
        let directions: [SIMD3<Float>] = [
            SIMD3<Float>(-1,  0,  0), // Left
            SIMD3<Float>( 1,  0,  0), // Right
            SIMD3<Float>( 0,  1,  0), // Top
            SIMD3<Float>( 0, -1,  0), // Down
            SIMD3<Float>( 0,  0,  1), // Front
            SIMD3<Float>( 0,  0, -1)  // Back
        ]

        let ups: [SIMD3<Float>] = [
            SIMD3<Float>(0, 1,  0),
            SIMD3<Float>(0, 1,  0),
            SIMD3<Float>(0, 0, -1),
            SIMD3<Float>(0, 0,  1),
            SIMD3<Float>(0, 1,  0),
            SIMD3<Float>(0, 1,  0)
        ]

        return self.lookAtRightHand(eye: eye, center: eye+directions[face], up: ups[face])
    }
}

func radians_from_degrees(_ degrees: Float) -> Float {
    return (degrees / 180) * .pi
}

extension float3x3 {
    init(_ lmr4x4: float4x4) {
        self.init(lmr4x4[0].xyz, lmr4x4[1].xyz, lmr4x4[2].xyz)
    }
}
