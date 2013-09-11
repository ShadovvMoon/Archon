// VisibleBsp.cpp: implementation of the CVisibleBsp class.
//
//////////////////////////////////////////////////////////////////////

#include "stdafx.h"
#include "sparkedit.h"
#include "VisibleBsp.h"
#include "OutputPane.h"
#include "ShaderManager.h"
#include "TagManager.h"

extern COutputPane *g_pOutput;
extern CShaderManager gShaderManager;
extern CTagManager gTagManager;


#ifdef _DEBUG
#undef THIS_FILE
static char THIS_FILE[]=__FILE__;
#define new DEBUG_NEW
#endif

/*-------------------------------------------------------------------
 * Name: CVisibleBsp()
 * Description:
 *   
 *-----------------------------------------------------------------*/
CVisibleBsp::CVisibleBsp()
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

/*-------------------------------------------------------------------
 * Name: ~CVisibleBsp()
 * Description:
 *   
 *-----------------------------------------------------------------*/
CVisibleBsp::~CVisibleBsp()
{
  Cleanup();
}

/*-------------------------------------------------------------------
 * Name: Cleanup()
 * Description:
 *   
 *-----------------------------------------------------------------*/
void CVisibleBsp::Cleanup(void)
{
  int i;

  if(m_pMesh)
  {
    for(i=0; i<m_SubMeshCount; i++)
    {
      if(m_pMesh[i].pCompVert)
        delete [] m_pMesh[i].pCompVert;

      if(m_pMesh[i].pVert)
        delete [] m_pMesh[i].pVert;
      
      if(m_pMesh[i].pIndex)
        delete [] m_pMesh[i].pIndex;
      
      if(m_pMesh[i].pTextureData)
        delete [] m_pMesh[i].pTextureData;

      if(m_pMesh[i].pLightmapVert)
        delete [] m_pMesh[i].pLightmapVert;

      if(m_pMesh[i].pCompLightmapVert)
        delete [] m_pMesh[i].pCompLightmapVert;
    }
    
    delete [] m_pMesh;
    m_pMesh = 0;
  }

  if(m_pLightmaps)
    delete [] m_pLightmaps;
  m_pLightmaps = 0;

  if(m_pWeather)
    delete [] m_pWeather;
  m_pWeather = NULL;

  if(m_pClusters)
    delete [] m_pClusters;
  m_pClusters = NULL;


  m_CollBsp.Cleanup();

  m_pMapFile = NULL;
  m_BspMagic = 0;
  m_Magic = 0;
  m_SubMeshCount = 0;
}

/*-------------------------------------------------------------------
 * Name: LoadVisibleBsp()
 * Description:
 *   
 *-----------------------------------------------------------------*/
