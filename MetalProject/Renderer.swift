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


class skyBoxScene {
    var fps = 0
    var translateFirst = 0
    var rotateFirst = 1
    var False = false
    var True = true
    var centreOfReflection : simd_float3
    var camera : Camera
    var projection : simd_float4x4
    var nodes = [Mesh]()
    var skyBoxMesh : Mesh
    var reflectiveNodeMesh : Mesh?
   
    var reflectiveNodeInitialState = [simd_float3]()
    var current_node = 0
    // use these to render to cubeMap
    var renderToCubeframeConstants = [FrameConstants]()
    
    // use this to render the skybox and the final pass
    var frameConstants : FrameConstants


    // pipelines
    var renderToCubePipelineForSkyBox : pipeLine?
    var renderToCubePipelineForMesh : pipeLine?
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
    var directionalLight : simd_float3?
    var cameraChanged = false {
        didSet {
            for mesh in nodes {
                mesh.updateNormalMatrix(with: camera.cameraMatrix)
            }
        }
    }
    
    

    func initiatePipeline(){
        let posAttrib = Attribute(format: .float4, offset: 0, length: 16, bufferIndex: 0)
        let normalAttrib = Attribute(format: .float3, offset: MemoryLayout<Float>.stride*4,length: 12, bufferIndex: 0)
        let texAttrib = Attribute(format: .float2, offset: MemoryLayout<Float>.stride*7, length : 8, bufferIndex: 0)
        let tangentAttrib = Attribute(format: .float4, offset: MemoryLayout<Float>.stride*9, length: 16, bufferIndex: 0)
        let bitangentAttrib = Attribute(format: .float4, offset: MemoryLayout<Float>.stride*13, length: 16, bufferIndex: 0)

        let instanceAttrib = Attribute(format : .float3, offset: 0, length : 12, bufferIndex: 1)
        let vertexDescriptor = createVertexDescriptor(attributes: posAttrib,normalAttrib,texAttrib,tangentAttrib,bitangentAttrib)

        // render world into cubemap
        
        let FC = functionConstant()
        
        FC.setValue(type: .bool, value: &False, at: FunctionConstantValues.constant_colour)
        FC.setValue(type: .bool, value: &True, at: FunctionConstantValues.cube)
        
       
    
        
        renderToCubePipelineForSkyBox  = pipeLine(device, "vertexRenderToCube", "fragmentRenderToCube", vertexDescriptor, true,amplificationCount: 6,functionConstant: FC.functionConstant,label: "RenderToCubePipeline")
      
        
        
        FC.setValue(type: .bool, value: &True, at: FunctionConstantValues.constant_colour)
        FC.setValue(type: .bool, value: &False, at: FunctionConstantValues.cube)
        
        renderToCubePipelineForMesh = pipeLine(device, "vertexRenderToCube", "fragmentRenderToCube", vertexDescriptor, true,amplificationCount: 6,functionConstant: FC.functionConstant,label: "RenderToCubePipeline")
        
        // simple pipeline for the final pass

       
        simplePipeline = pipeLine(device, "vertexSimpleShader", "fragmentSimpleShader", vertexDescriptor,false,label: "simpleShaderPipeline")


        // render the reflections using cubemap
      
        renderReflectionPipleline = pipeLine(device, "vertexRenderCubeReflection", "fragmentRenderCubeReflection", vertexDescriptor, false, label: "renderCubeMapReflection")
        
        // pipeline for rendering skybox

        renderSkyboxPipeline = pipeLine(device, "vertexRenderSkyBox", "fragmentRenderSkyBox", vertexDescriptor, false, label: "SkyboxPipeline")

    }

    func initialiseRenderTarget(){
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .bgra8Unorm_srgb
        textureDescriptor.textureType = .typeCube
        textureDescriptor.width = 1200
        textureDescriptor.height = 1200
        textureDescriptor.storageMode = .private
        textureDescriptor.mipmapLevelCount = 8
        textureDescriptor.usage = [.shaderRead,.renderTarget]
        var renderTargetTexture = device.makeTexture(descriptor: textureDescriptor)
        textureDescriptor.pixelFormat = .depth32Float
        depthRenderTarget = device.makeTexture(descriptor: textureDescriptor)
        renderTarget = Texture(texture: renderTargetTexture!, index: textureIDs.cubeMap)
    }

