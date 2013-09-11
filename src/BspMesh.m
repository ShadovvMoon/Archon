//
//  BspMesh.m
//  swordedit
//
//  Created by sword on 10/28/07.
//  Copyright 2007 sword Inc. All rights reserved.
//

#import "BspMesh.h"
#import "BitmapTag.h"

#import "TextureManager.h"

@implementation BspMesh
- (id)initWithMapAndBsp:(HaloMap *)map bsp_class:(BSP *)bsp_class texManager:(TextureManager *)texManager bsp_magic:(unsigned long)bsp_magic
{
	if ((self = [super init]) != nil)
	{
		m_SubMeshCount = 0;
		m_activeBsp = 0;
		m_pMesh = 0;
		m_pWeather = nil;
		m_pClusters = nil;
		
		m_Centroid[0] = 0;
		m_Centroid[1] = 0;
		m_Centroid[2] = 0;
		m_TriTotal = 0;
		int x;
		for (x = 0; x < 3; x++)
		{
			m_MapBox.min[x] = 40000;
			m_MapBox.max[x] = -40000;
		}
		
		texturesLoaded = FALSE;
		
		_bspParent = [bsp_class retain];
		_mapfile = [map retain];
		_texManager = [texManager retain];
		_bspMagic = bsp_magic;
	}
	return self;
}
- (void)dealloc
{
	#ifdef __DEBUG__
	NSLog(@"Deallocating BSP Mesh!");
	#endif
	
	[_bspParent release];
	[_mapfile release];
	[_texManager release];
	
	if (m_pMesh->textures)
		free(m_pMesh->textures);
	if (m_pMesh->pVert)
		free(m_pMesh->pVert);
	if (m_pMesh->pIndex)
		free(m_pMesh->pIndex);
	if (m_pMesh->pLightmapVert)
		free(m_pMesh->pLightmapVert);
	free(m_pMesh);
	free(m_pWeather);
	free(m_pLightmaps);
	free(m_pClusters);
	
	#ifdef __DEBUG__
	NSLog(@"BSP Mesh deallocated!");
	#endif
	
	[super dealloc];
}
- (void)freeBSPAllocation
{
	
}
- (SUBMESH_INFO *)m_pMesh:(long)index
{
	return &m_pMesh[index];
}
- (unsigned long)m_SubMeshCount
{
	return m_SubMeshCount;
}
- (void)LoadVisibleBsp:(unsigned long)BspHeaderOffset version:(unsigned long)version
{
	[_mapfile seekToAddress:BspHeaderOffset];
	m_BspHeader.LightmapsTag = [_mapfile readReference];
	NSLog(@"Lightmap tag stuff: ID:[0x%x], name:[%@]", m_BspHeader.LightmapsTag.TagId, [[_mapfile tagForId:m_BspHeader.LightmapsTag.TagId] tagName]);
	[_mapfile skipBytes:(0x25 * sizeof(long))];
	m_BspHeader.Shaders = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.CollBspHeader = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Nodes = [_mapfile readBspReflexive:_bspMagic];
	[_mapfile skipBytes:(6 * sizeof(long))];
	m_BspHeader.Leaves = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.LeafSurfaces = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.SubmeshTriIndices = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.SubmeshHeader = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Chunk10 = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Chunk11 = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Chunk12 = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Clusters = [_mapfile readBspReflexive:_bspMagic];
	[_mapfile readLong:&m_BspHeader.ClusterDataSize];
	[_mapfile readLong:&m_BspHeader.unk11];
	m_BspHeader.Chunk14 = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.ClusterPortals = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Chunk16a = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.BreakableSurfaces = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.FogPlanes = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.FogRegions = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.FogOrWeatherPallette = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Chunk16f = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Chunk16g = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Weather = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.WeatherPolyhedra = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Chunk19 = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Chunk20 = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.PathfindingSurface = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Chunk24 = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.BackgroundSound = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.SoundEnvironment = [_mapfile readBspReflexive:_bspMagic];
	[_mapfile readLong:&m_BspHeader.SoundPASDataSize];
	[_mapfile readLong:&m_BspHeader.unk12];
	m_BspHeader.Chunk25 = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Chunk26 = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Chunk27 = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Markers = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.DetailObjects = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.RuntimeDecals = [_mapfile readBspReflexive:_bspMagic];
	[_mapfile skipBytes:(9 * sizeof(unsigned long))];
	
	[self LoadMaterialMeshHeaders];
	[self LoadCollisionMeshHeaders];
	[self LoadPcSubmeshes];
}
- (void)LoadPcSubmeshes
{
	int i, v, x;
	SUBMESH_INFO *pPcSubMesh;
	[self ResetBoundingBox];
	for (i =0; i < m_SubMeshCount; i++)
	{
		pPcSubMesh = &m_pMesh[i];
		pPcSubMesh->VertCount = pPcSubMesh->header.VertexCount1;
		pPcSubMesh->IndexCount = pPcSubMesh->header.VertIndexCount;
		
		// In Bob's words, "Allocate vertex and index arrays"
		pPcSubMesh->pIndex = malloc(pPcSubMesh->IndexCount * sizeof(TRI_INDICES));
		pPcSubMesh->pVert = malloc(pPcSubMesh->VertCount * sizeof(UNCOMPRESSED_BSP_VERT));
		pPcSubMesh->pCompVert = malloc(pPcSubMesh->VertCount * sizeof(COMPRESSED_BSP_VERT));
		pPcSubMesh->pLightmapVert = malloc(pPcSubMesh->VertCount * sizeof(UNCOMPRESSED_LIGHTMAP_VERT));
		
		[_mapfile seekToAddress:pPcSubMesh->header.PcVertexDataOffset];
		//NSLog(@"%d", pPcSubMesh->header.PcVertexDataOffset);
		for (v = 0; v < pPcSubMesh->VertCount; v++)
			pPcSubMesh->pVert[v] = [_bspParent readUncompressedBspVert]; 
		for (v = 0; v < pPcSubMesh->VertCount; v++)
			pPcSubMesh->pLightmapVert[v] = [_bspParent readUncompressedLightmapVert];
		[_mapfile seekToAddress:pPcSubMesh->header.VertIndexOffset];
		for (v = 0; v < pPcSubMesh->IndexCount; v++)
			pPcSubMesh->pIndex[v] = [_bspParent readIndexFromFile];
		m_TriTotal += pPcSubMesh->VertCount;
		// OH GEE
		// In bob's words, "Update the map extents for analysis
		for (x = 0; x < pPcSubMesh->VertCount; x++)
			[self UpdateBoundingBox:i pCoord:pPcSubMesh->pVert[x].vertex_k version:7];
		
		
	
		
		
		
		pPcSubMesh->RenderTextureIndex = [[_mapfile bitmTagForShaderId:pPcSubMesh->header.ShaderTag.TagId] idOfTag];
	}
}

