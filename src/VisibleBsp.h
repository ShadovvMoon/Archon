//
//  VisibleBsp.h
//  SparkEdit
//
//  Created by Michael Edgar on Mon Jul 19 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//
@class NSFile;
@class BitmapTag;
@class HaloMap;
#import <Foundation/Foundation.h>
#import "BSPDefs.h"
#define BSP_XREF_COUNT  42
@interface VisibleBsp : NSObject {
	unsigned long m_SubMeshCount;
	SUBMESH_INFO *m_pMesh;
	BSP_WEATHER *m_pWeather;
	BSP_XREF m_BspXrefs[BSP_XREF_COUNT];
	
	NSFile *m_pMapFile;
	unsigned long m_BspMagic;
	unsigned long m_Magic;
	HaloMap *myMap;
	BSP_HEADER m_BspHeader;
	BSP_LIGHTMAP *m_pLightmaps;
	BOUNDING_BOX m_MapBox;
	BSP_CLUSTER *m_pClusters;
	
 	float m_Centroid[3];
    unsigned long m_CentroidCount;
	int m_ActiveBsp;
	int m_TriTotal;
}
- (id)init;
- (void) Initialize:(NSFile *)pMapFile magic:( unsigned long )magic bsp_magic:( unsigned long )bsp_magic map:(HaloMap*)map;
- (void) LoadVisibleBsp:(unsigned long)BspHdrOffset version:(unsigned long)version;
- (void) LoadMaterialMeshHeaders;
- (void) LoadPcSubmeshes;
- (void) ResetBoundingBox;
- (void) LoadPcSubmeshTextures;
- (unsigned long)m_SubMeshCount;
- (void)UpdateBoundingBox:(int)mesh_index pCoord:(float *)pCoord version:(unsigned long)version;
- (void)GetMapCentroid:(float*)cx cy:(float*)cy cz:(float*)cz;
- (SUBMESH_INFO*)m_pMesh:(long)idx;
@end
