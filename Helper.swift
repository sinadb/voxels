//
//  Helper.swift
//  MetalProject
//
//  Created by Sina Dashtebozorgy on 04/03/2023.
//



import Foundation
import Metal
import MetalKit
import AppKit


func createBuffersForRenderToCube(scale : simd_float3 , rotation : simd_float3 , translate : simd_float3 , from eye : simd_float3 ) -> [Transforms] {
    
    let projection = simd_float4x4(fovRadians: 3.14/2, aspectRatio: 1, near: 0.1, far: 100)
    let scale = simd_float4x4(scale: scale)
    let rotation = simd_float4x4(rotationXYZ: rotation)
    let translation = simd_float4x4(translate: translate)
    
    let out = [Transforms(Scale: scale, Translate: translation, Rotation: rotation, Projection: projection, Camera: simd_float4x4(eye: eye, center: simd_float3(1,0,0) + eye, up: simd_float3(0,-1,0))),
               
        Transforms(Scale: scale, Translate: translation, Rotation: rotation, Projection: projection, Camera: simd_float4x4(eye: eye, center: simd_float3(-1,0,0) + eye, up: simd_float3(0,-1,0))),
               
        Transforms(Scale: scale, Translate: translation, Rotation: rotation, Projection: projection, Camera: simd_float4x4(eye: eye, center: simd_float3(0,-1,0) + eye, up: simd_float3(0,0,-1))),
               
        Transforms(Scale: scale, Translate: translation, Rotation: rotation, Projection: projection, Camera: simd_float4x4(eye: eye, center: simd_float3(0,1,0) + eye, up: simd_float3(0,0,1))),
               
        Transforms(Scale: scale, Translate: translation, Rotation: rotation, Projection: projection, Camera: simd_float4x4(eye: eye, center: simd_float3(0,0,1) + eye, up: simd_float3(0,-1,0))),
               
        Transforms(Scale: scale, Translate: translation, Rotation: rotation, Projection: projection, Camera: simd_float4x4(eye: eye, center: simd_float3(0,0,-1) + eye, up: simd_float3(0,-1,0)))
                                           ]
            return out
       
}

func createBuffersForRenderToCube(scale : simd_float3 , rotation : simd_float3 , translate : simd_float3 , from cameras : [simd_float4x4] ) -> [Transforms] {
    
    let projection = simd_float4x4(fovRadians: 3.14/2, aspectRatio: 1, near: 0.1, far: 100)
    let scale = simd_float4x4(scale: scale)
    let rotation = simd_float4x4(rotationXYZ: rotation)
    let translation = simd_float4x4(translate: translate)
    
    let out = [Transforms(Scale: scale, Translate: translation, Rotation: rotation, Projection: projection, Camera: cameras[0]),
               
        Transforms(Scale: scale, Translate: translation, Rotation: rotation, Projection: projection, Camera: cameras[1]),
               
        Transforms(Scale: scale, Translate: translation, Rotation: rotation, Projection: projection, Camera: cameras[2]),
               
        Transforms(Scale: scale, Translate: translation, Rotation: rotation, Projection: projection, Camera: cameras[3]),
               
        Transforms(Scale: scale, Translate: translation, Rotation: rotation, Projection: projection, Camera: cameras[4]),
               
        Transforms(Scale: scale, Translate: translation, Rotation: rotation, Projection: projection, Camera: cameras[5])
                                           ]
            return out
       
}


func createBuffersForRenderToCube() -> [Transforms] {
    
    return createBuffersForRenderToCube(scale: simd_float3(1), rotation: simd_float3(0), translate: simd_float3(0), from: simd_float3(0))
       
}

struct Attribute {
    let format : MTLVertexFormat;
    let offset : Int;
    // length in bytes
    let length : Int;
    let bufferIndex : Int
    
    
}

struct Texture {
    var texture : MTLTexture
    let index : Int
    mutating func update_texture(with texture : MTLTexture){
        self.texture = texture
    }
}

struct UniformBuffer {
    let buffer : MTLBuffer
    let index : Int
    var functionType : MTLFunctionType?
    var count : Int?
}





