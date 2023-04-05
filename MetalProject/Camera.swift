//
//  Camera.swift
//  MetalProject
//
//  Created by Sina Dashtebozorgy on 22/03/2023.
//

import Foundation
import Metal
import MetalKit
import AppKit

class Camera {
    var scene : DefaultScene?
    var eye : simd_float3
    var centre : simd_float3
    var previous_x : Float?
    var previous_y : Float?
    var mouse_x : Float?
    var mouse_y : Float?
    var view : MTKView
    var width : Float
    var height : Float
    var totalChangeTheta : Float =  0
    var totalChangePhi : Float = 0
    var cameraMatrix : simd_float4x4
    var isOrtho = false
    
//    var across : simd_float3
//    var forward : simd_float3
    
    init(for view : MTKView, eye: simd_float3, centre: simd_float3) {
        self.view = view
        self.eye = eye
        self.centre = centre
        width = 3024/2
        height = 1726/2
      
        cameraMatrix = simd_float4x4(eye: eye, center: eye + centre, up: simd_float3(0,1,0))
       
    }
    
   
    
    func reset_mouse(){
        mouse_x = nil
        mouse_y = nil
    }
    
    func update_mouse(with position : simd_float2){
        if mouse_x == nil && mouse_y == nil {
            mouse_x = position.x
            mouse_y = position.y
            previous_x = position.x
            previous_y = position.y
        }
        else {
            mouse_x = position.x
            mouse_y = position.y
            update()
        }
    }
    
    func update_eye(with offset : simd_float3){
        //let offset = offset.x * across + offset.y * up + offset.z * forward
        eye += offset
        update()
    }
    
    func get_camera_matrix() -> simd_float4x4 {
        return simd_float4x4(eye: eye, center: eye + centre, up: simd_float3(0,1,0))
    }
    
    func update(){
        var delta_x = (mouse_x ?? (previous_x ?? 0 )) - (previous_x ?? 0)
        var delta_y = (mouse_y ?? (previous_y ?? 0 )) - (previous_y ?? 0)
        let deltaTheta = (delta_x/(2*width))*360
        let deltaPhi = (delta_y/(2*height))*360
        totalChangePhi += deltaPhi
        totalChangeTheta += deltaTheta
        let rotatedCentre = (simd_float4x4(rotationXYZ: simd_float3(-deltaPhi,-deltaTheta,0))*simd_float4(centre,1))
        centre = simd_float3(rotatedCentre.x, rotatedCentre.y,rotatedCentre.z)
        previous_x = mouse_x
        previous_y = mouse_y
        
        cameraMatrix = simd_float4x4(eye: eye, center: centre + eye, up: simd_float3(0,1,0))
        
        scene?.cameraHasBeenUpdated()
            
        }
        
        
      
     
       
    
}
