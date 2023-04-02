//
//  Renderer.swift
//  MetalProject
//
//  Created by Sina Dashtebozorgy on 22/12/2022.
//

import Foundation
import Metal
import MetalKit
import AppKit


func create_random_points_in_sphere(for n : Int) -> [simd_float3]{
    
    var output = [simd_float3]()
    for _ in 0..<n{
        let x_r = Float.random(in: 0...1)
        let y_r = Float.random(in: 0...1)
        let z_r = Float.random(in: 0...1)
        let new_v = normalize(simd_float3(x_r,y_r,z_r))
        output.append(new_v)
    }
    return output
}

class drawing_methods {
    var depthStencilState : MTLDepthStencilState?
    var sampler : MTLSamplerState?
    var renderMeshWithColour : MTLRenderPipelineState?
    var renderMeshWithCubeMap : MTLRenderPipelineState?
    var renderMeshWithFlatMap : MTLRenderPipelineState?
    var skyBoxPipeline : MTLRenderPipelineState?
    var renderMeshWithCubeMapReflection : MTLRenderPipelineState?
   
    
    func renderMesh(renderEncoder : MTLRenderCommandEncoder, mesh : Mesh, with colour : inout simd_float4){
        renderEncoder.setRenderPipelineState(renderMeshWithColour!)
        renderEncoder.setDepthStencilState(depthStencilState!)
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setCullMode(.back)
        renderEncoder.setFragmentBytes(&colour , length: MemoryLayout<simd_float4>.stride, index: fragmentBufferIDs.colours)
        mesh.draw(renderEncoder: renderEncoder)
        
    }
    func renderSkyBox(renderEncoder : MTLRenderCommandEncoder, mesh : Mesh, with cubeMap : MTLTexture){
        renderEncoder.setRenderPipelineState(skyBoxPipeline!)
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setCullMode(.front)
        renderEncoder.setFragmentTexture(cubeMap, index: textureIDs.cubeMap)
        renderEncoder.setFragmentSamplerState(sampler, index: 0)
        mesh.draw(renderEncoder: renderEncoder)
    }
    func renderCubeMapReflection(renderEncoder : MTLRenderCommandEncoder, mesh : Mesh, with cubeMap : MTLTexture, instances : Int = 1){
        renderEncoder.setRenderPipelineState(renderMeshWithCubeMapReflection!)
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setCullMode(.back)
        renderEncoder.setFragmentTexture(cubeMap, index: textureIDs.cubeMap)
        renderEncoder.setFragmentSamplerState(sampler, index: 0)
        mesh.draw(renderEncoder: renderEncoder, with: instances )
    }
}



class skyBoxScene {
    var fps = 0
    var translateFirst = 0
    var rotateFirst = 1
    var False = false
    var True = true
    
    var meshFragmentUniforms : [Bool] = [false,false,true]
    var skyBoxFragmentUniforms : [Bool] = [true,false,false]
    
    var centreOfReflection : simd_float3
    var camera : simd_float4x4
    var eye : simd_float3
    var direction : simd_float3
    var projection : simd_float4x4
    var firstPassNodes = [String : Mesh]()
    var finalPassNodes = [String : Mesh]()
    var nodesInitialState = [String : [[simd_float3]]]()
    var nodeCounts = [String : Int]()
    var skyBoxfirstPassMesh : Mesh?
    var skyBoxfinalPassMesh : Mesh?
    var reflectiveNodeMesh : Mesh?
    var reflectiveNodeInitialState = [simd_float3]()
    var current_node = 0
    
    
    // pipelines
    var renderToCubePipeline : pipeLine?
    var simplePipeline : pipeLine?
    var renderSkyboxPipeline : pipeLine?
    var renderReflectionPipleline_noFuzzy : pipeLine?
    var renderReflectionPipleline_Fuzzy : pipeLine?
    let device : MTLDevice
    
    var renderTarget : Texture?
    var depthRenderTarget : MTLTexture?
    
    var commandQueue : MTLCommandQueue
    var view : MTKView
    var depthStencilState : MTLDepthStencilState
    var sampler : MTLSamplerState
    var cameras = [simd_float4x4]()
    var random_vectors_buffer : MTLBuffer?
    var sceneCamera : Camera?
   
    
    func initiatePipeline(){
        let posAttrib = Attribute(format: .float4, offset: 0, length: 16, bufferIndex: 0)
        let normalAttrib = Attribute(format: .float3, offset: MemoryLayout<Float>.stride*4,length: 12, bufferIndex: 0)
        let texAttrib = Attribute(format: .float2, offset: MemoryLayout<Float>.stride*7, length : 8, bufferIndex: 0)
        let tangentAttrib = Attribute(format: .float4, offset: MemoryLayout<Float>.stride*9, length: 16, bufferIndex: 0)
        let bitangentAttrib = Attribute(format: .float4, offset: MemoryLayout<Float>.stride*13, length: 16, bufferIndex: 0)
        
        let instanceAttrib = Attribute(format : .float3, offset: 0, length : 12, bufferIndex: 1)
        let vertexDescriptor = createVertexDescriptor(attributes: posAttrib,normalAttrib,texAttrib,tangentAttrib,bitangentAttrib)
        
        renderToCubePipeline  = pipeLine(device, "render_to_cube_vertex", "render_to_cube_fragment", vertexDescriptor, true)!
        
        let simplePipelineFC = functionConstant()
        simplePipelineFC.setValue(type: .bool, value: &False)
        simplePipelineFC.setValue(type: .bool, value: &False)
        simplePipelineFC.setValue(type: .bool, value: &False)
        simplePipelineFC.setValue(type: .bool, value: &False)
        simplePipelineFC.setValue(type: .bool, value: &False)
        simplePipelineFC.setValue(type: .bool, value: &False)
        simplePipeline = pipeLine(device, "simple_shader_vertex", "simple_shader_fragment", vertexDescriptor, simplePipelineFC.functionConstant)!
        
        
        // this pipeline renders cubemap reflections
        let fuzzy_reflectionFC = functionConstant()
        fuzzy_reflectionFC.setValue(type: .bool, value: &False, at: 4)
//        renderReflectionPipleline = pipeLine(device, "cubeMap_reflection_vertex", "cubeMap_reflection_fragment", vertexDescriptor, false)!
        
        renderReflectionPipleline_noFuzzy = pipeLine(device, "cubeMap_reflection_vertex", "cubeMap_reflection_fragment", vertexDescriptor, fuzzy_reflectionFC.functionConstant)!
        
        
        fuzzy_reflectionFC.setValue(type: .bool, value: &True, at: 4)
        renderReflectionPipleline_Fuzzy = pipeLine(device, "cubeMap_reflection_vertex", "cubeMap_reflection_fragment", vertexDescriptor, fuzzy_reflectionFC.functionConstant)!
        
        // this one renders a skybox
        let skyboxFunctionConstants = functionConstant()
        skyboxFunctionConstants.setValue(type: .bool, value: &True, at: 0)
        skyboxFunctionConstants.setValue(type: .bool, value: &False, at: 1)
        skyboxFunctionConstants.setValue(type: .bool, value: &False, at: 2)
        skyboxFunctionConstants.setValue(type: .bool, value: &True, at: 3)
        skyboxFunctionConstants.setValue(type: .bool, value: &False, at: 5)
        
        renderSkyboxPipeline = pipeLine(device, "simple_shader_vertex", "simple_shader_fragment", vertexDescriptor, skyboxFunctionConstants.functionConstant)!
        
    }
    
