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

#import <OpenGL/OpenGL.h>


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
			[_mapfile readBlockOfData:currentPart->junk4 size_of_buffer:4];
			[_mapfile readShort:&currentPart->shaderIndex];
			
			[_mapfile readBlockOfData:&currentPart->junk size_of_buffer:66];// <-- This little baby was causing a buffer overrun on PPC macs, so I'm just skipping it
			//[_mapfile skipBytes:66];
			
			[_mapfile readLong:&currentPart->indexPointer.count];
			[_mapfile readLong:&currentPart->indexPointer.rawPointer[0]];
			[_mapfile readLong:&currentPart->indexPointer.rawPointer[1]];
			
			#ifdef __DEBUG__
			if (currentPart->indexPointer.rawPointer[1] != currentPart->indexPointer.rawPointer[0])
				NSLog(@"BadPartInt!"); // Whatever the hell that is
			#endif
				
			[_mapfile readBlockOfData:currentPart->junk2 size_of_buffer:4];
			
			[_mapfile readLong:&currentPart->vertPointer.count];
			[_mapfile readBlockOfData:currentPart->vertPointer.junk size_of_buffer:8];
			[_mapfile readLong:&currentPart->vertPointer.rawPointer];
			
			[_mapfile readBlockOfData:currentPart->junk3 size_of_buffer:28];
			
			endOfPart = [_mapfile currentOffset];
			
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
	int x;
	
	if (texturesLoaded)
	{
		return;
	}
	
	for (x = 0; x < partsref.chunkcount; x++)
	{
		
		int graphics_insane = 0;
		if (graphics_insane)
		{
			
			NSMutableArray *bitmaps = [_mapfile bitmsTagForShaderId:[parent shaderIdentForIndex:parts[x].shaderIndex]];
			if ([bitmaps count] > 0)
			{
				parts[x].shaderBitmapIndex = [[bitmaps objectAtIndex:0] idOfTag];
				[[parent _texManager] loadTextureOfIdent:parts[x].shaderBitmapIndex subImage:0];
				
				int i;
				for (i=0;i<[bitmaps count]; i++)
				{
					//[[parent _texManager] loadTextureOfIdent:[[bitmaps objectAtIndex:i] idOfTag] subImage:0];
				}
			}
			else
			{
				parts[x].shaderBitmapIndex = nil;
			}
		}
		else
		{
		
			parts[x].shaderBitmapIndex = [[_mapfile bitmTagForShaderId:[parent shaderIdentForIndex:parts[x].shaderIndex]] idOfTag];
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
    
    NSLog(@"Initialing drawing");
    
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
    indexCount_R = ind;
    NSLog(@"Complete");
    
    
    
}

- (void)drawIntoView:(BOOL)useAlphas
{
    useAlphas = YES;
    
	int i, x;
	part currentPart;
	float u_scale, v_scale;
			
	u_scale = [parent u_scale];
	v_scale = [parent v_scale];
	
    if (partsref.chunkcount <= 0)
        return;
    
    //--------------------------------
    //The copyright for the following code is owned by Samuel Colbran (Samuco).
    //The copyright for other smaller segments that are not identified by these comments are also owned by Samuel Colbran (Samuco).
    //--------------------------------
    
    
    if (useNewRenderer())
    {
       
        glVertexPointer(3, GL_FLOAT, 0, vertex_array);
        glTexCoordPointer(2, GL_FLOAT, 0, texture_uv);
        //glNormalPointer(GL_FLOAT, 0, normals);
        
        int currentIndex = 0;
        for (i = 0; i < partsref.chunkcount; i++)
        {
            currentPart = parts[i];
            if (currentPart.indexPointer.rawPointer[0] == currentPart.indexPointer.rawPointer[1])
            {
                if (currentPart.shaderIndex != -1)
                {
                    [[parent _texManager] activateTextureOfIdent:currentPart.shaderBitmapIndex subImage:0 useAlphas:useAlphas];
                }
                
                if (currentIndex+currentPart.indexPointer.count+2 <= indexCount_R)
                {
                    glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
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