void CVisibleBsp::LoadVisibleBsp(UINT BspHdrOffset, UINT version)
{
  // read the header
  m_pMapFile->Seek(BspHdrOffset, 0);
  m_pMapFile->Read(&m_BspHeader, sizeof(m_BspHeader));

  //UINT i = (UINT)&m_BspHeader.RuntimeDecals.Count - (UINT)&m_BspHeader;
  //m_pMapFile->Seek(BspHdrOffset, 0);
  //m_pMapFile->Write(&m_BspHeader, sizeof(m_BspHeader));

  m_BspHeader.LightmapsTag.NamePtr -= m_Magic;
  m_BspHeader.Shaders.Offset -=  m_BspMagic;
  m_BspHeader.CollBspHeader.Offset -= m_BspMagic;
  m_BspHeader.Nodes.Offset -= m_BspMagic;
  m_BspHeader.Leaves.Offset -= m_BspMagic;
  m_BspHeader.LeafSurfaces.Offset -= m_BspMagic;
  m_BspHeader.SubmeshTriIndices.Offset -= m_BspMagic;
  m_BspHeader.SubmeshHeader.Offset -= m_BspMagic;
  m_BspHeader.Chunk10.Offset -= m_BspMagic;
  m_BspHeader.Chunk11.Offset -= m_BspMagic;
  m_BspHeader.Chunk12.Offset -= m_BspMagic;
  m_BspHeader.Clusters.Offset -= m_BspMagic;
  m_BspHeader.Chunk14.Offset -= m_BspMagic;
  m_BspHeader.ClusterPortals.Offset -= m_BspMagic;
  //m_BspHeader.Chunk16a.Offset -= m_BspMagic;
  //m_BspHeader.Chunk16b.Offset -= m_BspMagic;
  //m_BspHeader.Chunk16c.Offset -= m_BspMagic;
  //m_BspHeader.Chunk16d.Offset -= m_BspMagic;
  //m_BspHeader.Chunk16e.Offset -= m_BspMagic;
  //m_BspHeader.Chunk16f.Offset -= m_BspMagic;
  //m_BspHeader.Chunk16g.Offset -= m_BspMagic;
  m_BspHeader.Weather.Offset -= m_BspMagic;
  m_BspHeader.WeatherPolyhedra.Offset -= m_BspMagic;
  m_BspHeader.Chunk19.Offset -= m_BspMagic;
  m_BspHeader.Chunk20.Offset -= m_BspMagic;
  m_BspHeader.PathfindingSurface.Offset -= m_BspMagic;
  m_BspHeader.BackgroundSound.Offset -= m_BspMagic;
  m_BspHeader.SoundEnvironment.Offset -= m_BspMagic;
  m_BspHeader.Chunk24.Offset -= m_BspMagic;
  m_BspHeader.Chunk25.Offset -= m_BspMagic;
  m_BspHeader.Chunk26.Offset -= m_BspMagic;
  m_BspHeader.Chunk27.Offset -= m_BspMagic;
  m_BspHeader.Markers.Offset -= m_BspMagic;
  m_BspHeader.DetailObjects.Offset -= m_BspMagic;
  m_BspHeader.RuntimeDecals.Offset -= m_BspMagic;
  
  gTagManager.ActivateLightmap(m_BspHeader.LightmapsTag.TagId);

  m_CollBsp.Initialize(m_pMapFile, m_BspMagic, m_Magic);
  m_CollBsp.LoadCollisionBsp(m_BspHeader.CollBspHeader.Offset);

  InitBspXrefs();

  LoadClusters();
  LoadWeather();

  TRACE("bsp decals:  %d\n", m_BspHeader.RuntimeDecals.Count);

  if(version == 5)
  {
    LoadMaterialMeshHeaders();
    LoadXboxSubmeshes();
  }
  else if(version == 7)
  {
    LoadMaterialMeshHeaders();
    LoadPcSubmeshes();
  }
}

/*-------------------------------------------------------------------
 * Name: Initialize()
 * Description:
 *   
 *-----------------------------------------------------------------*/
void CVisibleBsp::Initialize(CFile *pMapFile, UINT magic, UINT bsp_magic)
{
  m_pMapFile = pMapFile;
  m_Magic = magic;
  m_BspMagic = bsp_magic;
}

/*-------------------------------------------------------------------
 * Name: LoadPcSubmeshes()
 * Description:
 *   
 *-----------------------------------------------------------------*/
