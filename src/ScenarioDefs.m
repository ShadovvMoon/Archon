#import "ScenarioDefs.h"
#import "NSFile.h"
SCNR_HEADER readScnrHeaderFromFile(NSFile *file, unsigned long magic)
{
	SCNR_HEADER header;
	[file readIntoStruct:header.unk_str1 size:16];
		[file readIntoStruct:header.unk_str2 size:16];
		[file readIntoStruct:header.unk_str3 size:16];
		header.SkyBox = readReflexiveFromFile(file,magic);
		header.unk1 = [file readDword];
		header.ChildScenarios = readReflexiveFromFile(file,magic);
		[file readIntoStruct:header.unneeded1 size:46 * sizeof(long)];
		header.EditorScenarioSize = [file readDword];
		header.unk2 = [file readDword];
		header.unk3 = [file readDword];
		header.pointertoindex = [file readDword];
		[file readIntoStruct:header.unneeded2 size:2* sizeof(long)];
		header.pointertoendofindex = [file readDword];
		[file readIntoStruct:header.zero1 size:57 * sizeof(long)];
		header.ObjectNames = readReflexiveFromFile(file,magic);
		header.Scenery = readReflexiveFromFile(file,magic);
		header.SceneryRef = readReflexiveFromFile(file,magic);
		header.Biped = readReflexiveFromFile(file,magic);
		header.BipedRef = readReflexiveFromFile(file,magic);
		header.Vehicle = readReflexiveFromFile(file,magic);
		header.VehicleRef = readReflexiveFromFile(file,magic);
		header.Equip = readReflexiveFromFile(file,magic);
		header.EquipRef = readReflexiveFromFile(file,magic);
		header.Weap = readReflexiveFromFile(file,magic);
		header.WeapRef = readReflexiveFromFile(file,magic);
		header.DeviceGroups = readReflexiveFromFile(file,magic);
		header.Machine = readReflexiveFromFile(file,magic);
		header.MachineRef = readReflexiveFromFile(file,magic);
		header.Control = readReflexiveFromFile(file,magic);
		header.ControlRef = readReflexiveFromFile(file,magic);
		header.LightFixture = readReflexiveFromFile(file,magic);
		header.LightFixtureRef = readReflexiveFromFile(file,magic);
		header.SoundScenery = readReflexiveFromFile(file,magic);
		header.SoundSceneryRef = readReflexiveFromFile(file,magic);
		//7 unknown reflexives
		[file skipBytes:7 * sizeof(reflexive)];
		header.PlayerStartingProfile = readReflexiveFromFile(file,magic);
		header.PlayerSpawn = readReflexiveFromFile(file,magic);
		header.TriggerVolumes = readReflexiveFromFile(file,magic);
		header.Animations = readReflexiveFromFile(file,magic);
		header.MultiplayerFlags = readReflexiveFromFile(file,magic);
		header.MpEquip = readReflexiveFromFile(file,magic);
		header.StartingEquip = readReflexiveFromFile(file,magic);
		header.BspSwitchTrigger = readReflexiveFromFile(file,magic);
		header.Decals = readReflexiveFromFile(file,magic);
		header.DecalsRef = readReflexiveFromFile(file,magic);
		header.DetailObjCollRef = readReflexiveFromFile(file,magic);
		//7 unknown reflexives
		[file skipBytes:7 * sizeof(reflexive)];
		header.ActorVariantRef = readReflexiveFromFile(file,magic);
		header.Encounters = readReflexiveFromFile(file,magic);
		header.CommandLists = readReflexiveFromFile(file,magic);
		header.Unknown2 = readReflexiveFromFile(file,magic);
		header.StartingLocations = readReflexiveFromFile(file,magic);
		header.Platoons = readReflexiveFromFile(file,magic);
		header.AiConversations = readReflexiveFromFile(file,magic);
		header.ScriptSyntaxDataSize = [file readDword];
		header.Unknown4 = [file readDword];
		header.ScriptCrap = readReflexiveFromFile(file,magic);
		header.Commands = readReflexiveFromFile(file,magic);
		header.Points = readReflexiveFromFile(file,magic);
		header.AiAnimationRefs = readReflexiveFromFile(file,magic);
		header.GlobalsVerified = readReflexiveFromFile(file,magic);
		header.AiRecordingRefs = readReflexiveFromFile(file,magic);
		header.Unknown5 = readReflexiveFromFile(file,magic);
		header.Participants = readReflexiveFromFile(file,magic);
		header.Lines = readReflexiveFromFile(file,magic);
		header.ScriptTriggers = readReflexiveFromFile(file,magic);
		header.VerifyCutscenes = readReflexiveFromFile(file,magic);
		header.VerifyCutsceneTitle = readReflexiveFromFile(file,magic);
		header.SourceFiles = readReflexiveFromFile(file,magic);
		header.CutsceneFlags = readReflexiveFromFile(file,magic);
		header.CutsceneCameraPoi = readReflexiveFromFile(file,magic);
		header.CutsceneTitles = readReflexiveFromFile(file,magic);
		header.SoundSceneryRef = readReflexiveFromFile(file,magic);
		
		//8 unknown reflexives
		[file skipBytes:8*sizeof(reflexive)];
		header.Unknown7[0] = [file readDword];
		header.Unknown7[1] = [file readDword];
		[file skipBytes:-12];
		header.StructBsp = readReflexiveFromFile(file,magic);

	return header;


}


