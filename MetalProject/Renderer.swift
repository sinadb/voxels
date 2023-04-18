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
    var camera : simd_float4x4
    var eye : simd_float3
    var direction : simd_float3
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
    var cameras = [simd_float4x4]()
    var sceneCamera : Camera?


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
        
        
        frameConstants = FrameConstants(viewMatrix: self.camera, projectionMatrix: projection)
        
        let allocator = MTKMeshBufferAllocator(device: device)
        let cubeMDLMesh = MDLMesh(boxWithExtent: simd_float3(1,1,1), segments: simd_uint3(1,1,1), inwardNormals: false, geometryType: .triangles, allocator: allocator)
        skyBoxMesh = Mesh(device: device, Mesh: cubeMDLMesh)!
        let frameConstantBuffer = device.makeBuffer(bytes: &frameConstants, length: MemoryLayout<FrameConstants>.stride,options: [])
        //skyBoxMesh.addUniformBuffer(buffer: UniformBuffer(buffer: frameConstantBuffer!, index: vertexBufferIDs.frameConstant))

       

        let projection = simd_float4x4(fovRadians: 3.14/2, aspectRatio: 1, near: 0.1, far: 100)
        
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
        
        initiatePipeline()
        initialiseRenderTarget()
        
    }

    func attach_camera_to_scene(camera : Camera){
        sceneCamera = camera
    }




    func addNodes(mesh : Mesh){
        // firest pass nodes are being rendered from the centre of reflection
        
        nodes.append(mesh)
        
      

    }

    func addReflectiveNode(mesh : Mesh){
        
        reflectiveNodeMesh = mesh
        let modelMatrix = create_modelMatrix(rotation: simd_float3(0), translation: centreOfReflection, scale: simd_float3(1))
        reflectiveNodeMesh?.createInstance(with: modelMatrix)
        reflectiveNodeMesh?.init_instance_buffers(with: self.camera)
        let frameConstantBuffer = device.makeBuffer(bytes: &frameConstants, length: MemoryLayout<FrameConstants>.stride,options: [])
        reflectiveNodeMesh?.addUniformBuffer(buffer: UniformBuffer(buffer: frameConstantBuffer!, index: vertexBufferIDs.frameConstant))
        reflectiveNodeMesh?.add_textures(texture: renderTarget!)
     
    }

    func setSkyMapTexture(with texture : Texture){
        skyBoxMesh.add_textures(texture: texture)
    }



    func renderScene(){

//        fps += 1
          guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {return}
        renderPassDescriptor.colorAttachments[0].texture = renderTarget?.texture
        renderPassDescriptor.depthAttachment.texture = depthRenderTarget!
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.clearDepth = 1
        renderPassDescriptor.renderTargetArrayLength = 6
//
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}
        renderEncoder.setRenderPipelineState(renderToCubePipelineForMesh!.m_pipeLine)
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setVertexAmplificationCount(6, viewMappings: nil)
        renderEncoder.setVertexBytes(&renderToCubeframeConstants, length: MemoryLayout<FrameConstants>.stride*6, index: vertexBufferIDs.frameConstant)
        for mesh in nodes {
            mesh.draw(renderEncoder: renderEncoder)
        }
        
        renderEncoder.setRenderPipelineState(renderToCubePipelineForSkyBox!.m_pipeLine)
        skyBoxMesh.draw(renderEncoder: renderEncoder, with: 1)
        
        renderEncoder.endEncoding()
//        renderEncoder.setFragmentSamplerState(sampler, index: 0)
//
//        // render nodes
       
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
        guard let finalRenderPassDescriptor = view.currentRenderPassDescriptor else {return}
        finalRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
        finalRenderPassDescriptor.depthAttachment.clearDepth = 1
       finalRenderPassDescriptor.depthAttachment.loadAction = .clear
//
        guard let finalRenderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalRenderPassDescriptor) else {return}
        finalRenderEncoder.setDepthStencilState(depthStencilState)
        finalRenderEncoder.setFrontFacing(.counterClockwise)
        
        finalRenderEncoder.setRenderPipelineState(renderReflectionPipleline!.m_pipeLine)
        finalRenderEncoder.setFragmentBytes(&self.eye, length: 16, index: 0)
        reflectiveNodeMesh?.draw(renderEncoder: finalRenderEncoder,with: 1, culling: .back)
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

        finalRenderEncoder.setRenderPipelineState(renderSkyboxPipeline!.m_pipeLine)
        finalRenderEncoder.setVertexBytes(&frameConstants, length: MemoryLayout<FrameConstants>.stride, index: vertexBufferIDs.frameConstant)
        
        skyBoxMesh.draw(renderEncoder: finalRenderEncoder, with: 1, culling: .front)

        finalRenderEncoder.endEncoding()

        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()



    }
}




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
    var CubeMesh : Mesh?
    var frameConstant : FrameConstants
    var testCamera : Camera
    var initialState = [[simd_float3]]()
    
    
    
    
    var shadowScene : shadowMapScene?
    
   
    var adjustSceneCamera = true
    var testShadowScene : shadowMapScene
    
    
    var skyboxpipeline : pipeLine
    var skyTexture : MTLTexture
    
    var renderToCubePipelineColouredMesh : pipeLine
    var renderToCubePipelineSkyBox : pipeLine
    
    var MeshesToBeRenderedToCube : Mesh
    var colourRenderTarget : MTLTexture
    var depthRenderTarget : MTLTexture
    var SkyScene : skyBoxScene
    
    
    
  
    
    init?(mtkView: MTKView){
      
       
        
        let rotate = simd_float4x4(rotationX: 90)
        print(rotate*simd_float4(-1,0,-1,1))
        
        device = mtkView.device!
        mtkView.preferredFramesPerSecond = 120
        
        commandQueue = device.makeCommandQueue()!
        
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        mtkView.depthStencilPixelFormat = .depth32Float
        
       
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
        let cubeMDLMesh = MDLMesh(boxWithExtent: simd_float3(1,1,1), segments: simd_uint3(1,1,1), inwardNormals: false, geometryType: .triangles, allocator: allocator)
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



                    spheresMesh?.createInstance(with: modelMatrix, and: simd_float4(c_r,c_g,c_b,1))
            
           
        }
        
