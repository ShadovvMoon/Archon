//
//  Scenario.m
//  swordedit
//
//  Created by Fred Havemeyer on 5/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Scenario.h"
#import "BSP.h"
#import "Bitmask.h"

//#import <SecurityFoundation/SFAuthorization.h>
//#import <Security/AuthorizationTags.h>
#import "unistd.h"


int compare(const void *a, const void *b);

#define EndianSwap64(x) (((x & 0xFF00000000000000) >> 56) | ((x & 0x00FF000000000000) >> 40) | ((x & 0x0000FF0000000000) >> 24) | ((x & 0x000000FF00000000) >> 8) | ((x & 0x00000000FF000000) << 8) | ((x & 0x0000000000FF0000) << 24) | ((x & 0x000000000000FF00) << 40) |    ((x & 0x00000000000000FF) << 56))
#define EndianSwap32(x) (((x & 0xFF000000) >> 24) | ((x & 0x00FF0000) >> 8) | ((x & 0x0000FF00) << 8) | ((x & 0x000000FF) << 24))
#define EndianSwap16(x) (((x & 0x00FF) << 8) | ((x & 0xFF00) >> 8))

@implementation Scenario
- (id)initWithMapFile:(HaloMap *)map
{
	if ((self = [super initWithDataFromFile:map]) != nil)
	{
		_mapfile = [map retain];
		mapMagic = [map getMagic];
	}
	return self;
}
- (void)dealloc
{
	[scenTagArray removeAllObjects];
	[scenModelArray removeAllObjects];
	[inactiveScenTagArray removeAllObjects];
	[itmcTagArray removeAllObjects];
	[itmcModelArray removeAllObjects];
	[itmcModelLookup removeAllObjects];
	[netgameFlagIDLookup removeAllObjects];
	[netgameFlagIndexLookup removeAllObjects];
	[machTagArray removeAllObjects];
	[inactiveMachTagArray removeAllObjects];
	
	[scenTagArray release];
	[scenModelArray release];
	[inactiveScenTagArray release];
	[itmcTagArray release];
	[itmcModelArray release];
	[itmcModelLookup release];
	[netgameFlagIDLookup release];
	[netgameFlagIndexLookup release];
	[machTagArray release];
	[inactiveMachTagArray release];

	[mapBsp release];
	[_mapfile release];
	free (scnr);
	free(vehi_references);
	free(vehi_spawns);
	free(scen_references);
	free(scen_spawns);
	free(item_spawns);
	free(mach_references);
	free(device_groups);
	free(mach_spawns);
	free(spawns);
	free(mp_flags);
	[super dealloc];
}


-(void)resetMachineReferences
{
}






- (BOOL)loadScenario
{
	int i;
	
	// Allocate the memory we need for the scenario
	#ifdef __DEBUG__
	NSLog(@"Scenario length: 0x%X and Scenario Start: 0x%x", [self tagLength], [self tagLocation]);
	#endif
	scnr = (char *)malloc([self tagLength]);
	[_mapfile readBlockOfDataAtAddress:scnr size_of_buffer:[self tagLength] address:[self tagLocation]];
	
	_reflexCounter = 0;
	
	[self readScenario:&header.unk_str1 size:0x10];
	[self readScenario:&header.unk_str2 size:0x10];
	[self readScenario:&header.unk_str3 size:0x10];
	
	[self readScenarioReflexive:&header.SkyBox];
	
	[self readScenario:&header.unk1 size:0x4];
	
	[self readScenarioReflexive:&header.ChildScenarios];
	
	[self readScenario:&header.unneeded1 size:(0xB8)];
	
	[self readScenario:&header.EditorScenarioSize size:0x4];
	[self readScenario:&header.unk2 size:0x4];
	[self readScenario:&header.unk3 size:0x4];
	[self readScenario:&header.pointertoindex size:4];
	
	[self readScenario:&header.unneeded2 size:(0x8)];
	
	[self readScenario:&header.pointertoendofindex size:0x4];
	
	[self readScenario:&header.zero1 size:(0xE4)];
	
	// Now we can continue on to read the reflexives pointing to the interesting stuff
	
	// Lots 'O Reflexives
	[self readScenarioReflexive:&header.ObjectNames];
	
	// Scenery Spawns
	[self readScenarioReflexive:&header.Scenery];
	[self readScenarioReflexive:&header.SceneryRef];
	
	// Biped Spawns
	[self readScenarioReflexive:&header.Biped];
	[self readScenarioReflexive:&header.BipedRef];
	
	// Vehicle Spawns
	[self readScenarioReflexive:&header.Vehicle];
	[self readScenarioReflexive:&header.VehicleRef];
	
	// Equipment Spawns
	[self readScenarioReflexive:&header.Equip];
	[self readScenarioReflexive:&header.EquipRef];
	
	// Weapon Spawns?
	[self readScenarioReflexive:&header.Weap];
	[self readScenarioReflexive:&header.WeapRef];
	
	// Device groups, whatever the hell those are
	[self readScenarioReflexive:&header.DeviceGroups];
	
	// Machines
	[self readScenarioReflexive:&header.Machine];
	[self readScenarioReflexive:&header.MachineRef];
	
	// Control?
	[self readScenarioReflexive:&header.Control];
	[self readScenarioReflexive:&header.ControlRef];
		
	// Light Fixtures!
	[self readScenarioReflexive:&header.LightFixture];
	[self readScenarioReflexive:&header.LightFixtureRef];
	
	// Sound Scenery
	[self readScenarioReflexive:&header.SoundScenery];
	[self readScenarioReflexive:&header.SoundSceneryRef];
	
	// More reflexives again!
	// There seem to be several unknowns here...
	for (i = 0; i < 7; i++)
		[self readScenarioReflexive:&header.Unknown1[i]];
	//positionInScenario += 84;
	
	[self readScenarioReflexive:&header.PlayerStartingProfile];
	
	// Player spawn
	[self readScenarioReflexive:&header.PlayerSpawn];
	[self readScenarioReflexive:&header.TriggerVolumes];
	[self readScenarioReflexive:&header.Animations];
	
	// CTF Flag location, ctf vehicles, race track, hill, ball, teleporters, all the good stuff
	//[self readScenarioReflexive:&header.MultiplayerFlags];
	[self readScenarioReflexive:&header.MultiplayerFlags];

	// MP Equipment, aka weapon spawns
	[self readScenarioReflexive:&header.MpEquip];
	[self readScenarioReflexive:&header.StartingEquip];
	[self readScenarioReflexive:&header.BspSwitchTrigger];
	[self readScenarioReflexive:&header.Decals];
	[self readScenarioReflexive:&header.DecalsRef];
	[self readScenarioReflexive:&header.DetailObjCollRef];
	
	for (i = 0; i < 7; i++)
		[self readScenarioReflexive:&header.Unknown3[i]];
	//positionInScenario += 84;
	
	[self readScenarioReflexive:&header.ActorVariantRef];
	[self readScenarioReflexive:&header.Encounters];
    
	[self readScenarioReflexive:&header.CommandLists]; //Confirm
	[self readScenarioReflexive:&header.Unknown2]; //Ai animation refs
	[self readScenarioReflexive:&header.StartingLocations]; //Ai script refs
	[self readScenarioReflexive:&header.Platoons]; //Ai recording refs
	[self readScenarioReflexive:&header.AiConversations]; //Ai conversations

	/* NEED TO WORK ON THIS, KK? */
	NSLog(@"header.ScriptDataSize position: 0x%x", positionInScenario);
	[self readScenario:&header.ScriptDataSize size:4];

	[self readScenario:&header.Unknown4 size:4];
	/* TO WORK ON ^^^^ */
	
	[self readScenarioReflexive:&header.ScriptCrap];
	[self readScenarioReflexive:&header.Commands];
	[self readScenarioReflexive:&header.Points];
	[self readScenarioReflexive:&header.AiAnimationRefs];
	[self readScenarioReflexive:&header.GlobalsVerified];
	[self readScenarioReflexive:&header.AiRecordingRefs];
	[self readScenarioReflexive:&header.Unknown5];
	[self readScenarioReflexive:&header.Participants];
	[self readScenarioReflexive:&header.Lines];
	[self readScenarioReflexive:&header.ScriptTriggers];
	[self readScenarioReflexive:&header.VerifyCutscenes];
	[self readScenarioReflexive:&header.VerifyCutsceneTitle];
	[self readScenarioReflexive:&header.SourceFiles];
	[self readScenarioReflexive:&header.CutsceneFlags];
	[self readScenarioReflexive:&header.CutsceneCameraPoi];
	[self readScenarioReflexive:&header.CutsceneTitles];
	
	// Seems to be 8 more unknown reflexives. Damn there are a lot of these!
	for (i = 0; i < 8; i++)
		[self readScenarioReflexive:&header.Unknown6[i]];
	//positionInScenario += 96;
	
	[self readScenario:&header.Unknown7 size:(8)];
	
	positionInScenario = 0x5A4;
	
	[self readScenarioReflexive:&header.StructBsp];
	
	#ifdef __DEBUG__
	NSLog(@"Position of BSP Reflexive in mapfile => 0x%x", (header.StructBsp.location_in_mapfile + resolvedOffset));
	#endif
	
	header.StructBsp.offset += resolvedOffset;
	
	// I need to add on support for teleporters and for machines and other things hur
    bipd_references = malloc(sizeof(bipd_reference) * header.BipedRef.chunkcount);
	vehi_references = malloc(sizeof(vehicle_reference) * header.VehicleRef.chunkcount);
	vehi_spawns = malloc(sizeof(vehicle_spawn) * header.Vehicle.chunkcount);
	scen_references = malloc(sizeof(scenery_reference) * header.SceneryRef.chunkcount);
	scen_spawns = malloc(sizeof(scenery_spawn) * header.Scenery.chunkcount);
	item_spawns = malloc(sizeof(mp_equipment) * header.MpEquip.chunkcount);
	spawns = malloc(sizeof(player_spawn) * header.PlayerSpawn.chunkcount);
	mp_flags = malloc(sizeof(multiplayer_flags) * header.MultiplayerFlags.chunkcount);
	skies = malloc(sizeof(SkyBox) * header.SkyBox.chunkcount);
	mach_references = malloc(sizeof(machine_ref) * header.MachineRef.chunkcount);
	device_groups = malloc(sizeof(device_group) * header.DeviceGroups.chunkcount);
	mach_spawns = malloc(sizeof(machine_spawn) * header.Machine.chunkcount);
	encounters = malloc(sizeof(encounter) * header.Encounters.chunkcount);
	
    memset(bipd_references,0,sizeof(bipd_reference) * header.BipedRef.chunkcount);
	memset(vehi_references,0,sizeof(vehicle_reference) * header.VehicleRef.chunkcount);
	memset(vehi_spawns, 0, sizeof(vehicle_spawn) * header.Vehicle.chunkcount);
	memset(scen_references, 0, sizeof(scenery_reference) * header.SceneryRef.chunkcount);
	memset(scen_spawns, 0, sizeof(scenery_spawn) * header.Scenery.chunkcount);
	memset(item_spawns, 0, sizeof(mp_equipment) * header.MpEquip.chunkcount);
	memset(spawns, 0, sizeof(player_spawn) * header.PlayerSpawn.chunkcount);
	memset(mp_flags, 0, sizeof(multiplayer_flags) * header.MultiplayerFlags.chunkcount);
	memset(skies, 0, sizeof(SkyBox) * header.SkyBox.chunkcount);
	memset(mach_references, 0, sizeof(machine_ref) * header.MachineRef.chunkcount);
	memset(mach_spawns, 0, sizeof(machine_spawn) * header.Machine.chunkcount);
	memset(device_groups, 0, sizeof(device_group) * header.DeviceGroups.chunkcount);
	memset(encounters, 0, sizeof(encounter) * header.Encounters.chunkcount);
	
	NSLog(@"BIPD PALETTE SIZE %d", header.BipedRef.chunkcount);
  
    
	int x;
	/* BEGIN VEHICLE SPAWNS */
	positionInScenario = header.VehicleRef.offset;
	for (x = 0; x < header.VehicleRef.chunkcount; x++)
		vehi_references[x] = [self readVehicleReference];
	vehi_ref_count = header.VehicleRef.chunkcount;
	positionInScenario = header.Vehicle.offset;
	for (x = 0; x < header.Vehicle.chunkcount; x++)
		vehi_spawns[x] = [self readVehicleSpawn];
	vehicle_spawn_count = header.Vehicle.chunkcount;
	/* END VEHICLE SPAWNS */
    
    /* BEGIN BIPD SPAWNS */
	positionInScenario = header.BipedRef.offset;
	for (x = 0; x < header.BipedRef.chunkcount; x++)
		bipd_references[x] = (bipd_reference)[self readBipdReference];
	bipd_ref_count = header.BipedRef.chunkcount;

	/* END VEHICLE SPAWNS */
	
	/* BEGIN SCENERY SPAWNS */
	positionInScenario = header.SceneryRef.offset;
	for (x = 0; x < header.SceneryRef.chunkcount; x++)
		scen_references[x] = [self readSceneryReference];
	scen_ref_count = header.SceneryRef.chunkcount;
	positionInScenario = header.Scenery.offset;
	for (x = 0; x < header.Scenery.chunkcount; x++)
		scen_spawns[x] = [self readScenerySpawn];
	scenery_spawn_count = header.Scenery.chunkcount;
	/* END SCENERY SPAWNS */
	
	/* BEGIN MP EQUIPMENT */
	positionInScenario = header.MpEquip.offset;
	for (x = 0; x < header.MpEquip.chunkcount; x++)
		item_spawns[x] = [self readMPEquip];
	item_spawn_count = header.MpEquip.chunkcount;
	/* END MP EQUIPMENT */
	
	/* BEGIN PLAYER SPAWNS */
	positionInScenario = header.PlayerSpawn.offset;
	for (x = 0; x < header.PlayerSpawn.chunkcount; x++)
		spawns[x] = [self readPlayerSpawn];
	player_spawn_count = header.PlayerSpawn.chunkcount;
	/* END PLAYER SPAWNS */
	
	/* BEGIN MULTIPLAYER FLAGS */
	[self readMultiplayerFlags];
	multiplayer_flags_count = header.MultiplayerFlags.chunkcount;
	/* END MULTIPLAYER FLAGS */
	
	/* BEGIN MACHINES */
	mach_ref_count = 0;
	NSLog(@"Machine spawn pos in map: 0x%x", (header.Machine.offset + [self offsetInMap]));
    NSLog(@"Machine size %lu %lu", sizeof(machine_ref), sizeof(machine_ref) * header.MachineRef.chunkcount);
	positionInScenario = header.MachineRef.offset;
	for (x = 0; x < header.MachineRef.chunkcount; x++)
		mach_references[x] = [self readMachineReference];
	mach_ref_count = header.MachineRef.chunkcount;
	
    NSLog(@"Reading spawns");
	positionInScenario = header.Machine.offset;
	for (x = 0; x < header.Machine.chunkcount; x++)
		mach_spawns[x] = [self readMachineSpawn];
	mach_spawn_count = header.Machine.chunkcount;
	/* END MACHINES */
	
	
	/* BEGIN DEVICE GROUPS */
	device_group_count = 0;
	NSLog(@"Device group spawn pos in map: 0x%x", (header.DeviceGroups.offset + [self offsetInMap]));
	positionInScenario = header.DeviceGroups.offset;
	for (x = 0; x < header.DeviceGroups.chunkcount; x++)
		device_groups[x] = [self readDeviceGroup];
	device_group_count = header.DeviceGroups.chunkcount;
	
	/* END DEVICE GROUPS */
	
	/* BEGIN ENCOUNTERS */
	encounters_count = 0;
	NSLog(@"Device group spawn pos in map: 0x%x", (header.Encounters.offset + [self offsetInMap]));
	positionInScenario = header.Encounters.offset;
	for (x = 0; x < header.Encounters.chunkcount; x++)
		encounters[x] = [self readEncounter];
	encounters_count = header.Encounters.chunkcount;
	
	/* END ENCOUNTERS */
	
	positionInScenario = header.SkyBox.offset;
	skybox_count = header.SkyBox.chunkcount;
	for (x = 0; x < header.SkyBox.chunkcount; x++)
		skies[x] = [self readSkyBox];
	skybox_count = header.SkyBox.chunkcount;
	
	// Lets now construct our list of all used reflexives
	[self findActiveReflexives];
	
	// Now lets build our chunk sizes
	[self buildChunkSizes];
	NSLog(@"VEHICLE CHUNK SIZE %d", header.Vehicle.chunkSize);
    
	// Now lets find the size and location of the last bit of the scenario
	// (This never changes unless we increase the size of the scenario)
	[self findLastBitOfScenario];
	
	// Finally, lets pair the models with the spawn points
	[self pairModelsWithSpawn];
	
	[self buildAllTagArrays];
	
	#ifdef __DEBUG__
	printf("\n");
	#endif
	
	// Our scenario's data has been loaded! Woo Woo!
	// Now lets process this data
	return TRUE;
}
- (void)readScenario:(void *)buffer size:(int)size
{
	memcpy(buffer, &scnr[positionInScenario], size);
	positionInScenario += size;
}
- (void)readScenarioAtAddress:(void *)buffer address:(int)address size:(int)size
{
	memcpy(buffer, &scnr[(((address > 0) && (address < [self tagLength])) ? address : 0)], size);
}
- (void)skipBytes:(int)count
{
	positionInScenario += count;
}
- (void)readScenarioReflexive:(reflexive *)reflex
{
	reflex->location_in_mapfile = positionInScenario;
	[self readScenario:&reflex->chunkcount size:0x4];
	[self readScenario:&reflex->offset size:0x4];
	[self readScenario:&reflex->zero size:0x4];
	
	
	
	reflex->offset -= ([_mapfile magic] + resolvedOffset);
	//NSLog(@"REFLEXIVE OFFSET %d", reflex->offset);
	reflex->newChunkCount = reflex->chunkcount; // Set this as such
	reflex->chunkSize = 0;
	reflex->refNumber=_reflexCounter;
	reflex->oldOffset = reflex->offset;
	
	_reflexLookup[_reflexCounter] = (unsigned int)reflex; // Here the reflexive ewre using is in the form of a pointer, so we can just add it to this table
	_reflexCounter++;
}
- (void)readScenarioReflexiveType:(reflexive_tag *)reflex
{
	[self readScenario:&reflex->chunkcount size:0x4];
	[self readScenario:&reflex->offset size:0x4];
	[self readScenario:&reflex->zero size:0x4];
		
	reflex->offset -= ([_mapfile magic] + resolvedOffset);
}
- (void)readScenarioReflexiveAtAddress:(reflexive *)reflex addr:(int)addr
{
	int tmpPos = positionInScenario;
	positionInScenario = addr;
	reflex->location_in_mapfile = positionInScenario;
	[self readScenario:&reflex->chunkcount size:0x4];
	[self readScenario:&reflex->offset size:0x4];
	[self readScenario:&reflex->zero size:0x4];
	reflex->offset -= ([_mapfile magic] + resolvedOffset);
	positionInScenario = tmpPos;
}
- (void)readScenarioTagReference:(TAG_REFERENCE *)ref
{
	[self readScenario:&ref->tag size:4];
	[self readScenario:&ref->NamePtr size:4];
	[self readScenario:&ref->unknown size:4];
	[self readScenario:&ref->TagId size:4];
}
- (void)readScenarioTagReferenceAtAddress:(TAG_REFERENCE *)ref addr:(int)addr
{
	int tmpPos = positionInScenario;
	positionInScenario = addr;
	[self readScenario:&ref->tag size:4];
	[self readScenario:&ref->NamePtr size:4];
	[self readScenario:&ref->unknown size:4];
	[self readScenario:&ref->TagId size:4];
	ref->NamePtr -= [_mapfile magic];
	positionInScenario = tmpPos;
}

