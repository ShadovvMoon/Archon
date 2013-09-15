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
	
	vert *coll_verts;
	int coll_count;
    
    struct Bsp3dNode *bsp3d_nodes;
    int node3d_count;
	
    struct Plane *planes;
    int plane_count;
    int leaf_count;
    
    struct Leaf3d *leaves;
    struct Bsp2dRef *bsp2dref;
    struct Bsp2dNodes *bsp2dnode;
    struct Surfaces *surfaces;
    struct Edges *edges;
    struct Verticies *verticies;
    
	BSP_WEATHER *m_pWeather;
	BSP_XREF m_BspXrefs[BSP_XREF_COUNT];
	
	BSP_HEADER m_BspHeader;
	BSP_LIGHTMAP *m_pLightmaps;
	BSP_COLLISION *m_pCollisions;
	BSP_CLUSTER *m_pClusters;
	
	BOUNDING_BOX m_MapBox;
	
	BOOL texturesLoaded;
	
	float m_Centroid[3];
	unsigned long m_CentroidCount;
	int m_activeBsp;
	int m_TriTotal;
}
-(float*)findIntersection:(float*)p withOther:(float*)q;

- (id)initWithMapAndBsp:(HaloMap *)map bsp_class:(BSP *)bsp_class texManager:(TextureManager *)texManager bsp_magic:(unsigned long)bsp_magic;
- (void)dealloc;
- (void)freeBSPAllocation;
- (SUBMESH_INFO *)m_pMesh:(long)index;
- (vert*)collision_verticies;
- (unsigned long)m_SubMeshCount;
- (void)LoadVisibleBsp:(unsigned long)BspHeaderOffset version:(unsigned long)version;
- (void)LoadPcSubmeshes;
- (void)LoadPcSubmeshTextures;
- (void)LoadMaterialMeshHeaders;
- (void)getMapCentroid:(float *)center_x center_y:(float *)center_y center_z:(float *)center_z;
- (void)UpdateBoundingBox:(int)mesh_index pCoord:(float *)pCoord version:(unsigned long)version;
- (void)ResetBoundingBox;

@property (retain) HaloMap *_mapfile;
@property (retain) BSP *_bspParent;
@property (retain) TextureManager *_texManager;
@property (getter=m_SubMeshCount) unsigned long m_SubMeshCount;
@property unsigned long _bspMagic;
@property SUBMESH_INFO *m_pMesh;
@property BSP_WEATHER *m_pWeather;
@property BSP_LIGHTMAP *m_pLightmaps;
@property BSP_CLUSTER *m_pClusters;
@property BOOL texturesLoaded;
@property unsigned long m_CentroidCount;
@property int m_activeBsp;
@property int m_TriTotal;
@end