    init(device : MTLDevice, at view : MTKView, from centreOfReflection: simd_float3, attachTo camera : Camera, with projection : simd_float4x4) {
        self.device = device
        self.centreOfReflection = centreOfReflection
        self.camera = camera
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
        
        
        frameConstants = FrameConstants(viewMatrix: self.camera.cameraMatrix, projectionMatrix: projection)
        
        let allocator = MTKMeshBufferAllocator(device: device)
        let cubeMDLMesh = MDLMesh(boxWithExtent: simd_float3(1,1,1), segments: simd_uint3(1,1,1), inwardNormals: false, geometryType: .triangles, allocator: allocator)
        skyBoxMesh = Mesh(device: device, Mesh: cubeMDLMesh)!
        let frameConstantBuffer = device.makeBuffer(bytes: &frameConstants, length: MemoryLayout<FrameConstants>.stride,options: [])
        //skyBoxMesh.addUniformBuffer(buffer: UniformBuffer(buffer: frameConstantBuffer!, index: vertexBufferIDs.frameConstant))

       

       
        
        initiatePipeline()
        initialiseRenderTarget()
        
    }

//    func attach_camera_to_scene(camera : Camera){
//        sceneCamera = camera
//    }



    func addDirectionalLight(with direction : simd_float3){
        directionalLight = direction
    }

    func addNodes(mesh : Mesh){
        // firest pass nodes are being rendered from the centre of reflection
        
        mesh.init_instance_buffers(with: camera.cameraMatrix)
        nodes.append(mesh)
        
      

    }

    func addReflectiveNode(mesh : Mesh, with size : Float){
        
        reflectiveNodeMesh = mesh
        let modelMatrix = create_modelMatrix(rotation: simd_float3(0), translation: centreOfReflection, scale: simd_float3(size))
        reflectiveNodeMesh?.createInstance(with: modelMatrix)
        reflectiveNodeMesh?.init_instance_buffers(with: self.camera.cameraMatrix)
        reflectiveNodeMesh?.add_textures(texture: renderTarget!)
        
        let projection = simd_float4x4(fovRadians: 3.14/2, aspectRatio: 1, near: size, far: 100)
        
        var cameraArray = [simd_float4x4]()
        
        cameraArray.append(simd_float4x4(eye: centreOfReflection, center: simd_float3(1,0,0) + centreOfReflection , up: simd_float3(0,-1,0)))
                           
        cameraArray.append(simd_float4x4(eye: centreOfReflection, center: simd_float3(-1,0,0) + centreOfReflection , up: simd_float3(0,-1,0)))
        
        cameraArray.append(simd_float4x4(eye: centreOfReflection,  center: simd_float3(0,-1,0) + centreOfReflection , up: simd_float3(0,0,-1)))
           
        cameraArray.append(simd_float4x4(eye: centreOfReflection, center: simd_float3(0,1,0) + centreOfReflection , up: simd_float3(0,0,1)))
                           
        cameraArray.append(simd_float4x4(eye: centreOfReflection, center: simd_float3(0,0,1) + centreOfReflection , up: simd_float3(0,-1,0)))
                   
        cameraArray.append(simd_float4x4(eye: centreOfReflection, center: simd_float3(0,0,-1) + centreOfReflection, up: simd_float3(0,-1,0)))
                   
        
        for i in 0..<6{
            renderToCubeframeConstants.append(FrameConstants(viewMatrix: cameraArray[i], projectionMatrix: projection))
        }
     
    }

    func setSkyMapTexture(with texture : Texture){
        skyBoxMesh.add_textures(texture: texture)
    }



    func renderScene(){
        
        frameConstants.viewMatrix = camera.cameraMatrix

        fps += 1
          guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {return}
        renderPassDescriptor.colorAttachments[0].texture = renderTarget?.texture
        renderPassDescriptor.depthAttachment.texture = depthRenderTarget!
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.clearDepth = 1
        renderPassDescriptor.renderTargetArrayLength = 6
        
        // render to cubempa pass
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}
        renderEncoder.setRenderPipelineState(renderToCubePipelineForMesh!.m_pipeLine)
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setVertexAmplificationCount(6, viewMappings: nil)
        renderEncoder.setVertexBytes(&renderToCubeframeConstants, length: MemoryLayout<FrameConstants>.stride*6, index: vertexBufferIDs.frameConstant)
        
        
        for mesh in nodes {
            mesh.rotateMesh(with: simd_float3(0,Float(fps)*0.2,0), and: camera.cameraMatrix)
            mesh.draw(renderEncoder: renderEncoder)
        }
        
        renderEncoder.setRenderPipelineState(renderToCubePipelineForSkyBox!.m_pipeLine)
        skyBoxMesh.draw(renderEncoder: renderEncoder, with: 1)
        
