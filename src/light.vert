#version 120

varying vec3  Normal;
varying vec3  EyeDir;
varying vec4  EyePos;
varying float LightIntensity;
uniform vec3  LightPos;


//Swat
uniform int swatShader;
uniform float time;
varying vec3 normal, sunNormal;
varying vec4 shadowCoord;
varying vec4 specular;
varying vec4  fragPos;

attribute vec3 normals_buffer;
attribute vec2 texCoord_buffer;
varying vec2 tex_coord;

void main()
{
    tex_coord[0] = texCoord_buffer[0];
    tex_coord[1] = texCoord_buffer[1];
    gl_ClipVertex = gl_ModelViewMatrix * gl_Vertex;
    
    if (swatShader != 1)
    {
        gl_TexCoord[0] = gl_MultiTexCoord0;
        gl_TexCoord[1] = gl_TextureMatrix[1] * gl_MultiTexCoord0;

        gl_Position    = ftransform();
        

 
        Normal         = normalize(gl_NormalMatrix * gl_Normal);
        vec4 pos       = gl_ModelViewMatrix * gl_Vertex;
        EyeDir         = pos.xyz;
        EyePos		   = gl_ModelViewProjectionMatrix * gl_Vertex;
        LightIntensity = max(dot(normalize(LightPos - EyeDir), Normal), 0.0);
    }
    else
    {
        Normal         = normalize(gl_NormalMatrix * normals_buffer);
        vec4 pos       = gl_ModelViewMatrix * gl_Vertex;
        EyeDir         = pos.xyz;
        EyePos		   = gl_ModelViewProjectionMatrix * gl_Vertex;
        LightIntensity = max(dot(normalize(LightPos - EyeDir), Normal), 0.0);
        
        shadowCoord = gl_TextureMatrix[7] * gl_ModelViewMatrix * gl_Vertex;
        normal = normalize(gl_NormalMatrix * normals_buffer);
        sunNormal = normalize(gl_LightSource[0].spotDirection);
        
        float specWeight = pow(max(dot(normal, gl_LightSource[0].halfVector.xyz), 0.0), gl_LightSource[0].specular.w);
        
        specular = vec4(gl_LightSource[0].specular.xyz, 0.0) * specWeight;
        specular.w = specWeight;
        
        fragPos = gl_ModelViewMatrix * gl_Vertex;
        gl_Position = ftransform();
        
        vec4 modelPos = vec4(gl_ModelViewMatrix[0][3], gl_ModelViewMatrix[1][3], gl_ModelViewMatrix[2][3], 0);
        vec4 vertex = gl_Vertex + modelPos;
        
        float scaled = 1.0;
        gl_TexCoord[0].x = 2.5*scaled * vertex.x + time * 0.2;
        gl_TexCoord[0].y = 2.5*scaled * vertex.y + time * 0.23;
        
        gl_TexCoord[1].x = -3.4*scaled * vertex.y + time * 0.3;
        gl_TexCoord[1].y = 3.4*scaled * vertex.x + time * 0.35;
        
        gl_TexCoord[2].x = (gl_Position.x / gl_Position.w * 0.5 + 0.5);
        gl_TexCoord[2].y = (gl_Position.y / gl_Position.w * 0.5 + 0.5);
    }
}
