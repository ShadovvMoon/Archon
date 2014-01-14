//
//  Geometry.m
//  swordedit
//
//  Created by Fred Havemeyer on 5/11/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Geometry.h"

#import "HaloMap.h"

#import "ModelTag.h"
#import "BitmapTag.h"

#import "TextureManager.h"

#ifndef MACVERSION
#import "glew.h"
#endif

#import "defines.h"
#import "glut_teapot.h"

#import  <OpenGL/OpenGL.h>
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#include <OpenGL/glext.h>

@implementation Geometry
- (id)initWithMap:(HaloMap *)map parent:(ModelTag *)mTag
{
	int i, x, endOfPart;
	
	if ((self = [super init]) != nil)
	{
		_mapfile = [map retain];
		parent = [mTag retain];
		
		vertexSize = [_mapfile indexHead].vertex_size;
		vertexOffset = [_mapfile indexHead].vertex_offset;
		
        #ifdef __DEBUG__
        CSLog(@"Reading geometry start 0x%lx", [_mapfile currentOffset]);
#endif
        
		[_mapfile readBlockOfData:&me.junk size_of_buffer:36];
		
        #ifdef __DEBUG__
        CSLog(@"Reading parts offset 0x%lx", [_mapfile currentOffset]);
#endif
        
		partsref = [_mapfile readReflexive];
		base_indicies = malloc(sizeof(int)*partsref.chunkcount);
		detail_indicies = malloc(sizeof(int)*partsref.chunkcount);
        
		textures = malloc(partsref.chunkcount * sizeof(GLuint));
		
		[_mapfile seekToAddress:partsref.offset];
        
        #ifdef __DEBUG__
		CSLog(@"Seeking to 0x%x", partsref.offset);
#endif
        
		parts = (part *)malloc(sizeof(part) * partsref.chunkcount);
        
        #ifdef __DEBUG__
        CSLog(@"Parts count %ld", partsref.chunkcount);
        
#endif
        
		for (x = 0; x < partsref.chunkcount; x++)
		{
			part *currentPart = &parts[x];
			[_mapfile readBlockOfData:currentPart->junk4 size_of_buffer:4]; //FLAGS
			[_mapfile readShort:&currentPart->shaderIndex]; //SHADER INDEX
			
            //CSLog(@"%d", currentPart->shaderIndex);
            
			[_mapfile readBlockOfData:&currentPart->junk size_of_buffer:66];// <-- This little baby was causing a buffer overrun on PPC macs, so I'm just skipping it
			//[_mapfile skipBytes:66];
			
            [_mapfile readint32_t:&currentPart->indexPointer.count];
			[_mapfile readint32_t:&currentPart->indexPointer.rawPointer[0]];
			[_mapfile readint32_t:&currentPart->indexPointer.rawPointer[1]];
			
            #ifdef __DEBUG__
            CSLog(@"Reading index pointer at offset 0x%lx 0x%x 0x%x", [_mapfile currentOffset], vertexOffset, vertexSize);
			CSLog(@"0x%lx", (currentPart->indexPointer.rawPointer[0] + vertexOffset + vertexSize));
#endif
            
			//#ifdef __DEBUG__
			if (currentPart->indexPointer.rawPointer[1] != currentPart->indexPointer.rawPointer[0])
            {
				CSLog(@"BadPartInt!"); // Whatever the hell that is
                return nil;
            }
			//#endif
				
			[_mapfile readBlockOfData:currentPart->junk2 size_of_buffer:4];
			
           
			[_mapfile readint32_t:&currentPart->vertPointer.count];
			[_mapfile readBlockOfData:currentPart->vertPointer.junk size_of_buffer:8];
			[_mapfile readint32_t:&currentPart->vertPointer.rawPointer];
			
            [_mapfile readint32_t:&currentPart->compressedVertPointer.count];
			[_mapfile readBlockOfData:currentPart->compressedVertPointer.junk size_of_buffer:8];
			[_mapfile readint32_t:&currentPart->compressedVertPointer.rawPointer];
            
			[_mapfile readBlockOfData:currentPart->junk3 size_of_buffer:12];
			
			endOfPart = [_mapfile currentOffset];
            
            #ifdef __DEBUG__
			CSLog(@"Vert count: %ld 0x%lx", currentPart->vertPointer.count, currentPart->vertPointer.rawPointer);
            CSLog(@"Index count: %ld 0x%lx", currentPart->indexPointer.count, currentPart->indexPointer.rawPointer[0]);
#endif
            
			[_mapfile seekToAddress:currentPart->vertPointer.rawPointer+vertexOffset];
			currentPart->vertices = (Vector *)malloc(sizeof(Vector) * currentPart->vertPointer.count);
			for (i = 0; i < currentPart->vertPointer.count; i++)
			{
				Vector *currentVertex = &currentPart->vertices[i];
				[_mapfile readFloat:&currentVertex->x];
				[_mapfile readFloat:&currentVertex->y];
				[_mapfile readFloat:&currentVertex->z];
				
				[_mapfile readFloat:&currentVertex->normalx];
				[_mapfile readFloat:&currentVertex->normaly];
				[_mapfile readFloat:&currentVertex->normalz];
				[_mapfile skipBytes:24];
				[_mapfile readFloat:&currentVertex->u];
				[_mapfile readFloat:&currentVertex->v];
				[_mapfile skipBytes:12];
			}
			
			[_mapfile seekToAddress:(currentPart->indexPointer.rawPointer[0] + vertexOffset + vertexSize)];
			currentPart->indices = (unsigned short *)malloc(sizeof(unsigned short) * (currentPart->indexPointer.count + 2));
				// No clue why its +2, lol
			for (i = 0; i < currentPart->indexPointer.count + 2; i++)
				[_mapfile readShort:&currentPart->indices[i]];
			
			[_mapfile seekToAddress:endOfPart];
		}
	}
    
    
    
	return self;
}
- (void)dealloc
{	
	//CSLog(@"Destroying geometry!");
	int x;
	
	for (x = 0; x < partsref.chunkcount; x++)
		free(parts[x].vertices);
	for (x = 0; x < partsref.chunkcount; x++)
		free(parts[x].indices);

	free(parts);
    
    //if (vertex_array)
    //
    free(vertex_array);
	
	if (textures)
		free(textures); // Not so sure about this call, I'm not sure if glDeleteTextures frees this or not
		
	[super dealloc];
}
- (void)destroy
{
	[parent release];
	[_mapfile release];
}
- (void)loadBitmaps
{
    //CSLog(@"Loading bitmaps");
	int x;
	
    
	if (texturesLoaded)
	{
		return;
	}
	
	for (x = 0; x < partsref.chunkcount; x++)
	{
		parts[x].hasShader = 2;
        
		int graphics_insane = 1;
		if (graphics_insane)
		{
            
            //[parent shaderIdentForIndex:parts[x].shaderIndex]
            //[parent shaderIdentForIndex:parts[x].shaderIndex]
			
            //CSLog(@"%d", parts[x].shaderIndex);
            
            if (parts[x].shaderIndex == -1)
            {
                CSLog(@"The shader is missing for this part");
                return;
            }
            
            parts[x].textureIndex = -1;
            NSString *type = [parent shaderTypeForIndex:parts[x].shaderIndex];
           // 
            //CSLog(type);
            parts[x].isGlass = 0;
            if ([type isEqualToString:@"osos"])
            {
                soso *shader = (soso *)malloc(sizeof(soso));
                
                #ifdef __DEBUG__
                if ([[_mapfile tagArray] count] > 2413)
                CSLog([[[_mapfile tagArray] objectAtIndex:2413] tagName]);
                CSLog(@"Shader ID 0x%lx %ld", [parent shaderIdentForIndex:parts[x].shaderIndex], parts[x].shaderIndex);
#endif
                
                [_mapfile loadSOSO:shader forID:[parent shaderIdentForIndex:parts[x].shaderIndex]];
                
                parts[x].baseMapIndex = shader->baseMap.TagId;
                parts[x].detailMapIndex = shader->detailMap.TagId;
                parts[x].detailMapScale = shader->detailScale;
                parts[x].shaderBitmapIndex = shader->baseMap.TagId;
                MapTag *baseTag = [_mapfile tagForId:shader->baseMap.TagId];
                
                #ifdef __DEBUG__
                CSLog(@"Loading shader base ID 0x%lx", shader->baseMap.TagId);
                
                CSLog(@"PRT; %.4s %@", [parent tagClassHigh], [parent tagName]);
                CSLog(@"SHR; %.4s %@", [baseTag tagClassHigh], [baseTag tagName]);
#endif
                
                [[parent _texManager] loadTextureOfIdent:parts[x].baseMapIndex subImage:0];
                [[parent _texManager] loadTextureOfIdent:parts[x].detailMapIndex subImage:0];
            }
            else if ([type isEqualToString:@"ihcs"])
            {
                //CSLog(@"Loading ichs");
                
                schi *shader = (schi *)malloc(sizeof(schi));
                [_mapfile loadSCHI:shader forID:[parent shaderIdentForIndex:parts[x].shaderIndex]];
                
                parts[x].shader = shader;
                parts[x].hasShader = 3;
                parts[x].baseMapIndex = -1;

                int g;
                for (g=0; g < parts[x].shader->maps.chunkcount; g++)
                {
                    [[parent _texManager] loadTextureOfIdent:parts[x].shader->read_maps[g].bitm.TagId subImage:0];
                }
                
                parts[x].lengthOfBitmapArray = -1;
                
                //CSLog(@"ICHS loaded");
            }
            else if ([type isEqualToString:@"algs"])
            {
                //CSLog(@"LOADING GLASS");
                //CSLog([parent tagName]);
                
                /*parts[x].shaderBitmapIndex = [[[_mapfile bitmsTagForShaderId:[parent shaderIdentForIndex:parts[x].shaderIndex]] objectAtIndex:1] idOfTag];
                parts[x].baseMapIndex = parts[x].shaderBitmapIndex;
                parts[x].detailMapIndex = -1;
                parts[x].textureIndex = -1;*/
                
                long ident = [parent shaderIdentForIndex:parts[x].shaderIndex];
                MapTag *tag = [_mapfile tagForId:ident];

                if (tag)
                {
                    [_mapfile seekToAddress:[tag offsetInMap] + 0x28];
                    [_mapfile readShort:&parts[x].glass_flags];
                }
                //glass_flags
                
                
                parts[x].hasShader = 5;
                
                //parts[x].lengthOfBitmapArray = -1;
                //[[parent _texManager] loadTextureOfIdent:parts[x].shaderBitmapIndex subImage:0];
            }
            else if ([type isEqualToString:@"xecs"])
            {
               // CSLog(@"Loading xecs");
                
                scex *shader = (scex *)malloc(sizeof(scex));
                [_mapfile loadSCEX:shader forID:[parent shaderIdentForIndex:parts[x].shaderIndex]];
                
                parts[x].scexshader = shader;
                parts[x].hasShader = 4;
                parts[x].baseMapIndex = -1;
                //CSLog(@"Loading parts %d", (parts[x].scexshader->maps.chunkcount + ((scex*)parts[x].scexshader)->maps2.chunkcount));
                
                
                
                //Replace the first texture with a precalculated sky texture.
                //_glTextureTable_Compiled
                
                //Load up all of the map textures.
                int g;
                for (g=0; g < (parts[x].scexshader->maps.chunkcount + ((scex*)parts[x].scexshader)->maps2.chunkcount); g++)
                {
                    //CSLog(@"%d %ld", g, parts[x].scexshader->read_maps[g].bitm.TagId);
                    
                    [[parent _texManager] loadTextureOfIdent:parts[x].scexshader->read_maps[g].bitm.TagId subImage:0 removeAlpha:NO];
                }
                
                /*
                //Make a 512 image (size of the first bitmap)
                BitmapTag *bitmap = [[parent _texManager] bitmapForIdent:parts[x].scexshader->read_maps[0].bitm.TagId];
                NSSize size = [bitmap textureSizeForImageIndex:0];
                float uscale = parts[x].scexshader->read_maps[0].uscale;
                float vscale = parts[x].scexshader->read_maps[0].vscale;
                
                size = NSMakeSize(size.width*uscale, size.height*vscale);
                unsigned char *imageData = malloc(size.width * size.height * 4);
                
                for (g=(parts[x].scexshader->maps.chunkcount + ((scex*)parts[x].scexshader)->maps2.chunkcount)-1; g >=0 ; g--)
                {
                    BitmapTag *bitmap = [[parent _texManager] bitmapForIdent:parts[x].scexshader->read_maps[g].bitm.TagId];
                    
                    if (!bitmap)
                        continue;
                    
                    NSSize bitmapSize = [bitmap textureSizeForImageIndex:0];
                    unsigned char *bitmapData = [bitmap imagePixelsForImageIndex:0];

                    short alphaFunction = parts[x].scexshader->read_maps[g].alphaFunction;
                    short colorFunction = parts[x].scexshader->read_maps[g].colorFunction;
                    
                    float uscale = parts[x].scexshader->read_maps[g].uscale;
                    float vscale = parts[x].scexshader->read_maps[g].vscale;
                    
                    CSLog(@"CREATING TILED IMAGE FILE %f %f", bitmapSize.width, bitmapSize.height);
                    
                    //Tile the image over the existing image data
                    int i;
                    for (i = 0; i < size.width * size.height * 4; i += 4)
                    {
                        //Where are we actually at in the main image
                        int x = (i/4) % (int)size.width;
                        int y = floor((i/4) / size.width);
                        
                        //Where is this pixel on the mapped repeated texture
                        int modx = x % (int)(bitmapSize.width / uscale);
                        int mody = y % (int)(bitmapSize.height / vscale);
                        
                        //Where is this pixel in terms of j
                        int j;
                        j = mody * ((int)size.width * 4) + modx * 4;
                        
                        unsigned char a;
                        
                        if (colorFunction == 0) //Currect
                        {
                            *(imageData + i+0) = *(bitmapData + j+0); //R
                            *(imageData + i+1) = *(bitmapData + j+1); //G
                            *(imageData + i+2) = *(bitmapData + j+2); //B
                        }
                        else if (colorFunction == 4) //Add
                        {
                            *(imageData + i+0) = *(imageData + i+0)+*(bitmapData + j+0); //R
                            *(imageData + i+1) = *(imageData + i+1)+*(bitmapData + j+1); //G
                            *(imageData + i+2) = *(imageData + i+2)+*(bitmapData + j+2); //B
                        }
                        else if (colorFunction == 4) //Multiply
                        {
                            *(imageData + i+0) = *(imageData + i+0)*((*(bitmapData + j+0))/255.0); //Alpha
                            *(imageData + i+1) = *(imageData + i+1)*((*(bitmapData + j+1))/255.0); //Alpha
                            *(imageData + i+2) = *(imageData + i+2)*((*(bitmapData + j+2))/255.0); //Alpha
                        }
                        
                        
                        if (alphaFunction == 0) //Currect
                            *(imageData + i+3) = *(bitmapData + j+3); //Alpha
                        else if (alphaFunction == 4) //Add
                            *(imageData + i+3) = *(imageData + i+3) + *(bitmapData + j+3); //Alpha
                        else if (alphaFunction == 4) //Multiply
                            *(imageData + i+3) = *(imageData + i+3)*((*(bitmapData + j+3))/255.0); //Alpha
                    }
                }
                
                //Export imagesata as a bitmap
                /*
                NSBitmapImageRep *imgRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&imageData
                                                                                   pixelsWide:size.width
                                                                                   pixelsHigh:size.height
                                                                                bitsPerSample:8
                                                                              samplesPerPixel:4
                                                                                     hasAlpha:true
                                                                                     isPlanar:false
                                                                               colorSpaceName:NSDeviceRGBColorSpace
                                            
                                                                                  bytesPerRow:0
                                                                                 bitsPerPixel:0];
                
                int k;
                for (k=0; k < 1000; k++)
                {
                    NSString *filename = [NSString stringWithFormat:@"someImage%d.tiff", k];
                    NSString *write = [@"/Users/colbrans/Desktop/Generated" stringByAppendingPathComponent:filename];
                    if (![[NSFileManager defaultManager] fileExistsAtPath:write])
                    {
                        [[imgRep TIFFRepresentation] writeToFile:write atomically:YES];
                        break;
                    }
                }
                
                
                //Create the texture
                //_glTextureTable_Compiled
                int index = [[parent _texManager] createTextureWithData:imageData withSize:size];
                
                parts[x].textureIndex = index;
                parts[x].lengthOfBitmapArray = -1;
                */
                //CSLog(@"SCEX loaded");
            }
            else if ([type isEqualToString:@"vnes"])
            {
                senv *shader = (senv *)malloc(sizeof(senv));
                [_mapfile loadShader:shader forID:[parent shaderIdentForIndex:parts[x].shaderIndex]];
                
                //BASE MAP
				parts[x].baseMapIndex = shader->baseMapBitm.TagId;
                parts[x].detailMapIndex = shader->primaryMapBitm.TagId;
                parts[x].detailMapScale = shader->primaryMapScale;
                parts[x].shaderBitmapIndex = shader->baseMapBitm.TagId;
                
                [[parent _texManager] loadTextureOfIdent:parts[x].baseMapIndex subImage:0 ];
                [[parent _texManager] loadTextureOfIdent:parts[x].detailMapIndex subImage:0];
            }
            else
            {
                
                parts[x].baseMapIndex = -1;
                parts[x].shaderBitmapIndex = [[_mapfile bitmTagForShaderId:[parent shaderIdentForIndex:parts[x].shaderIndex]] idOfTag];
                //CSLog(@"Load bitmaps %ld",parts[x].shaderBitmapIndex);
                
                parts[x].lengthOfBitmapArray = -1;
                [[parent _texManager] loadTextureOfIdent:parts[x].shaderBitmapIndex subImage:0];
                
            }
		}
		else
		{
		
            parts[x].baseMapIndex = -1;
			parts[x].shaderBitmapIndex = [[_mapfile bitmTagForShaderId:[parent shaderIdentForIndex:parts[x].shaderIndex]] idOfTag];
            //CSLog(@"Load bitmaps %ld",parts[x].shaderBitmapIndex);
            
            parts[x].lengthOfBitmapArray = -1;
			[[parent _texManager] loadTextureOfIdent:parts[x].shaderBitmapIndex subImage:0];
			
		}
	}
	texturesLoaded = TRUE;
    
    //Check for error

    
    
}
- (BOUNDING_BOX)determineBoundingBox
{
	BOUNDING_BOX bb;
	bb.min[0] = 50000;
	bb.min[1] = 50000;
	bb.min[2] = 50000;
	bb.max[0] = -50000;
	bb.max[1] = -50000;
	bb.max[2] = -50000;
	int x;
	for (x=0;x<partsref.chunkcount;x++)
	{
		part currentPart = parts[x];
		int y;
		for (y=0;y<currentPart.vertPointer.count;y++)
		{
			if (currentPart.vertices[y].x>bb.max[0])
				bb.max[0]=currentPart.vertices[y].x;
			if (currentPart.vertices[y].y>bb.max[1])
				bb.max[1]=currentPart.vertices[y].y;
			if (currentPart.vertices[y].z>bb.max[2])
				bb.max[2]=currentPart.vertices[y].z;
			if (currentPart.vertices[y].x<bb.min[0])
				bb.min[0]=currentPart.vertices[y].x;
			if (currentPart.vertices[y].y<bb.min[1])
				bb.min[1]=currentPart.vertices[y].y;
			if (currentPart.vertices[y].z<bb.min[2])
				bb.min[2]=currentPart.vertices[y].z;
		}
	}
	return bb;
}

