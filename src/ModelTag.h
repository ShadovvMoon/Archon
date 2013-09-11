//
//  ModelTag.h
//  SparkEdit
//
//  Created by Michael Edgar on Mon Jun 21 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Geometry;
@class NSFile;
@class HaloMap;
#import "FileConstants.h"
#import "ModelDefs.h"

@interface ModelTag : NSObject {
	tag myTag;
	NSString *name;
	NSMutableArray *subModels;
	NSMutableArray *shaders;
	float u_scale;
	float v_scale;
	MODEL_REGION *regions;
	unsigned long numRegions;
	BOUNDING_BOX *bb;
}
- (void)drawBoundingBox;
- (void)determineBoundingBox;
- (void)drawAtPoint:(float*)point lod:(int)lod withView:(NSOpenGLView*)view index:(long)index type:(short)type selected:(bool)selected moving:(bool)moving;
- (id)initWithFile:(NSFile *)file atOffset:(long)offset map:(HaloMap *)map;
- (NSString *)name;
- (unsigned long)ident;
- (int)submodelCount;
- (Geometry *)geoAtIndex:(int)idx;
- (NSNumber *)shaderIdentForIndex:(char)idx;
- (float)u_scale;
- (void)loadBitmaps;
- (float)v_scale;
@end
