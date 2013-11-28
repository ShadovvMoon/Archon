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
		
		[_mapfile readBlockOfData:&me.junk size_of_buffer:36];
		
		partsref = [_mapfile readReflexive];
		
		
		textures = malloc(partsref.chunkcount * sizeof(GLuint));
		
		[_mapfile seekToAddress:partsref.offset];
		
		parts = (part *)malloc(sizeof(part) * partsref.chunkcount);
		for (x = 0; x < partsref.chunkcount; x++)
		{
			part *currentPart = &parts[x];
			[_mapfile readBlockOfData:currentPart->junk4 size_of_buffer:4]; //FLAGS
			[_mapfile readShort:&currentPart->shaderIndex]; //SHADER INDEX
			
            //NSLog(@"%d", currentPart->shaderIndex);
            
			[_mapfile readBlockOfData:&currentPart->junk size_of_buffer:66];// <-- This little baby was causing a buffer overrun on PPC macs, so I'm just skipping it
			//[_mapfile skipBytes:66];
			
			[_mapfile readLong:&currentPart->indexPointer.count]; 
			[_mapfile readLong:&currentPart->indexPointer.rawPointer[0]];
			[_mapfile readLong:&currentPart->indexPointer.rawPointer[1]];
			
			//#ifdef __DEBUG__
			if (currentPart->indexPointer.rawPointer[1] != currentPart->indexPointer.rawPointer[0])
				NSLog(@"BadPartInt!"); // Whatever the hell that is
			//#endif
				
			[_mapfile readBlockOfData:currentPart->junk2 size_of_buffer:4];
			
			[_mapfile readLong:&currentPart->vertPointer.count];
			[_mapfile readBlockOfData:currentPart->vertPointer.junk size_of_buffer:8];
			[_mapfile readLong:&currentPart->vertPointer.rawPointer];
			
            [_mapfile readLong:&currentPart->compressedVertPointer.count];
			[_mapfile readBlockOfData:currentPart->compressedVertPointer.junk size_of_buffer:8];
			[_mapfile readLong:&currentPart->compressedVertPointer.rawPointer];
            
			[_mapfile readBlockOfData:currentPart->junk3 size_of_buffer:12];
			
			endOfPart = [_mapfile currentOffset];
			
            //NSLog(@"%d %d", currentPart->vertPointer.count, currentPart->compressedVertPointer.count);
            
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
    
    [self setupDrawing];
    
	return self;
}
- (void)dealloc
{	
	//NSLog(@"Destroying geometry!");
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
    //NSLog(@"Loading bitmaps");
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
			
            //NSLog(@"%d", parts[x].shaderIndex);
            
            if (parts[x].shaderIndex == -1)
            {
                NSLog(@"The shader is missing for this part");
                return;
            }
            
            parts[x].textureIndex = -1;
            NSString *type = [parent shaderTypeForIndex:parts[x].shaderIndex];
           // 
            //NSLog(type);
            
            if ([type isEqualToString:@"osos"])
            {
                soso *shader = (soso *)malloc(sizeof(soso));
                [_mapfile loadSOSO:shader forID:[parent shaderIdentForIndex:parts[x].shaderIndex]];
                
                parts[x].baseMapIndex = shader->baseMap.TagId;
                parts[x].detailMapIndex = shader->detailMap.TagId;
                parts[x].detailMapScale = shader->detailScale;
                parts[x].shaderBitmapIndex = shader->baseMap.TagId;
                
                //NSLog([parent tagName]);
                //NSLog(@"DETAIL MAP %d", shader->detailMap.TagId);
                
                [[parent _texManager] loadTextureOfIdent:parts[x].baseMapIndex subImage:0];
                [[parent _texManager] loadTextureOfIdent:parts[x].detailMapIndex subImage:0];
            }
            else if ([type isEqualToString:@"ihcs"])
            {
                //NSLog(@"Loading ichs");
                
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
                
                //NSLog(@"ICHS loaded");
            }
            /*else if ([type isEqualToString:@"algs"])
            {
                //NSLog(@"LOADING GLASS");
                //NSLog([parent tagName]);
                
                parts[x].shaderBitmapIndex = [[[_mapfile bitmsTagForShaderId:[parent shaderIdentForIndex:parts[x].shaderIndex]] objectAtIndex:1] idOfTag];
                parts[x].baseMapIndex = parts[x].shaderBitmapIndex;
                parts[x].detailMapIndex = -1;
                
                parts[x].lengthOfBitmapArray = -1;
                [[parent _texManager] loadTextureOfIdent:parts[x].shaderBitmapIndex subImage:0];
            }*/
            else if ([type isEqualToString:@"xecs"])
            {
               // NSLog(@"Loading xecs");
                
                scex *shader = (scex *)malloc(sizeof(scex));
                [_mapfile loadSCEX:shader forID:[parent shaderIdentForIndex:parts[x].shaderIndex]];
                
                parts[x].scexshader = shader;
                parts[x].hasShader = 4;
                parts[x].baseMapIndex = -1;
                //NSLog(@"Loading parts %d", (parts[x].scexshader->maps.chunkcount + ((scex*)parts[x].scexshader)->maps2.chunkcount));
                
                
                
                //Replace the first texture with a precalculated sky texture.
                //_glTextureTable_Compiled
                
                //Load up all of the map textures.
                int g;
                for (g=0; g < (parts[x].scexshader->maps.chunkcount + ((scex*)parts[x].scexshader)->maps2.chunkcount); g++)
                {
                    //NSLog(@"%d %ld", g, parts[x].scexshader->read_maps[g].bitm.TagId);
                    [[parent _texManager] loadTextureOfIdent:parts[x].scexshader->read_maps[g].bitm.TagId subImage:0];
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
                    
                    NSLog(@"CREATING TILED IMAGE FILE %f %f", bitmapSize.width, bitmapSize.height);
                    
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
                //NSLog(@"SCEX loaded");
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
                //NSLog(@"Load bitmaps %ld",parts[x].shaderBitmapIndex);
                
                parts[x].lengthOfBitmapArray = -1;
                [[parent _texManager] loadTextureOfIdent:parts[x].shaderBitmapIndex subImage:0];
                
            }
		}
		else
		{
		
            parts[x].baseMapIndex = -1;
			parts[x].shaderBitmapIndex = [[_mapfile bitmTagForShaderId:[parent shaderIdentForIndex:parts[x].shaderIndex]] idOfTag];
            //NSLog(@"Load bitmaps %ld",parts[x].shaderBitmapIndex);
            
            parts[x].lengthOfBitmapArray = -1;
			[[parent _texManager] loadTextureOfIdent:parts[x].shaderBitmapIndex subImage:0];
			
		}
	}
	texturesLoaded = TRUE;
    
    
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
    
    USEDEBUG NSLog(@"Initialing drawing");
    
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
                    vertex_array[a] = vertex.x;
                    vertex_array[a+1] = vertex.y;
                    vertex_array[a+2] = vertex.z;
                    //normals[a]=vertex.normalx;
                    //normals[a+2]=vertex.normaly;
                    //normals[a+3]=vertex.normalz;
                    
                    
                    
                    
                    
                    
                    texture_uv[uvr] = vertex.u*u_scale;
                    texture_uv[uvr+1] = vertex.v*v_scale;
                    
                    uvr+=2;
                    a+=3;
                }
                
                
            }
            
           
            
            
        }
    }
    indexCount_R = ind;
    //NSLog(@"Complete");
    
    drawingSetup = YES;
    
}

