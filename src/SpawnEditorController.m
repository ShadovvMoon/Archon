//
//  SpawnEditorController.m
//  swordedit
//
//  Created by sword on 6/1/08.
//  Copyright 2008 sword Inc. All rights reserved.
//

#import "SpawnEditorController.h"

#import "FadeView.h"

#import "defines.h"

#import "HaloMap.h"
#import "MapTag.h"
#import "Scenario.h"
#import "RenderView.h"

#import "GeneralMath.h"
#import "Bitmask.h"
#import "defines.h"

typedef enum
{
	SCEN_REF_ROW,
	SCEN_SPAWN_ROW,
	PLAYER_SPAWN_ROW,
	VEHICLE_SPAWN_ROW,
	NETGAME_FLAG_ROW,
	MACHINE_REF_ROW,
	MACHINE_SPAWN_ROW
} table_struct;

/*
#define SCEN_REF_ROW		0

#define PLAYER_SPAWN_ROW	1
#define NETGAME_FLAG_ROW	2
#define MACHINE_SPAWN_ROW	3
*/

@implementation SpawnEditorController
- (void)awakeFromNib
{
    CSLog(@"Checking mac spawn editor");
#ifndef MACVERSION
    return;
#endif
    
	spawnEditorOptions = [[NSMutableArray alloc] initWithCapacity:7];
	[spawnEditorOptions addObject:@"Scenery References"];
	[spawnEditorOptions addObject:@"Scenery Spawns"];
	[spawnEditorOptions addObject:@"Player Spawns"];
	[spawnEditorOptions addObject:@"Vehicle Spawns"];
	[spawnEditorOptions addObject:@"Netgame Flags"];
	[spawnEditorOptions addObject:@"Machine References"];
	[spawnEditorOptions addObject:@"Machine Spawns"];
	
	[_contentView addSubview:scenRefView];
	currentView = scenRefView;
	
	[self loadAllUnchangingData];
		
	[self setNotificationObservers];
	
	[self setDataSources];
}
- (void)setNotificationObservers
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewSelectionDidChange:) name:NSTableViewSelectionDidChangeNotification object:spawnEditorTable];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewSelectionDidChange:) name:NSTableViewSelectionDidChangeNotification object:p_spawnListTable];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewSelectionDidChange:) name:NSTableViewSelectionDidChangeNotification object:s_spawnListTable];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewSelectionDidChange:) name:NSTableViewSelectionDidChangeNotification object:m_spawnListTable];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewSelectionDidChange:) name:NSTableViewSelectionDidChangeNotification object:ng_listTable];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewSelectionDidChange:) name:NSTableViewSelectionDidChangeNotification object:v_spawnListTable];
}
- (void)setDataSources
{
	[inactiveSceneryRef setDataSource:self];
	[activeSceneryRef setDataSource:self];
	[s_spawnListTable setDataSource:self];
	[p_spawnListTable setDataSource:self];
	[m_spawnListTable setDataSource:self];
	[m_inactiveMachineRef setDataSource:self];
	[m_activeMachineRef setDataSource:self];
	[ng_listTable setDataSource:self];
	[v_spawnListTable setDataSource:self];
	[spawnEditorTable selectRow:0 byExtendingSelection:NO];
}
- (void)reloadAllData
{
	[inactiveSceneryRef reloadData];
	[activeSceneryRef reloadData];
	[s_spawnListTable reloadData];
	[p_spawnListTable reloadData];
	[m_spawnListTable reloadData];
	[m_inactiveMachineRef reloadData];
	[m_activeMachineRef reloadData];
	[v_spawnListTable reloadData];
	[ng_listTable reloadData];
}
- (void)setMapFile:(HaloMap *)mapfile
{
	_mapfile = [mapfile retain];
	_scenario = [[mapfile scenario] retain];
	
	[self reloadAllData];
}
- (void)destroyAllMapObjects
{
	[_mapfile release];
	[_scenario release];
}
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (tableView == spawnEditorTable)
	{
		return [spawnEditorOptions count];
	}
	else if (currentView == scenRefView)
	{
		if (tableView == inactiveSceneryRef)
			return [[_scenario inactiveScenTagArray] count];
		else if (tableView == activeSceneryRef)
			return [[_scenario scenTagArray] count];
	}
	else if (currentView == scenSpawnView)
	{
		if (tableView == s_spawnListTable)
			return [_scenario scenery_spawn_count];
	}
	else if (currentView == playerSpawnView)
	{
		if (tableView == p_spawnListTable)
			return [_scenario player_spawn_count];
	}
	else if (currentView == vehicleSpawnView)
	{
		if (tableView == v_spawnListTable)
			return [_scenario vehicle_spawn_count];
	}
	else if (currentView == netgameFlagView)
	{
		if (tableView == ng_listTable)
			return [_scenario multiplayer_flags_count];
	}
	else if (currentView == machineSpawnView)
	{
		if (tableView == m_spawnListTable)
			return [_scenario mach_spawn_count];
	}
	return 0;
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if (tableView == spawnEditorTable)
	{
		return [spawnEditorOptions objectAtIndex:row];
	}
	
	// Now for content
	if (currentView == scenRefView)
	{
		if (tableView == inactiveSceneryRef)
			return [[_scenario inactiveScenTagArray] objectAtIndex:row];
		else if (tableView == activeSceneryRef)
			return [[_scenario scenTagArray] objectAtIndex:row];
	}
	else if (currentView == scenSpawnView)
	{
		if (tableView == s_spawnListTable)
			return [NSString stringWithFormat:@"Scenery Spawn: [%d]", row];
	}
	else if (currentView == playerSpawnView)
	{
		if (tableView == p_spawnListTable)
			return [NSString stringWithFormat:@"Spawn: [%d]", row]; 
	}
	else if (currentView == vehicleSpawnView)
	{
		if (tableView == v_spawnListTable)
			return [NSString stringWithFormat:@"Vehicle Spawn: [%d]", row];
	}
	else if (currentView == netgameFlagView)
	{
		if (tableView == ng_listTable)
			return [NSString stringWithFormat:@"Netgame Flag: [%d]", row];
	}
	else if (currentView == machineSpawnView)
	{
		if (tableView == m_spawnListTable)
			return [NSString stringWithFormat:@"Machine: [%d]", row];
	}
	else if (currentView == machineRefView)
	{
		CSLog(@"Machine ref view!");
	}
	return nil;
}
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	
}
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	id notificationObject = [aNotification object];
	if ([notificationObject selectedRow] < 0)
	{
		return;
	}
	
	if (!fromDelegate)
	{
		[(RenderView *)_updateDelegate deselectAllObjects];
	}
	
	if (notificationObject == spawnEditorTable)
	{
		switch ([spawnEditorTable selectedRow])
		{
			case SCEN_REF_ROW:
				[self _switchTo:scenRefView from:currentView];
				break;
			case SCEN_SPAWN_ROW:
				[self _switchTo:scenSpawnView from:currentView];
				break;
			case PLAYER_SPAWN_ROW:
				[self _switchTo:playerSpawnView from:currentView];
				break;
			case MACHINE_SPAWN_ROW:
				[self _switchTo:machineSpawnView from:currentView];
				break;
			case NETGAME_FLAG_ROW:
				[self _switchTo:netgameFlagView from:currentView];
				break;
			case MACHINE_REF_ROW:
				[self _switchTo:machineRefView from:currentView];
				break;
			case VEHICLE_SPAWN_ROW:
				[self _switchTo:vehicleSpawnView from:currentView];
				break;
		}
		[self reloadAllData];
	}
	else if (notificationObject == p_spawnListTable)
	{
		if (!fromDelegate)
		{
			[(RenderView *)_updateDelegate lookAt:[_scenario spawns][[notificationObject selectedRow]].coord[0] 
										y:[_scenario spawns][[notificationObject selectedRow]].coord[1]
										z:[_scenario spawns][[notificationObject selectedRow]].coord[2]];
		}
		[(RenderView *)_updateDelegate processSelection:(s_playerspawn * MAX_SCENARIO_OBJECTS + [notificationObject selectedRow])];
		
		[self loadPlayerSpawnData:[notificationObject selectedRow]];
	}
	else if (notificationObject == s_spawnListTable)
	{
		if (!fromDelegate)
		{
			[(RenderView *)_updateDelegate lookAt:[_scenario scen_spawns][[notificationObject selectedRow]].coord[0]
										y:[_scenario scen_spawns][[notificationObject selectedRow]].coord[1]
										z:[_scenario scen_spawns][[notificationObject selectedRow]].coord[2]];
		}
		[(RenderView *)_updateDelegate processSelection:(s_scenery * MAX_SCENARIO_OBJECTS + [notificationObject selectedRow])];
		[self loadScenerySpawnData:[notificationObject selectedRow]];
	}
	else if (notificationObject == ng_listTable)
	{
		if (!fromDelegate)
		{
			[(RenderView *)_updateDelegate lookAt:[_scenario netgame_flags][[notificationObject selectedRow]].coord[0]
										y:[_scenario netgame_flags][[notificationObject selectedRow]].coord[1]
										z:[_scenario netgame_flags][[notificationObject selectedRow]].coord[2]];
		}
		[(RenderView *)_updateDelegate processSelection:(s_netgame * MAX_SCENARIO_OBJECTS + [notificationObject selectedRow])];
		[self loadNetgameFlagData:[notificationObject selectedRow]];
	}
	else if (notificationObject == v_spawnListTable)
	{
		if (!fromDelegate)
		{
			[(RenderView *)_updateDelegate lookAt:[_scenario vehi_spawns][[notificationObject selectedRow]].coord[0]
											y:[_scenario vehi_spawns][[notificationObject selectedRow]].coord[1]
											z:[_scenario vehi_spawns][[notificationObject selectedRow]].coord[2]];
		}
		[(RenderView *)_updateDelegate processSelection:(s_vehicle * MAX_SCENARIO_OBJECTS + [notificationObject selectedRow])];
		[self loadVehicleSpawnData:[notificationObject selectedRow]];
	}
	else if (notificationObject == m_spawnListTable)
	{
		if (!fromDelegate)
		{
			[(RenderView *)_updateDelegate lookAt:[_scenario mach_spawns][[notificationObject selectedRow]].coord[0]
											y:[_scenario mach_spawns][[notificationObject selectedRow]].coord[1]
											z:[_scenario mach_spawns][[notificationObject selectedRow]].coord[2]];
		}
		[(RenderView *)_updateDelegate processSelection:(s_machine * MAX_SCENARIO_OBJECTS + [notificationObject selectedRow])];
		[self loadMachineSpawn:[notificationObject selectedRow]];
	}
}
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	
}
- (IBAction)tableViewSelected:(id)sender
{
	
}
/*
	Jesus christ this function fucking sucks!
	Terribly planned!
*/
- (IBAction)buttonAction:(id)sender
{
	if (currentView == scenRefView)
	{
		if (sender == activateScen)
		{
			if ([inactiveSceneryRef selectedRow] >= 0 && [inactiveSceneryRef selectedRow] < [[_scenario inactiveScenTagArray] count])
			{
				TAG_REFERENCE tempTagRef;
			
				MapTag *tempTag = [[_mapfile tagForId:[[[_mapfile scenLookupByName] objectForKey:[[_scenario inactiveScenTagArray] objectAtIndex:[inactiveSceneryRef selectedRow]]] longValue]] retain];
				memcpy(tempTagRef.tag,[tempTag tagClassHigh],4);
				tempTagRef.NamePtr = [tempTag stringOffset];
				tempTagRef.unknown = 0x00000000;
				tempTagRef.TagId = [tempTag idOfTag];
				[_scenario createSceneryReference:tempTagRef];
				[tempTag release];
				
				[_scenario buildAllTagArrays];
				
				[inactiveSceneryRef deselectAll:self];
				[activeSceneryRef deselectAll:self];
				
				[activeSceneryRef reloadData];
				[inactiveSceneryRef reloadData];
			}
		}
		else if (sender == deactivateScen)
		{
			if ([activeSceneryRef selectedRow] >= 0 && [activeSceneryRef selectedRow] < [[_scenario scenTagArray] count])
			{
				[_scenario deleteSceneryReference:[activeSceneryRef selectedRow]];
				[_scenario buildAllTagArrays];
				
				[activeSceneryRef deselectAll:self];
				[inactiveSceneryRef deselectAll:self];
				
				[activeSceneryRef reloadData];
				[inactiveSceneryRef reloadData];
			}
		}
	}
	else if (currentView == playerSpawnView)
	{
		
	}
}

