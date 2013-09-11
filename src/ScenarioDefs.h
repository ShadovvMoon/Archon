#import "FileConstants.h"
@class NSFile;

typedef struct
{
  char unk_str1[16];
  char unk_str2[16];
  char unk_str3[16];
  reflexive SkyBox;
  int unk1;
  reflexive ChildScenarios;

	unsigned long unneeded1[46];
  int EditorScenarioSize;
  int unk2;
  int unk3;
  unsigned long pointertoindex;
	unsigned long unneeded2[2];
  unsigned long pointertoendofindex;
	unsigned long zero1[57];

  reflexive ObjectNames;
  reflexive Scenery;
  reflexive SceneryRef;
  reflexive Biped;
  reflexive BipedRef;
  reflexive Vehicle;
  reflexive VehicleRef;
  reflexive Equip;
  reflexive EquipRef;
  reflexive Weap;
  reflexive WeapRef;
  reflexive DeviceGroups;
  reflexive Machine;
  reflexive MachineRef;
  reflexive Control;
  reflexive ControlRef;
  reflexive LightFixture;
  reflexive LightFixtureRef;
  reflexive SoundScenery;
  reflexive SoundSceneryRef;
  reflexive Unknown1[7];
  reflexive PlayerStartingProfile;
  reflexive PlayerSpawn;
  reflexive TriggerVolumes;
  reflexive Animations;
  reflexive MultiplayerFlags;
  reflexive MpEquip;
  reflexive StartingEquip;
  reflexive BspSwitchTrigger;
  reflexive Decals;
  reflexive DecalsRef;
  reflexive DetailObjCollRef;
  reflexive Unknown3[7];
  reflexive ActorVariantRef;
  reflexive Encounters;
  //below this, structs still not confirmed
  reflexive CommandLists;
  reflexive Unknown2;
  reflexive StartingLocations;
  reflexive Platoons;
  reflexive AiConversations;
  unsigned long ScriptSyntaxDataSize;
  unsigned long Unknown4;
  reflexive ScriptCrap;        
  reflexive Commands;
  reflexive Points;
  reflexive AiAnimationRefs;
  reflexive GlobalsVerified;
  reflexive AiRecordingRefs;
  reflexive Unknown5;
  reflexive Participants;
  reflexive Lines;
  reflexive ScriptTriggers;
  reflexive VerifyCutscenes;
  reflexive VerifyCutsceneTitle;
  reflexive SourceFiles;
  reflexive CutsceneFlags;
  reflexive CutsceneCameraPoi;
  reflexive CutsceneTitles;
  reflexive Unknown6[8];
  unsigned long  Unknown7[2];
  reflexive StructBsp;
}SCNR_HEADER;



typedef struct STRUCT_SKYBOX
{
	TAG_REFERENCE skybox;
	long modelIdent;
}SKYBOX;

typedef struct STRUCT_SCENERY_SPAWN
{
	short numid;
	short flag;
	unsigned long unk1;
	float coord[3];
	float rotation[3];
	long unknown[10];
	long modelIdent;
	bool selected;
	bool moving;
} SCENERY_SPAWN;

typedef struct STRUCT_SCENERY_REF
{
	TAG_REFERENCE sceneryRef;
	unsigned long zero[8];
} SCENERY_REF;

typedef struct STRUCT_VEHICLE_SPAWN
{
  short numid;
  unsigned short flag;
  unsigned long unknown1;
	float x;
	float y;
	float z;
	float rotx;
	float roty;
	float rotz;
	unsigned long unknown2[22];
	//not part of struct
	long modelIdent;
	bool selected;
	bool moving;
}VEHICLE_SPAWN;
typedef struct STRUCT_VEHICLE_REF
{
	TAG_REFERENCE vehicle;
	unsigned long zero[8];
}VEHICLE_REF;
typedef struct STRUCT_MP_EQUIP
{
  unsigned long unk[16];
  float x;
  float y;
  float z;
  float yaw;
  float unk1; //not in struct
  float unk2; //not in struct
  TAG_REFERENCE itmc;
  unsigned long unk3[12];
  long modelIdent;
  bool selected;
  bool moving;
}MP_EQUIP;

typedef struct STRUCT_PLAYER_SPAWN
{
	float  x;
	float  y;
	float  z;
	float  rot;
	long   team;
	float  unknown2[8];
	bool selected;
	bool moving;
}PLAYER_SPAWN;

PLAYER_SPAWN readPlayerSpawnFromFile(NSFile *file,unsigned long magic);
MP_EQUIP readMPEquipFromFile(NSFile *file,unsigned long magic);
SCENERY_SPAWN readScenerySpawnFromFile(NSFile *file, unsigned long magic);
SCENERY_REF readSceneryRefFromFile(NSFile *file,unsigned long magic);
SKYBOX readSkyboxFromFile(NSFile *file, unsigned long magic);
VEHICLE_SPAWN readVehicleSpawnFromFile(NSFile *file,unsigned long magic);
SCNR_HEADER readScnrHeaderFromFile(NSFile *file, unsigned long magic);
VEHICLE_REF readVehicleRefFromFile(NSFile *file, unsigned long magic);