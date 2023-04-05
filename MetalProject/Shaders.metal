//
//  Shaders.metal
//  MetalProject
//
//  Created by Sina Dashtebozorgy on 23/12/2022.
//

#include <metal_stdlib>
using namespace metal;
#include "ShaderDefinition.h"
#include <simd/simd.h>

enum transformation_mode : int {
    translate_first = 0,
    rotate_first = 1
    };

    

enum class vertexBufferIDs : int {
    vertexBuffers = 0,
    instanceConstantsBuffer = 1,
    frameConstantsBuffer = 2,
    colour = 3,
    lightConstantBuffer = 4,
    
    
};
enum class textureIDs : int {
    cubeMap  = 0,
    flat = 1,
    Normal = 2,
    Displacement = 3,
    depth = 4,
};

enum class fragmentBufferIDs : int {
  colours = 0
};

constant bool cube [[function_constant(0)]];
constant bool flat [[function_constant(1)]];
constant bool no_texture [[function_constant(2)]];
constant bool is_sky_box [[function_constant(3)]];
constant bool fuzzy [[function_constant(4)]];
constant bool has_normal_map [[function_constant(5)]];
constant bool has_displacement_map [[function_constant(6)]];
constant bool shadow_map [[function_constant(7)]];

float4 post_transform_rotate_first(Transforms t, float4 pos){
    return t.Projection*t.Camera*t.Translate*t.Rotation*t.Scale*pos;

}
float4 post_transform_translate_first(Transforms t, float4 pos){
    return t.Projection*t.Camera*t.Rotation*t.Translate*t.Scale*pos;
}

struct VertexIn{
   
    simd_float4 pos [[attribute(0)]];
    simd_float4 normal [[attribute(1)]];
    simd_float2 tex [[attribute(2)]];
    simd_float4 tangent [[attribute(3)]];
    simd_float4 bitangent [[attribute(4)]];
    
};
struct VertexOut{
   
    float4 pos [[position]];
    float4 colour;
    float3 world_normal;
    float3 eye_normal;
    float2 tex;
    float3 tex_3;
    float3 world_pos;
    float3 eye_pos;
    float3 tangent;
    float3 bitangent;
    float3 viewLightPos;
   
    
    
    
};
    
   

    
// render to cube map

struct VertexOutCube{
    float4 pos [[position]];
    float4 colour;
    float4 normal;
    float2 tex;
    float3 tex_3;
    uint face[[render_target_array_index]];
    
};

