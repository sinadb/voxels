//
//  utils.swift
//  MetalProject
//
//  Created by Sina Dashtebozorgy on 12/05/2023.
//

import Foundation
import Metal
import MetalKit
import AppKit


private let gridVertices : [Float] = [
    -0.5,-0.5,-0.5,1, 0,0,1,1,  0,0,0,0,  0,0,0,0, 0,0,0,0,
     0.5,-0.5,-0.5,1, 0,0,1,1,  1,0,0,0,  0,0,0,0, 0,0,0,0,
     0.5,0.5,-0.5,1, 0,0,1,1,  1,1,0,0,  0,0,0,0, 0,0,0,0,
     -0.5,0.5,-0.5,1, 0,0,1,1,  0,1,0,0,  0,0,0,0, 0,0,0,0,
     
     -0.5,-0.5,0.5,1, 0,0,1,1,  0,0,0,0,  0,0,0,0, 0,0,0,0,
      0.5,-0.5,0.5,1, 0,0,1,1,  1,0,0,0,  0,0,0,0, 0,0,0,0,
      0.5,0.5,0.5,1, 0,0,1,1,  1,1,0,0,  0,0,0,0, 0,0,0,0,
      -0.5,0.5,0.5,1, 0,0,1,1,  0,1,0,0,  0,0,0,0, 0,0,0,0,
      
]

private let gridIndices : [uint16] = [
                0,1,
                1,2,
                2,3,
                3,0,

                4,5,
                5,6,
                6,7,
                7,4,

                0,4,
                1,5,
                2,6,
                3,7

]


class GridMesh : Mesh {
    var instanceCount : Int
    init(device : MTLDevice,minBound : simd_float3, maxBound : simd_float3, length : Float){
        instanceCount = (Int)((maxBound.x - minBound.x) / length)
        instanceCount *= (instanceCount * instanceCount)
        print(instanceCount)
        super.init(device: device, vertices: gridVertices, indices: gridIndices)
        let step = ( maxBound.x - minBound.x ) / length
        let halfLength : Float = length * 0.5
       
        for i in stride(from: minBound.x, to: maxBound.x, by: length){
            for j in stride(from: minBound.y, to: maxBound.y, by: length){
                for k in stride(from: minBound.z, to: maxBound.z, by: length){
                    let centre =  simd_float3(i + halfLength, j + halfLength, k + halfLength)
                    
                    let c_r = Float.random(in: 0...1)
                    let c_g = Float.random(in: 0...1)
                    let c_b = Float.random(in: 0...1)
                    //let colour = simd_float4(vec3: <#T##simd_float3#>)
                    let modelMatrix = create_modelMatrix(translation: centre,scale: simd_float3(length))
                    super.createInstance(with: modelMatrix, and: simd_float4(0.2,0.2,0.2))
                }
            }
            //let centre : Float = i - sign(i) * (length / 2)
          
        }
            
        
        
//        for i in stride(from: minBound.x, to: maxBound.x, by: length){
//            for j in stride(from: minBound.y, to: maxBound.y, by: length){
//                for k in stride(from: minBound.z, to: maxBound.z, by: length){
//                    let modelMatrix = create_modelMatrix(translation: simd_float3(i - sign(i) * length,j - sign(j) * length ,k - sign(k) * length),scale: simd_float3(length))
//                    super.createInstance(with: modelMatrix, and: simd_float4(1,0,0,1))
//                }
//            }
//        }
       
        let view = simd_float4x4(fovRadians: 3.14/2, aspectRatio: 2.0, near: 0.1, far: 20)
        super.init_instance_buffers(with: view)
    }
    func draw(renderEncoder : MTLRenderCommandEncoder){
        self.draw(renderEncoder: renderEncoder,with: instanceCount, renderMode: .line)
    }
}
