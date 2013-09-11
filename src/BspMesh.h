//
//  BspMesh.h
//  swordedit
//
//  Created by sword on 10/28/07.
//  Copyright 2007 sword Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "defines.h"

#import "HaloMap.h"
#import "BSP.h"


#define BSP_XREF_COUNT 42

@class TextureManager;

@interface BspMesh : NSObject {
	HaloMap *_mapfile;
	BSP *_bspParent;
	
	TextureManager *_texManager;

	unsigned long m_SubMeshCount;
	unsigned long _bspMagic;
	
	SUBMESH_INFO *m_pMesh;
	BSP_WEATHER *m_pWeather;
	BSP_XREF m_BspXrefs[BSP_XREF_COUNT];
	
	BSP_HEADER m_BspHeader;
	BSP_LIGHTMAP *m_pLightmaps;
	BSP_CLUSTER *m_pClusters;
	
	BOUNDING_BOX m_MapBox;
	
	BOOL texturesLoaded;
	
	float m_Centroid[3];
	unsigned long m_CentroidCount;
	int m_activeBsp;
	int m_TriTotal;
}
- (id)initWithMapAndBsp:(HaloMap *)map bsp_class:(BSP *)bsp_class texManager:(TextureManager *)texManager bsp_magic:(unsigned long)bsp_magic;
- (void)dealloc;
- (void)freeBSPAllocation;
- (SUBMESH_INFO *)m_pMesh:(long)index;
- (unsigned long)m_SubMeshCount;
- (void)LoadVisibleBsp:(unsigned long)BspHeaderOffset version:(unsigned long)version;
- (void)LoadPcSubmeshes;
- (void)LoadPcSubmeshTextures;
- (void)LoadMaterialMeshHeaders;
- (void)getMapCentroid:(float *)center_x center_y:(float *)center_y center_z:(float *)center_z;
- (void)UpdateBoundingBox:(int)mesh_index pCoord:(float *)pCoord version:(unsigned long)version;
- (void)ResetBoundingBox;
@end