//vertex VertexOutCube render_to_cube_vertex(VertexIn in [[stage_in]],
//                                           device Transforms *transform [[buffer(vertexBufferIDs::uniformBuffers)]],
//                                           device simd_float4* colour_out [[buffer(vertexBufferIDs::colour)]],
//                                           uint index [[instance_id]],
//                                           constant bool &is_skymap [[buffer(vertexBufferIDs::skyMap)]],
//                                           constant int &transform_mode [[buffer(vertexBufferIDs::order_of_rot_tran)]]
//                                           ){
//    Transforms current_transform = transform[index];
//    VertexOutCube out;
//    if(transform_mode == transformation_mode::translate_first){
//        out.pos = post_transform_translate_first(current_transform, in.pos);
//
//    }
//    else {
//        out.pos = post_transform_rotate_first(current_transform, in.pos);
//
//    }
//    if(is_skymap){
//        out.pos.z = out.pos.w;
//
//    }
//    out.tex = in.tex;
//    out.tex_3 = normalize(in.pos.xyz);
//    out.face = index%6;
//    out.colour = colour_out[index];
//    return out;
//}
//
//fragment float4 render_to_cube_fragment(VertexOutCube in [[stage_in]],
//                                        texturecube<float> cubeMap [[texture(textureIDs::cubeMap)]],
//                                            texture2d<float> flatMap [[texture(textureIDs::flat)]],
//                                                                               constant bool &has_cube [[buffer(3)]],
//                                                                               constant bool &has_flat [[buffer(4)]],
//                                                                               constant bool &has_colour [[buffer(5)]],
//                                                                               sampler textureSampler [[sampler(0)]]
//                                        ){
//
//
//    switch(in.face){
//        case 0:
//            if(has_cube){
//                return cubeMap.sample(textureSampler, in.tex_3);
//            }
//            else if(has_flat){
//                return flatMap.sample(textureSampler,in.tex);
//            }
//            else {
//                return in.colour;
//            }
//        case 1:
//            if(has_cube){
//                return cubeMap.sample(textureSampler, in.tex_3);
//            }
//            else if(has_flat){
//                return flatMap.sample(textureSampler,in.tex);
//            }
//            else {
//                return in.colour;
//            }
//        case 2:
//            if(has_cube){
//                return cubeMap.sample(textureSampler, in.tex_3);
//            }
//            else if(has_flat){
//                return flatMap.sample(textureSampler,in.tex);
//            }
//            else {
//                return in.colour;
//            }
//        case 3:
//            if(has_cube){
//                return cubeMap.sample(textureSampler, in.tex_3);
//            }
//            else if(has_flat){
//                return flatMap.sample(textureSampler,in.tex);
//            }
//            else {
//                return in.colour;
//            }
//        case 4:
//            if(has_cube){
//                return cubeMap.sample(textureSampler, in.tex_3);
//            }
//            else if(has_flat){
//                return flatMap.sample(textureSampler,in.tex);
//            }
//            else {
//                return in.colour;
//            }
//        case 5:
//            if(has_cube){
//                return cubeMap.sample(textureSampler, in.tex_3);
//            }
//            else if(has_flat){
//                return flatMap.sample(textureSampler,in.tex);
//            }
//            else {
//                return in.colour;
//            }
//        default:
//            if(has_cube){
//                return cubeMap.sample(textureSampler, in.tex_3);
//            }
//            else if(has_flat){
//                return flatMap.sample(textureSampler,in.tex);
//            }
//            else {
//                return in.colour;
//            }
//    }
//}
//
//
//
    
    
vertex float4 vertex_shadow(VertexIn in [[stage_in]],
                            constant InstanceConstants* Transforms [[buffer(vertexBufferIDs::instanceConstantsBuffer)]],
                            constant FrameConstants& SceneConstants [[buffer(vertexBufferIDs::frameConstantsBuffer)]],
                            constant lightConstants& lightTransform [[buffer(vertexBufferIDs::lightConstantBuffer)]],
                            uint index [[instance_id]]
                            ){
    simd_float4x4 modelMatrix = Transforms[index].modelMatrix;
    simd_float4x4 projectionMatrix = lightTransform.lightProjectionMatrix;
    simd_float4x4 viewMatrix = lightTransform.lightViewMatirx;
    simd_float4x4 lightProjectViewModel = projectionMatrix * viewMatrix * modelMatrix;
    simd_float4 result = lightProjectViewModel * in.pos;
    return result;
}
    
    
   

vertex VertexOut simple_shader_vertex(VertexIn in [[stage_in]],
                                      constant InstanceConstants* Transforms [[buffer(vertexBufferIDs::instanceConstantsBuffer)]],
                                      constant FrameConstants& SceneConstants [[buffer(vertexBufferIDs::frameConstantsBuffer)]],
                                      constant simd_float4* colour_out [[buffer(vertexBufferIDs::colour)]],
                                      uint index [[instance_id]]
                            ){
    VertexOut out;
    out.colour = colour_out[index];
    simd_float4x4 modelMatrix = Transforms[index].modelMatrix;
    simd_float4x4 normalMatrix = Transforms[index].normalMatrix;
    simd_float4x4 viewMatrix = SceneConstants.viewMatrix;
    simd_float4x4 projectionMatrix = SceneConstants.projectionMatrix;
    simd_float4x4 modelViewMatrix = viewMatrix * modelMatrix;
    
    // world_pos is in eye space so if need world_pos, ensure camera matrix is identity
    out.world_pos = (modelMatrix*in.pos).xyz;
    out.eye_pos = (modelViewMatrix*in.pos).xyz;
    simd_float4 normal = simd_float4(in.normal.xyz,0);
    out.world_normal = normalize((modelMatrix*normal).xyz);
    out.eye_normal = normalize((normalMatrix*in.normal).xyz);
    out.tex_3 = normalize(in.pos.xyz);
    out.tex = in.tex;
    out.pos = projectionMatrix * modelViewMatrix * in.pos;
    
//    if(is_sky_box){
//        simd_float4x4 camera = simd_float4x4(current_transform.Camera[0],current_transform.Camera[1],current_transform.Camera[2],simd_float4(0,0,0,1));
//        out.pos = current_transform.Projection*camera*current_transform.Translate*current_transform.Rotation*current_transform.Scale*in.pos;
//        out.pos.z = out.pos.w;
//
//    }
        
    
    return out;
}
    
    
    static float shadow(float3 worldPos,
                 depth2d<float, access::sample> depthMap,
                  float4x4 lightProjectionViewMatrix
                 ){
        
        constexpr sampler shadowSampler(coord::normalized,
                                           address::clamp_to_edge,
                                           filter::nearest,
                                           compare_func::less);
        simd_float4 shadowNDC = lightProjectionViewMatrix * simd_float4(worldPos,1);
        shadowNDC.xyz /= shadowNDC.w;
        simd_float2 shadowCoord = shadowNDC.xy * 0.5 + 0.5;
        shadowCoord.y = 1 - shadowCoord.y;
        float depthBias = 10e-3f;
        float shadowCoverage = depthMap.sample_compare(shadowSampler, shadowCoord, shadowNDC.z - depthBias);
        return shadowCoverage;
        
        
    }

    
    static float test(depth2d<float> depthMap){
        constexpr sampler shadowSampler(coord::normalized,
                                           address::clamp_to_edge,
                                           filter::linear,
                                           compare_func::less_equal);
        return depthMap.sample_compare(shadowSampler, float2(1), 1.0);
    }
