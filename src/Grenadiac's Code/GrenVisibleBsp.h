// VisibleBsp.h: interface for the CVisibleBsp class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_VISIBLEBSP_H__465524FD_32DD_4AD0_A88B_80069D55A9EF__INCLUDED_)
#define AFX_VISIBLEBSP_H__465524FD_32DD_4AD0_A88B_80069D55A9EF__INCLUDED_

#include "HaloStructDefs.h"
#include "Util.h"
#include "CollBsp.h"

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

typedef struct STRUCT_BSP_XREF
{
  char name[128];
  UINT offset;
  UINT count;
}BSP_XREF;

#define BSP_XREF_COUNT  42

class CVisibleBsp : public CUtil
{
public:
	void LoadClusters(void);
	CVisibleBsp();
	virtual ~CVisibleBsp();
  CString GetMeshInfo(int mesh_index);
	void Cleanup(void);
	void LoadVisibleBsp(UINT BspHdrOffset, UINT version);
	void Initialize(CFile *pMapFile, UINT magic, UINT bsp_magic);
  void GetMapCentroid(float *cx, float *cy, float *cz);
	void DumpBoundingBoxInfo(int mesh_index);
  void ExportPcMeshToObj(CString path);
  void ExportXboxMeshToObj(CString path);

  UINT m_SubMeshCount;
  SUBMESH_INFO *m_pMesh;
  BSP_WEATHER *m_pWeather;
  
  CCollBsp m_CollBsp;

  BSP_XREF m_BspXrefs[BSP_XREF_COUNT];

protected:
	void InitBspXrefs(void);
	void LoadWeather(void);
  void LoadXboxSubmeshes(void);
	
  void LoadMaterialMeshHeaders(void);
	void LoadPcSubmeshes(void);

  void UpdateBoundingBox(int mesh_index, float *pCoord, UINT version);
	void ResetBoundingBox(void);
  CFile *m_pMapFile;
  UINT m_BspMagic;
  UINT m_Magic;

  BSP_HEADER m_BspHeader;
  BSP_LIGHTMAP *m_pLightmaps;
  BOUNDING_BOX m_MapBox;
  BSP_CLUSTER *m_pClusters;

  float m_Centroid[3];
  UINT m_CentroidCount;
  int m_ActiveBsp;
  int m_TriTotal;


};

#endif // !defined(AFX_VISIBLEBSP_H__465524FD_32DD_4AD0_A88B_80069D55A9EF__INCLUDED_)
