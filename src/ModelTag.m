//
//  ModelTag.m
//  SparkEdit
//
//  Created by Michael Edgar on Mon Jun 21 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "ModelTag.h"
#import "NSFile.h"
#import "HaloMap.h"
#import "Geometry.h"
@implementation ModelTag
- (NSString *)name
{
	return [[name retain] autorelease];
}
- (Geometry *)geoAtIndex:(int)idx
{
	return [[[subModels objectAtIndex:idx] retain] autorelease];
}
- (int)submodelCount
{
	return [subModels count];
}
- (unsigned long)ident
{
	return myTag.ident;
}
- (id)initWithFile:(NSFile *)file atOffset:(long)offset map:(HaloMap *)map
{
	if (self = [super init])
	{
		long offsetInHeader;
		long magic = [map indexHeader].magic;
		offsetInHeader = offset;
		[file seekToOffset:offset];
		[file readIntoStruct:&myTag.classA size:12];
		myTag.ident = [file readDword];
		myTag.stringOffset = [file readDword];
		myTag.offset = [file readDword];
		[file skipBytes:8];
		[file seekToOffset:myTag.stringOffset - magic];
		name = [[file readCString] retain];
		[file seekToOffset:myTag.offset-magic];
		[file skipBytes:48];
		u_scale = [file readFloat];
		v_scale = [file readFloat];
		[file skipBytes:116];
		//other reflexives
		[file skipBytes:24];
		reflexive regionRef = readReflexiveFromFile(file,magic);
		reflexive geometryRef = readReflexiveFromFile(file,magic);
		reflexive shaderRef = readReflexiveFromFile(file,magic);
		int x;
		[file seekToOffset:regionRef.offset];
		numRegions = regionRef.chunkcount;
		regions = malloc(regionRef.chunkcount * sizeof(MODEL_REGION));
		for (x=0;x<regionRef.chunkcount;x++)
			regions[x] = readModelRegionFromFile(file,magic);
		
		[file seekToOffset:geometryRef.offset];
		subModels = [[NSMutableArray alloc] initWithCapacity:geometryRef.chunkcount];
		Geometry *tempGeo;
		for (x=0;x<geometryRef.chunkcount;x++)
		{
			[file seekToOffset:(geometryRef.offset) + (x * 48)];
			tempGeo = [[Geometry alloc] initWithFile:file magic:magic map:map parent:self];
			[subModels addObject:tempGeo];
		
		}
		
		[file seekToOffset:shaderRef.offset];
		shaders = [[NSMutableArray alloc] initWithCapacity:shaderRef.chunkcount];
		for (x=0;x<shaderRef.chunkcount;x++)
		{
			[file skipBytes:12];
			[shaders addObject:[NSNumber numberWithLong:[file readDword]]];
			[file skipBytes:16];
		}
		
		[file seekToOffset:offsetInHeader+32];
	}
	return self;
}
- (void)loadBitmaps
{
	[subModels makeObjectsPerformSelector:@selector(loadBitmaps)];
}
- (void)drawAtPoint:(float*)point lod:(int)lod withView:(NSOpenGLView*)view index:(long)index type:(short)type selected:(bool)selected moving:(bool)moving
{
	int permutation = 0;
	int region;

	Geometry *tempGeo;
	[[view openGLContext] makeCurrentContext];
	if (selected)
    {
    
        if (bb == NULL)
            [self determineBoundingBox];
         glPushMatrix();
         glTranslatef(point[0],point[1],point[2]);
    
    
         glRotatef(point[3]*(57.29577951),0,0,1);
         glRotatef(point[4]*(57.29577951),0,1,0);
         glRotatef(point[5]*(57.29577951),1,0,0);
         [self drawBoundingBox];
         glPopMatrix();
     }
     if (moving)
     {
        glPushMatrix();
    	glTranslatef(point[0],point[1],point[2]);
    

        glRotatef(point[3]*(57.29577951),0,0,1);
        glRotatef(point[4]*(57.29577951),0,1,0);
        glRotatef(point[5]*(57.29577951),1,0,0);
    	
    	for(region=0; region<numRegions; region++)
    	{
    		tempGeo = [subModels objectAtIndex:regions[region].permutations[permutation].LOD_MeshIndex[lod]];
    		
    		[tempGeo drawIntoView:view x:point[0] y:point[1] z:point[3]];
    	}
    
    	glPopMatrix();
    }
    else
    {
	   if (glIsList((type*15000) + index))
	       glCallList((type*15000) + index);
	   else
	   {
	      
        	glNewList((type*15000) + index, GL_COMPILE);
        	glPushMatrix();
        	glTranslatef(point[0],point[1],point[2]);
       
       
           glRotatef(point[3]*(57.29577951),0,0,1);
           glRotatef(point[4]*(57.29577951),0,1,0);
           glRotatef(point[5]*(57.29577951),1,0,0);
       	
       	    for(region=0; region<numRegions; region++)
       	    {
       	    	tempGeo = [subModels objectAtIndex:regions[region].permutations[permutation].LOD_MeshIndex[lod]];
       	    	
       	    	[tempGeo drawIntoView:view x:point[0] y:point[1] z:point[3]];
       	    }
            
       	    glPopMatrix();
            
       	    glEndList();
       	    glCallList((type*15000) + index);
	   }
	}
}
- (void)drawBoundingBox
{
    glColor3f(0.0f,1.0f,0.0f);
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
	    
    glEnd();
}
- (void)determineBoundingBox
{
	if (bb == NULL)
	{   
		bb = malloc(sizeof(BOUNDING_BOX));
		bb->min[0] = 50000;
		bb->min[1] = 50000;
		bb->min[2] = 50000;
		bb->max[0] = -50000;
		bb->max[1] = -50000;
		bb->max[2] = -50000;
		BOUNDING_BOX b;
		int x;
		for (x=0;x<[subModels count];x++)
		{
			b = [(Geometry*)[subModels objectAtIndex:x] determineBoundingBox];
			if (b.min[0]<bb->min[0])
				bb->min[0]=b.min[0];
			if (b.min[1]<bb->min[1])
				bb->min[1]=b.min[1];
			if (b.min[2]<bb->min[2])
				bb->min[2]=b.min[2];
			if (b.max[0]>bb->max[0])
				bb->max[0]=b.max[0];
			if (b.max[1]>bb->max[1])
				bb->max[1]=b.max[1];
			if (b.max[2]>bb->max[2])
				bb->max[2]=b.max[2];
		}
	}
}
- (NSNumber *)shaderIdentForIndex:(char)idx
{
	return [shaders objectAtIndex:idx];
}
- (float)u_scale
{
	return u_scale;
}
- (float)v_scale
{
	return v_scale;
}

@end
