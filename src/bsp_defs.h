#pragma once

#include "basic_types.h"

//This struct is always located at the beginning of a bsp
//in xbox, it defines the two arrays of reflexives that 
//determine the true location of the vertex data
//only the offset element is used.  The rest is garbage.
typedef struct STRUCT_BSP_SECTION_HEADER
{
  UINT BspHeaderOffset;
  UINT Xbox_Vert_ReflexiveCount;
  UINT Xbox_Vert_ReflexiveStart;
  UINT Xbox_LightmapVert_ReflexiveCount;
  UINT Xbox_LightmapVert_ReflexiveStart;
  char tag[4]; //sbsp
}BSP_SECTION_HEADER;

//This struct (or array of structs) is located at the end of the scenario
//It defines the location of the BSP and its size
typedef struct STRUCT_SCENARIO_BSP_INFO
{
  UINT BspStart;
  UINT BspSize;
  UINT Magic;
  UINT Zero1;
  char bsptag[4];
  UINT NamePtr;
  UINT unknown2;
  UINT TagId;
}SCENARIO_BSP_INFO;


//
//This is the BSP Header, it defines the location of everything in the BSP
//
typedef struct STRUCT_BSP_HEADER
{
  TAG_REFERENCE LightmapsTag;
  UINT unk4[0x25];
  REFLEXIVE Shaders;
  REFLEXIVE CollBspHeader;
  REFLEXIVE Nodes;
  UINT unk6[6];
  REFLEXIVE Leaves;
  REFLEXIVE LeafSurfaces;
  REFLEXIVE SubmeshTriIndices;
  REFLEXIVE SubmeshHeader;
  REFLEXIVE Chunk10;
  REFLEXIVE Chunk11;
  REFLEXIVE Chunk12;
  REFLEXIVE Clusters;
  int ClusterDataSize;
  UINT unk11;
  REFLEXIVE Chunk14;
  REFLEXIVE ClusterPortals;
  REFLEXIVE Chunk16a;
  REFLEXIVE BreakableSurfaces;
  REFLEXIVE FogPlanes;
  REFLEXIVE FogRegions;
  REFLEXIVE FogOrWeatherPallette;
  REFLEXIVE Chunk16f;
  REFLEXIVE Chunk16g;
  REFLEXIVE Weather;
  REFLEXIVE WeatherPolyhedra;
  REFLEXIVE Chunk19;
  REFLEXIVE Chunk20;
  REFLEXIVE PathfindingSurface;
  REFLEXIVE Chunk24;
  REFLEXIVE BackgroundSound;
  REFLEXIVE SoundEnvironment;
  int SoundPASDataSize;
  UINT unk12;
  REFLEXIVE Chunk25;
  REFLEXIVE Chunk26;
  REFLEXIVE Chunk27;
  REFLEXIVE Markers;
  REFLEXIVE DetailObjects;
  REFLEXIVE RuntimeDecals;
  UINT unk10[9];
}BSP_HEADER;

//
// Collision BSP Data Structures
//
typedef struct STRUCT_COLLISION_BSP_HEADER
{
  REFLEXIVE Nodes;        //12 bytes
  REFLEXIVE Planes;       //16 bytes
  REFLEXIVE Leaves;       //8 bytes
  REFLEXIVE Bsp2dRef;     //8 bytes
  REFLEXIVE Bsp2dNodes;   //20 bytes
  REFLEXIVE Surfaces;     //12 bytes
  REFLEXIVE Edges;        //24 bytes
  REFLEXIVE Vertices;     //16 bytes
}COLLISION_BSP_HEADER;

typedef struct STRUCT_COLL_NODE
{
  int PlaneIndex;
  int Back;
  int Front;
}COLL_NODE;

typedef struct STRUCT_COLL_PLANE
{
  float x;
  float y;
  float z;
  float d;
}COLL_PLANE;

typedef struct STRUCT_COLL_LEAF
{
  int unk[2];
}COLL_LEAF;

typedef struct STRUCT_COLL_BSP_2D_REF
{
  int unk[2];
}COLL_BSP_2D_REF;

typedef struct STRUCT_COLL_BSP_2D_NODES
{
  float unk[3];
  UINT  unk2;
  UINT  LeafIndex;
}COLL_BSP_2D_NODES;

typedef struct STRUCT_COLL_SURFACES
{
  int unk[2];
  short unk1;
  short unk2;
}COLL_SURFACES;

typedef struct STRUCT_COLL_EDGES
{
  UINT unk[6];
}COLL_EDGES;

typedef struct STRUCT_COLL_VERTEX
{
  float unk[4];
}COLL_VERTEX;


//
// Visible BSP Data Structures
//
typedef struct STRUCT_BSP_SHADER
{
  TAG_REFERENCE ShaderTag;
  USHORT UnkFlags[2];
}BSP_SHADER;

typedef struct STRUCT_BSP_NODES
{
  SHORT unk[3];
}BSP_NODES;

