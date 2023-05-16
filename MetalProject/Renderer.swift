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
    var cameraChanged = false
    
    

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
        if(cameraChanged){
            for mesh in nodes {
                mesh.updateNormalMatrix(with: frameConstants.viewMatrix)

            }
            cameraChanged = false
        }

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
            //mesh.rotateMesh(with: simd_float3(0,Float(fps)*0.2,0), and: camera.cameraMatrix)
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
    var cameraLists = [Camera]()
    
    let posAttrib = Attribute(format: .float4, offset: 0, length: 16, bufferIndex: 0)
    let normalAttrib = Attribute(format: .float3, offset: MemoryLayout<Float>.stride*4,length: 12, bufferIndex: 0)
    let texAttrib = Attribute(format: .float2, offset: MemoryLayout<Float>.stride*7, length : 8, bufferIndex: 0)
    let tangentAttrib = Attribute(format: .float4, offset: MemoryLayout<Float>.stride*9, length : 16, bufferIndex: 0)
    let bitangentAttrib = Attribute(format: .float4, offset: MemoryLayout<Float>.stride*13, length : 16, bufferIndex: 0)
    
    var triangleVertices : [Float] = [-1,-1,0,1, 0,0,1,1,  0,0,0,0,  0,0,0,0, 0,0,0,0,
                                       1,-1,0,1, 0,0,1,1,  0,0,0,0,   0,0,0,0, 0,0,0,0,
                                       0,1,0,1,  0,0,1,1,  0,0,0,0,   0,0,0,0, 0,0,0,0,
                                      
    ]
    var triangleIndices : [uint16] = [0,1,2]
    var triangleVB : MTLBuffer?
    var triangleIB : MTLBuffer?
    let pipeline : pipeLine
    var currentTriangleTranslation = simd_float3(0,0,-15)
    var frameSephamore = DispatchSemaphore(value: 1)
    let computePipeLineState : MTLComputePipelineState
    let finalComputePipeLineState : MTLComputePipelineState
    let colourGridComputePipeLineState : MTLComputePipelineState
    var axisMinMax : MTLBuffer
    var fps = 0
    let cubeMesh : Mesh
    
    
    var frameConstants = FrameConstants(viewMatrix: simd_float4x4(eye: simd_float3(0), center: simd_float3(0,0,-1), up: simd_float3(0,1,0)) , projectionMatrix: simd_float4x4(fovRadians: 3.14/2, aspectRatio: 2.0, near: 0.1, far: 50))
    
    var cubeModelMatrix : simd_float4x4
    var cubeNormalMatrix : simd_float4x4
    
    var triangleModelMatrix : simd_float4x4
    var triangleNormalMatrix : simd_float4x4
    var colourBuffer : MTLBuffer
    let depthStencilState : MTLDepthStencilState
    
    
    
    let postpocessPipeline : pipeLine
    var moveTriangle : Bool = true
    
    
    
   // let linesVB : MTLBuffer
    //let linesIB : MTLBuffer
    
    let quadVertices : [Float] = [
        -1,-1,0,1, 0,0,1,1,  0,0,0,0,  0,0,0,0, 0,0,0,0,
         1,-1,0,1, 0,0,1,1,  1,0,0,0,  0,0,0,0, 0,0,0,0,
         1,1,0,1, 0,0,1,1,  1,1,0,0,  0,0,0,0, 0,0,0,0,
         -1,1,0,1, 0,0,1,1,  0,1,0,0,  0,0,0,0, 0,0,0,0,
    ]
    
    let quadIndices : [uint32] = [
        0,1,2,
        0,2,3
        
    ]
    