    func initialiseRenderTarget(){
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .bgra8Unorm_srgb
        textureDescriptor.textureType = .typeCube
        textureDescriptor.width = 1200
        textureDescriptor.height = 1200
        textureDescriptor.storageMode = .private
        textureDescriptor.usage = [.shaderRead,.renderTarget]
        var renderTargetTexture = device.makeTexture(descriptor: textureDescriptor)
        textureDescriptor.pixelFormat = .depth32Float
        depthRenderTarget = device.makeTexture(descriptor: textureDescriptor)
        renderTarget = Texture(texture: renderTargetTexture!, index: textureIDs.cubeMap)
    }
    
    init(device : MTLDevice, at view : MTKView, from centreOfReflection: simd_float3, eye : simd_float3, direction : simd_float3, with projection : simd_float4x4) {
        self.device = device
        self.centreOfReflection = centreOfReflection
        self.camera = simd_float4x4(eye: eye, center: direction + eye, up: simd_float3(0,1,0))
        self.eye = eye
        self.direction = direction
        self.projection = projection
        commandQueue = device.makeCommandQueue()!
        self.view = view
        
        // make depthstencil state
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilDescriptor.depthCompareFunction = .lessEqual
        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)!
        
        // create a samplerState
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.rAddressMode = .repeat
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
        samplerDescriptor.normalizedCoordinates = True
        sampler = device.makeSamplerState(descriptor: samplerDescriptor)!
        
        random_vectors_buffer = device.makeBuffer(bytes: create_random_points_in_sphere(for: 200), length: MemoryLayout<simd_float3>.stride*200, options: [])
        
        initiatePipeline()
        initialiseRenderTarget()
        
            let camera0 = simd_float4x4(eye: centreOfReflection, center: simd_float3(1,0,0) + centreOfReflection, up: simd_float3(0,-1,0))
        cameras.append(camera0)
        
    
        
        let camera1 = simd_float4x4(eye: centreOfReflection, center: simd_float3(-1,0,0) + centreOfReflection, up: simd_float3(0,-1,0))
        cameras.append(camera1)
        
        let camera2 = simd_float4x4(eye: centreOfReflection, center: simd_float3(0,-1,0) + centreOfReflection, up: simd_float3(0,0,-1))
        cameras.append(camera2)
        
        let camera3 = simd_float4x4(eye: centreOfReflection, center: simd_float3(0,1,0) + centreOfReflection, up: simd_float3(0,0,1))
        cameras.append(camera3)
        
        let camera4 = simd_float4x4(eye: centreOfReflection, center: simd_float3(0,0,1) + centreOfReflection, up: simd_float3(0,-1,0))
        cameras.append(camera4)
        
