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


//func create_random_points_in_sphere(for n : Int) -> [simd_float3]{
//
//    var output = [simd_float3]()
//    for _ in 0..<n{
//        let x_r = Float.random(in: 0...1)
//        let y_r = Float.random(in: 0...1)
//        let z_r = Float.random(in: 0...1)
//        let new_v = normalize(simd_float3(x_r,y_r,z_r))
//        output.append(new_v)
//    }
//    return output
//}
//
//class drawing_methods {
//    var depthStencilState : MTLDepthStencilState?
//    var sampler : MTLSamplerState?
//    var renderMeshWithColour : MTLRenderPipelineState?
//    var renderMeshWithCubeMap : MTLRenderPipelineState?
//    var renderMeshWithFlatMap : MTLRenderPipelineState?
//    var skyBoxPipeline : MTLRenderPipelineState?
//    var renderMeshWithCubeMapReflection : MTLRenderPipelineState?
//
//
//    func renderMesh(renderEncoder : MTLRenderCommandEncoder, mesh : Mesh, with colour : inout simd_float4){
//        renderEncoder.setRenderPipelineState(renderMeshWithColour!)
//        renderEncoder.setDepthStencilState(depthStencilState!)
//        renderEncoder.setFrontFacing(.counterClockwise)
//        renderEncoder.setCullMode(.back)
//        renderEncoder.setFragmentBytes(&colour , length: MemoryLayout<simd_float4>.stride, index: fragmentBufferIDs.colours)
//        mesh.draw(renderEncoder: renderEncoder)
//
//    }
//    func renderSkyBox(renderEncoder : MTLRenderCommandEncoder, mesh : Mesh, with cubeMap : MTLTexture){
//        renderEncoder.setRenderPipelineState(skyBoxPipeline!)
//        renderEncoder.setDepthStencilState(depthStencilState)
//        renderEncoder.setFrontFacing(.counterClockwise)
//        renderEncoder.setCullMode(.front)
//        renderEncoder.setFragmentTexture(cubeMap, index: textureIDs.cubeMap)
//        renderEncoder.setFragmentSamplerState(sampler, index: 0)
//        mesh.draw(renderEncoder: renderEncoder)
//    }
//    func renderCubeMapReflection(renderEncoder : MTLRenderCommandEncoder, mesh : Mesh, with cubeMap : MTLTexture, instances : Int = 1){
//        renderEncoder.setRenderPipelineState(renderMeshWithCubeMapReflection!)
//        renderEncoder.setDepthStencilState(depthStencilState)
//        renderEncoder.setFrontFacing(.counterClockwise)
//        renderEncoder.setCullMode(.back)
//        renderEncoder.setFragmentTexture(cubeMap, index: textureIDs.cubeMap)
//        renderEncoder.setFragmentSamplerState(sampler, index: 0)
//        mesh.draw(renderEncoder: renderEncoder, with: instances )
//    }
//}
//