//    let quadVB : MTLBuffer
//    let quadIB : MTLBuffer
//
    let postprocessImage : MTLTexture
    
    let gridMesh : GridMesh
    var camera : Camera
    var indicesBuffer : MTLBuffer
    
    var length : Float = 0.02
    let minBound = simd_float3(-2,-2,-14)
    let maxBound = simd_float3(2,2,-10)
    var nthreads : Int {
        return Int((maxBound.y - minBound.y) / length)
    }
  
    let triangleMesh : Mesh
    let outputIndicesBuffer : MTLBuffer
    let coneMesh : Mesh
    var triangleCount : Int32
    let opageGridPipeLine : pipeLine
    let atomicComputeState : MTLComputePipelineState
    let atomicBuffer : MTLBuffer
    
    
    let spotMesh : Mesh
    init?(mtkView: MTKView){
        
        
        device = mtkView.device!
        mtkView.preferredFramesPerSecond = 120
        commandQueue = device.makeCommandQueue()!
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        mtkView.depthStencilPixelFormat = .depth32Float
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilDescriptor.depthCompareFunction = .lessEqual
        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)!
        
        camera = Camera(for: mtkView, eye: simd_float3(0), centre: simd_float3(0,0,-1))
        cameraLists.append(camera)
        
        let allocator = MTKMeshBufferAllocator(device: device)
        let planeMDLMesh = MDLMesh(planeWithExtent: simd_float3(1,1,1), segments: simd_uint2(1,1), geometryType: .triangles, allocator: allocator)
        let cubeMDLMesh = MDLMesh(boxWithExtent: simd_float3(1,1,1), segments: simd_uint3(1,1,1), inwardNormals: false, geometryType: .triangles, allocator: allocator)
        let circleMDLMesh = MDLMesh(sphereWithExtent: simd_float3(1,1,1), segments: simd_uint2(20,20), inwardNormals: False, geometryType: .triangles, allocator: allocator)
        let coneMDLMesh = MDLMesh(coneWithExtent: simd_float3(1,1,1), segments: simd_uint2(20,20), inwardNormals: False, cap: False, geometryType: .triangles, allocator: allocator)
        
        
        
        
        
        
        
        
        
        triangleVB = device.makeBuffer(bytes: &triangleVertices, length: MemoryLayout<Float>.stride * 20 * 3, options: [])
        triangleIB = device.makeBuffer(bytes: &triangleIndices, length: MemoryLayout<uint32>.stride * 3, options: [])
        
        cubeMesh = Mesh(device: device, Mesh: cubeMDLMesh)!
        
        
        
        cubeModelMatrix = create_modelMatrix(translation: simd_float3(0,0,-15), rotation: simd_float3(0), scale: simd_float3(6))
        cubeNormalMatrix = create_normalMatrix(modelViewMatrix: frameConstants.viewMatrix * cubeModelMatrix)
        
        triangleModelMatrix = create_modelMatrix(translation: currentTriangleTranslation, rotation: simd_float3(0), scale: simd_float3(0.1))
        triangleNormalMatrix = create_normalMatrix(modelViewMatrix: frameConstants.viewMatrix * triangleModelMatrix)
        
        
        
        
        let vertexDescriptor = cushionedVertexDescriptor()
        
        pipeline = pipeLine(device, "render_vertex", "render_fragment", vertexDescriptor, false)!
        opageGridPipeLine = pipeLine(device, "renderOpageGrid_vertex", "renderOpageGrid_fragment",vertexDescriptor,false)!
        
        
        let library = device.makeDefaultLibrary()
        let computeFunction = library?.makeFunction(name: "compute")
        computePipeLineState = try! device.makeComputePipelineState(function: computeFunction!)
        //print(computePipeLineState.maxTotalThreadsPerThreadgroup)
        
        let finalComputeFunction = library?.makeFunction(name: "final_compute")
        finalComputePipeLineState = try! device.makeComputePipelineState(function: finalComputeFunction!)
        
        let colourGridComputeFunction = library?.makeFunction(name: "colour_grid_compute")
        colourGridComputePipeLineState = try! device.makeComputePipelineState(function: colourGridComputeFunction!)
        
        let atomicComputeFunction = library?.makeFunction(name: "test_atomic")
        atomicComputeState = try! device.makeComputePipelineState(function: atomicComputeFunction!)
        
        atomicBuffer = device.makeBuffer(length: MemoryLayout<Int32>.stride * 10, options: [])!
        
        
        axisMinMax = device.makeBuffer(length: MemoryLayout<simd_float2>.stride * 3,options: [])!
        
        colourBuffer = device.makeBuffer(length: 16,options: [])!
        
        print("The bounding box of the cube is : ", cubeMesh.boundingBox)
        
        
        postpocessPipeline = pipeLine(device, "postProcess_vertex", "postProcess_fragment", vertexDescriptor, false)!
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: (mtkView.colorPixelFormat), width: 1200, height: 1200, mipmapped: false)
        textureDescriptor.usage = [.shaderRead,.renderTarget]
        
        
        postprocessImage = device.makeTexture(descriptor: textureDescriptor)!
        
        //quadVB = device.makeBuffer(bytes: &quadVertices, length: MemoryLayout<Float>.stride * 4 * 20, options: [])!
        //quadIB = device.makeBuffer(bytes: &quadIndices, length: MemoryLayout<uint32>.stride * 6, options: [])!
        
        //        linesIB = device.makeBuffer(bytes: &linesIndices, length: MemoryLayout<uint32>.stride * 8 * 3, options: [])!
        //        linesVB = device.makeBuffer(bytes: &linesVertices, length: MemoryLayout<Float>.stride * 80 * 2, options: [])!
        //
        
        //        gridMesh = Mesh(device: device, vertices: linesVertices, indices: linesIndices)
        //        let gridmodelMatrix = create_modelMatrix( translation: simd_float3(0,0,-2))
        //        let gridModelMAtrix1 = create_modelMatrix(translation: simd_float3(3,0,-3))
        //        let gridnormalMatrix = simd_float4x4(1)
        //        var gridinstanceData = InstanceConstants(modelMatrix: gridmodelMatrix, normalMatrix: gridnormalMatrix)
        //        gridMesh.createInstance(with: gridmodelMatrix, and: simd_float4(1,0,0,1))
        //        gridMesh.createInstance(with: gridModelMAtrix1, and: simd_float4(0,1,0,1))
        //
        //        gridMesh.init_instance_buffers(with: simd_float4x4(fovRadians: 3.14/1, aspectRatio: 2.0, near: 0.1, far: 20))
        
        
       
        let halfLength : Float = length * 0.5
        
        gridMesh = GridMesh(device: device, minBound: minBound, maxBound: maxBound, length: length)
        
        
       
        
        let n = Int((maxBound.x - minBound.x) / length)
       
        for i in 0..<n{
            let offsetx = halfLength + Float(i) * length
            for j in 0..<n{
                let offsety = halfLength + Float(j) * length
                for k in 0..<n{
                    let offsetz = halfLength + Float(k) * length
                    
                    let centre =  simd_float3(minBound.x + offsetx, minBound.y + offsety, minBound.z + offsetz)
             
                    //                    let c_r = Float.random(in: 0...1)
                    //                    let c_g = Float.random(in: 0...1)
                    //                    let c_b = Float.random(in: 0...1)
                    //let colour = simd_float4(vec3: <#T##simd_float3#>)
                    let modelMatrix = create_modelMatrix(translation: centre,scale: simd_float3(length))
                    cubeMesh.createInstance(with: modelMatrix,and: simd_float4(1,1,0,1))
                    
                }
            }
        }
        cubeMesh.init_instance_buffers(with: camera.cameraMatrix)
        
        
        triangleMesh = Mesh(device: device, vertices: triangleVertices, indices: triangleIndices)
        
        
        triangleMesh.createInstance(with: create_modelMatrix(translation: simd_float3(0.5,0,-11),scale: simd_float3(0.2)),and: simd_float4(1,0,0,1))
       // triangleMesh.createInstance(with: create_modelMatrix(translation: simd_float3(0,0,-11),scale: simd_float3(0.3)),and: simd_float4(1,0,0,1))
       triangleMesh.createInstance(with: create_modelMatrix(translation: simd_float3(-0.5,0,-11),scale: simd_float3(0.2)),and: simd_float4(1,1,0,1))