void CVisibleBsp::LoadPcSubmeshes()
{
  int i, v;
  CString str;
  SUBMESH_INFO *pPcSubMesh;

  ResetBoundingBox();

  for(i=0; i<m_SubMeshCount; i++)
  {
    pPcSubMesh = &m_pMesh[i];
    
    str.Format("Loading Submesh[%d]\n", i);
    g_pOutput->PostText(str, LOG_BLACK);

    pPcSubMesh->VertCount = pPcSubMesh->header.VertexCount1;
    pPcSubMesh->IndexCount = pPcSubMesh->header.VertIndexCount;

    /* Allocate vertex and index arrays */ 
    pPcSubMesh->pIndex = new TRI_INDICES[pPcSubMesh->IndexCount];
    pPcSubMesh->pVert = new UNCOMPRESSED_BSP_VERT[pPcSubMesh->VertCount];
    pPcSubMesh->pLightmapVert = new UNCOMPRESSED_LIGHTMAP_VERT[pPcSubMesh->VertCount];

    /* Ahoy - read in that thar data argghh */ 
    m_pMapFile->Seek(pPcSubMesh->header.PcVertexDataOffset, 0);
    m_pMapFile->Read(pPcSubMesh->pVert, pPcSubMesh->VertCount*sizeof(UNCOMPRESSED_BSP_VERT));
    m_pMapFile->Read(pPcSubMesh->pLightmapVert, pPcSubMesh->VertCount*sizeof(UNCOMPRESSED_LIGHTMAP_VERT));

    m_pMapFile->Seek(pPcSubMesh->header.VertIndexOffset, 0);
    m_pMapFile->Read(pPcSubMesh->pIndex, pPcSubMesh->IndexCount*sizeof(TRI_INDICES));

    //update tri count
    m_TriTotal += pPcSubMesh->VertCount;

    /* Update the map extents info for analysis */ 
    for(v=0; v<pPcSubMesh->VertCount; v++)
    {
      //TRACE("%d %f %f\n", v, pPcSubMesh->pLightmapData[v].uv[0], pPcSubMesh->pLightmapData[v].uv[1]);
      UpdateBoundingBox(i, pPcSubMesh->pVert[v].vertex_k, 7);
    }
    
    pPcSubMesh->RenderTextureIndex = gTagManager.GetBaseTextureIndex(pPcSubMesh->header.ShaderTag.TagId);
  }
}

/*-------------------------------------------------------------------
 * Name: LoadMaterialMeshHeaders()
 * Description:
 *   
 *-----------------------------------------------------------------*/
void CVisibleBsp::LoadMaterialMeshHeaders()
{
  int i, j, hdr_count;
  UINT offset;
  CString ref;
  char *pShaderName;
  BOOL ret;

  //load the submesh index
  m_pLightmaps = new BSP_LIGHTMAP[m_BspHeader.SubmeshHeader.Count];
  m_pMapFile->Seek(m_BspHeader.SubmeshHeader.Offset, 0);
  m_pMapFile->Read(m_pLightmaps, sizeof(BSP_LIGHTMAP)*m_BspHeader.SubmeshHeader.Count);

  m_SubMeshCount = 0;
  for(i=0; i<m_BspHeader.SubmeshHeader.Count; i++)
  {
    m_pLightmaps[i].Material.Offset -= m_BspMagic;
    m_SubMeshCount += m_pLightmaps[i].Material.Count; //calculate total number of submeshes for allocation
    //TRACE("%2d: %d %08X  (%d)\n", i, m_pLightmaps[i].Count, m_pLightmaps[i].Offset, m_SubMeshCount);
  }

  //load the submesh headers
  m_pMesh = new SUBMESH_INFO[m_SubMeshCount];
  ZeroMemory(m_pMesh, sizeof(SUBMESH_INFO)*m_SubMeshCount);
  hdr_count = 0;

  for(i=0; i<m_BspHeader.SubmeshHeader.Count; i++)
  {
    for(j=0; j<m_pLightmaps[i].Material.Count; j++)
    {
      offset = m_pLightmaps[i].Material.Offset + sizeof(MATERIAL_SUBMESH_HEADER)*j;
      m_pMapFile->Seek(offset, 0);
      ret = m_pMapFile->Read(&(m_pMesh[hdr_count].header), sizeof(MATERIAL_SUBMESH_HEADER));

      //subtract magic from offsets
      m_pMesh[hdr_count].header.Vert_Reflexive -= m_BspMagic;
      m_pMesh[hdr_count].header.CompVert_Reflexive -= m_BspMagic;
      m_pMesh[hdr_count].header.VertexDataOffset -= m_BspMagic;
      m_pMesh[hdr_count].header.PcVertexDataOffset -= m_BspMagic;
      m_pMesh[hdr_count].header.VertIndexOffset = sizeof(TRI_INDICES)*m_pMesh[hdr_count].header.VertIndexOffset + 
                                                  m_BspHeader.SubmeshTriIndices.Offset;
      
      //load the shader name string (for output window)
      ref = CheckForReference(m_pMapFile, m_pMesh[hdr_count].header.ShaderTag.NamePtr, m_Magic);
      pShaderName = ref.GetBuffer(128);
      strncpy(m_pMesh[hdr_count].shader_name, pShaderName, 128);
      ref.ReleaseBuffer();

      m_pMesh[hdr_count].LightmapIndex = m_pLightmaps[i].LightmapIndex;

      hdr_count++;
    }
  }
}

