//
//  test.metal
//  MetalProject
//
//  Created by Sina Dashtebozorgy on 07/05/2023.
//

#include <metal_stdlib>
using namespace metal;
#include "ShaderDefinition.h"
#include <simd/simd.h>


enum class vertexBufferIDs : int {
    vertexBuffers = 0,
    instanceConstantsBuffer = 1,
    frameConstantsBuffer = 2,
    colour = 3,
    lightConstantBuffer = 4,
    lightbuffer = 5,
    lightCount = 6,
    lightPos = 7,
    
    
};


struct VertexIn{
    
    simd_float4 pos [[attribute(0)]];
    simd_float4 normal [[attribute(1)]];
    simd_float2 tex [[attribute(2)]];
    simd_float4 tangent [[attribute(3)]];
    simd_float4 bitangent [[attribute(4)]];
    
};
struct VertexOut{
    
    float4 pos [[position]];
    float pointSize [[point_size]];
    float4 colour;
    float3 world_normal;
    float3 eye_normal;
    float2 tex;
    float3 tex_3;
    float3 world_pos;
    float3 eye_pos;
    float3 tangent;
    float3 bitangent;
    float3 lightPos;
    
    
    
};

vertex VertexOut render_vertex(VertexIn in [[stage_in]],
                               constant InstanceConstants* instanceTransforms [[buffer(vertexBufferIDs::instanceConstantsBuffer)]],
                               constant FrameConstants& frameTransforms [[buffer(vertexBufferIDs::frameConstantsBuffer)]],
                               const device float4* colourOut [[buffer(vertexBufferIDs::colour)]],
                               uint instanceIndex [[instance_id]]
                               ){
    VertexOut out;
    out.colour = colourOut[instanceIndex];
    simd_float4x4 modelMatrix = instanceTransforms[instanceIndex].modelMatrix;
    simd_float4x4 projectionMatrix = frameTransforms.projectionMatrix;
    simd_float4x4 viewMatrix = frameTransforms.viewMatrix;
    out.pos = projectionMatrix * viewMatrix * modelMatrix * in.pos;
    return out;
}
    