- (void)drawIntoView:(BOOL)useAlphas distance:(float)dist
{
    if (!drawingSetup)
    {
        NSLog(@"Drawing not setup");
        return;
    }
    USEDEBUG NSLog(@"DIV 1");
    useAlphas = YES;
    
	int i, x;
	part currentPart;
	float u_scale, v_scale;
			
	u_scale = [parent u_scale];
	v_scale = [parent v_scale];
	USEDEBUG NSLog(@"DIV 2");
    if (partsref.chunkcount <= 0)
        return;
    
    //--------------------------------
    //The copyright for the following code is owned by Samuel Colbran (Samuco).
    //The copyright for other smaller segments that are not identified by these comments are also owned by Samuel Colbran (Samuco).
    //--------------------------------
    USEDEBUG NSLog(@"DIV 3");
    if (TRUE)//useNewRenderer())
    {
       glDepthFunc(GL_LEQUAL);
        glVertexPointer(3, GL_FLOAT, 0, vertex_array);
        glNormalPointer(GL_FLOAT, 0, normals);
        USEDEBUG NSLog(@"DIV 4");
        int currentIndex = 0;
        for (i = 0; i < partsref.chunkcount; i++)
        {
            currentPart = parts[i];
            if (currentPart.indexPointer.rawPointer[0] == currentPart.indexPointer.rawPointer[1])
            {
                glDisable(GL_ALPHA_TEST);
                
                USEDEBUG NSLog(@"DIV 5 %d", i);
                currentPart.lengthOfBitmapArray = -1;
                
                if ((currentPart.hasShader==3 || currentPart.hasShader == 4) && useNewRenderer() >= 2)
                {
                   
                    
                    
                    
                    
                    
                    USEDEBUG NSLog(@"DIV 6 %d", i);
                    glEnable(GL_BLEND);
                    glBlendFunc(GL_DST_ALPHA,GL_ONE_MINUS_DST_ALPHA);
                    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
                    
                    USEDEBUG NSLog(@"DIV 7 %d", i);
                    //NSLog(@"1");
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

                    
                    USEDEBUG NSLog(@"DIV 8 %d", i);
                    //glColor4f(1.0, 1.0, 1.0, 1.0);
                    int g;
                    
                    glDepthFunc(GL_LEQUAL);
                    
                    USEDEBUG NSLog(@"DIV 9 %d", i);
                    
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

                        if (currentIndex+currentPart.indexPointer.count+2 <= indexCount_R)
                        {
                            glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
                        }
                        
                        glClientActiveTextureARB(GL_TEXTURE0_ARB);
                        glDisable(GL_TEXTURE_2D);
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
                            texIndex = [[[parent _texManager]._textureLookupByID objectForKey:[NSNumber numberWithLong:currentPart.scexshader->read_maps[g].bitm.TagId]] intValue];
                        else //schi
                            texIndex = [[[parent _texManager]._textureLookupByID objectForKey:[NSNumber numberWithLong:currentPart.shader->read_maps[g].bitm.TagId]] intValue];
                        
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
                            glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
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
                    
                    
#else
                        
                        //---------------//---------------//---------------//---------------
                        //OLD SKY CODE
                        //---------------//---------------//---------------//---------------
                        
                    USEDEBUG NSLog(@"DIV 10 %d", i);
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
                            glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
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
                    
                    
                    USEDEBUG NSLog(@"DIV 16 %d", i);
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
                        glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
                        
                        }
                    }
     USEDEBUG NSLog(@"DIV 17 %d", i);
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
                    
                 USEDEBUG NSLog(@"DIV 18 %d", i);
                    
                    //glColor4f(1.0, 1.0, 1.0, 1.0);
                    if (useNewRenderer() >= 2)
                    {
                        //Calculate the alpha amount based on distance away, from 0.05 to
                        float minimum = 0.4;
                        float maximum = 0.95;
                        
                        //Whats our distance?
                        float ourdist = dist;
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
                    
                    bool showDetail = true;
                    
                    
                    glDepthFunc(GL_LEQUAL);
                    glEnable(GL_BLEND);
                    
                    
             
                    glBlendFunc(GL_DST_ALPHA,GL_ONE_MINUS_DST_ALPHA);
                    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
                    
                    
                    //glPushMatrix();
                    [[parent _texManager] activateTextureAndLightmap:currentPart.baseMapIndex lightmap:currentPart.detailMapIndex secondary:0 subImage:0];
                    
        
                    
                    //glColor4f(1.0, 1.0, 1.0, 1.5);
                    
                    if (useNewRenderer() != 1)
                    {
                        USEDEBUG NSLog(@"DIV 19 %d", i);
                    glActiveTextureARB(GL_TEXTURE0_ARB);
   
                    // texture coord 0
                    glClientActiveTextureARB(GL_TEXTURE0_ARB); // program texcoord unit 0
                    glTexCoordPointer(2, GL_FLOAT, 0, texture_uv);
                    glEnableClientState(GL_TEXTURE_COORD_ARRAY); // enable array data to shader
                    USEDEBUG NSLog(@"DIV 20 %d", i);
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
                    
                    USEDEBUG NSLog(@"DIV 21 %d", i);
                    glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
                   
                    USEDEBUG NSLog(@"DIV 22 %d", i);
                    
                    if (showDetail)
                    {
                        glActiveTextureARB(GL_TEXTURE1_ARB);
                        glPopMatrix();
                        glMatrixMode(GL_MODELVIEW);
                        
                        glClientActiveTextureARB(GL_TEXTURE1_ARB);
                        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                    }
                    USEDEBUG NSLog(@"DIV 23 %d", i);
                    glClientActiveTextureARB(GL_TEXTURE0_ARB);
                    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                    
                    glActiveTextureARB(GL_TEXTURE2_ARB);
                    glBindTexture(GL_TEXTURE_2D, 0);
                    glDisable(GL_TEXTURE_2D);
                    USEDEBUG NSLog(@"DIV 24 %d", i);
                    glActiveTextureARB(GL_TEXTURE1_ARB);
                    glBindTexture(GL_TEXTURE_2D, 0);
                    glDisable(GL_TEXTURE_2D);
                    USEDEBUG NSLog(@"DIV 25 %d", i);
                    glActiveTextureARB(GL_TEXTURE0_ARB);
                    glBindTexture(GL_TEXTURE_2D, 0);
                    glDisable(GL_TEXTURE_2D);
                    glDisable(GL_BLEND);
                        USEDEBUG NSLog(@"DIV 26 %d", i);
                        
                    }
                    else
                    {
                    //PC Friendly VBO rendering
                    
                    /* GL Texture stuff goes hur */
                    if (currentPart.shaderIndex != -1)
                    {
                        [[parent _texManager] activateTextureOfIdent:currentPart.shaderBitmapIndex subImage:0 useAlphas:useAlphas];
                    }
                    USEDEBUG NSLog(@"DIV 27 %d", i);
                    
                    glTexCoordPointer(2, GL_FLOAT, 0, texture_uv);//&currentPart.shader->read_maps[g].texture_uv);
                    glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
                    USEDEBUG NSLog(@"DIV 28 %d", i);
                    }
                    
                    //glEnable(GL_DEPTH_TEST);
                    glDisable(GL_ALPHA_TEST);
                    
                    USEDEBUG NSLog(@"DIV 29 %d", i);
                    glDisable(GL_TEXTURE_2D);
                    glDisable(GL_BLEND);
                    
                    
                    USEDEBUG NSLog(@"DIV 30 %d", i);

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
                        glVertexPointer(3, GL_FLOAT, 0, vertex_array);
                        
                        //glDisable(GL_DEPTH_TEST);
                        
                        [[parent _texManager] activateTextureAndLightmap:currentPart.baseMapIndex lightmap:currentPart.detailMapIndex secondary:0 subImage:0 isAlphaType:YES];
                        
                        glActiveTextureARB(GL_TEXTURE1_ARB);
                        glDisable(GL_TEXTURE_2D);
                        
                        glActiveTextureARB(GL_TEXTURE0_ARB);
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

USEDEBUG NSLog(@"DIV 31 %d", i);
                    if (useNewRenderer() != 2)
                    {
                        glDisable(GL_BLEND);
                    }
                    
                }
                else if (currentPart.shaderIndex != -1)
                {
                    USEDEBUG NSLog(@"DIV 32 %d", i);
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
                    
                    glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
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
                    glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
                    
                    }
                    
                }
                
                
                currentIndex+=currentPart.indexPointer.count+2;
            }
        }
        
        

        return;

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
                    glTexCoord2f(tempVector->u * u_scale, tempVector->v * v_scale);
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
