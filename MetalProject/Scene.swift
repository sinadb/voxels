//
//  Scene.swift
//  MetalProject
//
//  Created by Sina Dashtebozorgy on 03/04/2023.
//

import Foundation
import Metal
import MetalKit
import AppKit




func generalVertexDescriptor() -> MTLVertexDescriptor {
    
    let posAttrib = Attribute(format: .float4, offset: 0, length: 16, bufferIndex: 0)
    let normalAttrib = Attribute(format: .float3, offset: MemoryLayout<Float>.stride*4,length: 12, bufferIndex: 0)
    let texAttrib = Attribute(format: .float2, offset: MemoryLayout<Float>.stride*7, length : 8, bufferIndex: 0)
    let tangentAttrib = Attribute(format: .float4, offset: MemoryLayout<Float>.stride*9, length : 16, bufferIndex: 0)
    let bitangentAttrib = Attribute(format: .float4, offset: MemoryLayout<Float>.stride*13, length : 16, bufferIndex: 0)
   
    let instanceAttrib = Attribute(format : .float3, offset: 0, length : 12, bufferIndex: 1)
    
    return createVertexDescriptor(attributes: posAttrib,normalAttrib,texAttrib,tangentAttrib,bitangentAttrib)
}


func generalTextureSampler(device : MTLDevice) -> MTLSamplerState {
    let samplerDC = MTLSamplerDescriptor()
    samplerDC.magFilter = .linear
    samplerDC.minFilter = .linear
    samplerDC.rAddressMode = .clampToEdge
    samplerDC.sAddressMode = .clampToEdge
    samplerDC.tAddressMode = .clampToEdge
    samplerDC.normalizedCoordinates = true
    
    return device.makeSamplerState(descriptor: samplerDC)!
}

func createPipelineForDisplacementMapping(device : MTLDevice, vertexDescriptor : MTLVertexDescriptor) -> pipeLine {
    var False = false
    var True = true
    let tempFC = functionConstant()
    
    vertexDescriptor.layouts[0].stepFunction = .perPatchControlPoint
    vertexDescriptor.layouts[0].stepRate = 1
    
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.cube)
    tempFC.setValue(type: .bool, value: &True, at: FunctionConstantValues.flat)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.constant_colour)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.is_skyBox)
    tempFC.setValue(type: .bool, value: &True, at: FunctionConstantValues.has_normalMap)
    tempFC.setValue(type: .bool, value: &True, at: FunctionConstantValues.has_displacementMap)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.shadow_map)
    
    return pipeLine(device, "post_tesselation_tri", "simple_shader_fragment", vertexDescriptor, tempFC.functionConstant, tesselation: true)!
}


func createPipelineForNormalMappedMesh(device : MTLDevice, vertexDescriptor : MTLVertexDescriptor) -> pipeLine {
    
    var False = false
    var True = true
    let tempFC = functionConstant()
    
    
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.cube)
    tempFC.setValue(type: .bool, value: &True, at: FunctionConstantValues.flat)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.constant_colour)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.is_skyBox)
    tempFC.setValue(type: .bool, value: &True, at: FunctionConstantValues.has_normalMap)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.has_displacementMap)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.shadow_map)
    
    return pipeLine(device, "simple_shader_vertex", "simple_shader_fragment", vertexDescriptor, tempFC.functionConstant)!
    
    
}

func createPipelineForFlatTexturedMesh(device : MTLDevice, vertexDescriptor : MTLVertexDescriptor) -> pipeLine {
    
    var False = false
    var True = true
    let tempFC = functionConstant()
    
    
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.cube)
    tempFC.setValue(type: .bool, value: &True, at: FunctionConstantValues.flat)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.constant_colour)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.is_skyBox)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.has_normalMap)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.has_displacementMap)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.shadow_map)
    
    return pipeLine(device, "simple_shader_vertex", "simple_shader_fragment", vertexDescriptor, tempFC.functionConstant)!
    
    
}

func createPipelineForShadowMapping(device : MTLDevice, vertexDescriptor : MTLVertexDescriptor) -> pipeLine {
    var False = false
    var True = true
    let tempFC = functionConstant()
    
    
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.cube)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.flat)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.constant_colour)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.is_skyBox)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.has_normalMap)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.has_displacementMap)
    tempFC.setValue(type: .bool, value: &True, at: FunctionConstantValues.shadow_map)
    
    return pipeLine(device, "simple_shader_vertex", "simple_shader_fragment", vertexDescriptor, tempFC.functionConstant)!
}

