//
//  SpawnEditorController.h
//  swordedit
//
//  Created by sword on 6/1/08.
//  Copyright 2008 sword Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class FadeView;
@class HaloMap;
@class Scenario;

@interface SpawnEditorController : NSDocument {
	
	/* Main Content View Related */
	IBOutlet NSView *_contentView;
	IBOutlet NSTableView *spawnEditorTable;
	
	FadeView *_fadeView;
	
	NSView *currentView;
	/* End Main Content View Related */
	
	/* VIEWS */
	
	/* Scenery reference view */
	IBOutlet NSView *scenRefView;
	IBOutlet NSTableView *inactiveSceneryRef;
	IBOutlet NSTableView *activeSceneryRef;
	IBOutlet NSButton *activateScen;
	IBOutlet NSButton *deactivateScen;
	/* End scenery reference view */
	
	/* Scenery Spawn View */
	IBOutlet NSView *scenSpawnView;
	IBOutlet NSTableView *s_spawnListTable;
	IBOutlet NSButton *s_spawnCreate;
	IBOutlet NSButton *s_spawnCreateWhereClicked;
	IBOutlet NSButton *s_spawnDelete;
	IBOutlet NSPopUpButton *s_possibleSwaps;
	IBOutlet NSPopUpButton *s_bspIndex;
	IBOutlet NSTextField *s_spawnXCoord;
	IBOutlet NSTextField *s_spawnYCoord;
	IBOutlet NSTextField *s_spawnZCoord;
	IBOutlet NSTextField *s_spawnYaw;
	IBOutlet NSTextField *s_spawnPitch;
	IBOutlet NSTextField *s_spawnRoll;
	IBOutlet NSButton *s_spawnAuto;
	IBOutlet NSButton *s_spawnEasy;
	IBOutlet NSButton *s_spawnNormal;
	IBOutlet NSButton *s_spawnHard;
	/* End Scenery Spawn View */
	
	/* Player Spawn View */
	IBOutlet NSView *playerSpawnView;
	IBOutlet NSTableView *p_spawnListTable;
	IBOutlet NSPopUpButton *p_spawnTeam;
	IBOutlet NSPopUpButton *p_spawnBSPIndex;
	IBOutlet NSPopUpButton *p_spawnType1;
	IBOutlet NSPopUpButton *p_spawnType2;
	IBOutlet NSPopUpButton *p_spawnType3;
	IBOutlet NSPopUpButton *p_spawnType4;
	IBOutlet NSTextField *p_spawnXCoord;
	IBOutlet NSTextField *p_spawnYCoord;
	IBOutlet NSTextField *p_spawnZCoord;
	IBOutlet NSTextField *p_spawnRot;
	IBOutlet NSButton *p_spawnCreate;
	IBOutlet NSButton *p_spawnCreateWhereClicked;
	IBOutlet NSButton *p_spawnDelete;
	/* End Player Spawn View */
	
	/* Begin Vehicle Spawn View */
	IBOutlet NSView *vehicleSpawnView;
	IBOutlet NSTableView *v_spawnListTable;
	IBOutlet NSButton *v_spawnCreate;
	IBOutlet NSButton *v_spawnCreateWhereClicked;
	IBOutlet NSButton *v_spawnDelete;
	IBOutlet NSTextField *v_spawnXCoord;
	IBOutlet NSTextField *v_spawnYCoord;
	IBOutlet NSTextField *v_spawnZCoord;
	IBOutlet NSTextField *v_spawnRot;
	/* End Vehicle Spawn View */
	
	/* Machine Ref View */
	IBOutlet NSView *machineRefView;
	IBOutlet NSTableView *m_inactiveMachineRef;
	IBOutlet NSTableView *m_activeMachineRef;
	IBOutlet NSButton *m_activateMachine;
	IBOutlet NSButton *m_deactivateMachine;
	/* End Machine Ref View */
	
