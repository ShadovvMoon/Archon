//
//  BSP.m
//  swordedit
//
//  Created by sword on 10/21/07.
//  Copyright 2007 sword Inc. All rights reserved.
//
//	sword@clanhalo.net
//
#import "BSP.h"
#import "BspMesh.h"

#import "TextureManager.h"

@implementation BSP
- (id)initWithMapFile:(HaloMap *)map texManager:(TextureManager *)texManager
{
	if ((self = [super init]) != nil)
	{
		_mapfile = [map retain];
		_texManager = [texManager retain];
	}
	return self;
}
- (void)dealloc
{
	#ifdef __DEBUG__
	NSLog(@"Deallocating BSP Manager!");
	#endif
	
	free(m_pBspInfo);
	
	[super dealloc];
}
- (void)destroyObjects
{
	[m_pBsp removeAllObjects];
	[m_pBsp release];
	
	[_mapfile release];
	
	[_texManager release];
}
- (void)loadVisibleBspInfo:(reflexive)BspChunk version:(unsigned long)version
{
	#ifdef __DEBUG__
	NSLog(@"Loading BSP Info!");
	#endif
	
	unsigned long hdr;
	unsigned long offset;
	int i;
	m_Version = version;
	if (BspChunk.chunkcount > 0)
	{
		m_pBspInfo = malloc(sizeof(SCENARIO_BSP_INFO) * BspChunk.chunkcount);
		m_pBsp = [[NSMutableArray alloc] initWithCapacity:BspChunk.chunkcount];
		[_mapfile seekToAddress:BspChunk.offset];
		#ifdef __DEBUG__
		NSLog(@"BSP Chunk offset: 0x%x", BspChunk.offset);
		#endif
		for (i = 0; i < BspChunk.chunkcount; i++)
		{
			#ifdef __DEBUG__
			NSLog(@"Loading BSP number: %i", i);
			//[_mapfile seekToAddress:BspChunk.location_in_mapfile];
			NSLog(@"BSP Chunk %i is located at: 0x%x", i, BspChunk.location_in_mapfile);
			#endif
 			m_pBspInfo[i] = [self readBspInfo];
			tempBsp = [[BspMesh alloc] initWithMapAndBsp:_mapfile bsp_class:self texManager:_texManager bsp_magic:m_pBspInfo[i].Magic];
			[tempBsp retain];
			
			// In bob's words, "Read in the scenario BSP Info"
			offset = [_mapfile currentOffset];
			[_mapfile seekToAddress:m_pBspInfo[i].BspStart];
			[_mapfile readLong:&hdr];
			hdr -= m_pBspInfo[i].Magic;
			[tempBsp LoadVisibleBsp:hdr version:version];
			
			[_mapfile seekToAddress:offset];
			[m_pBsp addObject:tempBsp];
			[tempBsp release];
		}
	}
	else
	{
		#ifdef __DEBUG__
		NSLog(@"Somethings up..");
		#endif
	}
	#ifdef __DEBUG__
	printf("\n");
	#endif
}


-(BspMesh*)mesh
{
	return tempBsp;
}

