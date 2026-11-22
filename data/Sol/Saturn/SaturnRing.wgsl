#include "././common.wgsh"

struct ObjectUniform
{
    ObjectViewProjectionMatrices: array<mat4x4<f32>, MAX_EYE_COUNT>,
    ObjectMatrix: mat4x4<f32>,
    Custom: vec4<f32>,
};

@group(0) @binding(0) var<uniform> View: ViewUniform;
@group(1) @binding(0) var<uniform> Object: ObjectUniform;
@group(2) @binding(0) var Texture: texture_2d<f32>;
@group(2) @binding(1) var Sampler: sampler;

struct VertexInput 
{
    @location(0) Position: vec3f,
    @location(1) UV: vec2f,
    @location(2) Normal: vec3f,
};

struct FragmentInput 
{
    @builtin(position) Position: vec4f,
    @location(0) UV: vec2f,
    @location(1) Normal: vec3f,
    @location(2) @interpolate(flat) EyeIndex: u32,
};

@vertex
fn vs_main( input: VertexInput, @builtin(instance_index) thread: u32 ) -> FragmentInput 
{
    SetEyeAndInstance( thread );
    
    var output: FragmentInput;
    output.Position = Object.ObjectViewProjectionMatrices[eyeIndex] * vec4f( input.Position, 1.0 );
    ApplyStereoOffset( output.Position, eyeIndex );
    output.UV = input.UV;
    // Transform normal by object matrix (rotation only)
    output.Normal = normalize( (Object.ObjectMatrix * vec4f( input.Normal, 0.0 )).xyz );
    output.EyeIndex = eyeIndex;
    return output;
}

@fragment
fn fs_main( input: FragmentInput ) -> @location(0) vec4f 
{
    ClipStereoFragment( input.Position, input.EyeIndex );
    
    let texColor: vec4f = SampleSRGB( Texture, Sampler, input.UV );
    let lightDir: vec3<f32> = View.LightDirection.xyz;
    let NdotL: f32 = max(dot(normalize(input.Normal), lightDir), 0.0);
    let diffuse: vec3<f32> = View.LightColor.rgb * NdotL + View.AmbientColor.rgb;
    return vec4f(texColor.rgb * diffuse, texColor.a);
}

// Thauros-Development & IA-FORTH - 2025