        let camera5 = simd_float4x4(eye: centreOfReflection, center: simd_float3(0,0,-1) + centreOfReflection, up: simd_float3(0,-1,0))
        cameras.append(camera5)
    }
    
    func attach_camera_to_scene(camera : Camera){
        sceneCamera = camera
    }
    
    
    
    
    func addNodes(with label : String, mesh : MDLMesh, scale : simd_float3, translate : simd_float3, rotation : simd_float3, colour : simd_float4){
        // firest pass nodes are being rendered from the centre of reflection
        
      
        var initialState = [scale,translate,rotation]
        // add initial state to for the correct node
        
        if let _ = nodesInitialState[label], let _ = nodeCounts[label] {
            nodesInitialState[label]?.append(initialState)
            nodeCounts[label]? += 1
        }
        else{
            nodesInitialState[label] = [initialState]
            nodeCounts[label] = 1
        }
        
        
        // if the label exists then update the instance data
        if let _ = firstPassNodes[label]{
            var firstPassTransformation = createBuffersForRenderToCube(scale: scale, rotation: rotation, translate: translate, from: centreOfReflection)
            for i in 0...5{
                firstPassNodes[label]?.createInstance(with: firstPassTransformation[i], and: colour, add: translateFirst)
            }
            
            var finalPassTransformation = Transforms(Scale: simd_float4x4(scale: scale), Translate: simd_float4x4(translate: translate), Rotation: simd_float4x4(rotationXYZ: rotation), Projection: projection, Camera: camera)
            
            finalPassNodes[label]?.createInstance(with: finalPassTransformation, and: colour, add: translateFirst)
//            if sceneCamera != nil {
//                finalPassNodes[label]?.attach_camera_to_mesh(to: sceneCamera!)
//            }
           
            
        }
        else {
            var firstPassTransformation = createBuffersForRenderToCube(scale: scale, rotation: rotation, translate: translate, from: centreOfReflection)
            let firstPassMesh = Mesh(device: device, Mesh: mesh)!
            for i in 0...5{
                firstPassMesh.createInstance(with: firstPassTransformation[i], and: colour, add: translateFirst)
                
            }
            
            
            firstPassMesh.createAndAddUniformBuffer(bytes: &False, length: 1, at: vertexBufferIDs.skyMap, for: device)
            
            for i in 0...2{
                firstPassMesh.createAndAddUniformBuffer(bytes: &meshFragmentUniforms[i], length: 1, at: 3 + i, for: device, for: .fragment)
            }
            firstPassNodes[label] = firstPassMesh
            
            var finalPassTransformation = Transforms(Scale: simd_float4x4(scale: scale), Translate: simd_float4x4(translate: translate), Rotation: simd_float4x4(rotationXYZ: rotation), Projection: projection, Camera: camera)
            let finalPassMesh = Mesh(device: device, Mesh: mesh)!
            
            finalPassMesh.createInstance(with: finalPassTransformation, and: colour, add: translateFirst)
            finalPassMesh.createAndAddUniformBuffer(bytes: &False, length: 1, at: vertexBufferIDs.skyMap, for: device)
            for i in 0...2{
                finalPassMesh.createAndAddUniformBuffer(bytes: &meshFragmentUniforms[i], length: 1, at: 3 + i, for: device, for: .fragment)
            }
            finalPassNodes[label] = finalPassMesh
            
            
        }
        current_node += 1
        
    }
    
    func finalise_nodes_buffers(){
        for mesh in firstPassNodes.values{
            mesh.init_instance_buffers()
            
        }
        for mesh in finalPassNodes.values{
            mesh.init_instance_buffers()
            if let camera = sceneCamera {
                mesh.attach_camera_to_mesh(to: camera)
            }
        }
        if let camera = sceneCamera {
            reflectiveNodeMesh?.attach_camera_to_mesh(to: camera)
            skyBoxfinalPassMesh?.attach_camera_to_mesh(to: camera)
        }
    }
        
        
        
  
    func addSkyBoxNode(with texture : Texture, mesh : MDLMesh){
        
        skyBoxfirstPassMesh = Mesh(device: device, Mesh: mesh)
        skyBoxfinalPassMesh = Mesh(device: device, Mesh: mesh)
        
       
        var skyBoxfirstPassTransform = createBuffersForRenderToCube()
        
        var finalPassCamera = camera
        finalPassCamera[3] = simd_float4(0,0,0,1)
        
        var skyBoxfinalPassTransform = Transforms(Scale: simd_float4x4(scale: simd_float3(1)), Translate: simd_float4x4(translate: simd_float3(0)), Rotation: simd_float4x4(rotationXYZ: simd_float3(0)), Projection: projection, Camera: finalPassCamera)
        
        
        skyBoxfirstPassMesh?.createAndAddUniformBuffer(bytes: &skyBoxfirstPassTransform, length: MemoryLayout<Transforms>.stride*6, at: vertexBufferIDs.uniformBuffers, for: device)
        for i in 0...2{
            skyBoxfirstPassMesh?.createAndAddUniformBuffer(bytes: &skyBoxFragmentUniforms[i], length: 1, at: 3 + i, for: device, for: .fragment)
            skyBoxfirstPassMesh?.createAndAddUniformBuffer(bytes: &skyBoxFragmentUniforms[i], length: 1, at: 3 + i, for: device, for: .fragment)
        }
       
        skyBoxfirstPassMesh?.createAndAddUniformBuffer(bytes: &True, length: 1, at: vertexBufferIDs.skyMap, for: device)
        skyBoxfirstPassMesh?.createAndAddUniformBuffer(bytes: &translateFirst, length: MemoryLayout<Int>.stride, at: vertexBufferIDs.order_of_rot_tran, for: device)
        skyBoxfirstPassMesh?.add_textures(textures: texture)
        
        
        
        
        
        skyBoxfinalPassMesh?.createAndAddUniformBuffer(bytes: &skyBoxfinalPassTransform, length: MemoryLayout<Transforms>.stride, at: vertexBufferIDs.uniformBuffers, for: device)
        skyBoxfinalPassMesh?.createAndAddUniformBuffer(bytes: &True, length: 1, at: vertexBufferIDs.skyMap, for: device)
        skyBoxfinalPassMesh?.createAndAddUniformBuffer(bytes: &rotateFirst, length: MemoryLayout<Int>.stride, at: vertexBufferIDs.order_of_rot_tran, for: device)
        skyBoxfinalPassMesh?.add_textures(textures: texture)
       
        
        
    }
    func addReflectiveNode(mesh : MDLMesh, scale : simd_float3, rotation : simd_float3){
        
        reflectiveNodeInitialState.append(scale)
        reflectiveNodeInitialState.append(centreOfReflection)
        reflectiveNodeInitialState.append(rotation)
        
        reflectiveNodeMesh = Mesh(device: device, Mesh: mesh)
        var reflectiveMeshTransform = Transforms(Scale: simd_float4x4(scale: scale), Translate: simd_float4x4(translate: centreOfReflection), Rotation: simd_float4x4(rotationXYZ: rotation), Projection: projection, Camera: camera)
        reflectiveNodeMesh?.createAndAddUniformBuffer(bytes: &reflectiveMeshTransform, length: MemoryLayout<Transforms>.stride, at: vertexBufferIDs.uniformBuffers, for: device)
        reflectiveNodeMesh?.createAndAddUniformBuffer(bytes: &rotateFirst, length: MemoryLayout<Int>.stride, at: vertexBufferIDs.order_of_rot_tran, for: device)
        reflectiveNodeMesh?.add_textures(textures: renderTarget!)
       // var eye = -simd_float3(self.camera[3].x,self.camera[3].y,self.camera[3].z)
        reflectiveNodeMesh?.createAndAddUniformBuffer(bytes: &eye, length: MemoryLayout<simd_float3>.stride, at: vertexBufferIDs.camera_origin, for: device)
        
//        if sceneCamera != nil {
//            reflectiveNodeMesh?.attach_camera_to_mesh(to: sceneCamera!)
//        }
    }
    
    func setSkyMapTexture(with texture : Texture){
        skyBoxfirstPassMesh?.updateTexture(with: texture)
        skyBoxfinalPassMesh?.updateTexture(with: texture)
    }
    

    
    func renderScene(){
        
        fps += 1
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {return}
        renderPassDescriptor.colorAttachments[0].texture = renderTarget?.texture
        renderPassDescriptor.depthAttachment.texture = depthRenderTarget!
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].loadAction = .dontCare
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.clearDepth = 1
        renderPassDescriptor.renderTargetArrayLength = 6
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}
        renderEncoder.setRenderPipelineState(renderToCubePipeline!.m_pipeLine)
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setFragmentSamplerState(sampler, index: 0)
        
        // render nodes
        renderEncoder.setCullMode(.back)
        renderEncoder.setFrontFacing(.counterClockwise)

        
        for (label,mesh) in firstPassNodes {
            
            let states = nodesInitialState[label]!
            let totalStetesCount = states.count

                            
                            for i in 0..<totalStetesCount{
                                    let state = states[i]
                                    var new_transform = createBuffersForRenderToCube(scale: state[0], rotation: state[2] + simd_float3(0,Float(fps)*0.1,0), translate: state[1], from: cameras)
                                    firstPassNodes[label]?.updateUniformBuffer(with: &new_transform, at: i)

                                    var new_transformFinalPass = Transforms(Scale: simd_float4x4(scale: state[0]), Translate: simd_float4x4(translate: state[1]), Rotation: simd_float4x4(rotationXYZ: state[2]+simd_float3(0,Float(fps)*0.1,0)), Projection: projection, Camera: camera)
                                    finalPassNodes[label]?.updateUniformBuffer(with: &new_transformFinalPass, at: i)
                            }
//
               
                                let count = nodeCounts[label]!
                                mesh.draw(renderEncoder: renderEncoder, with: 6*count)
            
        }
        
        // render skybox
        
        renderEncoder.setCullMode(.front)
        skyBoxfirstPassMesh?.draw(renderEncoder: renderEncoder,with: 6)
        
        renderEncoder.endEncoding()
        
        
        guard let finalRenderPassDescriptor = view.currentRenderPassDescriptor else {return}
        finalRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
        finalRenderPassDescriptor.depthAttachment.clearDepth = 1
        finalRenderPassDescriptor.depthAttachment.loadAction = .clear
        
        guard let finalRenderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalRenderPassDescriptor) else {return}
        
        finalRenderEncoder.setRenderPipelineState(renderReflectionPipleline_noFuzzy!.m_pipeLine)
        finalRenderEncoder.setDepthStencilState(depthStencilState)
        finalRenderEncoder.setFragmentSamplerState(sampler, index: 0)
        finalRenderEncoder.setFragmentBuffer(random_vectors_buffer, offset: 0, index: vertexBufferIDs.points_in_sphere)
        finalRenderEncoder.setFrontFacing(.counterClockwise)
        finalRenderEncoder.setCullMode(.back)
        var eye = sceneCamera?.eye
        reflectiveNodeMesh?.createAndAddUniformBuffer(bytes: &eye, length: MemoryLayout<simd_float3>.stride, at: vertexBufferIDs.camera_origin, for: device)
        reflectiveNodeMesh?.draw(renderEncoder: finalRenderEncoder)
        
        finalRenderEncoder.setRenderPipelineState(simplePipeline!.m_pipeLine)

        
       
        for (label,mesh) in finalPassNodes {
            
 
           
                let count = nodeCounts[label]!
                 mesh.draw(renderEncoder: finalRenderEncoder, with: count)
 
        }
        
        finalRenderEncoder.setRenderPipelineState(renderSkyboxPipeline!.m_pipeLine)
        finalRenderEncoder.setCullMode(.front)
        skyBoxfinalPassMesh?.draw(renderEncoder: finalRenderEncoder)
        
        finalRenderEncoder.endEncoding()
        
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
                
        
        
    }
}