//        triangleMesh.createInstance(with: create_modelMatrix(translation: simd_float3(0.5,0.5,-11),scale: simd_float3(0.2)),and: simd_float4(0,1,0,1))
//        triangleMesh.createInstance(with: create_modelMatrix(translation: currentTriangleTranslation, rotation: simd_float3(0,0,90), scale: simd_float3(0.3)),and: simd_float4(1,0,0,1))
//        triangleMesh.createInstance(with: create_modelMatrix(translation: currentTriangleTranslation, rotation: simd_float3(0,0,-90), scale: simd_float3(0.3)),and: simd_float4(1,0,0,1))
        //triangleMesh.createInstance(with: create_modelMatrix(translation: currentTriangleTranslation, rotation: simd_float3(0,0,180), scale: simd_float3(0.3)),and: simd_float4(1,0,0,1))
       
        coneMesh = Mesh(device: device, Mesh: circleMDLMesh)!
        coneMesh.createInstance(with: create_modelMatrix(translation: simd_float3(0,0,-12),scale: simd_float3(1)),and: simd_float4(0,1,0,1))
        print(coneMesh.Mesh?.submeshes[0].indexType.rawValue)
        coneMesh.init_instance_buffers(with: camera.cameraMatrix)
        
        
        let assetURL = Bundle.main.url(
            forResource: "spot_triangulated",
            withExtension: "obj")
        
        spotMesh = Mesh(device: device, address: assetURL!, with: "SpotMesh")
        let spotmodelMatrix = create_modelMatrix(translation: simd_float3(0,0,-12),scale: simd_float3(2))
        spotMesh.createInstance(with: spotmodelMatrix, and: simd_float4(1,1,0,1))
        spotMesh.init_instance_buffers(with: camera.cameraMatrix)
        
        
        triangleCount = spotMesh.triangleCount!
        
        print("the number of cubes is : ", cubeMesh.no_instances)
        
        
        triangleMesh.init_instance_buffers(with: camera.cameraMatrix)
        //print(gridMesh.no_instances * triangleMesh.no_instances)
        
        indicesBuffer = device.makeBuffer(length: gridMesh.no_instances * MemoryLayout<Int32>.stride , options: [])!
        outputIndicesBuffer = device.makeBuffer(length: MemoryLayout<Int8>.stride * gridMesh.no_instances,options: [])!
        
    }
   
    // mtkView will automatically call this function
    // whenever it wants new content to be rendered.
    
    
   
    
    
    func draw(in view: MTKView) {
        
        frameSephamore.wait()
        frameConstants.viewMatrix = camera.cameraMatrix
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}
        commandBuffer.addCompletedHandler(){[self] _ in
            frameSephamore.signal()
        }
        
       
        
        if(fps == 0){
           
            
            guard let computeCommandBuffer = commandQueue.makeCommandBuffer() else {return}
            
            
            guard let computeEncoder = computeCommandBuffer.makeComputeCommandEncoder() else {return}
            
            var ptr = gridMesh.BufferArray[1].buffer
            
            
            computeEncoder.setComputePipelineState(computePipeLineState)
            var cubeBB = [minBound,maxBound]
            computeEncoder.setBuffer(indicesBuffer, offset: 0, index: 6)
            computeEncoder.setBytes(&length, length: 4, index: 4)
            computeEncoder.setBuffer(ptr, offset: 0, index: 5)
            computeEncoder.setBytes(&cubeBB, length: MemoryLayout<simd_float3>.stride * 2, index: 0)
            //computeEncoder.setBytes(&coneMesh.Mesh!.vertexBuffers[0].buffer, length: MemoryLayout<Float>.stride * 20 * 3, index: 1)
            computeEncoder.setBuffer(spotMesh.Mesh!.vertexBuffers[0].buffer, offset: 0, index: 1)
            //computeEncoder.setBytes(&triangleInstanceData, length: MemoryLayout<InstanceConstants>.stride, index: 2)
            computeEncoder.setBuffer(spotMesh.BufferArray[0].buffer, offset: 0, index: 2)
            computeEncoder.setBuffer(colourBuffer, offset: 0, index: 3)
            computeEncoder.setBuffer(cubeMesh.BufferArray[1].buffer, offset: 0, index: 7)
            computeEncoder.setBuffer(spotMesh.Mesh!.submeshes[0].indexBuffer.buffer, offset: 0, index: 9)
            
            
            
            //computeEncoder.setBytes(&instace_index, length: MemoryLayout<Int>.stride, index: 8)
            computeEncoder.dispatchThreadgroups(MTLSize(width: Int(triangleCount), height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: 8, height:8, depth: 8))
//            
            
            //computeEncoder.setComputePipelineState(finalComputePipeLineState)
            computeEncoder.setBuffer(outputIndicesBuffer, offset: 0, index: 9)
            computeEncoder.setBytes(&(triangleCount), length: MemoryLayout<Int32>.stride, index: 8)
            computeEncoder.setComputePipelineState(colourGridComputePipeLineState)
            computeEncoder.dispatchThreadgroups(MTLSize(width: gridMesh.no_instances, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1))
          
            computeEncoder.endEncoding()
            computeCommandBuffer.commit()
            computeCommandBuffer.waitUntilCompleted()
        }
        

        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {return}
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
        
        //renderPassDescriptor.colorAttachments[0].texture = postprocessImage
        //renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.depthAttachment.clearDepth = 1
        renderPassDescriptor.depthAttachment.loadAction = .clear
        
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setCullMode(.back)
        //renderEncoder.setTriangleFillMode(.lines)
        

        
        renderEncoder.setRenderPipelineState(pipeline.m_pipeLine)
        
        renderEncoder.setVertexBytes(&frameConstants, length: MemoryLayout<FrameConstants>.stride, index: vertexBufferIDs.frameConstant)
        //cubeMesh.draw(renderEncoder: renderEncoder)
      
       

        
       // gridMesh.draw(renderEncoder: renderEncoder)
        

        //spotMesh.draw(renderEncoder: renderEncoder)
        
        cubeMesh.draw(renderEncoder: renderEncoder)
        
        
        renderEncoder.endEncoding()
        
        

        
        
       
        
        
        commandBuffer.present(view.currentDrawable!)
       
        commandBuffer.commit()
        //commandBuffer.waitUntilCompleted()
        if (fps == 0){
            
            let array = atomicBuffer.contents().bindMemory(to: Int32.self, capacity: 10)
            for i in 0..<10{
                print((array + i).pointee)
            }
        }
        fps+=1
        
        

       
    }

    // mtkView will automatically call this function
    // whenever the size of the view changes (such as resizing the window).
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}
