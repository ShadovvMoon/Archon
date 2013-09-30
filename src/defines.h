/*
 *  defines.h
 *  swordedit
 *
 *  Created by sword on 5/11/08.
 *  Copyright 2008 sword Inc. All rights reserved.
 *
 */
#ifndef MACVERSION
 #import "glew.h"
#endif

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

#define MAX_SCENARIO_OBJECTS 100000
//#define fasterRendering 1
#define SUN 1
#define VBO 1
//#define VBO2 1
//#define __DEBUG__ 1
#define NEWSKY 1
#define USEDEBUG if (FALSE) 
//#define DEBUGPAINT 1

int newR;
bool drawO ;
bool lightScene;

int useNewRenderer();
bool drawObjects();

id renderV;
BOOL performanceMode;

NSThread* performanceThread;


typedef struct 
{
	unsigned char TName[32];          // 'object'
	unsigned short MaxObjects;        // Maximum number of objects - 0x800(2048 objects)
	unsigned short Size;                  // Size of each object array - 0x0C(12 bytes)
	unsigned long Unknown0;           // always 1?
	unsigned char Data[4];              // '@t@d' - translates to 'data'?
	unsigned short Unknown1;         // Something to do with number of objects
	unsigned short Max;                  // Max number of objects the game has reached (slots maybe?)
	unsigned short Num;                  // Number of objects in the current game
	unsigned short NextObjectIndex; // Index number of the next object to spawn
	unsigned short NextObjectID;      // ID number of the next object to spawn
	unsigned long FirstObject;          // Pointer to the first object in the table 
} Object_Table_Header; // 0x4BB206B4

typedef struct
{
	unsigned short ObjectID;           // Matches up to Object ID in static player table ( for players )
	unsigned short Unknown0;
	unsigned short Unknown1;
	unsigned short Size;                 // Structure size
	unsigned long Offset;                // Pointer to the object data structure
} Object_Table_Array;


typedef struct 
{
	float x;
	float y;
	float z;
	float sx;
	float sy;
	float sz;
	int address;
	long id_tag;
	BOOL isSelected;
} dynamic_object;

typedef struct
{
	float x,y,z;
} CVector3;

/* BEGIN RENDER VIEW */

typedef enum
{
	redIndex,
	greenIndex,
	blueIndex,
	alphaIndex
} ClearColors;

typedef enum
{
	point,
	wireframe,
	flat_shading,
	textured,
	textured_tris
} RenderStyle;

typedef enum  
{
	rotate_camera,
	translate,
	rotate,
    dirt,
    grass,
    lightmap,
    eyedrop
} Mode;

typedef enum 
{
	s_all = 0,
	s_scenery = 1,
	s_vehicle = 2,
	s_playerspawn = 3,
	s_encounter = 9,
	s_item = 4,
	s_netgame = 5,
	s_machine = 6,
	s_playerobject = 7,
	s_mapobject = 8,
	s_bsppoint = 10,
	s_colpoint = 11
} SelectionType;

typedef enum
{
	up,
	down,
	left,
	right,
	forward,
	back
} Direction;

typedef struct
{
	int direction;
	BOOL isDown;
} Key_In_Use;

typedef struct
{
	float red;
	float blue;
	float green;
	long color_count;
} rgb;

/* END RENDER VIEW */

/* BEGIN MAP */
typedef struct
{
	long map_id;
	long version;
	long map_length;
	long zeros;
	long offsetToIndex;
	long metaSize;
	long zeros2[2];
	char name[32];
	char builddate[32];
	long maptype;
	long footer;
} Header;

typedef struct
{
	long indexMagic;
	long starting_id;
	long vertexsize;
	long tagcount;
	long vertex_object_count;
	long vertex_offset;
	long indices_object_count;
	long vertex_size;
	long modelsize;
	long tagstart;
} IndexHeader;

typedef struct
{
	long chunkcount;
	int offset;
	long zero;
	
	// Editing / saving related aspect
	long location_in_mapfile;
	int oldOffset;
	int newChunkCount;
	int chunkSize;
	
	// Scenario reconstruction aspect
	int refNumber;
} reflexive;