-(void)writePcSubmeshes
{
	int i, v, x;
	SUBMESH_INFO *pPcSubMesh;
	for (i =0; i < m_SubMeshCount; i++)
	{
		pPcSubMesh = &m_pMesh[i];
		pPcSubMesh->VertCount = pPcSubMesh->header.VertexCount1;
		pPcSubMesh->IndexCount = pPcSubMesh->header.VertIndexCount;

		int address = pPcSubMesh->header.PcVertexDataOffset;
		for (v = 0; v < pPcSubMesh->VertCount; v++)
		{
			[_mapfile writeAnyDataAtAddress:&(pPcSubMesh->pVert[v]) size:sizeof(UNCOMPRESSED_BSP_VERT) address:address];
			address+=sizeof(UNCOMPRESSED_BSP_VERT);
		}
		for (v = 0; v < pPcSubMesh->VertCount; v++)
		{
			[_mapfile writeAnyDataAtAddress:&(pPcSubMesh->pLightmapVert[v]) size:sizeof(UNCOMPRESSED_LIGHTMAP_VERT) address:address];
			address+=sizeof(UNCOMPRESSED_LIGHTMAP_VERT);
		}

		address = pPcSubMesh->header.VertIndexOffset;
		for (v = 0; v < pPcSubMesh->IndexCount; v++)
		{
			[_mapfile writeAnyDataAtAddress:&(pPcSubMesh->pIndex[v]) size:6 address:address];
			address+=6;
		}
	}

		unsigned long offset;
		int j;
		int cv=0;
		for (i = 0; i < m_BspHeader.CollBspHeader.chunkcount; i++)
		{
			for (j = 0; j < m_pCollisions[i].Material.chunkcount; j++)
			{
				offset = (m_pCollisions[i].Material.offset + (16 * j));
				[_mapfile writeAnyDataAtAddress:&coll_verts[cv].x size:4 address:offset];
				[_mapfile writeAnyDataAtAddress:&coll_verts[cv].y size:4 address:offset+4];
				[_mapfile writeAnyDataAtAddress:&coll_verts[cv].z size:4 address:offset+8];
				cv++;
			}
		}
	
}