        renderEncoder.endEncoding()
        
        guard let mipRenderEncoder = commandBuffer.makeBlitCommandEncoder() else {return}
        mipRenderEncoder.generateMipmaps(for: renderTarget!.texture)
        mipRenderEncoder.endEncoding()
        
        
        
        guard let finalRenderPassDescriptor = view.currentRenderPassDescriptor else {return}
        finalRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
        finalRenderPassDescriptor.depthAttachment.clearDepth = 1
       finalRenderPassDescriptor.depthAttachment.loadAction = .clear
//
        guard let finalRenderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalRenderPassDescriptor) else {return}
        finalRenderEncoder.setDepthStencilState(depthStencilState)
        finalRenderEncoder.setFrontFacing(.counterClockwise)
        
        finalRenderEncoder.setRenderPipelineState(renderReflectionPipleline!.m_pipeLine)
        finalRenderEncoder.setVertexBytes(&frameConstants, length: MemoryLayout<FrameConstants>.stride, index: vertexBufferIDs.frameConstant)
        finalRenderEncoder.setFragmentBytes(&self.camera.eye, length: 16, index: 0)
        
        // render reflective mesh
        reflectiveNodeMesh?.draw(renderEncoder: finalRenderEncoder,with: 1, culling: .back)

        // render the meshes
        
        finalRenderEncoder.setRenderPipelineState(simplePipeline!.m_pipeLine)
        
        var eyeSpaceLightDirection = camera.cameraMatrix * simd_float4(directionalLight!.x,directionalLight!.y,directionalLight!.z,0)
        
        finalRenderEncoder.setFragmentBytes(&eyeSpaceLightDirection, length: 16, index: vertexBufferIDs.lightPos)
        for mesh in nodes {
            mesh.draw(renderEncoder: finalRenderEncoder,culling: .back)
        }

        
        // render the skybox
        
        finalRenderEncoder.setRenderPipelineState(renderSkyboxPipeline!.m_pipeLine)
        skyBoxMesh.draw(renderEncoder: finalRenderEncoder, with: 1, culling: .front)

        finalRenderEncoder.endEncoding()

        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()



    }
}








class Renderer : NSObject, MTKViewDelegate {
    
  
    
 
    
   
    
    var True = true
    var False = false
   
   
    let device: MTLDevice
    let commandQueue : MTLCommandQueue
    var spheresMesh : Mesh?
    var CubeMesh : Mesh?
    var skyTexture : MTLTexture
    var SkyScene : skyBoxScene
    var cameraLists = [Camera]()
    
    
    
  
    
    init?(mtkView: MTKView){
      
       
        device = mtkView.device!
        mtkView.preferredFramesPerSecond = 120
        commandQueue = device.makeCommandQueue()!
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        mtkView.depthStencilPixelFormat = .depth32Float
        
       
        
        let allocator = MTKMeshBufferAllocator(device: device)
        let planeMDLMesh = MDLMesh(planeWithExtent: simd_float3(1,1,1), segments: simd_uint2(1,1), geometryType: .triangles, allocator: allocator)
        let cubeMDLMesh = MDLMesh(boxWithExtent: simd_float3(1,1,1), segments: simd_uint3(1,1,1), inwardNormals: false, geometryType: .triangles, allocator: allocator)
        let circleMDLMesh = MDLMesh(sphereWithExtent: simd_float3(1,1,1), segments: simd_uint2(30,30), inwardNormals: False, geometryType: .triangles, allocator: allocator)
        let coneMDLMesh = MDLMesh(coneWithExtent: simd_float3(1,1,1), segments: simd_uint2(100,100), inwardNormals: False, cap: False, geometryType: .triangles, allocator: allocator)
      
     
       
       
        
        
        
    
        
        
       
        
       
        
        var skyBoxCamera = Camera(for: mtkView, eye: simd_float3(0), centre: simd_float3(0,0,1))
        cameraLists.append(skyBoxCamera)
        
        
        var cube = Mesh(device: device, Mesh: cubeMDLMesh)!
        var spheres = Mesh(device: device, Mesh: circleMDLMesh)!
        
        for i in 0..<100 {
            
            var x_r = Float.random(in: -20 ... 20)
            var y_r = Float.random(in: -20 ... 20)
            var z_r = Float.random(in: -20 ... 20)
            
            
            
            let c_r = Float.random(in: 0...1)
            let c_g = Float.random(in: 0...1)
            let c_b = Float.random(in: 0...1)
            
            let modelMatrix = create_modelMatrix(rotation: simd_float3(0), translation: simd_float3(x_r,y_r,z_r), scale: simd_float3(1))
            
            if(i < 50){
                spheres.createInstance(with: modelMatrix, and: simd_float4(c_r,c_g,c_b,1))

            }
            else{
                cube.createInstance(with: modelMatrix, and: simd_float4(c_r,c_g,c_b,1))

            }
                    
            
        }
        

        
        

        
        
      
        
        var skyCamera = Camera(for: mtkView, eye: simd_float3(0,0,10), centre: simd_float3(0,0,-1))
        cameraLists.append(skyCamera)
        
        let projectionMatrix = simd_float4x4(fovRadians: 3.14/2, aspectRatio: 2.0, near: 0.1, far: 100)
        SkyScene = skyBoxScene(device: device, at: mtkView, from: simd_float3(0,0,0), attachTo: skyCamera, with: projectionMatrix)
        SkyScene.addDirectionalLight(with: simd_float3(1,1,0))
        
        let textureLoader = MTKTextureLoader(device: device)
        let cubeTextureOptions: [MTKTextureLoader.Option : Any] = [
          .textureUsage : MTLTextureUsage.shaderRead.rawValue,
          .textureStorageMode : MTLStorageMode.private.rawValue,
          .generateMipmaps : true,
        ]
        skyTexture = try! textureLoader.newTexture(name: "SkyMap", scaleFactor: 1.0, bundle: nil)
        
        SkyScene.setSkyMapTexture(with: Texture(texture: skyTexture, index: textureIDs.cubeMap))
        SkyScene.addNodes(mesh: spheres)
        SkyScene.addNodes(mesh: cube)
        
        let reflectiveMesh = Mesh(device: device, Mesh: circleMDLMesh)
        SkyScene.addReflectiveNode(mesh: reflectiveMesh!,with: 5)
        
        
        
        
      

    }
   