typedef struct
{
	long chunkcount;
	int offset;
	long zero;
} reflexive_tag;

typedef struct
{
  char tag[4];
  long NamePtr;
  long unknown;
  long TagId;
} TAG_REFERENCE;

typedef struct
{
    unsigned long junk1[34];
    TAG_REFERENCE baseMapBitm;
    unsigned long junk2[7];
    float primaryMapScale;
    TAG_REFERENCE primaryMapBitm;
    float secondaryMapScale;
    TAG_REFERENCE secondaryMapBitm;
    float r,g,b;
    //Rest is bleh
} senv;

typedef struct
{
    unsigned long junk1[41];
    TAG_REFERENCE baseMap;
    unsigned long junk3[2];
    TAG_REFERENCE multiPurpose;
    unsigned long junk2[3];
    float detailScale;
    TAG_REFERENCE detailMap;
    
} soso;

typedef struct
{
    float r,g,b;
} swat;

typedef struct
{
    //unsigned long junk1[11];
    short colorFunction;
    short alphaFunction;
    //unsigned long junk2[9];
    float uscale;
    float vscale;
    //unsigned long junk4[4];
    TAG_REFERENCE bitm;
    //unsigned long junk3[24];
    
    GLfloat *texture_uv;
} map;

typedef struct
{
    //unsigned long junk1[21];
    reflexive maps;
    
    map *read_maps;
    
} schi;

typedef struct
{
    //unsigned long junk1[21];
    reflexive maps;
    reflexive maps2;
    map *read_maps;
    
} scex;

/* END MAP */
/* BEGIN SCENARIO */

// scenario header -> Taken from ScenarioDefs.h from Bob's sparkedit (Probably gren's code in the first place)
/*
*
*	Scenario header is ALWAYS 0x5B0 long and ends with the skybox tag ref.
*
*	Scenario reconstruction leaves everything up to Scenery untouched
*	After scenery, which we allow users to edit, the scenario may be reconstructed
*	thereby causing reflexives to change
*
*/
typedef struct
{
  char unk_str1[16];
  char unk_str2[16];
  char unk_str3[16];
  reflexive SkyBox; // 1
  int unk1;
  reflexive ChildScenarios; // 2

	unsigned long unneeded1[46];
  int EditorScenarioSize;
  int unk2;
  int unk3;
  unsigned long pointertoindex;
	unsigned long unneeded2[2];
  unsigned long pointertoendofindex;
	unsigned long zero1[57];

  reflexive ObjectNames; // 3
  reflexive Scenery; // 4
  reflexive SceneryRef; // 5
  reflexive Biped; // 6
  reflexive BipedRef; // 7
  reflexive Vehicle; // 8
  reflexive VehicleRef;  // 9
  reflexive Equip; // 10
  reflexive EquipRef; // 11
  reflexive Weap; // 12
  reflexive WeapRef; // 13
  reflexive DeviceGroups; // 14
  reflexive Machine; // 15
  reflexive MachineRef; // 16
  reflexive Control; // 17
  reflexive ControlRef; // 18
  reflexive LightFixture; // 19
  reflexive LightFixtureRef; // 20
  reflexive SoundScenery; // 21
  reflexive SoundSceneryRef; // 22
  reflexive Unknown1[7]; // 23-29
  reflexive PlayerStartingProfile; // 30
  reflexive PlayerSpawn; // 31
  reflexive TriggerVolumes; // 32
  reflexive Animations; // 33
  reflexive MultiplayerFlags; // 34
  reflexive MpEquip; // 35
  reflexive StartingEquip; // 36
  reflexive BspSwitchTrigger; // 37
  reflexive Decals; // 38
  reflexive DecalsRef; // 39
  reflexive DetailObjCollRef; // 40
  reflexive Unknown3[7]; // 41-47
  reflexive ActorVariantRef; // 48
  reflexive Encounters; // 49
  //below this, structs still not confirmed
    
    
  reflexive CommandLists; // 50
    
    /*
  reflexive AnimationRefs;
  reflexive AiScriptRefs;
    reflexive AiRecordingRefs;
    reflexive AiConversations;
    
    long scriptSyntax;
    long scriptSyntax2;
    float scriptSyntax3;
    long scriptSyntax4;
    long scriptSyntax5;
    float scriptSyntax6;

    reflexive Scripts;
    reflexive Globals;
    
    reflexive References;
    reflexive SourceFiles;
    reflexive CutsceneFlags;
    reflexive CutsceneCameraPoints;
    reflexive CutsceneTitles;
    
    reflexive UnknownRef[9];
    
    long con[2];
    long ight[2];
    long hud[2];
    
    reflexive StructBsp;
    */
    
    
  reflexive Unknown2; // 51
  reflexive StartingLocations; // 52
  reflexive Platoons; // 53
  reflexive AiConversations; // 54
  reflexive Unknown8[3]; // 71-78
    
  unsigned long ScriptDataSize;
  unsigned long Unknown4;
  reflexive ScriptCrap; // 55
  reflexive Commands; // 56
  reflexive Points; // 57
  reflexive AiAnimationRefs; // 58
  reflexive GlobalsVerified; // 59
  reflexive AiRecordingRefs; // 60
  reflexive Unknown5; // 61
  reflexive Participants; // 62
  reflexive Lines; // 63
  reflexive ScriptTriggers; // 64
  reflexive VerifyCutscenes; // 65
  reflexive VerifyCutsceneTitle; // 66
  reflexive SourceFiles; // 67
  reflexive CutsceneFlags; // 68
  reflexive CutsceneCameraPoi; // 69
  reflexive CutsceneTitles; // 70
  reflexive Unknown6[8]; // 71-78
    reflexive Unknown61[14]; // 71-78
  unsigned long  Unknown7[2];
  reflexive StructBsp; // 79
    
    
}SCNR_HEADER;