- (void)LoadPcSubmeshTextures
{
	int i;
	
	if (texturesLoaded)
		return;
	
	NSLog(@"SUbmeshes: %d", m_SubMeshCount);
	
	for (i = 0; i < m_SubMeshCount; i++)
	{
		
		int gm = 1;
		if (gm)
		{
		
			m_pMesh[i].DefaultBitmapIndex = [[_mapfile bitmTagForShaderId:m_pMesh[i].header.ShaderTag.TagId] idOfTag];
			//m_pMesh[i].DefaultBitmapIndex = m_BspHeader.LightmapsTag.TagId;
			
			[_texManager loadTextureOfIdent:m_pMesh[i].DefaultBitmapIndex subImage:0];
			//[_texManager loadTextureOfIdent:m_BspHeader.LightmapsTag.TagId subImage:0];
			
			/*
			NSMutableArray *bitmaps = [_mapfile bitmsTagForShaderId:m_pMesh[i].header.ShaderTag.TagId];
			NSLog(@"%d", [bitmaps count]);
			if ([bitmaps count] > 0)
			{
				m_pMesh[i].DefaultBitmapIndex = [[bitmaps objectAtIndex:0] idOfTag];
				[_texManager loadTextureOfIdent:m_pMesh[i].DefaultBitmapIndex subImage:0];
				w
				int i;
				for (i=0;i<[bitmaps count]; i++)
				{
					NSLog(@"BLAAAHHH %@", [[bitmaps objectAtIndex:i] tagName]);
					[_texManager loadTextureOfIdent:[[bitmaps objectAtIndex:i] idOfTag] subImage:0];
				}
			}
			else
			{
				m_pMesh[i].DefaultBitmapIndex  = 0xFFFFFFFFF;
			}
			*/
			
		}
		else
		{
		
		//m_pMesh[i].DefaultBitmapIndex = [[_mapfile bitmTagForShaderId:m_pMesh[i].header.ShaderTag.TagId] idOfTag];
		m_pMesh[i].DefaultBitmapIndex = m_BspHeader.LightmapsTag.TagId;
		
		[_texManager loadTextureOfIdent:m_pMesh[i].DefaultBitmapIndex subImage:0];
		//[_texManager loadTextureOfIdent:m_BspHeader.LightmapsTag.TagId subImage:0];
		
		
		}
		
	}
	texturesLoaded = TRUE;
}






//OFFSETS
//9DC68
//F4F10 FOUND!
//164578