- (mp_equipment)readMPEquip
{
	mp_equipment equip;
    [self readScenario:&equip.bitmask32 size:4];
    [self readScenario:&equip.type1 size:2];
    [self readScenario:&equip.type2 size:2];
    [self readScenario:&equip.type3 size:2];
    [self readScenario:&equip.type4 size:2];
    [self readScenario:&equip.team_index size:2];
    [self readScenario:&equip.spawn_time size:2];
    
    
	[self readScenario:&equip.unknown size:48];
	int i;
	for (i = 0; i < 3; i++)
		[self readScenario:&equip.coord[i] size:4];
	[self readScenario:&equip.yaw size:4];
	[self readScenarioTagReference:&equip.itmc];
	[self readScenario:&equip.unknown2 size:48];
	
	equip.isSelected = NO;
	equip.isMoving = NO;
	return equip;
}
- (player_spawn)readPlayerSpawn
{
	player_spawn spawn;
	int i;
	for (i = 0; i < 3; i++)
		[self readScenario:&spawn.coord[i] size:4];
	[self readScenario:&spawn.rotation size:4];
	if ([_mapfile isPPC])
	{
		[self readScenario:&spawn.bsp_index size:2];
		[self readScenario:&spawn.team_index size:2];
		[self readScenario:&spawn.type2 size:2];
		[self readScenario:&spawn.type1 size:2];
		[self readScenario:&spawn.type4 size:2];
		[self readScenario:&spawn.type3 size:2];
	}
	else
	{	
		[self readScenario:&spawn.team_index size:2];
		[self readScenario:&spawn.bsp_index size:2];
		[self readScenario:&spawn.type1 size:2];
		[self readScenario:&spawn.type2 size:2];
		[self readScenario:&spawn.type3 size:2];
		[self readScenario:&spawn.type4 size:2];
	}
	[self readScenario:&spawn.unknown size:24];
	//[self readScenario:&spawn.team size:4];
	//[self readScenario:spawn.unknown size:32];
	spawn.isSelected = NO;
	spawn.isMoving = NO;
	
	return spawn;
}
- (scenery_reference)readSceneryReference
{
	scenery_reference ref;
	[self readScenarioTagReference:&ref.scen_ref];
	[self readScenario:&ref.zero size:32];
	return ref;
}

- (scenery_spawn)readScenerySpawn
{
	scenery_spawn scen;
	int i;
	
	if ([_mapfile isPPC])
	{
		// Byte order shit
		[self readScenario:&scen.flag size:2];
		[self readScenario:&scen.numid size:2];
		[self readScenario:&scen.desired_permutation size:2];
		[self readScenario:&scen.not_placed size:2];
	}
	else
	{
		[self readScenario:&scen.numid size:2];
		[self readScenario:&scen.flag size:2];
		[self readScenario:&scen.not_placed size:2];
		[self readScenario:&scen.desired_permutation size:2];
	}
	for (i = 0; i < 3; i++)
		[self readScenario:&scen.coord[i] size:4];
	for (i = 0; i < 3; i++)
		[self readScenario:&scen.rotation[i] size:4];
	
	[self readScenario:&scen.unknown size:40];
	
	//NSLog(@"Desired permutation: 0x%x", scen.unknown1);
	
	scen.isSelected = NO;
	scen.isMoving = NO;
	
	return scen;
}
- (bipd_reference)readBipdReference
{
	bipd_reference ref;
	
	[self readScenarioTagReference:&ref.bipd_ref];
	[self readScenario:&ref.zero size:32];
	return ref;
}
- (vehicle_reference)readVehicleReference
{
	vehicle_reference ref;
	
	[self readScenarioTagReference:&ref.vehi_ref];
	[self readScenario:&ref.zero size:32];
	return ref;
}
- (vehicle_spawn)readVehicleSpawn
{
    /*vehicle_spawn vehi;
     int i;
     
     if ([_mapfile isPPC])
     {
     [self readScenario:&vehi.flag size:2];
     [self readScenario:&vehi.numid size:2];
     [self readScenario:&vehi.desired_permutation size:2];
     [self readScenario:&vehi.not_placed size:2];
     }
     else
     {
     [self readScenario:&vehi.numid size:2];
     [self readScenario:&vehi.flag size:2];
     [self readScenario:&vehi.not_placed size:2];
     [self readScenario:&vehi.desired_permutation size:2];
     }
     for (i = 0; i < 3; i++)
     [self readScenario:&vehi.coord[i] size:4];
     for (i = 0; i < 3; i++)
     [self readScenario:&vehi.rotation[i] size:4];
     
     [self readScenario:&vehi.unknown1 size:40];
     [self readScenario:&vehi.body_vitality size:4];
     [self readScenario:&vehi.flags size:4];
     [self readScenario:&vehi.unknown3 size:8];
     [self readScenario:&vehi.mpTeamIndex size:2];
     [self readScenario:&vehi.mpSpawnFlags size:8];
     
     [self readScenario:vehi.unknown2 size:22];*/
    
    /*
	vehicle_spawn vehi;
	int i;
	
	if ([_mapfile isPPC])
	{
        NSLog(@"PPC Vehicle");
		[self readScenario:&vehi.flag size:2];
		[self readScenario:&vehi.numid size:2];
		[self readScenario:&vehi.desired_permutation size:2];
		[self readScenario:&vehi.not_placed size:2];
	}
	else
	{
		[self readScenario:&vehi.numid size:2];
		[self readScenario:&vehi.flag size:2];
		[self readScenario:&vehi.not_placed size:2];
		[self readScenario:&vehi.desired_permutation size:2];
	}
	for (i = 0; i < 3; i++)
		[self readScenario:&vehi.coord[i] size:4];
	for (i = 0; i < 3; i++)
		[self readScenario:&vehi.rotation[i] size:4];
    
    [self readScenario:&vehi.unknown1 size:40]; //32
    [self readScenario:&vehi.body_vitality size:4]; //72
    [self readScenario:&vehi.flags size:2]; //76
    [self readScenario:&vehi.unknown3 size:10]; //78
    [self readScenario:&vehi.mpTeamIndex size:2]; //88
    [self readScenario:&vehi.mpSpawnFlags size:2]; //90
	[self readScenario:&vehi.unknown2 size:28];*/
    
    vehicle_spawn vehi;
	int i;
	
	if ([_mapfile isPPC])
	{
        NSLog(@"PPC Vehicle");
		[self readScenario:&vehi.flag size:2];
		[self readScenario:&vehi.numid size:2];
		[self readScenario:&vehi.desired_permutation size:2];
		[self readScenario:&vehi.not_placed size:2];
	}
	else
	{
		[self readScenario:&vehi.numid size:2];
		[self readScenario:&vehi.flag size:2];
		[self readScenario:&vehi.not_placed size:2];
		[self readScenario:&vehi.desired_permutation size:2];
	}
	for (i = 0; i < 3; i++)
		[self readScenario:&vehi.coord[i] size:4];
	for (i = 0; i < 3; i++)
		[self readScenario:&vehi.rotation[i] size:4];
    
	[self readScenario:&vehi.unknown2 size:88];
    
	vehi.isSelected = NO;
	vehi.isMoving = NO;
		
	return vehi;
}
- (SkyBox)readSkyBox
{
	SkyBox sky;
	[self readScenarioTagReference:&sky.skybox];
	[_mapfile readLongAtAddress:&sky.modelIdent address:[[_mapfile tagForId:sky.skybox.TagId] offsetInMap] + 0xC];
	NSLog(@"Skybox ID: 0x%x", sky.modelIdent);
	return sky;
}
- (machine_ref)readMachineReference
{
    NSLog(@"Reading machine ref");
	machine_ref machRef;
    NSLog(@"and 1");
	[self readScenarioTagReference:&machRef.machTag];
    NSLog(@"and a 2");
	[self readScenario:&machRef.zeros size:32];
    NSLog(@"and a 3");
	return machRef;
}

- (device_group)readDeviceGroup
{
	device_group machRef;
	[self readScenario:&machRef.name size:32];
	[self readScenario:&machRef.initial_value size:4];
	[self readScenario:&machRef.flags size:2];
	
	return machRef;
}

- (encounter)readEncounter
{
	NSLog(@"Reading encounter...");
	encounter machRef;
	
	[self readScenario:&machRef size:128];
    
	[self readScenarioReflexiveType:&machRef.squads];
	[self readScenarioReflexiveType:&machRef.platoons];
	[self readScenarioReflexiveType:&machRef.firing];
	[self readScenarioReflexiveType:&machRef.start_locations];
	
	NSLog(@"squads = %d", machRef.squads.chunkcount);
	NSLog(@"platoons = %d", machRef.platoons.chunkcount);
	NSLog(@"firing = %d", machRef.firing.chunkcount);
	NSLog(@"start_locations = %d", machRef.start_locations.chunkcount);
	
	NSLog(@"MACHINE TAG IS %d", sizeof(machRef)-sizeof(player_spawn)-sizeof(int));
	
	machRef.start_locs_count = 0;
	int x = 0;
	
	machRef.start_locs = malloc(sizeof(player_spawn) * machRef.start_locations.chunkcount);
	memset(machRef.start_locs, 0, sizeof(player_spawn) * machRef.start_locations.chunkcount);
	NSLog(@"Memory allocated.");
	int tmp_pos = positionInScenario;
	positionInScenario = machRef.start_locations.offset;
	NSLog(@"Position determined");
	for (x = 0; x < machRef.start_locations.chunkcount; x++)
	{
		NSLog(@"%d", x);
		machRef.start_locs[x] = [self readPlayerSpawn];
		NSLog(@"X: %f, %f, %f", machRef.start_locs[x].coord[0], machRef.start_locs[x].coord[1], machRef.start_locs[x].coord[2]);
	}
	NSLog(@"Locs increased");
	machRef.start_locs_count = machRef.start_locations.chunkcount;
	NSLog(@"Search successful");
	positionInScenario = tmp_pos;
	/* END PLAYER SPAWNS */
	//positionInScenario+=ENCOUNTER_CHUNK;
	
	NSLog(@"Player repaired!");
	
	return machRef;
}