func createVertexDescriptor(attributes : Attribute...) -> MTLVertexDescriptor {
    
    
    let vertexDescriptor = MTLVertexDescriptor()
    for (index,attribute) in attributes.enumerated(){
        vertexDescriptor.attributes[index].format = attribute.format
        vertexDescriptor.attributes[index].offset = attribute.offset
        vertexDescriptor.attributes[index].bufferIndex = attribute.bufferIndex
        vertexDescriptor.layouts[attribute.bufferIndex].stride += attribute.length
    }
    return vertexDescriptor
    
}



class Mesh{
    
    var MeshCamera : Camera?
    var uniformBuffersArray = [UniformBuffer]()
    var texturesArray = [Texture]()
    let device : MTLDevice
    var vertexData : [Float]?
    var indexData : [UInt16]?
    var vertexBuffer : MTLBuffer?
    var indexBuffer : MTLBuffer?
    var Mesh : MTKMesh?
    var instanceTransformData = [Transforms]()
    var instanceColourData = [simd_float4]()
    var instanceTransformModeData = [Int]()
    var instaceTransformBuffer : MTLBuffer?
    var instanceColourBuffer : MTLBuffer?
    var instanceTransformModeBuffer : MTLBuffer?
    var instanceBuffer : MTLBuffer?
    var no_instances = 0
    
    func initaliseBuffers(){
        if Mesh != nil{
            print("Test Mesh ")
            vertexBuffer = Mesh?.vertexBuffers[0].buffer
            indexBuffer = Mesh?.submeshes[0].indexBuffer.buffer
        }
        else{
            vertexBuffer = device.makeBuffer(bytes: &vertexData, length: MemoryLayout<Float>.stride*(vertexData!.count), options: [])
            indexBuffer = device.makeBuffer(bytes: &indexData, length: MemoryLayout<UInt16>.stride*indexData!.count, options: [])
        }
        
        
    }
    
    func createAndAddUniformBuffer(bytes :  UnsafeRawPointer , length : Int, at index : Int, for device : MTLDevice, for functiontype : MTLFunctionType? =  nil) {
        
        let buffer = device.makeBuffer(bytes: bytes, length: length)!
        let index = index
        let function = functiontype ?? .vertex
        var out = UniformBuffer(buffer: buffer, index: index,functionType: function)
        add_uniform_buffer(buffers: out)
        
    }
    
    func attach_camera_to_mesh(to camera : Camera){
        MeshCamera = camera
        MeshCamera?.transformBuffer.append(uniformBuffersArray[0])
    }
    
    func add_uniform_buffer(buffers : UniformBuffer...){
        for b in buffers {
            uniformBuffersArray.append(b)
        }
    }
    
    func add_textures(textures : Texture...){
        for t in textures {
            texturesArray.append(t)
        }
    }
    
    
    init(device : MTLDevice, vertices : [Float], indices : [uint16]){
        self.device = device
        vertexData = vertices
        indexData = indices
        initaliseBuffers()
        
    }
    init?(device : MTLDevice, Mesh : MDLMesh){
        self.device = device
        let allocator = MTKMeshBufferAllocator(device: device)
        do {
            try self.Mesh = MTKMesh(mesh: Mesh, device: device)
            print("Test Mesh created")
        }
        catch{
            print(error)
            print("Failed to create Mesh")
            return nil
        }
        initaliseBuffers()
    }
    