fragment float4 simple_shader_fragment(VertexOut in [[stage_in]],
                                       texturecube<float> cubeMap [[texture(textureIDs::cubeMap),function_constant(cube)]],
                                       texture2d<float> flatMap [[texture(textureIDs::flat),function_constant(flat)]],
                                       texture2d<float> normalMap
                                       [[texture(textureIDs::Normal),function_constant(has_normal_map)]],
                                       depth2d<float> depthMap [[texture(textureIDs::depth),function_constant(shadow_map)]],
                                       constant lightConstants& lightTransforms [[buffer(vertexBufferIDs::lightConstantBuffer),function_constant(shadow_map)]],
                                       sampler textureSampler [[sampler(0)]],
                                       constant bool& renderDepth [[buffer(15)]]
                                       ){
  
    if(has_normal_map){
        simd_float3 L = normalize(in.viewLightPos - in.eye_pos);
        simd_float3 V = normalize(- in.eye_pos);
        float specularExponent = 150;
        simd_float3 H = normalize(L+V);
       

        //light_vector = simd_float3(1,0,0);

        simd_float4 outcolour = flatMap.sample(textureSampler, in.tex);
        simd_float3 tangent = normalize(in.tangent - dot(in.tangent, in.eye_pos) * in.eye_normal);
        simd_float3 bitangent = normalize(cross(in.eye_normal, tangent));
        simd_float3x3 TBN = simd_float3x3(normalize(tangent),bitangent,normalize(in.eye_normal));
        float3 normal = (normalMap.sample(textureSampler, in.tex)).rgb;
        normal = (normal * 2.0 - 1.0);
        //normal.xy *= 3.0;
        normal = normalize(normal);
        //normal = normalize(simd_float3(0.3,0,1));
        normal = normalize(TBN * normal);
        float diffuseFactor = saturate(dot(L,normal));
        float specularFactor = powr(saturate(dot(normal, H)), 150.0) * 50;
        //return float4(specularFactor,0,0,1);
        return (diffuseFactor+specularFactor)*outcolour;
    }
        
    
    if(shadow_map){
                
                constexpr sampler shadowSampler(coord::normalized,
                                                address::clamp_to_edge,
                                                filter::nearest,
                                                compare_func::less_equal);
                float4x4 lightProjectionViewMatrix = lightTransforms.lightProjectionMatrix * lightTransforms.lightViewMatirx;
                simd_float4 fragmentLightPos = lightProjectionViewMatrix * simd_float4(in.world_pos,1);
                simd_float2 fragment_tex = fragmentLightPos.xy * 0.5 + 0.5;
                float depthValue = depthMap.sample(shadowSampler, fragment_tex);
               // return float4(depthValue,depthValue,depthValue,1);
        
        
        float shadowCoverage = shadow(in.world_pos, depthMap, lightProjectionViewMatrix);
        if(shadowCoverage < 0.5){
            return float4(0,0,0,1);
        }
        else{
            if(flat){
                return flatMap.sample(textureSampler, in.tex);
            }
            else{
                return in.colour;
            }
        }
        
    }
    
    else if(cube){
        return cubeMap.sample(textureSampler, in.tex_3);
    }
    else if(flat && !shadow_map){
        return flatMap.sample(textureSampler, in.tex);
    }
    else {
        return in.colour;
    }
    
    
    
}
    
    
    
    fragment float4 shadow_fragment(VertexOut in [[stage_in]],
                                          
                                           texture2d<float> flatMap [[texture(textureIDs::flat),function_constant(flat)]],
                                           depth2d<float> depthMap [[texture(textureIDs::depth),function_constant(shadow_map)]],
                                           constant lightConstants& lightTransforms [[buffer(vertexBufferIDs::lightConstantBuffer),function_constant(shadow_map)]],
                                           sampler textureSampler [[sampler(0)]],
                                           constant bool& renderDepth [[buffer(15)]]
                                           ){
      
    
        
        if(flat){
            constexpr sampler shadowSampler(coord::normalized,
                                            address::clamp_to_edge,
                                            filter::nearest,
                                            compare_func::less_equal);
            float4x4 lightProjectionViewMatrix = lightTransforms.lightProjectionMatrix * lightTransforms.lightViewMatirx;
            simd_float4 fragmentLightPos = lightProjectionViewMatrix * simd_float4(in.world_pos,1);
            simd_float2 fragment_tex = fragmentLightPos.xy * 0.5 + 0.5;
            float depthValue = depthMap.sample(shadowSampler, fragment_tex);
           // return float4(depthValue,depthValue,depthValue,1);
    
    
    float shadowCoverage = shadow(in.world_pos, depthMap, lightProjectionViewMatrix);
    if(shadowCoverage < 0.5){
        return float4(0,0,0,1);
    }
            return flatMap.sample(textureSampler, in.tex);
        }
        else{
            constexpr sampler shadowSampler(coord::normalized,
                                            address::clamp_to_edge,
                                            filter::nearest,
                                            compare_func::less_equal);
            float4x4 lightProjectionViewMatrix = lightTransforms.lightProjectionMatrix * lightTransforms.lightViewMatirx;
            simd_float4 fragmentLightPos = lightProjectionViewMatrix * simd_float4(in.world_pos,1);
            simd_float2 fragment_tex = fragmentLightPos.xy * 0.5 + 0.5;
            float depthValue = depthMap.sample(shadowSampler, fragment_tex);
           // return float4(depthValue,depthValue,depthValue,1);
    
    
    float shadowCoverage = shadow(in.world_pos, depthMap, lightProjectionViewMatrix);
    if(shadowCoverage < 0.5){
        return float4(0,0,0,1);
    }
            return in.colour;
        }
                    
                  
         
        
        
        
        
    }
    
   

