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
    uniformBuffers = 1,
    skyMap = 3,
    order_of_rot_tran = 4,
    camera_origin = 5,
    colour = 6,
    points_in_sphere = 7
    
};
enum class textureIDs : int {
    cubeMap  = 0,
    flat = 1,
    Normal = 2,
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

float4 post_transform_rotate_first(Transforms t, float4 pos){
    return t.Projection*t.Camera*t.Translate*t.Rotation*t.Scale*pos;

}
float4 post_transform_translate_first(Transforms t, float4 pos){
    return t.Projection*t.Camera*t.Rotation*t.Translate*t.Scale*pos;
}

struct VertexIn{
   
    simd_float4 pos [[attribute(0)]];
    simd_float3 normal [[attribute(1)]];
    simd_float2 tex [[attribute(2)]];
    simd_float4 tangent [[attribute(3)]];
    simd_float4 bitangent [[attribute(4)]];
    
};
struct VertexOut{
   
    float4 pos [[position]];
    float4 colour;
    float3 normal;
    float2 tex;
    float3 tex_3;
    float3 world_pos;
    float3 tangent;
    float3 bitangent;
   
    
    
    
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

vertex VertexOutCube render_to_cube_vertex(VertexIn in [[stage_in]],
                                           device Transforms *transform [[buffer(vertexBufferIDs::uniformBuffers)]],
                                           device simd_float4* colour_out [[buffer(vertexBufferIDs::colour)]],
                                           uint index [[instance_id]],
                                           constant bool &is_skymap [[buffer(vertexBufferIDs::skyMap)]],
                                           constant int &transform_mode [[buffer(vertexBufferIDs::order_of_rot_tran)]]
                                           ){
    Transforms current_transform = transform[index];
    VertexOutCube out;
    if(transform_mode == transformation_mode::translate_first){
        out.pos = post_transform_translate_first(current_transform, in.pos);

    }
    else {
        out.pos = post_transform_rotate_first(current_transform, in.pos);

    }
    if(is_skymap){
        out.pos.z = out.pos.w;

    }
    out.tex = in.tex;
    out.tex_3 = normalize(in.pos.xyz);
    out.face = index%6;
    out.colour = colour_out[index];
    return out;
}

fragment float4 render_to_cube_fragment(VertexOutCube in [[stage_in]],
                                        texturecube<float> cubeMap [[texture(textureIDs::cubeMap)]],
                                            texture2d<float> flatMap [[texture(textureIDs::flat)]],
                                                                               constant bool &has_cube [[buffer(3)]],
                                                                               constant bool &has_flat [[buffer(4)]],
                                                                               constant bool &has_colour [[buffer(5)]],
                                                                               sampler textureSampler [[sampler(0)]]
                                        ){
    
 
    switch(in.face){
        case 0:
            if(has_cube){
                return cubeMap.sample(textureSampler, in.tex_3);
            }
            else if(has_flat){
                return flatMap.sample(textureSampler,in.tex);
            }
            else {
                return in.colour;
            }
        case 1:
            if(has_cube){
                return cubeMap.sample(textureSampler, in.tex_3);
            }
            else if(has_flat){
                return flatMap.sample(textureSampler,in.tex);
            }
            else {
                return in.colour;
            }
        case 2:
            if(has_cube){
                return cubeMap.sample(textureSampler, in.tex_3);
            }
            else if(has_flat){
                return flatMap.sample(textureSampler,in.tex);
            }
            else {
                return in.colour;
            }
        case 3:
            if(has_cube){
                return cubeMap.sample(textureSampler, in.tex_3);
            }
            else if(has_flat){
                return flatMap.sample(textureSampler,in.tex);
            }
            else {
                return in.colour;
            }
        case 4:
            if(has_cube){
                return cubeMap.sample(textureSampler, in.tex_3);
            }
            else if(has_flat){
                return flatMap.sample(textureSampler,in.tex);
            }
            else {
                return in.colour;
            }
        case 5:
            if(has_cube){
                return cubeMap.sample(textureSampler, in.tex_3);
            }
            else if(has_flat){
                return flatMap.sample(textureSampler,in.tex);
            }
            else {
                return in.colour;
            }
        default:
            if(has_cube){
                return cubeMap.sample(textureSampler, in.tex_3);
            }
            else if(has_flat){
                return flatMap.sample(textureSampler,in.tex);
            }
            else {
                return in.colour;
            }
    }
}




vertex VertexOut simple_shader_vertex(VertexIn in [[stage_in]],
                                      constant Transforms* transforms [[buffer(vertexBufferIDs::uniformBuffers)]],
                                      constant int &transform_mode[[buffer(vertexBufferIDs::order_of_rot_tran)]],
                                      device simd_float4* colour_out [[buffer(vertexBufferIDs::colour)]],
                                      uint index [[instance_id]]
                            ){
    VertexOut out;
    out.colour = colour_out[index];
    Transforms current_transform = transforms[index];
    out.tangent = normalize(simd_float3(current_transform.Rotation*current_transform.Scale*in.tangent));
    
    out.normal = normalize((current_transform.Rotation*float4(in.normal,0)).xyz);
    //out.bitangent = normalize(simd_float3(current_transform.Rotation*float4(in.bitangent,0)));
//    out.TBN = simd_float3x3(tangent,bitangent,normal);
    out.bitangent = normalize(cross(out.normal, out.tangent));
   
//
    if(transform_mode == transformation_mode::translate_first){
        out.pos = post_transform_translate_first(current_transform, in.pos);
        out.world_pos = (current_transform.Rotation*current_transform.Translate*current_transform.Scale*in.pos).xyz;

    }
    else {
        out.pos = post_transform_rotate_first(current_transform, in.pos);
        out.world_pos = (current_transform.Translate*current_transform.Rotation*current_transform.Scale*in.pos).xyz;

    }
    if(is_sky_box){
        out.pos.z = out.pos.w;
        
    }
        out.tex_3 = normalize(in.pos.xyz);
        out.tex = in.tex;
    
    return out;
}

fragment float4 simple_shader_fragment(VertexOut in [[stage_in]],
                                       texturecube<float> cubeMap [[texture(textureIDs::cubeMap),function_constant(cube)]],
                                       texture2d<float> flatMap [[texture(textureIDs::flat),function_constant(flat)]],
                                       texture2d<float> normalMap
                                       [[texture(textureIDs::Normal),function_constant(has_normal_map)]],
                                       sampler textureSampler [[sampler(0)]],
                                       constant float4 &colour [[buffer(fragmentBufferIDs::colours),function_constant(no_texture)]]
                                       ){
    
    simd_float3 light_pos = simd_float3(30,0,0);
    simd_float3 light_vector = normalize(light_pos - in.world_pos);
    //light_vector = simd_float3(1,0,0);
    if(has_normal_map){
        simd_float3 colour = flatMap.sample(textureSampler, in.tex).rgb;
        simd_float3 tangent = normalize(in.tangent - dot(in.tangent, in.normal) * in.normal);
        simd_float3 bitangent = normalize(cross(in.normal, tangent));
        simd_float3x3 TBN = simd_float3x3(normalize(tangent),bitangent,normalize(in.normal));
        float3 normal = (normalMap.sample(textureSampler, in.tex)).rgb;
        normal = (normal * 2.0 - 1.0);
        normal.xy *= 30.0;
        normal = normalize(normal);
        //normal = normalize(simd_float3(0.3,0,1));
        normal = normalize(TBN * normal);
        float attenuation = saturate(saturate(dot(light_vector,normal)) + 0.5);
        //return float4(normal,1);
        return float4(attenuation*colour,1);
        
    }
    if(cube){
        return cubeMap.sample(textureSampler, in.tex_3);
    }
    else if(flat){
        return flatMap.sample(textureSampler, in.tex);
    }
    else if(no_texture){
        return colour;
    }
    else {
        return in.colour;
    }
    
}

vertex VertexOut cubeMap_reflection_vertex(VertexIn in [[stage_in]],
                                           constant Transforms &transforms [[buffer(vertexBufferIDs::uniformBuffers)]],
                                           constant int &transform_mode[[buffer(vertexBufferIDs::order_of_rot_tran)]],
                                           constant float3 &eye [[buffer(vertexBufferIDs::camera_origin)]]
                                           ){
    VertexOut out;
    
    if(transform_mode == transformation_mode::translate_first){
        out.pos = post_transform_translate_first(transforms, in.pos);
//        out.world_pos = float3(transforms.Camera*transforms.Rotation*transforms.Translate*transforms.Scale*in.pos);
        out.world_pos = float3(transforms.Rotation*transforms.Translate*transforms.Scale*in.pos) - eye;
        out.normal = normalize(float3(transforms.Translate*transforms.Rotation*transforms.Scale*float4(in.normal,0)));
    }
    else {
        out.pos = post_transform_rotate_first(transforms, in.pos);
        out.world_pos = float3(transforms.Translate*transforms.Rotation*transforms.Scale*in.pos) - eye;
        out.normal = normalize(float3(transforms.Translate*transforms.Rotation*transforms.Scale*float4(in.normal,0)));

    }
    
   
    return out;
}

fragment float4 cubeMap_reflection_fragment(VertexOut in [[stage_in]],
                                            texturecube<float> cubeMap [[texture(textureIDs::cubeMap)]],
                                            sampler textureSampler [[sampler(0)]],
                                            constant simd_float3* random_offsets [[buffer(vertexBufferIDs::points_in_sphere), function_constant(fuzzy)]]
                                            ){
    float3 incident = normalize(in.world_pos);
    if(fuzzy){
        float4 final_colour = simd_float4(0);
        for(int i = 0; i!=20; i++){
            float3 reflection_vector = reflect(incident, in.normal);
            reflection_vector.y *= -1.0;
            reflection_vector += 0.1*random_offsets[i];
            final_colour += cubeMap.sample(textureSampler, reflection_vector);
        }
        return final_colour/20.0;
    }
    float3 reflection_vector = reflect(incident, in.normal);
    reflection_vector.y *= -1.0;
    return cubeMap.sample(textureSampler, reflection_vector);
}
