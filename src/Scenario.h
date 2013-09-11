//
//  Scenario.h
//  swordedit
//
//  Created by Fred Havemeyer on 5/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MapTag.h"
#import "HaloMap.h"

#import "defines.h"

enum
{
	ctf_flag = 0,
	ctf_vehicle = 1,
	oddball = 2,
	race_track = 3,
	race_vehicle = 4,
	vegas_bank = 5,
	teleporter_entrance = 6,
	teleporter_exit = 7,
	hill_flag = 8
} MultiplayerFlags;

@interface Scenario : MapTag {
	HaloMap *_mapfile;
	BSP *mapBsp;
	long mapMagic;
	
	char *scnr;
	int positionInScenario;
	long scnr_length;
	
	SCNR_HEADER header;
	
	SkyBox *skies;
	int skybox_count;
	int current_ref;
	/* Begin spawn related vars */
	
	vehicle_reference *vehi_references;
	vehicle_spawn *vehi_spawns;
	int vehicle_spawn_count;
	int vehi_ref_count;
	
	scenery_reference *scen_references;
	scenery_spawn *scen_spawns;
	int scenery_spawn_count;
	int scen_ref_count;
	NSMutableArray *vehiTagArray;
	NSMutableArray *scenTagArray;
	NSMutableArray *scenModelArray;
	NSMutableArray *inactiveScenTagArray;
	
	machine_ref *mach_references;
	machine_spawn *mach_spawns;
	int mach_spawn_count;
	int mach_ref_count;
	NSMutableArray *machTagArray;
	NSMutableArray *inactiveMachTagArray;
	
	device_group *device_groups;
	int device_group_count;
	
	encounter *encounters;
	int encounters_count;
	
	mp_equipment *item_spawns;
	int item_spawn_count;
	NSMutableArray *itmcTagArray;
	NSMutableArray *itmcModelArray;
	NSMutableDictionary *itmcModelLookup;
	int *itmcLookup;
	
	player_spawn *spawns;
	int player_spawn_count;
	
	multiplayer_flags *mp_flags;
	int multiplayer_flags_count;
	
	int teleporter_pair_count;
	
	NSMutableDictionary *netgameFlagIndexLookup;
	NSMutableDictionary *netgameFlagIDLookup;
	
	/* End spawn related vars */
	
	/* Begin scenario reconstruction vars */
		/*
		There are 79 reflexives in the scenario header that I have in the SCENARIO_HEADER struct
		This will be a lookup table for each and every one of 'em for scenario reconstruction.
		*/
	unsigned int _reflexLookup[79];
	unsigned int *_activeReflexives;
	int _reflexCounter;
	int _activeReflexCounter;
	int _activeScriptSize;
	int _bufferSize;
	int _totalSizeChange;
	int _endOfScriptDataOffset;
	int _endOfScriptDataLength;
	BOOL _largerScenario;
	/* End scenario reconstruction vars */
}

- (id)initWithMapFile:(HaloMap *)map;
- (void)dealloc;
- (BOOL)loadScenario;
- (void)readScenario:(void *)buffer size:(int)size;
- (void)readScenarioAtAddress:(void *)buffer address:(int)address size:(int)size;
- (void)skipBytes:(int)count;
- (void)readScenarioReflexive:(reflexive *)reflex;
- (void)readScenarioReflexiveType:(reflexive_tag *)reflex;
- (void)readScenarioReflexiveAtAddress:(reflexive *)reflex addr:(int)addr;
- (void)readScenarioTagReference:(TAG_REFERENCE *)ref;
- (void)readScenarioTagReferenceAtAddress:(TAG_REFERENCE *)ref addr:(int)addr;

/* BEGIN DATA TYPE READING */
- (mp_equipment)readMPEquip;
- (player_spawn)readPlayerSpawn;
- (scenery_reference)readSceneryReference;
- (scenery_spawn)readScenerySpawn;
- (vehicle_reference)readVehicleReference;
- (vehicle_spawn)readVehicleSpawn;
- (SkyBox)readSkyBox;
- (machine_ref)readMachineReference;
- (machine_spawn)readMachineSpawn;
- (device_group)readDeviceGroup;
- (encounter)readEncounter;
- (void)readMultiplayerFlags;
/* END DATA TYPE READING */

/* Various lookup methods */
- (short)netgameFlagIDForIndex:(int)index;
- (int)netgameFlagIndexForID:(short)index;
- (void)pairModelsWithSpawn;
- (long)itmcModelForId:(long)ident;
- (long)baseModelIdent:(long)ident;
/* End these lookup methods fool. */

/* BEGIN DATA SET ACCESSORS */
- (SCNR_HEADER)header;
- (vehicle_reference *)vehi_references;
- (vehicle_spawn *)vehi_spawns;
- (scenery_reference *)scen_references;
- (scenery_spawn *)scen_spawns;
- (mp_equipment *)item_spawns;
- (player_spawn *)spawns;
- (multiplayer_flags *)netgame_flags;
- (machine_ref *)mach_references;
- (machine_spawn *)mach_spawns;
- (encounter *)encounters;
- (SkyBox *)sky;
/* END DATA SET ACCESSORS */

/* BEGIN DATA TYPE COUNTER ACCESSORS */
- (int)vehicle_spawn_count;
- (int)vehi_ref_count;
- (int)scenery_spawn_count;
- (int)scen_ref_count;
- (int)item_spawn_count;
- (int)player_spawn_count;
- (int)multiplayer_flags_count;
- (int)mach_ref_count;
- (int)mach_spawn_count;
- (int)encounter_count;
/* END DATA TYPE COUNTER ACCESSORS */

/* Scenario editing functions */
// Scenario Object Creation
- (unsigned int)duplicateScenarioObject:(int)type index:(int)index;
- (int)duplicateScenery:(int)index;
- (void)createSceneryReference:(TAG_REFERENCE)tag;
- (int)duplicateMpEquipment:(int)index;
- (void)createPlayerSpawn:(player_spawn)p_Spawn;
- (unsigned int)createTeleporterPair:(float *)coord;

// Scenario Object Destruction
- (void)deleteScenarioObject:(int)type index:(int)index;
- (void)deleteMPEquipment:(int)index;
- (void)deleteScenery:(int)index;
- (void)deletePlayerSpawn:(int)index;
- (void)deleteSceneryReference:(int)index;
- (void)deleteNetgameFlag:(int)index;

// Item swapping related
- (void)buildAllTagArrays;
- (void)buildArrayOfSceneryTags;
- (void)buildArrayOfInactiveSceneryTags;
- (void)buildArrayOfMachineTags;
- (void)buildArrayOfInactiveMachineTags;

- (NSMutableArray *)scenTagArray;
- (NSMutableArray *)inactiveScenTagArray;
- (NSMutableArray *)machTagArray;
- (NSMutableArray *)inactiveMachTagArray;

/* Here are the interesting things */

- (void)findActiveReflexives;
- (void)buildChunkSizes;
- (void)updateReflexiveOffsets;
- (void)calculateSizeChange;
- (void)calculateRawBufferLength;
- (void)findLastBitOfScenario;
- (void)dumpReflexiveOffsets;
- (void)rebuildScenario;
- (void)saveScenario;
/* End scenario editing functions */
@end
