//
//  MapTag.m
//  swordedit
//
//  Created by sword on 10/21/07.
//  Copyright 2007 sword Inc. All rights reserved.
//
//	sword@clanhalo.net
//

#import "MapTag.h"


@implementation MapTag
- (id)initWithDataFromFile:(HaloMap *)mapFile
{
	if ((self = [super init]) != nil)
	{
		offsetInIndex = ([mapFile currentOffset] + 32);
		[mapFile read:&classA size:4];
		[mapFile read:&classB size:4];
		[mapFile read:&classC size:4];
		[mapFile readLong:&identity];
		[mapFile readLong:&stringOffset];
		[mapFile readLong:&offset];
		[mapFile skipBytes:8];
		
		resolvedOffset = (offset - [mapFile getMagic]);
		resolvedStringOffset = (stringOffset - [mapFile getMagic]);
		
		long prevOffset = [mapFile currentOffset];
		[mapFile seekToAddress:resolvedStringOffset];
		tagName = [mapFile readCString];
		[mapFile seekToAddress:prevOffset];
	}
	return self;
}
- (void)dealloc 
{
	free(tagName);
	[super dealloc];
}
- (NSString *)stringTagClassHigh
{
	return [NSString stringWithCString:classA];
}
- (char *)tagClassHigh
{
	return classA;
}
- (char *)charTagName
{
	return tagName;
}
- (NSString *)tagName
{
	return [NSString stringWithCString:tagName];
}
- (long)idOfTag
{
	return identity;
}
- (long)offsetInMap
{
	return resolvedOffset;
}
- (unsigned int)tagLength
{
	return tagLength;
}
- (void)setTagLength:(int)length
{
	tagLength = length;
}
- (int)tagLocation
{
	return resolvedOffset;
}
- (long)stringOffset
{
	return stringOffset;
}
- (long)rawOffset
{
	return offset;
}
@end