/*-------------------------------------------------------------------
 * Name: LoadXboxSubmeshes()
 * Description:
 *   
 *-----------------------------------------------------------------*/
void CVisibleBsp::LoadXboxSubmeshes()
{
  int i;
  CString str;
  SUBMESH_INFO *pSubMesh;

  ResetBoundingBox();

  for(i=0; i<m_SubMeshCount; i++)
  {
    pSubMesh = &m_pMesh[i];
    
    str.Format("Loading Submesh[%d]\n", i);
    g_pOutput->PostText(str, LOG_BLACK);

    pSubMesh->VertCount = pSubMesh->header.VertexCount1;
    pSubMesh->IndexCount = pSubMesh->header.VertIndexCount;

    /* Allocate vertex and index arrays */ 
    pSubMesh->pIndex = new TRI_INDICES[pSubMesh->IndexCount];
    pSubMesh->pCompVert = new COMPRESSED_BSP_VERT[pSubMesh->VertCount];
    pSubMesh->pVert = new UNCOMPRESSED_BSP_VERT[pSubMesh->VertCount];
    pSubMesh->pCompLightmapVert = new COMPRESSED_LIGHTMAP_VERT[pSubMesh->VertCount];
    pSubMesh->pLightmapVert = new UNCOMPRESSED_LIGHTMAP_VERT[pSubMesh->VertCount];

    /* Ahoy - read in that thar data argghh */ 
    m_pMapFile->Seek(pSubMesh->header.VertexDataOffset, 0);
    m_pMapFile->Read(pSubMesh->pCompVert, pSubMesh->VertCount*sizeof(COMPRESSED_BSP_VERT));

    m_pMapFile->Seek(pSubMesh->header.VertIndexOffset, 0);
    m_pMapFile->Read(pSubMesh->pIndex, pSubMesh->IndexCount*sizeof(TRI_INDICES));

    // read in compressed unknown (lightmap coords?) data
    REFLEXIVE reflexive_ptr;
    m_pMapFile->Seek(pSubMesh->header.CompVert_Reflexive, 0);
    m_pMapFile->Read(&reflexive_ptr, 12);
    reflexive_ptr.Offset -= m_BspMagic;
    m_pMapFile->Seek(reflexive_ptr.Offset, 0);
    m_pMapFile->Read(pSubMesh->pCompLightmapVert, pSubMesh->VertCount*sizeof(COMPRESSED_LIGHTMAP_VERT));

    //update tri count
    m_TriTotal += pSubMesh->VertCount;
    
    // Decompress verts and update the map extents info for analysis
    for(int v=0; v<pSubMesh->VertCount; v++)
    {
      pSubMesh->pVert[v].vertex_k[0] = pSubMesh->pCompVert[v].vertex_k[0];
      pSubMesh->pVert[v].vertex_k[1] = pSubMesh->pCompVert[v].vertex_k[1];
      pSubMesh->pVert[v].vertex_k[2] = pSubMesh->pCompVert[v].vertex_k[2];

      pSubMesh->pVert[v].uv[0] = pSubMesh->pCompVert[v].uv[0];
      pSubMesh->pVert[v].uv[1] = pSubMesh->pCompVert[v].uv[1];

      //note:  we don't use the normals/binormals/tangents, so skip them

      pSubMesh->pLightmapVert[v].uv[0] = DecompressShortToFloat(pSubMesh->pCompLightmapVert[v].comp_uv[0]);
      pSubMesh->pLightmapVert[v].uv[1] = DecompressShortToFloat(pSubMesh->pCompLightmapVert[v].comp_uv[1]);
      UpdateBoundingBox(v, pSubMesh->pCompVert[v].vertex_k, 5);
    }
    
    if(pSubMesh->pCompVert)
    {
      delete [] pSubMesh->pCompVert;
      pSubMesh->pCompVert = NULL;
    }

    if(pSubMesh->pCompLightmapVert)
    {
      delete [] pSubMesh->pCompLightmapVert;
      pSubMesh->pCompLightmapVert = NULL;
    }

    pSubMesh->RenderTextureIndex = gTagManager.GetBaseTextureIndex(pSubMesh->header.ShaderTag.TagId);
  }
}