- (void)setUpdateDelegate:(id)delegate
{
	if (_updateDelegate)
		[_updateDelegate release];
	
	_updateDelegate = [delegate retain];
}


// This is shamelessly ripped from The Cheat by moi
- (void)_switchTo:(NSView *)destination from:(NSView *)source
{
	NSRect frame = [source frame];
	NSImage *fadeImage = nil;
	
	if ([source lockFocusIfCanDraw])
	{
		NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:[source bounds]];
		[source unlockFocus];
		
		// create the image object
		fadeImage = [[NSImage alloc] initWithSize:frame.size];
		[fadeImage addRepresentation:imageRep];
		
		if (_fadeView)
		{
			[_fadeView stopFadeAnimation];
			[_fadeView removeFromSuperview];
		}
		
		// Create the new fade view and start the fade
		_fadeView = [[FadeView alloc] initWithFrame:frame];
		[_fadeView setAutoresizingMask:[source autoresizingMask]];
		[_fadeView setDelegate:self];
		[_fadeView setImage:fadeImage];
		[_fadeView setFadeDuration:0.25];
		[_contentView addSubview:_fadeView];
		[_fadeView startFadeAnimation];
		
		[imageRep release];
		[fadeImage release];
	}
	
	// update view size of incoming view
	[destination setFrame:frame];
	// replace the views
	[_contentView replaceSubview:source with:destination];
	
	currentView = destination;
}
// FadeView Delegate
- (void)fadeViewFinishedAnimation:(FadeView *)theView
{
	[_fadeView removeFromSuperview];
	_fadeView = nil;
}