//vertex VertexOut cubeMap_reflection_vertex(VertexIn in [[stage_in]],
//                                           constant Transforms &transforms [[buffer(vertexBufferIDs::uniformBuffers)]],
//                                           constant int &transform_mode[[buffer(vertexBufferIDs::order_of_rot_tran)]],
//                                           constant float3 &eye [[buffer(vertexBufferIDs::camera_origin)]]
//                                           ){
//    VertexOut out;
//
//    if(transform_mode == transformation_mode::translate_first){
//        out.pos = post_transform_translate_first(transforms, in.pos);
////        out.world_pos = float3(transforms.Camera*transforms.Rotation*transforms.Translate*transforms.Scale*in.pos);
//        out.world_pos = float3(transforms.Rotation*transforms.Translate*transforms.Scale*in.pos) - eye;
//        out.normal = normalize(float3(transforms.Translate*transforms.Rotation*transforms.Scale*float4(in.normal,0)));
//    }
//    else {
//        out.pos = post_transform_rotate_first(transforms, in.pos);
//        out.world_pos = float3(transforms.Translate*transforms.Rotation*transforms.Scale*in.pos) - eye;
//        out.normal = normalize(float3(transforms.Translate*transforms.Rotation*transforms.Scale*float4(in.normal,0)));
//
//    }
//
//
//    return out;
//}
//
//fragment float4 cubeMap_reflection_fragment(VertexOut in [[stage_in]],
//                                            texturecube<float> cubeMap [[texture(textureIDs::cubeMap)]],
//                                            sampler textureSampler [[sampler(0)]],
//                                            constant simd_float3* random_offsets [[buffer(vertexBufferIDs::points_in_sphere), function_constant(fuzzy)]]
//                                            ){
//    float3 incident = normalize(in.world_pos);
//    if(fuzzy){
//        float4 final_colour = simd_float4(0);
//        for(int i = 0; i!=20; i++){
//            float3 reflection_vector = reflect(incident, in.normal);
//            reflection_vector.y *= -1.0;
//            reflection_vector += 0.1*random_offsets[i];
//            final_colour += cubeMap.sample(textureSampler, reflection_vector);
//        }
//        return final_colour/20.0;
//    }
//    float3 reflection_vector = reflect(incident, in.normal);
//
//        reflection_vector.y *= -1.0;
//
//
//    reflection_vector = normalize(reflection_vector);
//    //return float4(reflection_vector,1);
//    return cubeMap.sample(textureSampler, reflection_vector);
//}