func createPipelineForShadowsWithColour(device : MTLDevice, vertexDescriptor : MTLVertexDescriptor) -> pipeLine {
    var False = false
    var True = true
    let tempFC = functionConstant()
    
    
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.cube)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.flat)
    tempFC.setValue(type: .bool, value: &True, at: FunctionConstantValues.constant_colour)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.is_skyBox)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.has_normalMap)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.has_displacementMap)
    tempFC.setValue(type: .bool, value: &True, at: FunctionConstantValues.shadow_map)
    
    return pipeLine(device, "simple_shader_vertex", "shadow_fragment", vertexDescriptor, tempFC.functionConstant)!
}

func createPipelineForShadowsWithFlatTexture(device : MTLDevice, vertexDescriptor : MTLVertexDescriptor) -> pipeLine {
    var False = false
    var True = true
    let tempFC = functionConstant()
    
    
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.cube)
    tempFC.setValue(type: .bool, value: &True, at: FunctionConstantValues.flat)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.constant_colour)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.is_skyBox)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.has_normalMap)
    tempFC.setValue(type: .bool, value: &False, at: FunctionConstantValues.has_displacementMap)
    tempFC.setValue(type: .bool, value: &True, at: FunctionConstantValues.shadow_map)
    
    return pipeLine(device, "simple_shader_vertex", "shadow_fragment", vertexDescriptor, tempFC.functionConstant)!
}

class DefaultScene {
    
    var pointLightPos : simd_float4?
    var defaultPipeline : pipeLine
    var flatTexturedMeshPipeline : pipeLine
    var renderShadowPipeline : pipeLine
    var renderShadows = false
    var depthMap : Texture?
    
    
    var lightTransform : lightConstants?
    var lightCamera : Camera?
    
    var defaultDepthStencilState : MTLDepthStencilState
    var defaultVertexDescriptor : MTLVertexDescriptor
    var sceneConstant : FrameConstants
    var defaultSamplerState : MTLSamplerState
    var sceneCamera : Camera
    
    var defaultMeshes = [Mesh]()
    var flatTexturedMeshed = [Mesh]()
    var normalMappedMesh = [Mesh]()
    var renderDepth = false
    
    var shadowAndConstantColourPipeline : pipeLine
    var shadowAndFlatTexturePipeline : pipeLine
    var normalMappedPipeline : pipeLine
    
    init(device : MTLDevice, projectionMatrix : simd_float4x4, attachTo camera : Camera) {
        var False = false
        var True = true
        
        
        sceneCamera = camera
        
        
        defaultSamplerState = generalTextureSampler(device: device)
        
        let defaultFunctionConstant = functionConstant()
        
        
        defaultFunctionConstant.setValue(type: .bool, value: &False, at: FunctionConstantValues.cube)
        defaultFunctionConstant.setValue(type: .bool, value: &False, at: FunctionConstantValues.flat)
        defaultFunctionConstant.setValue(type: .bool, value: &True, at: FunctionConstantValues.constant_colour)
        defaultFunctionConstant.setValue(type: .bool, value: &False, at: FunctionConstantValues.is_skyBox)
        defaultFunctionConstant.setValue(type: .bool, value: &False, at: FunctionConstantValues.has_normalMap)
        defaultFunctionConstant.setValue(type: .bool, value: &False, at: FunctionConstantValues.has_displacementMap)
        defaultFunctionConstant.setValue(type: .bool, value: &False, at: FunctionConstantValues.shadow_map)
        
        defaultVertexDescriptor = generalVertexDescriptor()
        
        let depthState = MTLDepthStencilDescriptor()
        depthState.depthCompareFunction = .lessEqual
        depthState.isDepthWriteEnabled = true
        defaultDepthStencilState = device.makeDepthStencilState(descriptor: depthState)!
        
        
        
        
        sceneConstant = FrameConstants(viewMatrix: camera.cameraMatrix, projectionMatrix: projectionMatrix)
        
        
        defaultPipeline = pipeLine(device, "simple_shader_vertex", "simple_shader_fragment", defaultVertexDescriptor, defaultFunctionConstant.functionConstant)!
        flatTexturedMeshPipeline = createPipelineForFlatTexturedMesh(device: device, vertexDescriptor: defaultVertexDescriptor)
        renderShadowPipeline = createPipelineForShadowMapping(device: device, vertexDescriptor: defaultVertexDescriptor)
        
        shadowAndFlatTexturePipeline = createPipelineForShadowsWithFlatTexture(device: device, vertexDescriptor: defaultVertexDescriptor)
        shadowAndConstantColourPipeline = createPipelineForShadowsWithColour(device: device, vertexDescriptor: defaultVertexDescriptor)
        normalMappedPipeline = createPipelineForNormalMappedMesh(device: device, vertexDescriptor: defaultVertexDescriptor)
        
        camera.scene = self
        
    }
    