//class skyBoxScene {
//    var fps = 0
//    var translateFirst = 0
//    var rotateFirst = 1
//    var False = false
//    var True = true
//
//    var meshFragmentUniforms : [Bool] = [false,false,true]
//    var skyBoxFragmentUniforms : [Bool] = [true,false,false]
//
//    var centreOfReflection : simd_float3
//    var camera : simd_float4x4
//    var eye : simd_float3
//    var direction : simd_float3
//    var projection : simd_float4x4
//    var firstPassNodes = [String : Mesh]()
//    var finalPassNodes = [String : Mesh]()
//    var nodesInitialState = [String : [[simd_float3]]]()
//    var nodeCounts = [String : Int]()
//    var skyBoxfirstPassMesh : Mesh?
//    var skyBoxfinalPassMesh : Mesh?
//    var reflectiveNodeMesh : Mesh?
//    var reflectiveNodeInitialState = [simd_float3]()
//    var current_node = 0
//
//
//    // pipelines
//    var renderToCubePipeline : pipeLine?
//    var simplePipeline : pipeLine?
//    var renderSkyboxPipeline : pipeLine?
//    var renderReflectionPipleline_noFuzzy : pipeLine?
//    var renderReflectionPipleline_Fuzzy : pipeLine?
//    let device : MTLDevice
//
//    var renderTarget : Texture?
//    var depthRenderTarget : MTLTexture?
//
//    var commandQueue : MTLCommandQueue
//    var view : MTKView
//    var depthStencilState : MTLDepthStencilState
//    var sampler : MTLSamplerState
//    var cameras = [simd_float4x4]()
//    var random_vectors_buffer : MTLBuffer?
//    var sceneCamera : Camera?
//
//
//    func initiatePipeline(){
//        let posAttrib = Attribute(format: .float4, offset: 0, length: 16, bufferIndex: 0)
//        let normalAttrib = Attribute(format: .float3, offset: MemoryLayout<Float>.stride*4,length: 12, bufferIndex: 0)
//        let texAttrib = Attribute(format: .float2, offset: MemoryLayout<Float>.stride*7, length : 8, bufferIndex: 0)
//        let tangentAttrib = Attribute(format: .float4, offset: MemoryLayout<Float>.stride*9, length: 16, bufferIndex: 0)
//        let bitangentAttrib = Attribute(format: .float4, offset: MemoryLayout<Float>.stride*13, length: 16, bufferIndex: 0)
//
//        let instanceAttrib = Attribute(format : .float3, offset: 0, length : 12, bufferIndex: 1)
//        let vertexDescriptor = createVertexDescriptor(attributes: posAttrib,normalAttrib,texAttrib,tangentAttrib,bitangentAttrib)
//
//        renderToCubePipeline  = pipeLine(device, "render_to_cube_vertex", "render_to_cube_fragment", vertexDescriptor, true)!
//
//        let simplePipelineFC = functionConstant()
//        simplePipelineFC.setValue(type: .bool, value: &False)
//        simplePipelineFC.setValue(type: .bool, value: &False)
//        simplePipelineFC.setValue(type: .bool, value: &False)
//        simplePipelineFC.setValue(type: .bool, value: &False)
//        simplePipelineFC.setValue(type: .bool, value: &False)
//        simplePipelineFC.setValue(type: .bool, value: &False)
//        simplePipeline = pipeLine(device, "simple_shader_vertex", "simple_shader_fragment", vertexDescriptor, simplePipelineFC.functionConstant)!
//
//
//        // this pipeline renders cubemap reflections
//        let fuzzy_reflectionFC = functionConstant()
//        fuzzy_reflectionFC.setValue(type: .bool, value: &False, at: 4)
////        renderReflectionPipleline = pipeLine(device, "cubeMap_reflection_vertex", "cubeMap_reflection_fragment", vertexDescriptor, false)!
//
//        renderReflectionPipleline_noFuzzy = pipeLine(device, "cubeMap_reflection_vertex", "cubeMap_reflection_fragment", vertexDescriptor, fuzzy_reflectionFC.functionConstant)!
//
//
//        fuzzy_reflectionFC.setValue(type: .bool, value: &True, at: 4)
//        renderReflectionPipleline_Fuzzy = pipeLine(device, "cubeMap_reflection_vertex", "cubeMap_reflection_fragment", vertexDescriptor, fuzzy_reflectionFC.functionConstant)!
//
//        // this one renders a skybox
//        let skyboxFunctionConstants = functionConstant()
//        skyboxFunctionConstants.setValue(type: .bool, value: &True, at: 0)
//        skyboxFunctionConstants.setValue(type: .bool, value: &False, at: 1)
//        skyboxFunctionConstants.setValue(type: .bool, value: &False, at: 2)
//        skyboxFunctionConstants.setValue(type: .bool, value: &True, at: 3)
//        skyboxFunctionConstants.setValue(type: .bool, value: &False, at: 5)
//
//        renderSkyboxPipeline = pipeLine(device, "simple_shader_vertex", "simple_shader_fragment", vertexDescriptor, skyboxFunctionConstants.functionConstant)!
//
//    }
//
//    func initialiseRenderTarget(){
//        let textureDescriptor = MTLTextureDescriptor()
//        textureDescriptor.pixelFormat = .bgra8Unorm_srgb
//        textureDescriptor.textureType = .typeCube
//        textureDescriptor.width = 1200
//        textureDescriptor.height = 1200
//        textureDescriptor.storageMode = .private
//        textureDescriptor.usage = [.shaderRead,.renderTarget]
//        var renderTargetTexture = device.makeTexture(descriptor: textureDescriptor)
//        textureDescriptor.pixelFormat = .depth32Float
//        depthRenderTarget = device.makeTexture(descriptor: textureDescriptor)
//        renderTarget = Texture(texture: renderTargetTexture!, index: textureIDs.cubeMap)
//    }
//
//    init(device : MTLDevice, at view : MTKView, from centreOfReflection: simd_float3, eye : simd_float3, direction : simd_float3, with projection : simd_float4x4) {
//        self.device = device
//        self.centreOfReflection = centreOfReflection
//        self.camera = simd_float4x4(eye: eye, center: direction + eye, up: simd_float3(0,1,0))
//        self.eye = eye
//        self.direction = direction
//        self.projection = projection
//        commandQueue = device.makeCommandQueue()!
//        self.view = view
//
//        // make depthstencil state
//        let depthStencilDescriptor = MTLDepthStencilDescriptor()
//        depthStencilDescriptor.isDepthWriteEnabled = true
//        depthStencilDescriptor.depthCompareFunction = .lessEqual
//        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)!
//
//        // create a samplerState
//        let samplerDescriptor = MTLSamplerDescriptor()
//        samplerDescriptor.magFilter = .linear
//        samplerDescriptor.minFilter = .linear
//        samplerDescriptor.rAddressMode = .repeat
//        samplerDescriptor.sAddressMode = .repeat
//        samplerDescriptor.tAddressMode = .repeat
//        samplerDescriptor.normalizedCoordinates = True
//        sampler = device.makeSamplerState(descriptor: samplerDescriptor)!
//
//        random_vectors_buffer = device.makeBuffer(bytes: create_random_points_in_sphere(for: 200), length: MemoryLayout<simd_float3>.stride*200, options: [])
//
//        initiatePipeline()
//        initialiseRenderTarget()
//
//            let camera0 = simd_float4x4(eye: centreOfReflection, center: simd_float3(1,0,0) + centreOfReflection, up: simd_float3(0,-1,0))
//        cameras.append(camera0)
//
//
//
//        let camera1 = simd_float4x4(eye: centreOfReflection, center: simd_float3(-1,0,0) + centreOfReflection, up: simd_float3(0,-1,0))
//        cameras.append(camera1)
//
//        let camera2 = simd_float4x4(eye: centreOfReflection, center: simd_float3(0,-1,0) + centreOfReflection, up: simd_float3(0,0,-1))
//        cameras.append(camera2)
//
//        let camera3 = simd_float4x4(eye: centreOfReflection, center: simd_float3(0,1,0) + centreOfReflection, up: simd_float3(0,0,1))
//        cameras.append(camera3)
//
//        let camera4 = simd_float4x4(eye: centreOfReflection, center: simd_float3(0,0,1) + centreOfReflection, up: simd_float3(0,-1,0))
//        cameras.append(camera4)
//
//        let camera5 = simd_float4x4(eye: centreOfReflection, center: simd_float3(0,0,-1) + centreOfReflection, up: simd_float3(0,-1,0))
//        cameras.append(camera5)
//    }
//
//    func attach_camera_to_scene(camera : Camera){
//        sceneCamera = camera
//    }
//
//
//
//
//    func addNodes(with label : String, mesh : MDLMesh, scale : simd_float3, translate : simd_float3, rotation : simd_float3, colour : simd_float4){
//        // firest pass nodes are being rendered from the centre of reflection
//
//
//        var initialState = [scale,translate,rotation]
//        // add initial state to for the correct node
//
//        if let _ = nodesInitialState[label], let _ = nodeCounts[label] {
//            nodesInitialState[label]?.append(initialState)
//            nodeCounts[label]? += 1
//        }
//        else{
//            nodesInitialState[label] = [initialState]
//            nodeCounts[label] = 1
//        }
//
//
//        // if the label exists then update the instance data
//        if let _ = firstPassNodes[label]{
//            var firstPassTransformation = createBuffersForRenderToCube(scale: scale, rotation: rotation, translate: translate, from: centreOfReflection)
//            for i in 0...5{
//                firstPassNodes[label]?.createInstance(with: firstPassTransformation[i], and: colour, add: translateFirst)
//            }
//
//            var finalPassTransformation = Transforms(Scale: simd_float4x4(scale: scale), Translate: simd_float4x4(translate: translate), Rotation: simd_float4x4(rotationXYZ: rotation), Projection: projection, Camera: camera)
//
//            finalPassNodes[label]?.createInstance(with: finalPassTransformation, and: colour, add: translateFirst)
////            if sceneCamera != nil {
////                finalPassNodes[label]?.attach_camera_to_mesh(to: sceneCamera!)
////            }
//
//
//        }
//        else {
//            var firstPassTransformation = createBuffersForRenderToCube(scale: scale, rotation: rotation, translate: translate, from: centreOfReflection)
//            let firstPassMesh = Mesh(device: device, Mesh: mesh)!
//            for i in 0...5{
//                firstPassMesh.createInstance(with: firstPassTransformation[i], and: colour, add: translateFirst)
//
//            }
//
//
//            firstPassMesh.createAndAddUniformBuffer(bytes: &False, length: 1, at: vertexBufferIDs.skyMap, for: device)
//
//            for i in 0...2{
//                firstPassMesh.createAndAddUniformBuffer(bytes: &meshFragmentUniforms[i], length: 1, at: 3 + i, for: device, for: .fragment)
//            }
//            firstPassNodes[label] = firstPassMesh
//
//            var finalPassTransformation = Transforms(Scale: simd_float4x4(scale: scale), Translate: simd_float4x4(translate: translate), Rotation: simd_float4x4(rotationXYZ: rotation), Projection: projection, Camera: camera)
//            let finalPassMesh = Mesh(device: device, Mesh: mesh)!
//
//            finalPassMesh.createInstance(with: finalPassTransformation, and: colour, add: translateFirst)
//            finalPassMesh.createAndAddUniformBuffer(bytes: &False, length: 1, at: vertexBufferIDs.skyMap, for: device)
//            for i in 0...2{
//                finalPassMesh.createAndAddUniformBuffer(bytes: &meshFragmentUniforms[i], length: 1, at: 3 + i, for: device, for: .fragment)
//            }
//            finalPassNodes[label] = finalPassMesh
//
//
//        }
//        current_node += 1
//
//    }
//
//    func finalise_nodes_buffers(){
//        for mesh in firstPassNodes.values{
//            mesh.init_instance_buffers()
//
//        }
//        for mesh in finalPassNodes.values{
//            mesh.init_instance_buffers()
//            if let camera = sceneCamera {
//                mesh.attach_camera_to_mesh(to: camera)
//            }
//        }
//        if let camera = sceneCamera {
//            reflectiveNodeMesh?.attach_camera_to_mesh(to: camera)
//            skyBoxfinalPassMesh?.attach_camera_to_mesh(to: camera)
//        }
//    }
//
//
//
//
//    func addSkyBoxNode(with texture : Texture, mesh : MDLMesh){
//
//        skyBoxfirstPassMesh = Mesh(device: device, Mesh: mesh)
//        skyBoxfinalPassMesh = Mesh(device: device, Mesh: mesh)
//
//
//        var skyBoxfirstPassTransform = createBuffersForRenderToCube()
//
//        var finalPassCamera = camera
//        finalPassCamera[3] = simd_float4(0,0,0,1)
//
//        var skyBoxfinalPassTransform = Transforms(Scale: simd_float4x4(scale: simd_float3(1)), Translate: simd_float4x4(translate: simd_float3(0)), Rotation: simd_float4x4(rotationXYZ: simd_float3(0)), Projection: projection, Camera: finalPassCamera)
//
//
//        skyBoxfirstPassMesh?.createAndAddUniformBuffer(bytes: &skyBoxfirstPassTransform, length: MemoryLayout<Transforms>.stride*6, at: vertexBufferIDs.uniformBuffers, for: device)
//        for i in 0...2{
//            skyBoxfirstPassMesh?.createAndAddUniformBuffer(bytes: &skyBoxFragmentUniforms[i], length: 1, at: 3 + i, for: device, for: .fragment)
//            skyBoxfirstPassMesh?.createAndAddUniformBuffer(bytes: &skyBoxFragmentUniforms[i], length: 1, at: 3 + i, for: device, for: .fragment)
//        }
//
//        skyBoxfirstPassMesh?.createAndAddUniformBuffer(bytes: &True, length: 1, at: vertexBufferIDs.skyMap, for: device)
//        skyBoxfirstPassMesh?.createAndAddUniformBuffer(bytes: &translateFirst, length: MemoryLayout<Int>.stride, at: vertexBufferIDs.order_of_rot_tran, for: device)
//        skyBoxfirstPassMesh?.add_textures(textures: texture)
//
//
//
//
//
//        skyBoxfinalPassMesh?.createAndAddUniformBuffer(bytes: &skyBoxfinalPassTransform, length: MemoryLayout<Transforms>.stride, at: vertexBufferIDs.uniformBuffers, for: device)
//        skyBoxfinalPassMesh?.createAndAddUniformBuffer(bytes: &True, length: 1, at: vertexBufferIDs.skyMap, for: device)
//        skyBoxfinalPassMesh?.createAndAddUniformBuffer(bytes: &rotateFirst, length: MemoryLayout<Int>.stride, at: vertexBufferIDs.order_of_rot_tran, for: device)
//        skyBoxfinalPassMesh?.add_textures(textures: texture)
//
//
//
//    }
//    func addReflectiveNode(mesh : MDLMesh, scale : simd_float3, rotation : simd_float3){
//
//        reflectiveNodeInitialState.append(scale)
//        reflectiveNodeInitialState.append(centreOfReflection)
//        reflectiveNodeInitialState.append(rotation)
//
//        reflectiveNodeMesh = Mesh(device: device, Mesh: mesh)
//        var reflectiveMeshTransform = Transforms(Scale: simd_float4x4(scale: scale), Translate: simd_float4x4(translate: centreOfReflection), Rotation: simd_float4x4(rotationXYZ: rotation), Projection: projection, Camera: camera)
//        reflectiveNodeMesh?.createAndAddUniformBuffer(bytes: &reflectiveMeshTransform, length: MemoryLayout<Transforms>.stride, at: vertexBufferIDs.uniformBuffers, for: device)
//        reflectiveNodeMesh?.createAndAddUniformBuffer(bytes: &rotateFirst, length: MemoryLayout<Int>.stride, at: vertexBufferIDs.order_of_rot_tran, for: device)
//        reflectiveNodeMesh?.add_textures(textures: renderTarget!)
//       // var eye = -simd_float3(self.camera[3].x,self.camera[3].y,self.camera[3].z)
//        reflectiveNodeMesh?.createAndAddUniformBuffer(bytes: &eye, length: MemoryLayout<simd_float3>.stride, at: vertexBufferIDs.camera_origin, for: device)
//
////        if sceneCamera != nil {
////            reflectiveNodeMesh?.attach_camera_to_mesh(to: sceneCamera!)
////        }
//    }
//
//    func setSkyMapTexture(with texture : Texture){
//        skyBoxfirstPassMesh?.updateTexture(with: texture)
//        skyBoxfinalPassMesh?.updateTexture(with: texture)
//    }
//
//
//
//    func renderScene(){
//
//        fps += 1
//        guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}
//        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {return}
//        renderPassDescriptor.colorAttachments[0].texture = renderTarget?.texture
//        renderPassDescriptor.depthAttachment.texture = depthRenderTarget!
//        renderPassDescriptor.colorAttachments[0].storeAction = .store
//        renderPassDescriptor.colorAttachments[0].loadAction = .dontCare
//        renderPassDescriptor.depthAttachment.loadAction = .clear
//        renderPassDescriptor.depthAttachment.clearDepth = 1
//        renderPassDescriptor.renderTargetArrayLength = 6
//
//        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}
//        renderEncoder.setRenderPipelineState(renderToCubePipeline!.m_pipeLine)
//        renderEncoder.setDepthStencilState(depthStencilState)
//        renderEncoder.setFragmentSamplerState(sampler, index: 0)
//
//        // render nodes
//        renderEncoder.setCullMode(.back)
//        renderEncoder.setFrontFacing(.counterClockwise)
//
//
//        for (label,mesh) in firstPassNodes {
//
//            let states = nodesInitialState[label]!
//            let totalStetesCount = states.count
//
//
//                            for i in 0..<totalStetesCount{
//                                    let state = states[i]
//                                    var new_transform = createBuffersForRenderToCube(scale: state[0], rotation: state[2] + simd_float3(0,Float(fps)*0.1,0), translate: state[1], from: cameras)
//                                    firstPassNodes[label]?.updateUniformBuffer(with: &new_transform, at: i)
//
//                                    var new_transformFinalPass = Transforms(Scale: simd_float4x4(scale: state[0]), Translate: simd_float4x4(translate: state[1]), Rotation: simd_float4x4(rotationXYZ: state[2]+simd_float3(0,Float(fps)*0.1,0)), Projection: projection, Camera: camera)
//                                    finalPassNodes[label]?.updateUniformBuffer(with: &new_transformFinalPass, at: i)
//                            }
////
//
//                                let count = nodeCounts[label]!
//                                mesh.draw(renderEncoder: renderEncoder, with: 6*count)
//
//        }
//
//        // render skybox
//
//        renderEncoder.setCullMode(.front)
//        skyBoxfirstPassMesh?.draw(renderEncoder: renderEncoder,with: 6)
//
//        renderEncoder.endEncoding()
//
//
//        guard let finalRenderPassDescriptor = view.currentRenderPassDescriptor else {return}
//        finalRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
//        finalRenderPassDescriptor.depthAttachment.clearDepth = 1
//        finalRenderPassDescriptor.depthAttachment.loadAction = .clear
//
//        guard let finalRenderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalRenderPassDescriptor) else {return}
//
//        finalRenderEncoder.setRenderPipelineState(renderReflectionPipleline_noFuzzy!.m_pipeLine)
//        finalRenderEncoder.setDepthStencilState(depthStencilState)
//        finalRenderEncoder.setFragmentSamplerState(sampler, index: 0)
//        finalRenderEncoder.setFragmentBuffer(random_vectors_buffer, offset: 0, index: vertexBufferIDs.points_in_sphere)
//        finalRenderEncoder.setFrontFacing(.counterClockwise)
//        finalRenderEncoder.setCullMode(.back)
//        var eye = sceneCamera?.eye
//        reflectiveNodeMesh?.createAndAddUniformBuffer(bytes: &eye, length: MemoryLayout<simd_float3>.stride, at: vertexBufferIDs.camera_origin, for: device)
//        reflectiveNodeMesh?.draw(renderEncoder: finalRenderEncoder)
//
//        finalRenderEncoder.setRenderPipelineState(simplePipeline!.m_pipeLine)
//
//
//
//        for (label,mesh) in finalPassNodes {
//
//
//
//                let count = nodeCounts[label]!
//                 mesh.draw(renderEncoder: finalRenderEncoder, with: count)
//
//        }
//
//        finalRenderEncoder.setRenderPipelineState(renderSkyboxPipeline!.m_pipeLine)
//        finalRenderEncoder.setCullMode(.front)
//        skyBoxfinalPassMesh?.draw(renderEncoder: finalRenderEncoder)
//
//        finalRenderEncoder.endEncoding()
//
//        commandBuffer.present(view.currentDrawable!)
//        commandBuffer.commit()
//
//
//
//    }
//}
//
//