-(void)setupDrawing
{
    
    
    int i, x;
	part currentPart;
    
 
    float u_scale, v_scale;
    
	u_scale = [parent u_scale];
	v_scale = [parent v_scale];
    
    int requiredSize = 0;
    int indexSize = 0;
    int cC= partsref.chunkcount;
    
    for (i = 0; i < cC; i++)
	{
        currentPart = parts[i];
        requiredSize+=currentPart.vertPointer.count;
        indexSize+=currentPart.indexPointer.count+2;
    }
    
    vertex_array = (GLfloat*)malloc(requiredSize * 3 * sizeof(GLfloat));
    index_array = (GLshort*)malloc(indexSize * sizeof(GLshort));
    texture_uv = (GLfloat*)malloc(requiredSize * 2 * sizeof(GLfloat));
    normals = (GLfloat*)malloc(requiredSize * 3 * sizeof(GLfloat));
    
    int a=0;
    int uvr=0;
    int normal=0;
    int ind=0;
    
    for (i = 0; i < cC; i++)
	{
        currentPart = parts[i];
        
        if (currentPart.indexPointer.rawPointer[0] == currentPart.indexPointer.rawPointer[1])
		{
            
            for (x = 0; x < currentPart.indexPointer.count+2; x++)
            {
                GLshort index = currentPart.indices[x];
                index+=(a/3);
                
                index_array[ind]=index;
                ind++;
            }
        
            if (0)//currentPart.hasShader == 3)
            {
                //Get the UV Scale
                
                
                int aa;
                for(aa=0; aa < currentPart.shader->maps.chunkcount; aa++)
                {
                    currentPart.shader->read_maps[aa].texture_uv = (GLfloat*)malloc(requiredSize * 2 * sizeof(GLfloat));
                    int avr=0;
                    
                    int f;
                    for (f = 0; f < cC; f++)
                    {
                        for (x=0; x < parts[f].vertPointer.count; x++)
                        {
                            Vector vertex = parts[f].vertices[x];
                            currentPart.shader->read_maps[aa].texture_uv[avr] = vertex.u*currentPart.shader->read_maps[aa].uscale;
                            currentPart.shader->read_maps[aa].texture_uv[avr+1] = vertex.u*currentPart.shader->read_maps[aa].vscale;
                            
                            avr+=2;
                        }
                    }
                    
                }
                
                
                
            }
            else
            {
                u_scale = [parent u_scale];
                v_scale = [parent v_scale];
                
                for (x=0; x < currentPart.vertPointer.count; x++)
                {
                    Vector vertex = currentPart.vertices[x];
                    vertex_array[a] = (GLfloat)vertex.x;
                    vertex_array[a+1] = (GLfloat)vertex.y;
                    vertex_array[a+2] = (GLfloat)vertex.z;
                    
                    normals[a]=vertex.normalx;
                    normals[a+1]=vertex.normaly;
                    normals[a+2]=vertex.normalz;
                    
                    
                    
                    
                    
                    
                    texture_uv[uvr] = vertex.u*u_scale;
                    texture_uv[uvr+1] = vertex.v*v_scale;
                    
                    uvr+=2;
                    a+=3;
                }
                
                
            }
            
           
            
            
        }
    }
    indexCount_R = ind;
    
#ifdef VERTEX_BUFFERS
    

    
    //free(vertex_array);
    //free(index_array);
#endif
    
    
#ifdef DISPLAY_LISTS
    geometryList = glGenLists(1);
    glNewList(geometryList, GL_COMPILE);
    [self drawIntoView:YES displayList:YES];
    glEndList();
#endif
    
    //CSLog(@"Complete");
    
    
    /* house texture */
       /*
    glGenTextures(1, &house_texture);
    NSString *string = [[NSBundle mainBundle] pathForResource: @"House" ofType: @"jpg"];
    
    NSBitmapImageRep *bitmapimagerep = LoadImage(string, 1);
    NSRect rect = NSMakeRect(0, 0, [bitmapimagerep pixelsWide], [bitmapimagerep pixelsHigh]);
    
    glBindTexture(GL_TEXTURE_2D, house_texture);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, rect.size.width, rect.size.height, 0,
                 (([bitmapimagerep hasAlpha])?(GL_RGBA):(GL_RGB)), GL_UNSIGNED_BYTE,
                 [bitmapimagerep bitmapData]);

    
 

    */
    /*
    glGenTextures(1, &frameBuffer_texture);
    glBindTexture(GL_TEXTURE_2D, frameBuffer_texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    GLint viewport[4];
    glGetIntegerv(GL_VIEWPORT,viewport);
    CopyFramebufferToTexture(frameBuffer_texture);
    */
    
    #define INDEX_BUFFER 0
    #define POS_VB 1
    #define NORMAL_VB 2
    #define TEXCOORD_VB 3
    
    glFinish();
    
    GLuint texCoord_buffer;
    texCoord_buffer = glGetAttribLocation(currentNormalProgram(), "texCoord_buffer");
    GLuint texCoord_buffer2;
    texCoord_buffer2 = glGetAttribLocation(currentLightProgram(), "texCoord_buffer");
    GLuint normals_buffer;
    normals_buffer = glGetAttribLocation(currentSglaProgram(), "VertexNormal");

    //NSLog(@"%d %d %d", texCoord_buffer, texCoord_buffer2, normals_buffer);
    
    glGenVertexArraysAPPLE(1, &geometryVAO);
    glBindVertexArrayAPPLE(geometryVAO);
    
    // Create the buffers for the vertices atttributes
    glGenBuffers(4, m_Buffers);
    
    //Shift these to vertex buffers
    glBindBuffer(GL_ARRAY_BUFFER, m_Buffers[POS_VB]);
    glBufferData(GL_ARRAY_BUFFER, requiredSize * 3 * sizeof(GLfloat), NULL, GL_STATIC_DRAW);
    GLvoid* my_vertex_pointer = glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);
    memcpy(my_vertex_pointer, vertex_array, requiredSize * 3 * sizeof(GLfloat));
    glUnmapBuffer(GL_ARRAY_BUFFER);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
    
    glBindBuffer(GL_ARRAY_BUFFER, m_Buffers[TEXCOORD_VB]);
    glBufferData(GL_ARRAY_BUFFER, requiredSize * 2 * sizeof(GLfloat), &texture_uv[0], GL_STATIC_DRAW);
    glEnableVertexAttribArray(texCoord_buffer);
    glVertexAttribPointer(texCoord_buffer, 2, GL_FLOAT, GL_FALSE, 0, 0);
    
    glEnableVertexAttribArray(texCoord_buffer2);
    glVertexAttribPointer(texCoord_buffer2, 2, GL_FLOAT, GL_FALSE, 0, 0);
    
    glBindBuffer(GL_ARRAY_BUFFER, m_Buffers[NORMAL_VB]);
    glBufferData(GL_ARRAY_BUFFER, requiredSize * 3 * sizeof(GLfloat), &normals[0], GL_STATIC_DRAW);
    glEnableVertexAttribArray(normals_buffer);
    glVertexAttribPointer(normals_buffer, 3, GL_FLOAT, GL_FALSE, 0, 0);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_Buffers[INDEX_BUFFER]);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indexSize * sizeof(GLshort), &index_array[0], GL_STATIC_DRAW);
    
    
    glBindVertexArrayAPPLE(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    
    //free(index_array);
    //free(texture_uv);
    //free(vertex_array);
    //free(normals);
    
    //Create base index cache
    //Draw parts
    NSMutableDictionary *texture_lookup = [[parent _texManager] _textureLookupByID];
    int detailIndex, baseIndex;
    for (i = 0; i < partsref.chunkcount; i++)
    {
        currentPart = parts[i];
        baseIndex  = [[texture_lookup objectForKey:[NSNumber numberWithLong:currentPart.baseMapIndex]] intValue];
        base_indicies[i]=baseIndex;
        
        detailIndex = [[texture_lookup objectForKey:[NSNumber numberWithLong:currentPart.detailMapIndex]] intValue];
        detail_indicies[i] = detailIndex;
    }
    
    drawingSetup = YES;
}




