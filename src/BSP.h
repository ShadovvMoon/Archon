//
//  BSP.h
//  swordedit
//
//  Created by sword on 10/21/07.
//  Copyright 2007 sword Inc. All rights reserved.
//
//	sword@clanhalo.net
//
#ifndef MACVERSION
#import "glew.h"
#endif

#import <Cocoa/Cocoa.h>
/*#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>*/

#import "defines.h"

#import "HaloMap.h"
#import "ModelTag.h"
#import "Geometry.h"

@class BspMesh;
@class TextureManager;

@interface BSP : NSObject {
	HaloMap *_mapfile;
	TextureManager *_texManager;
	
	int32_t m_ActiveBsp;
	int32_t m_Version;
	int32_t m_Magic;
	int32_t m_BspCount;
	
	BspMesh *tempBsp;
	
	SCENARIO_BSP_INFO *m_pBspInfo;
	NSMutableArray *m_BspNames;
	NSMutableArray *m_pBsp;
}
    -(int)bspCount;
    -(int)activeBSP;
    - (SUBMESH_INFO *)GetBsp:(int)bsp PCSubmesh:(int)mesh_index;
    - (uint32_t)GetBspSubmeshCount:(int)bsp;
    - (short)NumberOfBsps;
    -(void)loadAllBsps;
    
- (id)initWithMapFile:(HaloMap *)map texManager:(TextureManager *)texManager;
- (void)dealloc;
- (void)destroyObjects;
- (void)loadVisibleBspInfo:(reflexive)BspChunk version:(uint32_t)version;
- (UNCOMPRESSED_BSP_VERT)readUncompressedBspVert;
- (COMPRESSED_BSP_VERT)readCompressedBspVert;
- (UNCOMPRESSED_LIGHTMAP_VERT)readUncompressedLightmapVert;
- (TRI_INDICES)readIndexFromFile;
- (MATERIAL_SUBMESH_HEADER)readMaterialSubmeshHeader;
- (SCENARIO_BSP_INFO)readBspInfo;
- (short)NumberOfBsps;
- (void)setActiveBsp:(uint32_t)bsp;
- (BspMesh *)getActiveBsp;
- (uint32_t)GetActiveBspSubmeshCount;
- (BspMesh*)mesh;
- (SUBMESH_INFO *)GetActiveBspPCSubmesh:(int)mesh_index;
- (void)GetActiveBspCentroid:(float *)_center_x center_y:(float *)_center_y center_z:(float *)_center_z;
@property (retain) HaloMap *_mapfile;
@property (retain) TextureManager *_texManager;
@property int32_t m_ActiveBsp;
@property int32_t m_Version;
@property int32_t m_Magic;
@property int32_t m_BspCount;
@property SCENARIO_BSP_INFO *m_pBspInfo;
@property (retain) NSMutableArray *m_BspNames;
@property (retain) NSMutableArray *m_pBsp;
@end