func sort(array : inout [simd_float4]) -> [simd_float3]{
    let boundx = array.sorted(){ $0[0] < $1[0]}
    let boundy = array.sorted(){ $0[1] < $1[1]}
    let boundz =  array.sorted(){ $0[2] < $1[2]}
    let minx = boundx.first!.x
    let maxx = boundx.last!.x
    let miny = boundy.first!.y
    let maxy = boundy.last!.y
    let minz = boundz.first!.z
    let maxz = boundz.last!.z
    return [simd_float3(minx,miny,minz),simd_float3(maxx,maxy,maxz)]
}


func findBounds(array : inout [simd_float4], light : Camera) -> simd_float4x4{
    var eyeBounds = array.map{ light.cameraMatrix * $0}
    let eyeMinMax = sort(array: &eyeBounds)
    let left = eyeMinMax.first!.x - 1.1
    let right = eyeMinMax.last!.x + 1.1
    let bottom = eyeMinMax.first!.y - 1.1
    let top = eyeMinMax.last!.y + 1.1
    let near = -(eyeMinMax.last!.z + 1.1 )
    let far = -(eyeMinMax.first!.z - 1.1 )
    return simd_float4x4(orthoWithLeft: left, right: right, bottom: bottom, top: top, near: near, far: far)
    
}



