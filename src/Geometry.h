//
//  Geometry.h
//  swordedit
//
//  Created by Fred Havemeyer on 5/11/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "defines.h"

@class HaloMap;
@class ModelTag;
@class TextureManager;

@interface Geometry : NSObject {
	int numParts;
	int vertexSize;
	int vertexOffset;
	
	GLuint *textures;
	
	HaloMap *_mapfile;
	ModelTag *parent;
	
	TextureManager *_texManager;
	
	reflexive partsref;
	part *parts;
	geometry me;
	
	BOOL texturesLoaded;
}
- (id)initWithMap:(HaloMap *)map parent:(ModelTag *)mTag;
- (void)dealloc;
- (void)destroy;
- (void)loadBitmaps;
- (BOUNDING_BOX)determineBoundingBox;
- (void)drawIntoView:(BOOL)useAlphas;
@end
