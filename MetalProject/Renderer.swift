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
    var firstPassNodes = [Mesh]()
    var finalPassNodes = [Mesh]()
    var nodesInitialState = [[simd_float3]]()
    var skyBoxfirstPassMesh : Mesh?
    var skyBoxfinalPassMesh : Mesh?
    var reflectiveNodeMesh : Mesh?
    var reflectiveNodeInitialState = [simd_float3]()
    var current_node = 0
    
    
    // pipelines
    var renderToCubePipeline : pipeLine?
    var simplePipeline : pipeLine?
    var renderSkyboxPipeline : pipeLine?
    var renderReflectionPipleline : pipeLine?
    let device : MTLDevice
    
    var renderTarget : Texture?
    var depthRenderTarget : MTLTexture?
    
    var commandQueue : MTLCommandQueue
    var view : MTKView
    var depthStencilState : MTLDepthStencilState
    var sampler : MTLSamplerState
    
    func initiatePipeline(){
        let posAttrib = Attribute(format: .float4, offset: 0, length: 16, bufferIndex: 0)
        let normalAttrib = Attribute(format: .float3, offset: MemoryLayout<Float>.stride*4,length: 12, bufferIndex: 0)
        let texAttrib = Attribute(format: .float2, offset: MemoryLayout<Float>.stride*7, length : 8, bufferIndex: 0)
       
        let instanceAttrib = Attribute(format : .float3, offset: 0, length : 12, bufferIndex: 1)
        let vertexDescriptor = createVertexDescriptor(attributes: posAttrib,normalAttrib,texAttrib)
        
        renderToCubePipeline  = pipeLine(device, "render_to_cube_vertex", "render_to_cube_fragment", vertexDescriptor, true)!
        
        let simplePipelineFC = functionConstant()
        simplePipelineFC.setValue(type: .bool, value: &False)
        simplePipelineFC.setValue(type: .bool, value: &False)
        simplePipelineFC.setValue(type: .bool, value: &True)
        simplePipelineFC.setValue(type: .bool, value: &False)
        simplePipeline = pipeLine(device, "simple_shader_vertex", "simple_shader_fragment", vertexDescriptor, simplePipelineFC.functionConstant)!
        
        
        // this pipeline renders cubemap reflections
        renderReflectionPipleline = pipeLine(device, "cubeMap_reflection_vertex", "cubeMap_reflection_fragment", vertexDescriptor, false)!
        
        
       // this one renders a skybox
        let skyboxFunctionConstants = functionConstant()
        skyboxFunctionConstants.setValue(type: .bool, value: &True, at: 0)
        skyboxFunctionConstants.setValue(type: .bool, value: &False, at: 1)
        skyboxFunctionConstants.setValue(type: .bool, value: &False, at: 2)
        skyboxFunctionConstants.setValue(type: .bool, value: &True, at: 3)
        
        renderSkyboxPipeline = pipeLine(device, "simple_shader_vertex", "simple_shader_fragment", vertexDescriptor, skyboxFunctionConstants.functionConstant)!
        
    }
    
    func initialiseRenderTarget(){
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .bgra8Unorm_srgb
        textureDescriptor.textureType = .typeCube
        textureDescriptor.width = 800
        textureDescriptor.height = 800
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
        self.camera = simd_float4x4(eye: eye, center: direction, up: simd_float3(0,1,0))
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
        samplerDescriptor.magFilter = .nearest
        samplerDescriptor.minFilter = .nearest
        samplerDescriptor.rAddressMode = .clampToEdge
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerDescriptor.normalizedCoordinates = true
        sampler = device.makeSamplerState(descriptor: samplerDescriptor)!
        
        
        
        initiatePipeline()
        initialiseRenderTarget()
    }
    
    
    
   
    
    func addNodes(mesh : MDLMesh, scale : simd_float3, translate : simd_float3, rotation : simd_float3, colour : simd_float4){
        // firest pass nodes are being rendered from the centre of reflection
        
        var initialState = [scale,translate,rotation]
        nodesInitialState.append(initialState)
        firstPassNodes.append(Mesh(device: device, Mesh: mesh)!)
        firstPassNodes[current_node].createAndAddUniformBuffer(bytes: &translateFirst, length: MemoryLayout<Int>.stride, at: vertexBufferIDs.order_of_rot_tran, for: device)
        var firstPassTransformation = createBuffersForRenderToCube(scale: scale, rotation: rotation, translate: translate, from: centreOfReflection)
        firstPassNodes[current_node].createAndAddUniformBuffer(bytes: &firstPassTransformation, length: MemoryLayout<Transforms>.stride*6, at: vertexBufferIDs.uniformBuffers, for: device)
        firstPassNodes[current_node].createAndAddUniformBuffer(bytes: &False, length: 1, at: vertexBufferIDs.skyMap, for: device)
        
        var temp_colour = colour
        firstPassNodes[current_node].createAndAddUniformBuffer(bytes: &temp_colour, length: 16, at: fragmentBufferIDs.colours, for: device, for: .fragment)
        
        // second pass nodes are rendered from the camera with self.projection
        finalPassNodes.append(Mesh(device: device, Mesh: mesh)!)
        
        
        finalPassNodes[current_node].createAndAddUniformBuffer(bytes: &translateFirst, length: MemoryLayout<Int>.stride, at: vertexBufferIDs.order_of_rot_tran, for: device)
        var finalPassTransformation = Transforms(Scale: simd_float4x4(scale: scale), Translate: simd_float4x4(translate: translate), Rotation: simd_float4x4(rotationXYZ: rotation), Projection: projection, Camera: camera)
        finalPassNodes[current_node].createAndAddUniformBuffer(bytes: &finalPassTransformation, length: MemoryLayout<Transforms>.stride, at: vertexBufferIDs.uniformBuffers, for: device)
        finalPassNodes[current_node].createAndAddUniformBuffer(bytes: &False, length: 1, at: vertexBufferIDs.skyMap, for: device)
        finalPassNodes[current_node].createAndAddUniformBuffer(bytes: &temp_colour, length: 16, at: fragmentBufferIDs.colours, for: device, for: .fragment)
        
        for i in 0...2{
            firstPassNodes[current_node].createAndAddUniformBuffer(bytes: &meshFragmentUniforms[i], length: 1, at: 3 + i, for: device, for: .fragment)
           
            finalPassNodes[current_node].createAndAddUniformBuffer(bytes: &meshFragmentUniforms[i], length: 1, at: 3 + i, for: device, for: .fragment)
        }
        current_node += 1
        
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
        
        
    }
    
    func setSkyMapTexture(with texture : Texture){
        skyBoxfirstPassMesh?.updateTexture(with: texture)
        skyBoxfinalPassMesh?.updateTexture(with: texture)
    }
    
    func updateCamera(with camera : simd_float4x4){
        self.camera = camera
        
        var reflectiveMeshTransform = Transforms(Scale: simd_float4x4(scale: reflectiveNodeInitialState[0]), Translate: simd_float4x4(translate: centreOfReflection), Rotation: simd_float4x4(rotationXYZ: reflectiveNodeInitialState[2]), Projection: projection, Camera: camera)
        reflectiveNodeMesh?.createAndAddUniformBuffer(bytes: &reflectiveMeshTransform, length: MemoryLayout<Transforms>.stride, at: vertexBufferIDs.uniformBuffers, for: device)
        print(eye)
        reflectiveNodeMesh?.createAndAddUniformBuffer(bytes: &eye, length: MemoryLayout<simd_float3>.stride, at: vertexBufferIDs.camera_origin, for: device)
        
        var finalPassCamera = self.camera
        finalPassCamera[3] = simd_float4(0,0,0,1)
        var skyBoxfinalPassTransform = Transforms(Scale: simd_float4x4(scale: simd_float3(1)), Translate: simd_float4x4(translate: simd_float3(0)), Rotation: simd_float4x4(rotationXYZ: simd_float3(0)), Projection: projection, Camera: finalPassCamera)
        
        skyBoxfinalPassMesh?.createAndAddUniformBuffer(bytes: &skyBoxfinalPassTransform, length: MemoryLayout<Transforms>.stride, at: vertexBufferIDs.uniformBuffers, for: device)
        
       
        
        for (mesh,state) in zip(finalPassNodes,nodesInitialState){
            var new_transform = Transforms(Scale: simd_float4x4(scale: state[0]), Translate: simd_float4x4(translate: state[1]), Rotation: simd_float4x4(rotationXYZ: state[2]+simd_float3(0,Float(fps)*0.1,0)), Projection: projection, Camera: camera)
            mesh.updateUniformBuffer(with: &new_transform)
        }
        
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
        for (mesh,state) in zip(firstPassNodes,nodesInitialState){
            var new_transform = createBuffersForRenderToCube(scale: state[0], rotation: state[2] + simd_float3(0,Float(fps)*0.1,0), translate: state[1], from: centreOfReflection)
            mesh.updateUniformBuffer(with: &new_transform)
            mesh.draw(renderEncoder: renderEncoder,with: 6)
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
        
        finalRenderEncoder.setRenderPipelineState(renderReflectionPipleline!.m_pipeLine)
        finalRenderEncoder.setDepthStencilState(depthStencilState)
        finalRenderEncoder.setFragmentSamplerState(sampler, index: 0)
        
        finalRenderEncoder.setFrontFacing(.counterClockwise)
        finalRenderEncoder.setCullMode(.back)
        reflectiveNodeMesh?.draw(renderEncoder: finalRenderEncoder)
        
        finalRenderEncoder.setRenderPipelineState(simplePipeline!.m_pipeLine)
        
        for (mesh,state) in zip(finalPassNodes,nodesInitialState){
            var new_transform = Transforms(Scale: simd_float4x4(scale: state[0]), Translate: simd_float4x4(translate: state[1]), Rotation: simd_float4x4(rotationXYZ: state[2]+simd_float3(0,Float(fps)*0.1,0)), Projection: projection, Camera: camera)
            mesh.updateUniformBuffer(with: &new_transform)
            mesh.draw(renderEncoder: finalRenderEncoder)
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
    
    init?(mtkView: MTKView){
      
        
        device = mtkView.device!
        mtkView.preferredFramesPerSecond = 120
        
        commandQueue = device.makeCommandQueue()!
        
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        mtkView.depthStencilPixelFormat = .depth32Float
        
        let cubeTextureOptions: [MTKTextureLoader.Option : Any] = [
          .textureUsage : MTLTextureUsage.shaderRead.rawValue,
          .textureStorageMode : MTLStorageMode.private.rawValue,
          .cubeLayout : MTKTextureLoader.CubeLayout.vertical
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
        
        // set up states of skymap
        
        
        
        currentScene = skyBoxScene(device : device, at : mtkView, from: simd_float3(0,0,-10), eye: simd_float3(0,0,-20), direction : simd_float3(0,0,0), with: simd_float4x4(fovRadians: 3.14/2, aspectRatio: 2, near: 0.1, far: 100))
        
        
            
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
       
        let instanceAttrib = Attribute(format : .float3, offset: 0, length : 12, bufferIndex: 1)
        let vertexDescriptor = createVertexDescriptor(attributes: posAttrib,normalAttrib,texAttrib)
        
        renderToCubePipeline  = pipeLine(device, "render_to_cube_vertex", "render_to_cube_fragment", vertexDescriptor, true)
//        vertexDescriptor.attributes[3].offset = 0
//        vertexDescriptor.attributes[3].format = .float3
//        vertexDescriptor.attributes[3].bufferIndex = 2
//        vertexDescriptor.layouts[2].stride = 12
//        vertexDescriptor.layouts[2].stepFunction = .perInstance
//        vertexDescriptor.layouts[2].stepRate = 1
//
        
        // render a simple cube with colour pipeline
        let simplePipelineFC = functionConstant()
        simplePipelineFC.setValue(type: .bool, value: &False)
        simplePipelineFC.setValue(type: .bool, value: &False)
        simplePipelineFC.setValue(type: .bool, value: &True)
        simplePipelineFC.setValue(type: .bool, value: &False)
        simplePipeline = pipeLine(device, "simple_shader_vertex", "simple_shader_fragment", vertexDescriptor, simplePipelineFC.functionConstant)
        
        
        // this pipeline renders cubemap reflections
        renderCubeMapReflection = pipeLine(device, "cubeMap_reflection_vertex", "cubeMap_reflection_fragment", vertexDescriptor, false)
        
        
       // this one renders a skybox
        let skyboxFunctionConstants = functionConstant()
        skyboxFunctionConstants.setValue(type: .bool, value: &True, at: 0)
        skyboxFunctionConstants.setValue(type: .bool, value: &False, at: 1)
        skyboxFunctionConstants.setValue(type: .bool, value: &False, at: 2)
        skyboxFunctionConstants.setValue(type: .bool, value: &True, at: 3)
        
        skyboxPipeline = pipeLine(device, "simple_shader_vertex", "simple_shader_fragment", vertexDescriptor, skyboxFunctionConstants.functionConstant)
        
        
        
        
        
        let allocator = MTKMeshBufferAllocator(device: device)
        let cubeMDLMesh = MDLMesh(boxWithExtent: simd_float3(1,1,1), segments: simd_uint3(1,1,1), inwardNormals: false, geometryType: .triangles, allocator: allocator)
        let mdlMeshVD = MDLVertexDescriptor()
        mdlMeshVD.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float4, offset: 0, bufferIndex: 0)
        mdlMeshVD.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: 16, bufferIndex: 0)
        mdlMeshVD.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: 28, bufferIndex: 0)
        mdlMeshVD.layouts[0] = MDLVertexBufferLayout(stride: 36)
        cubeMDLMesh.vertexDescriptor = mdlMeshVD
        
        currentScene.addSkyBoxNode(with: Texture(texture: skyboxTexture!, index: textureIDs.cubeMap), mesh: cubeMDLMesh)
        currentScene.addNodes(mesh: cubeMDLMesh, scale: simd_float3(1), translate: simd_float3(0,0,-5), rotation: simd_float3(0), colour: simd_float4(1,0,0,1))
        
        currentScene.addNodes(mesh: cubeMDLMesh, scale: simd_float3(1), translate: simd_float3(-10,0,-10), rotation: simd_float3(0), colour: simd_float4(0,1,1,1))
        currentScene.addReflectiveNode(mesh: cubeMDLMesh, scale: simd_float3(5), rotation: simd_float3(0))
        
        reflectiveCubeMesh = Mesh(device: device, Mesh: cubeMDLMesh)
        cubeMesh = Mesh(device: device, Mesh: cubeMDLMesh)
        skyBoxMesh = Mesh(device: device, Mesh: cubeMDLMesh)
        finalPassSkyBoxMesh = Mesh(device: device, Mesh: cubeMDLMesh)
        finalCubeMesh = Mesh(device: device, Mesh: cubeMDLMesh)
        // these meshes get rendered after rendering to cube pass
        reflectiveCubeMesh?.createAndAddUniformBuffer(bytes: &rotateFirst, length: MemoryLayout<Int>.stride, at: vertexBufferIDs.order_of_rot_tran, for: device)
        
        finalPassSkyBoxMesh?.createAndAddUniformBuffer(bytes: &rotateFirst, length: MemoryLayout<Int>.stride, at: vertexBufferIDs.order_of_rot_tran, for: device)
        
        finalPassSkyBoxMesh?.createAndAddUniformBuffer(bytes: &skyBoxfinalPassTransform, length: MemoryLayout<Transforms>.stride, at: vertexBufferIDs.uniformBuffers, for: device)
        
        finalPassSkyBoxMesh?.createAndAddUniformBuffer(bytes: &True, length: 1, at: vertexBufferIDs.skyMap, for: device)
        
        finalCubeMesh?.createAndAddUniformBuffer(bytes: &translateFirst, length: MemoryLayout<Int>.stride, at: vertexBufferIDs.order_of_rot_tran, for: device)
        
        finalCubeMesh?.createAndAddUniformBuffer(bytes: &False, length: 1, at: vertexBufferIDs.skyMap, for: device)
        
        finalCubeMesh?.createAndAddUniformBuffer(bytes: &cubeFinalPassTransform, length: MemoryLayout<Transforms>.stride, at: vertexBufferIDs.uniformBuffers, for: device)
        
        
        
        cubeMesh?.createAndAddUniformBuffer(bytes: &translateFirst, length: MemoryLayout<Int>.stride, at: vertexBufferIDs.order_of_rot_tran, for: device)
        skyBoxMesh?.createAndAddUniformBuffer(bytes: &rotateFirst, length: MemoryLayout<Int>.stride, at: vertexBufferIDs.order_of_rot_tran, for: device)
        
        cubeMesh?.createAndAddUniformBuffer(bytes: &cubeTransform, length: MemoryLayout<Transforms>.stride*cubeTransform.count, at: vertexBufferIDs.uniformBuffers, for: device)
        skyBoxMesh?.createAndAddUniformBuffer(bytes: &skyBoxTransform, length: MemoryLayout<Transforms>.stride*6, at: vertexBufferIDs.uniformBuffers, for: device)
        
        cubeMesh?.createAndAddUniformBuffer(bytes: &False, length: 1, at: vertexBufferIDs.skyMap, for: device)
        cubeMesh?.createAndAddUniformBuffer(bytes: &Red, length: 16, at: fragmentBufferIDs.colours, for: device, for: .fragment)
        skyBoxMesh?.createAndAddUniformBuffer(bytes: &Red, length: 16, at: fragmentBufferIDs.colours, for: device, for: .fragment)
        skyBoxMesh?.createAndAddUniformBuffer(bytes: &True, length: 1, at: vertexBufferIDs.skyMap, for: device)
        finalCubeMesh?.createAndAddUniformBuffer(bytes: &Red, length: 16, at: fragmentBufferIDs.colours, for: device, for: .fragment)
        
        
        let reflectionTexture = Texture(texture: cubeTexture!, index: textureIDs.cubeMap)
        activeSkyBox = Texture(texture: skyboxTexture!, index: textureIDs.cubeMap)
        
        finalPassSkyBoxMesh?.add_textures(textures: activeSkyBox)
        skyBoxMesh?.add_textures(textures: activeSkyBox)
        reflectiveCubeMesh?.add_textures(textures: reflectionTexture)
        reflectiveCubeMesh?.createAndAddUniformBuffer(bytes: &reflectiveCubeTransform, length: MemoryLayout<Transforms>.stride, at: vertexBufferIDs.uniformBuffers, for: device)
        
        for i in 0...2{
            skyBoxMesh?.createAndAddUniformBuffer(bytes: &skyboxUniforms[i], length: 1, at: 3 + i, for: device, for: .fragment)
            cubeMesh?.createAndAddUniformBuffer(bytes: &cubeUniforms[i], length: 1, at: 3 + i, for: device, for: .fragment)
           // finalPassSkyBoxMesh?.createAndAddUniformBuffer(bytes: &skyboxUniforms[i], length: 1, at: 3 + i, for: device, for: .fragment)
            finalCubeMesh?.createAndAddUniformBuffer(bytes: &cubeUniforms[i], length: 1, at: 3 + i, for: device, for: .fragment)
        }
        
        
        let samplerDC = MTLSamplerDescriptor()
        samplerDC.magFilter = .nearest
        samplerDC.minFilter = .nearest
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
        drawer.renderMeshWithCubeMapReflection = pipeLine(device, "cubeMap_reflection_vertex", "cubeMap_reflection_fragment", vertexDescriptor, false)?.m_pipeLine
        
        
    }
   
    // mtkView will automatically call this function
    // whenever it wants new content to be rendered.
    
    
    func draw(in view: MTKView) {
        
        fps += 1
        
        currentScene.renderScene()
       
//        guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}
//        
//        
//        
//        
//   
//        
//        
//        
//        
//        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {return}
//        renderPassDescriptor.renderTargetArrayLength = 6
// 
//       
//        
//        
//        renderPassDescriptor.colorAttachments[0].storeAction = .store
//        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
//        renderPassDescriptor.colorAttachments[0].texture = cubeTexture
//        renderPassDescriptor.depthAttachment.texture = cubeDepthTexture
//        renderPassDescriptor.depthAttachment.clearDepth = 1.0
//       guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}
//      
//        
//        
//        
//           
//               
//                renderEncoder.setRenderPipelineState(renderToCubePipeline!.m_pipeLine)
//                renderEncoder.setDepthStencilState(depthStencilState)
//                renderEncoder.setFragmentSamplerState(sampler, index: 0)
//                // render other geometry
//                renderEncoder.setFrontFacing(.counterClockwise)
//                renderEncoder.setCullMode(.back)
//                
//                
//                cubeTransform = createBuffersForRenderToCube(scale: simd_float3(1), rotation: simd_float3(0,Float(self.fps)*0.1,0), translate: simd_float3(0,0,-5), from: simd_float3(0,0,-10))
//                cubeMesh?.updateUniformBuffer(with: &cubeTransform)
//                cubeMesh?.draw(renderEncoder: renderEncoder, with: 6)
//                
//            
//        
//        
//        
//        
//        // render the skybox first
//       
//            renderEncoder.setFrontFacing(.counterClockwise)
//            renderEncoder.setCullMode(.front)
//            skyBoxMesh?.draw(renderEncoder: renderEncoder, with: 6)
//           
//
//        renderEncoder.endEncoding()
//        
//      
//        
//        
//        
//        
//        
//        
//        guard let renderPassDescriptor1 = view.currentRenderPassDescriptor else {return}
//        renderPassDescriptor1.colorAttachments[0].storeAction = .store
//        renderPassDescriptor1.colorAttachments[0].loadAction = .clear
//        renderPassDescriptor1.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
//        renderPassDescriptor1.depthAttachment.loadAction = .clear
//        renderPassDescriptor.depthAttachment.clearDepth = 1
//        guard let renderEncoder1 = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor1) else {return}
//
//        
//        renderEncoder1.setRenderPipelineState(renderCubeMapReflection!.m_pipeLine)
//        renderEncoder1.setDepthStencilState(depthStencilState)
//        renderEncoder1.setFragmentSamplerState(sampler, index: 0)
//        renderEncoder1.setFrontFacing(.counterClockwise)
//        renderEncoder1.setCullMode(.back)
//        
//        reflectiveCubeMesh?.draw(renderEncoder: renderEncoder1)
//        
//        cubeFinalPassTransform = Transforms(Scale: simd_float4x4(scale: simd_float3(1)), Translate: simd_float4x4(translate: simd_float3(0,0,-5)), Rotation: simd_float4x4(rotationXYZ: simd_float3(0,Float(self.fps)*0.1,0)), Projection: simd_float4x4(fovRadians: 3.14/2, aspectRatio: 2, near: 0.1, far: 100), Camera: simd_float4x4(eye: simd_float3(0), center: simd_float3(0,0,-1), up: simd_float3(0,1,0)))
//        finalCubeMesh?.updateUniformBuffer(with: &cubeFinalPassTransform)
//        renderEncoder1.setRenderPipelineState(simplePipeline!.m_pipeLine)
//        finalCubeMesh?.draw(renderEncoder: renderEncoder1)
//        
//        renderEncoder1.setRenderPipelineState(skyboxPipeline!.m_pipeLine)
//        renderEncoder1.setFrontFacing(.counterClockwise)
//        renderEncoder1.setCullMode(.front)
//        
//        finalPassSkyBoxMesh?.draw(renderEncoder: renderEncoder1)
//        
//        renderEncoder1.endEncoding()
//        
//       
// 
//        
//        commandBuffer.present(view.currentDrawable!)
//        commandBuffer.commit()
       
    }

    // mtkView will automatically call this function
    // whenever the size of the view changes (such as resizing the window).
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}