class Renderer : NSObject, MTKViewDelegate {
    
    var testCamera : Camera
    let testPipeline : pipeLine?
    var testMesh : Mesh?
    
    var skymapChanged = false {
        didSet {
            currentScene.setSkyMapTexture(with: activeSkyBox)
            skymapChanged = false
        }
    }
    
    var True = true
    var False = false
    var drawer = drawing_methods()
    var fps = 0
    var sampler : MTLSamplerState?
    var depthStencilState : MTLDepthStencilState?
    var rotateFirst = transformation_mode.rotate_first
    var translateFirst = transformation_mode.translate_first
                        
    
    
    var reflectiveCubeTransform : Transforms
    
    var currentScene : skyBoxScene
    var cubeTransform = createBuffersForRenderToCube(scale: simd_float3(1), rotation: simd_float3(0), translate: simd_float3(0,0,-5), from: simd_float3(0,0,-10))
    
    var skyBoxTransform = createBuffersForRenderToCube()
    
    // this is transformation for a regular skybox
    var skyBoxfinalPassTransform : Transforms
    
    var cubeFinalPassTransform : Transforms
    
    var finalPassSkyBoxMesh : Mesh?
    var finalCubeMesh : Mesh?
   
    let device: MTLDevice
    let commandQueue : MTLCommandQueue
    var simplePipeline : pipeLine?
    var renderToCubePipeline : pipeLine?
    var skyboxPipeline : pipeLine?
    var renderCubeMapReflection : pipeLine?
    var skyboxTexture : MTLTexture?
    var skyboxTexture1 : MTLTexture?
    var activeSkyBox : Texture
    var cubeMesh : Mesh?
    var skyBoxMesh : Mesh?
    var reflectiveCubeMesh : Mesh?
    var Red : simd_float4 = simd_float4(1,0,0,1)
    let planeData : [Float] = [ -1, -1, 0, 1, 0,0,1, 0,0,
                                 1, -1, 0, 1, 0,0,1, 1,0,
                                 1, 1, 0, 1,  0,0,1, 1,1,
                                 -1, 1, 0,1,  0,0,1, 0,1
    ]
    let planeIndices : [UInt16] = [ 0, 1, 2,
                                    0, 2, 3
    ]
    var planeVerticesBuffer : MTLBuffer?
    var planeIndicesBuffer : MTLBuffer?
   
    
    var cubeTexture : MTLTexture?
    var cubeDepthTexture : MTLTexture?
    