	/* Machine Spawn View */
	IBOutlet NSView *machineSpawnView;
	IBOutlet NSTableView *m_spawnListTable;
	IBOutlet NSTextField *m_spawnXCoord;
	IBOutlet NSTextField *m_spawnYCoord;
	IBOutlet NSTextField *m_spawnZCoord;
	IBOutlet NSTextField *m_spawnYaw;
	IBOutlet NSTextField *m_spawnPitch;
	IBOutlet NSTextField *m_spawnRoll;
	// Machine Spawned
//	{
		IBOutlet NSButton *m_spawnAuto;
		IBOutlet NSButton *m_spawnEasy;
		IBOutlet NSButton *m_spawnNormal;
		IBOutlet NSButton *m_spawnHard;
//	}
	// Machine Spawn Flags1
//	{
		IBOutlet NSButton *m_spawnInitiallyOpen;
		IBOutlet NSButton *m_spawnInitiallyOff;
		IBOutlet NSButton *m_spawnChangeOnlyOnce;
		IBOutlet NSButton *m_spawnPositionReversed;
		IBOutlet NSButton *m_spawnUsableAnySide;
//	}
	// Machine Spawn Flags2
//	{
		IBOutlet NSButton *m_spawnNotOperateAuto;
		IBOutlet NSButton *m_spawnOneSided;
		IBOutlet NSButton *m_spawnNeverAppearsLocked;
		IBOutlet NSButton *m_spawnOpenMeleeAttack;
//	}
	/* End Machine Spawn View */
	
	/* Netgame Flag Spawn View */
	IBOutlet NSView *netgameFlagView;
	IBOutlet NSTableView *ng_listTable;
	IBOutlet NSTextField *ng_spawnXCoord;
	IBOutlet NSTextField *ng_spawnYCoord;
	IBOutlet NSTextField *ng_spawnZCoord;
	IBOutlet NSTextField *ng_spawnRot;
	IBOutlet NSPopUpButton *ng_type;
	IBOutlet NSPopUpButton *ng_teamIndex;
	IBOutlet NSButton *ng_createNew;
	IBOutlet NSButton *ng_createNewWhereClicked;
	IBOutlet NSButton *ng_deleteSelected;
	/* End Netgame Flag Spawn View */
	
	
	/* Mapfile related */
	HaloMap *_mapfile;
	Scenario *_scenario;
	
	/* Program interface variables */
	id _updateDelegate;
	BOOL fromDelegate; // Very cheap hack

	NSMutableArray *spawnEditorOptions;
}

- (void)awakeFromNib;
- (void)setNotificationObservers;
- (void)setDataSources;
- (void)reloadAllData;
- (void)setMapFile:(HaloMap *)mapfile;
- (void)destroyAllMapObjects;

/* Table Data Functions */
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
/* End table Data Functions


/* Interface Actions */
- (IBAction)tableViewSelected:(id)sender;
- (IBAction)buttonAction:(id)sender;
/* End Interface Actions */

/* Program Interface Functions */
- (void)setUpdateDelegate:(id)delegate;
/* End Program Interface Functions */

// Ripped from The Cheat
- (void)_switchTo:(NSView *)destination from:(NSView *)source;
- (void)fadeViewFinishedAnimation:(FadeView *)theView;

/* Editor data loading */
- (void)loadAllUnchangingData;
- (void)loadFocusedItemData:(unsigned int)selectFocus;
- (void)loadPlayerSpawnData:(int)p_spawnIndex;
- (void)loadScenerySpawnData:(int)s_spawnIndex;
- (void)loadMachineSpawn:(int)m_spawnIndex;
- (void)loadVehicleSpawnData:(int)v_spawnIndex;
- (void)loadNetgameFlagData:(int)ng_spawnIndex;

