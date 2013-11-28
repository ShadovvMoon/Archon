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
	if ((self = [super initWithDataFromFile:map]) != nil)
	{
		int i, x, j, currentOffset;
		long ID;
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
                    //NSLog(@"%@ %d %d %d %d",  [[NSString alloc] initWithCString:regions[i].modPermutations[x].Name  encoding:NSMacOSRomanStringEncoding], i,x, j, (short)regions[i].modPermutations[x].LOD_MeshIndex[j]);
                }
				[_mapfile readBlockOfData:&regions[i].modPermutations[x].Reserved size_of_buffer:14];
			}
			[_mapfile seekToAddress:currentOffset];
		}
		/* -sword */
		
		[_mapfile seekToAddress:geometryRef.offset];
		
		subModels = [[NSMutableArray alloc] initWithCapacity:geometryRef.chunkcount];
		
        //NSLog(@"Geometry: %ld", geometryRef.chunkcount);
		for (i = 0; i < geometryRef.chunkcount; i++)
		{
            //NSLog(@"Building geometry chunk %d", i);
			[_mapfile seekToAddress:(geometryRef.offset + (i * 48))];
			tmpGeo = [[Geometry alloc] initWithMap:_mapfile parent:self];
			[subModels addObject:tmpGeo];
			//[tmpGeo release]; //LEAK?
		}
		
		[_mapfile seekToAddress:shaderRef.offset];
		
		shaders = [[NSMutableArray alloc] initWithCapacity:shaderRef.chunkcount];
		shaderTypes = [[NSMutableArray alloc] initWithCapacity:shaderRef.chunkcount];
		
		for (i = 0; i < shaderRef.chunkcount; i++)
		{
            TAG_REFERENCE ref = [_mapfile readReference];
			
            //NSLog(@"ADDING SHADER: %@", [[NSString alloc] initWithCString:ref.tag length:4]);
            
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
    
    [self drawAtPoint:pt lod:4 isSelected:NO useAlphas:YES distance:0.0f];
    
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

- (void)drawAtPoint:(float *)point lod:(int)lod isSelected:(BOOL)isSelected useAlphas:(BOOL)useAlphas
{
    [self drawAtPoint:point lod:lod isSelected:isSelected useAlphas:useAlphas distance:0.0];
}


- (void)drawAtPoint:(float *)point lod:(int)lod isSelected:(BOOL)isSelected useAlphas:(BOOL)useAlphas distance:(float)dist
{
	int i, x;
	
    USEDEBUG NSLog(@"DAP 0");
    
	if (bb == NULL)
		[self determineBoundingBox];
	
    
    USEDEBUG NSLog(@"DAP 1");
	glPushMatrix();
    glTranslatef(point[0],point[1],point[2]);
    USEDEBUG NSLog(@"DAP 2");
    if (isSelected)
    {
        if (TRUE)//useNewRenderer())
        {
            glDisableClientState(GL_VERTEX_ARRAY);
            glDisableClientState(GL_TEXTURE_COORD_ARRAY);
            
            glDisable(GL_TEXTURE_2D);
            glDisable(GL_BLEND);
        }
        
        float lineLength = 1000.0f/2;
        
        glLineWidth(1.0f);
        glColor4f(5.0f,5.0f,5.0f, 1.0f);
        glBegin(GL_LINES);
        {
            glVertex3f(-lineLength,0.0f,0.0f);
            glVertex3f(lineLength,0.0f,0.0f);
            glVertex3f(0.0f,-lineLength,0.0f);
            glVertex3f(0.0f,lineLength,0.0f);
            glVertex3f(0.0f,0.0f,-lineLength);
            glVertex3f(0.0f,0.0f,lineLength);
        }
        glEnd();
        
        
        if (TRUE)//useNewRenderer())
        {
            glEnableClientState(GL_VERTEX_ARRAY);
            glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        }
        
    }
    USEDEBUG NSLog(@"DAP 3");
    
    /* Perform rotation */
    glRotatef(point[5] * (57.29577951), 1, 0, 0);
    glRotatef(-point[4] * (57.29577951), 0, 1, 0);
    glRotatef(point[3] * (57.29577951), 0, 0, 1);
    
    USEDEBUG NSLog(@"DAP 4");
    if (bb->max[2]-bb->min[2]<= 0.001)
    {
        glDisable(GL_TEXTURE_2D);
        glEnable(GL_BLEND);
        
        glColor4f(1.0f, 0.0f, 0.0f, 0.5f);
        
        GLUquadric *sphere=gluNewQuadric();
        gluQuadricDrawStyle( sphere, GLU_FILL);
        gluQuadricNormals( sphere, GLU_SMOOTH);
        gluQuadricOrientation( sphere, GLU_OUTSIDE);
        gluQuadricTexture( sphere, GL_TRUE);
        
        gluSphere(sphere,0.05f,10,10);
        gluDeleteQuadric ( sphere );
        
        glDisable(GL_BLEND);
        
        glColor3f(1.0f,1.0f,1.0f);
        glBegin(GL_LINES);
        {
            glVertex3f(0.5f,0.0f,0.0f);
            glVertex3f(0.3f,0.2f,0.0f);
            glVertex3f(0.5f,0.0f,0.0f);
            glVertex3f(0.3f,-0.2f,0.0f);
        }
        glEnd();
        
    }
    
    USEDEBUG NSLog(@"DAP 5");
    
    
    
    //--------------------------------
    //The copyright for the following code is owned by Samuel Colbran (Samuco).
    //The copyright for other smaller segments that are not identified by these comments are also owned by Samuel Colbran (Samuco).
    //--------------------------------
    USEDEBUG NSLog(@"DAP 6");
    if (isSelected)
    {
         if (TRUE)//useNewRenderer())
        {
            USEDEBUG NSLog(@"DAP 7");
            glDisableClientState(GL_VERTEX_ARRAY);
            glDisableClientState(GL_TEXTURE_COORD_ARRAY);
            
            glDisable(GL_TEXTURE_2D);
            glDisable(GL_BLEND);
            USEDEBUG NSLog(@"DAP 8");
        }
        
        glColor4f(1.0f,1.0f,0.0f,1.0f);
        USEDEBUG NSLog(@"DAP 9");
        if (renderV)
        {
                if (![renderV isAboveGround:point])
                    glColor4f(1.0f,0.0f,0.0f,0.2f);
                else
                    glColor4f(1.0f,1.0f,0.0f,1.0f);
            
        }
        else
            glColor4f(1.0f,1.0f,0.0f,1.0f);
        USEDEBUG NSLog(@"DAP 10");
        //isAboveGround
       
        [self drawBoundingBox];
        USEDEBUG NSLog(@"DAP 11");
        
        if (renderV)
            glColor4f(1.0f,1.0f,0.0f,1.0f);
        
        if (TRUE)//useNewRenderer())
        {
            glEnableClientState(GL_VERTEX_ARRAY);
            glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        }
        USEDEBUG NSLog(@"DAP 12");
        
        
    }
 
    USEDEBUG NSLog(@"DAP 13");
    int z;
    for (i = 0; i < numRegions; i++)
    {
        USEDEBUG NSLog(@"DAP 14 %d", i);
        for (x = 0; x < regions[i].Permutations.chunkcount; x++)
        {
            
            USEDEBUG NSLog(@"DAP 15 %d", x);
      
               // NSLog([NSString stringWithCString:regions[i].modPermutations[x].Name encoding:NSUTF8StringEncoding]);
            
            int g = regions[i].modPermutations[x].Flags[0];
            if ((g & 0xFF) == 1)
            {
                USEDEBUG NSLog(@"DAP 16 %d", x);
                //NSLog([NSString stringWithCString:regions[i].modPermutations[x].Name encoding:NSUTF8StringEncoding]);
                //continue;
            }
            else
            {
                USEDEBUG NSLog(@"DAP 17 %d", x);
                int index;
                //if (dist < 10.0)
                    index = regions[i].modPermutations[x].LOD_MeshIndex[4];
                //else
                //  index = regions[i].modPermutations[x].LOD_MeshIndex[0];
                
                USEDEBUG NSLog(@"DAP 18 %d", x);
                if (index>=[subModels count])
                {
                    continue;
                }
                USEDEBUG NSLog(@"DAP 19 %d", x);
                id model = [subModels objectAtIndex:index];
                if (model)
                {
                    USEDEBUG NSLog(@"DAP 20 %d", x);
    #ifdef fasterRendering
                    glBegin(GL_TRIANGLE_STRIP);
    #endif
                    USEDEBUG NSLog(@"DAP 21 %d", x);
                    [model drawIntoView:useAlphas distance:dist];
    #ifdef fasterRendering
                    glEnd();
                    USEDEBUG NSLog(@"DAP 22 %d", x);
    #endif
                }
                else
                {
                    NSLog(@"NO MODEL?");
                }
            }
            
        }
    }
    USEDEBUG NSLog(@"DAP 23");
    //END CODE
    
    glColor4f(1.0f,1.0f,1.0f, 1.0f);
    USEDEBUG NSLog(@"DAP 24");
	glPopMatrix();
    USEDEBUG NSLog(@"DAP 25");
}

- (void)loadAllBitmaps
{
    if (!loaded)
	[subModels makeObjectsPerformSelector:@selector(loadBitmaps)];
    loaded=TRUE;
}
- (long)shaderIdentForIndex:(int)index
{
	return [[shaders objectAtIndex:index] longValue];
}
-(NSString*)shaderTypeForIndex:(int)index
{
    return [shaderTypes objectAtIndex:index];
}
- (void)drawBoundingBox
{
    glFlush();
    glLineWidth(1.0f);
    //glColor4f(1.0f,1.0f,0.0f, 5.0f);
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
		//[self drawAxes:TRUE];
	glEnd();
   
}
- (void)drawAxes:(BOOL)withPointerArrow
{
	// Draw 3 dimensional axes.
	glLineWidth(2.0f);
		// x
		glColor3f(1.0f,0.0f,0.0f);
		glVertex3f(0.0f,0.0f,0.0f);
	    glVertex3f(50.0f,0.0f,0.0f);
		// y
		glColor3f(0.0f,1.0f,0.0f);
		glVertex3f(0.0f,0.0f,0.0f);
		glVertex3f(0.0f,50.0f,0.0f);
		// z
		glColor3f(0.0f,0.0f,1.0f);
		glVertex3f(0.0f,0.0f,0.0f);
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
    glEnd();
}
- (TextureManager *)_texManager
{
	return _texManager;
}
- (void)renderPartyTriangle
{
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

}
@synthesize _mapfile;
@synthesize _texManager;
@synthesize subModels;
@synthesize shaders;
@synthesize u_scale;
@synthesize v_scale;
@synthesize regions;
@synthesize bb;
@synthesize moving;
@synthesize selected;
@end