    func addDrawable(mesh : Mesh){
        mesh.init_instance_buffers(with: sceneCamera.cameraMatrix)
        if(!(mesh.has_flat)){
            defaultMeshes.append(mesh)
        }
        else if(mesh.has_normal){
            print("has normal")
            normalMappedMesh.append(mesh)
        }
        else {
            flatTexturedMeshed.append(mesh)
        }
        
    }
    
    
    func cameraHasBeenUpdated(){
       
        
        for mesh in defaultMeshes{
            var ptr = mesh.BufferArray[0].buffer.contents().bindMemory(to: InstanceConstants.self, capacity: mesh.no_instances)
            
           
            
            for i in 0..<mesh.no_instances{
                let normalMatrix = create_normalMatrix(modelViewMatrix: sceneCamera.cameraMatrix * (ptr + i).pointee.modelMatrix)
                
                (ptr + i).pointee.normalMatrix = normalMatrix
               
            }
        }
        
        for mesh in flatTexturedMeshed {
            var ptr = mesh.BufferArray[0].buffer.contents().bindMemory(to: InstanceConstants.self, capacity: mesh.no_instances)
            
           
            
            for i in 0..<mesh.no_instances{
                let normalMatrix = create_normalMatrix(modelViewMatrix: sceneCamera.cameraMatrix * (ptr + i).pointee.modelMatrix)
                
                (ptr + i).pointee.normalMatrix = normalMatrix
               
            }
        }
        
    }
    
    func drawScene(with commandBuffer : MTLCommandBuffer, in view : MTKView) {
        
        if(renderShadows){
            print("rendering shadows")
            guard let renderPassDescriptor = view.currentRenderPassDescriptor else {return}
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
            renderPassDescriptor.depthAttachment.clearDepth = 1
            renderPassDescriptor.depthAttachment.loadAction = .clear

            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}
           
            renderEncoder.setRenderPipelineState(shadowAndConstantColourPipeline.m_pipeLine)
            
            sceneConstant.viewMatrix = sceneCamera.cameraMatrix
            
            sceneConstant.viewMatrix = sceneCamera.cameraMatrix
            renderEncoder.setVertexBytes(&sceneConstant, length: MemoryLayout<FrameConstants>.stride, index: vertexBufferIDs.frameConstant)
            renderEncoder.setFragmentBytes(&lightTransform, length: MemoryLayout<lightConstants>.stride, index: vertexBufferIDs.lightConstant)
            renderEncoder.setFragmentSamplerState(defaultSamplerState, index: 0)
            renderEncoder.setFrontFacing(.counterClockwise)
            renderEncoder.setDepthStencilState(defaultDepthStencilState)
            //renderEncoder.setCullMode(.back)
            renderEncoder.setFragmentTexture(depthMap?.texture, index: textureIDs.depth)
            for mesh in defaultMeshes{
                mesh.draw(renderEncoder: renderEncoder, with: 1)
            }
            
            renderEncoder.setRenderPipelineState(shadowAndFlatTexturePipeline.m_pipeLine)
            for mesh in flatTexturedMeshed {
                mesh.draw(renderEncoder: renderEncoder, with: 1)
            }
            

            renderEncoder.endEncoding()
            return
            
        }
        
        if(renderDepth){
            guard let renderPassDescriptor = view.currentRenderPassDescriptor else {return}
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
            renderPassDescriptor.depthAttachment.clearDepth = 1
            renderPassDescriptor.depthAttachment.loadAction = .clear

            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}
           
            renderEncoder.setRenderPipelineState(renderShadowPipeline.m_pipeLine)
            
           
            
            sceneConstant.viewMatrix = sceneCamera.cameraMatrix
            renderEncoder.setVertexBytes(&sceneConstant, length: MemoryLayout<FrameConstants>.stride, index: vertexBufferIDs.frameConstant)
            
            
            renderEncoder.setFragmentBytes(&lightTransform, length: MemoryLayout<lightConstants>.stride, index: vertexBufferIDs.lightConstant)
            renderEncoder.setFragmentSamplerState(defaultSamplerState, index: 0)
            renderEncoder.setFrontFacing(.counterClockwise)
            renderEncoder.setDepthStencilState(defaultDepthStencilState)
            renderEncoder.setFragmentTexture(depthMap?.texture, index: textureIDs.depth)
            //renderEncoder.setCullMode(.back)
            