- (void)drawIntoView:(BOOL)useAlphas
{
#ifdef DISPLAY_LISTS
    //[self drawIntoView:useAlphas displayList:NO];
    glCallList(geometryList);
#else
    [self drawIntoView:useAlphas displayList:NO];
#endif
}




- (void)drawIntoView:(BOOL)useAlphas displayList:(BOOL)list
{
    if (!drawingSetup)
    {
        [self setupDrawing];
        return;
    }
    
    glBlendFunc(GL_DST_ALPHA,GL_ONE_MINUS_DST_ALPHA);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    

    USEDEBUG CSLog(@"DIV 1");
    useAlphas = YES;
    
	int i, x;
	part currentPart;
    if (partsref.chunkcount <= 0)
    {
        return;
    }
    
    //--------------------------------
    //The copyright for the following code is owned by Samuel Colbran (Samuco).
    //The copyright for other smaller segments that are not identified by these comments are also owned by Samuel Colbran (Samuco).
    //--------------------------------

    if (!legacyMode)
    {
    glBindVertexArrayAPPLE(geometryVAO);
    NSMutableDictionary *texture_lookup = [[parent _texManager] _textureLookupByID];

    glEnable(GL_BLEND);
    
    //Draw parts
    int currentIndex = 0;
    int currentVertices = 0;
    int detailIndex, baseIndex;
    for (i = 0; i < partsref.chunkcount; i++)
    {
        //glDisable(GL_ALPHA_TEST);
        currentPart = parts[i];
        
        int index_count = currentPart.indexPointer.count + 2;
        int vertex_count = currentPart.vertPointer.count;
        
        if (currentPart.hasShader == 3) //schi
        {
            if (useAlphaTesting) glDisable(GL_ALPHA_TEST);
            activateSchiProgram();
            glUniform1f(global_time_schi, cggurrentTime());
            glUniform1f(global_t0_available_schi, 0.0);
            glUniform1f(global_t1_available_schi, 0.0);
            glUniform1i(global_t0_schi, 0);
            glUniform1i(global_t1_schi, 1);
            
            //Bind all of the textures
            int g;
            for (g=0; g<currentPart.shader->maps.chunkcount; g++)
            {
                int texIndex = [[[[parent _texManager] _textureLookupByID] objectForKey:[NSNumber numberWithLong:currentPart.shader->read_maps[g].bitm.TagId]] intValue];
                
                float u = currentPart.shader->read_maps[g].uscale;
                float v = currentPart.shader->read_maps[g].vscale;
                
                float c = 0.0;
                if (currentPart.shader->read_maps[g].colorFunction == 2)
                    c = 1.0;
                
                float a = 0.0;
                if (currentPart.shader->read_maps[g].alphaFunction == 2)
                    a = 1.0;
                
                float uf = 0.0;
                if (currentPart.shader->read_maps[g].uFunction != 0)
                    uf = 1.0;
                
                float vf = 0.0;
                if (currentPart.shader->read_maps[g].vFunction != 0)
                    vf = 1.0;
                
                if (g == 0)
                {
                    glActiveTexture(GL_TEXTURE0);
                    glUniform2f(global_t0_scale_schi, u,v);
                    glUniform4f(global_t0_option_schi, c,a,uf,vf);
                    glUniform1f(global_t0_available_schi, 1.0);
                }
                else if (g == 1)
                {
                    glActiveTexture(GL_TEXTURE1);
                    glUniform2f(global_t1_scale_schi, u,v);
                    glUniform4f(global_t1_option_schi, c,a,uf,vf);
                    glUniform1f(global_t1_available_schi, 1.0);
                }
                else
                    break;
                
                glBindTexture(GL_TEXTURE_2D, [parent _texManager]._glTextureTable[texIndex][0]);
            }
            
            if (index_count <= indexCount_R)
            {
                glDrawElementsBaseVertex(GL_TRIANGLE_STRIP,
                                         index_count,
                                         GL_UNSIGNED_SHORT,
                                         (void*)(currentIndex*sizeof(GLshort)),
                                         0);
            }
            activateNormalProgram();
            if (useAlphaTesting) glEnable(GL_ALPHA_TEST);
        }
        else if (currentPart.hasShader == 4) //scex
        {
            if (useAlphaTesting) glDisable(GL_ALPHA_TEST);
            activateScexProgram();
            glUniform1f(global_time, cggurrentTime());
            glUniform1f(global_t0_available, 0.0);
            glUniform1f(global_t1_available, 0.0);
            glUniform1f(global_t2_available, 0.0);
            glUniform1f(global_t3_available, 0.0);
            glUniform1i(global_t0, 0);
            glUniform1i(global_t1, 1);
            glUniform1i(global_t2, 2);
            glUniform1i(global_t3, 3);
        
            //Bind all of the textures
            int g;
            for (g=0; g<currentPart.scexshader->maps.chunkcount; g++)
            {
                int texIndex = [[[[parent _texManager] _textureLookupByID] objectForKey:[NSNumber numberWithLong:currentPart.scexshader->read_maps[g].bitm.TagId]] intValue];
                
                float u = currentPart.scexshader->read_maps[g].uscale;
                float v = currentPart.scexshader->read_maps[g].vscale;
                
                float c = 0.0;
                if (currentPart.scexshader->read_maps[g].colorFunction == 2)
                    c = 1.0;
                
                float a = 0.0;
                if (currentPart.scexshader->read_maps[g].alphaFunction == 2)
                    a = 1.0;
                
                float uf = 0.0;
                if (currentPart.scexshader->read_maps[g].uFunction != 0)
                    uf = 1.0;
                
                float vf = 0.0;
                if (currentPart.scexshader->read_maps[g].vFunction != 0)
                    vf = 1.0;
                
                if (g == 0)
                {
                    glActiveTexture(GL_TEXTURE0);
                    glUniform2f(global_t0_scale, u,v);
                    glUniform4f(global_t0_option, c,a,uf,vf);
                    glUniform1f(global_t0_available, 1.0);
                }
                else if (g == 1)
                {
                    glActiveTexture(GL_TEXTURE1);
                    glUniform2f(global_t1_scale, u,v);
                    glUniform4f(global_t1_option, c,a,uf,vf);
                    glUniform1f(global_t1_available, 1.0);
                }
                else if (g == 2)
                {
                    glActiveTexture(GL_TEXTURE2);
                    glUniform2f(global_t2_scale, u,v);
                    glUniform4f(global_t2_option, c,a,uf,vf);
                    glUniform1f(global_t2_available, 1.0);
                }
                else if (g == 3)
                {
                    glActiveTexture(GL_TEXTURE3);
                    glUniform2f(global_t3_scale, u,v);
                    glUniform4f(global_t3_option, c,a,uf,vf);
                    glUniform1f(global_t3_available, 1.0);
                }
                else
                    break;
                
                glBindTexture(GL_TEXTURE_2D, [parent _texManager]._glTextureTable[texIndex][0]);
            }
            
            if (index_count <= indexCount_R)
            {
                glDrawElementsBaseVertex(GL_TRIANGLE_STRIP,
                                         index_count,
                                         GL_UNSIGNED_SHORT,
                                         (void*)(currentIndex*sizeof(GLshort)),
                                         0);
            }
            activateNormalProgram();
            
            if (useAlphaTesting) glEnable(GL_ALPHA_TEST);
        }
        else if (currentPart.hasShader == 5) //sgla
        {
            activateSglaProgram();
            
            GLint viewport[4];
            glGetIntegerv(GL_VIEWPORT,viewport);
            glUniform1f(global_FrameWidth, viewport[2]);
            glUniform1f(global_FrameHeight, viewport[3]);
            glUniform1f(global_textureWidth, NextHighestPowerOf2(viewport[2]));
            glUniform1f(global_textureHeight, NextHighestPowerOf2(viewport[3]));
            
            glUniform3f(global_LightPos, 0.0, 0.0, 4.0);
            glUniform3f(global_BaseColor, 0.4, 0.4, 1.0);
            glUniform1f(global_Depth, 0.1);
            glUniform1f(global_MixRatio, 1.0);
            glUniform1i(global_EnvMap, 0);
            glUniform1i(global_RefractionMap, 1);
            
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            
            //CopyFramebufferToTexture(frameBuffer_texture);
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, house_texture);
            
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(GL_TEXTURE_2D, frameBuffer_texture);
            //CopyFramebufferToTexture(frameBuffer_texture);
            
            if (index_count <= indexCount_R)
            {
                glDrawElementsBaseVertex(GL_TRIANGLE_STRIP,
                                         index_count,
                                         GL_UNSIGNED_SHORT,
                                         (void*)(currentIndex*sizeof(GLshort)),
                                         0);
            }
            activateNormalProgram();
        }
        else
        {
            baseIndex  = base_indicies[i];
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, [parent _texManager]._glTextureTable[baseIndex][0]);

            if (currentPart.detailMapIndex == -1)
            {
                if (global_detailedStatus)
                {
                    global_detailedStatus=NO;
                    glUniform1f(global_isDetailed, 0.0);
                }
            }
            else
            {
                detailIndex = detail_indicies[i];
                if (!global_detailedStatus)
                {
                    global_detailedStatus=YES;
                    glUniform1f(global_isDetailed, 1.0);
                }
                
                glUniform1f(global_detailScale, currentPart.detailMapScale);
                
                glActiveTexture(GL_TEXTURE1);
                glBindTexture(GL_TEXTURE_2D, [parent _texManager]._glTextureTable[detailIndex][0]);
            }
            
            
            
            
            if (index_count <= indexCount_R)
            {
                glDrawElementsBaseVertex(GL_TRIANGLE_STRIP,
                                         index_count,
                                         GL_UNSIGNED_SHORT,
                                         (void*)(currentIndex*sizeof(GLshort)),
                                         0);
            }
            

        }
        
        currentVertices += vertex_count;
        currentIndex+=index_count;
    }
    
    //Disable states
    glBindVertexArrayAPPLE(0);
    //glDisableClientState(GL_VERTEX_ARRAY);
    //glDisableClientState(GL_NORMAL_ARRAY);
    //glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    return;
    }
    else
    {
    
    glEnable(GL_TEXTURE_2D);
    
    
    
    
    
    
    
    
    
    
    
    
    USEDEBUG CSLog(@"DIV 3");
    if (TRUE)//useNewRenderer())
    {
        
        glDepthFunc(GL_LEQUAL);
        
        glGetError();
        
#ifdef VERTEX_BUFFERS
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        glDisableClientState(GL_NORMAL_ARRAY);
        glDisableClientState(GL_COLOR_ARRAY);
        glDisableClientState(GL_INDEX_ARRAY);
        glDisableClientState(GL_EDGE_FLAG_ARRAY);
        glDisableClientState(GL_FOG_COORD_ARRAY);
        glDisableClientState(GL_SECONDARY_COLOR_ARRAY);
        
        glBindBuffer( GL_ARRAY_BUFFER        , textureVBO );
        glTexCoordPointer(2, GL_FLOAT, 0, 0 );
        
        glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, indexVBO );
        
        glBindBuffer( GL_ARRAY_BUFFER        , vertexVBO );
        glVertexPointer(3, GL_FLOAT, 0, 0 );
        
#else
        glVertexPointer(3, GL_FLOAT, 0, vertex_array);
#endif
        
        glNormalPointer(GL_FLOAT, 0, normals);
        
        

        USEDEBUG CSLog(@"DIV 4");
        int currentIndex = 0;
        for (i = 0; i < partsref.chunkcount; i++)
        {
            GLint texLoc = glGetUniformLocation(currentLightProgram(), "isDetailed");
            glUniform1i(texLoc, 0);

            
    
            
            currentPart = parts[i];
            if (currentPart.hasShader != 5)
            {
                //currentIndex+=currentPart.indexPointer.count+2;
                //continue;
            }
            
#ifdef VERTEX_BUFFERS
            glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, (void*)0);
#else
            
            
            if (currentPart.indexPointer.rawPointer[0] == currentPart.indexPointer.rawPointer[1])
            {
                if (useAlphaTesting) glDisable(GL_ALPHA_TEST);
                
                USEDEBUG CSLog(@"DIV 5 %d", i);
                currentPart.lengthOfBitmapArray = -1;
                
                /*if (currentPart.hasShader == 5)
                {
                    GLuint program_object = currentLightProgram();
                    GLint texLoc = glGetUniformLocation(program_object, "sglaShader");
                    glUniform1i(texLoc, 1);
                    
                    glPushAttrib(GL_ENABLE_BIT | GL_COLOR_BUFFER_BIT);
                    glDisable(GL_TEXTURE_2D);
                    glDisable(GL_TEXTURE_3D);
                    
                    glEnable(GL_BLEND);
                    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                    
                    GLint viewport[4];
                    glGetIntegerv(GL_VIEWPORT,viewport);
                    glUniform1f(glGetUniformLocation(program_object, "FrameWidth"), viewport[2]);
                    glUniform1f(glGetUniformLocation(program_object, "FrameHeight"), viewport[3]);
                    glUniform1f(glGetUniformLocation(program_object, "textureWidth"), NextHighestPowerOf2(viewport[2]));
                    glUniform1f(glGetUniformLocation(program_object, "textureHeight"), NextHighestPowerOf2(viewport[3]));
                    
                    glUniform3f(glGetUniformLocation(program_object, "LightPos"), 0.0, 0.0, 4.0);
                    glUniform3f(glGetUniformLocation(program_object, "BaseColor"), 0.4, 0.4, 1.0);
                    glUniform1f(glGetUniformLocation(program_object, "Depth"), 0.1);
                    glUniform1f(glGetUniformLocation(program_object, "MixRatio"), 1);
                    glUniform1i(glGetUniformLocation(program_object, "EnvMap"), 0);
                    glUniform1i(glGetUniformLocation(program_object, "RefractionMap"), 1);
                    
                    CopyFramebufferToTexture(frameBuffer_texture);
                    
                    glActiveTexture(GL_TEXTURE0);
                    glBindTexture(GL_TEXTURE_2D, house_texture);
                    
                    glActiveTexture(GL_TEXTURE1);
                    glBindTexture(GL_TEXTURE_2D, frameBuffer_texture);
                    CopyFramebufferToTexture(frameBuffer_texture);
                    
                    glActiveTexture(GL_TEXTURE2);
                    glDisable(GL_TEXTURE_2D);
                    glActiveTexture(GL_TEXTURE3);
                    glDisable(GL_TEXTURE_2D);
                    
                    glActiveTexture(GL_TEXTURE0);
                    glColor4f(1.0, 1.0, 1.0, 0.8);
                    

                    
                   // glEnable(GL_AUTO_NORMAL);
                    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                    glEnableClientState(GL_NORMAL_ARRAY);
                    glTexCoordPointer(2, GL_FLOAT, 0, texture_uv);//&currentPart.shader->read_maps[g].texture_uv);
                    glNormalPointer(GL_FLOAT, 0, normals);//&currentPart.shader->read_maps[g].texture_uv);
                    if (currentIndex+currentPart.indexPointer.count+2 <= indexCount_R)
                    {
                        glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
                    }
                    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                    glDisableClientState(GL_NORMAL_ARRAY);
                    //teapot(8, 0.5, GL_FILL);
                    
                    glPopAttrib();
                    
                    glUniform1i(texLoc, 0);
                    glUseProgram(0);
                }*/
                if ((currentPart.hasShader==3 || currentPart.hasShader == 4) && useNewRenderer() >= 2)
                {
                   
                    
                    
                    
                    
                    
                    USEDEBUG CSLog(@"DIV 6 %d", i);
                    glEnable(GL_BLEND);
                    glBlendFunc(GL_DST_ALPHA,GL_ONE_MINUS_DST_ALPHA);
                    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
                    
                    USEDEBUG CSLog(@"DIV 7 %d", i);
                    //CSLog(@"1");
                    int maps;
                    if (currentPart.hasShader == 4)
                    {
                        if (useNewRenderer() == 4)
                        {
                            maps = currentPart.scexshader->maps2.chunkcount;
                        }
                        else
                            maps = currentPart.scexshader->maps2.chunkcount+currentPart.scexshader->maps.chunkcount;
                    }
                    else
                    {
                        maps = currentPart.shader->maps.chunkcount;
                    }

                    
                    USEDEBUG CSLog(@"DIV 8 %d", i);
                    //glColor4f(1.0, 1.0, 1.0, 1.0);
                    int g;
                    
                    glDepthFunc(GL_LEQUAL);
                    
                    USEDEBUG CSLog(@"DIV 9 %d", i);
                    
                    if ([parent _texManager]._textures)
                    {
                if (useNewRenderer()!=1)
                {
                    
#ifdef NEWSKY
                    
                    glAlphaFunc(GL_GREATER, 0.1);
                    //glEnable(GL_ALPHA_TEST);
                    
                    //glEnable(GL_DEPTH_TEST);
                    glDepthFunc(GL_LEQUAL);
                    
                    glDisableClientState(GL_VERTEX_ARRAY); // enable array data to shader
                    glEnableClientState(GL_VERTEX_ARRAY); // enable array data to shader
                    
                    if (currentPart.textureIndex != -1)
                    {
                        
                        //Check for error
                        GLenum error = glGetError();
                        if( error != GL_NO_ERROR )
                        {
                            printf( "Previous error s %s\n", gluErrorString( error ) );
                        }
                        
                        
                        glActiveTextureARB(GL_TEXTURE0_ARB);
                        glEnable(GL_TEXTURE_2D);
                        
                        glBindTexture(GL_TEXTURE_2D, [parent _texManager]._glTextureTable_Compiled[currentPart.textureIndex][0]);
                        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT);
                        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT);
                        glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
                        
                        glEnable(GL_BLEND);
                        glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
                        
                        glClientActiveTextureARB(GL_TEXTURE0_ARB);
                        
                        glColor4f(1.0, 1.0, 1.0, 0.5f);
                        glTexCoordPointer(2, GL_FLOAT, 0, texture_uv);//&currentPart.shader->read_maps[g].texture_uv);
                        glEnableClientState(GL_TEXTURE_COORD_ARRAY); // enable array data to shader
                        
                        //Check for error
                         error = glGetError();
                        if( error != GL_NO_ERROR )
                        {
                            printf( "Vertex error %s\n", gluErrorString( error ) );
                        }
                        if (currentIndex+currentPart.indexPointer.count+2 <= indexCount_R)
                        {
                            #ifdef VERTEX_BUFFERS
                                glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, 0);
                            #else
                                glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
                            #endif
                        }
                        
                        //Check for error
                         error = glGetError();
                        if( error != GL_NO_ERROR )
                        {
                            printf( "Post error %s\n", gluErrorString( error ) );
                        }
                        glClientActiveTextureARB(GL_TEXTURE0_ARB);
                        glDisable(GL_TEXTURE_2D);
                    }
                    else
                    {

                        BOOL useShaders = NO;
                        if (useShaders)
                        {
                            if (currentPart.hasShader == 5)
                            {
                                NSLog(@"Draw glass");
                            }
                            else if (currentPart.hasShader == 4)
                            {
                                //Scex shader
                                activateLightProgram();
                                GLint texLoc = glGetUniformLocation(currentLightProgram(), "scexShader");
                                glUniform1i(texLoc, 1);
                                
                                glUniform1i(glGetUniformLocation(currentLightProgram(), "t0"), 0);
                                glUniform1i(glGetUniformLocation(currentLightProgram(), "t1"), 1);
                                glUniform1i(glGetUniformLocation(currentLightProgram(), "t2"), 2);
                                glUniform1i(glGetUniformLocation(currentLightProgram(), "t3"), 3);
                                glUniform1f(glGetUniformLocation(currentLightProgram(), "time"), cggurrentTime());
                                
                                glUniform1i(glGetUniformLocation(currentLightProgram(), "t0_available"), 0);
                                glUniform1i(glGetUniformLocation(currentLightProgram(), "t1_available"), 0);
                                glUniform1i(glGetUniformLocation(currentLightProgram(), "t2_available"), 0);
                                glUniform1i(glGetUniformLocation(currentLightProgram(), "t3_available"), 0);
                                
                                //Bind all of the textures
                                for (g=0; g<currentPart.scexshader->maps.chunkcount; g++)
                                {
                                    int texIndex = [[[[parent _texManager] _textureLookupByID] objectForKey:[NSNumber numberWithLong:currentPart.scexshader->read_maps[g].bitm.TagId]] intValue];
                                    
                                    float u = currentPart.scexshader->read_maps[g].uscale;
                                    float v = currentPart.scexshader->read_maps[g].vscale;
                                    
                                    short c       = currentPart.scexshader->read_maps[g].colorFunction;
                                    short a       = currentPart.scexshader->read_maps[g].alphaFunction;
                                    short uf      = currentPart.scexshader->read_maps[g].uFunction;
                                    short vf      = currentPart.scexshader->read_maps[g].vFunction;
                                    
                                    if (g == 0)
                                    {
                                        glActiveTexture(GL_TEXTURE0);
                                        glUniform2f(glGetUniformLocation(currentLightProgram(), "t0_scale"), u,v);
                                        glUniform4i(glGetUniformLocation(currentLightProgram(), "t0_option"), c,a,uf,vf);
                                        glUniform1i(glGetUniformLocation(currentLightProgram(), "t0_available"), 1);
                                    }
                                    else if (g == 1)
                                    {
                                        glActiveTexture(GL_TEXTURE1);
                                        glUniform2f(glGetUniformLocation(currentLightProgram(), "t1_scale"), u,v);
                                        glUniform4i(glGetUniformLocation(currentLightProgram(), "t1_option"), c,a,uf,vf);
                                        glUniform1i(glGetUniformLocation(currentLightProgram(), "t1_available"), 1);
                                    }
                                    else if (g == 2)
                                    {
                                        glActiveTexture(GL_TEXTURE2);
                                        glUniform2f(glGetUniformLocation(currentLightProgram(), "t2_scale"), u,v);
                                        glUniform4i(glGetUniformLocation(currentLightProgram(), "t2_option"), c,a,uf,vf);
                                        glUniform1i(glGetUniformLocation(currentLightProgram(), "t2_available"), 1);
                                    }
                                    else if (g == 3)
                                    {
                                        glActiveTexture(GL_TEXTURE3);
                                        glUniform2f(glGetUniformLocation(currentLightProgram(), "t3_scale"), u,v);
                                        glUniform4i(glGetUniformLocation(currentLightProgram(), "t3_option"), c,a,uf,vf);
                                        glUniform1i(glGetUniformLocation(currentLightProgram(), "t3_available"), 1);
                                    }
                                    else
                                        continue;
                                    
                                    
                                    glEnable(GL_TEXTURE_2D);
                                    glBindTexture(GL_TEXTURE_2D, [parent _texManager]._glTextureTable[texIndex][0]);
                                    
                                    /*glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT);
                                    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT);
                                    glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
                                    */
                                    
                                    
                                }
                                
                                
                                glClientActiveTexture(GL_TEXTURE0);
                                glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                                glTexCoordPointer(2, GL_FLOAT, 0, texture_uv);
                                

                                if (currentIndex+currentPart.indexPointer.count+2 <= indexCount_R)
                                {
                                    glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
                                }
                                
                                glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                                
                               
                                glActiveTexture(GL_TEXTURE0);
                                glDisable(GL_TEXTURE_2D);
                                glActiveTexture(GL_TEXTURE1);
                                glDisable(GL_TEXTURE_2D);
                                glActiveTexture(GL_TEXTURE2);
                                glDisable(GL_TEXTURE_2D);
                                glActiveTexture(GL_TEXTURE3);
                                glDisable(GL_TEXTURE_2D);
                                
                                  /*
                                glActiveTexture(GL_TEXTURE2);
                                glDisable(GL_TEXTURE_2D);
                                glActiveTexture(GL_TEXTURE3);
                                glDisable(GL_TEXTURE_2D);
                                glActiveTexture(GL_TEXTURE4);
                                glDisable(GL_TEXTURE_2D);
                    */
                                
                                glUniform1i(texLoc, 0);
                            }
                            else if (currentPart.hasShader == 3)
                            {
                                //schi shader
                                activateLightProgram();
                                GLint texLoc = glGetUniformLocation(currentLightProgram(), "schiShader");
                                glUniform1i(texLoc, 1);
                                
                                glUniform1i(glGetUniformLocation(currentLightProgram(), "t0"), 0);
                                glUniform1i(glGetUniformLocation(currentLightProgram(), "t1"), 1);
                                glUniform1i(glGetUniformLocation(currentLightProgram(), "t2"), 2);
                                glUniform1i(glGetUniformLocation(currentLightProgram(), "t3"), 3);
                                
                                glUniform1i(glGetUniformLocation(currentLightProgram(), "t0_available"), 0);
                                glUniform1i(glGetUniformLocation(currentLightProgram(), "t1_available"), 0);
                                glUniform1i(glGetUniformLocation(currentLightProgram(), "t2_available"), 0);
                                glUniform1i(glGetUniformLocation(currentLightProgram(), "t3_available"), 0);
                                
                                glUniform1f(glGetUniformLocation(currentLightProgram(), "time"), cggurrentTime());
                                
                                //Bind all of the textures
                                for (g=0; g<maps; g++)
                                {
                                    int texIndex = [[[[parent _texManager] _textureLookupByID] objectForKey:[NSNumber numberWithLong:currentPart.shader->read_maps[g].bitm.TagId]] intValue];
                                    
                                    float u = currentPart.shader->read_maps[g].uscale;
                                    float v = currentPart.shader->read_maps[g].vscale;
                                    
                                    short c       = currentPart.shader->read_maps[g].colorFunction;
                                    short a       = currentPart.shader->read_maps[g].alphaFunction;
                                    short uf      = currentPart.shader->read_maps[g].uFunction;
                                    short vf      = currentPart.shader->read_maps[g].vFunction;
                                    int animate = currentPart.shader->read_maps[g].animation_period;
                                    
                                    if (g == 0)
                                    {
                                        glActiveTexture(GL_TEXTURE0);
                                        glUniform2f(glGetUniformLocation(currentLightProgram(), "t0_scale"), u,v);
                                        glUniform4i(glGetUniformLocation(currentLightProgram(), "t0_option"), c,a,uf,vf);
                                        glUniform1i(glGetUniformLocation(currentLightProgram(), "t0_available"), 1);
                                    }
                                    else if (g == 1)
                                    {
                                        glActiveTexture(GL_TEXTURE1);
                                        glUniform2f(glGetUniformLocation(currentLightProgram(), "t1_scale"), u,v);
                                        glUniform4i(glGetUniformLocation(currentLightProgram(), "t1_option"), c,a,uf,vf);
                                        glUniform1i(glGetUniformLocation(currentLightProgram(), "t1_available"), 1);
                                    }
                                    else if (g == 2)
                                    {
                                        glActiveTexture(GL_TEXTURE2);
                                        glUniform2f(glGetUniformLocation(currentLightProgram(), "t2_scale"), u,v);
                                        glUniform4i(glGetUniformLocation(currentLightProgram(), "t2_option"), c,a,uf,vf);
                                        glUniform1i(glGetUniformLocation(currentLightProgram(), "t2_available"), 1);
                                    }
                                    else
                                        continue;
                                    
                                    
                                    glEnable(GL_TEXTURE_2D);
                                    glBindTexture(GL_TEXTURE_2D, [parent _texManager]._glTextureTable[texIndex][0]);
                                    
                                    /*glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT);
                                     glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT);
                                     glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
                                     */
                                    
                                    
                                }
                                
                                
                                glClientActiveTexture(GL_TEXTURE0);
                                glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                                glTexCoordPointer(2, GL_FLOAT, 0, texture_uv);
                                
                                
                                if (currentIndex+currentPart.indexPointer.count+2 <= indexCount_R)
                                {
                                    glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
                                }
                                
                                glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                                
                                
                                glActiveTexture(GL_TEXTURE0);
                                glDisable(GL_TEXTURE_2D);
                                glActiveTexture(GL_TEXTURE1);
                                glDisable(GL_TEXTURE_2D);
                                glActiveTexture(GL_TEXTURE2);
                                glDisable(GL_TEXTURE_2D);
                                
                                /*
                                 glActiveTexture(GL_TEXTURE2);
                                 glDisable(GL_TEXTURE_2D);
                                 glActiveTexture(GL_TEXTURE3);
                                 glDisable(GL_TEXTURE_2D);
                                 glActiveTexture(GL_TEXTURE4);
                                 glDisable(GL_TEXTURE_2D);
                                 */
                                
                                glUniform1i(texLoc, 0);
                            }
                        }
                        else
                        {
                            
                        
              
                        
#define FLIP 1
#ifdef FLIP
                    for (g=maps-1; g>=0; g--)
                    {
#else
                    for (g=0; g<maps; g++)
                    {
#endif

                        //scexshader
                        int texIndex;
                        
                        if (currentPart.hasShader == 4)
                            texIndex = [[[[parent _texManager] _textureLookupByID] objectForKey:[NSNumber numberWithLong:currentPart.scexshader->read_maps[g].bitm.TagId]] intValue];
                        else //schi
                            texIndex = [[[[parent _texManager] _textureLookupByID] objectForKey:[NSNumber numberWithLong:currentPart.shader->read_maps[g].bitm.TagId]] intValue];
                        
                        if (useNewRenderer() == 4)
                            glActiveTextureARB(g);
                        else
                            glActiveTextureARB(GL_TEXTURE0_ARB);
                        
                        glEnable(GL_TEXTURE_2D);
                        
                        glBindTexture(GL_TEXTURE_2D, [parent _texManager]._glTextureTable[texIndex][0]);
                        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT);
                        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT);
                        glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
                        //glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_LINEAR);
                        
                        glEnable(GL_COLOR_MATERIAL) ;
                        glEnable(GL_BLEND);
                        //glBlendFunc(GL_DST_ALPHA,GL_ONE_MINUS_DST_ALPHA);
                        glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
                        
                        
                        glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_MODULATE);
                        
                        if (currentPart.hasShader == 4) //scex
                        {
                            if (useNewRenderer() == -1)
                            {
                                
                                //glColor4f(1.0, 1.0, 1.0, 1.0f);
                                if (currentPart.scexshader->read_maps[g].colorFunction == 0) //Current
                                {
                                    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_MODULATE);   //Modulate RGB with RGB
                                    glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_RGB, GL_PREVIOUS);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE1_RGB, GL_TEXTURE);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_RGB, GL_SRC_COLOR);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_RGB, GL_SRC_COLOR);
                                }
                                else if (currentPart.scexshader->read_maps[g].colorFunction == 4) //Add
                                {
                                    //glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_ADD);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_ADD);   //Modulate RGB with RGB
                                    glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_RGB, GL_PREVIOUS);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE1_RGB, GL_TEXTURE);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_RGB, GL_SRC_COLOR);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_RGB, GL_SRC_COLOR);
                                }
                                else //Other
                                {
                                    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_MODULATE);   //Modulate RGB with RGB
                                    glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_RGB, GL_PREVIOUS);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE1_RGB, GL_TEXTURE);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_RGB, GL_SRC_COLOR);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_RGB, GL_SRC_COLOR);
                                }
                                
                                
                                
                                if (currentPart.scexshader->read_maps[g].alphaFunction == 0) //Current
                                {
                                    glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_INTERPOLATE);   //Interpolate ALPHA with ALPHA
                                    glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_ALPHA, GL_PREVIOUS);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE1_ALPHA, GL_TEXTURE);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE2_ALPHA, GL_PREVIOUS);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_ALPHA, GL_SRC_ALPHA);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND2_ALPHA, GL_SRC_ALPHA);
                                }
                                else if (currentPart.scexshader->read_maps[g].alphaFunction == 4) //Add
                                {
                                    glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_ADD);  //Modulate ALPHA with ALPHA
                                    glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_ALPHA, GL_PREVIOUS);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE1_ALPHA, GL_TEXTURE);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_ALPHA, GL_SRC_ALPHA);
                                }
                                else //Other
                                {
                                    glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_MODULATE);  //Modulate ALPHA with ALPHA
                                    glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_ALPHA, GL_PREVIOUS);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE1_ALPHA, GL_TEXTURE);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_ALPHA, GL_SRC_ALPHA);
                                }
                                //glBlendFunc(GL_DST_ALPHA,GL_ONE_MINUS_DST_ALPHA);
                            }
                            else
                            {
                                //glColor4f(1.0, 1.0, 1.0, 1.0f);
                                if (currentPart.scexshader->read_maps[g].colorFunction == 0) //Current
                                    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
                                else if (currentPart.scexshader->read_maps[g].colorFunction == 4) //Add
                                    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
                                else //Other
                                    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_BLEND);
                                
                                if (currentPart.scexshader->read_maps[g].alphaFunction == 0) //Current
                                    glBlendFunc(GL_ONE,GL_ONE_MINUS_SRC_ALPHA);
                                else if (currentPart.scexshader->read_maps[g].alphaFunction == 4) //Add
                                    glBlendFunc(GL_SRC_ALPHA,GL_ONE);
                                //else //Other
                                    //glBlendFunc(GL_DST_ALPHA,GL_ONE_MINUS_DST_ALPHA);
                            }
                            
                            //(useNewRenderer() == 4)
                            
                        }
                        else  //schi
                        {
                            if (useNewRenderer() == 4)
                            {
                                glColor4f(1.0, 1.0, 1.0, 0.8f);
                                if (currentPart.shader->read_maps[g].colorFunction == 0) //Current
                                {
                                    
                                }
                                else if (currentPart.shader->read_maps[g].colorFunction == 4) //Add
                                {
                                   
                                }
                                else //Other
                                {
                                    //glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
                                   // glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_REPLACE);   //Modulate RGB with RGB
        
                                }
                                
                                
                                
                                if (currentPart.shader->read_maps[g].alphaFunction == 0) //Current
                                {
                                    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);

                                }
                                else if (currentPart.shader->read_maps[g].alphaFunction == 4) //Add
                                {
          
                                }
                                else //Other
                                {
                                    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB_ARB, GL_MODULATE);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_RGB_ARB, g);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_RGB_ARB, GL_SRC_COLOR);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE1_RGB_ARB, g+1);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_RGB_ARB, GL_SRC_COLOR );
                 
                                    
                                }
                            }
                            else
                            {
                                //continue;
                                if (currentPart.shader->read_maps[g].colorFunction == 0)
                                {
                                    if (maps > 1)
                                        continue;
                                    
                                    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_REPLACE);
                                    //glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
                                }
                                else if (currentPart.shader->read_maps[g].colorFunction == 4)
                                    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
                                else
                                {
                                    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
                                    glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_INTERPOLATE);
                                    //(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_BLEND);
                                    
                                    
                                }
                                
                                
                                //glBlendFuncSeparate

                                if (currentPart.shader->read_maps[g].alphaFunction == 0) //Current
                                {
                                    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
                                    //glBlendFunc(GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA);
                                    //continue;
                                }
                                else if (currentPart.shader->read_maps[g].alphaFunction == 4) //Add
                                {
                                    
                                    //continue;
                                }
                                else
                                {
                                   //glBlendFunc(GL_DST_COLOR, GL_ZERO);
                                }
                            }
                            
                        }
                        
                        //glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
                        
                        if (useNewRenderer() == 4)
                            glClientActiveTextureARB(g);
                        else
                        glClientActiveTextureARB(GL_TEXTURE0_ARB);
                        
                        glTexCoordPointer(2, GL_FLOAT, 0, texture_uv);//&currentPart.shader->read_maps[g].texture_uv);
                        glEnableClientState(GL_TEXTURE_COORD_ARRAY); // enable array data to shader
                        
                        if (currentPart.hasShader == 4)
                        {
                            glMatrixMode(GL_TEXTURE);
                            glPushMatrix();
                            glScalef(currentPart.scexshader->read_maps[g].uscale,currentPart.scexshader->read_maps[g].vscale, 0.0);
                        }
                        else if (currentPart.hasShader == 3)
                        {
                            glAlphaFunc(GL_GREATER, 0.1);
                            //glEnable(GL_ALPHA_TEST);
                            glMatrixMode(GL_TEXTURE);
                            glPushMatrix();
                            glScalef(currentPart.shader->read_maps[g].uscale,currentPart.shader->read_maps[g].vscale, 0.0);
                        }
                        
                        if (currentIndex+currentPart.indexPointer.count+2 <= indexCount_R)
                        {
#ifdef VERTEX_BUFFERS
                            glDrawElements(GL_TRIANGLE_STRIP, 0, GL_UNSIGNED_SHORT, NULL);
#else
                            glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
#endif
                        }
                        
                        glPopMatrix();
                        glMatrixMode(GL_MODELVIEW);

                        if (useNewRenderer() == 4)
                        {
                            glBindTexture(GL_TEXTURE_2D, g);
                            glClientActiveTextureARB(g);
                        }
                        else
                        {
                        glBindTexture(GL_TEXTURE_2D, GL_TEXTURE0);
                        glClientActiveTextureARB(GL_TEXTURE0_ARB);
                        }

                        glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_MODULATE);
                        glDisable(GL_TEXTURE_2D);
                        glAlphaFunc(GL_GREATER, 0.1);
                        //glEnable(GL_ALPHA_TEST);
                    }
                        }
                    glEnableClientState(GL_VERTEX_ARRAY); // enable array data to shader
                    
                    //glEnable(GL_DEPTH_TEST);
                        }
                    