class Renderer : NSObject, MTKViewDelegate {
    
  
    
 
    
   
    
    var True = true
    var False = false
   
    var fps = 0
    var sampler : MTLSamplerState?
    var depthStencilState : MTLDepthStencilState?
    
    
    

    
   
   
    let device: MTLDevice
    let commandQueue : MTLCommandQueue
    var simplePipeline : pipeLine?
    
    
 
    
  
    
    var tesselationPipelineState : MTLRenderPipelineState?
    var tesselateWall : Mesh?
    var FlowerImage : MTLTexture?
    var cameraLists = [Camera]()
    var lightCameraLists = [Camera]()
    
    
   
    var wallVB : [Float] = [
        -1,-1,0,1, 0,0,1, 0,0, 1,0,0,1, 0,1,0,1,
         -1,1,0,1, 0,0,1, 0,1, 1,0,0,1, 0,1,0,1,
         1,1,0,1, 0,0,1, 1,1, 1,0,0,1, 0,1,0,1,
         1,-1,0,1, 0,0,1, 1,0, 1,0,0,1, 0,1,0,1
    ]
    var wallIB : [uint16] = [
        0,1,2,
        0,2,3
    ]
    
    var wallVertexBuffer : MTLBuffer?
    var wallIndexBuffer : MTLBuffer?
    var testSlicesRenderingPipeline : pipeLine?
    var testTextureArray : MTLTexture?
    var testDepthTextureArray : MTLTexture?
    var renderSlicePipeline : pipeLine?
    
