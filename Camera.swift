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
    var transformBuffer = [UniformBuffer]()
    var eye : simd_float3
    var centre : simd_float3
    var previous_x : Float?
    var previous_y : Float?
    var view : MTKView
    var width : Float
    var height : Float
    var totalChange : Float =  0
    init(for view : MTKView, eye: simd_float3, centre: simd_float3) {
        self.view = view
        self.eye = eye
        self.centre = centre
        width = 3024/2
        height = 1726/2
        print(width,height)
    }
    func update(){
        let delta_x = mouse_x! - previous_x!
        let delta_y = mouse_y! - previous_y!
        totalChange += delta_y
        let deltaTheta = (delta_x/(2*width))*360
        let deltaPhi = (delta_y/(2*height))*360
        let rotatedCentre = (simd_float4x4(rotationXYZ: simd_float3(deltaPhi,-deltaTheta,0))*simd_float4(centre,1))
        centre = simd_float3(rotatedCentre.x, rotatedCentre.y,rotatedCentre.z)
        previous_x = mouse_x
        previous_y = mouse_y
        var camera = simd_float4x4(eye: eye, center: centre + eye, up: simd_float3(0,1,0))
        for buffer in transformBuffer {
            for i in 0..<buffer.count! {
                var ptr = buffer.buffer.contents().advanced(by: i*MemoryLayout<Transforms>.stride).bindMemory(to: Transforms.self, capacity: 1)
                ptr.pointee.Camera = camera
            }
            
            
        }
       
    }
}