fragment float4 render_fragment(VertexOut in [[stage_in]]){
        
    return in.colour;
}
    
    
    bool test_collision(simd_float3 pos1, simd_float3 pos2, simd_float3 pos3, array<simd_float3, 2> BB){
        
        // fine the centre of the cube and translate the cube to the centre of world
        
        float3 centre = float3( (BB[0][0] + BB[1][0]) * 0.5, (BB[0][1] + BB[1][1]) * 0.5 ,
                               (BB[0][2] + BB[1][2]) * 0.5);
        
        
        // find the vertices of the cube
        
        array<float3, 8> cubeVertices;
        
        cubeVertices[0] = BB[0] - centre;
        cubeVertices[1] = float3(BB[0][0],BB[1][1],BB[0][2]) - centre;
        cubeVertices[2] = float3(BB[1][0],BB[0][1],BB[0][2]) - centre;
        cubeVertices[3] = float3(BB[1][0],BB[1][1],BB[0][2]) - centre;
        
        cubeVertices[4] = BB[1] - centre;
        cubeVertices[5] = float3(BB[0][0],BB[0][1],BB[1][2]) - centre;
        cubeVertices[6] = float3(BB[1][0],BB[0][1],BB[1][2]) - centre;
        cubeVertices[7] = float3(BB[0][0],BB[1][0],BB[1][2]) - centre;
        
        // translate triangle vertices too and put them into an array
        
        array<float3, 3> triangleVertices;
        triangleVertices[0] = pos1 - centre;
        triangleVertices[1] = pos2 - centre;
        triangleVertices[2] = pos3 - centre;
        
        // all the axes that need to be checked against
        
        
        array<float3, 12> axes;
        
        axes[0] = float3(1,0,0);
        axes[1] = float3(0,1,0);
        axes[2] = float3(0,0,1);
//
//        // get the edge to edge axes
//
//        // get the edges
//
        array<float3, 3> triangleEdges = {normalize(triangleVertices[1] - triangleVertices[0]), normalize(triangleVertices[2] - triangleVertices[0]), normalize(triangleVertices[2] - triangleVertices[1])};

        for(int i = 0; i != 3; i++){
            for(int j = 0; j != 3; j++){
                axes[3 + i * 3 + j] = cross(triangleEdges[i], axes[j]);
            }
        }


        for (int i = 0; i != 12; i++){
            float3 SA = axes[i];

            // find the bounds of the triangle against the current SA

            array<float, 2> triangleBB;

            for (int j = 0; j != 3; j++){
                float d = dot(triangleVertices[j], SA);
                if(j == 0){
                    triangleBB[0] = d;
                    triangleBB[1] = d;
                }
                else{
                    triangleBB[0] = min(triangleBB[0], d);
                    triangleBB[1] = max(triangleBB[1],d);
                }

            }

            // find the bounds of the cube against the current SA
            array<float, 2> cubeBB = {0,0};

            for (int k = 0; k != 8; k++){

                float d = dot(cubeVertices[k],SA);

                if(k == 0){
                    cubeBB[0] = d;
                    cubeBB[1] = d;
                }
                else{
                    cubeBB[0] = min(cubeBB[0], d);
                    cubeBB[1] = max(cubeBB[1],d);
                }


            }

            float r = abs(cubeBB[0]);
            float deltaMin = abs(triangleBB[0]) - r;
            float deltaMax = abs(triangleBB[1]) - r;

            bool first = (triangleBB[0] >= cubeBB[0] && triangleBB[0] <= cubeBB[1]);
            bool two = (triangleBB[1] >= cubeBB[0] && triangleBB[1] <= cubeBB[1]);

            bool third = (triangleBB[0] >= cubeBB[0] && triangleBB[1] <= cubeBB[1]);
            bool fourth = (triangleBB[0] <= cubeBB[0] && triangleBB[1] >= cubeBB[1]);

            if(first || two || third || fourth){
                continue;
            }
            else{
                return false;
            }


        }
//
        float3 triangleN = cross(triangleEdges[0], triangleEdges[1]);
        float triangleD = dot(triangleVertices[0],triangleN);



        // find the bounds of the cube against the current SA
        array<float, 2> cubeBB = {0,0};

        for (int k = 0; k != 8; k++){

            float d = dot(cubeVertices[k],triangleN);

            if(k == 0){
                cubeBB[0] = d;
                cubeBB[1] = d;
            }
            else{
                cubeBB[0] = min(cubeBB[0], d);
                cubeBB[1] = max(cubeBB[1],d);
            }


        }
        
       
        
        bool first = (triangleD >= cubeBB[0] && triangleD <= cubeBB[1]);
      
        
        if(first){
            return true;
        }
        else{
            return false;
        }

        
       // we never found an SAT so there is a collision
        //return true;
    }


kernel void compute(const device float3* cubeBB [[buffer(0)]],
                    const device VertexIn* in [[buffer(1)]],
                    const device InstanceConstants& instanceTransform [[buffer(2)]],
                    device simd_float4& colour [[buffer(3)]],
               uint position [[thread_position_in_grid]]
               ){
    
    simd_float4x4 modelMatrix = instanceTransform.modelMatrix;
    float3 pos1 = (modelMatrix * in[0].pos).xyz;
    float3 pos2 = (modelMatrix * in[1].pos).xyz;
    float3 pos3 = (modelMatrix * in[2].pos).xyz;
    array<simd_float3, 2> BoundingBox = {cubeBB[0],cubeBB[1]};
    bool collision = test_collision( pos1, pos2, pos3, BoundingBox);
    
    if(!collision){
        colour = simd_float4(0,1,0,1);
        
    }
    else{
        colour = simd_float4(0,0,0,1);
    }
    
    
    

    
}


