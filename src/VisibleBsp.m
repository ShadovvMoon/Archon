//
//  VisibleBsp.m
//  SparkEdit
//
//  Created by Michael Edgar on Mon Jul 19 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "VisibleBsp.h"
#import "NSFile.h"
#import "HaloMap.h"
#import "BitmapTag.h"
#import "FileConstants.h"
@implementation VisibleBsp
- (id)init
{
	if (self = [super init])
	{
		  m_pMapFile = NULL;
		m_BspMagic = 0;
		m_Magic = 0;
		m_SubMeshCount = 0;
		m_ActiveBsp = 0;
		m_pMesh = 0;
		m_pWeather = NULL;
		m_pClusters = NULL;

		m_Centroid[0] = 0;
		m_Centroid[1] = 0;
		m_Centroid[2] = 0;
		m_CentroidCount = 0;
		m_TriTotal = 0;

		m_MapBox.min[0] = 40000;
		m_MapBox.min[1] = 40000;
		m_MapBox.min[2] = 40000;
		m_MapBox.max[0] = -40000;
		m_MapBox.max[1] = -40000;
		m_MapBox.max[2] = -40000;
	}
	return self;
}
- (void) Initialize:(NSFile *)pMapFile magic:( unsigned long )magic bsp_magic:( unsigned long )bsp_magic map:(HaloMap*)map
{
	m_pMapFile = [pMapFile retain];
	m_Magic = magic;
	m_BspMagic = bsp_magic;
	myMap = [map retain];
}
- (SUBMESH_INFO*)m_pMesh:(long)idx
{
	return &m_pMesh[idx];
}
- (unsigned long)m_SubMeshCount
{
	return m_SubMeshCount;
}
- (void) LoadVisibleBsp:(unsigned long)BspHdrOffset version:(unsigned long)version
{
	[m_pMapFile seekToOffset:BspHdrOffset];
	
	//read the BSP Header
	m_BspHeader.LightmapsTag = readReferenceFromFile(m_pMapFile,m_Magic);
	[m_pMapFile skipBytes:0x25 * sizeof(unsigned long)];
	m_BspHeader.Shaders = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.CollBspHeader = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.Nodes = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	[m_pMapFile skipBytes:6 * sizeof(unsigned long)];
	m_BspHeader.Leaves = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.LeafSurfaces = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.SubmeshTriIndices = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.SubmeshHeader = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.Chunk10 = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.Chunk11 = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.Chunk12 = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.Clusters = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.ClusterDataSize = [m_pMapFile readDword];
	m_BspHeader.unk11 = [m_pMapFile readDword];
	m_BspHeader.Chunk14 = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.ClusterPortals = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.Chunk16a = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.BreakableSurfaces = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.FogPlanes = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.FogRegions = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.FogOrWeatherPallette = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.Chunk16f = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.Chunk16g = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.Weather = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.WeatherPolyhedra = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.Chunk19 = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.Chunk20 = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.PathfindingSurface = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.Chunk24 = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.BackgroundSound = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.SoundEnvironment = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.SoundPASDataSize = [m_pMapFile readDword];
	m_BspHeader.unk12 = [m_pMapFile readDword];
	m_BspHeader.Chunk25 = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.Chunk26 = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.Chunk27 = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.Markers = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.DetailObjects = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	m_BspHeader.RuntimeDecals = readReflexiveFromFile(m_pMapFile,m_BspMagic);
	[m_pMapFile skipBytes:9 * sizeof(unsigned long)];
	
	[self LoadMaterialMeshHeaders];
    [self LoadPcSubmeshes];

}
- (void) ResetBoundingBox
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
}
- (void)dealloc
{
	free(m_pMesh);

	[myMap release];
	free(m_pLightmaps);

	[super dealloc];
}
- (void) LoadPcSubmeshTextures
{
  int i;

  SUBMESH_INFO *pPcSubMesh;
  for(i=0; i<m_SubMeshCount; i++)
  {
    pPcSubMesh = &m_pMesh[i];
	NSLog([NSString stringWithFormat:@"Loading Submesh Texture[%d]\n", i]);
	

	long identOfBitm = [myMap baseBitmapIdentForShader:pPcSubMesh->header.ShaderTag.TagId file:m_pMapFile];
	BitmapTag *bitm = [myMap bitmForIdent:identOfBitm];
	unsigned int *texData = [bitm imagePixelsForImageIndex:0];
	pPcSubMesh->textures = malloc(1 * sizeof(GLuint));
	glGenTextures( 1 , pPcSubMesh->textures );
	glBindTexture( GL_TEXTURE_2D, pPcSubMesh->textures[0] );
	glTexImage2D( GL_TEXTURE_2D, 0, 4, [bitm textureSizeForImageIndex:0].width,
				[bitm textureSizeForImageIndex:0].height, 0, GL_RGBA,
				GL_UNSIGNED_BYTE, texData );
	[bitm freeImagePixels];
	}
}
- (void) LoadPcSubmeshes
{
  int i, v;

  SUBMESH_INFO *pPcSubMesh;

  [self ResetBoundingBox];

  for(i=0; i<m_SubMeshCount; i++)
  {
    pPcSubMesh = &m_pMesh[i];

    NSLog([NSString stringWithFormat:@"Loading Submesh[%d]\n", i]);
	
	

    pPcSubMesh->VertCount = pPcSubMesh->header.VertexCount1;
    pPcSubMesh->IndexCount = pPcSubMesh->header.VertIndexCount;

    /* Allocate vertex and index arrays */ 
    pPcSubMesh->pIndex = malloc(pPcSubMesh->IndexCount * sizeof(TRI_INDICES));
	pPcSubMesh->pVert = malloc(pPcSubMesh->VertCount * sizeof(UNCOMPRESSED_BSP_VERT));
    pPcSubMesh->pLightmapVert = malloc(pPcSubMesh->VertCount * sizeof(UNCOMPRESSED_LIGHTMAP_VERT));

    /* Ahoy - read in that thar data argghh */ 
	[m_pMapFile seekToOffset:pPcSubMesh->header.PcVertexDataOffset];
	
	//read in the uncompressed BSP Verts
	int x;
	for (x=0;x<pPcSubMesh->VertCount;x++)
		pPcSubMesh->pVert[x] = readUncompressedBspVert(m_pMapFile);
	for (x=0;x<pPcSubMesh->VertCount;x++)
		pPcSubMesh->pLightmapVert[x] = readUncompressedLightmapVert(m_pMapFile);
   
    [m_pMapFile seekToOffset:pPcSubMesh->header.VertIndexOffset];
	for (x=0;x<pPcSubMesh->IndexCount;x++)
		pPcSubMesh->pIndex[x] = readIndexFromFile(m_pMapFile);

    //update tri count
    m_TriTotal += pPcSubMesh->VertCount;

    /* Update the map extents info for analysis */ 
    for(v=0; v<pPcSubMesh->VertCount; v++)
    {
      //TRACE("%d %f %f\n", v, pPcSubMesh->pLightmapData[v].uv[0], pPcSubMesh->pLightmapData[v].uv[1]);
      [self UpdateBoundingBox:i pCoord:pPcSubMesh->pVert[v].vertex_k version:7];
    }
    //pPcSubMesh->RenderTextureIndex = 
    pPcSubMesh->RenderTextureIndex = [myMap baseBitmapIdentForShader:pPcSubMesh->header.ShaderTag.TagId file:m_pMapFile];
  }


}
- (void)GetMapCentroid:(float*)cx cy:(float*)cy cz:(float*)cz
{
	if (m_CentroidCount == 0)
	{
		*cx = 0;
		*cy = 0;
		*cz = 0;
	}
	else
	{
    *cx = m_Centroid[0]/m_CentroidCount;
    *cy = m_Centroid[1]/m_CentroidCount;
    *cz = m_Centroid[2]/m_CentroidCount;
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
- (void) LoadMaterialMeshHeaders
{
  int i, j, hdr_count;
  unsigned long offset;
//  NSString *ref;
//  char *pShaderName;
//  BOOL ret;

  //load the submesh index
  m_pLightmaps = malloc(sizeof(BSP_LIGHTMAP) * m_BspHeader.SubmeshHeader.chunkcount);
  [m_pMapFile seekToOffset:m_BspHeader.SubmeshHeader.offset];
  int x;
  m_SubMeshCount = 0;
  for (x=0;x<m_BspHeader.SubmeshHeader.chunkcount;x++)
  {

	m_pLightmaps[x].LightmapIndex = [m_pMapFile readWord];
	m_pLightmaps[x].unk1 = [m_pMapFile readWord];
	[m_pMapFile skipBytes:4*sizeof(unsigned long)];
	m_pLightmaps[x].Material = readReflexiveFromFile(m_pMapFile,m_BspMagic);
    m_SubMeshCount += m_pLightmaps[x].Material.chunkcount;
  
  }

  


  //load the submesh headers
  m_pMesh = malloc(m_SubMeshCount * sizeof(SUBMESH_INFO));
  hdr_count = 0;

  for(i=0; i<m_BspHeader.SubmeshHeader.chunkcount; i++)
  {
    for(j=0; j<m_pLightmaps[i].Material.chunkcount; j++)
    {
      offset = m_pLightmaps[i].Material.offset + sizeof(MATERIAL_SUBMESH_HEADER)*j;
      [m_pMapFile seekToOffset:offset];
	  //read in the submesh header
	  //gay!
	  m_pMesh[hdr_count].header = readMaterialSubmeshHeader(m_pMapFile,m_BspMagic);
	  
	  //done reading in the submesh header
	  
     
      //subtract magic from offsets
      m_pMesh[hdr_count].header.Vert_Reflexive -= m_BspMagic;
      m_pMesh[hdr_count].header.CompVert_Reflexive -= m_BspMagic;
      m_pMesh[hdr_count].header.VertexDataOffset -= m_BspMagic;
      m_pMesh[hdr_count].header.PcVertexDataOffset -= m_BspMagic;
      m_pMesh[hdr_count].header.VertIndexOffset = sizeof(TRI_INDICES)*m_pMesh[hdr_count].header.VertIndexOffset + 
                                                  m_BspHeader.SubmeshTriIndices.offset;
      
      //load the shader name string (for output window)
      //ref = CheckForReference(m_pMapFile, m_pMesh[hdr_count].header.ShaderTag.NamePtr, m_Magic);
//      pShaderName = ref.GetBuffer(128);
//      strncpy(m_pMesh[hdr_count].shader_name, pShaderName, 128);
//      ref.ReleaseBuffer();

      m_pMesh[hdr_count].LightmapIndex = m_pLightmaps[i].LightmapIndex;

      hdr_count++;
    }
  }
}

@end
