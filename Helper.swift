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


func createBuffersForRenderToCube(scale : simd_float4x4 , rotation : simd_float3 , translate : simd_float4x4 , from cameras : [simd_float4x4] ) -> [Transforms] {
    
    let projection = simd_float4x4(fovRadians: 3.14/2, aspectRatio: 1, near: 0.1, far: 100)
    let scale = scale
    let rotation = simd_float4x4(rotationXYZ: rotation)
    let translation = translate
    
    let out = [Transforms(Scale: scale, Translate: translation, Rotation: rotation, Projection: projection, Camera: cameras[0]),
               
        Transforms(Scale: scale, Translate: translation, Rotation: rotation, Projection: projection, Camera: cameras[1]),
               
        Transforms(Scale: scale, Translate: translation, Rotation: rotation, Projection: projection, Camera: cameras[2]),
               
        Transforms(Scale: scale, Translate: translation, Rotation: rotation, Projection: projection, Camera: cameras[3]),
               
        Transforms(Scale: scale, Translate: translation, Rotation: rotation, Projection: projection, Camera: cameras[4]),
               
        Transforms(Scale: scale, Translate: translation, Rotation: rotation, Projection: projection, Camera: cameras[5])
                                           ]
            return out
       
}


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
    
    
    let device : MTLDevice
    var Mesh : MTKMesh?
    var is_shadow_caster : Bool?
    var futureModelMatrices = [simd_float4x4]()
    var MeshCamera : Camera?
    
    
    var BufferArray = [UniformBuffer]()
    var texturesArray = [Texture]()
    var NormalTextureArray = [Texture]()
    var DisplacementTextureArray = [Texture]()
    
    
   
    var vertexData : [Float]?
    var indexData : [UInt16]?
    var vertexBuffer : MTLBuffer?
    var indexBuffer : MTLBuffer?
    var indexBufferArray = [MTLBuffer]()
  
    
    
    var instanceConstantData = [InstanceConstants]()
    var instanceModelMatrixData = [simd_float4x4]()
    var instanceColourData = [simd_float4]()

    
    var instaceConstantBuffer : MTLBuffer?
    var instanceColourBuffer : MTLBuffer?
    
  
   
    var no_instances : Int = 0
    
    
    
    var tesselationFactorBuffer : MTLBuffer?
    var tesselationLevelBuffer : MTLBuffer?
    var computePipeLineState : MTLComputePipelineState?
    
    var has_flat = false
    var has_normal = false
    var has_displacement = false
    var cullFace : MTLCullMode?
    
    var scaleInitialState = [Float]()
    var translationInitialState = [simd_float3]()
    
    var boundingBox : [simd_float3]?
    
    
    init?(device : MTLDevice, Mesh : MDLMesh,  with label : String = "NoLabel"){
        self.device = device
        //MeshCamera = camera
        //MeshCamera?.Mesh?.append(self)
        let allocator = MTKMeshBufferAllocator(device: device)
        do {
            let mdlMeshVD = MDLVertexDescriptor()
            mdlMeshVD.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float4, offset: 0, bufferIndex: 0)
            
            mdlMeshVD.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float4, offset: 16, bufferIndex: 0)
            
            mdlMeshVD.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float4, offset: 32, bufferIndex: 0)
            
            mdlMeshVD.attributes[3] = MDLVertexAttribute(name: MDLVertexAttributeTangent, format: .float4, offset: 48, bufferIndex: 0)
            
            mdlMeshVD.attributes[4] = MDLVertexAttribute(name: MDLVertexAttributeBitangent, format: .float4, offset: 64, bufferIndex: 0)
            
            mdlMeshVD.layouts[0] = MDLVertexBufferLayout(stride: 80)
            
            Mesh.addTangentBasis(
              forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
              normalAttributeNamed: MDLVertexAttributeNormal,
              tangentAttributeNamed: MDLVertexAttributeTangent)
            
            Mesh.vertexDescriptor = mdlMeshVD
            boundingBox = [Mesh.boundingBox.minBounds,Mesh.boundingBox.maxBounds]
            try self.Mesh = MTKMesh(mesh: Mesh, device: device)
            print("\(label) Mesh created")
        
        }
        catch{
            print(error)
            print("Failed to create Mesh \(label)")
            return nil
        }
        
       
        initaliseBuffers()
    }
    
    init?(device : MTLDevice, address : URL, with label : String = "NoLabel", with tesselationLevel : Int){
        self.device = device
        tesselationFactorBuffer = device.makeBuffer(length: MemoryLayout<MTLTriangleTessellationFactorsHalf>.stride, options:.storageModePrivate)
        var tempLevel = tesselationLevel
        tesselationLevelBuffer = device.makeBuffer(bytes: &tempLevel, length: MemoryLayout<Int>.stride,options: [])
        
        // do the quick compute stuff in the initialisation
        let library = device.makeDefaultLibrary()
        let computeFunction = library?.makeFunction(name: "tess_factor_tri")
        if(computeFunction == nil){
            print("Kernel function does not exist")
        }
        else {
            print("Kernel function found and loaded")
        }
         do {
             computePipeLineState = try device.makeComputePipelineState(function: computeFunction!) }
        catch{
            return nil
        }
        
        
       
        
//        let result = tesselationFactorBuffer?.contents().bindMemory(to: MTLTriangleTessellationFactorsHalf.self, capacity: 1)
        //print(result?.pointee.insideTessellationFactor)
        
        
        let mdlMeshVD = MDLVertexDescriptor()
        mdlMeshVD.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float4, offset: 0, bufferIndex: 0)
        
        mdlMeshVD.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: 16, bufferIndex: 0)
        mdlMeshVD.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: 28, bufferIndex: 0)
        
        mdlMeshVD.attributes[3] = MDLVertexAttribute(name: MDLVertexAttributeTangent, format: .float4, offset: 36, bufferIndex: 0)
        
        mdlMeshVD.attributes[4] = MDLVertexAttribute(name: MDLVertexAttributeBitangent, format: .float4, offset: 52, bufferIndex: 0)
        mdlMeshVD.layouts[0] = MDLVertexBufferLayout(stride: 68)
      
        //self.device = device
       
        let allocator = MTKMeshBufferAllocator(device: device)
        let Asset = MDLAsset(url: address, vertexDescriptor: mdlMeshVD, bufferAllocator: allocator)
        Asset.loadTextures()
        guard let MeshArray = Asset.childObjects(of: MDLMesh.self) as? [MDLMesh] else {
            print("\(label) failed to load")
            return
        }
        let MDLMesh = MeshArray.first!
        
        MDLMesh.addTangentBasis(
          forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
          normalAttributeNamed: MDLVertexAttributeNormal,
          tangentAttributeNamed: MDLVertexAttributeTangent)
        MDLMesh.vertexDescriptor = mdlMeshVD
        
        do {
            try self.Mesh = MTKMesh(mesh: MDLMesh, device: device)
            print("\(label) Mesh created")
        }
        catch{
            print(error)
            print("Failed to create Mesh \(label)")
            return
        }
        
        let textureLoader = MTKTextureLoader(device: device)
        vertexBuffer = Mesh?.vertexBuffers[0].buffer
        let submeshcount = MDLMesh.submeshes!.count
        for i in 0..<(submeshcount ){
            let indexBuffer = Mesh?.submeshes[i].indexBuffer.buffer
            indexBufferArray.append(indexBuffer!)
            let currentSubMesh = MDLMesh.submeshes?[i] as? MDLSubmesh
            let material = currentSubMesh?.material
            if let baseColour = material?.property(with: MDLMaterialSemantic.baseColor){
                if baseColour.type == .texture, let textureURL = baseColour.urlValue {
                    has_flat = true
                    let options: [MTKTextureLoader.Option : Any] = [
                        .textureUsage : MTLTextureUsage.shaderRead.rawValue,
                        .textureStorageMode : MTLStorageMode.private.rawValue,
                        .origin : MTKTextureLoader.Origin.bottomLeft.rawValue,
                        .generateMipmaps : true
                    ]
                    do {
                        let texture = try textureLoader.newTexture(URL: textureURL, options: options)
                        texturesArray.append(Texture(texture: texture, index: textureIDs.flat))
//                        self.add_textures(textures: Texture(texture: texture, index: textureIDs.flat))
                    }
                    catch {
                        print(error)
                        print("Alley texture failed to load")
                    }
                }
                else {
                    print("Alley texture not loaded")
                }
            }
            
            if let baseColour = material?.property(with: MDLMaterialSemantic.tangentSpaceNormal){
                if baseColour.type == .texture, let textureURL = baseColour.urlValue {
                    has_normal = true
                    let options: [MTKTextureLoader.Option : Any] = [
                        .textureUsage : MTLTextureUsage.shaderRead.rawValue,
                        .textureStorageMode : MTLStorageMode.private.rawValue,
                        .origin : MTKTextureLoader.Origin.bottomLeft.rawValue,
                        .SRGB : false,
                        .generateMipmaps : true
                    ]
                    
                    do {
                        let texture = try textureLoader.newTexture(URL: textureURL, options: options)
                        NormalTextureArray.append(Texture(texture: texture, index: textureIDs.Normal))
//                        self.add_textures(textures: Texture(texture: texture, index: textureIDs.Normal))
                    }
                    catch {
                        print(error)
                        print("Alley texture failed to load")
                    }
                }
                else {
                    print("Alley Normal texture not loaded")
                }
            }
            if let baseColour = material?.property(with: MDLMaterialSemantic.displacement){
                if baseColour.type == .texture, let textureURL = baseColour.urlValue {
                    has_displacement = true
                    let options: [MTKTextureLoader.Option : Any] = [
                        .textureUsage : MTLTextureUsage.shaderRead.rawValue,
                        .textureStorageMode : MTLStorageMode.private.rawValue,
                        .origin : MTKTextureLoader.Origin.bottomLeft.rawValue,
                        .generateMipmaps : true
                    ]
                    do {
                        let texture = try textureLoader.newTexture(URL: textureURL, options: options)
                        DisplacementTextureArray.append(Texture(texture: texture, index: textureIDs.Displacement))
//                        self.add_textures(textures: Texture(texture: texture, index: textureIDs.flat))
                    }
                    catch {
                        print(error)
                        print("Alley texture failed to load")
                    }
                }
                else {
                    print("Alley texture not loaded")
                }
            }
        }
    }
    
    init(device : MTLDevice, address : URL, with label : String = "NoLable"){
        
        let mdlMeshVD = MDLVertexDescriptor()
        mdlMeshVD.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float4, offset: 0, bufferIndex: 0)
        
        mdlMeshVD.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: 16, bufferIndex: 0)
        mdlMeshVD.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: 28, bufferIndex: 0)
        
        mdlMeshVD.attributes[3] = MDLVertexAttribute(name: MDLVertexAttributeTangent, format: .float4, offset: 36, bufferIndex: 0)
        
        mdlMeshVD.attributes[4] = MDLVertexAttribute(name: MDLVertexAttributeBitangent, format: .float4, offset: 52, bufferIndex: 0)
        mdlMeshVD.layouts[0] = MDLVertexBufferLayout(stride: 68)
      
        self.device = device
       
        let allocator = MTKMeshBufferAllocator(device: device)
        let Asset = MDLAsset(url: address, vertexDescriptor: mdlMeshVD, bufferAllocator: allocator)
        Asset.loadTextures()
        guard let MeshArray = Asset.childObjects(of: MDLMesh.self) as? [MDLMesh] else {
            print("\(label) failed to load")
            return
        }
        let MDLMesh = MeshArray.first!
        
        MDLMesh.addTangentBasis(
          forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
          normalAttributeNamed: MDLVertexAttributeNormal,
          tangentAttributeNamed: MDLVertexAttributeTangent)
        MDLMesh.vertexDescriptor = mdlMeshVD
        
        do {
            try self.Mesh = MTKMesh(mesh: MDLMesh, device: device)
            print("\(label) Mesh created")
        }
        catch{
            print(error)
            print("Failed to create Mesh \(label)")
            return
        }
        
        let textureLoader = MTKTextureLoader(device: device)
        vertexBuffer = Mesh?.vertexBuffers[0].buffer
        let submeshcount = MDLMesh.submeshes!.count
        for i in 0..<(submeshcount ){
            let indexBuffer = Mesh?.submeshes[i].indexBuffer.buffer
            indexBufferArray.append(indexBuffer!)
            let currentSubMesh = MDLMesh.submeshes?[i] as? MDLSubmesh
            let material = currentSubMesh?.material
            if let baseColour = material?.property(with: MDLMaterialSemantic.baseColor){
                if baseColour.type == .texture, let textureURL = baseColour.urlValue {
                    let options: [MTKTextureLoader.Option : Any] = [
                        .textureUsage : MTLTextureUsage.shaderRead.rawValue,
                        .textureStorageMode : MTLStorageMode.private.rawValue,
                        .origin : MTKTextureLoader.Origin.bottomLeft.rawValue
                    ]
                    do {
                        let texture = try textureLoader.newTexture(URL: textureURL, options: options)
                        self.add_textures(texture: Texture(texture: texture, index: textureIDs.flat))
                    }
                    catch {
                        print(error)
                        print("Alley texture failed to load")
                    }
                }
                else {
                    print("Alley texture not loaded")
                }
            }
            
            if let baseColour = material?.property(with: MDLMaterialSemantic.tangentSpaceNormal){
                if baseColour.type == .texture, let textureURL = baseColour.urlValue {
                    let options: [MTKTextureLoader.Option : Any] = [
                        .textureUsage : MTLTextureUsage.shaderRead.rawValue,
                        .textureStorageMode : MTLStorageMode.private.rawValue,
                        .origin : MTKTextureLoader.Origin.bottomLeft.rawValue,
                        .SRGB : false
                    ]
                    
                    do {
                        let texture = try textureLoader.newTexture(URL: textureURL, options: options)
                        self.add_textures(texture: Texture(texture: texture, index: textureIDs.Normal))
                    }
                    catch {
                        print(error)
                        print("Alley texture failed to load")
                    }
                }
                else {
                    print("Alley Normal texture not loaded")
                }
            }
        }
 
        print(texturesArray.count)
    }
    

    
    init(device : MTLDevice, vertices : [Float], indices : [uint16]){
      // MeshCamera = camera
        self.device = device
        vertexData = vertices
        indexData = indices
        initaliseBuffers()
        
    }
    
    init?(device : MTLDevice, vertices : [Float], indices : [uint16], with tesselationLevel : Int, with label : String = "NoLabel"){
        
        self.device = device
        vertexData = vertices
        indexData = indices
        initaliseBuffers()
        
        tesselationFactorBuffer = device.makeBuffer(length: MemoryLayout<MTLTriangleTessellationFactorsHalf>.stride, options:.storageModePrivate)
        var tempLevel = tesselationLevel
        tesselationLevelBuffer = device.makeBuffer(bytes: &tempLevel, length: MemoryLayout<Int>.stride,options: [])
        
        // do the quick compute stuff in the initialisation
        let library = device.makeDefaultLibrary()
        let computeFunction = library?.makeFunction(name: "tess_factor_tri")
        if(computeFunction == nil){
            print("Kernel function does not exist")
        }
        else {
            print("Kernel function found and loaded")
        }
         do {
             computePipeLineState = try device.makeComputePipelineState(function: computeFunction!) }
        catch{
            return nil
        }
        
        print("\(label) mesh was created successfully")
        
    }
    
    func setCullModeForMesh(side : MTLCullMode){
        cullFace = side
    }
    
    
    func initaliseBuffers(){
        if Mesh != nil{
            vertexBuffer = Mesh?.vertexBuffers[0].buffer
            for submesh in (Mesh?.submeshes)! {
                indexBufferArray.append(submesh.indexBuffer.buffer)
            }
            
        }
        else{
            print("creating buffers")
            vertexBuffer = device.makeBuffer(bytes: &(vertexData!), length: MemoryLayout<Float>.stride*(vertexData!.count), options: [])
            indexBuffer = device.makeBuffer(bytes: &(indexData!), length: MemoryLayout<UInt16>.stride*indexData!.count, options: [])
        }
        
        
    }
    

    
    func rotateMesh(with rotation : simd_float3, and viewMatrix : simd_float4x4){
        var ptr = BufferArray[0].buffer.contents().bindMemory(to: InstanceConstants.self, capacity: no_instances)
        for i in 0..<no_instances{
            let modelMatrix = create_modelMatrix(rotation: rotation, translation: translationInitialState[i], scale: simd_float3(1))
            let normalMatrix = create_normalMatrix(modelViewMatrix: viewMatrix * modelMatrix)
            (ptr + i).pointee.normalMatrix = normalMatrix
            (ptr + i).pointee.modelMatrix = modelMatrix
            
        }
    }
    
    func add_textures(texture : Texture){
        texturesArray.append(texture)
        if(texture.index == textureIDs.flat){
            has_flat = true
        }
        else if(texture.index == textureIDs.Normal){
            has_normal = true
        }
    }
    
    
    
    
    func createInstance(with modelMatrix : simd_float4x4 , and colour : simd_float4? = nil, updateBB : Bool = false){
        
        if(updateBB){
            let transformedBB = boundingBox!.map(){
                modelMatrix * simd_float4(vec3: $0)
            }
            let sortedX = transformedBB.sorted(by: {$0.x < $1.x})
            let sortedY = transformedBB.sorted(by: {$0.y < $1.y})
            let sortedZ = transformedBB.sorted(by: {$0.z < $1.z})
            boundingBox![0].x = sortedX.first!.x
            boundingBox![1].x = sortedX.last!.x
            boundingBox![0].y = sortedY.first!.y
            boundingBox![1].y = sortedY.last!.y
            boundingBox![0].z = sortedZ.first!.z
            boundingBox![1].z = sortedZ.last!.z
        }
        
     
        no_instances += 1
        
        let translateColumn = modelMatrix.columns.3
        translationInitialState.append(simd_float3(translateColumn.x,translateColumn.y,translateColumn.z))
        
      
//        let normalMatrix = create_normalMatrix(modelViewMatrix: camera.cameraMatrix * modelMatrix)
//
//        let instanceData = InstanceConstants(modelMatrix: modelMatrix, normalMatrix: normalMatrix)
//
//        instanceConstantData.append(instanceData)
        
        instanceModelMatrixData.append(modelMatrix)
            
      
        if let colour = colour{
            instanceColourData.append(colour)
        }
       
        
       
    }
    
    func updateNormalMatrix(with viewMatrix : simd_float4x4){
        
        var ptr = BufferArray[0].buffer.contents().bindMemory(to: InstanceConstants.self, capacity: no_instances)
        
       
        
        for i in 0..<no_instances{
            let normalMatrix = create_normalMatrix(modelViewMatrix: viewMatrix * (ptr + i).pointee.modelMatrix)
            
            (ptr + i).pointee.normalMatrix = normalMatrix
           
        }
        
    }
    
    func init_instance_buffers(with viewMatrix : simd_float4x4){
        if(!(instanceColourData.isEmpty)){
            instanceColourBuffer = device.makeBuffer(bytes: &instanceColourData, length: MemoryLayout<simd_float4>.stride*instanceColourData.count, options: [])
        }
        
        
        
        for modelMatrix in instanceModelMatrixData {
            let normalMatrix = create_normalMatrix(modelViewMatrix: viewMatrix * modelMatrix)
            let instanceData = InstanceConstants(modelMatrix: modelMatrix, normalMatrix: normalMatrix)
            instanceConstantData.append(instanceData)
        }
        
        instaceConstantBuffer = device.makeBuffer(bytes: &instanceConstantData , length: MemoryLayout<InstanceConstants>.stride*instanceConstantData.count, options: [])
        
        
     
        
        let instanceBuffer = UniformBuffer(buffer: instaceConstantBuffer!, index: vertexBufferIDs.instanceConstant)
        
        BufferArray.insert(instanceBuffer, at: 0)
        
        if let instanceColourBuffer = instanceColourBuffer{
            let colourBuffer = UniformBuffer(buffer: instanceColourBuffer, index: vertexBufferIDs.colour)
            BufferArray.append(colourBuffer)
        }
       
        
      
       
      
    }
    
    func addUniformBuffer(buffer : UniformBuffer){
        BufferArray.append(buffer)
    }
    


    
    func updateTexture(with new_texture : Texture){
        for i in 0..<texturesArray.count{
            if(texturesArray[i].index == new_texture.index){
                texturesArray[i] = new_texture
            }
        }
    }
    