#else
                        
                        //---------------//---------------//---------------//---------------
                        //OLD SKY CODE
                        //---------------//---------------//---------------//---------------
                        
                    USEDEBUG CSLog(@"DIV 10 %d", i);
                        for (g=maps-1; g >=0 ; g--)
                        {
                            
                            //scexshader
                            int texIndex;
                            
                            if (currentPart.hasShader == 4)
                                texIndex = [[[parent _texManager]._textureLookupByID objectForKey:[NSNumber numberWithLong:currentPart.scexshader->read_maps[g].bitm.TagId]] intValue];
                            else //schi
                                texIndex = [[[parent _texManager]._textureLookupByID objectForKey:[NSNumber numberWithLong:currentPart.shader->read_maps[g].bitm.TagId]] intValue];
                            
#ifndef MACVERSION
                            glActiveTextureARB(0x84C0+g);
#else
                            glActiveTextureARB(g);
#endif
                            glEnable(GL_TEXTURE_2D);
                            glBindTexture(GL_TEXTURE_2D, [parent _texManager]._glTextureTable[texIndex][0]);
                            glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT);
                            glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT);
                            glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
                            
                      
                            glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_LINEAR);

                            
                            glEnable(GL_BLEND);
                            //glColor4f(1.0, 1.0, 1.0, 0.2f);
                            //glBlendFunc(GL_DST_ALPHA,GL_ONE);
                            glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
                            
                            
                            if (currentPart.hasShader == 4) //scex
                            {
                               
                                if (currentPart.scexshader->read_maps[g].colorFunction == 0)
                                    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
                                else if (currentPart.scexshader->read_maps[g].colorFunction == 4)
                                    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_ADD);
                                else
                                    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
                            }
                            else  //schi
                            {
                            
                                if (useNewRenderer() == 4)
                                {
                                    
                                    
                                    if (currentPart.shader->read_maps[g].colorFunction == 0) //Current
                                    {
                                        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
                                    }
                                    else if (currentPart.shader->read_maps[g].colorFunction == 4) //Add
                                    {
                                        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
                                        glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_ADD);   //Modulate RGB with RGB
                                        glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_RGB, GL_PREVIOUS);
                                        glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE1_RGB, GL_TEXTURE);
                                        glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_RGB, GL_SRC_COLOR);
                                        glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_RGB, GL_SRC_COLOR);
                                    }
                                    else //Other
                                    {
                                        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
                                        glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_MODULATE);   //Modulate RGB with RGB
                                        glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_RGB, GL_PREVIOUS);
                                        glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE1_RGB, GL_TEXTURE);
                                        glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_RGB, GL_SRC_COLOR);
                                        glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_RGB, GL_SRC_COLOR);
                                    }
                                    
                                    
                                    
                                    if (currentPart.shader->read_maps[g].alphaFunction == 0) //Current
                                    {
                                        
                                    }
                                    else if (currentPart.shader->read_maps[g].alphaFunction == 4) //Add
                                    {
                                        glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_ADD);  //Modulate ALPHA with ALPHA
                                        glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_ALPHA, GL_PREVIOUS);
                                        glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE1_ALPHA, GL_TEXTURE);
                                        glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
                                        glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_ALPHA, GL_SRC_ALPHA);
                                    }
                                    else //Other
                                    {
                                        glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_MODULATE);  //Modulate ALPHA with ALPHA
                                        glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_ALPHA, GL_PREVIOUS);
                                        glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE1_ALPHA, GL_TEXTURE);
                                        glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
                                        glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_ALPHA, GL_SRC_ALPHA);
                                    }
                                }
                                else
                                {
                                    if (currentPart.shader->read_maps[g].colorFunction == 0)
                                        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
                                    else if (currentPart.shader->read_maps[g].colorFunction == 4)
                                        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_ADD);
                                    else
                                        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
                                }
                            }

                            //glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
                            
                            
                            
                    }
    
                    
          
                        for (g=0; g < maps; g++)
                        {
#ifndef MACVERSION 
                            glClientActiveTextureARB(0x84C0+g);
                            glActiveTextureARB(0x84C0+g);
#else
                            glClientActiveTextureARB(g);
                            glActiveTextureARB(g);
#endif
                            
                            glEnable(GL_TEXTURE_2D);
                            
                            glTexCoordPointer(2, GL_FLOAT, 0, texture_uv);//&currentPart.shader->read_maps[g].texture_uv);
                            glEnableClientState(GL_TEXTURE_COORD_ARRAY); // enable array data to shader
                        }
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    //Need to redraw EVERY map! :(
                    //NO
                        if (currentPart.hasShader == 4)
                        {
                            for (g=0; g < maps; g++)
                            {
    #ifndef MACVERSION
                                glActiveTextureARB(0x84C0+g);
    #else
                                glActiveTextureARB(g);
    #endif
                                glMatrixMode(GL_TEXTURE);
                                glPushMatrix();
                                glScalef(currentPart.scexshader->read_maps[g].uscale,currentPart.scexshader->read_maps[g].vscale, 0.0);
                         
                            }
                        }
                        else if (currentPart.hasShader == 3)
                        {
                            for (g=0; g < maps; g++)
                            {
#ifndef MACVERSION
                            glActiveTextureARB(0x84C0+g);
#else
                            glActiveTextureARB(g);
#endif
                            glMatrixMode(GL_TEXTURE);
                            glPushMatrix();
                            glScalef(currentPart.shader->read_maps[g].uscale,currentPart.shader->read_maps[g].vscale, 0.0);
                        
                            }
                        }
                    
                        if (currentIndex+currentPart.indexPointer.count+2 <= indexCount_R)
                        {
                            //glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
                        }
        
                        if (currentPart.hasShader == 4)
                        {
#ifndef MACVERSION
                            glActiveTextureARB(0x84C0+0);
#else
                            glActiveTextureARB(0);
#endif
                            //glPopMatrix();
                            glMatrixMode(GL_MODELVIEW);
                        }
                        else if (currentPart.hasShader == 3)
                        {
#ifndef MACVERSION
                            glActiveTextureARB(0x84C0+g);
#else
                            glActiveTextureARB(g);
#endif
                            //glPopMatrix();
                            glMatrixMode(GL_MODELVIEW);
                        }

                    
                    
                    
                        for (g=0; g < maps; g++)
                        {
#ifndef MACVERSION
                            glBindTexture(GL_TEXTURE_2D, 0x84C0);
                            glClientActiveTextureARB(0x84C0+g);
#else
                            glBindTexture(GL_TEXTURE_2D, 0);
                            glClientActiveTextureARB(g);
#endif
                            glDisable(GL_TEXTURE_2D);
                        }
                    
                    
