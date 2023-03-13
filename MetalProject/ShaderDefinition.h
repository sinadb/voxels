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








#endif /* ShaderDefinition_h */