kernel void tess_factor_tri(device MTLTriangleTessellationFactorsHalf& factors [[buffer(0)]], constant int& value [[buffer(1)]]){
    
    
        factors.edgeTessellationFactor[0] = value;
        factors.edgeTessellationFactor[1] = value;
        factors.edgeTessellationFactor[2] = value;
        factors.insideTessellationFactor = value;
}
    
    template<typename T>
    T interpolate_tri(T a, T b, T c, float3 coord){
        return a*coord.x + b*coord.y + c*coord.z;
    }

    
struct PatchIn {
        patch_control_point<VertexIn> controlPoints;
};
[[patch(triangle,3)]]
    
vertex VertexOut post_tesselation_tri(
                                      PatchIn patch [[stage_in]],
                                      constant InstanceConstants* Transforms [[buffer(vertexBufferIDs::instanceConstantsBuffer)]],
                                      constant FrameConstants& SceneConstants [[buffer(vertexBufferIDs::frameConstantsBuffer)]],
                                      constant simd_float4* colour_out [[buffer(vertexBufferIDs::colour)]],
                                      uint index [[instance_id]],
                                      float3 positionInPatch [[position_in_patch]],
                                      texture2d<float> displacement [[texture(textureIDs::Displacement),function_constant(has_displacement_map)]],
                                      sampler textureSampler [[sampler(0),function_constant(has_displacement_map)]],
                                      constant simd_float4& light_pos [[buffer(10)]]
                                      ){
                                          VertexOut out;
                                          
                                          
                                          
                                          simd_float4x4 modelMatrix = Transforms[index].modelMatrix;
                                          simd_float4x4 normalMatrix = Transforms[index].normalMatrix;
                                          simd_float4x4 viewMatrix = SceneConstants.viewMatrix;
                                          simd_float4x4 projectionMatrix = SceneConstants.projectionMatrix;
                                          simd_float4x4 modelViewMatrix = viewMatrix * modelMatrix;
                                          
                                          out.viewLightPos = (viewMatrix * light_pos).xyz;
                                          
                                          // world_pos is in eye space so if need world_pos, ensure camera matrix is identity
//                                          out.world_pos = (modelMatrix*in.pos).xyz;
//                                          out.eye_pos = (modelViewMatrix*in.pos).xyz;
//                                          simd_float4 normal = simd_float4(in.normal.xyz,0);
//                                          out.world_normal = normalize((modelMatrix*normal).xyz);
//                                          out.eye_normal = normalize((normalMatrix*in.normal).xyz);
//                                          out.tex_3 = normalize(in.pos.xyz);
//                                          out.tex = in.tex;
//                                          out.pos = projectionMatrix * modelViewMatrix * in.pos;

                                          float4 aPos = (patch.controlPoints[2].pos);
                                          float4 bPos = (patch.controlPoints[1].pos);
                                          float4 cPos = (patch.controlPoints[0].pos);
                                          float4 aTangent = (patch.controlPoints[2].tangent);
                                          float4 bTangent = (patch.controlPoints[1].tangent);
                                          float4 cTangent = (patch.controlPoints[0].tangent);
                                          float4 aNormal = (patch.controlPoints[2].normal);
                                          float4 bNormal = (patch.controlPoints[1].normal);
                                          float4 cNormal = (patch.controlPoints[0].normal);
                                          float2 aTex = patch.controlPoints[2].tex;
                                          float2 bTex = patch.controlPoints[1].tex;
                                          float2 cTex = patch.controlPoints[0].tex;
                                         
                                          

                                          out.colour = colour_out[index];


                                          float4 new_pos = interpolate_tri(aPos,bPos,cPos,positionInPatch);

                                          out.world_normal =
                                          
                                         (modelMatrix * interpolate_tri(aNormal,bNormal,cNormal,positionInPatch)).xyz;

                                          
                                          out.eye_normal =
                                          (normalMatrix * interpolate_tri(aNormal,bNormal,cNormal,positionInPatch)).xyz;
                                          
                                          
                                          float4 new_tangent = float4(interpolate_tri(aTangent,bTangent,cTangent,positionInPatch).xyz, 0);
                                          
                                          out.tangent = (normalMatrix * new_tangent).xyz;

                                          out.tex = interpolate_tri(aTex, bTex, cTex, positionInPatch);


                                                        

                                          if(has_displacement_map){
                                              float height =  displacement.sample(textureSampler, out.tex).r;

                                                  new_pos.xyz += height * .3 * out.world_normal.xyz;

                                          }

                                          out.pos = projectionMatrix * viewMatrix * modelMatrix * new_pos;
                                                        
                                                        
                                          out.eye_pos = (viewMatrix * modelMatrix * new_pos).xyz;



                                                     //
                                                        

                                          return out;





}