- (machine_spawn)readMachineSpawn
{
	int i;
	machine_spawn mach;
	// Here's hoping this works.
	
	// This won't work with PPC computers
	//[self readScenario:&mach.numid size:0x40];
	
	mach.isSelected = NO;

    [self readScenario:&mach.numid size:2];
    [self readScenario:&mach.someflag size:2];
    [self readScenario:&mach.not_placed size:2];
    [self readScenario:&mach.desired_permutation size:2];
	
	for (i = 0; i < 3; i++)
		[self readScenario:&mach.coord[i] size:4];
	for (i = 0; i < 3; i++)
		[self readScenario:&mach.rotation[i] size:4];
		
    [self readScenario:&mach.unknown1 size:8];
    [self readScenario:&mach.powerGroup size:2];
    [self readScenario:&mach.positionGroup size:2];
    [self readScenario:&mach.flags size:2];
    [self readScenario:&mach.flags2 size:2];
	[self readScenario:&mach.zeros size:16];
	
	return mach;
}
- (void)readMultiplayerFlags
{
	int i;
	/*if (netgameFlagIDLookup)
	{
		[netgameFlagIDLookup removeAllObjects]; 
		[netgameFlagIDLookup release];
	}
	if (netgameFlagIndexLookup)
	{
		[netgameFlagIndexLookup removeAllObjects];
		[netgameFlagIndexLookup release];
	}
	
	netgameFlagIDLookup = [[NSMutableDictionary alloc] initWithCapacity:header.MultiplayerFlags.chunkcount];
	netgameFlagIndexLookup = [[NSMutableDictionary alloc] initWithCapacity:header.MultiplayerFlags.chunkcount];*/
	
	for (i = 0; i < header.MultiplayerFlags.chunkcount; i++)
	{
		positionInScenario = (header.MultiplayerFlags.offset + (i * 0x94));
		[self readScenario:&mp_flags[i].coord[0] size:4];
		[self readScenario:&mp_flags[i].coord[1] size:4];
		[self readScenario:&mp_flags[i].coord[2] size:4];
		[self readScenario:&mp_flags[i].rotation size:4];
		if ([_mapfile isPPC])
		{
			[self readScenario:&mp_flags[i].team_index size:2];
			[self readScenario:&mp_flags[i].type size:2];
		}
		else
		{
			[self readScenario:&mp_flags[i].type size:2];
			[self readScenario:&mp_flags[i].team_index size:2];
		}
		[self readScenarioTagReference:&mp_flags[i].item_used];
		if (mp_flags[i].type == teleporter_exit)
		{
			if (mp_flags[i].team_index > teleporter_pair_count)
				teleporter_pair_count = (mp_flags[i].team_index + 1);
			
			//NSLog(@"Teleporter exit! Team index: %d", mp_flags[i].team_index);
		}
		else if (mp_flags[i].type == teleporter_entrance)
		{
			//NSLog(@"Teleporter entrance! Team index: %d", mp_flags[i].team_index);
		}
		else
		{
			//NSLog(@"Something else!");
		}
		
		[netgameFlagIndexLookup setObject:[NSNumber numberWithInt:i] forKey:[NSNumber numberWithShort:mp_flags[i].team_index]];
		[netgameFlagIDLookup setObject:[NSNumber numberWithShort:mp_flags[i].team_index] forKey:[NSNumber numberWithInt:i]];
		
	}
	multiplayer_flags_count = i;
}
- (short)netgameFlagIDForIndex:(int)index
{
	return [[netgameFlagIDLookup objectForKey:[NSNumber numberWithInt:index]] shortValue];
}
- (int)netgameFlagIndexForID:(short)index
{
	return [[netgameFlagIndexLookup objectForKey:[NSNumber numberWithShort:index]] intValue];
}
- (void)pairModelsWithSpawn
{
	int x, i = 0;
	
	itmcTagArray = [[NSMutableArray alloc] initWithCapacity:item_spawn_count]; // This is incorrect, but fuck it
	itmcModelLookup = [[NSMutableDictionary alloc] initWithCapacity:item_spawn_count];
	
	
	for (x = 0; x < vehicle_spawn_count; x++)
	{
		if (vehi_references[vehi_spawns[x].numid].vehi_ref.TagId == 0xFFFFFFFF)
			vehi_spawns[x].modelIdent = 0xFFFFFFFF;
		else
			vehi_spawns[x].modelIdent = [self baseModelIdent:vehi_references[vehi_spawns[x].numid].vehi_ref.TagId];
	}
	for (x = 0; x < scenery_spawn_count; x++)
	{
		if (scen_references[scen_spawns[x].numid].scen_ref.TagId == 0xFFFFFFFF)
			scen_spawns[x].modelIdent = 0xFFFFFFFF;
		else
			scen_spawns[x].modelIdent = [self baseModelIdent:scen_references[scen_spawns[x].numid].scen_ref.TagId];
	}
	for (x = 0; x < item_spawn_count; x++)
	{
		long tempIdent;
		if (item_spawns[x].itmc.TagId == 0xFFFFFFFF)
			item_spawns[x].modelIdent = 0xFFFFFFFF;
		[_mapfile seekToAddress:([[_mapfile tagForId:item_spawns[x].itmc.TagId] offsetInMap] + 0x8C)];
		[_mapfile readLong:&tempIdent];
		item_spawns[x].modelIdent = [self baseModelIdent:tempIdent];
		
		if ([itmcModelLookup objectForKey:[NSNumber numberWithLong:item_spawns[x].itmc.TagId]] == nil)
		{
			[itmcModelLookup setObject:[NSNumber numberWithLong:i] forKey:[NSNumber numberWithLong:item_spawns[x].itmc.TagId]];
			[itmcTagArray addObject:[NSNumber numberWithLong:item_spawns[x].modelIdent]];
			i++;
		}
	}
	for (x = 0; x < mach_ref_count; x++)
	{
		if (mach_references[x].machTag.TagId == 0xFFFFFFFF)
			mach_references[x].modelIdent == 0xFFFFFFFF;
		else
			mach_references[x].modelIdent = [self baseModelIdent:mach_references[x].machTag.TagId];
	}
}
- (long)itmcModelForId:(long)ident
{
	#ifdef __DEBUG__
	NSLog(@"Model ident: %x", [[itmcTagArray objectAtIndex:[[itmcModelLookup objectForKey:[NSNumber numberWithLong:ident]] intValue]] longValue]);
	#endif
	return [[itmcTagArray objectAtIndex:[[itmcModelLookup objectForKey:[NSNumber numberWithLong:ident]] intValue]] longValue];
}
- (long)baseModelIdent:(long)ident
{
	// ident is the identity of the parent tag, ie weapon and such
	long newtagIdent;
	MapTag *tempTag = [_mapfile tagForId:ident];
	[_mapfile seekToAddress:([tempTag offsetInMap] + 0x34)];
	[_mapfile readLong:&newtagIdent];
	//NSLog(@"Tag offset: 0x%x", [tempTag offsetInMap]);
	return newtagIdent;
}

- (long)setBaseModelIdent:(long)newtagIdent ident:(long)ident
{
	// ident is the identity of the parent tag, ie weapon and such
	MapTag *tempTag = [_mapfile tagForId:ident];
	[_mapfile seekToAddress:([tempTag offsetInMap] + 0x34)];
	[_mapfile writeLong:newtagIdent];
	//NSLog(@"Tag offset: 0x%x", [tempTag offsetInMap]);
	return 1;
}

/* 

Accessor Methods

*/
- (SCNR_HEADER)header
{
	return header;
}
- (vehicle_reference *)vehi_references
{
	return vehi_references;
}
- (bipd_reference*)bipd_references
{
    return bipd_references;
}
- (vehicle_spawn *)vehi_spawns
{
	return vehi_spawns;
}
- (scenery_reference *)scen_references
{
	return scen_references;
}
- (scenery_spawn *)scen_spawns
{
	return scen_spawns;
}
- (mp_equipment *)item_spawns
{
	return item_spawns;
}
- (player_spawn *)spawns
{
	return spawns;
}
- (multiplayer_flags *)netgame_flags
{
	return mp_flags;
}
- (machine_ref *)mach_references
{
	return mach_references;
}
- (machine_spawn *)mach_spawns
{
	return mach_spawns;
}
- (encounter *)encounters
{
	return encounters;
}
- (SkyBox *)sky
{
	return skies;
}
-(int)skybox_count
{
    return skybox_count;
}
- (int)vehicle_spawn_count
{
	return vehicle_spawn_count;
}
- (int)bipd_ref_count
{
    return bipd_ref_count;
}
- (int)vehi_ref_count
{
	return vehi_ref_count;
}
- (int)scenery_spawn_count
{
	return scenery_spawn_count;
}
- (int)scen_ref_count
{
	return scen_ref_count;
}
- (int)item_spawn_count
{
	return item_spawn_count;
}
- (int)player_spawn_count
{
	return player_spawn_count;
}
- (int)multiplayer_flags_count
{
	return multiplayer_flags_count;
}
- (int)mach_ref_count
{
	return mach_ref_count;
}
- (int)mach_spawn_count
{
	return mach_spawn_count;
}
- (int)encounter_count
{
	return encounters_count;
}

/* 

End Accessor Methods 

*/


/*

Begin Duplication Methods

*/

- (unsigned int)duplicateScenarioObjectLocation:(int)type index:(int)index coord:(int)coo
{
	int retVal = 0;
	switch (type)
	{
		case s_scenery:
			retVal = ((s_scenery * MAX_SCENARIO_OBJECTS) + [self duplicateScenery:index coord:coo] );
			break;
		case s_machine:
			retVal = ((s_machine * MAX_SCENARIO_OBJECTS) + [self duplicateMachine:index coord:coo] );
			break;
	}
	return retVal;
}

- (unsigned int)duplicateScenarioObject:(int)type index:(int)index
{
	int retVal = 0;
	switch (type)
	{
		case s_playerspawn:
			retVal = ((s_playerspawn * MAX_SCENARIO_OBJECTS) + [self duplicatePlayerSpawn:index coord:0] );
			break;
        case s_scenery:
			retVal = ((s_scenery * MAX_SCENARIO_OBJECTS) + [self duplicateScenery:index coord:0] );
			break;
		case s_item:
        {
            
    
            
			retVal = ((s_item * MAX_SCENARIO_OBJECTS) + [self duplicateMpEquipment:index]);
			break;
        }
		case s_machine:
        {
       
			retVal = ((s_machine * MAX_SCENARIO_OBJECTS) + [self duplicateMachine:index coord:0]);
			break;
        }
		case s_vehicle:
        {
            //FILE *tmpFile = fopen("/Users/colbrans/Desktop/vehicle.seo","w+");
            //fwrite(&vehi_spawns[index],sizeof(vehicle_spawn),1,tmpFile);
            //fclose(tmpFile);
            
			retVal = ((s_vehicle * MAX_SCENARIO_OBJECTS) + [self duplicateVehicle:index]);
			break;
        }
	}
	return retVal;
}
- (int)duplicatePlayerSpawn:(int)index coord:(int)coo
{
	player_spawn tmpSpawn, *tmpSpawnPointer;
	int i;
	
	if (index < 0 || index > player_spawn_count)
		return 0;
    
	// Lets copy the data
	memcpy(&tmpSpawn,&spawns[index],sizeof(player_spawn));
	
    if (coo)
    {
        spawns[index].isSelected = YES;
    }
    else
    {
		spawns[index].isSelected = NO;
		for (i = 0; i < 2; i++)
			tmpSpawn.coord[i] -= 0.3;
    }
    
    
    
	tmpSpawn.isSelected = YES;
	
	// Now lets redo the counters.
	player_spawn_count += 1;
	header.PlayerSpawn.newChunkCount = player_spawn_count;
	
	tmpSpawnPointer = malloc(sizeof(player_spawn) * player_spawn_count);
	
	// Copy the old scenery
	memcpy(tmpSpawnPointer,spawns,(sizeof(player_spawn) * (player_spawn_count - 1)));
	memcpy(&tmpSpawnPointer[player_spawn_count-1], &tmpSpawn, sizeof(player_spawn));
	free(spawns);
	spawns = tmpSpawnPointer;
	
	return (player_spawn_count-1);
}

- (int)duplicateScenery:(int)index coord:(int)coo
{
	scenery_spawn tmpSpawn, *tmpSpawnPointer;
	int i;
	
	if (index < 0 || index > scenery_spawn_count)
		return 0;

	// Lets copy the data
	memcpy(&tmpSpawn,&scen_spawns[index],sizeof(scenery_spawn));
	
    if (coo)
    {
        scen_spawns[index].isSelected = YES;
    }
    else
    {
		scen_spawns[index].isSelected = NO;
		//for (i = 0; i < 2; i++)
		//	tmpSpawn.coord[i] -= [[_mapfile tagForId:tmpSpawn.modelIdent] bounding_box]->max[i];
    }
    
    
	tmpSpawn.isSelected = YES;
	tmpSpawn.numid = scen_spawns[index].numid;
	
    
	// Now lets redo the counters.
	scenery_spawn_count += 1;
	header.Scenery.newChunkCount = scenery_spawn_count;
	
	
	
	tmpSpawnPointer = malloc(sizeof(scenery_spawn) * scenery_spawn_count);
	
	// Copy the old scenery
	memcpy(tmpSpawnPointer,scen_spawns,(sizeof(scenery_spawn) * (scenery_spawn_count - 1)));
	memcpy(&tmpSpawnPointer[scenery_spawn_count-1], &tmpSpawn, sizeof(scenery_spawn));
	free(scen_spawns);
	scen_spawns = tmpSpawnPointer;
	
	return (scenery_spawn_count-1);
}