#endif
                    
                    
                    USEDEBUG CSLog(@"DIV 16 %d", i);
                }
                        else
                        {
                        
                        //PC Friendly VBO rendering
                        
                        /* GL Texture stuff goes hur */
                        if (currentPart.shaderIndex != -1)
                        {
                            [[parent _texManager] activateTextureOfIdent:currentPart.shaderBitmapIndex subImage:0 useAlphas:useAlphas];
                        }
                        
                        
                        glTexCoordPointer(2, GL_FLOAT, 0, texture_uv);//&currentPart.shader->read_maps[g].texture_uv);
                            
#ifdef VERTEX_BUFFERS
                            glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, 0);
#else
                        //glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
#endif
                            
                        }
                    }
     USEDEBUG CSLog(@"DIV 17 %d", i);
                    glDisable(GL_ALPHA_TEST);
                    //currentPart.shader;

                    //int g;
                    //for (g=0; g < parts[x].shader->maps.chunkcount; g++)
                    //{
                    //    [[parent _texManager] loadTextureOfIdent:parts[x].shader->read_maps[g].bitm.TagId subImage:0];
                    //}
                    
                }
                else if (currentPart.baseMapIndex != -1 && useNewRenderer() >= 2) //Candlelight
                {
                            //glEnable(GL_BLEND);
                     bool showDetail = true;
                    
                   
                 USEDEBUG CSLog(@"DIV 18 %d", i);
                    
                    //glColor4f(1.0, 1.0, 1.0, 1.0);
                    if (useNewRenderer() >= 2)
                    {
                        
                        
                        //Calculate the alpha amount based on distance away, from 0.05 to
                        float minimum = 0.4;
                        float maximum = 0.95;
                        
                        //Whats our distance?
                        float ourdist = 0.0;
                        if (ourdist > 100);
                            ourdist=100;
                        
                        float rend = minimum+(maximum-minimum)/(ourdist / 20);
                        
                        glAlphaFunc ( GL_GREATER, rend ) ;
                        glEnable( GL_ALPHA_TEST ) ;
                    }
                    else
                    {
                        glAlphaFunc ( GL_GREATER, 0 ) ;
                        glDisable( GL_ALPHA_TEST ) ;
                    }
                    
                   
                    
                    
                    glDepthFunc(GL_LEQUAL);
                    glEnable(GL_BLEND);
                    
                    
             
                    glBlendFunc(GL_DST_ALPHA,GL_ONE_MINUS_DST_ALPHA);
                    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
                    
                    
                    //glPushMatrix();
                    [[parent _texManager] activateTextureAndLightmap:currentPart.baseMapIndex lightmap:currentPart.detailMapIndex secondary:0 subImage:0];
                    
        
                    
                    if (currentPart.detailMapIndex != -1)
                    {
                        GLint texLoc = glGetUniformLocation(currentLightProgram(), "isDetailed");
                        glUniform1i(texLoc, 1);
                    }
    
                    //glColor4f(1.0, 1.0, 1.0, 1.5);
                    
                    if (useNewRenderer() != 1)
                    {
                    
                        USEDEBUG CSLog(@"DIV 19 %d", i);
                    glActiveTextureARB(GL_TEXTURE0_ARB);
   
                    #ifndef VERTEX_BUFFERS
                    // texture coord 0
                    glClientActiveTextureARB(GL_TEXTURE0_ARB); // program texcoord unit 0
                    glTexCoordPointer(2, GL_FLOAT, 0, texture_uv);
                    glEnableClientState(GL_TEXTURE_COORD_ARRAY); // enable array data to shader
                    USEDEBUG CSLog(@"DIV 20 %d", i);
                    if (showDetail)
                    {
                        //texture coord 1
                        glClientActiveTextureARB(GL_TEXTURE1_ARB);
                        glTexCoordPointer(2, GL_FLOAT, 0, texture_uv);
                        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                        
                        glActiveTextureARB(GL_TEXTURE1_ARB);
                        glMatrixMode(GL_TEXTURE);
                        glPushMatrix();
                        glScalef(currentPart.detailMapScale,currentPart.detailMapScale, 0.0);
                    }
                    #endif
                  
                    USEDEBUG CSLog(@"DIV 21 %d", i);
                        glUseProgram(0);
#ifdef VERTEX_BUFFERS
                    //glEnableClientState(GL_VERTEX_ARRAY);

                    //NSLog(@"Drawing %d %d %d %d", currentIndex, currentPart.indexPointer.count+2, vertexVBO, indexVBO);
       
                    glBindBuffer( GL_ARRAY_BUFFER, vertexVBO );
                    glVertexPointer(3, GL_FLOAT, 0, 0 );
                    
                    glBindBuffer( GL_ARRAY_BUFFER        , textureVBO );
                    glTexCoordPointer(2, GL_FLOAT, 0, 0 );
                        
                    glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, indexVBO );
                    glIndexPointer(GL_UNSIGNED_SHORT, 0, currentIndex );
                        
                    glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, (void*)0);
                    //glDisableClientState(GL_VERTEX_ARRAY);