    var spheresMesh : Mesh?
    var frameConstant : FrameConstants
    var testCamera : Camera
    var initialState = [[simd_float3]]()
    
    
    
    
    var shadowScene : shadowMapScene?
    
   
    var adjustSceneCamera = true
    var testShadowScene : shadowMapScene
    
    
    var testAmplificationPipeline : pipeLine
    var pointVertex : [Float] = [0,0,0,1, 0,0, 0,0,0, 1,0,0,1, 0,1,0,1
    ]
    var pointIndex : [uint16] = [0]
    var pointBuffer : MTLBuffer
    var pointIndexBuffer : MTLBuffer
    
    
    
  
    
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
       
        let BrickWall = try! textureLoader.newTexture(name: "BrickWallD", scaleFactor: 1.0, bundle: nil, options: flatTextureLoaderOptions)
            
      
        let BrickWallTexture = Texture(texture: BrickWall, index: textureIDs.flat)
        
        let flatTextureLoaderOptionsN : [MTKTextureLoader.Option : Any] = [
            .textureUsage : MTLTextureUsage.shaderRead.rawValue,
            .textureStorageMode : MTLStorageMode.private.rawValue,
            .origin : MTKTextureLoader.Origin.bottomLeft.rawValue,
            .SRGB : False
           
                
        ]
        