- (void)loadAllUnchangingData
{
	[p_spawnBSPIndex removeAllItems];
	[p_spawnTeam removeAllItems];
	
	[p_spawnTeam addItemWithTitle:@"Red"];
	[p_spawnTeam addItemWithTitle:@"Blue"];
	
}

- (void)loadFocusedItemData:(unsigned int)selectFocus
{
	@try {
		unsigned int	type = (selectFocus / MAX_SCENARIO_OBJECTS),
		index = (selectFocus % MAX_SCENARIO_OBJECTS);
		if (index < 0)
			return;
		
		fromDelegate = TRUE;
		
		switch (type)
		{
			case s_playerspawn:
				[self _switchTo:playerSpawnView from:currentView];
				[spawnEditorTable selectRow:2 byExtendingSelection:NO];
				[p_spawnListTable selectRow:index byExtendingSelection:NO];
				[self loadPlayerSpawnData:index];
				break;
			case s_scenery:
				[self _switchTo:scenSpawnView from:currentView];
				[spawnEditorTable selectRow:1 byExtendingSelection:NO];
				[s_spawnListTable selectRow:index byExtendingSelection:NO];
				[self loadScenerySpawnData:index];
				break;
			case s_machine:
				[self _switchTo:machineSpawnView from:currentView];
				[spawnEditorTable selectRow:6 byExtendingSelection:NO];
				[m_spawnListTable selectRow:index byExtendingSelection:NO];
				[self loadMachineSpawn:index];
				break;
			case s_vehicle:
				[self _switchTo:vehicleSpawnView from:currentView];
				[spawnEditorTable selectRow:3 byExtendingSelection:NO];
				[v_spawnListTable selectRow:index byExtendingSelection:NO];
				[self loadVehicleSpawnData:index];
				break;
			case s_netgame:
				[self _switchTo:netgameFlagView from:currentView];
				[spawnEditorTable selectRow:4 byExtendingSelection:NO];
				[ng_listTable selectRow:index byExtendingSelection:NO];
				[self loadNetgameFlagData:index];
				break;
		}
		fromDelegate = FALSE;
	}
	@catch (NSException * e) {
		
	}
	@finally {
		
	}
	
}

