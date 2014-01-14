//
//  ModelTag.m
//  swordedit
//
//  Created by sword on 5/11/08.
//

#import "ModelTag.h"
#import "Geometry.h"
#import "Camera.h"
#import "TextureManager.h"
#import "RenderView.h"

CVector3 AddTwoVectors(CVector3 v1, CVector3 v2);
CVector3 SubtractTwoVectors(CVector3 v1, CVector3 v2);
CVector3 MultiplyTwoVectors(CVector3 v1, CVector3 v2);
CVector3 DivideTwoVectors(CVector3 v1, CVector3 v2);
CVector3 Cross(CVector3 vVector1, CVector3 vVector2);
float Magnitude(CVector3 vNormal);
CVector3 Normalize(CVector3 vVector);
CVector3 Cross(CVector3 vVector1, CVector3 vVector2);
CVector3 NewCVector3(float x,float y,float z);

@implementation ModelTag
- (id)initWithMapFile:(HaloMap *)map texManager:(TextureManager *)texManager
{
    return [self initWithMapFile:map texManager:texManager usingData:nil];
}
- (id)initWithMapFile:(HaloMap *)map texManager:(TextureManager *)texManager usingData:(NSData*)data
{
    if (!data)
        self = [super initWithDataFromFile:map];
    else
        self = [super initWithData:data withMapfile:map];
    
	if (self != nil)
	{
		int i, x, j, currentOffset;
		Geometry *tmpGeo;
		
		_mapfile = [map retain];
		_texManager = [texManager retain];
		
		[_mapfile seekToAddress:resolvedOffset + 48];
		[_mapfile readFloat:&u_scale];
		[_mapfile readFloat:&v_scale];
		[_mapfile skipBytes:140];
		
		regionRef = [_mapfile readReflexive];
		reflexive geometryRef = [_mapfile readReflexive];
		reflexive shaderRef = [_mapfile readReflexive];
		[_mapfile seekToAddress:regionRef.offset];
		
		numRegions = regionRef.chunkcount;
		
        BOOL skip = NO;
        if (skip)
        {
            numRegions = 0;
            regionRef.chunkcount = 0;
        }
        
		regions = (MODEL_REGION *)malloc(regionRef.chunkcount * sizeof(MODEL_REGION));
		for (i = 0; i < regionRef.chunkcount; i++)
		{
			[_mapfile readBlockOfData:&regions[i].Name size_of_buffer:64];
			
			regions[i].Permutations = [_mapfile readReflexive];
			currentOffset = [_mapfile currentOffset];
			
			regions[i].modPermutations = (MODEL_REGION_PERMUTATION *)malloc(regions[i].Permutations.chunkcount * sizeof(MODEL_REGION_PERMUTATION));
            [_mapfile seekToAddress:regions[i].Permutations.offset];
			for (x = 0; x < regions[i].Permutations.chunkcount; x++)
			{
				[_mapfile readBlockOfData:regions[i].modPermutations[x].Name size_of_buffer:32];
				[_mapfile readBlockOfData:regions[i].modPermutations[x].Flags size_of_buffer:32];
				for (j = 0; j < 5; j++)
                {
					[_mapfile readShort:&regions[i].modPermutations[x].LOD_MeshIndex[j]];
                    //CSLog(@"%@ %d %d %d %d",  [[NSString alloc] initWithCString:regions[i].modPermutations[x].Name  encoding:NSMacOSRomanStringEncoding], i,x, j, (short)regions[i].modPermutations[x].LOD_MeshIndex[j]);
                }
				[_mapfile readBlockOfData:&regions[i].modPermutations[x].Reserved size_of_buffer:14];
			}
			[_mapfile seekToAddress:currentOffset];
		}
        
		/* -sword */
		
		[_mapfile seekToAddress:geometryRef.offset];
		
        if (skip)
        {
            geometryRef.chunkcount = 0;
        }
        
        
		subModels = [[NSMutableArray alloc] initWithCapacity:geometryRef.chunkcount];
		
        //CSLog(@"Geometry: %ld", geometryRef.chunkcount);
      
		for (i = 0; i < geometryRef.chunkcount; i++)
		{
            //CSLog(@"Building geometry chunk %d", i);
			[_mapfile seekToAddress:(geometryRef.offset + (i * 48))];
            
			tmpGeo = [[Geometry alloc] initWithMap:_mapfile parent:self];
            
            if (tmpGeo)
			[subModels addObject:tmpGeo];
            
			//[tmpGeo release]; //LEAK?
		}
		
		[_mapfile seekToAddress:shaderRef.offset];
		
        if (skip)
        {
            shaderRef.chunkcount= 0;
        }

		shaders = [[NSMutableArray alloc] initWithCapacity:shaderRef.chunkcount];
		shaderTypes = [[NSMutableArray alloc] initWithCapacity:shaderRef.chunkcount];
		
		for (i = 0; i < shaderRef.chunkcount; i++)
		{
            TAG_REFERENCE ref = [_mapfile readReference];
			
            #ifdef __DEBUG__
            CSLog(@"ADDING SHADER: %@ 0x%lx", [[NSString alloc] initWithCString:ref.tag length:4], ref.TagId);
#endif
            
            [shaderTypes addObject:[[NSString alloc] initWithCString:ref.tag length:4]];
            [shaders addObject:[NSNumber numberWithLong:ref.TagId]];
            
            
			[_mapfile skipBytes:16];
		}
	}
	return self;
}
- (void)dealloc
{
	int i;
	[_mapfile release];
	
	[_texManager release];
	
	for (i = 0; i < regionRef.chunkcount; i++)
		free(regions[i].modPermutations);
	
	free(regions);
	free(bb);
	
	[subModels removeAllObjects];
	[shaders removeAllObjects];
	[shaderTypes removeAllObjects];
    
	[subModels release];
	[shaders release];
    [shaderTypes release];
	
	[super dealloc];
}
- (void)releaseGeometryObjects
{
	[subModels makeObjectsPerformSelector:@selector(destroy)];
}
- (void)determineBoundingBox
{
	BOUNDING_BOX b;
	int i, x;
	if (bb == NULL)
	{
		bb = malloc(sizeof(BOUNDING_BOX));
		bb->min[0] = 50000;
		bb->min[1] = 50000;
		bb->min[2] = 50000;
		bb->max[0] = -50000;
		bb->max[1] = -50000;
		bb->max[2] = -50000;
        
		for (x = 0; x < [subModels count]; x++)
		{
			b = [(Geometry *)[subModels objectAtIndex:x] determineBoundingBox];
			for (i = 0; i < 3; i++)
			{
				if (b.min[i] < bb->min[i])
					bb->min[i] = b.min[i];
				if (b.max[i] > bb->max[i])
					bb->max[i] = b.max[i];
			}
		}
        
    }
    
	
}
- (BOUNDING_BOX *)bounding_box
{
	return bb;
}
- (float)u_scale
{
	return u_scale;
}
- (float)v_scale
{
	return v_scale;
}
- (int)numRegions
{
	return (int)numRegions;
}