- (UNCOMPRESSED_BSP_VERT)readUncompressedBspVert
{
	UNCOMPRESSED_BSP_VERT retVert;
	[_mapfile readFloat:&retVert.vertex_k[0]];
	[_mapfile readFloat:&retVert.vertex_k[1]];
	[_mapfile readFloat:&retVert.vertex_k[2]];
	[_mapfile readFloat:&retVert.normal[1]];
	[_mapfile readFloat:&retVert.normal[2]];
	[_mapfile readFloat:&retVert.normal[3]];
	[_mapfile readFloat:&retVert.binormal[0]];
	[_mapfile readFloat:&retVert.binormal[1]];
	[_mapfile readFloat:&retVert.binormal[2]];
	[_mapfile readFloat:&retVert.tangent[0]];
	[_mapfile readFloat:&retVert.tangent[1]];
	[_mapfile readFloat:&retVert.tangent[2]];
	[_mapfile readFloat:&retVert.uv[0]];
	[_mapfile readFloat:&retVert.uv[1]];
	return retVert;
}
- (COMPRESSED_BSP_VERT)readCompressedBspVert
{
	COMPRESSED_BSP_VERT retVert;
	
	
	[_mapfile readFloat:&retVert.vertex_k[0]];
	[_mapfile readFloat:&retVert.vertex_k[1]];
	[_mapfile readFloat:&retVert.vertex_k[2]];
	[_mapfile readLong:&retVert.comp_normal];
	[_mapfile readLong:&retVert.comp_binormal];
	[_mapfile readLong:&retVert.comp_tangent];
	[_mapfile readFloat:&retVert.uv[0]];
	[_mapfile readFloat:&retVert.uv[1]];
	return retVert;
}
- (UNCOMPRESSED_LIGHTMAP_VERT)readUncompressedLightmapVert
{
	UNCOMPRESSED_LIGHTMAP_VERT retLight;
	[_mapfile readFloat:&retLight.normal[0]];
	[_mapfile readFloat:&retLight.normal[1]];
	[_mapfile readFloat:&retLight.normal[2]];
	[_mapfile readFloat:&retLight.uv[0]];
	[_mapfile readFloat:&retLight.uv[1]];
	return retLight;
}
- (TRI_INDICES)readIndexFromFile
{
	TRI_INDICES retTri;
	[_mapfile readShort:&retTri.tri_ind[0]];
	[_mapfile readShort:&retTri.tri_ind[1]];
	[_mapfile readShort:&retTri.tri_ind[2]];
	return retTri;
}

- (vert)readVert
{
	vert retHeader;

	[_mapfile readLong:&retHeader.x];
	[_mapfile readLong:&retHeader.y];
	[_mapfile readLong:&retHeader.z];
	[_mapfile readLong:&retHeader.edge];
	
	return retHeader;
}
- (MATERIAL_SUBMESH_HEADER)readMaterialSubmeshHeader
{
	MATERIAL_SUBMESH_HEADER retHeader;
	retHeader.ShaderTag = [_mapfile readReference]; // I think I may have to do this differently since it uses a bsp magic
	
	[_mapfile readLong:&retHeader.UnkZero2];
	[_mapfile readLong:&retHeader.VertIndexOffset];
	[_mapfile readLong:&retHeader.VertIndexCount];
	
	// Loop Fun Time!
	int i;
	for (i = 0; i < 3; i++)
		[_mapfile readFloat:&retHeader.Centroid[i]];
	for (i = 0; i < 3; i++)
		[_mapfile readFloat:&retHeader.AmbientColor[i]];
		
	[_mapfile readLong:&retHeader.DistLightCount];
	
	for (i = 0; i < 6; i++)
		[_mapfile readFloat:&retHeader.DistLight1[i]];
	for (i = 0; i < 6; i++)
		[_mapfile readFloat:&retHeader.DistLight2[i]];
	for (i = 0; i < 3; i++)
		[_mapfile readFloat:&retHeader.unkFloat2[i]];
	for (i = 0; i < 4; i++)
		[_mapfile readFloat:&retHeader.ReflectTint[i]];
	for (i = 0; i < 3; i++)
		[_mapfile readFloat:&retHeader.ShadowVector[i]];
	for (i = 0; i < 3; i++)
		[_mapfile readFloat:&retHeader.ShadowColor[i]];
	for (i = 0; i < 4; i++)
		[_mapfile readFloat:&retHeader.Plane[i]];
		
	[_mapfile readLong:&retHeader.UnkFlag2]; 
	[_mapfile readLong:&retHeader.UnkCount1];
	[_mapfile readLong:&retHeader.VertexCount1];
	[_mapfile readLong:&retHeader.UnkZero4]; //Vertex offset
	[_mapfile readLong:&retHeader.VertexOffset];
	[_mapfile readLong:&retHeader.Vert_Reflexive];
	[_mapfile readLong:&retHeader.UnkAlways3];
	[_mapfile readLong:&retHeader.VertexCount2];
	[_mapfile readLong:&retHeader.UnkZero9];
	[_mapfile readLong:&retHeader.UnkLightmapOffset];
	[_mapfile readLong:&retHeader.CompVert_Reflexive];
	[_mapfile readLong:&retHeader.UnkZero5[0]];
	[_mapfile readLong:&retHeader.UnkZero5[1]];
	[_mapfile readLong:&retHeader.SomeOffset1];
	[_mapfile readLong:&retHeader.PcVertexDataOffset];
	[_mapfile readLong:&retHeader.UnkZero6];
	[_mapfile readLong:&retHeader.CompVertBufferSize];
	[_mapfile readLong:&retHeader.UnkZero7];
	[_mapfile readLong:&retHeader.SomeOffset2];
	[_mapfile readLong:&retHeader.VertexDataOffset];
	[_mapfile readLong:&retHeader.UnkZero8];
	//[_mapfile readLong:&retHeader.VertexDataOffset];
	return retHeader;
}
- (SCENARIO_BSP_INFO)readBspInfo
{
	// Need to do a thing for multi BSPs here
	// Next prototype will be: - (SCENARIO_BSP_INFO *)readBspInfo:(int)bspCount
	SCENARIO_BSP_INFO scenInfo;
	[_mapfile readLong:&scenInfo.BspStart];
	[_mapfile readLong:&scenInfo.BspSize];
	[_mapfile readLong:&scenInfo.Magic];
	[_mapfile readLong:&scenInfo.Zero1];
	[_mapfile readBlockOfData:scenInfo.bsptag size_of_buffer:4];
	[_mapfile readLong:&scenInfo.NamePtr];
	[_mapfile readLong:&scenInfo.unknown2];
	[_mapfile readLong:&scenInfo.TagId];
	scenInfo.Magic -= scenInfo.BspStart;
	
	#ifdef __DEBUG__
	NSLog(@"BSP Magic: 0x%x", scenInfo.Magic);
	NSLog(@"BSP Start: 0x%x", scenInfo.BspStart);
	NSLog(@"BSP Size: 0x%x", scenInfo.BspSize);
	#endif
	
	return scenInfo;
}
// Bsp Info Section
- (short)NumberOfBsps
{
	return [m_pBsp count];
}