MP_EQUIP readMPEquipFromFile(NSFile *file,unsigned long magic)
{
	MP_EQUIP e;
	[file skipBytes:16*4];
	e.x = [file readFloat];
	e.y = [file readFloat];
	e.z = [file readFloat];
	e.yaw = [file readFloat];
	e.unk1 = 0;
	e.unk2 = 0;
	e.itmc = readReferenceFromFile(file,magic);
	[file skipBytes:12*4];
	e.selected = FALSE;
	e.moving = FALSE;
	return e;
}
PLAYER_SPAWN readPlayerSpawnFromFile(NSFile *file,unsigned long magic)
{
	PLAYER_SPAWN p;
	p.x = [file readFloat];
	p.y = [file readFloat];
	p.z = [file readFloat];
	p.rot = [file readFloat];
	p.team = [file readDword];
	[file skipBytes:8*4];
	p.selected = FALSE;
	p.moving = FALSE;
	return p;
}
SCENERY_SPAWN readScenerySpawnFromFile(NSFile *file, unsigned long magic)
{
	SCENERY_SPAWN n;
	n.numid=[file readWord];
	n.flag = [file readWord];
	n.unk1 = [file readDword];
	int x;
	for (x=0;x<3;x++)
		n.coord[x]=[file readFloat];
	for (x=0;x<3;x++)
		n.rotation[x]=[file readFloat];
	[file skipBytes:10*4];
	n.selected = FALSE;
	n.moving = FALSE;
	return n;
}
SCENERY_REF readSceneryRefFromFile(NSFile *file,unsigned long magic)
{
	SCENERY_REF n;
	n.sceneryRef = readReferenceFromFile(file,magic);
	[file skipBytes:8*4];
	return n;
}
SKYBOX readSkyboxFromFile(NSFile *file, unsigned long magic)
{
	SKYBOX sky;
	sky.skybox = readReferenceFromFile(file,magic);
	return sky;
}
VEHICLE_SPAWN readVehicleSpawnFromFile(NSFile *file,unsigned long magic)
{
	VEHICLE_SPAWN vehi;
	vehi.numid = [file readWord];
	vehi.flag = [file readWord];
	vehi.unknown1 = [file readDword];
	vehi.x = [file readFloat];
	vehi.y = [file readFloat];
	vehi.z = [file readFloat];
	vehi.rotx = [file readFloat];
	vehi.roty = [file readFloat];
	vehi.rotz = [file readFloat];
	
	int x;
	for (x=0;x<22;x++)
		vehi.unknown2[x] = [file readDword];
	vehi.selected = FALSE;
	vehi.moving = FALSE;
	return vehi;
	
	
}
VEHICLE_REF readVehicleRefFromFile(NSFile *file, unsigned long magic)
{
	VEHICLE_REF vehi;
	vehi.vehicle = readReferenceFromFile(file,magic);
	int x;
	for (x=0;x<8;x++)
	     vehi.zero[x]=0;
	[file skipBytes:8*4];
	return vehi;
}