typedef struct STRUCT_BSP_LEAF
{
  UINT unk[4];
}BSP_LEAF;

typedef struct STRUCT_BSP_LEAF_SURFACE
{
  UINT unk[2];
}BSP_LEAF_SURFACE;


//
// Lightmaps (world meshes)
//

// This struct (array of structs actually) is pointed to by the BSP Header
// under the "SubmeshHeader" field.  It in turn points to the visible
// submesh headers that contain the actual vertex counts and pointers, etc.
// The purpose of this is to group the world meshes by texture to optimize
// texture cacheing.
typedef struct STRUCT_BSP_LIGHTMAP
{
  SHORT LightmapIndex;
  SHORT unk1;
	UINT unknown[4];
  REFLEXIVE Material;
}BSP_LIGHTMAP;

// There is one of these structs for every submesh in the map.
typedef struct STRUCT_MATERIAL_SUBMESH_HEADER
{
  TAG_REFERENCE ShaderTag;
  UINT UnkZero2;
  UINT VertIndexOffset;
  UINT VertIndexCount;
  float Centroid[3];
  float AmbientColor[3];
  UINT DistLightCount;
  float DistLight1[6];
  float DistLight2[6];
  float unkFloat2[3];
  float ReflectTint[4];
  float ShadowVector[3];
  float ShadowColor[3];
  float Plane[4];
  UINT UnkFlag2;
  UINT UnkCount1;
  UINT VertexCount1;
  UINT UnkZero4;
  UINT VertexOffset;
  UINT Vert_Reflexive;
  UINT UnkAlways3;
  UINT VertexCount2;
  UINT UnkZero9;
  UINT UnkLightmapOffset;
  UINT CompVert_Reflexive;
  UINT UnkZero5[2];
  UINT SomeOffset1;
  UINT PcVertexDataOffset;
  UINT UnkZero6;
  UINT CompVertBufferSize;
  UINT UnkZero7;
  UINT SomeOffset2;
  UINT VertexDataOffset;
  UINT UnkZero8;
}MATERIAL_SUBMESH_HEADER;

// triangle index; an array of these is pointed to from the 
// MATERIAL_SUBMESH_HEADER.
typedef struct
{
  USHORT tri_ind[3];
}TRI_INDICES;

// xbox specific vertex
typedef struct STRUCT_COMPRESSED_BSP_VERT
{
  float vertex_k[3];
  UINT  comp_normal;
  UINT  comp_binormal;
  UINT  comp_tangent;
  float uv[2];
}COMPRESSED_BSP_VERT;

// pc (uncompressed) vertex.  I think the xbox puts the verts in this
// format at runtime.
typedef struct
{
  float vertex_k[3];
  float normal[3];
  float binormal[3];
  float tangent[3];
  float uv[2];
}UNCOMPRESSED_BSP_VERT;

// xbox specific lightmap vertex
typedef struct STRUCT_COMPRESSED_LIGHTMAP_VERT
{
  UINT comp_normal;
  SHORT comp_uv[2];
}COMPRESSED_LIGHTMAP_VERT;

// pc (uncompressed) lightmap vertex.  I think the xbox puts the 
// verts in this format at runtime.  
typedef struct STRUCT_PC_LIGHTMAP_VERT
{
  float normal[3];
  float uv[2];
}UNCOMPRESSED_LIGHTMAP_VERT;

//
// BSP Clusters
//

typedef struct STRUCT_BSP_
{
}BSP_;

typedef struct STRUCT_BSP_CLUSTER
{
  SHORT SkyIndex;
  SHORT FogIndex;
  SHORT BackgroundSoundIndex;
  SHORT SoundEnvIndex;
  SHORT WeatherIndex;
  SHORT TransitionBsp;
  UINT  unk1[10];
  REFLEXIVE SubCluster;
	UINT unk2[7];
  REFLEXIVE Portals;
}BSP_CLUSTER;



typedef struct STRUCT_BSP_WEATHER
{
  char Name[32];
  char tag[4];
  UINT NamePtr;
  UINT zero1;
  UINT TagId;
  UINT reserved[20];
  char tag2[4];
  UINT NamePtr2;
  UINT zero2;
  UINT signature2;
  UINT unk[24];
}BSP_WEATHER;


//
// Data Organization Structs for SparkEdit
// (helper structures for the sparkedit render engine)
typedef struct
{
  MATERIAL_SUBMESH_HEADER header;
  char shader_name[128];
  UNCOMPRESSED_BSP_VERT *pVert;
  COMPRESSED_BSP_VERT *pCompVert;

  UINT     VertCount;
  TRI_INDICES *pIndex;
  UINT     IndexCount;
  BYTE *pTextureData;
  UINT ShaderType;
  UINT ShaderIndex;
  BOUNDING_BOX Box;
  int RenderTextureIndex;
  int LightmapIndex;
  UNCOMPRESSED_LIGHTMAP_VERT *pLightmapVert;
  COMPRESSED_LIGHTMAP_VERT *pCompLightmapVert;
}SUBMESH_INFO;