    // mtkView will automatically call this function
    // whenever it wants new content to be rendered.
    
    
   
    
    
    func draw(in view: MTKView) {
        
        SkyScene.renderScene()
        
     
//        guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}
//
//        guard let renderPassDescriptor1 = view.currentRenderPassDescriptor else {return}
//        renderPassDescriptor1.colorAttachments[0].texture = colourRenderTarget
//        renderPassDescriptor1.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
//        renderPassDescriptor1.depthAttachment.texture = depthRenderTarget
//        renderPassDescriptor1.renderTargetArrayLength = 6
//
//        guard let renderEncoder1 = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor1) else {return}
//        renderEncoder1.setRenderPipelineState(renderToCubePipelineColouredMesh.m_pipeLine)
//        renderEncoder1.setVertexAmplificationCount(6, viewMappings: nil)
//        renderEncoder1.setDepthStencilState(depthStencilState)
//
//
////        var instanceConstants = InstanceConstants(modelMatrix: modelMatrix, normalMatrix: normalMatrix)
//
//
//        let projection = simd_float4x4(fovRadians: 3.14/2, aspectRatio: 1, near: 0.1, far: 100)
//
//        var cameraArray = [simd_float4x4]()
//
//        cameraArray.append(simd_float4x4(eye: simd_float3(0), center: simd_float3(1,0,0) , up: simd_float3(0,-1,0)))
//
//        cameraArray.append(simd_float4x4(eye: simd_float3(0), center: simd_float3(-1,0,0) , up: simd_float3(0,-1,0)))
//
//        cameraArray.append(simd_float4x4(eye: simd_float3(0),  center: simd_float3(0,-1,0) , up: simd_float3(0,0,-1)))
//
//        cameraArray.append(simd_float4x4(eye: simd_float3(0), center: simd_float3(0,1,0) , up: simd_float3(0,0,1)))
//
//        cameraArray.append(simd_float4x4(eye: simd_float3(0), center: simd_float3(0,0,1) , up: simd_float3(0,-1,0)))
//
//        cameraArray.append(simd_float4x4(eye: simd_float3(0), center: simd_float3(0,0,-1) , up: simd_float3(0,-1,0)))
//
//        var frameConstants = [FrameConstants]()
//        for i in 0..<6{
//
//            frameConstants.append(FrameConstants(viewMatrix: cameraArray[i], projectionMatrix: projection))
//        }
//
//        var colour = simd_float4(1,0,0,1)
//        renderEncoder1.setVertexBytes(&colour, length: 16, index: 3)
//        renderEncoder1.setVertexBytes(&frameConstants, length: MemoryLayout<FrameConstants>.stride*6, index: vertexBufferIDs.frameConstant)
////        renderEncoder1.setVertexBytes(&instanceConstants, length: MemoryLayout<InstanceConstants>.stride, index: vertexBufferIDs.instanceConstant)
//        MeshesToBeRenderedToCube.draw(renderEncoder: renderEncoder1,with: 1)
//
//        renderEncoder1.setRenderPipelineState(renderToCubePipelineSkyBox.m_pipeLine)
//        CubeMesh?.draw(renderEncoder: renderEncoder1,with: 1)
//
//
//        renderEncoder1.endEncoding()
//
//
//
//
//
//
//        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {return}
//        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
//        renderPassDescriptor.depthAttachment.clearDepth = 1
//
//
//
//        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}
//
//        let projectionMatrix = simd_float4x4(fovRadians: 3.14/2, aspectRatio: 2, near: 0.1, far: 100)
//        let viewMatrix = cameraLists.last!.cameraMatrix
//        var sceneConstants = FrameConstants(viewMatrix: viewMatrix , projectionMatrix: projectionMatrix)
//        renderEncoder.setRenderPipelineState(skyboxpipeline.m_pipeLine)
//        renderEncoder.setVertexBytes(&sceneConstants, length: MemoryLayout<FrameConstants>.stride, index: vertexBufferIDs.frameConstant)
//        //renderEncoder.setFragmentTexture(skyTexture, index: textureIDs.cubeMap)
//        CubeMesh?.draw(renderEncoder: renderEncoder,with: 1)
//        renderEncoder.endEncoding()
//
//
//
//        //testShadowScene.shadowPass(with: commandBuffer, in: view)
//        //testShadowScene.test_pointShadowDepthPass(with: commandBuffer, in: view)
////        fps += 1
////
//
////        guard let renderPassDescriptor1 = view.currentRenderPassDescriptor else {return}
////        renderPassDescriptor1.colorAttachments[0].texture = testTextureArray
////        renderPassDescriptor1.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
////        renderPassDescriptor1.depthAttachment.texture = testDepthTextureArray
////        renderPassDescriptor1.renderTargetArrayLength = 3
////
////        guard let renderEncoder1 = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor1) else {return}
////
////        var mapping0 = MTLVertexAmplificationViewMapping(viewportArrayIndexOffset: 0, renderTargetArrayIndexOffset: 2)
////        var mapping1 = MTLVertexAmplificationViewMapping(viewportArrayIndexOffset: 0, renderTargetArrayIndexOffset: 1)
////        var mapping2 = MTLVertexAmplificationViewMapping(viewportArrayIndexOffset: 0, renderTargetArrayIndexOffset: 0)
////        let mappings = [mapping0,mapping1,mapping2]
////
////        renderEncoder1.setRenderPipelineState(testSlicesRenderingPipeline!.m_pipeLine)
////        renderEncoder1.setVertexAmplificationCount(3, viewMappings: mappings)
////        renderEncoder1.setVertexBuffer(wallVertexBuffer, offset: 0, index: 0)
////        renderEncoder1.drawIndexedPrimitives(type: .triangle, indexCount: 6, indexType: .uint16, indexBuffer: wallIndexBuffer!, indexBufferOffset: 0, instanceCount: 1)
////
////        renderEncoder1.endEncoding()
////
////
////        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {return}
////
////        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
////        renderPassDescriptor.colorAttachments[0].loadAction = .clear
////        renderPassDescriptor.colorAttachments[0].storeAction = .store
////
////
////       guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}
////        var offset : [simd_float4] = [simd_float4(-0.5,0,0,0),simd_float4(0.5,0,0,0),simd_float4(0,0.5,0,0),simd_float4(0,-0.5,0,0)]
////        renderEncoder.setRenderPipelineState(testAmplificationPipeline.m_pipeLine)
////        renderEncoder.setVertexBytes(&offset, length: MemoryLayout<simd_float4>.stride*4, index: 10)
////        renderEncoder.setVertexAmplificationCount(4, viewMappings: nil)
////        renderEncoder.setVertexBuffer(pointBuffer, offset: 0, index: 0)
////        renderEncoder.drawIndexedPrimitives(type: .point, indexCount: 1, indexType: .uint16, indexBuffer: pointIndexBuffer, indexBufferOffset: 0, instanceCount: 1)
////
////        renderEncoder.endEncoding()
//        commandBuffer.present(view.currentDrawable!)
//        commandBuffer.commit()
       
    }

    // mtkView will automatically call this function
    // whenever the size of the view changes (such as resizing the window).
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}
