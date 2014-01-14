#version 120

attribute vec2 texCoord_buffer_light;
attribute vec2 texCoord_buffer;

varying vec2 tex_coord;
varying vec2 tex_coord_light;

uniform vec3 global_positionData;
uniform vec3 global_rotationData;

void main()
{
    tex_coord       = texCoord_buffer;
    tex_coord_light = texCoord_buffer_light;
    gl_Position  = ftransform();
    gl_ClipVertex = gl_ModelViewMatrix * gl_Vertex;
}