#else
    
                    glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
#endif
                        
                    USEDEBUG CSLog(@"DIV 22 %d", i);
                    
                    if (showDetail)
                    {
                        glActiveTextureARB(GL_TEXTURE1_ARB);
                        glPopMatrix();
                        glMatrixMode(GL_MODELVIEW);
                        
                        glClientActiveTextureARB(GL_TEXTURE1_ARB);
                        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                    }
                    USEDEBUG CSLog(@"DIV 23 %d", i);
                    glClientActiveTextureARB(GL_TEXTURE0_ARB);
                    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                    
                    glActiveTextureARB(GL_TEXTURE2_ARB);
                    glBindTexture(GL_TEXTURE_2D, 0);
                    glDisable(GL_TEXTURE_2D);
                    USEDEBUG CSLog(@"DIV 24 %d", i);
                    glActiveTextureARB(GL_TEXTURE1_ARB);
                    glBindTexture(GL_TEXTURE_2D, 0);
                    glDisable(GL_TEXTURE_2D);
                    USEDEBUG CSLog(@"DIV 25 %d", i);
                    glActiveTextureARB(GL_TEXTURE0_ARB);
                    glBindTexture(GL_TEXTURE_2D, 0);
                    glDisable(GL_TEXTURE_2D);
                    glDisable(GL_BLEND);
                        USEDEBUG CSLog(@"DIV 26 %d", i);
                        
                    }
                    else
                    {
                    //PC Friendly VBO rendering
                    
                    /* GL Texture stuff goes hur */
                    if (currentPart.shaderIndex != -1)
                    {
                        [[parent _texManager] activateTextureOfIdent:currentPart.shaderBitmapIndex subImage:0 useAlphas:useAlphas];
                    }
                    USEDEBUG CSLog(@"DIV 27 %d", i);
                    
                    glTexCoordPointer(2, GL_FLOAT, 0, texture_uv);//&currentPart.shader->read_maps[g].texture_uv);
                        
#ifdef VERTEX_BUFFERS
                    glDrawElements(GL_TRIANGLE_STRIP, 0, GL_UNSIGNED_SHORT, 0);
#else
                    glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
#endif
                        
                    USEDEBUG CSLog(@"DIV 28 %d", i);
                    }
                    
                    //glEnable(GL_DEPTH_TEST);
                    glDisable(GL_ALPHA_TEST);
                    
                    USEDEBUG CSLog(@"DIV 29 %d", i);
                    glDisable(GL_TEXTURE_2D);
                    glDisable(GL_BLEND);
                    
                    
                    USEDEBUG CSLog(@"DIV 30 %d", i);

     if (useNewRenderer() == 3)
     {
                    if (currentPart.detailMapIndex != -1) //No need to render these as they arent darkened.
                    {
                        
                        int k = 0;
                        for(k=0; k < 1; k++)
                        {
                        //Don't draw the sun for alpha polygons (but how do we know??)
                        glDepthFunc(GL_LEQUAL);
                    
                        //glEnable(GL_DEPTH_TEST);
                        glDisable(GL_ALPHA_TEST);
                        
                        //Third pass - brighten your day!
                        glAlphaFunc ( GL_GREATER, 0.8 ) ;
                        glEnable( GL_ALPHA_TEST ) ;
                        
                        glEnable(GL_BLEND);
                        glBlendFunc(GL_DST_COLOR, GL_ONE);
                       
                        //glColor4f(1.0f,1.0f,1.0f,1.0f);
                        
                        //glEnableClientState(GL_VERTEX_ARRAY);
#ifdef VERTEX_BUFFERS
                        glVertexPointer(3, GL_FLOAT, 0, 0);
#else
                        glVertexPointer(3, GL_FLOAT, 0, vertex_array);
#endif
                            
                        //glDisable(GL_DEPTH_TEST);
                        
                        [[parent _texManager] activateTextureAndLightmap:currentPart.baseMapIndex lightmap:currentPart.detailMapIndex secondary:0 subImage:0 isAlphaType:YES];
                        
                        glActiveTextureARB(GL_TEXTURE1_ARB);
                        glDisable(GL_TEXTURE_2D);
                        
                        glActiveTextureARB(GL_TEXTURE0);
                        glEnable(GL_TEXTURE_2D);
                        
                        // texture coord 0
                        glClientActiveTextureARB(GL_TEXTURE0_ARB); // program texcoord unit 0
                        glTexCoordPointer(2, GL_FLOAT, 0, texture_uv);
                        glEnableClientState(GL_TEXTURE_COORD_ARRAY); // enable array data to shader
                        
                        glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
                        ////glEnable(GL_DEPTH_TEST);
                        
                        glDisable(GL_TEXTURE_2D);
                        glDisable(GL_BLEND);
                        glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
                        glBlendFunc(GL_DST_ALPHA,GL_ONE_MINUS_DST_ALPHA);
                        }
                    }
                }

