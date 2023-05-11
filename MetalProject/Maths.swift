//
//  Maths.swift
//  MetalProject
//
//  Created by Sina Dashtebozorgy on 23/12/2022.
//




import Foundation
import simd

extension simd_float3 {
    init(vec4 : simd_float4){
        self.init(vec4.x,vec4.y,vec4.z)
    }
}

extension simd_float4 {
    init(vec3 : simd_float3){
        self.init(vec3.x,vec3.y,vec3.z,1)
    }
}

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
    init(bounds : simd_float3, near: Float, far: Float) {
        let left = Float(bounds.x)
        let right = Float(left + bounds.z)
        let bottom = Float(bounds.y)
        let top = Float(bottom + bounds.z)
        
            let sx = 2 / (right - left)
               let sy = 2 / (top - bottom)
               let sz = 1 / (near - far)
               let tx = (left + right) / (left - right)
               let ty = (top + bottom) / (bottom - top)
               let tz = near / (near - far)

        self.init(simd_float4(sx,0,0,0),
                  simd_float4(0,sy,0,0),
                  simd_float4(0,0,sz,0),
                  simd_float4(tx,ty,tz,1)
                  )
        

    }
    init(orthoWithLeft left : Float, right : Float, bottom : Float, top : Float, near: Float, far: Float) {
        
        let sx = 2 / (right - left)
        let sy = 2 / (top - bottom)
        let sz = 1 / (near - far)
        let tx = (left + right) / (left - right)
        let ty = (top + bottom) / (bottom - top)
        let tz = near / (near - far)
        
        self.init(simd_float4(sx,0,0,0),
                  simd_float4(0,sy,0,0),
                  simd_float4(0,0,sz,0),
                  simd_float4(tx,ty,tz,1)
        )
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

func create_modelMatrix(translation : simd_float3, rotation : simd_float3, scale : simd_float3) -> simd_float4x4 {
    let translateMat = simd_float4x4(translate: translation)
    let rotateMat = simd_float4x4(rotationXYZ: rotation)
    let scaleMat = simd_float4x4(scale: scale)
    
    return translateMat*rotateMat*scaleMat
}

func create_modelMatrix(rotation : simd_float3, translation : simd_float3, scale : simd_float3) -> simd_float4x4 {
    let translateMat = simd_float4x4(translate: translation)
    let rotateMat = simd_float4x4(rotationXYZ: rotation)
    let scaleMat = simd_float4x4(scale: scale)
    
    return rotateMat*translateMat*scaleMat
}

func create_modelViewMatrix(modelMatrix : simd_float4x4, viewMatrix : simd_float4x4) -> simd_float4x4 {
    return viewMatrix * modelMatrix
}



func create_normalMatrix(modelViewMatrix : simd_float4x4) -> simd_float4x4 {
    return (modelViewMatrix.inverse).transpose
}