typedef struct SkyBox
{
	TAG_REFERENCE skybox;
	long modelIdent;
} SkyBox;
// scenery
typedef struct scenery_spawn
{
	short numid;
	short flag;
	short not_placed;
	short desired_permutation;
	float coord[3];
	float rotation[3];
	float unknown[10];
	
	// Not part of the in-map data
	long modelIdent;
	bool isSelected;
	bool isMoving;
} scenery_spawn;
#define SCENERY_SPAWN_CHUNK 0x48

typedef struct scenery_reference
{
	TAG_REFERENCE scen_ref;
	unsigned long zero[8];
} scenery_reference;
#define SCENERY_REF_CHUNK 0x30 



// vehicles
typedef struct 
{
    /*short numid;
     short flag;
     short not_placed;
     short desired_permutation;
     float coord[3];
     float rotation[3];
     
     long unknown1[5];
     float body_vitality;
     //short unknown2;
     unsigned long flags;
     unsigned long unknown3[2];
     char mpTeamIndex[2];
     long mpSpawnFlags;
     
     short unknown2[11];
     
     // Not part of the in-map data
     long modelIdent;
     bool isSelected;
     bool isMoving;*/
    
    
	short numid;
	short flag;
	short not_placed;
	short desired_permutation;
	float coord[3];
	float rotation[3];
	unsigned long unknown2[22];
    
    /*
    short numid;
    short flag;
    short not_placed;
    short desired_permutation;
    float coord[3];
    float rotation[3];
    unsigned long unknown1[10];
    float body_vitality; //72
    short flags; //76
    short unknown3[5]; //78
    short mpTeamIndex; //88
    short mpSpawnFlags; //90
    unsigned long unknown2[7];
*/
	
	// Not part of the in-map data
	long modelIdent;
	bool isSelected;
	bool isMoving;
} vehicle_spawn;
// Need to check this out
#define VEHICLE_SPAWN_CHUNK 0x78

typedef struct bipd_reference
{
	TAG_REFERENCE bipd_ref;
	unsigned long zero[8];
} bipd_reference;

typedef struct vehicle_reference
{
	TAG_REFERENCE vehi_ref;
	unsigned long zero[8];
} vehicle_reference;
#define VEHICLE_REF_CHUNK 0x30

