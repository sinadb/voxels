//
//  compute.swift
//  MetalProject
//
//  Created by Sina Dashtebozorgy on 17/01/2023.
//

import Foundation
import MetalKit


class ComputeKernel {
    let device : MTLDevice
    let computePipelineState : MTLComputePipelineState
    let commandQueue : MTLCommandQueue
    let buffer0 : MTLBuffer!
    let buffer1 : MTLBuffer!
    let result : MTLBuffer!
    let threadCount : Int
    
    static func buildComputePipeLineWith(_ device : MTLDevice)throws -> MTLComputePipelineState{
        let library = device.makeDefaultLibrary()
        var computeFunction = library?.makeFunction(name:"array")
        if  computeFunction == nil {
            print("function add_array found")
        }
        else{
            print("found function")
        }
        return try device.makeComputePipelineState(function: computeFunction!)
        
    }
    init?(_ device : MTLDevice, _ data0 : [Float], _ data1 : [Float]){
        threadCount = data0.count
        buffer0 = device.makeBuffer(bytes: data0, length: data0.count*4, options: .storageModeShared)
        buffer1 = device.makeBuffer(bytes: data1, length: data1.count*4, options: .storageModeShared)
        result = device.makeBuffer(length: data0.count*4, options: .storageModeShared)
        self.device = device
        commandQueue = self.device.makeCommandQueue()!
        do {
            try computePipelineState = ComputeKernel.buildComputePipeLineWith(self.device)
            print("compute pipeline created")
            
        }
        catch{
            print(error)
            return nil
        }
    }
    func performCalculation(){
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        computeEncoder.setComputePipelineState(computePipelineState)
        computeEncoder.setBuffer(buffer0, offset: 0, index: 0)
        computeEncoder.setBuffer(buffer1, offset: 0, index: 1)
        computeEncoder.setBuffer(result, offset: 0, index: 2)
        let threadGroupSize = MTLSize(width :threadCount,height : 1, depth : 1)
        

        computeEncoder.dispatchThreads(threadGroupSize, threadsPerThreadgroup: threadGroupSize)
        computeEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        let outcome = result.contents()
        let x = outcome.load(as: Float.self)
        print(x)
    }
}




