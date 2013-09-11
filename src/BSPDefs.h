@class NSFile;
#import "FileConstants.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
typedef struct
{
  unsigned long BspStart;
  unsigned long BspSize;
  unsigned long Magic;
  unsigned long Zero1;
  char bsptag[4];
  unsigned long NamePtr;
  unsigned long unknown2;
  unsigned long TagId;
}SCENARIO_BSP_INFO;
typedef struct STRUCT_BSP_HEADER
{
  TAG_REFERENCE LightmapsTag;
  unsigned long unk4[0x25];
  reflexive Shaders;
  reflexive CollBspHeader;
  reflexive Nodes;
  unsigned long unk6[6];
  reflexive Leaves;
  reflexive LeafSurfaces;
  reflexive SubmeshTriIndices;
  reflexive SubmeshHeader;
  reflexive Chunk10;
  reflexive Chunk11;
  reflexive Chunk12;
  reflexive Clusters;
  int ClusterDataSize;
  unsigned long unk11;
  reflexive Chunk14;
  reflexive ClusterPortals;
  reflexive Chunk16a;
  reflexive BreakableSurfaces;
  reflexive FogPlanes;
  reflexive FogRegions;
  reflexive FogOrWeatherPallette;
  reflexive Chunk16f;
  reflexive Chunk16g;
  reflexive Weather;
  reflexive WeatherPolyhedra;
  reflexive Chunk19;
  reflexive Chunk20;
  reflexive PathfindingSurface;
  reflexive Chunk24;
  reflexive BackgroundSound;
  reflexive SoundEnvironment;
  int SoundPASDataSize;
  unsigned long unk12;
  reflexive Chunk25;
  reflexive Chunk26;
  reflexive Chunk27;
  reflexive Markers;
  reflexive DetailObjects;
  reflexive RuntimeDecals;
  unsigned long unk10[9];
}BSP_HEADER;

typedef struct
{
  TAG_REFERENCE ShaderTag;
  unsigned long UnkZero2;
  unsigned long VertIndexOffset;
  unsigned long VertIndexCount;
  float Centroid[3];
  float AmbientColor[3];
  unsigned long DistLightCount;
  float DistLight1[6];
  float DistLight2[6];
  float unkFloat2[3];
  float ReflectTint[4];
  float ShadowVector[3];
  float ShadowColor[3];
  float Plane[4];
  unsigned long UnkFlag2;
  unsigned long UnkCount1;
  unsigned long VertexCount1;
  unsigned long UnkZero4;
  unsigned long VertexOffset;
  unsigned long Vert_Reflexive;
  unsigned long UnkAlways3;
  unsigned long VertexCount2;
  unsigned long UnkZero9;
  unsigned long UnkLightmapOffset;
  unsigned long CompVert_Reflexive;
  unsigned long UnkZero5[2];
  unsigned long SomeOffset1;
  unsigned long PcVertexDataOffset;
  unsigned long UnkZero6;
  unsigned long CompVertBufferSize;
  unsigned long UnkZero7;
  unsigned long SomeOffset2;
  unsigned long VertexDataOffset;
  unsigned long UnkZero8;
}MATERIAL_SUBMESH_HEADER;
typedef struct
{
  unsigned long comp_normal;
  short comp_uv[2];
}COMPRESSED_LIGHTMAP_VERT;
typedef struct
{
  float normal[3];
  float uv[2];
}UNCOMPRESSED_LIGHTMAP_VERT;


typedef struct
{
  float vertex_k[3];
  float normal[3];
  float binormal[3];
  float tangent[3];
  float uv[2];
}UNCOMPRESSED_BSP_VERT;
typedef struct
{
  float vertex_k[3];
  unsigned long  comp_normal;
  unsigned long  comp_binormal;
  unsigned long  comp_tangent;
  float uv[2];
}COMPRESSED_BSP_VERT;
typedef struct
{
  unsigned short tri_ind[3];
}TRI_INDICES;
typedef struct
{
  MATERIAL_SUBMESH_HEADER header;
  GLuint *textures;
  char shader_name[128];
  UNCOMPRESSED_BSP_VERT *pVert;
  COMPRESSED_BSP_VERT *pCompVert;
  unsigned long     VertCount;
  TRI_INDICES *pIndex;
  unsigned long     IndexCount;
  char *pTextureData;
  unsigned long ShaderType;
  unsigned long ShaderIndex;
  BOUNDING_BOX Box;
  int RenderTextureIndex;
  int LightmapIndex;
  UNCOMPRESSED_LIGHTMAP_VERT *pLightmapVert;
  COMPRESSED_LIGHTMAP_VERT *pCompLightmapVert;
}SUBMESH_INFO;
typedef struct
{
  char name[128];
  unsigned long offset;
  unsigned long count;
}BSP_XREF;
typedef struct
{
  char Name[32];
  char tag[4];
  unsigned long NamePtr;
  unsigned long zero1;
  unsigned long TagId;
  unsigned long reserved[20];
  char tag2[4];
  unsigned long NamePtr2;
  unsigned long zero2;
  unsigned long signature2;
  unsigned long unk[24];
}BSP_WEATHER;
typedef struct
{
  short LightmapIndex;
  short unk1;
  unsigned long unknown[4];
  reflexive Material;
}BSP_LIGHTMAP;
typedef struct
{
  short SkyIndex;
  short FogIndex;
  short BackgroundSoundIndex;
  short SoundEnvIndex;
  short WeatherIndex;
  short TransitionBsp;
  unsigned long  unk1[10];
  reflexive SubCluster;
	unsigned long unk2[7];
  reflexive Portals;
}BSP_CLUSTER;
SCENARIO_BSP_INFO readBspInfoFromFile(NSFile *file);
TRI_INDICES readIndexFromFile(NSFile *file);
UNCOMPRESSED_LIGHTMAP_VERT readUncompressedLightmapVert(NSFile *file);
UNCOMPRESSED_BSP_VERT readUncompressedBspVert(NSFile *file);
MATERIAL_SUBMESH_HEADER readMaterialSubmeshHeader(NSFile *file, unsigned long magic);