USEDEBUG CSLog(@"DIV 31 %d", i);
                    if (useNewRenderer() != 2)
                    {
                        glDisable(GL_BLEND);
                    }
                    
                }
                else if (currentPart.shaderIndex != -1)
                {
                    USEDEBUG CSLog(@"DIV 32 %d", i);
                    if (useNewRenderer() != 1)
                    {
                    
                    if (useNewRenderer() >= 2)
                        continue;
                    
                    [[parent _texManager] activateTextureOfIdent:currentPart.shaderBitmapIndex subImage:0 useAlphas:true ];
                        
       
                    glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_LINEAR);

                        
                    //glColor4f(1.0, 1.0, 1.0, 0.5);
                    glClientActiveTextureARB(GL_TEXTURE0_ARB); // program texcoord unit 0
                    glTexCoordPointer(2, GL_FLOAT, 0, texture_uv);
                    glEnableClientState(GL_TEXTURE_COORD_ARRAY); // enable array data to shader
                    
#ifdef VERTEX_BUFFERS
                        glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, 0);
#else
                    glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
#endif
                        
                    //glColor4f(1.0, 1.0, 1.0, 1.5);
                    
                    glClientActiveTextureARB(GL_TEXTURE0_ARB);
                    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                    }
                    else
                    {
                    //PC Friendly VBO rendering
                    
                    /* GL Texture stuff goes hur */
                    if (currentPart.shaderIndex != -1)
                    {
                        [[parent _texManager] activateTextureOfIdent:currentPart.shaderBitmapIndex subImage:0 useAlphas:useAlphas];
                    }
                    
                    
                    glTexCoordPointer(2, GL_FLOAT, 0, texture_uv);//&currentPart.shader->read_maps[g].texture_uv);
                        
#ifdef VERTEX_BUFFERS
                        glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, 0);
