//
//  ScenarioTag.m
//  SparkEdit
//
//  Created by Michael Edgar on Mon Jul 19 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "ScenarioTag.h"
#import "NSFile.h"
#import "HaloMap.h"
#import "ModelTag.h"
#import "BspManager.h"
#import "FileConstants.h"
@implementation ScenarioTag
- (void)dealloc
{
	[selections release];
	free(&header);
//	free(vehiclereferences);
//	free(vehiclespawns);
//	free(sceneryreferences);
//	free(sceneryspawns);
//	free(mpItems);
//	free(playerspawns);
	[myManager release];

	[super dealloc];
}
- (void)setSelectionForObject:(unsigned long)object on:(BOOL)on
{
	unsigned long selType,selIndex;
	selType = (long)object / 15000;
	selIndex = object % 15000;
	if (selType !=0)
	{
		switch (selType)
		{
			case 1:
				vehiclespawns[selIndex].selected = on;
				break;
			case 2:
				sceneryspawns[selIndex].selected = on;
				break;
			case 3:
				mpItems[selIndex].selected = on;
				break;
			case 4:
				playerspawns[selIndex].selected = on;
				break;
		}
	}
}
- (BOOL)getSelectionForObject:(unsigned long)object
{
	unsigned long selType,selIndex;
	selType = (long)object / 15000;
	selIndex = object % 15000;
	if (selType !=0)
	{
		switch (selType)
		{
			case 1:
				return vehiclespawns[selIndex].selected;
				break;
			case 2:
				return sceneryspawns[selIndex].selected;
				break;
			case 3:
				return mpItems[selIndex].selected;
				break;
			case 4:
				return playerspawns[selIndex].selected;
				break;
		}
	}
	return FALSE;
}
- (void)setSelection:(unsigned long)selection add:(BOOL)add
{
	//check for shift key here, if it's on, don't erase old selections
	if (!add)
	{
		NSEnumerator *en = [selections objectEnumerator];
		NSNumber *eachSel;
		while (eachSel = [en nextObject])
			[self setSelectionForObject:[eachSel unsignedLongValue] on:FALSE];
	
		[selections removeAllObjects];
	}
	//derive the new selection
	if ((unsigned long)(selection / 15000) != 0)
	{
		if (add)
		{
			BOOL currSel = [self getSelectionForObject:selection];
			[self setSelectionForObject:selection on:!currSel];
			currSel = !currSel;
			if (currSel)
				[selections addObject:[NSNumber numberWithUnsignedLong:selection]];
			else
				[selections removeObject:[NSNumber numberWithUnsignedLong:selection]];

		}
		else
		{
			[self setSelectionForObject:selection on:TRUE];
			[selections addObject:[NSNumber numberWithUnsignedLong:selection]];
		}
	}
}
- (void)moveSelection:(float)move_x move_y:(float)move_y move_z:(float)move_z rotz:(float)rotz roty:(float)roty rotx:(float)rotx enableAcc:(bool)enableAcc
{
	float moveCoords[6] = {move_x,move_y,move_z,rotz,roty,rotx};
	unsigned long max;
	max = [selections count];
	unsigned long x;
	for (x=0;x<max;x++)
		[self moveObject:[[selections objectAtIndex:x] unsignedLongValue] coords:moveCoords];
		
}
- (void)moveObject:(unsigned long)object coords:(float*)coords
{
	unsigned long selType,selIndex;
	selType = (long)object / 15000;
	selIndex = object % 15000;
	if (selType !=0)
	{
		switch (selType)
		{
			case 1:
				vehiclespawns[selIndex].x += coords[0];
				vehiclespawns[selIndex].y += coords[1];
				vehiclespawns[selIndex].z += coords[2];
				vehiclespawns[selIndex].rotx += coords[3];
				vehiclespawns[selIndex].roty += coords[4];
				vehiclespawns[selIndex].rotz += coords[5];
				break;
			case 2:
				sceneryspawns[selIndex].coord[0] += coords[0];
				sceneryspawns[selIndex].coord[1] += coords[1];
				sceneryspawns[selIndex].coord[2] += coords[2];
				sceneryspawns[selIndex].rotation[0] += coords[3];
				sceneryspawns[selIndex].rotation[1] += coords[4];
				sceneryspawns[selIndex].rotation[2] += coords[5];
				break;
			case 3:
				mpItems[selIndex].x += coords[0];
				mpItems[selIndex].y += coords[1];
				mpItems[selIndex].z += coords[2];
				mpItems[selIndex].yaw += coords[3];
				mpItems[selIndex].unk1 += coords[4];
				mpItems[selIndex].unk2 += coords[5];
				break;
			case 4:
				playerspawns[selIndex].x += coords[0];
				playerspawns[selIndex].y += coords[1];
				playerspawns[selIndex].z += coords[2];
				playerspawns[selIndex].rot += coords[3];
				break;
		}
	}
	[self setMovingForObject:object moving:TRUE];
	glDeleteLists(object,1);
}
- (void)setMovingForObject:(unsigned long)object moving:(bool)moving
{
	long selType,selIndex;
	selType = (long)object / 15000;
	selIndex = object % 15000;
	if (selType !=0)
	{
		switch (selType)
		{
			case 1:
				vehiclespawns[selIndex].moving = moving;
				break;
			case 2:
				sceneryspawns[selIndex].moving = moving;
				break;
			case 3:
				mpItems[selIndex].moving = moving;
				break;
			case 4:
				playerspawns[selIndex].moving = moving; 
				break;
		}
	}
}
- (void)resetMoving
{
	int x;
	int max = [selections count];
	for (x=0;x<max;x++)
		[self setMovingForObject:[[selections objectAtIndex:x] unsignedLongValue] moving:FALSE];
}
- (void)GetReferenceCoordinate:(float*)objpos
{
	unsigned long object = [[selections objectAtIndex:[selections count]-1] unsignedLongValue];
	unsigned long selType,selIndex;
	selType = (long)object / 15000;
	selIndex = object % 15000;
	if (selType !=0)
	{
		switch (selType)
		{
			case 1:
				objpos = &vehiclespawns[selIndex].x;
				break;
			case 2:
				objpos = sceneryspawns[selIndex].coord;
				break;
			case 3:
				objpos = &mpItems[selIndex].x;
				break;
			case 4:
				objpos =&playerspawns[selIndex].x;
				break;
		}
	}
}
- (BOOL)isObjectSelected
{
	return [selections count]>0;
}
- (id)initWithFile:(NSFile *)file atOffset:(long)offset map:(HaloMap *)map
{
	if (self = [super init])
	{
		selections = [[NSMutableArray alloc] initWithCapacity:1];
		myMap = [map retain];
		long offsetInHeader;
		long magic = [map indexHeader].magic;
		offsetInHeader = offset;
		[file seekToOffset:offset];
		[file readIntoStruct:&myTag.classA size:12];
		myTag.ident = [file readDword];
		myTag.stringOffset = [file readDword];
		myTag.offset = [file readDword];
		[file skipBytes:8];
		[file seekToOffset:myTag.stringOffset - magic];
		name = [[file readCString] retain];
		[file seekToOffset:myTag.offset-magic];
		
		//actual scnr
		header = readScnrHeaderFromFile(file,magic);
		
		myManager = [[BspManager alloc] init];
		[myManager Initialize:file magic:magic map:map];
		[myManager LoadVisibleBspInfo:header.StructBsp version:[map version]];
		
		int x;
		myMagic = magic;
		//read in player spawns
		
		[file seekToOffset:header.PlayerSpawn.offset];
		playerspawns = malloc(header.PlayerSpawn.chunkcount * sizeof(PLAYER_SPAWN));
		for (x=0;x<header.PlayerSpawn.chunkcount;x++)
			playerspawns[x] = readPlayerSpawnFromFile(file,magic);
		numberOfPlayerSpawns = header.PlayerSpawn.chunkcount;
		
		//read in the scenery stuffzorz
		
		[file seekToOffset:header.SceneryRef.offset];
		sceneryreferences = malloc(header.SceneryRef.chunkcount * sizeof(SCENERY_REF));
		for (x=0;x<header.SceneryRef.chunkcount;x++)
			sceneryreferences[x] = readSceneryRefFromFile(file,magic);
		[file seekToOffset:header.Scenery.offset];
		numberOfScenerySpawns = header.Scenery.chunkcount;
		sceneryspawns = malloc(header.Scenery.chunkcount * sizeof(SCENERY_SPAWN));
		for (x=0;x<header.Scenery.chunkcount;x++)
			sceneryspawns[x] = readScenerySpawnFromFile(file,magic);
			
		//read in the item stuffzorz
		[file seekToOffset:header.MpEquip.offset];
		mpItems = malloc(header.MpEquip.chunkcount * sizeof(MP_EQUIP));
		for (x=0;x<header.MpEquip.chunkcount;x++)
			mpItems[x] = readMPEquipFromFile(file,magic);
		numberOfMpItems = header.MpEquip.chunkcount;

		
		//read in the vehicle stuffzorz
		[file seekToOffset:header.VehicleRef.offset];
		vehiclereferences = malloc(header.VehicleRef.chunkcount * sizeof(VEHICLE_REF));
		for (x=0;x<header.VehicleRef.chunkcount;x++)
			vehiclereferences[x] = readVehicleRefFromFile(file,magic);
		[file seekToOffset:header.Vehicle.offset];
		vehiclespawns = malloc(header.Vehicle.chunkcount * sizeof(VEHICLE_SPAWN));
		numberOfVehicleSpawns = header.Vehicle.chunkcount;
		for (x=0;x<header.Vehicle.chunkcount;x++)
			vehiclespawns[x] = readVehicleSpawnFromFile(file,magic);

		[file seekToOffset:offsetInHeader+32];
	}
	
	return self;
}
- (void)loadModelIdents:(NSFile*)file
{
	//every time I add something to draw, add the model loader here
	int x;
	for (x=0;x<numberOfVehicleSpawns;x++)
	{
		vehiclespawns[x].modelIdent = [self baseModelIdent:vehiclereferences[vehiclespawns[x].numid].vehicle.TagId file:file];
		//[[myMap modelForIdent:vehiclespawns[x].modelIdent] loadBitmaps];
	}
	for (x=0;x<numberOfScenerySpawns;x++)
	{
		sceneryspawns[x].modelIdent = [self baseModelIdent:sceneryreferences[sceneryspawns[x].numid].sceneryRef.TagId file:file];
		//[[myMap modelForIdent:vehiclespawns[x].modelIdent] loadBitmaps];
	}
	for (x=0;x<numberOfMpItems;x++)
	{
		long offsetToUse = [myMap offsetForIdent:mpItems[x].itmc.TagId]-myMagic;
		[file seekToOffset:offsetToUse];
		[file skipBytes:140];
		mpItems[x].modelIdent = [self baseModelIdent:[file readDword] file:file];
	
	}

}
- (PLAYER_SPAWN *)playerspawns
{
	return playerspawns;
}
- (long)numberOfPlayerSpawns
{
	return numberOfPlayerSpawns;
}
- (MP_EQUIP *)mpItems
{
	return mpItems;
}
- (long)numberOfMpItems
{
	return numberOfMpItems;
}
- (VEHICLE_SPAWN *)vehiclespawns
{
	return vehiclespawns;
}
- (long)numberOfVehicleSpawns
{
	return numberOfVehicleSpawns;
}
- (SCENERY_SPAWN *)sceneryspawns
{
	return sceneryspawns;
}
- (long)numberOfScenerySpawns
{
	return numberOfScenerySpawns;
}
- (long)baseModelIdent:(long)ident file:(NSFile *)file
{

	unsigned long currentOffset = [file offset];
	long offsetToShader = [myMap offsetForIdent:ident];
	offsetToShader -= myMagic;
	[file seekToOffset:offsetToShader];
	[file skipBytes:52];
	long identRet = [file readDword];
	[file seekToOffset:currentOffset];
	return identRet;
	/*long mod2 = 'mod2';
	int x = 0;
	long tempInt;
	do
	{
		tempInt = [file readDword];
		x++;
	} while (tempInt != mod2 && x<1000);
	if (x != 1000)
	{
		[file skipBytes:8];
		long identOfMod2 = [file readDword];
		[file seekToOffset:currentOffset];
		return identOfMod2;
	}
	[file seekToOffset:currentOffset];
	return -1;*/
}
- (BspManager*)myManager
{
	return myManager;
}
@end