    func createInstance(with transforms : Transforms..., and colour : simd_float4..., add transformMode : Int...){
        for t in transforms {
            instanceTransformData.append(t)
            no_instances += 1
        }
        for c in colour{
            instanceColourData.append(c)
        }
        for mode in transformMode {
            instanceTransformModeData.append(mode)
        }
    }
    func init_instance_buffers(){
        instanceColourBuffer = device.makeBuffer(bytes: &instanceColourData, length: MemoryLayout<simd_float4>.stride*instanceColourData.count, options: [])
        instaceTransformBuffer = device.makeBuffer(bytes: &instanceTransformData, length: MemoryLayout<Transforms>.stride*instanceTransformData.count, options: [])
        instanceTransformModeBuffer = device.makeBuffer(bytes: &instanceTransformModeData, length: MemoryLayout<Int>.stride*instanceTransformModeData.count, options: [])
        let transformBuffer = UniformBuffer(buffer: instaceTransformBuffer!, index: vertexBufferIDs.uniformBuffers, count: no_instances)
        let colourBuffer = UniformBuffer(buffer: instanceColourBuffer!, index: vertexBufferIDs.colour)
        let transformModeBuffer = UniformBuffer(buffer: instanceTransformModeBuffer!, index: vertexBufferIDs.order_of_rot_tran)
        add_uniform_buffer(buffers: colourBuffer,transformModeBuffer)
        uniformBuffersArray.insert(transformBuffer, at: 0)
    }
    
//    func addInsanceData(with offsets : [Float]){
//        instanceData = offsets
//        instanceBuffer = device.makeBuffer(bytes: instanceData!, length: MemoryLayout<Float>.stride*offsets.count, options: [])
//    }
    
    func updateUniformBuffer(with newData : inout Transforms){
        for buffer in uniformBuffersArray {
            if (buffer.index == vertexBufferIDs.uniformBuffers){
                if let camera = MeshCamera {
                    newData.Camera = simd_float4x4(eye: camera.eye, center: camera.eye + camera.centre, up: simd_float3(0,1,0))
                }
                buffer.buffer.contents().copyMemory(from: &newData , byteCount: MemoryLayout<Transforms>.stride)
            }
        }
        
    }
    func updateUniformBuffer(with newData : inout Transforms, at offset : Int){
//        for buffer in uniformBuffersArray {
//            if (buffer.index == vertexBufferIDs.uniformBuffers){
//                buffer.buffer.contents().advanced(by: offset * MemoryLayout<Transforms>.stride).copyMemory(from: &newData , byteCount: MemoryLayout<Transforms>.stride)
//            }
//        }
        if let camera = MeshCamera {
            newData.Camera = simd_float4x4(eye: camera.eye, center: camera.eye + camera.centre, up: simd_float3(0,1,0))
        }
        uniformBuffersArray[0].buffer.contents().advanced(by: offset * MemoryLayout<Transforms>.stride).copyMemory(from: &newData , byteCount: MemoryLayout<Transforms>.stride)
        
    }
    
    func updateUniformBuffer(with newData : inout [Transforms]){
        for buffer in uniformBuffersArray {
            if (buffer.index == vertexBufferIDs.uniformBuffers){
                buffer.buffer.contents().copyMemory(from: &newData , byteCount: MemoryLayout<Transforms>.stride*newData.count)
            }
        }
        
    }
    
    func updateUniformBuffer(with newData : inout [Transforms], at offset : Int){
//        for buffer in uniformBuffersArray {
//            if (buffer.index == vertexBufferIDs.uniformBuffers){
//                buffer.buffer.contents().advanced(by: offset * MemoryLayout<Transforms>.stride*6).copyMemory(from: &newData , byteCount: MemoryLayout<Transforms>.stride*6)
//            }
//        }
        uniformBuffersArray[0].buffer.contents().advanced(by: offset * MemoryLayout<Transforms>.stride*6).copyMemory(from: &newData , byteCount: MemoryLayout<Transforms>.stride*6)
    }
    
    func updateTexture(with new_texture : Texture){
        for i in 0..<texturesArray.count{
            if(texturesArray[i].index == new_texture.index){
                texturesArray[i] = new_texture
            }
        }
    }
    
