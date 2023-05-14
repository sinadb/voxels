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
    return out;
}
    
fragment float4 render_fragment(VertexOut in [[stage_in]]){
    
    
    if( in.colour.a == 0 ){
        discard_fragment();
    }
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


    constant int gridSize = 8000;
kernel void compute(const device float3* cubeBB [[buffer(0)]],
                    const device float& length [[buffer(4)]],
                    const device VertexIn* in [[buffer(1)]],
                    const device InstanceConstants* instanceTransform [[buffer(2)]],
                    device simd_float4& colour [[buffer(3)]],
                   // device simd_float4* gridColourBuffer [[buffer(5)]],
                    device int* indices [[buffer(6)]],
                    device simd_float4* opageGridColourBuffer [[buffer(7)]],
                    const device int& instance_index [[buffer(8)]],
               uint3 position [[thread_position_in_threadgroup]],
               uint3 nthreads [[threads_per_threadgroup]],
               uint3 groupPosition [[threadgroup_position_in_grid]]
               ){
    
   
    
    if(position.x == 0){
        colour = simd_float4(0,0,0,1);
    }
    
    float n =  ((cubeBB[1][0] - cubeBB[0][0]) / length);
    float minx = cubeBB[0][0];
    float miny = cubeBB[0][1];
    float minz = cubeBB[0][2];
    
    
    simd_float4x4 modelMatrix = instanceTransform[groupPosition.x].modelMatrix;
    float3 pos1 = (modelMatrix * in[0].pos).xyz;
    float3 pos2 = (modelMatrix * in[1].pos).xyz;
    float3 pos3 = (modelMatrix * in[2].pos).xyz;
    
    // find the bounding box of the triangle and only test those
    float tminx = pos1.x;
    float tmaxx = pos1.x;
    float tminy = pos1.y;
    float tmaxy = pos1.y;
    float tminz = pos1.z;
    float tmaxz = pos1.z;
    
    tminx = min(pos3.x,min(pos2.x,tminx));
    tmaxx = max(pos3.x,max(pos2.x,tmaxx));
//    tminx = min(pos3.x,min(pos3.x,tminx));
//    tmaxx = max(pos3.x,max(pos3.x,tmaxx));
//    
    tminy = min(pos3.y,min(pos2.y,tminy));
    tmaxy = max(pos3.y,max(pos2.y,tmaxy));
//    tminy = min(pos3.y,min(pos3.y,tminy));
//    tmaxy = max(pos3.y,max(pos3.y,tmaxy));
//    
    tminz = min(pos3.z,min(pos2.z,tminz));
    tmaxz = max(pos3.z,max(pos2.z,tmaxz));
//    tminz = min(pos3.z,min(pos3.z,tminz));
//    tmaxz = max(pos3.z,max(pos3.z,tmaxz));
    
    
    float n2 = pow(n, 2);
    
    float start = floor( (tminx - minx) / n);
    float end = start + ((tmaxx - tminx) / n);
    
//    for (float i = 0 ; i != n ; i++ ){
//        for (float j = 0 ; j != n ; j++){
//            for (float k = 0 ; k != n ; k++){
//                float3 min = float3(minx + (i * length), miny + (j * length), minz + (k * length));
//                float3 max = float3(minx + (i + 1) * length, miny + (j + 1) * length, minz + (k + 1) * length);
//                array<float3, 2> BoundingBox = {min,max};
//                bool collision = test_collision(pos1, pos2, pos3, BoundingBox);
//                uint index = i * n2 + j * n + k ;
//                if(!collision){
//                    // gridColourBuffer[index] = simd_float4(0,1,0,1);
//                        opageGridColourBuffer[index] = simd_float4(0);
//                        indices[index] = 0;
//
//                    }
//                    else{
//                       // gridColourBuffer[index] = simd_float4(0,0,0,1);
//                        opageGridColourBuffer[index] = simd_float4(1,0,0,0.5);
//                        indices[index] = 1;
//                    }
//
//            }
//        }
//    }
    
    
    
//    for (float i = 0 ; i != n ; i++ ){
//                float3 min = float3(minx + (i * length), miny + (position.y * length), minz + (position.z * length));
//                float3 max = float3(minx + (i + 1) * length, miny + (position.y + 1) * length, minz + (position.z + 1) * length);
//                array<float3, 2> BoundingBox = {min,max};
//                bool collision = test_collision(pos1, pos2, pos3, BoundingBox);
//                uint index = i * n2 + position.y * n + position.z ;
//                if(!collision){
//                    // gridColourBuffer[index] = simd_float4(0,1,0,1);
//                        opageGridColourBuffer[index] = simd_float4(0);
//                        indices[index] = 0;
//
//                    }
//                    else{
//                       // gridColourBuffer[index] = simd_float4(0,0,0,1);
//                        opageGridColourBuffer[index] = simd_float4(1,0,0,0.5);
//                        indices[index] = 1;
//                    }
//
//    }
    
//    uint maxindex = n * n * n;
//    for(uint i = 0 ; i != maxindex ; i++){
//        if(indices[i] == 0){
//            opageGridColourBuffer[i] = simd_float4(0);
//        }
//    }
    
//
    
    threadgroup uint shared_memory[20*20*20];
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


                    float3 min = float3(cubeBB[0].x + (position.x + i * nthreads.x) * length,
                                        cubeBB[0].y + (position.y + j * nthreads.y) * length,
                                        cubeBB[0].z + (position.z + k * nthreads.z) * length );
                    float3 max = float3(cubeBB[0].x + (position.x + i * nthreads.x + 1) * length,
                                        cubeBB[0].y + (position.y + j * nthreads.y + 1) * length,
                                        cubeBB[0].z + (position.z + k * nthreads.z + 1) * length );
                    float3 centre = (min + max) * 0.5;
                    array<float3, 2> BoundingBox = {min,max};



                bool collision = test_collision( pos1, pos2, pos3, BoundingBox);
                

                uint index = (position.x + i * nthreads.x) * size * size + (position.y + j * nthreads.y) * size + (position.z + k * nthreads.z);
                if(!collision){
                   
                    //if(indices[index] != 1){
                        //opageGridColourBuffer[index] = simd_float4(0);
                    int indexTest = index + groupPosition.x * gridSize;
                        indices[index + groupPosition.x * gridSize ] = 0;

                    //}

                    
                    shared_memory[index] = 0;

                }
                else{
                      
                    int indexTest = index + groupPosition.x * gridSize;
                    indices[index + groupPosition.x * gridSize] = 1;
                    //opageGridColourBuffer[index] = simd_float4(1,0,0,0.5);

                    shared_memory[index] = 1;
                }
            }
        }
        