// MP Equipment
typedef struct mp_equipment
{
    unsigned long bitmask32;
    
    short type1; // Enum16
	short type2; // Enum16
	short type3; // Enum16
	short type4; // Enum16
    
    short team_index;
    short spawn_time;
    
	unsigned long unknown[12];
	float coord[3];
	float yaw;
	TAG_REFERENCE itmc;
	unsigned long unknown2[12];
	
	// Not part of the in-map data
	long modelIdent;
	bool isSelected;
	bool isMoving;
} mp_equipment;
#define MP_EQUIP_CHUNK 0x90

// players
typedef struct player_spawn
{
	float coord[3];
	float rotation;
	short team_index;
	short bsp_index;
	short type1; // Enum16
	short type2; // Enum16
	short type3; // Enum16
	short type4; // Enum16
	float unknown[6];
	
	// Not part of in-map data
	bool isSelected;
	bool isMoving;
} player_spawn;
#define PLAYER_SPAWN_CHUNK 0x34
 struct Bsp2dRef{
    int plane; // The plane used to decide what basis plane is best to project on (X,Y), (Y,Z) or (X,Z)
    int node; // starting node, if < 0 then node refers directly to a surface
};
 struct Bsp2dNodes{
    float a;    // ab and d uniquely define a 2d plane
    float b;
    float d;
    int leftChild; // if < 0 this refers to a surface (Ex, surface = leftChild & 0x7FFFFFFF;
    int rightChild;
};

 struct Surfaces{
    int plane;
    int firstEdge;
    int SomeOtherstuffs;
};
 struct Edges{  // Half edge data structure see:
    int startVertex;
    int endVertex;
    int forwardEdge;
    int reverseEdge;
    int leftFace;
    int rightFace;
};
 struct Verticies{
    float x,y,z;
    int firstEdge;
};
typedef struct multiplayer_flags
{
	float coord[3];
	float rotation;
	short type;
	short team_index;
	TAG_REFERENCE item_used; // Not always there
	long zeros[0x70]; // Never needs to be read, just needs to be here
	
	// Not part of in-map data
	BOOL isSelected;
	BOOL isMoving;
} multiplayer_flags;
#define MP_FLAGS_CHUNK 0x94

/* I don't really think this will work... */
typedef struct netgame_equipment
{
	long bitmask32;
	short type0;
	short type1;
	short type2;
	short type3;
	short teamIndex;
	short spawnTime;
	float coord[3];
	float rotation[1];
	TAG_REFERENCE item_used;
} netgame_equipment;
#define NETGAME_EQUIP_CHUNK 0x90

// 0xCC in length
typedef struct starting_weapons
{
	long unk1;
	long unk2;
	long unk3[13];
	TAG_REFERENCE weapon[6]; // 6 * 0x10
	long zeros2[12];
} starting_weapons;
#define STARTING_WEAPONS_CHUNK 0xCC

// 0x40 in length
typedef struct machine_spawn
{
	short numid;
	short someflag;
	short not_placed;
	short desired_permutation;
	float coord[3];
	float rotation[3];
	
    unsigned long unknown1[2]; //32
    
    short powerGroup; //40
    short positionGroup; //42
    
	short flags; //44
	short flags2; //48
	
	short zeros[8]; //50
	
	// non-spawn data
	BOOL isSelected;
} machine_spawn;
#define MACHINE_CHUNK 0x40

// 0x30 in length
typedef struct machine_ref
{
	TAG_REFERENCE machTag;
	long zeros[8];
	
	// non-map data
	long modelIdent;
} machine_ref;
#define MACHINE_REF_CHUNK 0x30

typedef struct 
{
	float coord[3];
	bool isSelected;
	int index;
	int amindex;
	int mesh;
} bsp_point;

typedef struct device_group
{
	char name[32];
	float initial_value;
	short flags;
	
} device_group;
#define DEVICE_CHUNK 52

typedef struct encounter
{
	unsigned long unknown[32];
	reflexive_tag squads;
	reflexive_tag platoons;
	reflexive_tag firing;
	reflexive_tag start_locations;
	
	int start_locs_count;
	player_spawn *start_locs;
} encounter;
#define ENCOUNTER_CHUNK 176


/* END SCENARIO */
/* BEGIN MODELS */