-(void)generateImage:(NSString*)filename
{
    //Set up an OpenGL context.
    const int width = 512;
    const int height = 512;
    
    GLuint color;
    GLuint depth;
    GLuint fbo;
    
    glGenTextures(1, &color);
    glBindTexture(GL_TEXTURE_2D, color);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_BGRA, GL_UNSIGNED_BYTE, NULL);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    glGenRenderbuffers(1, &depth);
    glBindRenderbuffer(GL_RENDERBUFFER, depth);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, width, height);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    
    glGenFramebuffers(1, &fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, color, 0);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depth);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);

    
    

	
    
    glLoadIdentity();
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glClearColor(237/255.0,237/255.0,237/255.0,1.0);          // We'll Clear To The Color Of The Fog ( Modified )
    glDepthFunc(GL_LEQUAL);
    
    //Render things
    float *pt = malloc(sizeof(float)*6);
    pt[0]=-3.0;
    pt[1]=0.0;
    pt[2]=0.0;
    pt[3]=0.0;
    pt[4]=0.0;
    pt[5]=0.0;
    
    //Center the image
    if (bb == NULL)
		[self determineBoundingBox];
	
    float min = bb->min[2];
    float max = bb->max[2];
    
    float min2 = bb->min[1];
    float max2 = bb->max[1];
    
    float boxheight = max-min;
    float boxlength = max2-min2;
    
    pt[1]=-min2-boxlength/2.0;
    pt[2]=-min-boxheight/2.0;
    
    if (boxlength > boxheight)
        pt[0]=-sin(45/180.0 * M_PI)*boxlength*2.5;
    else
        pt[0]=-sin(45/180.0 * M_PI)*boxheight*2.5;
    
    
    glViewport(0,0,width,height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective(45.0f,
                   (width / height),
                   0.1f,
                   4000.0f);
	glMatrixMode(GL_MODELVIEW);
    
    CVector3 vPosition	= NewCVector3(0.0f, 0.0f, 0.0f);
	CVector3 vView		= NewCVector3(-boxheight, 0.0f, 0.0f);
	CVector3 vUpVector	= NewCVector3(0.0f, 0.0f, -1.0f);
    
    gluLookAt(vPosition.x, vPosition.y, vPosition.z,
			  vView.x,	 vView.y,     vView.z,
			  vUpVector.x, vUpVector.y, vUpVector.z);
    
    
    GLfloat fogColor[4];     // Fog Color
    fogColor[0] = 1.0f;
    fogColor[1] = 1.0f;
    fogColor[2] = 1.0f;
    fogColor[3] = 1.0f;
    
    if (useNewRenderer() == 3)
    {
        
        fogColor[0] = 0.5f;
        fogColor[1] = 0.5f;
        fogColor[2] = 0.5f;
        
    }// Fog Color
    
    glFogi(GL_FOG_MODE, GL_LINEAR);        // Fog Mode
    glFogfv(GL_FOG_COLOR, fogColor);            // Set Fog Color
    glFogf(GL_FOG_DENSITY, 0.5f);              // How Dense Will The Fog Be
    glHint(GL_FOG_HINT, GL_NICEST);          // Fog Hint Value
    glFogf(GL_FOG_START, 0.3f);             // Fog Start Depth
    glFogf(GL_FOG_END, 200.0f);               // Fog End Depth
    
    glEnable(GL_FOG);
    glEnable(GL_MULTISAMPLE);
    glHint(GL_MULTISAMPLE_FILTER_HINT_NV, GL_NICEST);
    
    glEnable(GL_DEPTH_TEST);
    
    
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glColor4f(1.0f,1.0f,1.0f, 1.0f);
    
    [self drawAtPoint:pt lod:4 isSelected:NO useAlphas:YES];
    
    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_BLEND);
    
    
    void *imageData = malloc(width * height * 4);
    
    glBindTexture(GL_TEXTURE_2D, color);
    glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    NSBitmapImageRep *imgRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&imageData
                                                                       pixelsWide:width
                                                                       pixelsHigh:height
                                                                    bitsPerSample:8
                                                                  samplesPerPixel:4
                                                                         hasAlpha:true
                                                                         isPlanar:false
                                                                   colorSpaceName:NSDeviceRGBColorSpace
                                                                      bytesPerRow:0
                                                                     bitsPerPixel:0];
 
    
    [[imgRep TIFFRepresentation] writeToFile:filename atomically:YES];
    

    glBindTexture(GL_TEXTURE_2D, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);

    free(imageData);
    

}


