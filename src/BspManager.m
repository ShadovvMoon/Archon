//
//  BspManager.m
//  SparkEdit
//
//  Created by Michael Edgar on Mon Jul 19 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "BspManager.h"
#import "VisibleBsp.h"
#import "NSFile.h"
#import "HaloMap.h"
@implementation BspManager
- (void)Initialize:(NSFile *)pMapFile magic:(long)magic map:(HaloMap *)map
{
  m_pMapFile = [pMapFile retain];
  m_Magic = magic;
  myMap = map;
}
- (void)dealloc
{

	[m_BspNames release];
	[m_pBsp release];
	[m_pMapFile close];
	[m_pMapFile release];
	free(m_pBspInfo);

	[myMap release];
	[super dealloc];
}
- (id)init
{
	if (self = [super init])
	{
		  m_pMapFile = NULL;
		m_Magic = 0;
		m_pBspInfo = NULL;
		m_pBsp = NULL;
		m_ActiveBsp = 0;
		m_BspCount = 0;
		m_Version = 0;
	}
	return self;
}
- (void) LoadBspTextures
{
	int x;
	for (x=0;x<[m_pBsp count];x++)
		[(VisibleBsp*)[m_pBsp objectAtIndex:x] LoadPcSubmeshTextures];
}
- (unsigned short)GetNumberOfBsps
{
	return [m_pBsp count];
}
- (void)setActiveBsp:(unsigned short)bsp
{
	m_ActiveBsp = bsp;
}
- (VisibleBsp *)getActiveBsp
{
	return (VisibleBsp*)[m_pBsp objectAtIndex:m_ActiveBsp];
}
- (unsigned long)GetActiveBspSubmeshCount
{
	unsigned long mesh_count;
	
	if (m_pBsp)
		mesh_count = [[self getActiveBsp] m_SubMeshCount];
	else
		mesh_count = 0;
	return mesh_count;
}
- (void)GetActiveBspCentroid:(float*)x y:(float*)y z:(float*)z
{
	*x=0;
	*y=0;
	*z=0;
	if (m_pBsp)
		[[self getActiveBsp] GetMapCentroid:x cy:y cz:z];
}
- (SUBMESH_INFO*)GetActiveBspPcSubmesh:(unsigned long) mesh_index
{
	SUBMESH_INFO *pMesh = NULL;
	pMesh = [[self getActiveBsp] m_pMesh:mesh_index];
	return pMesh;
}
- (HaloMap*)myMap
{
	return [myMap retain];
}
- (void)LoadVisibleBspInfo:(reflexive) BspChunk version: (unsigned long) version
{
//	NSString *temp;
	unsigned long hdr;
	int i=0;
	unsigned long offset;
	m_Version = version;
	
	if (BspChunk.chunkcount> 0)
	{
		m_pBspInfo = malloc(sizeof(SCENARIO_BSP_INFO) * BspChunk.chunkcount);
		m_pBsp = [[NSMutableArray alloc] initWithCapacity:BspChunk.chunkcount];
		[m_pMapFile seekToOffset:BspChunk.offset];
		
		for (i=0; i<BspChunk.chunkcount;i++)
		{
			
			VisibleBsp *tempBsp = [[VisibleBsp alloc] init];
			
			//read in the Scenario Bsp Info
			m_pBspInfo[i] = readBspInfoFromFile(m_pMapFile);
			offset = [m_pMapFile offset];
			[tempBsp Initialize:m_pMapFile magic:m_Magic bsp_magic:m_pBspInfo[i].Magic map:myMap];
			[m_pMapFile seekToOffset:m_pBspInfo[i].BspStart];
			hdr = [m_pMapFile readDword];
			hdr -= m_pBspInfo[i].Magic;
			[tempBsp LoadVisibleBsp:hdr version:version];
		
			[m_pMapFile seekToOffset:offset];
			[m_pBsp addObject:tempBsp];
		}
	}

}

@end