/* Editor data saving */
@property (retain) NSView *_contentView;
@property (retain) NSTableView *spawnEditorTable;
@property (retain) FadeView *_fadeView;
@property (retain) NSView *currentView;
@property (retain) NSView *scenRefView;
@property (retain) NSTableView *inactiveSceneryRef;
@property (retain) NSTableView *activeSceneryRef;
@property (retain) NSButton *activateScen;
@property (retain) NSButton *deactivateScen;
@property (retain) NSView *scenSpawnView;
@property (retain) NSTableView *s_spawnListTable;
@property (retain) NSButton *s_spawnCreate;
@property (retain) NSButton *s_spawnCreateWhereClicked;
@property (retain) NSButton *s_spawnDelete;
@property (retain) NSPopUpButton *s_possibleSwaps;
@property (retain) NSPopUpButton *s_bspIndex;
@property (retain) NSTextField *s_spawnXCoord;
@property (retain) NSTextField *s_spawnYCoord;
@property (retain) NSTextField *s_spawnZCoord;
@property (retain) NSTextField *s_spawnYaw;
@property (retain) NSTextField *s_spawnPitch;
@property (retain) NSTextField *s_spawnRoll;
@property (retain) NSButton *s_spawnAuto;
@property (retain) NSButton *s_spawnEasy;
@property (retain) NSButton *s_spawnNormal;
@property (retain) NSButton *s_spawnHard;
@property (retain) NSView *playerSpawnView;
@property (retain) NSTableView *p_spawnListTable;
@property (retain) NSPopUpButton *p_spawnTeam;
@property (retain) NSPopUpButton *p_spawnBSPIndex;
@property (retain) NSPopUpButton *p_spawnType1;
@property (retain) NSPopUpButton *p_spawnType2;
@property (retain) NSPopUpButton *p_spawnType3;
@property (retain) NSPopUpButton *p_spawnType4;
@property (retain) NSTextField *p_spawnXCoord;
@property (retain) NSTextField *p_spawnYCoord;
@property (retain) NSTextField *p_spawnZCoord;
@property (retain) NSTextField *p_spawnRot;
@property (retain) NSButton *p_spawnCreate;
@property (retain) NSButton *p_spawnCreateWhereClicked;
@property (retain) NSButton *p_spawnDelete;
@property (retain) NSView *vehicleSpawnView;
@property (retain) NSTableView *v_spawnListTable;
@property (retain) NSButton *v_spawnCreate;
@property (retain) NSButton *v_spawnCreateWhereClicked;
@property (retain) NSButton *v_spawnDelete;
@property (retain) NSTextField *v_spawnXCoord;
@property (retain) NSTextField *v_spawnYCoord;
@property (retain) NSTextField *v_spawnZCoord;
@property (retain) NSTextField *v_spawnRot;
@property (retain) NSView *machineRefView;
@property (retain) NSTableView *m_inactiveMachineRef;
@property (retain) NSTableView *m_activeMachineRef;
@property (retain) NSButton *m_activateMachine;
@property (retain) NSButton *m_deactivateMachine;
@property (retain) NSView *machineSpawnView;
@property (retain) NSTableView *m_spawnListTable;
@property (retain) NSTextField *m_spawnXCoord;
@property (retain) NSTextField *m_spawnYCoord;
@property (retain) NSTextField *m_spawnZCoord;
@property (retain) NSTextField *m_spawnYaw;
@property (retain) NSTextField *m_spawnPitch;
@property (retain) NSTextField *m_spawnRoll;
@property (retain) NSButton *m_spawnAuto;
@property (retain) NSButton *m_spawnEasy;
@property (retain) NSButton *m_spawnNormal;
@property (retain) NSButton *m_spawnHard;
@property (retain) NSButton *m_spawnInitiallyOpen;
@property (retain) NSButton *m_spawnInitiallyOff;
@property (retain) NSButton *m_spawnChangeOnlyOnce;
@property (retain) NSButton *m_spawnPositionReversed;
@property (retain) NSButton *m_spawnUsableAnySide;
@property (retain) NSButton *m_spawnNotOperateAuto;
@property (retain) NSButton *m_spawnOneSided;
@property (retain) NSButton *m_spawnNeverAppearsLocked;
@property (retain) NSButton *m_spawnOpenMeleeAttack;
@property (retain) NSView *netgameFlagView;
@property (retain) NSTableView *ng_listTable;
@property (retain) NSTextField *ng_spawnXCoord;
@property (retain) NSTextField *ng_spawnYCoord;
@property (retain) NSTextField *ng_spawnZCoord;
@property (retain) NSTextField *ng_spawnRot;
@property (retain) NSPopUpButton *ng_type;
@property (retain) NSPopUpButton *ng_teamIndex;
@property (retain) NSButton *ng_createNew;
@property (retain) NSButton *ng_createNewWhereClicked;
@property (retain) NSButton *ng_deleteSelected;
@property (retain) HaloMap *_mapfile;
@property (retain) Scenario *_scenario;
@property (retain) id _updateDelegate;
@property BOOL fromDelegate;
@property (retain) NSMutableArray *spawnEditorOptions;
@end
