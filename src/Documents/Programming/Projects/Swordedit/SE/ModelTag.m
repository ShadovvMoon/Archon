//
//  ModelTag.m
//  swordedit
//
//  Created by sword on 5/11/08.
//

#import "ModelTag.h"
#import "Geometry.h"

#import "TextureManager.h"
#import "RenderView.h"

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

- (void)drawAtPoint:(float *)point lod:(int)lod isSelected:(BOOL)isSelected useAlphas:(BOOL)useAlphas
{
    [self drawAtPoint:point lod:lod isSelected:isSelected useAlphas:useAlphas distance:0.0];
}


- (void)drawAtPoint:(float *)point lod:(int)lod isSelected:(BOOL)isSelected useAlphas:(BOOL)useAlphas distance:(float)dist
{
	int i, x;
	
    
    
	if (bb == NULL)
		[self determineBoundingBox];
	
    
    
	glPushMatrix();
    glTranslatef(point[0],point[1],point[2]);
    
    if (isSelected)
    {
        if (useNewRenderer())
        {
            glDisableClientState(GL_VERTEX_ARRAY);
            glDisableClientState(GL_TEXTURE_COORD_ARRAY);
            
            glDisable(GL_TEXTURE_2D);
            glDisable(GL_BLEND);
        }
        
        glBegin(GL_LINES);
        {
            // Now to try some other stuffs! Bwahaha!
            // set these lines to white
            glLineWidth(1.0f);
            // x
            
            float lineLength = 1000.0f/2;
            
            glColor4f(5.0f,5.0f,5.0f, 1.0f);
            glVertex3f(-lineLength,0.0f,0.0f);
            glVertex3f(lineLength,0.0f,0.0f);
            glVertex3f(0.0f,-lineLength,0.0f);
            glVertex3f(0.0f,lineLength,0.0f);
            glVertex3f(0.0f,0.0f,-lineLength);
            glVertex3f(0.0f,0.0f,lineLength);
        }
        glEnd();
        
        
        if (useNewRenderer())
        {
            glEnableClientState(GL_VERTEX_ARRAY);
            glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        }
        
    }
    
    
    /* Perform rotation */
    glRotatef(point[5] * (57.29577951), 1, 0, 0);
    glRotatef(-point[4] * (57.29577951), 0, 1, 0);
    glRotatef(point[3] * (57.29577951), 0, 0, 1);
    
    
    if (bb->max[2]-bb->min[2]<= 0.001)
    {
        glDisable(GL_TEXTURE_2D);
        glEnable(GL_BLEND);
        
        glColor4f(1.0, 0.0, 0.0, 0.5);
        
        GLUquadric *sphere=gluNewQuadric();
        gluQuadricDrawStyle( sphere, GLU_FILL);
        gluQuadricNormals( sphere, GLU_SMOOTH);
        gluQuadricOrientation( sphere, GLU_OUTSIDE);
        gluQuadricTexture( sphere, GL_TRUE);
        
        gluSphere(sphere,0.05,5,5);
        gluDeleteQuadric ( sphere );
        
        glDisable(GL_BLEND);
        
        
        glBegin(GL_LINES);
        {
            // pointer arrow
            glColor3f(1.0f,1.0f,1.0f);
            glVertex3f(0.5f,0.0f,0.0f);
            glVertex3f(0.3f,0.2f,0.0f);
            glVertex3f(0.5f,0.0f,0.0f);
            glVertex3f(0.3f,-0.2f,0.0f);
        }
        glEnd();
        
    }
    
    
    
    
    
    //--------------------------------
    //The copyright for the following code is owned by Samuel Colbran (Samuco).
    //The copyright for other smaller segments that are not identified by these comments are also owned by Samuel Colbran (Samuco).
    //--------------------------------
    
    if (isSelected)
    {
        if (useNewRenderer())
        {
            glDisableClientState(GL_VERTEX_ARRAY);
            glDisableClientState(GL_TEXTURE_COORD_ARRAY);
            
            glDisable(GL_TEXTURE_2D);
            glDisable(GL_BLEND);
        }
        
        glColor4f(1.0f,1.0f,0.0f,4.0f);
        
        if (renderV)
        {
                if (![renderV isAboveGround:point])
                    glColor4f(1.0f,0.0f,0.0f,0.2f);
                else
                    glColor4f(1.0f,1.0f,0.0f,4.0f);
            
        }
        else
            glColor4f(1.0f,1.0f,0.0f,4.0f);
        
        //isAboveGround
       
        [self drawBoundingBox];
        
        
        
        if (useNewRenderer())
        {
            glEnableClientState(GL_VERTEX_ARRAY);
            glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        }
        
        
        
    }
 
    
    int z;
    for (i = 0; i < numRegions; i++)
    {
        for (x = 0; x < regions[i].Permutations.chunkcount; x++)
        {
            
            
      
               // NSLog([NSString stringWithCString:regions[i].modPermutations[x].Name encoding:NSUTF8StringEncoding]);
            
            int g = regions[i].modPermutations[x].Flags[0];
            if ((g & 0xFF) == 1)
            {
                
                //NSLog([NSString stringWithCString:regions[i].modPermutations[x].Name encoding:NSUTF8StringEncoding]);
                //continue;
            }
            else
            {
                int index;
                //if (dist < 10.0)
                    index = regions[i].modPermutations[x].LOD_MeshIndex[4];
                //else
                //  index = regions[i].modPermutations[x].LOD_MeshIndex[0];
                

                if (index>=[subModels count])
                {
                    continue;
                }
                
                id model = [subModels objectAtIndex:index];
                if (model)
                {
    #ifdef fasterRendering
                    glBegin(GL_TRIANGLE_STRIP);
    #endif
                    [model drawIntoView:useAlphas];
    #ifdef fasterRendering
                    glEnd();
    #endif
                }
                else
                {
                    NSLog(@"NO MODEL?");
                }
            }
            
        }
    }
    
    //END CODE
    
    glColor3f(1.0f,1.0f,1.0f);
	glPopMatrix();
}

- (void)loadAllBitmaps
{
	[subModels makeObjectsPerformSelector:@selector(loadBitmaps)];
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
