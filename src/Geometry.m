//
//  Geometry.m
//  SparkEdit
//
//  Created by Michael Edgar on Mon Jun 21 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "Geometry.h"
#import "NSFile.h"
#import "HaloMap.h"
#import "ModelTag.h"
#import "BitmapTag.h"
#include <string.h>
@implementation Geometry
- (void)releaseBitmaps
{
	glDeleteTextures(numParts,&textures[0] );
	
}
- (void)loadBitmaps
{
	NSFile *file = [[NSFile alloc] initWithPathForReading:pathToFile];
	[file setLittleEndian:YES];
	long index;
	for (index=0;index<numParts;index++)
	{

		long identOfBitm = [myMap baseBitmapIdentForShader:[[parent shaderIdentForIndex:parts[index].shaderIndex] longValue] file:file];
		BitmapTag *bitm = [myMap bitmForIdent:identOfBitm];
		unsigned int *texData = [bitm imagePixelsForImageIndex:0];
		glGenTextures( 1 , &textures[index] );
		glBindTexture( GL_TEXTURE_2D, textures[ index ] );
		glTexImage2D( GL_TEXTURE_2D, 0, 4, [bitm textureSizeForImageIndex:0].width,
                    [bitm textureSizeForImageIndex:0].height, 0, GL_RGBA,
                    GL_UNSIGNED_BYTE, texData );
		[bitm freeImagePixels];
		/*unsigned char **pointerToBitRep = (char *)&texData;
		NSBitmapImageRep *bitRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:pointerToBitRep
		pixelsWide:[bitm textureSizeForImageIndex:0].width
		pixelsHigh:[bitm textureSizeForImageIndex:0].height
		bitsPerSample:8
		samplesPerPixel:4
		hasAlpha:YES
		isPlanar:NO
		colorSpaceName:NSCalibratedRGBColorSpace
		bytesPerRow:(4 * 8 * [bitm textureSizeForImageIndex:0].width)
		bitsPerPixel:32];
		[[NSFileHandle fileHandleForWritingAtPath:@"bob.tiff"] writeData:[bitRep TIFFRepresentation]];*/

	
	
	
	}
	glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,
		GL_NEAREST);
	glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,
		GL_NEAREST);
		      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
	glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE, GL_DECAL);
	glEnable(GL_TEXTURE_2D);

}

- (void)drawIntoView:(NSOpenGLView *)view x:(float)x y:(float)y z:(float)z
{
	
	
	int i;
	//NSFile *file = [[NSFile alloc] initWithPathForReading:pathToFile];
	//[file setLittleEndian:YES];
	part currentPart;
	float u_scale = [parent u_scale];
	float v_scale = [parent v_scale];
	
	for (i=0;i<numParts;i++)
	{
		currentPart = parts[i];
		//[file seekToOffset:currentPart.indexPointer.rawPointer[0]+vertex_offset+vertex_size];
		glBindTexture( GL_TEXTURE_2D, textures[ i ] );
		glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER, GL_NEAREST);

	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
	//glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB_EXT, GL_REPLACE);
		glEnable(GL_TEXTURE_2D);

		int j;


		if (currentPart.indexPointer.rawPointer[0]==currentPart.indexPointer.rawPointer[1])
		{
		
		
		glBegin( GL_TRIANGLE_STRIP );
		unsigned short idx;
		
		for (j=0;j<currentPart.indexPointer.count+2;j++)
		{

			idx = currentPart.indices[j];
			Vector *tempVector = &currentPart.vertices[idx];
			glNormal3f( tempVector->normalx, tempVector->normaly, tempVector->normalz); 
			glTexCoord2f( tempVector->u*u_scale, tempVector->v*v_scale );

			glVertex3f(tempVector->x,tempVector->y,tempVector->z);
		}
		
		glEnd();

		glDisable(GL_TEXTURE_2D);
		}
		else
		{
		NSLog(@"Bad part");
		}
		//Vector *tempVector = &currentPart.vertices[0];
//			glTexCoord2f( tempVector->u*u_scale, tempVector->v*v_scale );
//			glVertex3f(tempVector->x,tempVector->y,tempVector->z);


	}
	
	glFlush();

	//[file close];
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
	for (x=0;x<numParts;x++)
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
					
		

- (id)initWithFile:(NSFile *)file magic:(long)magic map:(HaloMap *)map parent:(ModelTag *)myModel
{
	if (self = [super init])
	{
		myMap = [[map retain] autorelease];
		parent = myModel;
		vertex_size = [map indexHeader].vertex_size;
		vertex_offset = [map indexHeader].vertex_offset;
		//read the geometry
		pathToFile = [[file path] retain];
		[file readIntoStruct:&me.junk size:36];
		partsref.chunkcount = [file readDword];
		partsref.offset = [file readDword];
		partsref.zero = [file readDword];
		numParts = partsref.chunkcount;
		textures = malloc(numParts * sizeof(GLuint));
		[file seekToOffset:partsref.offset-magic];
		//go to the parts
		int x;
		parts = malloc(sizeof(part)*numParts);
		part *tempPointer = parts;
		for (x=0;x<numParts;x++)
		{
			part *currentPart = &parts[x];
			[file readIntoStruct:currentPart->junk4 size:4];
			currentPart->shaderIndex=[file readWord];
			[file readIntoStruct:currentPart->junk size:66];
			//read indices pointer
			currentPart->indexPointer.count = [file readDword];
			currentPart->indexPointer.rawPointer[0] = [file readDword];
			currentPart->indexPointer.rawPointer[1] = [file readDword];
			if (currentPart->indexPointer.rawPointer[1] != currentPart->indexPointer.rawPointer[0])
				NSLog(@"BadPartInit");
			//junk
			[file readIntoStruct:currentPart->junk2 size:4];
			//read vertex pointer
			currentPart->vertPointer.count = [file readDword];
			[file readIntoStruct:currentPart->vertPointer.junk size:8];
			currentPart->vertPointer.rawPointer = [file readDword];
			//junk
			[file readIntoStruct:currentPart->junk3 size:28];
			

			
			DWORD endOfPart = [file offset];
			[file seekToOffset:currentPart->vertPointer.rawPointer+vertex_offset];

			currentPart->vertices = malloc(sizeof(Vector) * currentPart->vertPointer.count);
			//parts->vertices=currentPart.vertices;
			int j;
			for (j=0;j<currentPart->vertPointer.count;j++)
			{
				Vector *currentVertex = &currentPart->vertices[j];
				currentVertex->x = [file readFloat];
				currentVertex->y = [file readFloat];
				currentVertex->z = [file readFloat];

				currentVertex->normalx = [file readFloat];
				currentVertex->normaly = [file readFloat];
				currentVertex->normalz = [file readFloat];
				[file skipBytes:24];
				currentVertex->u = [file readFloat];
				currentVertex->v = [file readFloat];
				[file skipBytes:12];
			}
			
			[file seekToOffset:currentPart->indexPointer.rawPointer[0]+vertex_offset+vertex_size];
			currentPart->indices = malloc(sizeof(unsigned short) * (currentPart->indexPointer.count+2));
			for (j=0;j<currentPart->indexPointer.count+2;j++)
				currentPart->indices[j] = [file readWord];
			
			[file seekToOffset:endOfPart];
			
		}
		parts = tempPointer;
	}
	return self;
}
@end
