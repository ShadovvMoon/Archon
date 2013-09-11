//
//  HaloMap.m
//  SparkEdit
//
//  Created by Michael Edgar on Mon Jun 21 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "HaloMap.h"
#import "NSFile.h"
#import "ModelTag.h"
#import "ScenarioTag.h"
#import "BspManager.h"
#import "BitmapTag.h"
#include <string.h>
const static struct mapname {
	 char inname[32];
	 char outname[32];
} mapnames[28] = {{"a10", "Pillar of Autumn"},
       {"a30", "Halo"},
	   {"a50", "Truth and Reconciliation"},
	   {"b30","Silent Cartographer"},
	   {"b40","Assault on the Control Room"},
	   {"c10","343 Guilty Spark"},
	   {"c20","The Library"},
	   {"c40","Two Betrayals"},
	   {"d20","Keyes"},
       {"d40", "The Maw"},
	   {"beavercreek","Beaver Creek"},
	   {"bloodgulch","Blood Gulch"},
	   {"boardingaction","Boarding Action"},
	   {"carousel","Derelict"},
	   {"chillout","Chill Out"},
	   {"deathisland","Death Island"},
	   {"damnation","Damnation"},
	   {"dangercanyon","Danger Canyon"},
	   {"gephyrophobia","Gephyrophobia"},
	   {"hangemhigh","Hang 'em High"},
	   {"icefields","Ice Fields"},
	   {"longest","Longest"},
	   {"prisoner","Prisoner"},
	   {"putput","Chiron TL34"},
	   {"ratrace","Rat Race"},
	   {"sidewinder","Sidewinder"},
	   {"timberland","Timberland"},
	   {"wizard","Wizard"}};
@implementation HaloMap
- (long)baseBitmapIdentForShader:(long)ident file:(NSFile *)file
{

	unsigned long currentOffset = [file offset];
	long offsetToShader = [self offsetForIdent:ident];
	offsetToShader -= indexHeader.magic;
	[file seekToOffset:offsetToShader];
	long bitm = 'bitm';
	int x = 0;
	long tempInt;
	do
	{
		tempInt = [file readDword];
		x++;
	} while (tempInt != bitm && x<1000);
	if (x != 1000)
	{
		[file skipBytes:8];
		long identOfBitm = [file readDword];
		[file seekToOffset:currentOffset];
		return identOfBitm;
	}
	[file seekToOffset:currentOffset];
	return -1;
	

}

- (long)offsetForIdent:(long)ident
{
	return [(NSNumber *)[allOtherTags objectForKey:[NSNumber numberWithLong:ident]] longValue];
}
- (ModelTag *)modelForIdent:(long)ident
{
	return [modelsDict objectForKey:[NSNumber numberWithLong:ident]];
}
- (BitmapTag *)bitmForIdent:(long)ident
{
	return [bitmaps objectForKey:[NSNumber numberWithLong:ident]];
}
- (NSString *)mapName
{
	int x;
	for (x=0;x<28;x++)
	{
		if(!strcmp(mapnames[x].inname, fileHeader.name))
		{
			NSString *tempString = [NSString stringWithCString:mapnames[x].outname];
			return tempString;
		}
	}
	return @"";

}
- (id)initWithPath:(NSString *)pathToFile
{
	if (self = [super init])
	{
		path = [pathToFile retain];
		NSFile *mapFile = [[NSFile alloc] initWithPathForReading:pathToFile];
		[mapFile setLittleEndian:YES];
		//read the file header
		fileHeader.id = [mapFile readDword];
		fileHeader.version = [mapFile readDword];
		fileHeader.decomp_len = [mapFile readDword];
		fileHeader.zeros = [mapFile readDword];
		fileHeader.offset_to_index_decomp = [mapFile readDword];
		fileHeader.metadatasize = [mapFile readDword];
		[mapFile skipBytes:8];
		[mapFile readIntoStruct:&fileHeader.name size:32];
		[mapFile readIntoStruct:&fileHeader.builddate size:32];
		fileHeader.maptype = [mapFile readDword];
		
		
		[mapFile seekToOffset:fileHeader.offset_to_index_decomp];
		//index header
		indexHeader.magic = [mapFile readDword];
		indexHeader.magic -= (fileHeader.offset_to_index_decomp + 40);
		indexHeader.starting_id = [mapFile readDword];
		indexHeader.vertexsize = [mapFile readDword];
		indexHeader.tagcount = [mapFile readDword];
		indexHeader.vertex_object_count = [mapFile readDword];
		indexHeader.vertex_offset = [mapFile readDword];
		indexHeader.indices_object_count = [mapFile readDword];
		indexHeader.vertex_size = [mapFile readDword];
		indexHeader.modelsize = [mapFile readDword];
		indexHeader.tagstart = [mapFile readDword];
		
		
		int x;
		tag temptag;
		ModelTag *tempModel;
		BitmapTag *tempBitm;
		models = [[NSMutableArray alloc] initWithCapacity:100];
		modelsDict = [[NSMutableDictionary alloc] initWithCapacity:100];
		bitmaps = [[NSMutableDictionary alloc] initWithCapacity:400];
		allOtherTags = [[NSMutableDictionary alloc] initWithCapacity:1700];
		char twodom[] = {'2','d','o','m'};
		char bitem[] = {'m','t','i','b'};
		char scnr[] = {'r','n','c','s'};
		for (x=0;x<indexHeader.tagcount;x++)
		{
			[mapFile readIntoStruct:&temptag.classA size:12];
			temptag.ident = [mapFile readDword];
			temptag.stringOffset = [mapFile readDword];
			temptag.offset = [mapFile readDword];
			[mapFile skipBytes:8];
			if (memcmp(temptag.classA,twodom,4)==0)
			{
				tempModel = [[ModelTag alloc] initWithFile:mapFile atOffset:([mapFile offset]-32) map:self];
				[models addObject:tempModel];
				[modelsDict setObject:tempModel forKey:[NSNumber numberWithLong:temptag.ident]];
			}
			else if (memcmp(temptag.classA,bitem,4)==0)
			{
				tempBitm = [[BitmapTag alloc] initWithFile:mapFile atOffset:([mapFile offset]-32)
					map:self];
				
				[bitmaps setObject:tempBitm forKey:[NSNumber numberWithLong:temptag.ident]];
			
			}
			else if (memcmp(temptag.classA,scnr,4)==0)
			{
				myScenario = [[ScenarioTag alloc] initWithFile:mapFile atOffset:([mapFile offset]-32)
					map:self];
			}
			else
				[allOtherTags setObject:[NSNumber numberWithLong:temptag.offset] forKey:[NSNumber numberWithLong:temptag.ident]];
		}
		[models makeObjectsPerformSelector:@selector(loadBitmaps)];
		[myScenario loadModelIdents:mapFile];
		[[myScenario myManager] LoadBspTextures];
		[mapFile close];
	}
	return self;
}
- (void)dealloc
{
	[path release];
	[myScenario release];
	[models release];
	[bitmaps release];
	[allOtherTags release];
	[super dealloc];
}
- (NSMutableDictionary *)bitmaps
{
	return [[bitmaps retain] autorelease];
}
- (NSMutableArray *)models
{
	return [[models retain] autorelease];
}
- (indexheader)indexHeader
{
	return indexHeader;
}
- (long)version
{
	return fileHeader.version;
}
- (ScenarioTag*)myScenario
{
	return myScenario;
}
@end