- (void)createSceneryReference:(TAG_REFERENCE)tag
{
	scenery_reference	*tmpRefPointer,
						tmpRef;
	
	if (![_mapfile isTag:tag.TagId])
		return;
	
	// Lets create our scenery spawn
	tmpRef.scen_ref = tag;
	
	scen_ref_count++;
	header.SceneryRef.newChunkCount = scen_ref_count;
	
	tmpRefPointer = (scenery_reference *)malloc(sizeof(scenery_reference) * scen_ref_count);
	
	// Copy the old shit
	memcpy(tmpRefPointer, scen_references, (sizeof(scenery_reference) * (scen_ref_count - 1)));
	memcpy(&tmpRefPointer[scen_ref_count-1], &tmpRef, sizeof(scenery_spawn));
	
	// Destroy the old data
	free(scen_references);
	
	// Set the pointer
	scen_references = tmpRefPointer;
	
	// Rebuild our array of scenery tags.
	[self buildArrayOfSceneryTags];
}

- (void)createDeviceGroup
{
	device_group	*tmpRefPointer,
	tmpRef;
	
	// Lets create our scenery spawn
	tmpRef.initial_value = 1;
	
	device_group_count++;
	header.DeviceGroups.newChunkCount = device_group_count;
	
	tmpRefPointer = (device_group *)malloc(sizeof(device_group) * device_group_count);
	
	// Copy the old shit
	memcpy(tmpRefPointer, device_groups, (sizeof(device_group) * (device_group_count - 1)));
	memcpy(&tmpRefPointer[device_group_count-1], &tmpRef, sizeof(device_group));
	
	// Destroy the old data
	free(device_groups);
	
	// Set the pointer
	device_groups = tmpRefPointer;
}

- (void)createMachineReference:(TAG_REFERENCE)tag
{
	machine_ref *newtmpRefPointer, tmpRef;
	
	if (![_mapfile isTag:tag.TagId])
    {
        NSLog(@"Not a tag!");
		return;
    }
	
	// Lets create our scenery spawn
	tmpRef.machTag = tag;
	tmpRef.modelIdent = [self baseModelIdent:tag.TagId];
	
	mach_ref_count++;
	header.MachineRef.newChunkCount = mach_ref_count;
	//NSLog(@"CR1");
	newtmpRefPointer = (machine_ref *)malloc(sizeof(machine_ref) * (mach_ref_count+1));
	//NSLog(@"CR2");
	/// Copy the old stuff
	memcpy(newtmpRefPointer, mach_references, (sizeof(machine_ref) * (mach_ref_count - 1)));
	//NSLog(@"CR3");
	
	memcpy(&newtmpRefPointer[mach_ref_count-1], &tmpRef, sizeof(machine_ref));
	//NSLog(@"CR4");
	// Destroy the old data
	
	free(mach_references);
	//NSLog(@"CR5");
	// Set the pointer
	mach_references = newtmpRefPointer;
	//NSLog(@"CR6");
	[self buildArrayOfMachineTags];
	//NSLog(@"CR7");
}
- (int)duplicateVehicle:(int)index
{
	vehicle_spawn tmpSpawn, *tmpSpawnPointer;
	int i;
	
	if (index < 0 || index > vehicle_spawn_count)
		return 0;
	
	vehi_spawns[index].isSelected = NO;
	
	// Lets copy the data
	memcpy(&tmpSpawn, &vehi_spawns[index], sizeof(vehicle_spawn));
	
	//for (i = 0; i < 2; i++)
		//tmpSpawn.coord[i] -= 0.5f;
	tmpSpawn.isSelected = YES;
	
	// Now lets redo the counters
	vehicle_spawn_count += 1;
	header.Vehicle.newChunkCount = vehicle_spawn_count;
	
	tmpSpawnPointer = malloc(sizeof(vehicle_spawn) * vehicle_spawn_count);
	
	// Copy the old items
	memcpy(tmpSpawnPointer, vehi_spawns, (sizeof(vehicle_spawn) * (vehicle_spawn_count - 1)));
	memcpy(&tmpSpawnPointer[vehicle_spawn_count-1],&tmpSpawn,sizeof(vehicle_spawn));
	free(vehi_spawns);
	vehi_spawns = tmpSpawnPointer;
	return (vehicle_spawn_count-1);
}
- (int)duplicateMpEquipment:(int)index
{
	mp_equipment tmpSpawn, *tmpSpawnPointer;
	int i;
	
	if (index < 0 || index > item_spawn_count)
		return 0;
		
	item_spawns[index].isSelected = NO;
	
	// Lets copy the data
	memcpy(&tmpSpawn, &item_spawns[index], sizeof(mp_equipment));
	
	
	//for (i = 0; i < 2; i++)
	//	tmpSpawn.coord[i] -= 0.5f;
	tmpSpawn.isSelected = YES;
	
	// Now lets redo the counters
	item_spawn_count += 1;
	header.MpEquip.newChunkCount = item_spawn_count;
	
	tmpSpawnPointer = malloc(sizeof(mp_equipment) * item_spawn_count);
	
	// Copy the old items
	memcpy(tmpSpawnPointer, item_spawns, (sizeof(mp_equipment) * (item_spawn_count - 1)));
	memcpy(&tmpSpawnPointer[item_spawn_count-1],&tmpSpawn,sizeof(mp_equipment));
	free(item_spawns);
	item_spawns = tmpSpawnPointer;
	return (item_spawn_count-1);
}
- (int)duplicateMachine:(int)index coord:(int)coo
{
	machine_spawn tmpSpawn, *tmpSpawnPointer;
	int i;
	
	if (index < 0 || index > mach_spawn_count)
		return 0;
	
	mach_spawns[index].isSelected = NO;
	
	// Lets copy the data
	memcpy(&tmpSpawn, &mach_spawns[index], sizeof(machine_spawn));
	
	if (coo)
    {
        mach_spawns[index].isSelected = YES;
    }
    else
    {
		mach_spawns[index].isSelected = NO;
		//for (i = 0; i < 2; i++)
		//	tmpSpawn.coord[i] -= 0.5f;
    }
	
	//mach_spawns[index].isSelected = YES;
	
	
	
	// Now lets redo the counters
	mach_spawn_count += 1;
	header.Machine.newChunkCount = mach_spawn_count;
	
	tmpSpawnPointer = malloc(sizeof(machine_spawn) * mach_spawn_count);
	
	// Copy the old items
	memcpy(tmpSpawnPointer, mach_spawns, (sizeof(machine_spawn) * (mach_spawn_count - 1)));
	memcpy(&tmpSpawnPointer[mach_spawn_count-1],&tmpSpawn,sizeof(machine_spawn));
	free(mach_spawns);
	mach_spawns = tmpSpawnPointer;
	return (mach_spawn_count-1);
}
- (void)createPlayerSpawn:(player_spawn)p_Spawn
{
	player_spawn *tmpSpawnPointer;
					
	if (p_Spawn.coord == NULL)
		return;
	
	p_Spawn.isSelected = YES;
	
	player_spawn_count++;
	header.PlayerSpawn.newChunkCount = player_spawn_count;
	
	tmpSpawnPointer = (player_spawn *)malloc(sizeof(player_spawn) * player_spawn_count);
	
	memcpy(tmpSpawnPointer, spawns, (sizeof(player_spawn) * (player_spawn_count - 1)));
	memcpy(&tmpSpawnPointer[player_spawn_count-1], &p_Spawn, sizeof(player_spawn));
	
	free(spawns);
	
	spawns = (player_spawn *)tmpSpawnPointer;
}
/*
	The coord for this should be the camera view coord or something BSP-specific
*/
- (unsigned int)createTeleporterPair:(float *)coord
{
	multiplayer_flags t_entrance, t_exit, *tmpSpawnPointer;
	int i;
	
	if (!coord[0] || !coord[1] || !coord[2])
		return 0;
	
	// Were good to go! Lets get a crackin.
	teleporter_pair_count++;
	
	// Lets create the teleporter entrance
	for (i = 0; i < 3; i++)
		t_entrance.coord[i] = coord[i];
	t_entrance.rotation = 0.0f;
	t_entrance.type = teleporter_entrance;
	t_entrance.team_index = teleporter_pair_count;
	t_entrance.isSelected = YES;
	
	// Now lets create the exit
	t_exit.coord[0] = coord[0];
	t_exit.coord[1] = (coord[1]);
	t_exit.coord[2] = coord[2];
	t_exit.rotation = 0.0f;
	t_exit.type = teleporter_exit;
	t_exit.team_index = teleporter_pair_count;
	t_exit.isSelected = NO;
	
	// Increment the counters for the 2 new netgame flag options
	multiplayer_flags_count += 2;
	header.MultiplayerFlags.newChunkCount = multiplayer_flags_count;
	
	tmpSpawnPointer = malloc(sizeof(multiplayer_flags) * multiplayer_flags_count);
	
	// Lets copy the old items now
	memcpy(tmpSpawnPointer, mp_flags, (sizeof(multiplayer_flags) * (multiplayer_flags_count - 2)));
	memcpy(&tmpSpawnPointer[multiplayer_flags_count-2], &t_entrance, sizeof(multiplayer_flags));
	memcpy(&tmpSpawnPointer[multiplayer_flags_count-1], &t_exit, sizeof(multiplayer_flags));
	free(mp_flags);
	mp_flags = tmpSpawnPointer;

	return ((s_netgame * MAX_SCENARIO_OBJECTS) + (multiplayer_flags_count - 2));
}

/*createPlayerSpawn*/
- (unsigned int)createBlueSpawn:(float *)coord
{
    NSLog(@"Create blue spawn");
	player_spawn tmpSpawn, *tmpSpawnPointer;
	
	NSString *scen = [[[NSBundle bundleForClass:[self class]]resourcePath] stringByAppendingString:@"/player_spawn_blue.seo"];
	FILE *tmpFile = fopen([scen cString],"rb+");
	fread(&tmpSpawn, sizeof(player_spawn), 1, tmpFile);
	fclose(tmpFile);
	
	// Lets copy the data
	if (!coord[0] || !coord[1] || !coord[2])
		return 0;
	
	tmpSpawn.coord[0] = coord[0];
	tmpSpawn.coord[1] = (coord[1]);
	tmpSpawn.coord[2] = coord[2];
	//tmpSpawn.rotation[0]=0;
	//tmpSpawn.rotation[1]=0;
	//tmpSpawn.rotation[2]=0;
	
	tmpSpawn.isSelected = NO;
	//tmpSpawn.numid=0;
	
	//tmpSpawn.modelIdent = [self baseModelIdent:item_[0].scen_ref.TagId];
	
	// Now lets redo the counters.
	player_spawn_count += 1;
	header.PlayerSpawn.newChunkCount = player_spawn_count;
	
	tmpSpawnPointer = malloc(sizeof(player_spawn) * player_spawn_count);
	
	// Copy the old scenery
	memcpy(tmpSpawnPointer,spawns,(sizeof(player_spawn) * (player_spawn_count - 1)));
	memcpy(&tmpSpawnPointer[player_spawn_count-1], &tmpSpawn, sizeof(player_spawn));
	free(spawns);
	spawns = tmpSpawnPointer;
	
	return (player_spawn_count-1);
}

- (unsigned int)createRedSpawn:(float *)coord
{
    NSLog(@"Create red spawn");
	player_spawn tmpSpawn, *tmpSpawnPointer;
	
	NSString *scen = [[[NSBundle bundleForClass:[self class]]resourcePath] stringByAppendingString:@"/player_spawn_red.seo"];
	FILE *tmpFile = fopen([scen cString],"rb+");
	fread(&tmpSpawn, sizeof(player_spawn), 1, tmpFile);
	fclose(tmpFile);
	
	// Lets copy the data
	if (!coord[0] || !coord[1] || !coord[2])
		return 0;
	
	tmpSpawn.coord[0] = coord[0];
	tmpSpawn.coord[1] = (coord[1]);
	tmpSpawn.coord[2] = coord[2];
	//tmpSpawn.rotation[0]=0;
	//tmpSpawn.rotation[1]=0;
	//tmpSpawn.rotation[2]=0;
	
	tmpSpawn.isSelected = NO;
	//tmpSpawn.numid=0;
	
	//tmpSpawn.modelIdent = [self baseModelIdent:item_[0].scen_ref.TagId];
	
	// Now lets redo the counters.
	player_spawn_count += 1;
	header.PlayerSpawn.newChunkCount = player_spawn_count;
	
	tmpSpawnPointer = malloc(sizeof(player_spawn) * player_spawn_count);
	
	// Copy the old scenery
	memcpy(tmpSpawnPointer,spawns,(sizeof(player_spawn) * (player_spawn_count - 1)));
	memcpy(&tmpSpawnPointer[player_spawn_count-1], &tmpSpawn, sizeof(player_spawn));
	free(spawns);
	spawns = tmpSpawnPointer;
	
	return (player_spawn_count-1);
}


- (unsigned int)createItem:(float *)coord
{
    NSLog(@"Create scenery");
	mp_equipment tmpSpawn, *tmpSpawnPointer;
	
	NSString *scen = [[[NSBundle bundleForClass:[self class]]resourcePath] stringByAppendingString:@"/item.seo"];
	FILE *tmpFile = fopen([scen cString],"rb+");
	fread(&tmpSpawn, sizeof(mp_equipment), 1, tmpFile);
	fclose(tmpFile);
	
	// Lets copy the data
	if (!coord[0] || !coord[1] || !coord[2])
		return 0;
	
	tmpSpawn.coord[0] = coord[0];
	tmpSpawn.coord[1] = (coord[1]);
	tmpSpawn.coord[2] = coord[2];
	//tmpSpawn.rotation[0]=0;
	//tmpSpawn.rotation[1]=0;
	//tmpSpawn.rotation[2]=0;
	
	tmpSpawn.isSelected = NO;
	//tmpSpawn.numid=0;
	
	//tmpSpawn.modelIdent = [self baseModelIdent:item_[0].scen_ref.TagId];
	
	// Now lets redo the counters.
	item_spawn_count += 1;
	header.MpEquip.newChunkCount = item_spawn_count;
	
	tmpSpawnPointer = malloc(sizeof(mp_equipment) * item_spawn_count);
	
	// Copy the old scenery
	memcpy(tmpSpawnPointer,item_spawns,(sizeof(mp_equipment) * (item_spawn_count - 1)));
	memcpy(&tmpSpawnPointer[item_spawn_count-1], &tmpSpawn, sizeof(mp_equipment));
	free(item_spawns);
	item_spawns = tmpSpawnPointer;
	
	return (item_spawn_count-1);
}

