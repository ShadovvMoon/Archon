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
			
            NSString *type = [parent shaderTypeForIndex:parts[x].shaderIndex];
           // NSLog([parent tagName]);
            //NSLog(type);
            
            if ([type isEqualToString:@"osos"])
            {
                soso *shader = (soso *)malloc(sizeof(soso));
                [_mapfile loadSOSO:shader forID:[parent shaderIdentForIndex:parts[x].shaderIndex]];
                
                parts[x].baseMapIndex = shader->baseMap.TagId;
                parts[x].detailMapIndex = shader->detailMap.TagId;
                parts[x].detailMapScale = shader->detailScale;
                parts[x].shaderBitmapIndex = shader->baseMap.TagId;
                
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
            else if ([type isEqualToString:@"xecs"])
            {
               // NSLog(@"Loading xecs");
                
                scex *shader = (scex *)malloc(sizeof(scex));
                [_mapfile loadSCEX:shader forID:[parent shaderIdentForIndex:parts[x].shaderIndex]];
                
                parts[x].scexshader = shader;
                parts[x].hasShader = 4;
                parts[x].baseMapIndex = -1;
                //NSLog(@"Loading parts %d", (parts[x].scexshader->maps.chunkcount + ((scex*)parts[x].scexshader)->maps2.chunkcount));
                
                int g;
                for (g=0; g < (parts[x].scexshader->maps.chunkcount + ((scex*)parts[x].scexshader)->maps2.chunkcount); g++)
                {
                    //NSLog(@"%d %ld", g, parts[x].scexshader->read_maps[g].bitm.TagId);
                    [[parent _texManager] loadTextureOfIdent:parts[x].scexshader->read_maps[g].bitm.TagId subImage:0];
                }
                

                parts[x].lengthOfBitmapArray = -1;
                
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
                
                [[parent _texManager] loadTextureOfIdent:parts[x].baseMapIndex subImage:0];
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
    
    //NSLog(@"Initialing drawing");
    
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
        glNormalPointer(GL_FLOAT, 0, normals);
        
        int currentIndex = 0;
        for (i = 0; i < partsref.chunkcount; i++)
        {
            currentPart = parts[i];
            if (currentPart.indexPointer.rawPointer[0] == currentPart.indexPointer.rawPointer[1])
            {
                
                
                currentPart.lengthOfBitmapArray = -1;
                
                if ((currentPart.hasShader==3 || currentPart.hasShader == 4) && useNewRenderer() == 2)
                {
                 
                    glEnable(GL_BLEND);
                    glBlendFunc(GL_DST_ALPHA,GL_ONE_MINUS_DST_ALPHA);
                    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
                    

                    //NSLog(@"1");
                    int maps;
                    if (currentPart.hasShader == 4)
                    {
                        maps = currentPart.scexshader->maps.chunkcount + currentPart.scexshader->maps2.chunkcount;
                    }
                    else
                    {
                        maps = currentPart.shader->maps.chunkcount;
                    }
                    
                    //glColor4f(1.0, 1.0, 1.0, 1.0);
                    int g;
                    
                    glDepthFunc(GL_LEQUAL);
                    
          
                    
                    if ([parent _texManager]._textures)
                    {
                        
                        for (g=0; g < maps; g++)
                        {
        
                            //scexshader
                            int texIndex;
                            
                            if (currentPart.hasShader == 4)
                                texIndex = [[[parent _texManager]._textureLookupByID objectForKey:[NSNumber numberWithLong:currentPart.scexshader->read_maps[g].bitm.TagId]] intValue];
                            else
                                texIndex = [[[parent _texManager]._textureLookupByID objectForKey:[NSNumber numberWithLong:currentPart.shader->read_maps[g].bitm.TagId]] intValue];
                            
                            
                            glActiveTextureARB(g);
                            glEnable(GL_TEXTURE_2D);
                            glBindTexture(GL_TEXTURE_2D, [parent _texManager]._glTextureTable[texIndex][0]);
                            glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT);
                            glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT);
                            glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
                            glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_LINEAR);
                            
                            if (currentPart.hasShader == 4)
                            {
                                if (currentPart.scexshader->read_maps[g].colorFunction == 0)
                                    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
                                else if (currentPart.scexshader->read_maps[g].colorFunction == 4)
                                    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_ADD);
                                else
                                    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
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
                            
                            
                            glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
                        }
                    
                    
                        for (g=0; g < maps; g++)
                        {
                            glClientActiveTextureARB(g);
                            glTexCoordPointer(2, GL_FLOAT, 0, texture_uv);//&currentPart.shader->read_maps[g].texture_uv);
                            glEnableClientState(GL_TEXTURE_COORD_ARRAY); // enable array data to shader
                            
                            
                            
                            //uscale, vscale
                        }
                        
                        if (currentPart.hasShader == 4)
                        {
                            glActiveTextureARB(0);
                            glMatrixMode(GL_TEXTURE);
                            glPushMatrix();
                            glScalef(currentPart.scexshader->read_maps[maps-1].uscale,currentPart.scexshader->read_maps[maps-1].vscale, 0.0);
                        }
                        else if (currentPart.hasShader == 3)
                        {
                            glActiveTextureARB(0);
                            glMatrixMode(GL_TEXTURE);
                            glPushMatrix();
                            glScalef(currentPart.shader->read_maps[0].uscale,currentPart.shader->read_maps[0].vscale, 0.0);
                        }
                        
                        if (currentIndex+currentPart.indexPointer.count+2 <= indexCount_R)
                        {
                            glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
                        }
                        
                        if (currentPart.hasShader == 4)
                        {
                            glActiveTextureARB(0);
                            glPopMatrix();
                            glMatrixMode(GL_MODELVIEW);
                        }
                        else if (currentPart.hasShader == 3)
                        {
                            glActiveTextureARB(0);
                            glPopMatrix();
                            glMatrixMode(GL_MODELVIEW);
                        }
                        
                        for (g=0; g < maps; g++)
                        {
                            
                            
                            glClientActiveTextureARB(g);
                            glBindTexture(GL_TEXTURE_2D, 0);
                            glDisable(GL_TEXTURE_2D);
                        }
                    }
     
                    glDisable(GL_ALPHA_TEST);
                    //currentPart.shader;

                    //int g;
                    //for (g=0; g < parts[x].shader->maps.chunkcount; g++)
                    //{
                    //    [[parent _texManager] loadTextureOfIdent:parts[x].shader->read_maps[g].bitm.TagId subImage:0];
                    //}
                    
                }
                else if (currentPart.baseMapIndex != -1 && useNewRenderer() == 2) //Candlelight
                {
                            //glEnable(GL_BLEND);
                    
             
                    
                            
                    bool showDetail = true;
                    
                    
                    glEnable(GL_BLEND);
                    glBlendFunc(GL_DST_ALPHA,GL_ONE_MINUS_DST_ALPHA);
                    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
                    
                    
                    //glPushMatrix();
                    [[parent _texManager] activateTextureAndLightmap:currentPart.baseMapIndex lightmap:currentPart.detailMapIndex secondary:0 subImage:0];
                    
                    //glColor4f(1.0, 1.0, 1.0, 1.5);
                    
                    
                    
                    glActiveTextureARB(GL_TEXTURE0_ARB);
   
                    
                    // texture coord 0
                    glClientActiveTextureARB(GL_TEXTURE0_ARB); // program texcoord unit 0
                    glTexCoordPointer(2, GL_FLOAT, 0, texture_uv);
                    glEnableClientState(GL_TEXTURE_COORD_ARRAY); // enable array data to shader
                    
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
                    
                    
                    glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
                    
                    
                    if (showDetail)
                    {
                        glActiveTextureARB(GL_TEXTURE1_ARB);
                        glPopMatrix();
                        glMatrixMode(GL_MODELVIEW);
                        
                        glClientActiveTextureARB(GL_TEXTURE1_ARB);
                        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                    }
                    
                    glClientActiveTextureARB(GL_TEXTURE0_ARB);
                    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                    
                    glActiveTextureARB(GL_TEXTURE2_ARB);
                    glBindTexture(GL_TEXTURE_2D, 0);
                    glDisable(GL_TEXTURE_2D);
                    
                    glActiveTextureARB(GL_TEXTURE1_ARB);
                    glBindTexture(GL_TEXTURE_2D, 0);
                    glDisable(GL_TEXTURE_2D);
                    
                    glActiveTextureARB(GL_TEXTURE0_ARB);
                    glBindTexture(GL_TEXTURE_2D, 0);
                    glDisable(GL_TEXTURE_2D);
                    glDisable(GL_BLEND);
                    
                    
                }
                else if (currentPart.shaderIndex != -1)
                {
      
                    if (useNewRenderer() == 2)
                        continue;
                    
                    [[parent _texManager] activateTextureOfIdent:currentPart.shaderBitmapIndex subImage:0 useAlphas:true ];
                    
                    //glColor4f(1.0, 1.0, 1.0, 0.5);
                    glClientActiveTextureARB(GL_TEXTURE0_ARB); // program texcoord unit 0
                    glTexCoordPointer(2, GL_FLOAT, 0, texture_uv);
                    glEnableClientState(GL_TEXTURE_COORD_ARRAY); // enable array data to shader
                    
                    glDrawElements(GL_TRIANGLE_STRIP, currentPart.indexPointer.count+2, GL_UNSIGNED_SHORT, &index_array[currentIndex]);
                    //glColor4f(1.0, 1.0, 1.0, 1.5);
                    
                    glClientActiveTextureARB(GL_TEXTURE0_ARB);
                    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                    
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