- (void)LoadCollisionMeshHeaders
{
	int am = 0;
	int pla = 0;
	
		if (!am)
		{
			if (!pla)
			{
				
			unsigned long offset;
			int x, i, j, hdr_count;
			
			m_pCollisions = malloc(sizeof(BSP_COLLISION) * m_BspHeader.CollBspHeader.chunkcount);
			
			[_mapfile seekToAddress:m_BspHeader.CollBspHeader.offset];
			int col_mesh_count = 0;
			for (x = 0; x< m_BspHeader.CollBspHeader.chunkcount; x++)
			{
				[_mapfile readShort:&m_pCollisions[x].LightmapIndex];
				[_mapfile readShort:&m_pCollisions[x].unk1];
				[_mapfile skipBytes:0x54-4];
				m_pCollisions[x].Material = [_mapfile readBspReflexive:_bspMagic]; //Verticies
				col_mesh_count += m_pCollisions[x].Material.chunkcount;
			}
			coll_count = col_mesh_count;
			coll_verts = malloc(col_mesh_count * sizeof(vert));
			hdr_count = 0;
			for (i = 0; i < m_BspHeader.CollBspHeader.chunkcount; i++)
			{
				for (j = 0; j < m_pCollisions[i].Material.chunkcount; j++)
				{
					offset = (m_pCollisions[i].Material.offset + (16 * j));
					[_mapfile seekToAddress:offset];
					
					
					long x;
					
					
					[_mapfile readFloat:&(coll_verts[hdr_count].x)];
					
					[_mapfile readFloat:&coll_verts[hdr_count].y];
					
					[_mapfile readFloat:&coll_verts[hdr_count].z];
					[_mapfile readFloat:&coll_verts[hdr_count].edge];
					
					
					hdr_count++;
				}
			}
			}
			else
			{
				unsigned long offset;
				int x, i, j, hdr_count;
				
				m_pCollisions = malloc(sizeof(BSP_COLLISION) * m_BspHeader.CollBspHeader.chunkcount);
				
				[_mapfile seekToAddress:m_BspHeader.CollBspHeader.offset];
				int col_mesh_count = 0;
				for (x = 0; x< m_BspHeader.CollBspHeader.chunkcount; x++)
				{
					[_mapfile readShort:&m_pCollisions[x].LightmapIndex];
					[_mapfile readShort:&m_pCollisions[x].unk1];
					[_mapfile skipBytes:0x0C-4];
					m_pCollisions[x].Material = [_mapfile readBspReflexive:_bspMagic]; //Verticies
					col_mesh_count += m_pCollisions[x].Material.chunkcount;
				}
				coll_count = col_mesh_count;
				coll_verts = malloc(col_mesh_count * sizeof(vert));
				hdr_count = 0;
				for (i = 0; i < m_BspHeader.CollBspHeader.chunkcount; i++)
				{
					for (j = 0; j < m_pCollisions[i].Material.chunkcount; j++)
					{
						offset = (m_pCollisions[i].Material.offset + (16 * j));
						[_mapfile seekToAddress:offset];
						
						
						long x;
						
						
						
						[_mapfile readLong:&(coll_verts[hdr_count].x)];
						
						[_mapfile readLong:&coll_verts[hdr_count].z];
						[_mapfile readLong:&coll_verts[hdr_count].edge];
						[_mapfile readLong:&coll_verts[hdr_count].y];
						
						
						
						
						hdr_count++;
					}
				}
			}
		}
		else
		{
			int i, v, x;
			SUBMESH_INFO *pPcSubMesh;
			[self ResetBoundingBox];
			
			int size;
			for (i =0; i < m_SubMeshCount; i++)
			{
				pPcSubMesh = &m_pMesh[i];
				pPcSubMesh->VertCount = pPcSubMesh->header.VertexCount1;
				size+=(pPcSubMesh->VertCount);
			}
			
			coll_count=size;
			coll_verts = malloc(size*sizeof(COMPRESSED_BSP_VERT));
			
			for (i =0; i < m_SubMeshCount; i++)
			{
				pPcSubMesh = &m_pMesh[i];
				pPcSubMesh->VertCount = pPcSubMesh->header.VertexCount1;
				pPcSubMesh->IndexCount = pPcSubMesh->header.VertIndexCount;
				
				// In Bob's words, "Allocate vertex and index arrays"
				pPcSubMesh->pIndex = malloc(pPcSubMesh->IndexCount * sizeof(TRI_INDICES));
				pPcSubMesh->pVert = malloc(pPcSubMesh->VertCount * sizeof(UNCOMPRESSED_BSP_VERT));
				pPcSubMesh->pCompVert = malloc(pPcSubMesh->VertCount * sizeof(COMPRESSED_BSP_VERT));
				pPcSubMesh->pLightmapVert = malloc(pPcSubMesh->VertCount * sizeof(UNCOMPRESSED_LIGHTMAP_VERT));
				
				[_mapfile seekToAddress:pPcSubMesh->header.VertexDataOffset];
				
				for (v = 0; v < pPcSubMesh->VertCount; v++)
					pPcSubMesh->pVert[v] = [_bspParent readUncompressedBspVert]; 
				for (v = 0; v < pPcSubMesh->VertCount; v++)
					pPcSubMesh->pLightmapVert[v] = [_bspParent readUncompressedLightmapVert]; 
				
				[_mapfile seekToAddress:pPcSubMesh->header.CompVert_Reflexive];
				for (v = 0; v < pPcSubMesh->VertCount; v++)
				{
					COMPRESSED_BSP_VERT verts = [_bspParent readCompressedBspVert]; 
					coll_verts[v].x= verts.vertex_k[0];
					coll_verts[v].y= verts.vertex_k[1];
					coll_verts[v].z= verts.vertex_k[2];
				}
			
				// OH GEE
				// In bob's words, "Update the map extents for analysis
		
			}
		}
		
	
}