-(void)updateTextures
{
    [[m_pBsp objectAtIndex:m_ActiveBsp] LoadPcSubmeshTextures];
}

- (void)setActiveBsp:(unsigned long)bsp
{
	#ifdef __DEBUG__
	NSLog(@"Setting active BSP!");
	#endif
	NSLog(@"Set active bsp");
	//if (m_ActiveBsp != bsp)
	//{
		[[m_pBsp objectAtIndex:bsp] LoadPcSubmeshTextures];
		m_ActiveBsp = bsp;
	//}
    NSLog(@"Bsp loaded");
}
- (BspMesh *)getActiveBsp;
{
	return [m_pBsp objectAtIndex:m_ActiveBsp];
}
- (unsigned long)GetActiveBspSubmeshCount
{
	if (m_pBsp)
		return [[self getActiveBsp] m_SubMeshCount];
	else
		return 0;
}
- (SUBMESH_INFO *)GetActiveBspPCSubmesh:(int)mesh_index
{
	SUBMESH_INFO *pMesh = NULL;
	pMesh = [[self getActiveBsp] m_pMesh:mesh_index];
	return pMesh;
}
- (void)GetActiveBspCentroid:(float *)_center_x center_y:(float *)_center_y center_z:(float *)_center_z
{
	*_center_x = 0;
	*_center_y = 0;
	*_center_z = 0;
	if (m_pBsp)
		[[self getActiveBsp] getMapCentroid:_center_x center_y:_center_y center_z:_center_z];
}
@synthesize _mapfile;
@synthesize _texManager;
@synthesize m_ActiveBsp;
@synthesize m_Version;
@synthesize m_Magic;
@synthesize m_BspCount;
@synthesize m_pBspInfo;
@synthesize m_BspNames;
@synthesize m_pBsp;
@end
