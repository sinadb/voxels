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
        
        let n = Int((maxBound.x - minBound.x) / length)
       
        for i in 0..<n{
            let offsetx = halfLength + Float(i) * length
            for j in 0..<n{
                let offsety = halfLength + Float(j) * length
                for k in 0..<n{
                    let offsetz = halfLength + Float(k) * length
                    
                    let centre =  simd_float3(minBound.x + offsetx, minBound.y + offsety, minBound.z + offsetz)
                    
                    let c_r = Float.random(in: 0...1)
                    let c_g = Float.random(in: 0...1)
                    let c_b = Float.random(in: 0...1)
                    //let colour = simd_float4(vec3: <#T##simd_float3#>)
                    let modelMatrix = create_modelMatrix(translation: centre,scale: simd_float3(length))
                    super.createInstance(with: modelMatrix, and: simd_float4(0.9,0.9,0.9))
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


class Voxel {
    let meshToBeVoxelizes : Mesh
    let opaqueGridMesh : Mesh
    let computePipeLineState : MTLComputePipelineState
    let fillVoxelComputePipeLineState : MTLComputePipelineState
    var cubeBB : [simd_float3]
    var length : Float
    let indicesBuffer : MTLBuffer
    var nthreads : Int {
        return Int((cubeBB[1].y - cubeBB[0].y) / length)
    }
    init(device : MTLDevice, address : String, minmax : [simd_float3], gridLength : Float){
        cubeBB = minmax
        length = gridLength
        let assetURL = Bundle.main.url(
            forResource: address,
            withExtension: "obj")!
        meshToBeVoxelizes = Mesh(device: device, address: assetURL)
        let centre = (minmax[0]+minmax[1]) * 0.5
        let modelMatrix = create_modelMatrix(translation: simd_float3(0,0,-13),scale: simd_float3(1.8))
        meshToBeVoxelizes.createInstance(with: modelMatrix, and: simd_float4(1,1,0,1))
        meshToBeVoxelizes.init_instance_buffers(with: simd_float4x4(1))
        
        let allocator = MTKMeshBufferAllocator(device: device)
        let cubeMDLMesh = MDLMesh(boxWithExtent: simd_float3(1,1,1), segments: simd_uint3(1,1,1), inwardNormals: false, geometryType: .triangles, allocator: allocator)
        opaqueGridMesh = Mesh(device: device, Mesh: cubeMDLMesh)!
        
        let n = Int((minmax[1].x - minmax[0].x) / gridLength)
        let halfLength : Float = gridLength * 0.5
       
        for i in 0..<n{
            let offsetx = halfLength + Float(i) * gridLength
            for j in 0..<n{
                let offsety = halfLength + Float(j) * gridLength
                for k in 0..<n{
                    let offsetz = halfLength + Float(k) * gridLength
                    
                    let centre =  simd_float3(minmax[0].x + offsetx, minmax[0].y + offsety, minmax[0].z + offsetz)
                    let modelMatrix = create_modelMatrix(translation: centre,scale: simd_float3(gridLength))
                    opaqueGridMesh.createInstance(with: modelMatrix,and: simd_float4(0,0,0,0))
                    
                }
            }
        }
        opaqueGridMesh.init_instance_buffers(with: simd_float4x4(0))
        
        
        
        let library = device.makeDefaultLibrary()
        let computeFunction = library?.makeFunction(name: "compute")
        computePipeLineState = try! device.makeComputePipelineState(function: computeFunction!)
       
        
        
        let fillVoxelComputeFunction = library?.makeFunction(name: "fill_voxel")
        fillVoxelComputePipeLineState = try! device.makeComputePipelineState(function: fillVoxelComputeFunction!)
        
        indicesBuffer = device.makeBuffer(length: opaqueGridMesh.no_instances * MemoryLayout<Int32>.stride , options: [])!

        
    }
    
    func voxelize(commandQueue : MTLCommandQueue){
        guard let computeCommandBuffer = commandQueue.makeCommandBuffer() else {return}
        
        
        guard let computeEncoder = computeCommandBuffer.makeComputeCommandEncoder() else {return}
        
        computeEncoder.setComputePipelineState(computePipeLineState)

        computeEncoder.setBuffer(indicesBuffer, offset: 0, index: 6)
        computeEncoder.setBytes(&length, length: 4, index: 4)
        computeEncoder.setBytes(&cubeBB, length: MemoryLayout<simd_float3>.stride * 2, index: 0)
        computeEncoder.setBuffer(meshToBeVoxelizes.Mesh!.vertexBuffers[0].buffer, offset: 0, index: 1)
        computeEncoder.setBuffer(meshToBeVoxelizes.BufferArray[0].buffer, offset: 0, index: 2)
        computeEncoder.setBuffer(opaqueGridMesh.BufferArray[1].buffer, offset: 0, index: 7)
        computeEncoder.setBuffer(meshToBeVoxelizes.Mesh!.submeshes[0].indexBuffer.buffer, offset: 0, index: 9)
        
        
       
        computeEncoder.dispatchThreadgroups(MTLSize(width: Int(meshToBeVoxelizes.triangleCount!), height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: 8, height:8, depth: 8))
//
        
        computeEncoder.setComputePipelineState(fillVoxelComputePipeLineState)
        computeEncoder.dispatchThreadgroups(MTLSize(width: 1, height: nthreads, depth: nthreads), threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1))
      
        computeEncoder.endEncoding()
        computeCommandBuffer.commit()
        computeCommandBuffer.waitUntilCompleted()
    }
    
    func drawOriginalMesh(with renderEncoder : MTLRenderCommandEncoder){
        meshToBeVoxelizes.draw(renderEncoder: renderEncoder)
    }
    
    func drawOpaqueGrid(with renderEncoder : MTLRenderCommandEncoder){
        opaqueGridMesh.draw(renderEncoder: renderEncoder)
    }
    
    
    
}