        let BrickWallN = try! textureLoader.newTexture(name: "BrickWallN", scaleFactor: 1.0, bundle: nil, options: flatTextureLoaderOptionsN)
        
        let BrickWallTextureN = Texture(texture: BrickWallN, index: textureIDs.Normal)
      
        // render a simple cube with colour pipeline
      
        

        
        let allocator = MTKMeshBufferAllocator(device: device)
        let planeMDLMesh = MDLMesh(planeWithExtent: simd_float3(1,1,1), segments: simd_uint2(1,1), geometryType: .triangles, allocator: allocator)
        let cubeMDLMesh = MDLMesh(boxWithExtent: simd_float3(1,1,1), segments: simd_uint3(1,1,1), inwardNormals: true, geometryType: .triangles, allocator: allocator)
        let circleMDLMesh = MDLMesh(sphereWithExtent: simd_float3(1,1,1), segments: simd_uint2(100,100), inwardNormals: False, geometryType: .triangles, allocator: allocator)
        let coneMDLMesh = MDLMesh(coneWithExtent: simd_float3(1,1,1), segments: simd_uint2(100,100), inwardNormals: False, cap: False, geometryType: .triangles, allocator: allocator)
       
    
//        cubeMDLMesh.vertexDescriptor = mdlMeshVD
//        circleMDLMesh.vertexDescriptor = mdlMeshVD
//        planeMDLMesh.vertexDescriptor = mdlMeshVD
//        coneMDLMesh.vertexDescriptor = mdlMeshVD
        
      
 

       
       
   
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
        
      

     
        
        
     
