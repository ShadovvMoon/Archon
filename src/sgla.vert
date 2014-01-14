#version 120

attribute vec2 texCoord_buffer_light;
attribute vec2 texCoord_buffer;

varying vec2 tex_coord;

varying vec3  Normal;
varying vec3  EyeDir;
varying vec4  EyePos;
varying float LightIntensity;
uniform vec3  LightPos;

uniform vec3 global_positionData;
uniform vec3 global_rotationData;

attribute vec3 VertexNormal;

void main()
{
    tex_coord       = texCoord_buffer;
    gl_Position  = ftransform();
    gl_ClipVertex = gl_ModelViewMatrix * gl_Vertex;
    
    Normal         = normalize(gl_NormalMatrix * VertexNormal);
    vec4 pos       = gl_ModelViewMatrix * gl_Vertex;
    EyeDir         = pos.xyz;
    EyePos		   = gl_ModelViewProjectionMatrix * gl_Vertex;
    LightIntensity = max(dot(normalize(LightPos - EyeDir), Normal), 0.0);
}