- (unsigned int)createVehicle:(float *)coord
{
	NSLog(@"createVehicle");
	vehicle_spawn tmpSpawn, *tmpSpawnPointer;
	
	NSString *scen = [[[NSBundle bundleForClass:[self class]]resourcePath] stringByAppendingString:@"/vehicle.seo"];
	FILE *tmpFile = fopen([scen cString],"rb+");
	fread(&tmpSpawn, sizeof(vehicle_spawn), 1, tmpFile);
	fclose(tmpFile);
	
	// Lets copy the data
	if (!coord[0] || !coord[1] || !coord[2])
		return 0;
	
	tmpSpawn.coord[0] = coord[0];
	tmpSpawn.coord[1] = (coord[1]);
	tmpSpawn.coord[2] = coord[2];
	tmpSpawn.rotation[0]=0;
	tmpSpawn.rotation[1]=0;
	tmpSpawn.rotation[2]=0;
	
	tmpSpawn.isSelected = NO;
	tmpSpawn.numid=0;
	//tmpSpawn.unknown2[14]=0;
    
	tmpSpawn.modelIdent = [self baseModelIdent:vehi_references[0].vehi_ref.TagId];
	
	// Now lets redo the counters.
	vehicle_spawn_count += 1;
	header.Vehicle.newChunkCount = vehicle_spawn_count;
	
	tmpSpawnPointer = malloc(sizeof(vehicle_spawn) * vehicle_spawn_count);
	
	// Copy the old scenery
	memcpy(tmpSpawnPointer,vehi_spawns,(sizeof(vehicle_spawn) * (vehicle_spawn_count - 1)));
	memcpy(&tmpSpawnPointer[vehicle_spawn_count-1], &tmpSpawn, sizeof(vehicle_spawn));
	free(vehi_spawns);
	vehi_spawns = tmpSpawnPointer;
	
	return (vehicle_spawn_count-1);
}


- (unsigned int)createSkull:(float *)coord
{
	NSLog(@"Create scenery");
	scenery_spawn tmpSpawn, *tmpSpawnPointer;
	
	NSString *scen = [[[NSBundle bundleForClass:[self class]]resourcePath] stringByAppendingString:@"/scenery.seo"];
	FILE *tmpFile = fopen([scen cString],"rb+");
	fread(&tmpSpawn, sizeof(scenery_spawn), 1, tmpFile);
	fclose(tmpFile);
	
	// Lets copy the data
	if (!coord[0] || !coord[1] || !coord[2])
		return 0;
	
	tmpSpawn.coord[0] = coord[0];
	tmpSpawn.coord[1] = (coord[1]);
	tmpSpawn.coord[2] = coord[2];
	tmpSpawn.rotation[0]=0;
	tmpSpawn.rotation[1]=0;
	tmpSpawn.rotation[2]=0;
	
	tmpSpawn.isSelected = NO;
	tmpSpawn.numid=0;
	
	tmpSpawn.modelIdent = [self baseModelIdent:scen_references[0].scen_ref.TagId];
	
	// Now lets redo the counters.
	scenery_spawn_count += 1;
	header.Scenery.newChunkCount = scenery_spawn_count;
	
	tmpSpawnPointer = malloc(sizeof(scenery_spawn) * scenery_spawn_count);
	
	// Copy the old scenery
	memcpy(tmpSpawnPointer,scen_spawns,(sizeof(scenery_spawn) * (scenery_spawn_count - 1)));
	memcpy(&tmpSpawnPointer[scenery_spawn_count-1], &tmpSpawn, sizeof(scenery_spawn));
	free(scen_spawns);
	scen_spawns = tmpSpawnPointer;
	
	return (scenery_spawn_count-1);
}

- (unsigned int)createMachine:(float *)coord
{
	NSLog(@"Creating machine");
	machine_spawn tmpSpawn, *tmpSpawnPointer;
	
	NSString *scen = [[[NSBundle bundleForClass:[self class]]resourcePath] stringByAppendingString:@"/machine.seo"];
	FILE *tmpFile = fopen([scen cString],"rb+");
	fread(&tmpSpawn, sizeof(machine_spawn), 1, tmpFile);
	fclose(tmpFile);
	
    NSLog(scen);
    
	// Lets copy the data
	if (!coord[0] || !coord[1] || !coord[2])
		return 0;
	
	// Lets create the teleporter entrance
	tmpSpawn.coord[0] = coord[0];
	tmpSpawn.coord[1] = (coord[1]);
	tmpSpawn.coord[2] = coord[2];
	tmpSpawn.rotation[0]=0;
	tmpSpawn.rotation[1]=0;
	tmpSpawn.rotation[2]=0;
	
	tmpSpawn.isSelected = NO;
	tmpSpawn.numid=0;
	
	//tmpSpawn.modelIdent = [self baseModelIdent:mach_references[0].machTag.TagId];
	
	// Now lets redo the counters.
	mach_spawn_count += 1;
	header.Machine.newChunkCount = mach_spawn_count;
	
	tmpSpawnPointer = malloc(sizeof(machine_spawn) * mach_spawn_count);
	
	// Copy the old scenery
	memcpy(tmpSpawnPointer,mach_spawns,(sizeof(machine_spawn) * (mach_spawn_count - 1)));
	memcpy(&tmpSpawnPointer[mach_spawn_count-1], &tmpSpawn, sizeof(machine_spawn));
	free(mach_spawns);
	mach_spawns = tmpSpawnPointer;
	
	return (mach_spawn_count-1);
}





/*

End Duplication Methods

*/

/*

Scenario object destruction

*/

- (void)deleteScenarioObject:(int)type index:(int)index
{
	switch (type)
	{
		case s_scenery:
			[self deleteScenery:index];
			break;
        case s_vehicle:
			[self deleteVehicle:index];
			break;
		case s_item:
			[self deleteMPEquipment:index];
			break;
		case s_netgame:
			[self deleteNetgameFlag:index];
			break;
        case s_playerspawn:
			[self deletePlayerSpawn:index];
			break;
		case s_machine:
			[self deleteMachine:index];
			break;
	}
}
- (void)deleteMPEquipment:(int)index
{
	mp_equipment *tmpSpawnPointer;
	int i, x;
	
	if (index < 0 || index > item_spawn_count)
		return;
	
	// Lets create our buffer
	tmpSpawnPointer = (mp_equipment *)malloc(sizeof(mp_equipment) * (item_spawn_count - 1));
	
	for (i = 0; i < index; i++)
		memcpy(&tmpSpawnPointer[i], &item_spawns[i], sizeof(mp_equipment));
	x = i;
	for (i = (index + 1); i < item_spawn_count; i++)
	{
		memcpy(&tmpSpawnPointer[x], &item_spawns[i], sizeof(mp_equipment));
		x++;
	}
	item_spawn_count--;
	header.MpEquip.newChunkCount = item_spawn_count;
	
	free(item_spawns);
	
	item_spawns = tmpSpawnPointer;
}

- (void)deleteVehicle:(int)index
{
	vehicle_spawn *tmpSpawnPointer;
	int i, x;
	
	if (index < 0 || index > vehicle_spawn_count)
		return;
    
	tmpSpawnPointer = (vehicle_spawn *)malloc(sizeof(vehicle_spawn) * (vehicle_spawn_count - 1));
    
	for (i = 0; i < index; i++)
		memcpy(&tmpSpawnPointer[i], &vehi_spawns[i], sizeof(vehicle_spawn));
	x = i;
	for (i = (index + 1); i < vehicle_spawn_count; i++)
	{
		memcpy(&tmpSpawnPointer[x], &vehi_spawns[i], sizeof(vehicle_spawn));
		x++;
	}
	vehicle_spawn_count--;
	header.Vehicle.newChunkCount = vehicle_spawn_count;
	
	free(vehi_spawns);
	
	vehi_spawns = (vehicle_spawn *)tmpSpawnPointer;
}
- (void)deleteScenery:(int)index
{
	scenery_spawn *tmpSpawnPointer;
	int i, x;
	
	if (index < 0 || index > scenery_spawn_count)
		return;
		
	tmpSpawnPointer = (scenery_spawn *)malloc(sizeof(scenery_spawn) * (scenery_spawn_count - 1));	
		
	for (i = 0; i < index; i++)
		memcpy(&tmpSpawnPointer[i], &scen_spawns[i], sizeof(scenery_spawn));
	x = i;
	for (i = (index + 1); i < scenery_spawn_count; i++)
	{
		memcpy(&tmpSpawnPointer[x], &scen_spawns[i], sizeof(scenery_spawn));
		x++;
	}
	scenery_spawn_count--;
	header.Scenery.newChunkCount = scenery_spawn_count;
	
	free(scen_spawns);
	
	scen_spawns = (scenery_spawn *)tmpSpawnPointer;
}

- (void)deleteMachine:(int)index
{
	machine_spawn *tmpSpawnPointer;
	int i, x;
	
	if (index < 0 || index > mach_spawn_count)
		return;
	
	tmpSpawnPointer = (machine_spawn *)malloc(sizeof(machine_spawn) * (mach_spawn_count - 1));	
	
	for (i = 0; i < index; i++)
		memcpy(&tmpSpawnPointer[i], &mach_spawns[i], sizeof(machine_spawn));
	x = i;
	for (i = (index + 1); i < mach_spawn_count; i++)
	{
		memcpy(&tmpSpawnPointer[x], &mach_spawns[i], sizeof(machine_spawn));
		x++;
	}
	mach_spawn_count--;
	header.Machine.newChunkCount = mach_spawn_count;
	
	free(mach_spawns);
	
	mach_spawns = (machine_spawn *)tmpSpawnPointer;
}

- (void)deletePlayerSpawn:(int)index
{
	player_spawn *tmpSpawnPointer;
	int i, x;
	
	if (index < 0 || index > player_spawn_count)
		return;
    
	tmpSpawnPointer = (player_spawn *)malloc(sizeof(player_spawn) * (player_spawn_count - 1));
    
	for (i = 0; i < index; i++)
		memcpy(&tmpSpawnPointer[i], &spawns[i], sizeof(player_spawn));
	x = i;
	for (i = (index + 1); i < player_spawn_count; i++)
	{
		memcpy(&tmpSpawnPointer[x], &spawns[i], sizeof(player_spawn));
		x++;
	}
	player_spawn_count--;
	header.PlayerSpawn.newChunkCount = player_spawn_count;
	
	free(spawns);
	
	spawns = (player_spawn *)tmpSpawnPointer;
	
}
- (void)deleteSceneryReference:(int)index
{
	//scenery_reference *tmpRefPointer;
	//int i, x
	
	if (index < 0 || index > scen_ref_count)
		return;
	/*tmpRefPointer = (scenery_reference *)malloc(sizeof(scenery_reference) * (scen_ref_count -1));
	
	for (i = 0; i < index; i++)
		memcpy(&tmpRefPointer[i], &scen_references[i], sizeof(scenery_reference));
	x = i;
	for (i = (index + 1); i < scen_ref_count; i++)
	{
		memcpy(&tmpRefPointer[x], &scen_references[i], sizeof(scenery_reference));
		x++;
	}
	scen_ref_count--;
	header.SceneryRef.newChunkCount = scen_ref_count;
	header.SceneryRef.chunkSize = SCENERY_REF_CHUNK;
	
	for (i = 0; i < scenery_spawn_count; i++)
	{
		if (scen_spawns[i].numid == index)
		{
			
		}
	}*/
	
	
	// EEP!
	//scen_references[index].scen_ref.TagId = 0xFFFFFFFF;
	//scen_references[index].scen_ref.NamePtr = 0x00000000;
	
	[self buildArrayOfSceneryTags];
}
- (void)deleteNetgameFlag:(int)index
{
	//NSMutableArray *netgameIndexArray;
	multiplayer_flags *tmpNetgameFlags;
	int i, x, type;
	
	if (index < 0 || index > multiplayer_flags_count)
		return;
	
	type = mp_flags[index].type;
	
	//				|
	// TODO: this:	V
	//if (type == teleporter_exit || type == teleporter_entrance)
	//	tmpNetgameFlags = (multiplayer_flags *)malloc(sizeof(multiplayer_flags) * (multiplayer_flags_count - 2));
	//else
	tmpNetgameFlags = (multiplayer_flags *)malloc(sizeof(multiplayer_flags) * (multiplayer_flags_count - 1));
	
	// Teleporters only
	//netgameIndexArray = [[netgameFlagIndexLookup objectsForKeys:[NSArray arrayWithObject:[NSNumber numberWithShort:mp_flags[index].team_index]] notFoundMarker:nil] retain];
	
	/*if (type == teleporter_exit || type == teleporter_entrance)
	{
		i = 0;
		for (x = 0; x < [netgameIndexArray count]; x++)
		{
			NSLog(@"HAI");
			for (; i < [[netgameIndexArray objectAtIndex:x] intValue]; i++)
			{
				memcpy(&tmpNetgameFlags[i], &mp_flags[i], sizeof(multiplayer_flags));
			}
			i++;
		}
		x = i;
		for (i = ([[netgameIndexArray objectAtIndex:x] intValue] + 1); i < multiplayer_flags_count; i++)
		{
			memcpy(&tmpNetgameFlags[x], &mp_flags[i], sizeof(multiplayer_flags));
			x++;
		}
	}
	else
	{*/
		for (i = 0; i < index; i++)
			memcpy(&tmpNetgameFlags[i], &mp_flags[i], sizeof(multiplayer_flags));
		x = i;
		for (i = (index + 1); i < multiplayer_flags_count; i++)
		{
			memcpy(&tmpNetgameFlags[x], &mp_flags[i], sizeof(multiplayer_flags));
			x++;
		}
	//}
	
	//x = i;
	//for (i = (index + 1); i < multiplayer_flags_count; i++)
	//{
	//	memcpy(&tmpNetgameFlags[x], &mp_flags[i], sizeof(multiplayer_flags));
	//	x++;
	//}
	//if (type == teleporter_entrance || type == teleporter_exit)
	//	multiplayer_flags_count -= 2;
	//else
	multiplayer_flags_count--;
		
	header.MultiplayerFlags.newChunkCount = multiplayer_flags_count;
	
	free(mp_flags);
	
	mp_flags = (multiplayer_flags *)tmpNetgameFlags;
}
/*

Item swapping 

*/
- (void)buildAllTagArrays
{
	[self buildArrayOfSceneryTags];
	[self buildArrayOfInactiveSceneryTags];
	[self buildArrayOfMachineTags];
	[self buildArrayOfInactiveMachineTags];
	[self buildArrayOfVehicleTags];
}
- (void)buildArrayOfSceneryTags
{
	int i;
	
	// Get rid of anything previously held
	if (scenTagArray)
	{
		[scenTagArray removeAllObjects];
		[scenTagArray release];
	}
	
	scenTagArray = [[NSMutableArray alloc] initWithCapacity:scen_ref_count];
	
	// Create an array of all the scenery references
	for (i = 0; i < scen_ref_count; i++)
	{
		if ([_mapfile isTag:scen_references[i].scen_ref.TagId])
			[scenTagArray addObject:[[_mapfile tagForId:scen_references[i].scen_ref.TagId] tagName]];
		else
			[scenTagArray addObject:@"Dead scenery reference!"];
	}
}
- (void)buildArrayOfInactiveSceneryTags
{	
	if (inactiveScenTagArray)
	{
		[inactiveScenTagArray removeAllObjects];
		[inactiveScenTagArray release];
	}
	
	inactiveScenTagArray = [[NSMutableArray arrayWithArray:[_mapfile scenList]] retain];
	[inactiveScenTagArray removeObjectsInArray:scenTagArray];
}
- (void)buildArrayOfMachineTags
{
	int i;
	
	if (machTagArray)
	{
		[machTagArray removeAllObjects];
		[machTagArray release];
	}
	
	machTagArray = [[NSMutableArray alloc] initWithCapacity:mach_ref_count];
	
	for (i = 0; i < mach_ref_count; i++)
	{
		if ([_mapfile isTag:mach_references[i].machTag.TagId])
			[machTagArray addObject:[NSString stringWithFormat:@"%@%d", [[_mapfile tagForId:mach_references[i].machTag.TagId] tagName], i]];
		else
			[machTagArray addObject:@"Dead Machinery Reference!"];
	}
}
- (void)buildArrayOfInactiveMachineTags
{
	NSMutableArray *tmpArray;
	
	if (inactiveMachTagArray)
	{
		[inactiveMachTagArray removeAllObjects];
		[inactiveMachTagArray release];
	}
	
	NSLog(@"hur?");
	//[_mapfile constructArrayAndLookupForTagType:([_mapfile isPPC] ? "mach" : "hcam") array:tmpArray dictionary:tmpDict];
	tmpArray = [_mapfile constructArrayForTagType:([_mapfile isPPC] ? "mach" : "hcam")];
	
	
	if ([tmpArray count] > 0)
	{
		NSLog(@"HOLY HELL");
		inactiveMachTagArray = [NSMutableArray arrayWithArray:tmpArray];
		[inactiveMachTagArray removeObjectsInArray:machTagArray];
	}
	
	[tmpArray removeAllObjects];
	[tmpArray release];
}
- (void)buildArrayOfVehicleTags
{
	int i;
	
	// Get rid of anything previously held
	if (vehiTagArray)
	{
		[vehiTagArray removeAllObjects];
		[vehiTagArray release];
	}
	
	vehiTagArray = [[NSMutableArray alloc] initWithCapacity:vehi_ref_count];
	
	// Create an array of all the scenery references
	for (i = 0; i < vehi_ref_count; i++)
	{
		if ([_mapfile isTag:vehi_references[i].vehi_ref.TagId])
        {
			[vehiTagArray addObject:[[_mapfile tagForId:vehi_references[i].vehi_ref.TagId] tagName]];
        }
		else
			[vehiTagArray addObject:@"Dead vehicle reference!"];
	}
}
- (void)setItmcArray:(NSMutableArray *)tagArray lookup:(int *)lookup
{
	itmcTagArray = [tagArray retain];
	itmcLookup = (int *)lookup;
}
- (NSMutableArray *)vehiTagArray
{
	return vehiTagArray;
}
- (NSMutableArray *)scenTagArray
{
	return scenTagArray;
}
- (NSMutableArray *)inactiveScenTagArray
{
	return inactiveScenTagArray;
}
- (NSMutableArray *)machTagArray
{
	return machTagArray;
}
- (NSMutableArray *)inactiveMachTagArray
{
	return inactiveMachTagArray;
}
/*
	Begin Scenario Rebuilding
*/
int compare(const void *a, const void *b)
{
	return (*(int *)a - (*(int *)b));
}

