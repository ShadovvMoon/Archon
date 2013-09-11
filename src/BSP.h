//
//  BSP.h
//  swordedit
//
//  Created by sword on 10/21/07.
//  Copyright 2007 sword Inc. All rights reserved.
//
//	sword@clanhalo.net
//

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
	
	long m_ActiveBsp;
	long m_Version;
	long m_Magic;
	long m_BspCount;
	
	SCENARIO_BSP_INFO *m_pBspInfo;
	NSMutableArray *m_BspNames;
	NSMutableArray *m_pBsp;
}
- (id)initWithMapFile:(HaloMap *)map texManager:(TextureManager *)texManager;
- (void)dealloc;
- (void)destroyObjects;
- (void)loadVisibleBspInfo:(reflexive)BspChunk version:(unsigned long)version;
- (UNCOMPRESSED_BSP_VERT)readUncompressedBspVert;
- (UNCOMPRESSED_LIGHTMAP_VERT)readUncompressedLightmapVert;
- (TRI_INDICES)readIndexFromFile;
- (MATERIAL_SUBMESH_HEADER)readMaterialSubmeshHeader;
- (SCENARIO_BSP_INFO)readBspInfo;
- (short)NumberOfBsps;
- (void)setActiveBsp:(unsigned long)bsp;
- (BspMesh *)getActiveBsp;
- (unsigned long)GetActiveBspSubmeshCount;
- (SUBMESH_INFO *)GetActiveBspPCSubmesh:(int)mesh_index;
- (void)GetActiveBspCentroid:(float *)_center_x center_y:(float *)_center_y center_z:(float *)_center_z;
@end
