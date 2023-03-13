//
//  Maths.swift
//  MetalProject
//
//  Created by Sina Dashtebozorgy on 23/12/2022.
//




import Foundation
import simd

extension simd_float4x4{
    init(scale : simd_float3){
        self.init(simd_float4(scale.x,0,0,0),
                  simd_float4(0,scale.y,0,0),
                  simd_float4(0,0,scale.z,0),
                  simd_float4(0,0,0,1)
        )
    }
    init(translate : simd_float3){
        self.init(simd_float4(1,0,0,0),
                  simd_float4(0,1,0,0),
                  simd_float4(0,0,1,0),
                  simd_float4(translate.x,translate.y,translate.z,1)
        )
    }
    init(fovRadians: Float,aspectRatio: Float,near: Float,far: Float){
        let sy = 1 / tan(fovRadians * 0.5)
        let sx = sy / aspectRatio
        let zRange = far - near
        let sz = -(far + near) / zRange
        let tz = -2 * far * near / zRange
        self.init(simd_float4(sx, 0,  0,  0),
                  simd_float4(0, sy,  0,  0),
                  simd_float4(0,  0, sz, -1),
                  simd_float4(0,  0, tz,  0))
    }
    init(orthographic rect: CGRect, near: Float, far: Float) {
        let left = Float(rect.origin.x)
        let right = Float(rect.origin.x + rect.width)
        let top = Float(rect.origin.y)
        let bottom = Float(rect.origin.y - rect.height)
        let X = simd_float4(2 / (right - left), 0, 0, 0)
        let Y = simd_float4(0, 2 / (top - bottom), 0, 0)
        let Z = simd_float4(0, 0, 1 / (far - near), 0)
        let W = simd_float4(
            (left + right) / (left - right),
            (top + bottom) / (bottom - top),
            near / (near - far),
            1)
        self.init(X,Y,Z,W)
    }
    
    init(eye: simd_float3, center: simd_float3, up: simd_float3) {
        let z = normalize(eye - center)
        let x = normalize(cross(up, z))
        let y = cross(z, x)

        let X = simd_float4(x.x, y.x, z.x, 0)
        let Y = simd_float4(x.y, y.y, z.y, 0)
        let Z = simd_float4(x.z, y.z, z.z, 0)
        let W = simd_float4(-dot(x, eye), -dot(y, eye), -dot(z, eye), 1)

        self.init(X, Y, Z, W)
      }
    
    init(rotationY angle : Float){
        
        let theta = (angle/180)*3.14
        self.init(simd_float4(cosf(theta),0,-sinf(theta),0), simd_float4(0,1,0,0), simd_float4(sinf(theta),0,cosf(theta),0), simd_float4(0,0,0,1))
    }
    
    init(rotationX angle : Float){
        
        let theta = (angle/180)*3.14
        self.init(simd_float4(1,0,0,0), simd_float4(0,cosf(theta),sinf(theta),0), simd_float4(0,-sinf(theta),cosf(theta),0),simd_float4(0,0,0,1))
        
    }
    
    init(rotationZ angle : Float){
        let theta = (angle/180)*3.14
        self.init(simd_float4(cos(theta), sin(theta), 0, 0),simd_float4(-sin(theta), cos(theta), 0, 0),simd_float4(0,0, 1, 0),simd_float4(0,0, 0, 1))
    }
                  
    init(rotationXYZ angle : simd_float3){
        let rotx = float4x4(rotationX: angle.x)
        let roty = float4x4(rotationY: angle.y)
        let rotz = float4x4(rotationZ: angle.z)
        let result = rotx * roty * rotz
        self.init(result)
    }
                  
      
}





//func rot_y(angle : Float) -> simd_float4x4 {
//    let theta = (angle/180)*3.14
//    let result = simd_float4x4(simd_float4(cosf(theta),0,-sinf(theta),0), simd_float4(0,1,0,0), simd_float4(sinf(theta),0,cosf(theta),0), simd_float4(0,0,0,1))
//    return result
//}
//
//func rot_x(angle : Float) -> simd_float4x4 {
//    let theta = (angle/180)*3.14
//    let result = simd_float4x4(simd_float4(1,0,0,0), simd_float4(0,cosf(theta),sinf(theta),0), simd_float4(0,-sinf(theta),cosf(theta),0),simd_float4(0,0,0,1))
//    return result
//}
//
////func create_projection_matrix(fovRadians: Float,
////     aspectRatio: Float,
////     near: Float,
////     far: Float) -> simd_float4x4
////{
////    let sy = 1 / tan(fovRadians * 0.5)
////    let sx = sy / aspectRatio
////    let zRange = far - near
////    let sz = -(far + near) / zRange
////    let tz = -2 * far * near / zRange
////    let result = simd_float4x4(SIMD4<Float>(sx, 0,  0,  0),
////              SIMD4<Float>(0, sy,  0,  0),
////              SIMD4<Float>(0,  0, sz, -1),
////              SIMD4<Float>(0,  0, tz,  0))
////    return result
////}
//
////init(eye: float3, center: float3, up: float3) {
////    let z = normalize(center - eye)
////    let x = normalize(cross(up, z))
////    let y = cross(z, x)
////
////    let X = float4(x.x, y.x, z.x, 0)
////    let Y = float4(x.y, y.y, z.y, 0)
////    let Z = float4(x.z, y.z, z.z, 0)
////    let W = float4(-dot(x, eye), -dot(y, eye), -dot(z, eye), 1)
////
////    self.init()
////    columns = (X, Y, Z, W)
////  }
//
//  // MARK: - Orthographic matrix
////  init(orthographic rect: CGRect, near: Float, far: Float) {
////    let left = Float(rect.origin.x)
////    let right = Float(rect.origin.x + rect.width)
////    let top = Float(rect.origin.y)
////    let bottom = Float(rect.origin.y - rect.height)
////    let X = float4(2 / (right - left), 0, 0, 0)
////    let Y = float4(0, 2 / (top - bottom), 0, 0)
////    let Z = float4(0, 0, 1 / (far - near), 0)
////    let W = float4(
////      (left + right) / (left - right),
////      (top + bottom) / (bottom - top),
////      near / (near - far),
////      1)
////    self.init()
////    columns = (X, Y, Z, W)
////  }
//
//
//
//
//
//
//