/*
	@method findActiveReflexives:
		This method finds all of the reflexives that are currently active in the mapfile,
		then constructs an ordered lookup table of said reflexives.
		The lookup table is ordered by the offset pointed to by the reflexive in ascending order.
*/
- (void)findActiveReflexives
{
	int i = 0,
		x = 0;
	reflexive *tmpReflex;
	long negativeOffset;
	negativeOffset = (0 - ([_mapfile magic] + [self offsetInMap]));
	
	_activeReflexCounter = 0;
	
	if (_activeReflexives)
		free(_activeReflexives);
	
	// First we find the number of active reflexives
	for (i = 0; i < 79; i++)
	{
		tmpReflex = (reflexive *)_reflexLookup[i];
		if ((tmpReflex->offset > 0) && (tmpReflex->offset < [self tagLength]) && (tmpReflex->offset != negativeOffset) && (tmpReflex->chunkcount > 0))
			_activeReflexCounter++;
	}
	
	// Then we create a lookup table of the active reflexives
	_activeReflexives = (unsigned int *)malloc(sizeof(unsigned int) * _activeReflexCounter);
	
	// And finally we add the reflexives to our new lookup table
	for (i = 0; i < 79; i++)
	{
		tmpReflex = (reflexive *)_reflexLookup[i];
		if ((tmpReflex->offset > 0) && (tmpReflex->offset < [self tagLength]) && (tmpReflex->offset != negativeOffset) && (tmpReflex->chunkcount > 0))
		{
			_activeReflexives[x] = ((tmpReflex->offset * 100) + i);
			x++;
		}
	}
	
	/* Ok, we have all of the working reflexives, lets sort shit */
	qsort(_activeReflexives, x, sizeof(int), compare);
}
/*
	@method buildChunkSizes:
		This method builds the dynamic chunk size of the active reflexives.
*/
- (void)buildChunkSizes
{
	int i;
	reflexive	*tmpReflex,
				*nextReflex;
	
	for (i = 0; i < _activeReflexCounter; i++)
	{
		tmpReflex = (reflexive *)_reflexLookup[ _activeReflexives[i] % 100];
		if (i < (_activeReflexCounter - 1)) // If we actually have a reflexive following this, lets check it out
		{
			nextReflex = (reflexive *)_reflexLookup[ _activeReflexives[i+1] % 100];
			tmpReflex->chunkSize = (int)((nextReflex->offset - tmpReflex->offset) / tmpReflex->chunkcount);
		}
		else
		{
			tmpReflex->chunkSize = (([self tagLength] - tmpReflex->offset) / tmpReflex->chunkcount);
		}
		
		// Quick hack until I learn more about scripts
		if ((_activeReflexives[i] % 100) == 54)
			tmpReflex->chunkSize = 0x20;
	}
}

- (void)updateReflexiveOffsets
{
	int i,
		sizeChange = 0;
	reflexive	*tmpReflex;
	
	for (i = 0; i < _activeReflexCounter; i++)
	{
		tmpReflex = (reflexive *)_reflexLookup[ _activeReflexives[i] % 100 ];
		
		// The old offset is the currently used one since were rebuilding
		tmpReflex->oldOffset = tmpReflex->offset;
		
		// The new offset has the size change added
		tmpReflex->offset += sizeChange;
		
		if (tmpReflex->chunkcount != tmpReflex->newChunkCount)
		{
			sizeChange += ((tmpReflex->newChunkCount - tmpReflex->chunkcount) * tmpReflex->chunkSize);
			
			// The new chunk counts are now equalized
			tmpReflex->chunkcount = tmpReflex->newChunkCount;
		}
	}
}

- (void)calculateSizeChange
{
	int i;
	reflexive *tmpReflex;
	
	_totalSizeChange = 0;
	
	for (i = 0; i < _activeReflexCounter; i++)
	{
		tmpReflex = (reflexive *)_reflexLookup[ _activeReflexives[i] % 100 ];
		
		if (tmpReflex->chunkcount != tmpReflex->newChunkCount)
			_totalSizeChange += ((tmpReflex->newChunkCount - tmpReflex->chunkcount) * tmpReflex->chunkSize);
	}
}

- (void)calculateRawBufferLength
{
	int i = 0;
	long inData;
	positionInScenario = header.ScriptCrap.offset;
	
	do
	{
		if (positionInScenario >= (header.ScriptCrap.offset + header.ScriptDataSize))
		{
			_activeScriptSize = header.ScriptDataSize;
			_bufferSize = 0;
			return;
		}
		[self readScenario:&inData size:4];
		if (inData == 0xCACA || inData == 0xCACACACA)
			break;
		i++;
	} while (1);
	
	_activeScriptSize = (i * 4);
	_bufferSize = ((header.ScriptDataSize - _activeScriptSize) - _totalSizeChange);
	header.ScriptDataSize = (_activeScriptSize + _bufferSize);
}

/*
	This function is to be run when first opening the scenario or after expanding the scenario I suppose
*/
- (void)findLastBitOfScenario
{
	//NSLog(@"guessed length: 0x%x", (header.ScriptCrap.offset + header.ScriptDataSize));
	
	_endOfScriptDataLength = ([self tagLength] - (header.ScriptCrap.offset + header.ScriptDataSize));
	_endOfScriptDataOffset = ([self tagLength] - _endOfScriptDataLength);
	
	//NSLog(@"End of script data location: 0x%x, length: [0x%x]", _endOfScriptDataOffset, _endOfScriptDataLength);
}

- (void)dumpReflexiveOffsets
{
	int i;
	reflexive *tmpReflex;
	
	for (i = 0; i < _activeReflexCounter; i++)
	{	
		tmpReflex = (reflexive *)_reflexLookup[ _activeReflexives[i] % 100 ];
		//NSLog(@"Temp reflex num: %d, offset in scenario:[0x%x], offset: 0x%x, chunkcount: [%d], chunksize:[0x%x]", ((unsigned int)_activeReflexives[i] % 100) + 1, tmpReflex->location_in_mapfile, tmpReflex->offset, tmpReflex->chunkcount, tmpReflex->chunkSize);
	}
}

/*- (void)writeScenerySpawn:(scenery_spawn *)spawn
{
	/*
		bufIndex = (n * SCENERY_SPAWN_CHUNK);
					if ([_mapfile isPPC])
					{
						hack = (long *)&scen_spawns[n];
						*hack = EndianSwap32(*hack);
						scen_spawns[n].flag = EndianSwap16(scen_spawns[n].flag);
						scen_spawns[n].numid = EndianSwap16(scen_spawns[n].numid);
					}
					memcpy(&newScnr[tmpReflex->offset + bufIndex],&scen_spawns[n],SCENERY_SPAWN_CHUNK);
					if ([_mapfile isPPC])
					{
						scen_spawns[n].flag = EndianSwap16(scen_spawns[n].flag);
						scen_spawns[n].numid = EndianSwap16(scen_spawns[n].numid);
						*hack = EndianSwap32(*hack);
					}
	//[self write
	if ([_mapfile isPPC])
	{
		hack = (long *)spawn;
		*hack = EndianSwap32(*hack);
		spawn.flag = EndianSwap16(spawn.flag);
		spawn.numid = EndianSwap16(spawn.numid);
	}
	//memcpy(&newScnr[tmpReflex->offset]
}
- (void)writeSceneryReference:(scenery_reference *)ref
{	
	
}*/