-(int)coll_count
{
	return coll_count;
}

-(vert*)collision_verticies
{
	return coll_verts;
}

- (void)LoadMaterialMeshHeaders
{
	unsigned long offset;
	int x, i, j, hdr_count;
	
	m_pLightmaps = malloc(sizeof(BSP_LIGHTMAP) * m_BspHeader.SubmeshHeader.chunkcount);
	
	[_mapfile seekToAddress:m_BspHeader.SubmeshHeader.offset];
	m_SubMeshCount = 0;
	for (x = 0; x< m_BspHeader.SubmeshHeader.chunkcount; x++)
	{
		[_mapfile readShort:&m_pLightmaps[x].LightmapIndex];
		[_mapfile readShort:&m_pLightmaps[x].unk1];
		[_mapfile skipBytes:(4 * sizeof(unsigned long))];
		m_pLightmaps[x].Material = [_mapfile readBspReflexive:_bspMagic];
		m_SubMeshCount += m_pLightmaps[x].Material.chunkcount;
	}
	
	m_pMesh = malloc(m_SubMeshCount * sizeof(SUBMESH_INFO));
	hdr_count = 0;
	for (i = 0; i < m_BspHeader.SubmeshHeader.chunkcount; i++)
	{
		for (j =0; j < m_pLightmaps[i].Material.chunkcount; j++)
		{
			offset = (m_pLightmaps[i].Material.offset + (sizeof(MATERIAL_SUBMESH_HEADER) * j));
			[_mapfile seekToAddress:offset];
			m_pMesh[hdr_count].header = [_bspParent readMaterialSubmeshHeader];
			
			m_pMesh[hdr_count].header.Vert_Reflexive -= _bspMagic;
			m_pMesh[hdr_count].header.CompVert_Reflexive -= _bspMagic;
			m_pMesh[hdr_count].header.VertexDataOffset -= _bspMagic;
			m_pMesh[hdr_count].header.PcVertexDataOffset -= _bspMagic;
			m_pMesh[hdr_count].header.VertIndexOffset = ((sizeof(TRI_INDICES) * m_pMesh[hdr_count].header.VertIndexOffset)
														 + m_BspHeader.SubmeshTriIndices.offset);
			m_pMesh[hdr_count].LightmapIndex = m_pLightmaps[i].LightmapIndex;
			hdr_count++;
		}
	}
}