typedef struct MODEL_REGION_PERMUTATION
{
  char Name[32];
  unsigned long Flags[8];
  short LOD_MeshIndex[5];
  short Reserved[7];
} MODEL_REGION_PERMUTATION;

typedef struct MODEL_REGION
{
  char Name[64];
  reflexive Permutations;
  MODEL_REGION_PERMUTATION *modPermutations;
} MODEL_REGION;

typedef struct
{
  float min[3];
  float max[3];
}BOUNDING_BOX;

typedef struct
{
	char junk[36];
	reflexive parts;
} geometry;
typedef struct
{
	long count;
	long rawPointer[2];
} indicesPointer;
typedef struct
{
	long count;
	char junk[8];
	long rawPointer;
} verticesPointer;
typedef struct
{
	float x;
	float y;
	float z;
	float normalx;
	float normaly;
	float normalz;
	float u;
	float v;
} Vector;
typedef struct
{
	char junk4[4];
	short shaderIndex;
	long shaderBitmapIndex;
	char junk[66];
	indicesPointer indexPointer;
	char junk2[4];
	verticesPointer vertPointer;
    verticesPointer compressedVertPointer;
	char junk3[12];
	Vector *vertices;
	unsigned short *indices;
    
    //Additional stuff
    long shaderBitmapIndexArray[30];
    long lengthOfBitmapArray;
    
    long baseMapIndex;
    long detailMapIndex;
    float detailMapScale;
    
    int hasShader;
    schi *shader;
    scex *scexshader;
    int textureIndex;
} part;

/* END MODELS */
/* BEGIN BSP */

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
  MATERIAL_SUBMESH_HEADER		header;
  GLuint						*textures;
  char							shader_name[128];
  UNCOMPRESSED_BSP_VERT			*pVert;
  COMPRESSED_BSP_VERT			*pCompVert;
  unsigned long					VertCount;
  TRI_INDICES					*pIndex;
  unsigned long					IndexCount;
  char							*pTextureData;
  unsigned long					ShaderType;
  unsigned long					ShaderIndex;
  unsigned long					DefaultBitmapIndex;
  unsigned long					DefaultLightmapIndex;
  BOUNDING_BOX					Box;
  int							RenderTextureIndex;
  int							LightmapIndex;
  UNCOMPRESSED_LIGHTMAP_VERT	*pLightmapVert;
  COMPRESSED_LIGHTMAP_VERT		*pCompLightmapVert;
    
    
  //Additioanl junk
  unsigned long					baseMap;
  unsigned long					primaryMap;
  unsigned long					secondaryMap;
  unsigned long					microMap;
    
    BOOL isWaterShader;
    
    float primaryMapScale;
    float secondaryMapScale;
    float microMapScale;
    
    float r,g,b;
    
    
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

struct Bsp3dNode{
    int plane;  // if < 0, then the plane is flipped (I'm not 100% sure about that though)
    int backNode; // if < 0, then the left node is a leaf, the leaf index can be obtained by masking off the MSB from the node (Ex: leaf = node & 0x7FFFFFFF;)
    int frontNode; // if < 0, then the right node is a leaf, see above
};

struct Plane{ //I think that this is traditionally (i,j,k,d), but I  like my naming scheme better.
    float a;
    float b;
    float c;
    float d;
};

struct Leaf3d
{
    int flags;
    int bsp2dRef; // Don't worry about this right now
    int bsp2dCount; // Don't worry about this right now
};

// Note that these are an extension to the Leaf3d block of the collision structure
struct Leaves
{
    int cluster;
    int surfaceRefCount;
    int surfaceRef;
};


typedef struct
{
	short LightmapIndex;
	short unk1;
	unsigned long unknown[4];
    
    
    reflexive Node3D;
    reflexive Planes;
    reflexive Leaves;
    reflexive BSP2DRef;
    reflexive BSP2DNodes;
    reflexive Surfaces;
    reflexive Edges;
	reflexive Material;
    
    
}BSP_COLLISION;
typedef struct
{
	float x, y, z;
	float edge;
	
	int isSelected;
}vert;




typedef struct
{
	short plane, left_child, right_child;
	int isSelected;
}node;




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
/* END BSP */