    let testInstanceData : [Float] = [ -3,-3,-2,
                                        0,0,0,
                                        4,4,-4,
    ]
    
    var skyboxUniforms : [Bool] = [true,false,false]
    var cubeUniforms : [Bool] = [false,false,true]
    
    var flatTexture : MTLTexture?
    var flatTextureDepth : MTLTexture?
    
    var testMeshes = [Mesh]()
    var BrickWallTextureN : MTLTexture?
    var BrickWallTextureD : MTLTexture?
    var BrickWallTextureH : MTLTexture?
    var Spot : Mesh?
    var alleyMesh : Mesh?
    var cameraLists = [Camera]()
    var testAlley : Mesh?
    
    var tesselationPipelineState : MTLRenderPipelineState
    var tesselateWall : Mesh?
    var FlowerImage : MTLTexture?
    
    
   
    var wallVB : [Float] = [
        -1,-1,0,1, 0,0,1, 0,0, 1,0,0,1, 0,1,0,1,
         -1,1,0,1, 0,0,1, 0,1, 1,0,0,1, 0,1,0,1,
         1,1,0,1, 0,0,1, 1,1, 1,0,0,1, 0,1,0,1,
         1,-1,0,1, 0,0,1, 1,0, 1,0,0,1, 01,0,1
    ]
    var wallIB : [uint32] = [
        0,1,2,
        0,2,3
    ]
    