- (void)rebuildScenario
{
	int debug = 1;
	int i, x, n,
	sizeChange = 0,
	index, 
	realReflexives = 0,
	bufIndex,
	posCounter = 0;
	char	*newScnr;
    long	negativeOffset;
    unsigned long cacashit,
	*hack;
	
    bool singlePlayer = false;
    
	reflexive *tmpReflex, *nextReflex, *areflex;
	
	newScnr = (char *)malloc([self tagLength]);
	memset(newScnr,0,[self tagLength]);
	
	negativeOffset = (0 - ([_mapfile magic] + [self offsetInMap]));
	
	if (device_group_count < 50)
	{
		//Add two device groups for the hell of it
        //for(i=0; i <50; i++)
        //    [self createDeviceGroup];
	}
	
	/* See how many reflexives are actually in use here */
	for (i = 0; i < 79; i++)
	{
		tmpReflex = (reflexive *)_reflexLookup[i];
		if ((tmpReflex->offset > 0) && (tmpReflex->offset < [self tagLength]) && (tmpReflex->offset != negativeOffset))
			realReflexives++;
		else if (tmpReflex->refNumber==15 && mach_ref_count)
			realReflexives++;
		else if (tmpReflex->refNumber==14 && mach_spawn_count )
			realReflexives++;
		else if (tmpReflex->refNumber==13 && device_group_count)
			realReflexives++;
	} 
	
	int OffsetTable[realReflexives];
	x = 0;
	
	for (i = 0; i < 79; i++)
	{
		tmpReflex = (reflexive *)_reflexLookup[i];
		if (debug) NSLog(@"REF %d", tmpReflex->refNumber);

		if ((tmpReflex->offset > 0) && (tmpReflex->offset < [self tagLength]) && (tmpReflex->offset != negativeOffset))
		{
			OffsetTable[x] = ((tmpReflex->offset * 1000) + i);
			x++;
		}
		else if (tmpReflex->refNumber==15 && mach_ref_count)
		{
            if (!singlePlayer)
            {
			//Find the last offset
			int largest_offset = 0;
			int largest_index = 0;
			int a;
			for (a=0;a<15;a++)
			{
				areflex = (reflexive *)_reflexLookup[a];
				if ((areflex->offset > 0) && (areflex->offset < [self tagLength]) && (areflex->offset != negativeOffset))
				{
					if (areflex->offset > largest_offset)
					{
						largest_offset = areflex->offset;
						largest_index = a;
					}
				}
			}
            tmpReflex->newChunkCount=mach_ref_count;
            tmpReflex->chunkSize=MACHINE_REF_CHUNK;
            
			reflexive *scenery = (reflexive *)_reflexLookup[largest_index];
			
			int increment_offset = scenery->newChunkCount * scenery->chunkSize;
			if (mach_ref_count)
				increment_offset+=mach_ref_count*MACHINE_REF_CHUNK;
			
			int increment_offset2 = mach_ref_count*MACHINE_REF_CHUNK;
			tmpReflex->offset= scenery->offset + increment_offset;
			
			tmpReflex->chunkcount=0;
			tmpReflex->newChunkCount=mach_ref_count;
			
			for (a=16;a<79;a++)
			{
				areflex = (reflexive *)_reflexLookup[a];
				if ((areflex->offset > 0) && (areflex->offset < [self tagLength]) && (areflex->offset != negativeOffset))
				{
					areflex->offset+=increment_offset2;
					_reflexLookup[a] = (reflexive *)areflex;
				}
			}
			_reflexLookup[15]=(reflexive *)tmpReflex;
			
			OffsetTable[x] = ((tmpReflex->offset * 1000) + i);
			x++;
            }
		}
		else if (tmpReflex->refNumber==14 && mach_spawn_count)
		{
			if (!singlePlayer)
            {
			//Find the last offset
			int largest_offset = 0;
			int largest_index = 0;
			int a;
			for (a=0;a<14;a++)
			{
				areflex = (reflexive *)_reflexLookup[a];
				if ((areflex->offset > 0) && (areflex->offset < [self tagLength]) && (areflex->offset != negativeOffset))
				{
					if (areflex->offset > largest_offset)
					{
						largest_offset = areflex->offset;
						largest_index = a;
					}
				}
			}
            tmpReflex->newChunkCount=mach_spawn_count;
            tmpReflex->chunkSize=MACHINE_CHUNK;
            
			reflexive *scenery = (reflexive *)_reflexLookup[largest_index];
			int increment_offset = scenery->newChunkCount*scenery->chunkSize;
			int increment_offset2 = mach_spawn_count*MACHINE_CHUNK;
			tmpReflex->offset=scenery->offset+increment_offset;
			
			tmpReflex->chunkcount=0;
			
			for (a=15;a<79;a++)
			{
				areflex = (reflexive *)_reflexLookup[a];
				if ((areflex->offset > 0) && (areflex->offset < [self tagLength]) && (areflex->offset != negativeOffset))
				{
					areflex->offset+=increment_offset2;
					_reflexLookup[a] = (reflexive *)areflex;
				}
			}
			_reflexLookup[14]=(reflexive *)tmpReflex;
			
			OffsetTable[x] = ((tmpReflex->offset * 1000) + i);
			x++;
            }
		}
		else if (tmpReflex->refNumber==13 && device_group_count)
		{
            if (!singlePlayer)
            {
                //continue; //Lets not.
                
                //Lets add a device group for fun!
                int largest_offset = 0;
                int largest_index = 0;
                int a;
                for (a=0;a<13;a++)
                {
                    areflex = (reflexive *)_reflexLookup[a];
                    if ((areflex->offset > 0) && (areflex->offset < [self tagLength]) && (areflex->offset != negativeOffset))
                    {
                        if (areflex->offset > largest_offset)
                        {
                            largest_offset = areflex->offset;
                            largest_index = a;
                        }
                    }
                }
                
                tmpReflex->newChunkCount=device_group_count;
                tmpReflex->chunkSize=DEVICE_CHUNK;
                
                
                reflexive *scenery = (reflexive *)_reflexLookup[largest_index];
                int increment_offset = scenery->newChunkCount*scenery->chunkSize;
                int increment_offset2 = tmpReflex->newChunkCount*DEVICE_CHUNK;
                tmpReflex->offset=scenery->offset+increment_offset;
                tmpReflex->chunkcount=0;
                
                for (a=14;a<79;a++)
                {
                    areflex = (reflexive *)_reflexLookup[a];
                    if ((areflex->offset > 0) && (areflex->offset < [self tagLength]) && (areflex->offset != negativeOffset))
                    {
                        areflex->offset+=increment_offset2;
                        _reflexLookup[a] = (reflexive *)areflex;
                    }
                }
                _reflexLookup[13]=(reflexive *)tmpReflex;
                
                OffsetTable[x] = ((tmpReflex->offset * 1000) + i);
                x++;
            }
		}
	}
	if (debug) NSLog(@"END");
	
	/* Ok, we have all of the working reflexives, lets sort shit */
	qsort(OffsetTable, x, sizeof(int), compare);
	
	if (debug) NSLog(@"1");
	/* Now that this is done, lets update our reflexive offsets */
	for (i = 0; i < x; i++)
	{
		if (debug) NSLog(@"BLAH %d", i);
		tmpReflex = (reflexive *)_reflexLookup[OffsetTable[i] % 1000];
		index = (int)(OffsetTable[i] % 1000);
		if (debug) NSLog(@"Saving %d", index);
		//if (i == (x - 1))
		//	break; // Last reflexive - leave it alone. We need this for the BSP data.
		if (debug) NSLog(@"NEXT1");
		
		tmpReflex->offset += sizeChange;
		if (debug) NSLog(@"NEXT2");
		if (tmpReflex->chunkcount != tmpReflex->newChunkCount)
		{
			if (debug) NSLog(@"NEXT3 %d", tmpReflex->chunkSize);
			sizeChange += ((tmpReflex->newChunkCount - tmpReflex->chunkcount) * tmpReflex->chunkSize);
			if (debug) NSLog(@"NEXT4");
			tmpReflex->chunkcount = tmpReflex->newChunkCount;
		}
		
	}
	if (debug) NSLog(@"1EE");
	/* Ok, thats all sorted out. Now lets copy everything into our new scenario buffer */
	int offset_buff=0;
	for (i = 0; i < x; i++)
	{
		if (debug) NSLog(@"Searching %d", i);
		tmpReflex = (reflexive *)_reflexLookup[OffsetTable[i] % 1000];
		if (!tmpReflex)
		{
			continue;
		}
		
		nextReflex = (reflexive *)_reflexLookup[OffsetTable[i+1] % 1000];
		index = (int)(OffsetTable[i] % 1000);
		if (debug) NSLog(@"Saving %d", index);
		switch (index)
		{
			case 3: // Scenery spawns
				for (n = 0; n < tmpReflex->chunkcount; n++)
				{
					bufIndex = (n * SCENERY_SPAWN_CHUNK);
					memcpy(&newScnr[tmpReflex->offset + bufIndex],&scen_spawns[n],SCENERY_SPAWN_CHUNK);
				}
				break;
			case 4: // Scenery ref
				for (n = 0; n < tmpReflex->chunkcount; n++)
				{
					bufIndex = (n * SCENERY_REF_CHUNK);
					memcpy(&newScnr[tmpReflex->offset +  bufIndex],&scen_references[n],SCENERY_REF_CHUNK);
					//insertMemory([RenderView ID], [_mapfile magic] + &newScnr[tmpReflex->offset + bufIndex], &scen_references[n], SCENERY_REF_CHUNK);
				}
				break;
			case 7: // vehicle spawns
                 NSLog(@"Vehicle spawns  %x", tmpReflex->offset);
				for (n = 0; n < tmpReflex->chunkcount; n++)
				{
					bufIndex = (n * VEHICLE_SPAWN_CHUNK);
					memcpy(&newScnr[tmpReflex->offset + bufIndex], &vehi_spawns[n], VEHICLE_SPAWN_CHUNK);
				}
				break;
			case 8: // Vehicle ref
                 NSLog(@"Vehicle refs  %x", tmpReflex->offset);
				for (n = 0; n < tmpReflex->chunkcount; n++)
				{
					bufIndex = (n * VEHICLE_REF_CHUNK);
					memcpy(&newScnr[tmpReflex->offset +  bufIndex],&vehi_references[n],VEHICLE_REF_CHUNK);
				}
				break;
        /*
			case 13: // Device groups
                    if (debug) NSLog(@"device group! %d", header.DeviceGroups.chunkcount);
                    if (debug) NSLog(@"Number of groups is %d", tmpReflex->chunkcount);
                    for (n = 0; n < device_group_count; n++)
                    {
                        if (debug) NSLog(@"Creating device group numbered %d", n);
                        
                        bufIndex = (n * DEVICE_CHUNK);
                        device_groups[n].initial_value = 1;
                        memcpy(&newScnr[tmpReflex->offset + bufIndex], &device_groups[n], DEVICE_CHUNK);
                    }
                    break;
			case 14: // Machines
                    if (debug) NSLog(@"MACHINE!");
                    for (n = 0; n < tmpReflex->chunkcount; n++)
                    {
                        if (debug) NSLog(@"Creating machine numbered %d %d", n, mach_spawns[n].positionGroup);
                        
                        bufIndex = (n * MACHINE_CHUNK);
                        memcpy(&newScnr[tmpReflex->offset + bufIndex], &mach_spawns[n], MACHINE_CHUNK);
                    }
                    break;
                case 15: // Machine ref
                    
                        for (n = 0; n < mach_ref_count; n++)
                        {
                            if (debug) NSLog(@"Saving machine ref  %d", n);
                            
                            bufIndex = (n * MACHINE_REF_CHUNK);
                            memcpy(&newScnr[tmpReflex->offset +  bufIndex], &mach_references[n],MACHINE_REF_CHUNK);
                            
                            if (debug) NSLog(@"Machine ref created!");
                        }
                        break;
            */
			case 30: // spawns
				for (n = 0; n < tmpReflex->chunkcount; n++)
				{
					bufIndex = (n * PLAYER_SPAWN_CHUNK);
					if ([_mapfile isPPC])
					{
						hack = (long *)&spawns[n].team_index;
						*hack = EndianSwap32(*hack);
						spawns[n].team_index = EndianSwap16(spawns[n].team_index);
						spawns[n].bsp_index = EndianSwap16(spawns[n].bsp_index);
						hack = (long *)&spawns[n].type1;
						*hack = EndianSwap32(*hack);
						spawns[n].type1 = EndianSwap16(spawns[n].type1);
						spawns[n].type2 = EndianSwap16(spawns[n].type2);
						hack = (long *)&spawns[n].type3;
						spawns[n].type3 = EndianSwap16(spawns[n].type3);
						spawns[n].type4 = EndianSwap16(spawns[n].type4);
					}
					memcpy(&newScnr[tmpReflex->offset + bufIndex], &spawns[n], PLAYER_SPAWN_CHUNK);
					if ([_mapfile isPPC])
					{
						hack = (long *)&spawns[n].team_index;
						*hack = EndianSwap32(*hack);
						spawns[n].team_index = EndianSwap16(spawns[n].team_index);
						spawns[n].bsp_index = EndianSwap16(spawns[n].bsp_index);
						hack = (long *)&spawns[n].type1;
						*hack = EndianSwap32(*hack);
						spawns[n].type1 = EndianSwap16(spawns[n].type1);
						spawns[n].type2 = EndianSwap16(spawns[n].type2);
						hack = (long *)&spawns[n].type3;
						spawns[n].type3 = EndianSwap16(spawns[n].type3);
						spawns[n].type4 = EndianSwap16(spawns[n].type4);
					}
				}
				break;
			case 33: // Netgame Flags
				for (n = 0; n < tmpReflex->chunkcount; n++)
				{
					bufIndex = (n * MP_FLAGS_CHUNK);
					
					if ([_mapfile isPPC])
					{
						// Flip the byte order
						hack = (long *)&mp_flags[n].type;
						*hack = EndianSwap32(*hack);
						mp_flags[n].type = EndianSwap16(mp_flags[n].type);
						mp_flags[n].team_index = EndianSwap16(mp_flags[n].team_index);
					}
					
					memcpy(&newScnr[tmpReflex->offset + bufIndex], &mp_flags[n], MP_FLAGS_CHUNK);
					
					if ([_mapfile isPPC])
					{
						mp_flags[n].type = EndianSwap16(mp_flags[n].type);
						mp_flags[n].team_index = EndianSwap16(mp_flags[n].team_index);
						*hack = EndianSwap32(*hack);
					}
				}
				break;
			case 34: // MpEquip
				for (n = 0; n < tmpReflex->chunkcount; n++)
				{
					bufIndex = (n * MP_EQUIP_CHUNK);
		
					memcpy(&newScnr[tmpReflex->offset + bufIndex], &item_spawns[n], MP_EQUIP_CHUNK);
				}
				break;
			/*case 48: // encounters
				for (n = 0; n < tmpReflex->chunkcount; n++)
				{
					//Fix up our starting locations reference
					bufIndex = (n * ENCOUNTER_CHUNK);
					memcpy(&newScnr[tmpReflex->offset + bufIndex], &encounters[n], ENCOUNTER_CHUNK);
				}
				break;*/
			default:
				if (i < (x - 1))
                {
                    NSLog(@"Moar patching  %x %x %d", tmpReflex->offset, tmpReflex->oldOffset, (nextReflex->offset - tmpReflex->offset));
					memcpy(&newScnr[tmpReflex->offset], &scnr[tmpReflex->oldOffset], (nextReflex->offset - tmpReflex->offset));
                    
                }
                else
				{
                    //memcpy(&newScnr[tmpReflex->offset], &scnr[tmpReflex->oldOffset], (nextReflex->offset - tmpReflex->offset));
                    
                   if (singlePlayer)
                   {
                    NSLog(@"BREAKING THE MAP HERE %x %x", tmpReflex->offset, tmpReflex->oldOffset);
                    // Copy the rest foo
					do
                    {
                         
  
                         // Copy 4 bytes at a time
                         memcpy(&cacashit, &scnr[tmpReflex->oldOffset + (4 * posCounter)], 4);
                         if (cacashit != 0xCACACACA || cacashit != 0x0000CACA)
                             memcpy(&newScnr[tmpReflex->offset + (4 * posCounter)], &scnr[tmpReflex->oldOffset + (4 * posCounter)], 4);
                         else
                         {
                             NSLog(@"Hit CACA");
                             break;
                         }
                        
                         posCounter += 1;
                        
                         
                    } while ((posCounter * 4) < ([self tagLength] - tmpReflex->offset));
                    
                    NSLog(@"Expired at %x %x", (tmpReflex->offset + (4 * posCounter)), (tmpReflex->oldOffset + (4 * posCounter)));
                    
                    //Maybe this is the script stuff
					 memcpy(&newScnr[tmpReflex->offset + (4 * posCounter)], &scnr[tmpReflex->oldOffset + (4 * posCounter) + sizeChange], ([self tagLength] - ( (4 * posCounter) + tmpReflex->offset)));
                     
                   }
					
				}
				break;	
		}
	}
    
    /*
    if (_largerScenario)
	{
		
	}
	else
	{
		// The size of the scenario does not need to be enlarged.
		
		// Copy all of the script data first
		memcpy(newScnr[header.ScriptCrap.offset], scnr[header.ScriptCrap.oldOffset], header.ScriptDataSize);
		
		// Now copy over all of the rest
		// This is in EXACTLY the same place, so were using the old offset when copying data.
		memcpy(newScnr[_endOfScriptDataOffset], scnr[_endOfScriptDataOffset], _endOfScriptDataLength);
	}
	*/
    
	if (debug) NSLog(@"Mid-map contstruction complete. Create the header");
	/* Construct the scenario header */
	memcpy(newScnr,scnr,0x5B0);
	if (debug) NSLog(@"Header copied.");
	
	/* Update all the scenario header reflexives */
	for (i = 0; i < x; i++)
	{
		NSLog(@"Updating reflexive %d", i);
		tmpReflex = (reflexive *)_reflexLookup[OffsetTable[i] % 1000];
		NSLog(@"1");
		tmpReflex->offset += ([self offsetInMap] + [_mapfile magic]);
		NSLog(@"2");
		memcpy(&newScnr[tmpReflex->location_in_mapfile], &tmpReflex->chunkcount, 4);
		NSLog(@"3");
		memcpy(&newScnr[tmpReflex->location_in_mapfile+4], &tmpReflex->offset, 4);
		NSLog(@"4");
		memcpy(&newScnr[tmpReflex->location_in_mapfile+8], &tmpReflex->zero, 4);
		NSLog(@"5");
		tmpReflex->offset -= ([self offsetInMap] + [_mapfile magic]);
	}
	if (debug) NSLog(@"Reflexives completed");
	
	
#ifdef __DEBUG__
	NSLog(@"Address of bsp offset: 0x%x", (header.StructBsp.offset - resolvedOffset));
#endif
	
if (debug) 	NSLog(@"Writing data...");
	/* Consistency write! */
	// This writes the last few hundred bytes, whatever it is, thats beyond the 0xCACACACA crap. This also ensures that the bsp data won't be corrupted.
	tmpReflex = (reflexive *)_reflexLookup[OffsetTable[x-1] % 1000];
	memcpy(&newScnr[tmpReflex->offset],&scnr[tmpReflex->oldOffset],(([self tagLength] - tmpReflex->offset) - (header.StructBsp.chunkcount * 0x20)));
	
#ifdef __DEBUG__
	NSLog(@"Final reflexive data: [offset][0x%x] :: [chunkcount][%d]", tmpReflex->offset, tmpReflex->chunkcount);
#endif
	
if (debug) NSLog(@"Writing bsp...");
	memcpy(&newScnr[header.StructBsp.offset - resolvedOffset],&scnr[header.StructBsp.offset - resolvedOffset],(0x20 * header.StructBsp.chunkcount));
	/* End consistency write! */
	
    /*
	if (debug) NSLog(@"Adjusting offsets...");
	for (i = 0; i < x; i++)
	{
		tmpReflex = (reflexive *)_reflexLookup[OffsetTable[i] % 1000];
		tmpReflex->offset = tmpReflex->oldOffset;
	}
    */
	
	if (debug) NSLog(@"Destroying old scenaro...");
	/* Destroy the old scenario */
	free(scnr);
	
	if (debug) NSLog(@"Creating new scenario...");
	/* Set the scenario pointer to the new scenario */
	scnr = (char *)newScnr;
    
    //Update the old offsets
    /* Update all the scenario header reflexives */
	for (i = 0; i < x; i++)
	{
		NSLog(@"Updating reflexive again %d", i);
		tmpReflex = (reflexive *)_reflexLookup[OffsetTable[i] % 1000];
		tmpReflex->oldOffset = tmpReflex->offset;
	}
	if (debug) NSLog(@"Reflexives completed");
	
	

}