- (void)getMapCentroid:(float *)center_x center_y:(float *)center_y center_z:(float *)center_z
{
	if (m_CentroidCount == 0)
	{
		*center_x = 0;
		*center_y = 0;
		*center_z = 0;
	}
	else
	{
		*center_x = (m_Centroid[0]/m_CentroidCount);
		*center_y = (m_Centroid[1]/m_CentroidCount);
		*center_z = (m_Centroid[2]/m_CentroidCount);
	}
}
- (void)UpdateBoundingBox:(int)mesh_index pCoord:(float *)pCoord version:(unsigned long)version
{
  if((mesh_index >= 0)&&(mesh_index <m_SubMeshCount))
  {
    //update total map extents
    if(pCoord[0] > m_MapBox.max[0])m_MapBox.max[0] = pCoord[0];
    if(pCoord[1] > m_MapBox.max[1])m_MapBox.max[1] = pCoord[1];
    if(pCoord[2] > m_MapBox.max[2])m_MapBox.max[2] = pCoord[2];

    if(pCoord[0] < m_MapBox.min[0])m_MapBox.min[0] = pCoord[0];
    if(pCoord[1] < m_MapBox.min[1])m_MapBox.min[1] = pCoord[1];
    if(pCoord[2] < m_MapBox.min[2])m_MapBox.min[2] = pCoord[2];

    m_Centroid[0] += pCoord[0];
    m_Centroid[1] += pCoord[1];
    m_Centroid[2] += pCoord[2];
    m_CentroidCount++;

    //update current mesh extents
    if(pCoord[0] > m_pMesh[mesh_index].Box.max[0])m_pMesh[mesh_index].Box.max[0] = pCoord[0];
    if(pCoord[1] > m_pMesh[mesh_index].Box.max[1])m_pMesh[mesh_index].Box.max[1] = pCoord[1];
    if(pCoord[2] > m_pMesh[mesh_index].Box.max[2])m_pMesh[mesh_index].Box.max[2] = pCoord[2];
    
    if(pCoord[0] < m_pMesh[mesh_index].Box.min[0])m_pMesh[mesh_index].Box.min[0] = pCoord[0];
    if(pCoord[1] < m_pMesh[mesh_index].Box.min[1])m_pMesh[mesh_index].Box.min[1] = pCoord[1];
    if(pCoord[2] < m_pMesh[mesh_index].Box.min[2])m_pMesh[mesh_index].Box.min[2] = pCoord[2];
  }
}
- (void)ResetBoundingBox
{
  m_MapBox.min[0] = 40000;
  m_MapBox.min[1] = 40000;
  m_MapBox.min[2] = 40000;
  m_MapBox.max[0] = -40000;
  m_MapBox.max[1] = -40000;
  m_MapBox.max[2] = -40000;

  m_Centroid[0] = 0;
  m_Centroid[1] = 0;
  m_Centroid[2] = 0;
  m_CentroidCount = 0;
  #ifdef __DEBUG__
  NSLog(@"Bounding box reset!");
  #endif
}
- (void)ExportPcMeshToObj:(NSString *)path
{
	FILE *outFile;
	NSString *str;
	int i, x, j;
	float vertex[3];
	UInt face[3];
	
	outFile = fopen([path cString],"w+");
	if (!outFile)
	{
	}
	else
	{
		int base_count = 1;
		int vert_count = 1;
		
		for (i = 0; i < m_SubMeshCount; i++)
		{
			// lol thats tough
			//str = [str stringByAppendingString:[[[NSNumber numberWithInt:i] stringValue] stringByAppendingString:[NSString stringWithString:@"\n"]]];
			str = [NSString stringWithFormat:@"g Submesh_%d\n", i];
			//[str release];
			fwrite([str cString],[str cStringLength],1,outFile);
			for (x = 0; x < m_pMesh[i].VertCount; x++)
			{
				vertex[0] = m_pMesh[i].pVert[x].vertex_k[0];
				vertex[1] = m_pMesh[i].pVert[x].vertex_k[1];
				vertex[2] = m_pMesh[i].pVert[x].vertex_k[2];
				
				str = [NSString stringWithFormat:@"v %f %f %f\n", vertex[0], vertex[1], vertex[2]];
				fwrite([str cString],[str cStringLength],1,outFile);
				[str release];
				
				if ((x % 10) == 0)
				{
					str = [NSString stringWithFormat:@"#vertex %d %d (%d)\n", x, vert_count+=10, m_pMesh[i].VertCount];
					fwrite([str cString], [str cStringLength], 1, outFile);
					[str release];
				}
			}
			for (j = 0; j < m_pMesh[i].IndexCount; j++)
			{
				face[0] = m_pMesh[i].pIndex[j].tri_ind[0]+base_count;
				face[1] = m_pMesh[i].pIndex[j].tri_ind[1]+base_count;
				face[2] = m_pMesh[i].pIndex[j].tri_ind[2]+base_count;
		
				str = [NSString stringWithFormat:@"f %d %d %d\n", face[0], face[1], face[2]];
				fwrite([str cString], [str cStringLength], 1, outFile);
				[str release];
			}
			base_count += m_pMesh[i].VertCount;
		}
	}
	fclose(outFile);
}
/*
ExportPcMeshToObj(CString path)
{
  CStdioFile OutFile;
  CString str;
  int i,v,f;
  float vertex[3];
  UINT face[3];

  if(!OutFile.Open(path, CFile::modeCreate|CFile::modeWrite))
  {
    AfxMessageBox("Failed to create exported mesh file.");
  }
  else
  {
    int base_count=1;
    int vert_count=1;
    for(i=0; i<m_SubMeshCount; i++)
    {
      str.Format("g Submesh_%03d\n", i);
      OutFile.WriteString(str);

      for(v=0; v<m_pMesh[i].VertCount; v++)
      {
        vertex[0] = m_pMesh[i].pVert[v].vertex_k[0];
        vertex[1] = m_pMesh[i].pVert[v].vertex_k[1];
        vertex[2] = m_pMesh[i].pVert[v].vertex_k[2];

        str.Format("v %f %f %f\n", vertex[0], vertex[1], vertex[2]);
        OutFile.WriteString(str);

        if((v%10)==0)
        {
          str.Format("#vertex %d %d (%d)\n", v, vert_count+=10,m_pMesh[i].VertCount);
          OutFile.WriteString(str);
        }
      }

      for(f=0; f<m_pMesh[i].IndexCount; f++)
      {
        face[0] = m_pMesh[i].pIndex[f].tri_ind[0]+base_count;
        face[1] = m_pMesh[i].pIndex[f].tri_ind[1]+base_count;
        face[2] = m_pMesh[i].pIndex[f].tri_ind[2]+base_count;

        str.Format("f %d %d %d\n", face[0], face[1], face[2]);
        OutFile.WriteString(str);
      }
      base_count+=m_pMesh[i].VertCount;
    }    
  }

  OutFile.Close();
}
*/
@synthesize _mapfile;
@synthesize _bspParent;
@synthesize _texManager;
@synthesize m_SubMeshCount;
@synthesize _bspMagic;
@synthesize m_pMesh;
@synthesize m_pWeather;
@synthesize m_pLightmaps;
@synthesize m_pClusters;
@synthesize texturesLoaded;
@synthesize m_CentroidCount;
@synthesize m_activeBsp;
@synthesize m_TriTotal;
@end