    var wallBuffer : MTLBuffer?
    var wallIndex : MTLBuffer?
    var computePipeLineState : MTLComputePipelineState?
    var tesselationFactorBuffer : MTLBuffer?
    var tesselationLevelBuffer : MTLBuffer?
    var spotCamera : Camera?
    var wallCamera : Camera?
    
    
    init?(mtkView: MTKView){
      
       
        let rotate = simd_float4x4(rotationX: 90)
        print(rotate*simd_float4(-1,0,-1,1))
        
        device = mtkView.device!
        mtkView.preferredFramesPerSecond = 120
        
        commandQueue = device.makeCommandQueue()!
        
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        mtkView.depthStencilPixelFormat = .depth32Float
        
        let cubeTextureOptions: [MTKTextureLoader.Option : Any] = [
          .textureUsage : MTLTextureUsage.shaderRead.rawValue,
          .textureStorageMode : MTLStorageMode.private.rawValue,
          .cubeLayout : MTKTextureLoader.CubeLayout.vertical,
          
        ]
        let flatTextureLoaderOptions : [MTKTextureLoader.Option : Any] = [
            .textureUsage : MTLTextureUsage.shaderRead.rawValue,
            .textureStorageMode : MTLStorageMode.private.rawValue,
            .origin : MTKTextureLoader.Origin.bottomLeft.rawValue,
           
                
        ]
        
        let textureLoader = MTKTextureLoader(device: device)
        
        do {
            try skyboxTexture = textureLoader.newTexture(name: "SkyMap", scaleFactor: 1.0, bundle: nil,options: cubeTextureOptions)
            try skyboxTexture1 = textureLoader.newTexture(name : "SkyMap1", scaleFactor : 1.0, bundle : nil, options: cubeTextureOptions)
            print("skybox Texture loaded")
        }
        catch{
            print("skybox Texture failed to load")
            print(error)
        }
        
        
        do {
           
            try BrickWallTextureD = textureLoader.newTexture(name: "BrickWallD", scaleFactor: 1.0, bundle: nil, options: flatTextureLoaderOptions)
            try BrickWallTextureH = textureLoader.newTexture(name: "BrickWallH", scaleFactor: 1.0, bundle: nil)
            try FlowerImage = textureLoader.newTexture(name: "Flower", scaleFactor: 1.0, bundle: nil, options: flatTextureLoaderOptions)
            print("Brick wall texture loaded")
            let flatTextureLoaderOptions : [MTKTextureLoader.Option : Any] = [
                .textureUsage : MTLTextureUsage.shaderRead.rawValue,
                .textureStorageMode : MTLStorageMode.private.rawValue,
                .origin : MTKTextureLoader.Origin.bottomLeft.rawValue,
                .SRGB : False
                    
            ]
            try BrickWallTextureN = textureLoader.newTexture(name: "BrickWallN", scaleFactor: 1.0, bundle: nil, options: flatTextureLoaderOptions)
        }
        catch{
            print("Failed to load brickwall texture")
            print("erro")
        }
        // set up states of skymap
        
        
        testCamera = Camera(for : mtkView, eye: simd_float3(0,0,10), centre: simd_float3(0,0,-1))
        currentScene = skyBoxScene(device : device, at : mtkView, from: simd_float3(0,0,0), eye: simd_float3(0,0,10), direction : simd_float3(0,0,-1), with: simd_float4x4(fovRadians: 3.14/2, aspectRatio: 2, near: 0.1, far: 100))
        currentScene.attach_camera_to_scene(camera: testCamera)
        
            
            reflectiveCubeTransform = Transforms(Scale: simd_float4x4(scale: simd_float3(5)), Translate: simd_float4x4(translate: currentScene.centreOfReflection), Rotation: simd_float4x4(rotationXYZ: simd_float3(0)), Projection: currentScene.projection, Camera: currentScene.camera)
            
        skyBoxfinalPassTransform = Transforms(Scale: simd_float4x4(scale: simd_float3(1)), Translate: simd_float4x4(translate: simd_float3(0,0,0)), Rotation: simd_float4x4(rotationXYZ: simd_float3(0)), Projection: currentScene.projection, Camera: currentScene.camera)
            
            cubeFinalPassTransform = Transforms(Scale: simd_float4x4(scale: simd_float3(1)), Translate: simd_float4x4(translate: simd_float3(0,0,-5)), Rotation: simd_float4x4(rotationXYZ: simd_float3(0)), Projection: currentScene.projection, Camera: currentScene.camera)
        
        
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .bgra8Unorm_srgb
        textureDescriptor.textureType = .typeCube
        textureDescriptor.width = 800
        textureDescriptor.height = 800
        textureDescriptor.storageMode = .private
        textureDescriptor.usage = [.shaderRead,.renderTarget]
        cubeTexture = device.makeTexture(descriptor: textureDescriptor)
        textureDescriptor.pixelFormat = .depth32Float
        cubeDepthTexture = device.makeTexture(descriptor: textureDescriptor)
        textureDescriptor.textureType = .type2D
        textureDescriptor.pixelFormat = .bgra8Unorm
        flatTexture = device.makeTexture(descriptor: textureDescriptor)
        textureDescriptor.pixelFormat = .depth32Float
        flatTextureDepth = device.makeTexture(descriptor: textureDescriptor)
        
        planeVerticesBuffer = device.makeBuffer(bytes: planeData, length: MemoryLayout<Float>.stride*9*4, options: [])
        planeIndicesBuffer = device.makeBuffer(bytes: planeIndices, length: MemoryLayout<UInt16>.stride*6, options: [])
        let posAttrib = Attribute(format: .float4, offset: 0, length: 16, bufferIndex: 0)
        let normalAttrib = Attribute(format: .float3, offset: MemoryLayout<Float>.stride*4,length: 12, bufferIndex: 0)
        let texAttrib = Attribute(format: .float2, offset: MemoryLayout<Float>.stride*7, length : 8, bufferIndex: 0)
        let tangentAttrib = Attribute(format: .float4, offset: MemoryLayout<Float>.stride*9, length : 16, bufferIndex: 0)
        let bitangentAttrib = Attribute(format: .float4, offset: MemoryLayout<Float>.stride*13, length : 16, bufferIndex: 0)
       
        let instanceAttrib = Attribute(format : .float3, offset: 0, length : 12, bufferIndex: 1)
        let vertexDescriptor = createVertexDescriptor(attributes: posAttrib,normalAttrib,texAttrib,tangentAttrib,bitangentAttrib)
        
        renderToCubePipeline  = pipeLine(device, "render_to_cube_vertex", "render_to_cube_fragment", vertexDescriptor, true)

        
        // render a simple cube with colour pipeline
        let simplePipelineFC = functionConstant()
        simplePipelineFC.setValue(type: .bool, value: &False)
        simplePipelineFC.setValue(type: .bool, value: &False)
        simplePipelineFC.setValue(type: .bool, value: &True)
        simplePipelineFC.setValue(type: .bool, value: &False)
        simplePipelineFC.setValue(type: .bool, value: &False, at: 5)
        simplePipeline = pipeLine(device, "simple_shader_vertex", "simple_shader_fragment", vertexDescriptor, simplePipelineFC.functionConstant)
        

        
        let allocator = MTKMeshBufferAllocator(device: device)
        let planeMDLMesh = MDLMesh(planeWithExtent: simd_float3(1,1,1), segments: simd_uint2(1,1), geometryType: .triangles, allocator: allocator)
        let cubeMDLMesh = MDLMesh(boxWithExtent: simd_float3(1,1,1), segments: simd_uint3(1,1,1), inwardNormals: false, geometryType: .triangles, allocator: allocator)
        let circleMDLMesh = MDLMesh(sphereWithExtent: simd_float3(1,1,1), segments: simd_uint2(20,20), inwardNormals: False, geometryType: .triangles, allocator: allocator)
        let coneMDLMesh = MDLMesh(coneWithExtent: simd_float3(1,1,1), segments: simd_uint2(100,100), inwardNormals: False, cap: False, geometryType: .triangles, allocator: allocator)
       
//        cubeMDLMesh.vertexDescriptor = mdlMeshVD
//        circleMDLMesh.vertexDescriptor = mdlMeshVD
//        planeMDLMesh.vertexDescriptor = mdlMeshVD
//        coneMDLMesh.vertexDescriptor = mdlMeshVD
        
        currentScene.addSkyBoxNode(with: Texture(texture: skyboxTexture!, index: textureIDs.cubeMap), mesh: cubeMDLMesh)
        let c_r = Float.random(in: 0...1)
                   let c_g = Float.random(in: 0...1)
                    let c_b = Float.random(in: 0...1)
//        currentScene.addNodes(with : "Circle", mesh: circleMDLMesh, scale: simd_float3(1), translate: simd_float3(7,0,0), rotation: simd_float3(0), colour: simd_float4(c_r,c_g,c_b,1))
        
        for i in 0...6000{
            let x_r = Float.random(in: -20...20)
            let y_r = Float.random(in: -20...20)
            let z_r = Float.random(in: -20...20)

            let c_r = Float.random(in: 0...1)
            let c_g = Float.random(in: 0...1)
            let c_b = Float.random(in: 0...1)
            let scale = Float.random(in: 0.1...1)

            if(i < 3001){
                currentScene.addNodes(with : "Cube", mesh: cubeMDLMesh, scale: simd_float3(scale), translate: simd_float3(x_r,y_r,z_r), rotation: simd_float3(0), colour: simd_float4(c_r,c_g,c_b,1))
            }
            else {
                currentScene.addNodes(with : "Circle", mesh: circleMDLMesh, scale: simd_float3(scale), translate: simd_float3(x_r,y_r,z_r), rotation: simd_float3(0), colour: simd_float4(c_r,c_g,c_b,1))
            }
//
       }
        //print(currentScene.nodeCounts)
//        currentScene.addNodes(with : "Cube", mesh: cubeMDLMesh, scale: simd_float3(1), translate: simd_float3(10,0,0), rotation: simd_float3(0), colour: simd_float4(1,0,0,1))
//
//        currentScene.addNodes(with : "Cube", mesh: cubeMDLMesh, scale: simd_float3(1), translate: simd_float3(-10,0,0), rotation: simd_float3(0), colour: simd_float4(0,1,1,1))
        currentScene.addReflectiveNode(mesh: circleMDLMesh, scale: simd_float3(5), rotation: simd_float3(0))
        
        currentScene.finalise_nodes_buffers()
        

       
       
        let reflectionTexture = Texture(texture: cubeTexture!, index: textureIDs.cubeMap)
        activeSkyBox = Texture(texture: skyboxTexture!, index: textureIDs.cubeMap)
        
      
        let samplerDC = MTLSamplerDescriptor()
        samplerDC.magFilter = .linear
        samplerDC.minFilter = .linear
        samplerDC.rAddressMode = .clampToEdge
        samplerDC.sAddressMode = .clampToEdge
        samplerDC.tAddressMode = .clampToEdge
        samplerDC.normalizedCoordinates = true
        
        sampler = device.makeSamplerState(descriptor: samplerDC)!
        
        let depthState = MTLDepthStencilDescriptor()
        depthState.depthCompareFunction = .lessEqual
        depthState.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthState)
        
