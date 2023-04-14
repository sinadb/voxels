//
//  ShaderDefinition.h
//  MetalProject
//
//  Created by Sina Dashtebozorgy on 22/12/2022.
//

#ifndef ShaderDefinition_h
#define ShaderDefinition_h



#include <simd/simd.h>








struct Transforms {
    simd_float4x4 Scale;
    simd_float4x4 Translate;
    simd_float4x4 Rotation;
    simd_float4x4 Projection;
    simd_float4x4 Camera;
    
};


struct InstanceConstants {
    simd_float4x4 modelMatrix;
    simd_float4x4 normalMatrix;
};

struct FrameConstants {
    simd_float4x4 viewMatrix;
    simd_float4x4 projectionMatrix;
};


struct lightConstants {
    simd_float4x4 lightViewMatrix;
    simd_float4x4 lightProjectionMatrix;
};

struct Lights {
    simd_float3 direction;
    simd_float3 position;
    uint type;
};






#endif /* ShaderDefinition_h */
