#version 120
uniform sampler2D baseTexture;
uniform sampler2D detailTexture;
uniform int isDetailed;

//Scex information
uniform int scexShader;
uniform int sglaShader;
uniform int swatShader;
uniform int schiShader;
uniform int skipFog;

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

uniform ivec4 t0_option;
uniform ivec4 t1_option;
uniform ivec4 t2_option;
uniform ivec4 t3_option;

uniform int t0_available;
uniform int t1_available;
uniform int t2_available;
uniform int t3_available;

uniform float time;
varying vec2 tex_coord;

uniform int ignoreEnvMap;
//sgla
const vec3 Xunitvec = vec3 (1.0, 0.0, 0.0);
const vec3 Yunitvec = vec3 (0.0, 1.0, 0.0);

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

varying vec3  Normal;
varying vec3  EyeDir;
varying vec4  EyePos;
varying float LightIntensity;
varying vec4  fragPos;

uniform float detailScale;

//Swat
varying vec3 normal, sunNormal;
varying vec4 specular;
uniform vec4 p_Color;
uniform sampler2D p_WaterNormalsTexture; //added
uniform sampler2D p_RefractionMap; //added

varying vec4 shadowCoord; //not needed
uniform sampler2DShadow p_ShadowMap; //not needed

float calculateShadow5()
{
	vec3 shadowST = shadowCoord.xyz / shadowCoord.w;
	float mapScale = 1.0 / 2048.0;
	
	vec2 o = mod(floor(gl_FragCoord.xy), 2.0) * 0.5;
	shadowST.xyz += vec3(o.x, o.y, 0) * mapScale;
	
	vec4 shadowColor = shadow2D(p_ShadowMap, shadowST);
	shadowColor += shadow2D(p_ShadowMap, shadowST.xyz + vec3( mapScale,  mapScale, 0));
	shadowColor += shadow2D(p_ShadowMap, shadowST.xyz + vec3( mapScale, -mapScale, 0));
	shadowColor += shadow2D(p_ShadowMap, shadowST.xyz + vec3(-mapScale,  mapScale, 0));
	shadowColor += shadow2D(p_ShadowMap, shadowST.xyz + vec3(-mapScale, -mapScale, 0));
	shadowColor = shadowColor * 0.2;
    
	return shadowColor.r;
}

float calculateShadow9()
{
	vec3 shadowST = shadowCoord.xyz / shadowCoord.w;
	float mapScale = 1.0 / 2048.0;
	
	vec2 o = mod(floor(gl_FragCoord.xy), 2.0);
	shadowST.xyz += vec3(o.x, o.y, 0) * mapScale;
	
	vec4 shadowColor = shadow2D(p_ShadowMap, shadowST);
	shadowColor += shadow2D(p_ShadowMap, shadowST.xyz + vec3( mapScale,  mapScale, 0));
	shadowColor += shadow2D(p_ShadowMap, shadowST.xyz + vec3( mapScale, -mapScale, 0));
	shadowColor += shadow2D(p_ShadowMap, shadowST.xyz + vec3( mapScale,         0, 0));
	shadowColor += shadow2D(p_ShadowMap, shadowST.xyz + vec3(-mapScale,  mapScale, 0));
	shadowColor += shadow2D(p_ShadowMap, shadowST.xyz + vec3(-mapScale, -mapScale, 0));
	shadowColor += shadow2D(p_ShadowMap, shadowST.xyz + vec3(-mapScale,         0, 0));
	shadowColor += shadow2D(p_ShadowMap, shadowST.xyz + vec3(        0,  mapScale, 0));
	shadowColor += shadow2D(p_ShadowMap, shadowST.xyz + vec3(        0, -mapScale, 0));
	shadowColor = shadowColor * 0.111111111;
    
	return shadowColor.r;
}

