#version 120
uniform sampler2D t0;
uniform sampler2D t1;
uniform sampler2D t2;
uniform sampler2D t3;

uniform vec2 t0_scale;
uniform vec2 t1_scale;
uniform vec2 t2_scale;
uniform vec2 t3_scale;

uniform float t0_rotation;
uniform float t1_rotation;
uniform float t2_rotation;
uniform float t3_rotation;

uniform vec4 t0_option;
uniform vec4 t1_option;
uniform vec4 t2_option;
uniform vec4 t3_option;

uniform float t0_available;
uniform float t1_available;
uniform float t2_available;
uniform float t3_available;

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
    
    uMod = clamp(t2_option[2],0.0,1.0);
    vMod = clamp(t2_option[3],0.0,1.0);
    tx2  = texture2D(t2, tex_coord * t2_scale + vec2(timeSpeed*uMod, timeSpeed*vMod));
    
    uMod = clamp(t3_option[2],0.0,1.0);
    vMod = clamp(t3_option[3],0.0,1.0);
    tx3  = texture2D(t3, tex_coord * t3_scale + vec2(timeSpeed*uMod, timeSpeed*vMod));
    
    temp_color = tx0 + tx1 * tx2;
    temp_color.a = mix(0.0, temp_color.a, t0_option[0]);
    temp_color.a = mix(temp_color.a += tx0.a, temp_color.a *= tx0.a, t0_option[1]);
    temp_color.a = mix(temp_color.a += tx1.a, temp_color.a *= tx1.a, t1_option[1]);
    temp_color.a = mix(temp_color.a += tx2.a, temp_color.a *= tx2.a, t2_option[1]);
    
    gl_FragColor = temp_color;
}