        drawer.skyBoxPipeline = skyboxPipeline?.m_pipeLine
        drawer.renderMeshWithColour = simplePipeline?.m_pipeLine
        drawer.depthStencilState = depthStencilState
        drawer.sampler = sampler

        let testFCs = functionConstant()
        testFCs.setValue(type: .bool, value: &False, at: FunctionConstantValues.cube)
        testFCs.setValue(type: .bool, value: &False, at: FunctionConstantValues.flat)
        testFCs.setValue(type: .bool, value: &True, at: FunctionConstantValues.constant_colour)
        testFCs.setValue(type: .bool, value: &False, at: FunctionConstantValues.is_skyBox)
        testFCs.setValue(type: .bool, value: &False, at: FunctionConstantValues.has_normalMap)
        testFCs.setValue(type: .bool, value: &False, at: FunctionConstantValues.has_displacementMap)
        testPipeline = pipeLine(device, "simple_shader_vertex", "simple_shader_fragment", vertexDescriptor, testFCs.functionConstant)
        
        
        testMesh = Mesh(device: device, Mesh: cubeMDLMesh)
        var transform = Transforms(Scale: simd_float4x4(scale: simd_float3(1)), Translate: simd_float4x4(translate: simd_float3(0,0,-10)), Rotation: simd_float4x4(rotationXYZ: simd_float3(45,-45,0)), Projection: simd_float4x4(fovRadians: 3.14/2, aspectRatio: 2, near: 0.1, far: 100), Camera: simd_float4x4(eye: simd_float3(0,0,0), center: simd_float3(0,0,-1), up: simd_float3(0,1,0)))
     
//        testMesh?.createInstance(with: transform, and: simd_float4(1,0,0,1), add: rotateFirst)
//
//        testMesh?.init_instance_buffers()
//        testMesh?.attach_camera_to_mesh(to: testCamera)
//        testMesh?.add_textures(textures: Texture(texture: BrickWallTextureN!, index: textureIDs.Normal))
//        testMesh?.add_textures(textures: Texture(texture: BrickWallTextureD!, index: textureIDs.flat))
//        cameraLists.append(testCamera)
//
//
//        let alleyURL = Bundle.main.url(forResource: "alley", withExtension: "obj")
//        let spotURL = Bundle.main.url(forResource: "spot_triangulated", withExtension: "obj")
//        spotCamera = Camera(for: mtkView, eye: simd_float3(0,0,0), centre: simd_float3(0,0,-1))
//        cameraLists.append(spotCamera!)
//
//
//        alleyMesh?.attach_camera_to_mesh(to: spotCamera!)
//        testAlley = Mesh(device: device, address: alleyURL!, with: "Alley Test Mesh")
//        testAlley?.createInstance(with: transform, and: simd_float4(0,0,0,1), add: rotateFirst)
//
//        testAlley?.init_instance_buffers()
//        testAlley?.attach_camera_to_mesh(to: spotCamera!)
//
//        Spot = Mesh(device: device, address: alleyURL!, with: "Spot Mesh")
//        Spot?.createAndAddUniformBuffer(bytes: &transform, length: MemoryLayout<Transforms>.stride, at: vertexBufferIDs.uniformBuffers, for: device)
//        Spot?.createAndAddUniformBuffer(bytes: &rotateFirst, length: MemoryLayout<Int>.stride, at: vertexBufferIDs.order_of_rot_tran, for: device)
//        Spot?.createAndAddUniformBuffer(bytes: &Red, length: 16, at: vertexBufferIDs.colour, for: device)
//        Spot?.attach_camera_to_mesh(to: spotCamera!)
//
//        vertexDescriptor.layouts[0].stepRate = 1
//        vertexDescriptor.layouts[0].stepFunction = .perPatchControlPoint
//        let library = device.makeDefaultLibrary()!
//
//        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
//
//               renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
//
//               renderPipelineDescriptor.tessellationFactorFormat = .half
//               renderPipelineDescriptor.tessellationPartitionMode = .integer
//               renderPipelineDescriptor.tessellationFactorStepFunction = .constant
//               renderPipelineDescriptor.tessellationOutputWindingOrder = .counterClockwise
//               renderPipelineDescriptor.tessellationControlPointIndexType = .uint32
//        renderPipelineDescriptor.maxTessellationFactor = 64
//
//               renderPipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
//               renderPipelineDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
//
//        renderPipelineDescriptor.vertexFunction = try! library.makeFunction(name: "post_tesselation_tri",constantValues: testFCs.functionConstant)
//        renderPipelineDescriptor.fragmentFunction = try! library.makeFunction(name: "simple_shader_fragment",constantValues: testFCs.functionConstant)
//
//               do {
//                   tesselationPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
//               } catch {
//                   fatalError("Unable to create render pipeline state: \(error)")
//               }
//        print("Tesselation pipeline created successfully")
//
//
//        var tesselatedWallCamera = Camera(for: mtkView, eye: simd_float3(0,5,0), centre: simd_float3(0,0,-20))
//        var tesselatedWallTransform = Transforms(Scale: simd_float4x4(scale: simd_float3(1)), Translate: simd_float4x4(translate: simd_float3(0,10,-10)), Rotation: simd_float4x4(rotationXYZ: simd_float3(90,0,0)), Projection: simd_float4x4(fovRadians: 3.14/2, aspectRatio: 2.0, near: 0.1, far: 100), Camera: tesselatedWallCamera.get_camera_matrix())
//        tesselateWall = Mesh(device: device, address: alleyURL!, with: "Tesselated Mesh Created", with: 64)
//        tesselateWall?.createAndAddUniformBuffer(bytes: &tesselatedWallTransform, length: MemoryLayout<Transforms>.stride, at: vertexBufferIDs.uniformBuffers, for: device)
//        tesselateWall?.createAndAddUniformBuffer(bytes: &rotateFirst, length: MemoryLayout<Int>.stride, at: vertexBufferIDs.order_of_rot_tran, for: device)
//        tesselateWall?.createAndAddUniformBuffer(bytes: &Red, length: 16, at: vertexBufferIDs.colour, for: device)
//        tesselateWall?.attach_camera_to_mesh(to: tesselatedWallCamera)
//        cameraLists.append(tesselatedWallCamera)
//
//
//
//        wallBuffer = device.makeBuffer(bytes: &wallVB, length: MemoryLayout<Float>.stride*17*4, options: [])
//        wallIndex = device.makeBuffer(bytes: &wallIB, length: MemoryLayout<uint32>.stride*6,options: [])
//        wallCamera = Camera(for: mtkView, eye: simd_float3(0,8,0), centre: simd_float3(0,0,-20))
//        cameraLists.append(wallCamera!)
//
//        let computeFunction = library.makeFunction(name: "tess_factor_tri")
//        if(computeFunction == nil){
//            print("Kernel function does not exist")
//        }
//        else {
//            print("Kernel function found and loaded")
//        }
//         do {
//             computePipeLineState = try device.makeComputePipelineState(function: computeFunction!) }
//        catch{
//            return nil
//        }
//
//        tesselationFactorBuffer = device.makeBuffer(length: MemoryLayout<MTLTriangleTessellationFactorsHalf>.stride,options: .storageModePrivate)
//        var level : Int = 64
//        tesselationLevelBuffer = device.makeBuffer(bytes: &level, length: MemoryLayout<Int>.stride, options: [])
//
//
//
//
    }
   
    // mtkView will automatically call this function
    // whenever it wants new content to be rendered.
   
    
    
    func draw(in view: MTKView) {
        
        fps += 1
  
       // currentScene.renderScene()

        var transform = Transforms(Scale: simd_float4x4(scale: simd_float3(8)), Translate: simd_float4x4(translate: simd_float3(0,0,-20)), Rotation: simd_float4x4(rotationXYZ: simd_float3(-90,Float(0)*0.1,0)), Projection: simd_float4x4(fovRadians: 3.14/2, aspectRatio: 2, near: 0.1, far: 100), Camera: wallCamera!.get_camera_matrix())

        guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}


        guard let computecommandBuffer = commandQueue.makeCommandBuffer() else {return}
        guard let computeEndoer = computecommandBuffer.makeComputeCommandEncoder() else {return}
        computeEndoer.setComputePipelineState(computePipeLineState!)
        computeEndoer.setBuffer(tesselationFactorBuffer, offset: 0, index: 0)
        computeEndoer.setBuffer(tesselationLevelBuffer, offset: 0, index: 1)
        computeEndoer.dispatchThreadgroups(MTLSize(width: 1,height: 1,depth: 1), threadsPerThreadgroup: MTLSize(width: 1,height: 1,depth: 1))
        computeEndoer.endEncoding()
        computecommandBuffer.commit()
        computecommandBuffer.waitUntilCompleted()


        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {return}
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
        renderPassDescriptor.depthAttachment.clearDepth = 1
        renderPassDescriptor.depthAttachment.loadAction = .clear

        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}


        renderEncoder.setRenderPipelineState(tesselationPipelineState)
        renderEncoder.setDepthStencilState(depthStencilState)

        renderEncoder.setFragmentSamplerState(sampler, index: 0)
        //renderEncoder.setTriangleFillMode(.lines)
        var colour = simd_float4(1,1,0,1);
        renderEncoder.setFragmentBytes(&colour, length: 16, index: fragmentBufferIDs.colours)
        renderEncoder.setVertexBytes(&colour, length: 16, index: vertexBufferIDs.colour)
        var camera = simd_float4(wallCamera!.eye,1)
        print(camera)
        let buffer = device.makeBuffer(bytes: &camera, length: 16)
        renderEncoder.setFragmentBytes(&camera, length: MemoryLayout<simd_float4>.stride, index: 10)
        //renderEncoder.setFragmentBuffer(buffer, offset: 0, index: 10)
        renderEncoder.setVertexSamplerState(sampler, index: 0)
        renderEncoder.setVertexBuffer(wallBuffer, offset: 0, index: vertexBufferIDs.vertexBuffers)
        renderEncoder.setVertexBytes(&transform, length: MemoryLayout<Transforms>.stride, index: vertexBufferIDs.uniformBuffers)
        renderEncoder.setVertexBytes(&rotateFirst, length: MemoryLayout<Int>.stride, index: vertexBufferIDs.order_of_rot_tran)
        renderEncoder.setTessellationFactorBuffer(tesselationFactorBuffer, offset: 0, instanceStride: 0)
        renderEncoder.setFragmentTexture(BrickWallTextureD, index: textureIDs.flat)
        renderEncoder.setFragmentTexture(BrickWallTextureN, index: textureIDs.Normal)
        renderEncoder.setVertexTexture(BrickWallTextureH, index: textureIDs.Displacement)
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setCullMode(.back)
        //tesselateWall?.drawTesselated(renderEncoder: renderEncoder)
//        tesselateWall?.drawTesselated(renderEncoder: renderEncoder)
  //     renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: 6, indexType: .uint32, indexBuffer: wallIndex!, indexBufferOffset: 0, instanceCount: 1)

        renderEncoder.drawIndexedPatches(numberOfPatchControlPoints: 3, patchStart: 0, patchCount: 2, patchIndexBuffer: nil, patchIndexBufferOffset: 0, controlPointIndexBuffer: wallIndex!, controlPointIndexBufferOffset: 0, instanceCount: 1, baseInstance: 0)

        renderEncoder.endEncoding()

        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
       
    }

    // mtkView will automatically call this function
    // whenever the size of the view changes (such as resizing the window).
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}
