#version 120
uniform sampler2D baseTexture;
uniform sampler2D detailTexture;
uniform sampler2D detailTexture2;
uniform sampler2D lightTexture;

uniform float isDetailed;
uniform float isLit;
uniform float isSeconded;
uniform float fogCap;

uniform float time;
varying vec2 tex_coord;
varying vec2 tex_coord_light;
uniform vec4 FrontColor;

uniform float detailScale;
uniform float detailScale2;

void main()
{
    vec4 texel0     = texture2D(baseTexture     , tex_coord);
    vec4 texel1     = texture2D(detailTexture   , tex_coord*detailScale);
    vec4 texel2     = texture2D(detailTexture2  , tex_coord*detailScale2);
    vec4 texel3     = texture2D(lightTexture    , tex_coord_light);
    vec4 white_color = vec4(1.0,1.0,1.0,1.0);
    
    vec4 litDetailed         = mix(texel1.rgba * 2.0 , texel1.rgba, isLit);
    
    vec4 detailed_texture    = mix(white_color       , litDetailed, isDetailed);
    vec4 detailed_texture2   = mix(white_color       , texel2.rgba, isSeconded);
    
    vec4 detail              = mix(detailed_texture2 , detailed_texture , texel0.a);
    vec4 light               = mix(white_color       , texel3.rgba * 2.0, isLit);
    
    vec4 tempcolor = gl_FrontMaterial.diffuse.rgba * (texel0.rgba * detail) * light;
    
    float z = (gl_FragCoord.z / gl_FragCoord.w);
    float fogFactor = 1.0-(z/200.0);
    fogFactor = clamp(fogFactor, fogCap, 1.0);
    gl_FragColor = mix(vec4(0.75,0.75,0.75, 1.0), tempcolor, fogFactor );
    //gl_FragColor = FrontColor;
}