-(void)disableOcclusion
{
    disableOcclusion = YES;
}

- (void)drawAtPoint:(float *)point lod:(int)lod isSelected:(BOOL)isSelected useAlphas:(BOOL)useAlphas withCollision:(CollisionTag*)tag
{
	int i, x;
	if (bb == NULL)
		[self determineBoundingBox];
	
    if (!disableOcclusion)
    {
        id render_view = [[[NSDocumentController sharedDocumentController] currentDocument] renderView];
        float *camera_position = [render_view getCameraPos];
        float *camera_view = [render_view getCameraView];
        
        float ppvx = camera_view[0] - camera_position[0];
        float ppvy = camera_view[1] - camera_position[1];
        float ppvz = camera_view[2] - camera_position[2];
        
        float ax = point[0];
        float ay = point[1];
        float az = point[2];
        
        GLfloat px = camera_position[0]; //camera x
        GLfloat py = camera_position[1]; //camera y
        GLfloat pz = camera_position[2]; //camera z
        
        float back = -0.5*tan((135/180.0) * M_PI);
        GLfloat bx = px - back*ppvx;
        GLfloat by = py - back*ppvy;
        GLfloat bz = pz - back*ppvz;
        
        float d = ppvx*px + ppvy*py + ppvz*pz;
        
        float ux = ax-bx;
        float uy = ay-by;
        float uz = az-bz;
        
        float mue = (ppvx*bx + ppvy*by + ppvz*bz - d)/(-(ppvx*ux+ppvy*uy+ppvz*uz));
        if (mue <= 0)
        {
            return;
        }
    }
    
	glPushMatrix();
    glTranslatef(point[0],point[1],point[2]);
    glRotatef(point[5] * (57.3), 1.0, 0.0, 0.0);
    glRotatef(-point[4] * (57.3), 0.0, 1.0, 0.0);
    glRotatef(point[3] * (57.3), 0.0, 0.0, 1.0);
    //glScalef(3.0, 3.0, 3.0);
    
    //--------------------------------
    //The copyright for the following code is owned by Samuel Colbran (Samuco).
    //The copyright for other smaller segments that are not identified by these comments are also owned by Samuel Colbran (Samuco).
    //--------------------------------
    if (isSelected)
    {
        //Turn off all the textures
        glActiveTexture(GL_TEXTURE0);
        glDisable(GL_TEXTURE_2D);
        glActiveTexture(GL_TEXTURE1);
        glDisable(GL_TEXTURE_2D);
        glActiveTexture(GL_TEXTURE2);
        glDisable(GL_TEXTURE_2D);
        glActiveTexture(GL_TEXTURE3);
        glDisable(GL_TEXTURE_2D);
        
        if (TRUE)//useNewRenderer())
        {
            glDisableClientState(GL_VERTEX_ARRAY);
            glDisableClientState(GL_TEXTURE_COORD_ARRAY);
            
            glDisable(GL_TEXTURE_2D);
            glDisable(GL_BLEND);
        }
        
        glColor4f(1.0f,1.0f,0.0f,1.0f);
        if (renderV)
        {
                if (![renderV isAboveGround:point])
                    glColor4f(1.0f,0.0f,0.0f,0.2f);
                else
                    glColor4f(1.0f,1.0f,0.0f,1.0f);
            
        }
        else
            glColor4f(1.0f,1.0f,0.0f,1.0f);

        [self drawBoundingBox];
        if (renderV)
            glColor4f(1.0f,1.0f,0.0f,1.0f);
        
        if (TRUE)//useNewRenderer())
        {
            glEnableClientState(GL_VERTEX_ARRAY);
            glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        }
    }

    //glUniform3f(global_positionData, point[0],point[1],point[2]);
    //glUniform3f(global_rotationData, point[3],point[4],point[5]);
    
    int index;
    for (i = 0; i < numRegions; i++)
    {
        for (x = 0; x < regions[i].Permutations.chunkcount; x++)
        {
            int g = regions[i].modPermutations[x].Flags[0];
            if ((g & 0xFF) != 1)
            {
                index = regions[i].modPermutations[x].LOD_MeshIndex[lod];
                if (index>=[subModels count])
                {
                    continue;
                }
                
                id model = [subModels objectAtIndex:index];
                if (model)
                    [model drawIntoView:useAlphas];
            }
        }
    }
    glBindVertexArrayAPPLE(0);
	glPopMatrix();
    
    if (isSelected || renderCollisionModels)
    {
        //Again
        //Turn off all the textures
        glActiveTexture(GL_TEXTURE0);
        glDisable(GL_TEXTURE_2D);
        glActiveTexture(GL_TEXTURE1);
        glDisable(GL_TEXTURE_2D);
        glActiveTexture(GL_TEXTURE2);
        glDisable(GL_TEXTURE_2D);
        glActiveTexture(GL_TEXTURE3);
        glDisable(GL_TEXTURE_2D);
        
        if (tag && [tag respondsToSelector:@selector(drawAtPoint:withModel:)])
            [tag drawAtPoint:point withModel:self];
    }
}