        testCamera = Camera(for: mtkView, eye: simd_float3(0,0,10), centre: simd_float3(0,0,-1))
        
        cameraLists.append(testCamera)
     
        
        spheresMesh = Mesh(device: device, Mesh: circleMDLMesh ,with: "Circle Mesh")
        let coneMesh = Mesh(device: device, Mesh: coneMDLMesh, with: "Cone Mesh")
        coneMesh?.is_shadow_caster = true
        spheresMesh?.is_shadow_caster = true
        
        let projectionMatrix = simd_float4x4(fovRadians: 3.14/2, aspectRatio: 2.0, near: 1.0, far: 100)
        
        frameConstant = FrameConstants(viewMatrix: testCamera.cameraMatrix, projectionMatrix: projectionMatrix)
       
        let houseMesh = Mesh(device: device, Mesh: cubeMDLMesh)
        //houseMesh?.is_shadow_caster = true
        let houseModelMatrix = create_modelMatrix(translation: simd_float3(0,0,0), rotation: simd_float3(0), scale: simd_float3(10))
        houseMesh?.createInstance(with: houseModelMatrix, and: simd_float4(0.5,0.5,0.5,1))
        //houseMesh?.init_instance_buffers()
        //houseMesh?.add_textures(texture: BrickWallTexture)
        //houseMesh?.add_textures(texture: BrickWallTextureN)
        houseMesh?.setCullModeForMesh(side: .back)
//        let modelMatrix = create_modelMatrix(rotation: simd_float3(0), translation: simd_float3(0,0,-1), scale: simd_float3(1))
//       //
//       //
//       //
//                           spheresMesh?.createInstance(with: modelMatrix, and: simd_float4(1,0,0,1))
       
        
        var boundsArray = [simd_float4]()
       // boundsArray.append(simd_float4(-5,-5,5,1))
       // boundsArray.append(simd_float4(5,5,-5,1))
        let n = 9
        for i in 0..<n{
            
            
            let theta = Float(i) * Float(6.28 / Float(n))
                    let x_r : Float = 4 * cos(theta)
                    let y_r : Float = 0
                    let z_r : Float = 4 * sin(theta)

                    let c_r = Float.random(in: 0...1)
                    let c_g = Float.random(in: 0...1)
                    let c_b = Float.random(in: 0...1)
                    let scale = Float.random(in: 0.1...0.4)
            
                    let minBound = simd_float4(x_r,y_r,z_r,1) - simd_float4(scale,scale,scale,0)
                    let maxbound = simd_float4(x_r,y_r,z_r,1) + simd_float4(scale,scale,scale,0)
            boundsArray.append(minBound)
            boundsArray.append(maxbound)

            let modelMatrix = create_modelMatrix(translation: simd_float3(x_r,y_r,z_r), rotation: simd_float3(0), scale: simd_float3(0.5))



                    //spheresMesh?.createInstance(with: modelMatrix, and: simd_float4(c_r,c_g,c_b,1))
            
           
        }
        
        let modelMatrix = create_modelMatrix(rotation: simd_float3(0), translation: simd_float3(0,2,0), scale: simd_float3(1))
        let modelMatrix1 = create_modelMatrix(rotation: simd_float3(0), translation: simd_float3(0,-2,0), scale: simd_float3(1))
        spheresMesh?.createInstance(with: modelMatrix,and: simd_float4(1,0,0,1))
        spheresMesh?.createInstance(with: modelMatrix1 , and: simd_float4(0,1,0,1))
        
       
      
        
        
            
        

   
      
        
        var shadowCamera = Camera(for: mtkView, eye: simd_float3(0,0,0), centre: simd_float3(-1,0,0))
        var shadowCamera1 = Camera(for: mtkView, eye: simd_float3(0,0,0), centre: simd_float3(-1,-1,0))
        var orthoProjection = findBounds(array: &boundsArray, light: shadowCamera)
        var orthoProjection1 = findBounds(array: &boundsArray, light: shadowCamera1)
        
        var testArray = [simd_float4(-1,-1,1,1),simd_float4(1,1,-1,1)]
        let testOrtho = findBounds(array: &testArray, light: shadowCamera)
        //let testResult = testArray.map {testOrtho * shadowCamera.cameraMatrix * $0}
        //print(testOrtho * shadowCamera.cameraMatrix * simd_float4(-5,-5,5,1))
        
        let result = boundsArray.map{orthoProjection * shadowCamera.cameraMatrix * $0}
        //print(result)
        
        testShadowScene = shadowMapScene(device: device, projectionMatrix: projectionMatrix, attachTo: testCamera)
        
  
        testShadowScene.addDirectionalLight(lightCamera: shadowCamera, with: orthoProjection)
        testShadowScene.addDirectionalLight(lightCamera: shadowCamera1, with: orthoProjection1)
        
        testShadowScene.initShadowMap()
        testShadowScene.addDrawable(mesh: houseMesh!)
        testShadowScene.addDrawable(mesh: spheresMesh!)
        
        