/*
	Editor data loading
*/
- (void)loadPlayerSpawnData:(int)p_spawnIndex
{
	int i;
	
	CSLog(@"Spawn index: %d", p_spawnIndex);
	
	@try {
		for (i = 0; i < [_scenario header].StructBsp.chunkcount; i++)
			[p_spawnBSPIndex addItemWithTitle:[[NSNumber numberWithInt:(i + 1)] stringValue]];
		
		[p_spawnBSPIndex selectItemAtIndex:[_scenario spawns][p_spawnIndex].bsp_index];
		
		[p_spawnXCoord setFloatValue:[_scenario spawns][p_spawnIndex].coord[0]];
		[p_spawnYCoord setFloatValue:[_scenario spawns][p_spawnIndex].coord[1]];
		[p_spawnZCoord setFloatValue:[_scenario spawns][p_spawnIndex].coord[2]];
		[p_spawnRot setFloatValue:piradToDeg([_scenario spawns][p_spawnIndex].rotation)];
		
		CSLog(@"Complete!");
	}
	@catch (NSException * e) {
		
	}
	@finally {
		
	}
	
	
	// Next up is spawn types 1, 2, 3, 4
}
- (void)loadScenerySpawnData:(int)s_spawnIndex
{
	int i;
	
	for (i = 0; i < [_scenario header].StructBsp.chunkcount; i++)
		[s_bspIndex addItemWithTitle:[NSString stringWithFormat:@"%d", (i + 1)]];;
	
	[s_bspIndex selectItemAtIndex:[_scenario scen_spawns][s_spawnIndex].desired_permutation];
	
	[s_spawnXCoord setFloatValue:[_scenario scen_spawns][s_spawnIndex].coord[0]];
	[s_spawnYCoord setFloatValue:[_scenario scen_spawns][s_spawnIndex].coord[1]];
	[s_spawnZCoord setFloatValue:[_scenario scen_spawns][s_spawnIndex].coord[2]];
	[s_spawnYaw setFloatValue:piradToDeg([_scenario scen_spawns][s_spawnIndex].rotation[0])];
	[s_spawnPitch setFloatValue:piradToDeg([_scenario scen_spawns][s_spawnIndex].rotation[1])];
	[s_spawnRoll setFloatValue:piradToDeg([_scenario scen_spawns][s_spawnIndex].rotation[2])];
	
	// Lets deselect a bunch of shit quickly
	[s_spawnAuto setState:NSOffState];
	[s_spawnEasy setState:NSOffState];
	[s_spawnNormal setState:NSOffState];
	[s_spawnHard setState:NSOffState];
	
	//CSLog(@"PLaced on: %d", [_scenario scen_spawns][s_spawnIndex].not_placed);
	switch ([_scenario scen_spawns][s_spawnIndex].not_placed)
	{
		case 0:
			[s_spawnAuto setState:NSOnState];
			break;
		case 1:
			[s_spawnEasy setState:NSOnState];
			break;
		case 2:
			[s_spawnNormal setState:NSOnState];
			break;
		case 3:
			[s_spawnHard setState:NSOnState];
			break;
	}	
}
- (void)loadMachineSpawn:(int)m_spawnIndex
{
	//int i;
	
	// Just below hur will be the BSP index thinger
	//for (i = 0; i < [_scenario header].StructBsp.chunkcount; i++)
		
	[m_spawnXCoord setFloatValue:[_scenario mach_spawns][m_spawnIndex].coord[0]];
	[m_spawnYCoord setFloatValue:[_scenario mach_spawns][m_spawnIndex].coord[1]];
	[m_spawnZCoord setFloatValue:[_scenario mach_spawns][m_spawnIndex].coord[2]];
	[m_spawnYaw setFloatValue:piradToDeg([_scenario mach_spawns][m_spawnIndex].rotation[0])];
	[m_spawnPitch setFloatValue:piradToDeg([_scenario mach_spawns][m_spawnIndex].rotation[1])];
	[m_spawnRoll setFloatValue:piradToDeg([_scenario mach_spawns][m_spawnIndex].rotation[2])];
	
	[m_spawnAuto setState:NSOffState];
	[m_spawnEasy setState:NSOffState];
	[m_spawnNormal setState:NSOffState];
	[m_spawnHard setState:NSOffState];
	
	switch ([_scenario mach_spawns][m_spawnIndex].not_placed)
	{
		case 0:
			[m_spawnAuto setState:NSOnState];
			break;
		case 1:
			[m_spawnEasy setState:NSOnState];
			break;
		case 2:
			[m_spawnNormal setState:NSOnState];
			break;
		case 3:
			[m_spawnHard setState:NSOnState];
			break;
	}
	
	//CSLog(@"Lets see... %x", [_scenario mach_spawns][m_spawnIndex].flags2);
}
- (void)loadVehicleSpawnData:(int)v_spawnIndex
{
	int i;
	
	//for (i = 0; i < [_scenario header].StructBsp.chunkcount; i++)
	//	[v_spawnIndex addItemWithTitle:[NSString stringWithFormat:@"%d", (i + 1)]];
	
	[v_spawnXCoord setFloatValue:[_scenario vehi_spawns][v_spawnIndex].coord[0]];
	[v_spawnYCoord setFloatValue:[_scenario vehi_spawns][v_spawnIndex].coord[1]];
	[v_spawnZCoord setFloatValue:[_scenario vehi_spawns][v_spawnIndex].coord[2]];
	[v_spawnRot setFloatValue:piradToDeg([_scenario vehi_spawns][v_spawnIndex].rotation[0])];
	
	
}
- (void)loadNetgameFlagData:(int)ng_spawnIndex
{
	int i;
	
	CSLog(@"NG Spawn Index: %d", ng_spawnIndex);
	
	[ng_spawnXCoord setFloatValue:[_scenario netgame_flags][ng_spawnIndex].coord[0]];
	[ng_spawnYCoord setFloatValue:[_scenario netgame_flags][ng_spawnIndex].coord[1]];
	[ng_spawnZCoord setFloatValue:[_scenario netgame_flags][ng_spawnIndex].coord[2]];
	[ng_spawnRot setFloatValue:[_scenario netgame_flags][ng_spawnIndex].rotation];
}