/*-------------------------------------------------------------------
 * Name: ResetBoundingBox()
 * Description:
 *   
 *-----------------------------------------------------------------*/
void CVisibleBsp::ResetBoundingBox()
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

/*-------------------------------------------------------------------
 * Name: UpdateBoundingBox()
 * Description:
 *   
 *-----------------------------------------------------------------*/
void CVisibleBsp::UpdateBoundingBox(int mesh_index, float *pCoord, UINT version)
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

/*-------------------------------------------------------------------
 * Name: DumpBoundingBoxInfo()
 * Description:
 *   
 *-----------------------------------------------------------------*/
void CVisibleBsp::DumpBoundingBoxInfo(int mesh_index)
{
  CString str;

  if(mesh_index == -1)
  {
    str.Format("Map Extents:  (%.1f, %.1f, %.1f) to (%.1f, %.1f, %.1f)\n",
               m_MapBox.min[0],
               m_MapBox.min[1],
               m_MapBox.min[2],
               m_MapBox.max[0],
               m_MapBox.max[1],
               m_MapBox.max[2]);

    g_pOutput->PostText(str, LOG_BLUE);

    str.Format("Map Size:  %.1f x %.1f x %.1f\n",
               m_MapBox.max[0] - m_MapBox.min[0],
               m_MapBox.max[1] - m_MapBox.min[1],
               m_MapBox.max[2] - m_MapBox.min[2]);
    g_pOutput->PostText(str, LOG_BLUE);
  }
  else
  {
/*    str.Format("Submesh Extents:  (%.1f, %.1f, %.1f) to (%.1f, %.1f, %.1f)\n",
               m_MeshBox[mesh_index].min[0],
               m_MeshBox[mesh_index].min[1],
               m_MeshBox[mesh_index].min[2],
               m_MeshBox[mesh_index].max[0],
               m_MeshBox[mesh_index].max[1],
               m_MeshBox[mesh_index].max[2]);
    g_pOutput->PostText(str, LOG_BLUE);
    */
  }
}

/*-------------------------------------------------------------------
 * Name: GetMapCentroid()
 * Description:
 *   
 *-----------------------------------------------------------------*/
