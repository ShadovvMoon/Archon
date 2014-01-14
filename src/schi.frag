#version 120
uniform sampler2D t0;
uniform sampler2D t1;
uniform vec2 t0_scale;
uniform vec2 t1_scale;
uniform float t0_rotation;
uniform float t1_rotation;
uniform vec4 t0_option;
uniform vec4 t1_option;
uniform float t0_available;
uniform float t1_available;

uniform float time;
varying vec2 tex_coord;
void main()
{
    vec4 tx0;
    vec4 tx1;
    vec4 tx2;
    vec4 tx3;
    float uMod;
    float vMod;
    vec4 temp_color;
    float timeSpeed = time/20000.0;
    
    uMod = clamp(t0_option[2],0.0,1.0);
    vMod = clamp(t0_option[3],0.0,1.0);
    tx0  = texture2D(t0, tex_coord * t0_scale + vec2(timeSpeed*uMod, timeSpeed*vMod));
    
    uMod = clamp(t1_option[2],0.0,1.0);
    vMod = clamp(t1_option[3],0.0,1.0);
    tx1  = texture2D(t1, tex_coord * t1_scale + vec2(timeSpeed*uMod, timeSpeed*vMod));

    gl_FragColor = mix(tx0, tx0 * tx1, t1_available);
}
