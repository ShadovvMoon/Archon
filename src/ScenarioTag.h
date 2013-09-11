//
//  ScenarioTag.h
//  SparkEdit
//
//  Created by Michael Edgar on Mon Jul 19 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//
@class NSFile;
@class HaloMap;
@class ModelTag;
@class BspManager;
#import <Foundation/Foundation.h>
#import "ScenarioDefs.h"

@interface ScenarioTag : NSObject {
	tag myTag;
	NSString *name;
	SCNR_HEADER header;
	BspManager *myManager;
	HaloMap *myMap;
	long myMagic;
	//for drawing vehicles n' stuffs
	VEHICLE_REF *vehiclereferences;
	VEHICLE_SPAWN *vehiclespawns;
	unsigned long numberOfVehicleSpawns;

	SCENERY_REF *sceneryreferences;
	SCENERY_SPAWN *sceneryspawns;
	unsigned long numberOfScenerySpawns;

	MP_EQUIP *mpItems;
	unsigned long numberOfMpItems;
	
	PLAYER_SPAWN *playerspawns;
	unsigned long numberOfPlayerSpawns;
	//selection stuff
	
	NSMutableArray *selections;
	
	unsigned long selectedType;
	unsigned long selectedIndex;
}
- (void)moveObject:(unsigned long)object coords:(float*)coords;
- (void)resetMoving;
- (void)GetReferenceCoordinate:(float*)objpos;
- (BOOL)isObjectSelected;
- (void)moveSelection:(float)move_x move_y:(float)move_y move_z:(float)move_z rotz:(float)rotz roty:(float)roty rotx:(float)rotx enableAcc:(bool)enableAcc;
- (void)setSelectionForObject:(unsigned long)object on:(BOOL)on;
- (BOOL)getSelectionForObject:(unsigned long)object;
- (void)setSelection:(unsigned long)selection add:(BOOL)add;
- (id)initWithFile:(NSFile *)file atOffset:(long)offset map:(HaloMap *)map;
- (BspManager*)myManager;
- (long)baseModelIdent:(long)ident file:(NSFile *)file;
- (VEHICLE_SPAWN *)vehiclespawns;
- (long)numberOfVehicleSpawns;
- (void)setMovingForObject:(unsigned long)object moving:(bool)moving;
- (SCENERY_SPAWN *)sceneryspawns;
- (long)numberOfScenerySpawns;
- (PLAYER_SPAWN *)playerspawns;
- (long)numberOfPlayerSpawns;
- (MP_EQUIP *)mpItems;
- (long)numberOfMpItems;
- (void)loadModelIdents:(NSFile*)file;
@end