/*
	Data creation / updating / saving
*/
@synthesize _contentView;
@synthesize spawnEditorTable;
@synthesize _fadeView;
@synthesize currentView;
@synthesize scenRefView;
@synthesize inactiveSceneryRef;
@synthesize activeSceneryRef;
@synthesize activateScen;
@synthesize deactivateScen;
@synthesize scenSpawnView;
@synthesize s_spawnListTable;
@synthesize s_spawnCreate;
@synthesize s_spawnCreateWhereClicked;
@synthesize s_spawnDelete;
@synthesize s_possibleSwaps;
@synthesize s_bspIndex;
@synthesize s_spawnXCoord;
@synthesize s_spawnYCoord;
@synthesize s_spawnZCoord;
@synthesize s_spawnYaw;
@synthesize s_spawnPitch;
@synthesize s_spawnRoll;
@synthesize s_spawnAuto;
@synthesize s_spawnEasy;
@synthesize s_spawnNormal;
@synthesize s_spawnHard;
@synthesize playerSpawnView;
@synthesize p_spawnListTable;
@synthesize p_spawnTeam;
@synthesize p_spawnBSPIndex;
@synthesize p_spawnType1;
@synthesize p_spawnType2;
@synthesize p_spawnType3;
@synthesize p_spawnType4;
@synthesize p_spawnXCoord;
@synthesize p_spawnYCoord;
@synthesize p_spawnZCoord;
@synthesize p_spawnRot;
@synthesize p_spawnCreate;
@synthesize p_spawnCreateWhereClicked;
@synthesize p_spawnDelete;
@synthesize vehicleSpawnView;
@synthesize v_spawnListTable;
@synthesize v_spawnCreate;
@synthesize v_spawnCreateWhereClicked;
@synthesize v_spawnDelete;
@synthesize v_spawnXCoord;
@synthesize v_spawnYCoord;
@synthesize v_spawnZCoord;
@synthesize v_spawnRot;
@synthesize machineRefView;
@synthesize m_inactiveMachineRef;
@synthesize m_activeMachineRef;
@synthesize m_activateMachine;
@synthesize m_deactivateMachine;
@synthesize machineSpawnView;
@synthesize m_spawnListTable;
@synthesize m_spawnXCoord;
@synthesize m_spawnYCoord;
@synthesize m_spawnZCoord;
@synthesize m_spawnYaw;
@synthesize m_spawnPitch;
@synthesize m_spawnRoll;
@synthesize m_spawnAuto;
@synthesize m_spawnEasy;
@synthesize m_spawnNormal;
@synthesize m_spawnHard;
@synthesize m_spawnInitiallyOpen;
@synthesize m_spawnInitiallyOff;
@synthesize m_spawnChangeOnlyOnce;
@synthesize m_spawnPositionReversed;
@synthesize m_spawnUsableAnySide;
@synthesize m_spawnNotOperateAuto;
@synthesize m_spawnOneSided;
@synthesize m_spawnNeverAppearsLocked;
@synthesize m_spawnOpenMeleeAttack;
@synthesize netgameFlagView;
@synthesize ng_listTable;
@synthesize ng_spawnXCoord;
@synthesize ng_spawnYCoord;
@synthesize ng_spawnZCoord;
@synthesize ng_spawnRot;
@synthesize ng_type;
@synthesize ng_teamIndex;
@synthesize ng_createNew;
@synthesize ng_createNewWhereClicked;
@synthesize ng_deleteSelected;
@synthesize _mapfile;
@synthesize _scenario;
@synthesize _updateDelegate;
@synthesize fromDelegate;
@synthesize spawnEditorOptions;
@end
