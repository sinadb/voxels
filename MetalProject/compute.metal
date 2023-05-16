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
    
    
vertex VertexOut postProcess_vertex(VertexIn in [[stage_in]],
                                    constant InstanceConstants& instanceTransform [[buffer(vertexBufferIDs::instanceConstantsBuffer)]],
                                    constant FrameConstants& frameTransform [[buffer(vertexBufferIDs::frameConstantsBuffer)]]
                                    ){
    VertexOut out;
    out.pos = frameTransform.projectionMatrix * instanceTransform.modelMatrix * in.pos;
    out.tex = in.tex;
    out.world_pos = in.pos.xyz;
    return out;
}

fragment float4 postProcess_fragment(VertexOut in [[stage_in]],
                                     texture2d<float> image [[texture(0)]]
                                     ){
   // float4 pos = in.pos;
     constexpr sampler texture_sampler(filter::nearest,
                                       coord::normalized,
                                       address::clamp_to_edge);
    return float4(1,0,0,1);

}

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
    out.world_normal = in.normal.xyz;
    
    return out;
}
    
fragment float4 render_fragment(VertexOut in [[stage_in]]){
    
    
    if( in.colour.a == 0 ){
        discard_fragment();
    }
    float3 light = normalize(float3(0,1,0));
    float ambientFactor = 0.05;
    float diffuseFactor = saturate(dot(in.world_normal,light));
    float finalFactor = diffuseFactor + ambientFactor;
    return float4(in.colour.rgb * finalFactor, 1);
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
        cubeVertices[7] = float3(BB[0][0],BB[1][1],BB[1][2]) - centre;
        
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

    constant int loopEnd = 100;
    constant int squareSize = loopEnd * loopEnd;
    constant int gridSize = squareSize * loopEnd;
kernel void compute(const device float3* cubeBB [[buffer(0)]],
                    const device float& length [[buffer(4)]],
                    const device VertexIn* in [[buffer(1)]],
                    const device int* indexBuffer [[buffer(9)]],
                    const device InstanceConstants* instanceTransform [[buffer(2)]],
                    device atomic_int* indices [[buffer(6)]],
               uint3 position [[thread_position_in_threadgroup]],
               uint3 nthreads [[threads_per_threadgroup]],
               uint3 groupPosition [[threadgroup_position_in_grid]]
               ){
    
   
    
   
    
   
    
    int index0 = indexBuffer[0 + groupPosition.x * 3];
    int index1 = indexBuffer[1 + groupPosition.x * 3];
    int index2 = indexBuffer[2 + groupPosition.x * 3];
    
    simd_float4x4 modelMatrix = instanceTransform[0].modelMatrix;
    float3 pos1 = (modelMatrix * in[index0].pos).xyz;
    float3 pos2 = (modelMatrix * in[index1].pos).xyz;
    float3 pos3 = (modelMatrix * in[index2].pos).xyz;
  

    
    
    float jump = ( cubeBB[1][0] - cubeBB[0][0] ) / (nthreads.x * length);
    int size = int((cubeBB[1][0] - cubeBB[0][0]) / length);
    

    for(float i = 0 ; i < jump ; i++){
        int stepx = position.x + i * nthreads.x;
        if(stepx >= size){
            break;
        }
        for(float j = 0 ; j < jump ; j++){
            int stepy = position.y + j * nthreads.y;
            if(stepy >= size){
                break;
            }
            for(float k = 0 ; k < jump ; k++){
                int stepz = position.x + k * nthreads.z;
                if(stepz >= size){
                    break;
                }

                uint index = (position.x + i * nthreads.x) * size * size + (position.y + j * nthreads.y) * size + (position.z + k * nthreads.z);
                
//                int value = atomic_load_explicit(&indices[index], memory_order_relaxed);
//                if(value > 0){
//                    break;
//                }
                
                    float3 min = float3(cubeBB[0].x + (position.x + i * nthreads.x) * length,
                                        cubeBB[0].y + (position.y + j * nthreads.y) * length,
                                        cubeBB[0].z + (position.z + k * nthreads.z) * length );
                    float3 max = float3(cubeBB[0].x + (position.x + i * nthreads.x + 1) * length,
                                        cubeBB[0].y + (position.y + j * nthreads.y + 1) * length,
                                        cubeBB[0].z + (position.z + k * nthreads.z + 1) * length );
                    float3 centre = (min + max) * 0.5;
                    array<float3, 2> BoundingBox = {min,max};



                bool collision = test_collision( pos1, pos2, pos3, BoundingBox);
                

               
                if(collision){
                    //atomic_fetch_add_explicit(&indices[index], 1, memory_order_relaxed);
                    int expected = 0;
                    int desired = 1;
                    atomic_compare_exchange_weak_explicit(&indices[index], &expected, desired, memory_order_relaxed, memory_order_relaxed);
                  
                }
            }
        }
        
    }
    
}
    
    //constant int gridSize = 2*2*2;
    
//void kernel final_compute(device int8_t* indices [[buffer(6)]],
//                          device simd_float4* opageGridColourBuffer [[buffer(7)]],
//                          const device int& nTriangles [[buffer(8)]],
//                          device int8_t* outPutIndices [[buffer(9)]],
//                          uint position [[thread_position_in_grid]]
//                          ){
//    int collision = 0;
//    for(int i = 0; i!= nTriangles; i++){
//        int index = position + (i) * gridSize;
//        collision += indices[index];
//        if(collision > 0){
//            outPutIndices[position] = 1;
//           
//            return;
//        }
//    }
//    outPutIndices[position] = 0;
// 
//    
//}
    
    void kernel colour_grid_compute(
                              device simd_float4* opaqueGridColourBuffer [[buffer(7)]],
                              //device int8_t* outPutIndices [[buffer(9)]],
                              device int* indices [[buffer(6)]],
                              uint position [[thread_position_in_grid]]
                              ){
                                  if(indices[position] > 0){
                                      
                                      opaqueGridColourBuffer[position] = simd_float4(1,0.1,0.2,1);
                                  }
                                  else{
                                      opaqueGridColourBuffer[position] = simd_float4(0);
                                  }
                                 
        
        
    }
    
    void kernel fill_voxel(device int* indices [[buffer(6)]],
                           device simd_float4* opaqueGridColourBuffer [[buffer(7)]],
                           uint3 position [[thread_position_in_grid]]
                           ){
        
        
        int startIndex = position.z + position.y * loopEnd;
        int leftIndex = startIndex;
        int rightIndex = startIndex;
        bool fill = false;
        for(int i = 0; i!= loopEnd; i++){
            int current_index = startIndex + i * squareSize;
            if(indices[current_index] > 0){
                leftIndex = current_index;
                break;
            }
        }
        
        for(int i = loopEnd - 1; i >= 0; i--){
            int currentIndex = startIndex + i * squareSize;
            if(indices[currentIndex] > 0){
                rightIndex = currentIndex;
                break;
            }
        }
        if(leftIndex == rightIndex){
            return;
        }
        
        for(int i = leftIndex; i <= rightIndex; i+= squareSize){
            opaqueGridColourBuffer[i] = simd_float4(1,0.1,0.2,1);
            indices[i] = 1;
        }
        
        
        
        
    }
    
vertex VertexOut renderOpageGrid_vertex(VertexIn in [[stage_in]],
                              const device float3* translate [[buffer(vertexBufferIDs::instanceConstantsBuffer)]],
                              const device FrameConstants& frameTransform [[buffer(vertexBufferIDs::frameConstantsBuffer)]],
                              uint index [[instance_id]]
                              ){
    VertexOut out;
    out.pos = frameTransform.projectionMatrix * frameTransform.viewMatrix * float4(in.pos.xyz + translate[index],1);
    out.world_normal = in.normal.xyz;
    out.colour = float4(1,0,0,1);
    return out;
}

fragment float4 renderOpageGrid_fragment(VertexOut in [[stage_in]]){

    float3 light = float3(0,0,1);
    float ambientFactor = 0.1;
    float diffuseFactor = saturate(dot(in.world_normal,light));
    float finalFactor = diffuseFactor + ambientFactor;
    return float4(in.colour.rgb * finalFactor, 1);
}
    
void kernel test_atomic(device atomic_int* buffer [[buffer(0)]],
                        constant int& count [[buffer(1)]],
                        uint position [[thread_position_in_grid]]
                        ){
    int expected = 0;
    for(int i = 0; i!=count; i++){
        atomic_compare_exchange_weak_explicit(&buffer[i], &expected, 1, memory_order_relaxed, memory_order_relaxed);
    }
    
    
}