//        threadgroup_barrier(mem_flags::mem_none);
//        if(position.x == 0 && position.y == 0 && position.z == 0){
//            for (int i = 0; i != 8000 ; i++){
//                if(shared_memory[i] == 1){
//                    opageGridColourBuffer[i] = simd_float4(1,0,0,0.5);
//                }
//                else{
//                    opageGridColourBuffer[i] = simd_float4(0);
//                }
//            }
//        }

    }

    
    
    
//    float3 min = float3(cubeBB[0].x + position.x * length, cubeBB[0].y + position.y * length, cubeBB[0].z + position.z * length );
//    float3 max = float3(cubeBB[0].x + (position.x + 1) * length, cubeBB[0].y + (position.y + 1) * length, cubeBB[0].z + (position.z + 1) * length );
//    float3 centre = (min + max) * 0.5;
//    array<float3, 2> BoundingBox = {min,max};
//
//
//    bool collision = test_collision( pos1, pos2, pos3, BoundingBox);
//
//    uint index = position.x * nthreads.x * nthreads.x + position.y * nthreads.x + position.z ;
//    if(!collision){
//       // gridColourBuffer[index] = simd_float4(0,1,0,1);
//        opageGridColourBuffer[index] = simd_float4(0);
//        indices[index] = 0;
//
//    }
//    else{
//       // gridColourBuffer[index] = simd_float4(0,0,0,1);
//        opageGridColourBuffer[index] = simd_float4(1,0,0,0.5);
//        indices[index] = 1;
//    }

    
    
}
    
    //constant int gridSize = 2*2*2;
    
void kernel final_compute(device int* indices [[buffer(6)]],
                          device simd_float4* opageGridColourBuffer [[buffer(7)]],
                          const device int& nTriangles [[buffer(8)]],
                          device int* outPutIndices [[buffer(9)]],
                          uint position [[thread_position_in_grid]]
                          ){
    int collision = 0;
    for(int i = 0; i!= nTriangles; i++){
        int index = position + (i) * gridSize;
        collision += indices[index];
        if(collision > 0){
            outPutIndices[position] = 1;
            //opageGridColourBuffer[position] = simd_float4(1,0,0,0.5);
            return;
        }
    }
    outPutIndices[position] = 0;
    //opageGridColourBuffer[position] = simd_float4(0);
    
}
    
    void kernel colour_grid_compute(
                              device simd_float4* opageGridColourBuffer [[buffer(7)]],
                              device int* outPutIndices [[buffer(9)]],
                              uint position [[thread_position_in_grid]]
                              ){
                                  if(outPutIndices[position] == 1){
                                      opageGridColourBuffer[position] = simd_float4(1,0,0,0.5);
                                  }
                                  else{
                                      opageGridColourBuffer[position] = simd_float4(0);
                                  }
        
        
    }
    
vertex VertexOut renderOpageGrid_vertex(VertexIn in [[stage_in]],
                              const device float3* translate [[buffer(vertexBufferIDs::instanceConstantsBuffer)]],
                              const device FrameConstants& frameTransform [[buffer(vertexBufferIDs::frameConstantsBuffer)]],
                              uint index [[instance_id]]
                              ){
    VertexOut out;
    out.pos = frameTransform.projectionMatrix * frameTransform.viewMatrix * float4(in.pos.xyz + translate[index],1);
    out.colour = float4(1,0,0,1);
    return out;
}

fragment float4 renderOpageGrid_fragment(VertexOut in [[stage_in]]){

    return in.colour;
}


