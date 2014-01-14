#version 120

varying vec3  Normal;
varying vec3  EyeDir;
varying vec4  EyePos;
varying float LightIntensity;
varying vec4  fragPos;

uniform vec3  BaseColor;
uniform float Depth;
uniform float MixRatio;

// need to scale our framebuffer - it has a fixed width/height of 2048
uniform float FrameWidth;
uniform float FrameHeight;
uniform float textureWidth;
uniform float textureHeight;

uniform sampler2D EnvMap;
uniform sampler2D RefractionMap;

const vec3 Xunitvec = vec3 (1.0, 0.0, 0.0);
const vec3 Yunitvec = vec3 (0.0, 1.0, 0.0);

uniform int ignoreEnvMap;

uniform float time;
varying vec2 tex_coord;
void main()
{
    // Compute reflection vector
    vec3 reflectDir = reflect(EyeDir, Normal);
    
    // Compute altitude and azimuth angles
    vec2 index;
    
    index.y = dot(normalize(reflectDir), Yunitvec);
    reflectDir.y = 0.0;
    index.x = dot(normalize(reflectDir), Xunitvec) * 0.5;
    
    // Translate index values into proper range
    index = (index + 1.0) * 0.5;

    vec3 envColor = vec3 (texture2D(EnvMap, index));
    
    float fresnel = abs(dot(normalize(EyeDir), Normal));
    fresnel *= MixRatio;
    fresnel = clamp(fresnel, 0.01, 0.99);
    
    vec3 refractionDir = normalize(EyeDir) - normalize(Normal);
    float depthVal = Depth / -refractionDir.z;
    float recipW = 1.0 / EyePos.w;
    
    vec2 eye = EyePos.xy * vec2(recipW);
    index.s = (eye.x + refractionDir.x * depthVal);
    index.t = (eye.y + refractionDir.y * depthVal);
    
    // scale and shift so we're in the range 0-1
    index.s = index.s / 2.0 + 0.5;
    index.t = index.t / 2.0 + 0.5;
    eye.x = eye.x / 2.0 + 0.5;
    eye.y = eye.y / 2.0 + 0.5;
    
    // as we're looking at the framebuffer, we want it clamping at the edge of the rendered scene, not the edge of the texture,
    // so we clamp before scaling to fit
    float recipTextureWidth = 1.0 / textureWidth;
    float recipTextureHeight = 1.0 / textureHeight;
    index.s = clamp(index.s, 0.0, 1.0 - recipTextureWidth);
    index.t = clamp(index.t, 0.0, 1.0 - recipTextureHeight);
    eye.x = clamp(eye.x, 0.0, 1.0 - recipTextureWidth);
    eye.y = clamp(eye.y, 0.0, 1.0 - recipTextureHeight);
    
    // scale the texture so we just see the rendered framebuffer
    index.s = index.s * FrameWidth * recipTextureWidth;
    index.t = index.t * FrameHeight * recipTextureHeight;
    eye.x = eye.x * FrameWidth * recipTextureWidth;
    eye.y = eye.y * FrameHeight * recipTextureHeight;
    
    vec3 RefractionColor = vec3 (texture2D(RefractionMap, index));
    vec3 OriginalColor   = vec3 (texture2D(RefractionMap, eye));
    
    vec3 color = mix(OriginalColor,RefractionColor,0.75);
    
    // Add lighting to base color and mix
    vec3 base = LightIntensity * BaseColor;
    envColor = mix(envColor, color, fresnel);
    envColor = mix(envColor, base, 0.2);
    
    vec4 tempcolor = vec4 (envColor, 1.0);
    tempcolor.a = 0.8; // 0.8;
    gl_FragColor.rgb = envColor;
    gl_FragColor.a = 1.0;
    
}