- (void)rebuildScenario222
{
	int x, n, index, bufIndex;
	reflexive	*tmpReflex,
				*nextReflex;
	long *hack;
	char *oldScenario;
	
	/*
		To begin with, we already have a sorted array of all of the reflexives that are in use.
		How do we construct the scenario with this I ask?
	*/
	[self findActiveReflexives];
	[self calculateRawBufferLength];
	[self calculateSizeChange];
	[self buildChunkSizes];
	[self updateReflexiveOffsets];
	
	#ifdef __DEBUG__
	[self dumpReflexiveOffsets];
	#endif
	
	/*
		Lets create our new scenario
	*/
	oldScenario = (char *)scnr;
	scnr = NULL;
	
	if ((_bufferSize - _totalSizeChange) < 0)
	{
		#ifdef __DEBUG__
		NSLog(@"_totalSizeChange::[0x%x]", _totalSizeChange);
		NSLog(@"_bufferSize::[0x%x]", _bufferSize);
		NSLog(@"_activeScriptSize::[0x%x]", _activeScriptSize);
		#endif
		// We've run out of buffer.
		// Lets create a larger urrrrverything
		#ifdef __DEBUG__
		NSLog(@"We've run out of bufferssssszzz!!11");
		#endif
		tagLength = ([self tagLength] + _totalSizeChange);
		_largerScenario = TRUE;
	}
	
	#ifdef __DEBUG__
	if (_largerScenario)
		NSLog(@"Larger scenario!");
	#endif
	
	scnr = (char *)malloc([self tagLength]);
	memset(scnr,0,[self tagLength]);
	
	/*
		Before I can do more with scripts, I've got to talk with conure about how they're structured.
	*/
	
	
	/*
		Now we copy all of the spawn object data over to the new scenario
	*/
	for (x = 0; x < _activeReflexCounter; x++)
	{
		tmpReflex = (reflexive *)_reflexLookup[ _activeReflexives[x] % 1000 ];
		nextReflex = (reflexive *)_reflexLookup[ _activeReflexives[x+1] % 1000 ];
		index = (int)(_activeReflexives[x] % 1000);
		
		switch (index)
		{
			case 3: // Scenery spawns
				for (n = 0; n < tmpReflex->chunkcount; n++)
				{
					bufIndex = (n * tmpReflex->chunkSize);
					if ([_mapfile isPPC])
					{
						hack = (long *)&scen_spawns[n];
						*hack = EndianSwap32(*hack);
						scen_spawns[n].flag = EndianSwap16(scen_spawns[n].flag);
						scen_spawns[n].numid = EndianSwap16(scen_spawns[n].numid);
						hack = (long *)&scen_spawns[n].not_placed;
						*hack = EndianSwap32(*hack);
						scen_spawns[n].not_placed = EndianSwap16(scen_spawns[n].not_placed);
						scen_spawns[n].desired_permutation = EndianSwap16(scen_spawns[n].desired_permutation);
					}
					memcpy(&scnr[tmpReflex->offset + bufIndex],&scen_spawns[n],tmpReflex->chunkSize);
					if ([_mapfile isPPC])
					{
						*hack = EndianSwap32(*hack);
						scen_spawns[n].not_placed = EndianSwap16(scen_spawns[n].not_placed);
						scen_spawns[n].desired_permutation = EndianSwap16(scen_spawns[n].desired_permutation);
						hack = (long *)&scen_spawns[n];
						*hack = EndianSwap32(*hack);
						scen_spawns[n].flag = EndianSwap16(scen_spawns[n].flag);
						scen_spawns[n].numid = EndianSwap16(scen_spawns[n].numid);
					}
				}
				break;
			case 4:	// Scenery ref
				for (n = 0; n < tmpReflex->chunkcount; n++)
				{
					bufIndex = (n * tmpReflex->chunkSize);
					memcpy(&scnr[tmpReflex->offset + bufIndex],&scen_references[n],tmpReflex->chunkSize);
				}
				break;
			case 7:	// Vehicle spawns
				for (n = 0; n < tmpReflex->chunkcount; n++)
				{
					bufIndex = (n * tmpReflex->chunkSize);
					if ([_mapfile isPPC])
					{
						hack = (long *)&vehi_spawns[n];
						*hack = EndianSwap32(*hack);
						vehi_spawns[n].flag = EndianSwap16(vehi_spawns[n].flag);
						vehi_spawns[n].numid = EndianSwap16(vehi_spawns[n].numid);
						hack = (long *)&vehi_spawns[n].not_placed;
						*hack = EndianSwap32(*hack);
						vehi_spawns[n].not_placed = EndianSwap16(vehi_spawns[n].not_placed);
						vehi_spawns[n].desired_permutation = EndianSwap16(vehi_spawns[n].desired_permutation);
					}
					memcpy(&scnr[tmpReflex->offset + bufIndex], &vehi_spawns[n], tmpReflex->chunkSize);
					if ([_mapfile isPPC])
					{
						*hack = EndianSwap32(*hack);
						scen_spawns[n].not_placed = EndianSwap16(scen_spawns[n].not_placed);
						scen_spawns[n].desired_permutation = EndianSwap16(scen_spawns[n].desired_permutation);
						hack = (long *)&vehi_spawns[n];
						*hack = EndianSwap32(*hack);
						vehi_spawns[n].flag = EndianSwap16(vehi_spawns[n].flag);
						vehi_spawns[n].numid = EndianSwap16(vehi_spawns[n].numid);
					}
				}
				break;
			case 30: // Spawns
				for (n = 0; n < tmpReflex->chunkcount; n++)
				{
					bufIndex = (n * tmpReflex->chunkSize);
					if ([_mapfile isPPC])
					{
						hack = (long *)&spawns[n].team_index;
						*hack = EndianSwap32(*hack);
						spawns[n].team_index = EndianSwap16(spawns[n].team_index);
						spawns[n].bsp_index = EndianSwap16(spawns[n].bsp_index);
						hack = (long *)&spawns[n].type1;
						*hack = EndianSwap32(*hack);
						spawns[n].type1 = EndianSwap16(spawns[n].type1);
						spawns[n].type2 = EndianSwap16(spawns[n].type2);
						hack = (long *)&spawns[n].type3;
						spawns[n].type3 = EndianSwap16(spawns[n].type3);
						spawns[n].type4 = EndianSwap16(spawns[n].type4);
					}
					memcpy(&scnr[tmpReflex->offset + bufIndex], &spawns[n], tmpReflex->chunkSize);
					if ([_mapfile isPPC])
					{
						hack = (long *)&spawns[n].team_index;
						*hack = EndianSwap32(*hack);
						spawns[n].team_index = EndianSwap16(spawns[n].team_index);
						spawns[n].bsp_index = EndianSwap16(spawns[n].bsp_index);
						hack = (long *)&spawns[n].type1;
						*hack = EndianSwap32(*hack);
						spawns[n].type1 = EndianSwap16(spawns[n].type1);
						spawns[n].type2 = EndianSwap16(spawns[n].type2);
						hack = (long *)&spawns[n].type3;
						spawns[n].type3 = EndianSwap16(spawns[n].type3);
						spawns[n].type4 = EndianSwap16(spawns[n].type4);
					}
				}
				break;
			case 33: // Netgame flags
				for (n = 0; n < tmpReflex->chunkcount; n++)
				{
					bufIndex = (n * tmpReflex->chunkSize);
					if ([_mapfile isPPC])
					{
						hack = (long *)&mp_flags[n].type;
						*hack = EndianSwap32(*hack);
						mp_flags[n].type = EndianSwap16(mp_flags[n].type);
						mp_flags[n].team_index = EndianSwap16(mp_flags[n].team_index);
					}
					
					memcpy(&scnr[tmpReflex->offset + bufIndex], &mp_flags[n], tmpReflex->chunkSize);
					
					if ([_mapfile isPPC])
					{
						mp_flags[n].type = EndianSwap16(mp_flags[n].type);
						mp_flags[n].team_index = EndianSwap16(mp_flags[n].type);
						*hack = EndianSwap32(*hack);
					}
				}
				break;
			case 34: // MpEquip
				for (n = 0; n < tmpReflex->chunkcount; n++)
				{
					bufIndex = (n * tmpReflex->chunkSize);
					memcpy(&scnr[tmpReflex->offset + bufIndex], &item_spawns[n], tmpReflex->chunkSize);
				}
				break;
			default:
				if (x < (_activeReflexCounter - 1))
				{
					// Need to be sure were not copying scripts, thats up next. We shouldn't be, but hey.
					memcpy(&scnr[tmpReflex->offset], &oldScenario[tmpReflex->oldOffset], (nextReflex->offset - tmpReflex->offset));
				}
				else
				{
					// Need to be sure were not copying scripts, thats up next. We shouldn't be, but hey.
					// This thar be scripts?
					#ifdef __DEBUG__
					NSLog(@"Index of last active reflexive: %d", index);
					#endif
				}
				break;
		}
	}
	
	/*
		Ok, so our active reflexive data EXCEPT for script data has been copied.
		
		Lets copy over all of our script data.
	*/
	if (_largerScenario)
	{
		
	}
	else
	{
		// The size of the scenario does not need to be enlarged.
		
		// Copy all of the script data first
		memcpy(&scnr[header.ScriptCrap.offset], &oldScenario[header.ScriptCrap.oldOffset], header.ScriptDataSize);
		
		// Now copy over all of the rest
		// This is in EXACTLY the same place, so were using the old offset when copying data.
		memcpy(&scnr[_endOfScriptDataOffset], &oldScenario[_endOfScriptDataOffset], _endOfScriptDataLength);
	}
	
	/*
		So our scenario changes are too large to be offset by the script buffer.
		
		Now we are going to make sure the changes necessary for a larger scenario are made.
	*/
	
	//if (_largerScenario)
	//{
		// I don't think this will work. Soo.... yeah....
	//	memcpy(&scnr[(header.ScriptCrap.offset + _activeScriptSize + _bufferSize)], &oldScnr[(header.ScriptCrap.oldOffset + _activeScriptSize + _bufferSize)], ([self tagLength] - (header.ScriptCrap.oldOffset + _activeScriptSize + _bufferSize));
	//}
	
	/*
		Now lets create the scenario header
	*/
	memcpy(&scnr[0], &oldScenario[0], 0x5B0);
	/*
		Finally, lets update the scenario header
	*/
	
	for (x = 0; x < _activeReflexCounter; x++)
	{
		tmpReflex = (reflexive *)_reflexLookup[ _activeReflexives[x] % 1000 ];
		tmpReflex->offset += ([self offsetInMap] + [_mapfile magic]);
		memcpy(&scnr[tmpReflex->location_in_mapfile], &tmpReflex->chunkcount, 4);
		memcpy(&scnr[tmpReflex->location_in_mapfile+4], &tmpReflex->offset, 4);
		memcpy(&scnr[tmpReflex->location_in_mapfile+8], &tmpReflex->zero, 4);
		tmpReflex->offset -= ([self offsetInMap] + [_mapfile magic]);
	}
	
	/*
		Update the script size to account for the amount of buffer we have used.
	*/
	[self calculateRawBufferLength];
	memcpy(&scnr[0x474], &header.ScriptDataSize, 4);
	
	/*
		Now we destroy the old scenario.
	*/
	free(oldScenario);
	
	/* TEST WRITE */
	#ifdef __DEBUG__
	FILE *tmpFile = fopen("test.scnr","wb+");
	
	fwrite(scnr,[self tagLength],1,tmpFile);
	
	fclose(tmpFile);
	#endif
}


- (void)saveScenario
{
	NSLog(@"WRITING SCENARIO!");
	[_mapfile writeAnyDataAtAddress:scnr size:[self tagLength] address:[self offsetInMap]];
}


/*

	// Lets write these changes so we can check this
	FILE *tmpFile = fopen("test.scnr","wb+");
	
	fwrite(scnr,[self tagLength],1,tmpFile);
	
	fclose(tmpFile);
	
*/
@end