//        let modelMatrix = create_modelMatrix(rotation: simd_float3(0), translation: simd_float3(0,2,0), scale: simd_float3(1))
//        let modelMatrix1 = create_modelMatrix(rotation: simd_float3(0), translation: simd_float3(0,-2,0), scale: simd_float3(1))
//        spheresMesh?.createInstance(with: modelMatrix,and: simd_float4(1,0,0,1))
//        spheresMesh?.createInstance(with: modelMatrix1 , and: simd_float4(0,1,0,1))
//        
       
      
        
        
            
        

   
      
        
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
       
       
        
        
        
    
        
        
        
        testShadowScene.addPointLight(position: simd_float3(0))
        print("creating point shadow pipeline")
        testShadowScene.init_pointShadowMapPipeline()
        testShadowScene.init_pointShadowRenderTargets()
        
        skyboxpipeline = pipeLine(device, "vertexRenderSkyBox", "fragmentRenderSkyBox", VD, false, label: "SkyboxPipeline")!
        CubeMesh = Mesh(device: device, Mesh: cubeMDLMesh)
        
        let cubeTextureOptions: [MTKTextureLoader.Option : Any] = [
          .textureUsage : MTLTextureUsage.shaderRead.rawValue,
          .textureStorageMode : MTLStorageMode.private.rawValue,
          .cubeLayout : MTKTextureLoader.CubeLayout.vertical,
          
        ]
        
        skyTexture = try! textureLoader.newTexture(name: "SkyMap", scaleFactor: 1.0, bundle: nil, options: cubeTextureOptions)
        
        CubeMesh?.add_textures(texture: Texture(texture: skyTexture, index: textureIDs.cubeMap))
        
        var skyBoxCamera = Camera(for: mtkView, eye: simd_float3(0), centre: simd_float3(0,0,1))
        cameraLists.append(skyBoxCamera)
        
        
        let FC = functionConstant()
        FC.setValue(type: .bool, value: &True, at: FunctionConstantValues.constant_colour)
        FC.setValue(type: .bool, value: &False, at: FunctionConstantValues.cube)
        
        renderToCubePipelineColouredMesh = pipeLine(device, "vertexRenderToCube", "fragmentRenderToCube", VD, true,amplificationCount: 6,functionConstant: FC.functionConstant,label: "RenderToCubePipeline")!
        
        FC.setValue(type: .bool, value: &False, at: FunctionConstantValues.constant_colour)
        FC.setValue(type: .bool, value: &True, at: FunctionConstantValues.cube)
        
        renderToCubePipelineSkyBox = pipeLine(device, "vertexRenderToCube", "fragmentRenderToCube", VD, true,amplificationCount: 6,functionConstant: FC.functionConstant,label: "RenderToCubePipeline")!
        
        MeshesToBeRenderedToCube = Mesh(device: device, Mesh: circleMDLMesh)!
        
        
        let modelMatrix = create_modelMatrix(rotation: simd_float3(0), translation: simd_float3(0,0,-20), scale: simd_float3(3))
        
        
        MeshesToBeRenderedToCube.createInstance(with: modelMatrix, and: simd_float4(0,1,0,1))
        MeshesToBeRenderedToCube.init_instance_buffers(with: simd_float4x4(eye: simd_float3(0), center: simd_float3(0,0,-1), up: simd_float3(0,1,0)))
        
        let shadowMapSize = 1200
        
        let textureDescriptor = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .bgra8Unorm_srgb, size: shadowMapSize, mipmapped: false)
        textureDescriptor.storageMode = .private
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        textureDescriptor.textureType = .typeCube
       
        
        
        let textureDescriptorDepth = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .depth32Float, size: shadowMapSize, mipmapped: false)
        textureDescriptorDepth.storageMode = .private
        textureDescriptorDepth.usage = [.renderTarget, .shaderRead]
        textureDescriptorDepth.textureType = .typeCube
       
        
        colourRenderTarget = device.makeTexture(descriptor: textureDescriptor)!
        depthRenderTarget = device.makeTexture(descriptor: textureDescriptorDepth)!
        
        
        SkyScene = skyBoxScene(device: device, at: mtkView, from: simd_float3(0,0,-5), eye: simd_float3(0,0,-10), direction: simd_float3(0,0,1), with: projectionMatrix)
        SkyScene.setSkyMapTexture(with: Texture(texture: skyTexture, index: textureIDs.cubeMap))
        SkyScene.addNodes(mesh: MeshesToBeRenderedToCube)
        
        let reflectiveMesh = Mesh(device: device, Mesh: circleMDLMesh)
        SkyScene.addReflectiveNode(mesh: reflectiveMesh!)
        
        
        
        
      

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
