//
//  
//  swordedit
//
//  Created by sword on 5/11/08.
//

#import <Cocoa/Cocoa.h>

#import "defines.h"

#import "HaloMap.h"
#import "MapTag.h"

@class TextureManager;

@interface ModelTag : MapTag {
	HaloMap *_mapfile;
	
	TextureManager *_texManager;
	
	NSMutableArray *subModels;
	NSMutableArray *shaders;
	NSMutableArray *shaderTypes;
	
	float u_scale;
	float v_scale;
	
	MODEL_REGION *regions;
	
	reflexive regionRef;
	
	int numRegions;
	
	BOUNDING_BOX *bb;
	
	BOOL moving;
	BOOL selected;
}
- (id)initWithMapFile:(HaloMap *)map texManager:(TextureManager *)texManager;
- (void)dealloc;
- (void)releaseGeometryObjects;
- (void)determineBoundingBox;
- (BOUNDING_BOX *)bounding_box;
- (float)u_scale;
- (float)v_scale;
- (int)numRegions;
- (void)drawAtPoint:(float *)point lod:(int)lod isSelected:(BOOL)isSelected useAlphas:(BOOL)useAlphas;
- (void)drawAtPoint:(float *)point lod:(int)lod isSelected:(BOOL)isSelected useAlphas:(BOOL)useAlphas distance:(float)dist;
- (void)loadAllBitmaps;
- (long)shaderIdentForIndex:(int)index;
- (void)drawBoundingBox;
- (void)drawAxes:(BOOL)withPointerArrow;
- (TextureManager *)_texManager;
- (void)renderPartyTriangle;
@property (retain) HaloMap *_mapfile;
@property (retain,getter=_texManager) TextureManager *_texManager;
@property (retain) NSMutableArray *subModels;
@property (retain) NSMutableArray *shaders;
@property (getter=u_scale) float u_scale;
@property (getter=v_scale) float v_scale;
@property MODEL_REGION *regions;
@property (getter=bounding_box) BOUNDING_BOX *bb;
@property BOOL moving;
@property BOOL selected;
@end