#else
                    glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
#endif
                        
                    }
                    
                }
                
                
                currentIndex+=currentPart.indexPointer.count+2;
            }
            else
            {
                NSLog(@"BAD PART");
            }
#endif
        }
       
        #ifdef VERTEX_BUFFERS
            glBindBuffer(GL_ARRAY_BUFFER, 0);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        #endif
            
            
            /*//Check for error
            GLenum error = glGetError();
            if( error != GL_NO_ERROR )
            {
                printf( "Final error %s\n", gluErrorString( error ) );
            }*/
            
        return;

    }
    }
    
    //END CODE
    
	for (i = 0; i < partsref.chunkcount; i++)
	{
		currentPart = parts[i];
		if (currentPart.indexPointer.rawPointer[0] == currentPart.indexPointer.rawPointer[1])
		{
			/* GL Texture stuff goes hur */
			if (currentPart.shaderIndex != -1)
			{
				[[parent _texManager] activateTextureOfIdent:currentPart.shaderBitmapIndex subImage:0 useAlphas:useAlphas];
			}

            
            unsigned short index;
            if (textures)
            {
                glBegin(GL_TRIANGLE_STRIP);
                for (x = 0; x < currentPart.indexPointer.count + 2; x++)
                {
                    index = currentPart.indices[x];
                    Vector *tempVector = &currentPart.vertices[index];
                    
                    glNormal3f(tempVector->normalx,tempVector->normaly,tempVector->normalz);
                    //glTexCoord2f(tempVector->u * u_scale, tempVector->v * v_scale);
                    glVertex3f(tempVector->x,tempVector->y,tempVector->z);
                }
                glEnd();
            }
            else
            {
                glBegin(GL_TRIANGLE_STRIP);
                for (x = 0; x < currentPart.indexPointer.count + 2; x++)
                {
                    index = currentPart.indices[x];
                    Vector *tempVector = &currentPart.vertices[index];
                    
                    glNormal3f(tempVector->normalx,tempVector->normaly,tempVector->normalz);
                    glVertex3f(tempVector->x,tempVector->y,tempVector->z);
                }
                glEnd();
            }
			
            glDisable(GL_TEXTURE_2D);
            glDisable(GL_BLEND);
		}
	}
        glFlush();
        
	
}
@synthesize numParts;
@synthesize vertexSize;
@synthesize vertexOffset;
@synthesize textures;
@synthesize _mapfile;
@synthesize parent;
@synthesize _texManager;
@synthesize parts;
@synthesize texturesLoaded;
@end