//    func draw(renderEncoder : MTLRenderCommandEncoder){
//
//        for buffer in BufferArray {
//            if let function = buffer.functionType {
//                if(function == .fragment){
//                    renderEncoder.setFragmentBuffer(buffer.buffer, offset: 0, index: buffer.index)
//                    continue
//                }
//            }
//            renderEncoder.setVertexBuffer(buffer.buffer, offset: 0, index: buffer.index)
//        }
//        if (!(indexBufferArray.isEmpty)){
//            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
//            for i in 0..<indexBufferArray.count{
//                renderEncoder.setFragmentTexture(texturesArray[i].texture, index: texturesArray[i].index)
//                renderEncoder.setFragmentTexture(texturesArray[i+1].texture, index: texturesArray[i+1].index)
//                let submesh = Mesh!.submeshes[i]
//
//                renderEncoder.setVertexBuffer(instanceBuffer, offset: 0, index: 2)
//                renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: indexBufferArray[i], indexBufferOffset: submesh.indexBuffer.offset)
//            }
//
//            return
//
//        }
//        for texture in texturesArray {
//            renderEncoder.setFragmentTexture(texture.texture, index: texture.index)
//        }
//        if Mesh != nil{
//            let submesh = Mesh!.submeshes[0]
//            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
//            renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: indexBuffer!, indexBufferOffset: submesh.indexBuffer.offset)
//        }
//        else{
//            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
//            renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexData!.count, indexType: .uint16, indexBuffer: indexBuffer!, indexBufferOffset: 0, instanceCount: 1)
//        }
//
//    }
//
    func draw(renderEncoder : MTLRenderCommandEncoder, with instances : Int? = nil, culling : MTLCullMode? = nil){
        
        if(cullFace != nil){
           
            renderEncoder.setCullMode(cullFace!)
        }
        
        else {
            
            renderEncoder.setCullMode(.back)
        }
        
        if let cullMode = culling {
            renderEncoder.setCullMode(cullMode)
        }
        
        for buffer in BufferArray {
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
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            for i in 0..<indexBufferArray.count{
                let submesh = Mesh!.submeshes[i]
                let count = instances ?? no_instances
                renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: indexBufferArray[i], indexBufferOffset: submesh.indexBuffer.offset, instanceCount: count)
            }
           
            return
        }
        else{
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            let count = instances ?? no_instances
            renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexData!.count, indexType: .uint16, indexBuffer: indexBuffer!, indexBufferOffset: 0, instanceCount: count)
        }
    }
    func drawTesselated(renderEncoder : MTLRenderCommandEncoder){

        let commandQueue = device.makeCommandQueue()
        guard let commandBuffer = commandQueue?.makeCommandBuffer() else {return}
        guard let computeEndoer = commandBuffer.makeComputeCommandEncoder() else {return}
        computeEndoer.setComputePipelineState(computePipeLineState!)
        computeEndoer.setBuffer(tesselationFactorBuffer, offset: 0, index: 0)
        computeEndoer.setBuffer(tesselationLevelBuffer, offset: 0, index: 1)
        computeEndoer.dispatchThreadgroups(MTLSize(width: 1,height: 1,depth: 1), threadsPerThreadgroup: MTLSize(width: 1,height: 1,depth: 1))
        computeEndoer.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        for buffer in BufferArray {
            if let function = buffer.functionType {
                if(function == .fragment){
                    renderEncoder.setFragmentBuffer(buffer.buffer, offset: 0, index: buffer.index)
                    continue
                }
            }
            renderEncoder.setVertexBuffer(buffer.buffer, offset: 0, index: buffer.index)
        }
        renderEncoder.setTessellationFactorBuffer(tesselationFactorBuffer, offset: 0, instanceStride: 0)
        if (!(indexBufferArray.isEmpty)){
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            for i in 0..<indexBufferArray.count{
                renderEncoder.setFragmentTexture(texturesArray[i].texture, index: texturesArray[i].index)
                if(has_normal){
                    renderEncoder.setFragmentTexture(NormalTextureArray[i].texture, index: NormalTextureArray[i].index)
                }
                if(has_displacement){
                    renderEncoder.setVertexTexture(DisplacementTextureArray[i].texture, index:DisplacementTextureArray[i].index )
                }

                let submesh = Mesh!.submeshes[i]

                renderEncoder.drawIndexedPatches(numberOfPatchControlPoints: 3, patchStart: 0, patchCount: submesh.indexCount/3, patchIndexBuffer: nil, patchIndexBufferOffset: 0, controlPointIndexBuffer: indexBufferArray[i], controlPointIndexBufferOffset: 0, instanceCount: 1, baseInstance: 0)

            }

            return

        }
        for texture in texturesArray {
            if(texture.index == textureIDs.Displacement){
                renderEncoder.setVertexTexture(texture.texture, index: textureIDs.Displacement)
            }
            renderEncoder.setFragmentTexture(texture.texture, index: texture.index)
        }
        if Mesh != nil{
            let submesh = Mesh!.submeshes[0]
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: indexBuffer!, indexBufferOffset: submesh.indexBuffer.offset)
        }
        else{
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.drawIndexedPatches(numberOfPatchControlPoints: 3, patchStart: 0, patchCount: indexData!.count/3, patchIndexBuffer: nil, patchIndexBufferOffset: 0, controlPointIndexBuffer: indexBuffer!, controlPointIndexBufferOffset: 0, instanceCount: 1, baseInstance: 0)
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
    
    
    
    init?(_ device : MTLDevice, _ vertexFunctionName : String, _ fragmentFunctionName : String?, _ renderToCube : Bool){
        library = device.makeDefaultLibrary()!
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.vertexFunction = library.makeFunction(name: vertexFunctionName)
        if let fragmentAddress = fragmentFunctionName{
            pipelineDescriptor.fragmentFunction = library.makeFunction(name: fragmentAddress)
        }
       
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
    init?(_ device : MTLDevice, _ vertexFunctionName : String, _ fragmentFunctionName : String?, _ vertexDescriptor : MTLVertexDescriptor,  _ renderToCube : Bool, amplificationCount : Int = 1, functionConstant : MTLFunctionConstantValues? = nil, colourPixelFormat : MTLPixelFormat = .bgra8Unorm_srgb, depthPixelFormat : MTLPixelFormat = .depth32Float, label : String = "nolabel"){
        
        library = device.makeDefaultLibrary()!
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.maxVertexAmplificationCount = amplificationCount
        pipelineDescriptor.colorAttachments[0].pixelFormat = colourPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = depthPixelFormat
        if let functionConstantValues = functionConstant {
            pipelineDescriptor.vertexFunction = try! library.makeFunction(name: vertexFunctionName,constantValues: functionConstantValues)
            if let fragmentAddress = fragmentFunctionName{
                pipelineDescriptor.fragmentFunction = try! library.makeFunction(name: fragmentAddress, constantValues: functionConstantValues)
            }
        }
        else{
            pipelineDescriptor.vertexFunction = library.makeFunction(name: vertexFunctionName)
            if let fragmentAddress = fragmentFunctionName{
                pipelineDescriptor.fragmentFunction = library.makeFunction(name: fragmentAddress)
            }
        }
       
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        if(renderToCube){
            pipelineDescriptor.inputPrimitiveTopology = .triangle
            pipelineDescriptor.rasterSampleCount = 1
        }
        do {
            try m_pipeLine = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            print("PipeLine \(label) Created Successfully")
        }
        catch{
            print("\(label) failed to inittialise")
            print(error)
            return nil
        }
        
    }
    
    init?(_ device : MTLDevice, _ vertexFunctionName : String, _ fragmentFunctionName : String, _ vertexDescriptor : MTLVertexDescriptor, _ functionConstant : MTLFunctionConstantValues, tesselation : Bool = false){

        library = device.makeDefaultLibrary()!
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        if(tesselation){
                    print("Tesselated")
                    pipelineDescriptor.tessellationFactorFormat = .half
                    pipelineDescriptor.tessellationPartitionMode = .integer
                    pipelineDescriptor.tessellationFactorStepFunction = .constant
                    pipelineDescriptor.tessellationOutputWindingOrder = .counterClockwise
                    pipelineDescriptor.tessellationControlPointIndexType = .uint16
            pipelineDescriptor.maxTessellationFactor = 64
            
        }
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
       
            pipelineDescriptor.vertexFunction = try! library.makeFunction(name: vertexFunctionName, constantValues: functionConstant)
            pipelineDescriptor.fragmentFunction = try! library.makeFunction(name: fragmentFunctionName, constantValues: functionConstant)
       
        
        
        

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