    func draw(renderEncoder : MTLRenderCommandEncoder){
        for buffer in uniformBuffersArray {
            if let function = buffer.functionType {
                if(function == .fragment){
                    renderEncoder.setFragmentBuffer(buffer.buffer, offset: 0, index: buffer.index)
                    continue
                }
            }
            renderEncoder.setVertexBuffer(buffer.buffer, offset: 0, index: buffer.index)
        }
        for texture in texturesArray {
            renderEncoder.setFragmentTexture(texture.texture, index: texture.index)
        }
        if Mesh != nil{
            let submesh = Mesh!.submeshes[0]
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: indexBuffer!, indexBufferOffset: submesh.indexBuffer.offset)
        }
        else{
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexData!.count, indexType: .uint16, indexBuffer: indexBuffer!, indexBufferOffset: 0, instanceCount: 1)
        }
        
    }
    
    func draw(renderEncoder : MTLRenderCommandEncoder, with instances : Int){
        for buffer in uniformBuffersArray {
            if let function = buffer.functionType {
                if(function == .fragment){
                    renderEncoder.setFragmentBuffer(buffer.buffer, offset: 0, index: buffer.index)
                    continue
                }
            }
            renderEncoder.setVertexBuffer(buffer.buffer, offset: 0, index: buffer.index)
        }
        for texture in texturesArray {
            renderEncoder.setFragmentTexture(texture.texture, index: texture.index)
        }
        if Mesh != nil{
            let submesh = Mesh!.submeshes[0]
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(instanceBuffer, offset: 0, index: 2)
            renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: indexBuffer!, indexBufferOffset: submesh.indexBuffer.offset, instanceCount: instances)
        }
        else{
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(instanceBuffer, offset: 0, index: 2)
            renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexData!.count, indexType: .uint16, indexBuffer: indexBuffer!, indexBufferOffset: 0, instanceCount: instances)
        }
    }
    
}

class functionConstant {
    let functionConstant = MTLFunctionConstantValues()
    var last_index : Int = 0
    func setValue<T>(type : MTLDataType, value : inout T){
        functionConstant.setConstantValue(&value, type: type, index: last_index)
       
        last_index += 1
    }
    func setValue<T>(type : MTLDataType, value : inout T, at index : Int){
        functionConstant.setConstantValue(&value, type: type, index: index)
    }
}






class pipeLine {
    let library : MTLLibrary
    let m_pipeLine : MTLRenderPipelineState
    
    
    
    init?(_ device : MTLDevice, _ vertexFunctionName : String, _ fragmentFunctionName : String, _ renderToCube : Bool){
        library = device.makeDefaultLibrary()!
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.vertexFunction = library.makeFunction(name: vertexFunctionName)
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: fragmentFunctionName)
        if(renderToCube){
            pipelineDescriptor.inputPrimitiveTopology = .triangle
            pipelineDescriptor.rasterSampleCount = 1
        }
        do {
            try m_pipeLine = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            print("PipeLine Created Successfully")
        }
        catch{
            print(error)
            return nil
        }
    }
    init?(_ device : MTLDevice, _ vertexFunctionName : String, _ fragmentFunctionName : String, _ vertexDescriptor : MTLVertexDescriptor,  _ renderToCube : Bool){
        
        library = device.makeDefaultLibrary()!
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.vertexFunction = library.makeFunction(name: vertexFunctionName)
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: fragmentFunctionName)
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        if(renderToCube){
            pipelineDescriptor.inputPrimitiveTopology = .triangle
            pipelineDescriptor.rasterSampleCount = 1
        }
        do {
            try m_pipeLine = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            print("PipeLine Created Successfully")
        }
        catch{
            print(error)
            return nil
        }
        
    }
    
    init?(_ device : MTLDevice, _ vertexFunctionName : String, _ fragmentFunctionName : String, _ vertexDescriptor : MTLVertexDescriptor, _ functionConstant : MTLFunctionConstantValues){

        library = device.makeDefaultLibrary()!
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
       
            pipelineDescriptor.vertexFunction = try! library.makeFunction(name: vertexFunctionName, constantValues: functionConstant)
            pipelineDescriptor.fragmentFunction = try! library.makeFunction(name: fragmentFunctionName, constantValues: functionConstant)
       
        
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor

        do {
            try m_pipeLine = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            print("PipeLine Created Successfully")
        }
        catch{
            print(error)
            return nil
        }

    }
    
}



