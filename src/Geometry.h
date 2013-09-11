//
//  Geometry.h
//  SparkEdit
//
//  Created by Michael Edgar on Mon Jun 21 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileConstants.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>




@class NSFile;
@class BitmapTag;
@class HaloMap;
@class ModelTag;
typedef struct
{
	char junk[36];
	reflexive parts;
} geometry;
typedef struct
{
	long count;
	long rawPointer[2];
} indicesPointer;
typedef struct
{
	long count;
	char junk[8];
	long rawPointer;
} verticesPointer;
typedef struct
{
	float x;
	float y;
	float z;
	float normalx;
	float normaly;
	float normalz;
	float u;
	float v;
} Vector;
typedef struct
{
	char junk4[4];
	short shaderIndex;
	char junk[66];
	indicesPointer indexPointer;
	char junk2[4];
	verticesPointer vertPointer;
	char junk3[28];
	Vector *vertices;
	unsigned short *indices;
} part;

@interface Geometry : NSObject {
	geometry me;
	long numParts;
	reflexive partsref;
	part *parts;
	NSString *pathToFile;
	long vertex_size;
	long vertex_offset;
	ModelTag *parent;
	HaloMap *myMap;
	GLuint *textures;

}
- (BOUNDING_BOX)determineBoundingBox;
- (void)drawIntoView:(NSOpenGLView *)view x:(float)x y:(float)y z:(float)z;
- (id)initWithFile:(NSFile *)file magic:(long)magic map:(HaloMap *)map parent:(ModelTag *)myModel;
- (void)loadBitmaps;
@end