void main()
{
    vec4 texel0     = texture2D(baseTexture,   tex_coord);
    vec4 texel1     = texture2D(detailTexture, tex_coord*detailScale);

    float brightness = 2.0;
    vec4 bright = vec4(brightness,brightness,brightness,1.0);

    //Optimised scex shader
    float uMod = 0.0;
    float vMod = 0.0;

    //Brighten object
    vec4 tempcolor;
    if (swatShader == 1)
    {

        //float shadow = calculateShadow5();
        //shadow = clamp(shadow, 0.2, 1.0);
        // Compute reflection vector
        vec3 reflectDir = normalize(reflect(-EyeDir, Normal));
        
        // Compute altitude and azimuth angles
        
        vec2 index;
        
        index.y = dot(normalize(reflectDir), Yunitvec);
        reflectDir.y = 0.0;
        index.x = dot(normalize(reflectDir), Xunitvec) * 0.5;
        
        // Translate index values into proper range
        
        if (reflectDir.z >= 0.0)
            index = (index + 1.0) * 0.5;
        else
        {
            index.t = (index.t + 1.0) * 0.5;
            index.s = (-index.s) * 0.5 + 1.0;
        }
        
        
        
        // calc fresnels term.  This allows a view dependant blend of reflection/refraction
        float fresnel = 0.8;
        
        // calc refraction
        vec3 refractionDir = normalize(EyeDir) - normalize(Normal);
        
        
        // Scale the refraction so the z element is equal to depth
        float depthVal = Depth / -refractionDir.z;
        
        float distance = sqrt(pow(fragPos.x - EyePos.x,2)+pow(fragPos.y - EyePos.y,2)+pow(fragPos.z - EyePos.z,2));;
        if (distance > 1000)
            distance = 1000;
        else if (distance < 2)
            distance = 2;
        
        distance/=2;
        
        float scaled = 1/distance;
        
        scaled = 1.0;
        vec3 wnTex0 = normalize((texture2D(p_WaterNormalsTexture, gl_TexCoord[0].xy * vec2(scaled,scaled)).xyz - vec3(0.5, 0.5, 0.5)));
        vec3 wnTex1 = normalize((texture2D(p_WaterNormalsTexture, gl_TexCoord[1].xy * vec2(scaled,scaled)).xyz - vec3(0.5, 0.5, 0.5)));
        vec3 wnTex2 = normalize((texture2D(p_WaterNormalsTexture, -0.25 * gl_TexCoord[1].xy).xyz - vec3(0.5, 0.5, 0.5)));
        vec3 n = normalize(wnTex0 + wnTex1);
        vec3 n2 = normalize(wnTex0 + wnTex1 + wnTex2);
        
        
        float ld = (1.0 + dot(n2, normalize(vec3(1, 1, -1)))) * 0.5;
        ld = pow(ld, 5.0);
        ld -= 0.0;

        // perform the div by w
        float recipW = 1.0 / EyePos.w;
        vec2 eye = EyePos.xy * vec2(recipW);
        
        // calc the refraction lookup
        index.s = eye.x;
        index.t = eye.y;
        
        // scale and shift so we're in the range 0-1
        index.s = index.s / 2.0 + 0.5;
        index.t = index.t / 2.0 + 0.5;
        
        // as we're looking at the framebuffer, we want it clamping at the edge of the rendered scene, not the edge of the texture,
        // so we clamp before scaling to fit
        float recipTextureWidth = 1.0 / textureWidth;
        float recipTextureHeight = 1.0 / textureHeight;
        index.s = clamp(index.s, 0.0, 1.0 - recipTextureWidth);
        index.t = clamp(index.t, 0.0, 1.0 - recipTextureHeight);
        
        // scale the texture so we just see the rendered framebuffer
        index.s = index.s * FrameWidth * recipTextureWidth;
        index.t = index.t * FrameHeight * recipTextureHeight;
        
        //Clip edges
        float border = 5;
        float scaler = textureWidth/1440.0;
        if (gl_FragCoord.x>border*scaler && gl_FragCoord.x < FrameWidth-border*scaler && gl_FragCoord.y>border*scaler && gl_FragCoord.y < FrameHeight-border*scaler)
            index.st += 0.05 * n.xy;
        
        vec3 RefractionColor = vec3 (texture2D(RefractionMap, index));
        
        vec3 light_position = vec3(0,0,0);
        vec3 L = normalize(light_position.xyz - EyePos.xyz);
        vec3 E = normalize(-EyePos.xyz); // we are in Eye Coordinates, so EyePos is (0,0,0)
        vec3 R = normalize(-reflect(L,n));
        
        float shiny = 0.8 - dot(n, L);
        vec4 cvec = vec4(1, 1, 1, 0);
        
        //vec4 color = (texture2D(p_RefractionMap, gl_TexCoord[2].xy) + (vec4(1, 1, 1, 0) * ld));
        vec4 color = vec4(RefractionColor.rgb, 1.0) * gl_FrontMaterial.diffuse.rgba;// + (cvec * ld);
        gl_FragColor = vec4(color.x, color.y, color.z, fresnel);
        
        return;
    }
    else if (sglaShader == 1)
    {
        // Compute reflection vector
        vec3 reflectDir = reflect(EyeDir, Normal);
        
        // Compute altitude and azimuth angles
        
        vec2 index;
        
        index.y = dot(normalize(reflectDir), Yunitvec);
        reflectDir.y = 0.0;
        index.x = dot(normalize(reflectDir), Xunitvec) * 0.5;
        
        // Translate index values into proper range
        
        if (reflectDir.z >= 0.0)
            index = (index + 1.0) * 0.5;
        else
        {
            index.t = (index.t + 1.0) * 0.5;
            index.s = (-index.s) * 0.5 + 1.0;
        }
        
        // if reflectDir.z >= 0.0, s will go from 0.25 to 0.75
        // if reflectDir.z <  0.0, s will go from 0.75 to 1.25, and
        // that's OK, because we've set the texture to wrap.
        
        // Do a lookup into the environment map.
        
        vec3 envColor = vec3 (texture2D(EnvMap, index));
      
        // calc fresnels term.  This allows a view dependant blend of reflection/refraction
        float fresnel = abs(dot(normalize(EyeDir), Normal));
        fresnel *= MixRatio;
        fresnel = clamp(fresnel, 0.01, 0.99);
        
        // calc refraction
        vec3 refractionDir = normalize(EyeDir) - normalize(Normal);
        

        // Scale the refraction so the z element is equal to depth
        float depthVal = Depth / -refractionDir.z;
        
        if (ignoreEnvMap == 1)
        {
            if (depthVal > 1.0)
                depthVal = 1.0;
            
            if (depthVal < 0.3)
                depthVal = 0.3;
        }
        
        // perform the div by w
        float recipW = 1.0 / EyePos.w;
        vec2 eye = EyePos.xy * vec2(recipW);
        
        // calc the refraction lookup
        index.s = (eye.x + refractionDir.x * depthVal);
        index.t = (eye.y + refractionDir.y * depthVal);
        
        // scale and shift so we're in the range 0-1
        index.s = index.s / 2.0 + 0.5;
        index.t = index.t / 2.0 + 0.5;
        
        // as we're looking at the framebuffer, we want it clamping at the edge of the rendered scene, not the edge of the texture,
        // so we clamp before scaling to fit
        float recipTextureWidth = 1.0 / textureWidth;
        float recipTextureHeight = 1.0 / textureHeight;
        index.s = clamp(index.s, 0.0, 1.0 - recipTextureWidth);
        index.t = clamp(index.t, 0.0, 1.0 - recipTextureHeight);
        
        // scale the texture so we just see the rendered framebuffer
        index.s = index.s * FrameWidth * recipTextureWidth;
        index.t = index.t * FrameHeight * recipTextureHeight;
        
        vec3 RefractionColor = vec3 (texture2D(RefractionMap, index));
        
        // Add lighting to base color and mix
        vec3 base = LightIntensity * BaseColor;
        envColor = mix(envColor, RefractionColor, fresnel);
        envColor = mix(envColor, base, 0.2);
        
        tempcolor = vec4 (envColor, 1.0);
        tempcolor.a = 0.8; // 0.8;
        
        if (ignoreEnvMap == 1)
        {
            vec4 texColor = vec4 (texture2D(t0, gl_TexCoord[0].st));
            tempcolor.rgb = texColor.rgb * texColor.a + envColor * (1-texColor.a);
            tempcolor.a = texColor.a * (1.9-(fresnel));
        }
        
        
        
        //tempcolor = vec4(0.0,0.0,0.0,0.5);
        /*
        tempcolor = gl_FrontMaterial.diffuse.rgba;
        tempcolor.a = 0.2;
         */
    }
    else if (scexShader == 1)
    {
        float uMod = 0.0;
        float vMod = 0.0;
        
        gl_FragColor = gl_FrontMaterial.diffuse.rgba;
        
        float timeSpeed = time/20000.0;
        
        if (t0_option[2] != 0)
            uMod = 1.0;
        if (t0_option[3] != 0)
            vMod = 1.0;
        
        vec4 tx0     = texture2D(t0, tex_coord * t0_scale + vec2(timeSpeed*uMod, timeSpeed*vMod));
        
        uMod=0.0;
        vMod=0.0;
        if (t1_option[2] != 0)
            uMod = 1.0;
        if (t1_option[3] != 0)
            vMod = 1.0;
        
        vec4 tx1     = texture2D(t1, tex_coord * t1_scale + vec2(timeSpeed*uMod, timeSpeed*vMod) );

        uMod=0.0;
        vMod=0.0;
        if (t2_option[2] != 0)
            uMod = 1.0;
        if (t2_option[3] != 0)
            vMod = 1.0;
        
        vec4 tx2     = texture2D(t2, tex_coord * t2_scale + vec2(timeSpeed*uMod, timeSpeed));
        
        uMod=0.0;
        vMod=0.0;
        if (t3_option[2] != 0)
            uMod = 1.0;
        if (t3_option[3] != 0)
            vMod = 1.0;
        
        vec4 tx3     = texture2D(t3, tex_coord * t3_scale + vec2(timeSpeed*uMod, timeSpeed*vMod));
        if (t3_available == 1)
        {
            tempcolor = tx0 + tx1 * tx2;
        }
        else
        {
            if (t0_option[0] != 2)
            {
                tempcolor = tx0 + tx1 * tx2  ;
                tempcolor.a = 0.0;
                if (t0_option[1] == 2)
                    tempcolor.a *= tx0.a;
                else
                    tempcolor.a += tx0.a;
                
                if (t1_option[1] == 2)
                    tempcolor.a *= tx1.a;
                else
                    tempcolor.a += tx1.a;
                
                if (t2_option[1] == 2)
                    tempcolor.a *= tx2.a;
                else
                    tempcolor.a += tx2.a;
                
                // = tx0.a * tx1.a * tx2.a;
            }
            else
                tempcolor = tx0 + tx1 * tx2;
        }
    }
    else if (schiShader == 1)
    {
        float uMod = 0.0;
        float vMod = 0.0;
        
        tempcolor = gl_FrontMaterial.diffuse.rgba;
        
        float timeSpeed = time/20000.0;
        
        if (t0_option[2] != 0)
            uMod = 1.0;
        if (t0_option[3] != 0)
            vMod = 1.0;
        
        
        vec4 tx0     = texture2D(t0, tex_coord * t0_scale + vec2(timeSpeed*uMod, timeSpeed*vMod));
        
        uMod=0.0;
        vMod=0.0;
        if (t1_option[2] != 0)
            uMod = 1.0;
        if (t1_option[3] != 0)
            vMod = 1.0;
        
        vec4 tx1     = texture2D(t1, tex_coord * t1_scale + vec2(timeSpeed*uMod, timeSpeed*vMod));
        
        if (t1_available == 1)
        {
            tempcolor = tx0 * tx1;
        }
        else
        {
            tempcolor = tx0;
        }
    }
    else if (isDetailed == 1)
    {
        tempcolor = gl_FrontMaterial.diffuse.rgba * texel0.rgba * texel1.rgba * bright;
    }
    else
    {
        tempcolor = gl_FrontMaterial.diffuse.rgba * texel0.rgba;
    }
    
    if (swatShader != 1)
    {
        if (skipFog != 1 && (sglaShader != 1 || ignoreEnvMap == 1) )
        {
            float z = (gl_FragCoord.z / gl_FragCoord.w);
            float fogFactor = 1.0-(z/200.0);
            
            if ((gl_FragCoord.z / gl_FragCoord.w) > 200.0)
            {
                fogFactor = 0.0;
            }
            
            fogFactor = clamp(fogFactor, 0.0, 1.0);
            gl_FragColor = mix(vec4(0.75,0.75,0.75, 1.0), tempcolor, fogFactor );
        }
        else
        {
            gl_FragColor = tempcolor;
        }
    }
}