- (void)loadAllBitmaps
{
    //if (!loaded)
        [subModels makeObjectsPerformSelector:@selector(loadBitmaps)];
    //loaded=TRUE;
}
- (int32_t)shaderIdentForIndex:(int)index
{
	return [[shaders objectAtIndex:index] longValue];
}
-(NSString*)shaderTypeForIndex:(int)index
{
    return [shaderTypes objectAtIndex:index];
}
- (void)drawBoundingBox
{
    glUseProgram(0);
    glFlush();
    glDisable(GL_TEXTURE_2D);
    glLineWidth(1.0f);
    glColor4f(1.0f,1.0f,0.0f, 1.0f);
	glBegin(GL_LINES);
	    glVertex3f(bb->max[0],bb->max[1],bb->max[2]);
	    glVertex3f(bb->max[0],bb->max[1],bb->min[2]);
	    
	    glVertex3f(bb->max[0],bb->max[1],bb->max[2]);
	    glVertex3f(bb->max[0],bb->min[1],bb->max[2]);
	    
	    glVertex3f(bb->max[0],bb->max[1],bb->max[2]);
	    glVertex3f(bb->min[0],bb->max[1],bb->max[2]);
	    
	    glVertex3f(bb->max[0],bb->max[1],bb->min[2]);
	    glVertex3f(bb->max[0],bb->min[1],bb->min[2]);
	    
	    glVertex3f(bb->max[0],bb->max[1],bb->min[2]);
	    glVertex3f(bb->min[0],bb->max[1],bb->min[2]);
	    
	    glVertex3f(bb->max[0],bb->min[1],bb->max[2]);
	    glVertex3f(bb->max[0],bb->min[1],bb->min[2]);
	    
	    glVertex3f(bb->max[0],bb->min[1],bb->max[2]);
	    glVertex3f(bb->min[0],bb->min[1],bb->max[2]);
	    
	    glVertex3f(bb->min[0],bb->max[1],bb->max[2]);
	    glVertex3f(bb->min[0],bb->min[1],bb->max[2]);
	    
	    glVertex3f(bb->min[0],bb->max[1],bb->max[2]);
	    glVertex3f(bb->min[0],bb->max[1],bb->min[2]);
	    
	    glVertex3f(bb->min[0],bb->min[1],bb->max[2]);
	    glVertex3f(bb->min[0],bb->min[1],bb->min[2]);
	    
	    glVertex3f(bb->min[0],bb->min[1],bb->min[2]);
	    glVertex3f(bb->min[0],bb->max[1],bb->min[2]);
	    
	    glVertex3f(bb->min[0],bb->min[1],bb->min[2]);
	    glVertex3f(bb->max[0],bb->min[1],bb->min[2]);
		
		// Now to try some other stuffs! Bwahaha!
		[self drawAxes:TRUE];
	glEnd();
    
    if (!legacyMode)
        activateNormalProgram();
}
- (void)drawAxes:(BOOL)withPointerArrow
{
	// Draw 3 dimensional axes.
	glLineWidth(2.0f);
    // x
    glColor3f(1.0f,1.0f,1.0f);
    glVertex3f(-50.0f,0.0f,0.0f);
    glVertex3f(50.0f,0.0f,0.0f);
    // y
    glColor3f(1.0f,1.0f,1.0f);
    glVertex3f(0.0f,-50.0f,0.0f);
    glVertex3f(0.0f,50.0f,0.0f);
    // z
    glColor3f(1.0f,1.0f,1.0f);
    glVertex3f(0.0f,0.0f,-50.0f);
    glVertex3f(0.0f,0.0f,50.0f);
    
    if (withPointerArrow)
    {
        // pointer arrow
        glColor3f(1.0f,1.0f,1.0f);
        glVertex3f(0.5f + bb->max[0],0.0f,0.0f);
        glVertex3f(0.3f + bb->max[0],0.2f,0.0f);
        glVertex3f(0.5f + bb->max [0],0.0f,0.0f);
        glVertex3f(0.3f + bb->max[0],-0.2f,0.0f);
    }
}
- (TextureManager *)_texManager
{
	return _texManager;
}
- (void)renderPartyTriangle
{
    #ifdef IMMEDIATE_MODE
	glBegin( GL_TRIANGLES );              // Draw a triangle
		glColor3f( 1.0f, 0.0f, 0.0f );        // Set color to red
		glVertex3f(  0.0f,  1.0f, 0.0f );     // Top of front
		glColor3f( 0.0f, 1.0f, 0.0f );        // Set color to green
		glVertex3f( -1.0f, -1.0f, 1.0f );     // Bottom left of front
		glColor3f( 0.0f, 0.0f, 1.0f );        // Set color to blue
		glVertex3f(  1.0f, -1.0f, 1.0f );     // Bottom right of front
			
		glColor3f( 1.0f, 0.0f, 0.0f );        // Red
		glVertex3f( 0.0f, 1.0f, 0.0f );       // Top of right side
		glColor3f( 0.0f, 0.0f, 1.0f );        // Blue
		glVertex3f( 1.0f, -1.0f, 1.0f );      // Left of right side
		glColor3f( 0.0f, 1.0f, 0.0f );        // Green
		glVertex3f( 1.0f, -1.0f, -1.0f );     // Right of right side

		glColor3f( 1.0f, 0.0f, 0.0f );        // Red
		glVertex3f( 0.0f, 1.0f, 0.0f );       // Top of back side
		glColor3f( 0.0f, 1.0f, 0.0f );        // Green
		glVertex3f( 1.0f, -1.0f, -1.0f );     // Left of back side
		glColor3f( 0.0f, 0.0f, 1.0f );        // Blue
		glVertex3f( -1.0f, -1.0f, -1.0f );    // Right of back side

		glColor3f( 1.0f, 0.0f, 0.0f );        // Red
		glVertex3f( 0.0f, 1.0f, 0.0f );       // Top of left side
		glColor3f( 0.0f, 0.0f, 1.0f );        // Blue
		glVertex3f( -1.0f, -1.0f, -1.0f );    // Left of left side
		glColor3f( 0.0f, 1.0f, 0.0f );        // Green
		glVertex3f( -1.0f, -1.0f, 1.0f );     // Right of left side
	glEnd();  // Done with triangle
#endif
    
}
@synthesize _mapfile;
@synthesize subModels;
@synthesize shaders;
@synthesize u_scale;
@synthesize v_scale;
@synthesize regions;
@synthesize bb;
@synthesize moving;
@synthesize selected;
@end