            for mesh in defaultMeshes{
                mesh.draw(renderEncoder: renderEncoder, with: 1)
            }
            
            //renderEncoder.setRenderPipelineState(renderShadowPipeline.m_pipeLine)
            for mesh in flatTexturedMeshed {
                mesh.draw(renderEncoder: renderEncoder, with: 1)
            }
            

            renderEncoder.endEncoding()
            return
        }
        
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {return}
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
        renderPassDescriptor.depthAttachment.clearDepth = 1
        renderPassDescriptor.depthAttachment.loadAction = .clear

        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}
       
        renderEncoder.setRenderPipelineState(defaultPipeline.m_pipeLine)
        
        renderEncoder.setVertexBytes(&(pointLightPos!), length: 16, index: vertexBufferIDs.lightWorldPos)
        sceneConstant.viewMatrix = sceneCamera.cameraMatrix
        
        renderEncoder.setVertexBytes(&sceneConstant, length: MemoryLayout<FrameConstants>.stride, index: vertexBufferIDs.frameConstant)
        renderEncoder.setFragmentSamplerState(defaultSamplerState, index: 0)
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setDepthStencilState(defaultDepthStencilState)
        //renderEncoder.setCullMode(.back)
        
        for mesh in defaultMeshes{
            mesh.draw(renderEncoder: renderEncoder, with: 1)
        }
        
        renderEncoder.setRenderPipelineState(flatTexturedMeshPipeline.m_pipeLine)
        for mesh in flatTexturedMeshed {
            mesh.draw(renderEncoder: renderEncoder, with: 1)
        }
        renderEncoder.setRenderPipelineState(normalMappedPipeline.m_pipeLine)
        for mesh in normalMappedMesh{
           
            mesh.draw(renderEncoder: renderEncoder, with: 1)
        }
        

        renderEncoder.endEncoding()
    }
    
    func setPointLight(at position : simd_float4){
        pointLightPos = position
    }
    
}


class shadowMapScene : DefaultScene {
    var shadowMapPipeline : pipeLine?
    var renderTarget : MTLTexture?
    init(device : MTLDevice, projectionMatrix : simd_float4x4, attachTo camera : Camera, with bounds : simd_float3, from lightCamera : Camera){
        super.init(device: device, projectionMatrix: projectionMatrix, attachTo: camera)
        super.renderShadows = true
        
        let lightProjection = simd_float4x4(bounds: bounds, near: 1.0, far: 20)
        
        self.lightCamera = lightCamera
        
        let lightView = self.lightCamera?.cameraMatrix
        
        lightTransform = lightConstants(lightViewMatirx: lightView!, lightProjectionMatrix: lightProjection)
        
        shadowMapPipeline = pipeLine(device, "vertex_shadow", nil, defaultVertexDescriptor ,false)
        
        let shadowMapSize = 1200
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: shadowMapSize, height: shadowMapSize, mipmapped: false)
        textureDescriptor.storageMode = .private
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        renderTarget = device.makeTexture(descriptor: textureDescriptor)
        
        super.depthMap = Texture(texture: renderTarget!, index: textureIDs.depth)
    }
    
    func shadowPass(with commandBuffer : MTLCommandBuffer, in view : MTKView) {
        
       
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {return}
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
        renderPassDescriptor.depthAttachment.clearDepth = 1
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.storeAction = .store
        renderPassDescriptor.depthAttachment.texture = renderTarget!

        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}
       
        renderEncoder.setRenderPipelineState(shadowMapPipeline!.m_pipeLine)
        
      
        // update lighttransforms here
        lightTransform?.lightViewMatirx = lightCamera!.cameraMatrix
        
        renderEncoder.setVertexBytes(&lightTransform, length: MemoryLayout<lightConstants>.stride, index: vertexBufferIDs.lightConstant)
        renderEncoder.setFragmentSamplerState(defaultSamplerState, index: 0)
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setDepthStencilState(defaultDepthStencilState)
        
        
        for mesh in defaultMeshes{
            mesh.draw(renderEncoder: renderEncoder, with: 1, culling: .front)
        }
        
        
        for mesh in flatTexturedMeshed {
            mesh.draw(renderEncoder: renderEncoder, with: 1, culling: .front)
        }
        

        renderEncoder.endEncoding()
        
        super.drawScene(with: commandBuffer, in: view)
    }

    
    
}