        wallVertexBuffer = device.makeBuffer(bytes: &wallVB, length: MemoryLayout<Float>.stride*17*4,options: [])
        wallIndexBuffer = device.makeBuffer(bytes: &wallIB, length: MemoryLayout<uint16>.stride*6,options: [])
        let VD = generalVertexDescriptor()
        print("creating test Pipeline")
        testSlicesRenderingPipeline = pipeLine(device, "test_shader_vertex", "test_shader_fragment", VD, true, amplificationCount: 3)
       
        let textureDescriptorColour = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: 1000, height: 1000, mipmapped: false)
        textureDescriptorColour.arrayLength = 3
        textureDescriptorColour.usage = [.shaderWrite,.renderTarget,.shaderRead]
        textureDescriptorColour.textureType = .type2DArray
        
        testTextureArray = device.makeTexture(descriptor: textureDescriptorColour)
        
        let textureDescriptorDepth = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: 1000, height: 1000, mipmapped: false)
        textureDescriptorDepth.arrayLength = 3
        textureDescriptorDepth.usage = [.shaderWrite,.renderTarget]
        textureDescriptorDepth.textureType = .type2DArray
        
        testDepthTextureArray = device.makeTexture(descriptor: textureDescriptorDepth)
        
        
        
        testAmplificationPipeline = pipeLine(device, "test_amp_vertex", "test_amp_fragment", VD, false,amplificationCount: 4)!
        pointBuffer = device.makeBuffer(bytes: &pointVertex, length: MemoryLayout<Float>.stride*17, options: [])!
        pointIndexBuffer = device.makeBuffer(bytes: &pointIndex, length: MemoryLayout<uint16>.stride,options: [])!
        
        
        
        testShadowScene.addPointLight(position: simd_float3(0))
        print("creating point shadow pipeline")
        testShadowScene.init_pointShadowMapPipeline()
        testShadowScene.init_pointShadowRenderTargets()
      

    }
   
    // mtkView will automatically call this function
    // whenever it wants new content to be rendered.
    
    
   
    
    
    func draw(in view: MTKView) {
        
     
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}
        
       
      
       
        //testShadowScene.shadowPass(with: commandBuffer, in: view)
        testShadowScene.test_pointShadowDepthPass(with: commandBuffer, in: view)
//        fps += 1
//
        
//        guard let renderPassDescriptor1 = view.currentRenderPassDescriptor else {return}
//        renderPassDescriptor1.colorAttachments[0].texture = testTextureArray
//        renderPassDescriptor1.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
//        renderPassDescriptor1.depthAttachment.texture = testDepthTextureArray
//        renderPassDescriptor1.renderTargetArrayLength = 3
//
//        guard let renderEncoder1 = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor1) else {return}
//
//        var mapping0 = MTLVertexAmplificationViewMapping(viewportArrayIndexOffset: 0, renderTargetArrayIndexOffset: 2)
//        var mapping1 = MTLVertexAmplificationViewMapping(viewportArrayIndexOffset: 0, renderTargetArrayIndexOffset: 1)
//        var mapping2 = MTLVertexAmplificationViewMapping(viewportArrayIndexOffset: 0, renderTargetArrayIndexOffset: 0)
//        let mappings = [mapping0,mapping1,mapping2]
//
//        renderEncoder1.setRenderPipelineState(testSlicesRenderingPipeline!.m_pipeLine)
//        renderEncoder1.setVertexAmplificationCount(3, viewMappings: mappings)
//        renderEncoder1.setVertexBuffer(wallVertexBuffer, offset: 0, index: 0)
//        renderEncoder1.drawIndexedPrimitives(type: .triangle, indexCount: 6, indexType: .uint16, indexBuffer: wallIndexBuffer!, indexBufferOffset: 0, instanceCount: 1)
//
//        renderEncoder1.endEncoding()
//
//
//        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {return}
//
//        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
//        renderPassDescriptor.colorAttachments[0].loadAction = .clear
//        renderPassDescriptor.colorAttachments[0].storeAction = .store
//
//
//       guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}
//        var offset : [simd_float4] = [simd_float4(-0.5,0,0,0),simd_float4(0.5,0,0,0),simd_float4(0,0.5,0,0),simd_float4(0,-0.5,0,0)]
//        renderEncoder.setRenderPipelineState(testAmplificationPipeline.m_pipeLine)
//        renderEncoder.setVertexBytes(&offset, length: MemoryLayout<simd_float4>.stride*4, index: 10)
//        renderEncoder.setVertexAmplificationCount(4, viewMappings: nil)
//        renderEncoder.setVertexBuffer(pointBuffer, offset: 0, index: 0)
//        renderEncoder.drawIndexedPrimitives(type: .point, indexCount: 1, indexType: .uint16, indexBuffer: pointIndexBuffer, indexBufferOffset: 0, instanceCount: 1)
//
//        renderEncoder.endEncoding()
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
       
    }

    // mtkView will automatically call this function
    // whenever the size of the view changes (such as resizing the window).
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}