void CVisibleBsp::GetMapCentroid(float *cx, float *cy, float *cz)
{
  //*cx = (m_MapBox.max[0] + m_MapBox.min[0])/2.0f;
  //*cy = (m_MapBox.max[1] + m_MapBox.min[1])/2.0f;
  //*cz = (m_MapBox.max[2] + m_MapBox.min[2])/2.0f;

  if(m_CentroidCount == 0)
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

void CVisibleBsp::ExportPcMeshToObj(CString path)
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

void CVisibleBsp::ExportXboxMeshToObj(CString path)
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

void CVisibleBsp::LoadWeather()
{
  if(m_BspHeader.Weather.Count > 0)
  {  
    m_pWeather = new BSP_WEATHER[m_BspHeader.Weather.Count];
    m_pMapFile->Seek(m_BspHeader.Weather.Offset, 0);
    m_pMapFile->Read(m_pWeather, sizeof(BSP_WEATHER)*m_BspHeader.Weather.Count);   
  }
}

CString CVisibleBsp::GetMeshInfo(int mesh_index)
{
  CString info = "SparkEdit Error:  Invalid Mesh";

  if(mesh_index < m_SubMeshCount)
  {
    info.Format("Triangle Count: %d\r\n", m_pMesh[mesh_index].IndexCount);
    info += gTagManager.GetTagDescription(m_pMesh[mesh_index].header.ShaderTag.NamePtr);
  }

  return(info);
}

void CVisibleBsp::LoadClusters()
{
  if(m_BspHeader.Clusters.Count > 0)
  {
    m_pClusters = new BSP_CLUSTER[m_BspHeader.Clusters.Count];

    m_pMapFile->Seek(m_BspHeader.Clusters.Offset, 0);
    m_pMapFile->Read(m_pClusters, sizeof(BSP_CLUSTER)*m_BspHeader.Clusters.Count);
  }
}

void CVisibleBsp::InitBspXrefs()
{
  ZeroMemory(m_BspXrefs, sizeof(m_BspXrefs));

  strncpy(m_BspXrefs[0].name, "Shaders", 127);
  m_BspXrefs[0].offset = m_BspHeader.Shaders.Offset;
  m_BspXrefs[0].count = m_BspHeader.Shaders.Count;

  strncpy(m_BspXrefs[1].name, "CollBspHeader", 127);
  m_BspXrefs[1].offset = m_BspHeader.CollBspHeader.Offset;
  m_BspXrefs[1].count = m_BspHeader.CollBspHeader.Count;

  strncpy(m_BspXrefs[2].name, "Nodes", 127);
  m_BspXrefs[2].offset = m_BspHeader.Nodes.Offset;
  m_BspXrefs[2].count = m_BspHeader.Nodes.Count;

  strncpy(m_BspXrefs[3].name, "Leaves", 127);
  m_BspXrefs[3].offset = m_BspHeader.Leaves.Offset;
  m_BspXrefs[3].count = m_BspHeader.Leaves.Count;

  strncpy(m_BspXrefs[4].name, "LeafSurfaces", 127);
  m_BspXrefs[4].offset = m_BspHeader.LeafSurfaces.Offset;
  m_BspXrefs[4].count = m_BspHeader.LeafSurfaces.Count;

  strncpy(m_BspXrefs[5].name, "SubmeshTriIndices", 127);
  m_BspXrefs[5].offset = m_BspHeader.SubmeshTriIndices.Offset;
  m_BspXrefs[5].count = m_BspHeader.SubmeshTriIndices.Count;

  strncpy(m_BspXrefs[6].name, "SubmeshHeader", 127);
  m_BspXrefs[6].offset = m_BspHeader.SubmeshHeader.Offset;
  m_BspXrefs[6].count = m_BspHeader.SubmeshHeader.Count;

  strncpy(m_BspXrefs[7].name, "Chunk10", 127);
  m_BspXrefs[7].offset = m_BspHeader.Chunk10.Offset;
  m_BspXrefs[7].count = m_BspHeader.Chunk10.Count;

  strncpy(m_BspXrefs[8].name, "Chunk11", 127);
  m_BspXrefs[8].offset = m_BspHeader.Chunk11.Offset;
  m_BspXrefs[8].count = m_BspHeader.Chunk11.Count;

  strncpy(m_BspXrefs[9].name, "Chunk12", 127);
  m_BspXrefs[9].offset = m_BspHeader.Chunk12.Offset;
  m_BspXrefs[9].count = m_BspHeader.Chunk12.Count;

  strncpy(m_BspXrefs[10].name, "Clusters", 127);
  m_BspXrefs[10].offset = m_BspHeader.Clusters.Offset;
  m_BspXrefs[10].count = m_BspHeader.Clusters.Count;

  strncpy(m_BspXrefs[11].name, "Chunk14", 127);
  m_BspXrefs[11].offset = m_BspHeader.Chunk14.Offset;
  m_BspXrefs[11].count = m_BspHeader.Chunk14.Count;

  strncpy(m_BspXrefs[12].name, "ClusterPortals", 127);
  m_BspXrefs[12].offset = m_BspHeader.ClusterPortals.Offset;
  m_BspXrefs[12].count = m_BspHeader.ClusterPortals.Count;

  strncpy(m_BspXrefs[13].name, "Chunk16a", 127);
  m_BspXrefs[13].offset = m_BspHeader.Chunk16a.Offset;
  m_BspXrefs[13].count = m_BspHeader.Chunk16a.Count;

  strncpy(m_BspXrefs[14].name, "BreakableSurfaces", 127);
  m_BspXrefs[14].offset = m_BspHeader.BreakableSurfaces.Offset;
  m_BspXrefs[14].count = m_BspHeader.BreakableSurfaces.Count;

  strncpy(m_BspXrefs[15].name, "FogPlanes", 127);
  m_BspXrefs[15].offset = m_BspHeader.FogPlanes.Offset;
  m_BspXrefs[15].count = m_BspHeader.FogPlanes.Count;

  strncpy(m_BspXrefs[16].name, "FogRegions", 127);
  m_BspXrefs[16].offset = m_BspHeader.FogRegions.Offset;
  m_BspXrefs[16].count = m_BspHeader.FogRegions.Count;

  strncpy(m_BspXrefs[17].name, "FogOrWeatherPallette", 127);
  m_BspXrefs[17].offset = m_BspHeader.FogOrWeatherPallette.Offset;
  m_BspXrefs[17].count = m_BspHeader.FogOrWeatherPallette.Count;

  strncpy(m_BspXrefs[18].name, "Chunk16f", 127);
  m_BspXrefs[18].offset = m_BspHeader.Chunk16f.Offset;
  m_BspXrefs[18].count = m_BspHeader.Chunk16f.Count;

  strncpy(m_BspXrefs[19].name, "Chunk16g", 127);
  m_BspXrefs[19].offset = m_BspHeader.Chunk16g.Offset;
  m_BspXrefs[19].count = m_BspHeader.Chunk16g.Count;

  strncpy(m_BspXrefs[20].name, "Weather", 127);
  m_BspXrefs[20].offset = m_BspHeader.Weather.Offset;
  m_BspXrefs[20].count = m_BspHeader.Weather.Count;

  strncpy(m_BspXrefs[21].name, "WeatherPolyhedra", 127);
  m_BspXrefs[21].offset = m_BspHeader.WeatherPolyhedra.Offset;
  m_BspXrefs[21].count = m_BspHeader.WeatherPolyhedra.Count;

  strncpy(m_BspXrefs[22].name, "Chunk19", 127);
  m_BspXrefs[22].offset = m_BspHeader.Chunk19.Offset;
  m_BspXrefs[22].count = m_BspHeader.Chunk19.Count;

  strncpy(m_BspXrefs[23].name, "Chunk20", 127);
  m_BspXrefs[23].offset = m_BspHeader.Chunk20.Offset;
  m_BspXrefs[23].count = m_BspHeader.Chunk20.Count;

  strncpy(m_BspXrefs[24].name, "PathfindingSurface", 127);
  m_BspXrefs[24].offset = m_BspHeader.PathfindingSurface.Offset;
  m_BspXrefs[24].count = m_BspHeader.PathfindingSurface.Count;

  strncpy(m_BspXrefs[25].name, "Chunk24", 127);
  m_BspXrefs[25].offset = m_BspHeader.Chunk24.Offset;
  m_BspXrefs[25].count = m_BspHeader.Chunk24.Count;

  strncpy(m_BspXrefs[26].name, "BackgroundSound", 127);
  m_BspXrefs[26].offset = m_BspHeader.BackgroundSound.Offset;
  m_BspXrefs[26].count = m_BspHeader.BackgroundSound.Count;

  strncpy(m_BspXrefs[27].name, "SoundEnvironment", 127);
  m_BspXrefs[27].offset = m_BspHeader.SoundEnvironment.Offset;
  m_BspXrefs[27].count = m_BspHeader.SoundEnvironment.Count;

  strncpy(m_BspXrefs[28].name, "Chunk25", 127);
  m_BspXrefs[28].offset = m_BspHeader.Chunk25.Offset;
  m_BspXrefs[28].count = m_BspHeader.Chunk25.Count;

  strncpy(m_BspXrefs[29].name, "Chunk26", 127);
  m_BspXrefs[29].offset = m_BspHeader.Chunk26.Offset;
  m_BspXrefs[29].count = m_BspHeader.Chunk26.Count;

  strncpy(m_BspXrefs[30].name, "Chunk27", 127);
  m_BspXrefs[30].offset = m_BspHeader.Chunk27.Offset;
  m_BspXrefs[30].count = m_BspHeader.Chunk27.Count;

  strncpy(m_BspXrefs[31].name, "Markers", 127);
  m_BspXrefs[31].offset = m_BspHeader.Markers.Offset;
  m_BspXrefs[31].count = m_BspHeader.Markers.Count;

  strncpy(m_BspXrefs[32].name, "DetailObjects", 127);
  m_BspXrefs[32].offset = m_BspHeader.DetailObjects.Offset;
  m_BspXrefs[32].count = m_BspHeader.DetailObjects.Count;

  strncpy(m_BspXrefs[33].name, "RuntimeDecals", 127);
  m_BspXrefs[33].offset = m_BspHeader.RuntimeDecals.Offset;
  m_BspXrefs[33].count = m_BspHeader.RuntimeDecals.Count;

  strncpy(m_BspXrefs[34].name, "Coll Nodes", 127);
  m_BspXrefs[34].offset = m_CollBsp.m_CollHeader.Nodes.Offset;
  m_BspXrefs[34].count = m_CollBsp.m_CollHeader.Nodes.Count;

  strncpy(m_BspXrefs[35].name, "Coll Planes", 127);
  m_BspXrefs[35].offset = m_CollBsp.m_CollHeader.Planes.Offset;
  m_BspXrefs[35].count = m_CollBsp.m_CollHeader.Planes.Count;

  strncpy(m_BspXrefs[36].name, "Coll Leaves", 127);
  m_BspXrefs[36].offset = m_CollBsp.m_CollHeader.Leaves.Offset;
  m_BspXrefs[36].count = m_CollBsp.m_CollHeader.Leaves.Count;

  strncpy(m_BspXrefs[37].name, "Coll Bsp2dRef", 127);
  m_BspXrefs[37].offset = m_CollBsp.m_CollHeader.Bsp2dRef.Offset;
  m_BspXrefs[37].count = m_CollBsp.m_CollHeader.Bsp2dRef.Count;

  strncpy(m_BspXrefs[38].name, "Coll Bsp2dNodes", 127);
  m_BspXrefs[38].offset = m_CollBsp.m_CollHeader.Bsp2dNodes.Offset;
  m_BspXrefs[38].count = m_CollBsp.m_CollHeader.Bsp2dNodes.Count;

  strncpy(m_BspXrefs[39].name, "Coll Surfaces", 127);
  m_BspXrefs[39].offset = m_CollBsp.m_CollHeader.Surfaces.Offset;
  m_BspXrefs[39].count = m_CollBsp.m_CollHeader.Surfaces.Count;

  strncpy(m_BspXrefs[40].name, "Coll Edges", 127);
  m_BspXrefs[40].offset = m_CollBsp.m_CollHeader.Edges.Offset;
  m_BspXrefs[40].count = m_CollBsp.m_CollHeader.Edges.Count;

  strncpy(m_BspXrefs[41].name, "Coll Vertices", 127);
  m_BspXrefs[41].offset = m_CollBsp.m_CollHeader.Vertices.Offset;
  m_BspXrefs[41].count = m_CollBsp.m_CollHeader.Vertices.Count;
}

