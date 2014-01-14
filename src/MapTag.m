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
-(NSString*)description
{
    return [NSString stringWithFormat:@"%@ %@", [self stringTagClassHigh], [self tagName]];
}

- (id)initWithData:(NSData*)tagData withMapfile:(HaloMap *)mapFile
{
    if ((self = [super init]) != nil)
	{
        const void *bytes = [tagData bytes];
        memcpy(&classA,         bytes+ 0, 4);
        memcpy(&classB,         bytes+ 4, 4);
        memcpy(&classC,         bytes+ 8, 4);
        memcpy(&identity,       bytes+12, 4);
        memcpy(&stringOffset,   bytes+16, 4);
        memcpy(&offset,         bytes+20, 4);
        memcpy(&someNumber,     bytes+24, 4);
        memcpy(&someNumber2,    bytes+28, 4);
        
        resolvedOffset = (offset - [mapFile getMagic]);
		resolvedStringOffset = (stringOffset - [mapFile getMagic]);
		
		[mapFile seekToAddress:resolvedStringOffset];
        
		tagName = [mapFile readCString];
        hasTagName = YES;
    }
    return self;
}

-(void)fixOffsetWithOldMagic:(int32_t)magic withMap:(HaloMap *)mapFile
{
    //offset -= magic;
    //offset += [mapFile getMagic];
    resolvedOffset = (offset - [mapFile getMagic]);
    resolvedStringOffset = (stringOffset - [mapFile getMagic]);
    
    int32_t prevOffset = [mapFile currentOffset];
    [mapFile seekToAddress:resolvedStringOffset];
    tagName = [mapFile readCString];
    hasTagName = YES;
    
#ifdef __DEBUG__
    CSLog(@"UPDATED TAG MAGICAL OFFSETS %s", tagName);
#endif
}

-(void)updateTag:(HaloMap *)mapFile
{
    offsetInIndex = ([mapFile currentOffset] + 32);
    [mapFile read:&classA size:4];
    [mapFile read:&classB size:4];
    [mapFile read:&classC size:4];
    [mapFile readint32_t:&identity];
    [mapFile readint32_t:&stringOffset];
    [mapFile readint32_t:&offset];
    [mapFile readint32_t:&someNumber];
    [mapFile readint32_t:&someNumber2];
    
    #ifdef __DEBUG__
    CSLog([self tagName]);
    CSLog(@"Updating 0x%lx to 0x%lx", resolvedOffset, offset-[mapFile getMagic]);
#endif
    
    resolvedOffset = (offset - [mapFile getMagic]);
    resolvedStringOffset = (stringOffset - [mapFile getMagic]);
    
    int32_t prevOffset = [mapFile currentOffset];
    [mapFile seekToAddress:resolvedStringOffset];
    tagName = [mapFile readCString];
    hasTagName = YES;
    #ifdef __DEBUG__
    CSLog(@"%s", tagName);
#endif
    
    [mapFile seekToAddress:prevOffset];
}

- (id)initWithDataFromFile:(HaloMap *)mapFile
{
	if ((self = [super init]) != nil)
	{
		offsetInIndex = ([mapFile currentOffset] + 32);
		[mapFile read:&classA size:4];
		[mapFile read:&classB size:4];
		[mapFile read:&classC size:4];
		[mapFile readint32_t:&identity];
		[mapFile readint32_t:&stringOffset];
		[mapFile readint32_t:&offset];
        [mapFile readint32_t:&someNumber];
        [mapFile readint32_t:&someNumber2];
        
        
		//[mapFile skipBytes:8];
		
		resolvedOffset = (offset - [mapFile getMagic]);
		resolvedStringOffset = (stringOffset - [mapFile getMagic]);
		
		int32_t prevOffset = [mapFile currentOffset];
		[mapFile seekToAddress:resolvedStringOffset];
		tagName = [mapFile readCString];
        hasTagName = YES;
		[mapFile seekToAddress:prevOffset];
		/*
		prevOffset = [mapFile currentOffset];
		[mapFile seekToAddress:resolvedOffset];
		CSLog([NSString stringWithCString:[mapFile readCString]]);
		[mapFile seekToAddress:prevOffset];*/
	}
	
	return self;
}
- (void)dealloc 
{

	[super dealloc];
}
- (NSString *)stringTagClassHigh
{
	return [[[NSString alloc] initWithCString:classA encoding:NSMacOSRomanStringEncoding] autorelease];
}
- (char *)tagClassHigh
{
	return classA;
}
- (char *)tagClassB
{
	return classB;
}
- (char *)tagClassC
{
	return classC;
}
- (char *)charTagName
{
	return tagName;
}
- (NSString *)tagName
{
	return [NSString stringWithCString:tagName];
}
- (int32_t)idOfTag
{
	return identity;
}
- (int32_t)offsetInMap
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
- (int32_t)stringOffset
{
	return stringOffset;
}
- (int32_t)rawOffset
{
	return offset;
}
- (int32_t)num1
{
	return someNumber;
}
- (int32_t)num2
{
	return someNumber2;
}
@synthesize identity;
@synthesize stringOffset;
@synthesize offset;
@synthesize resolvedOffset;
@synthesize resolvedStringOffset;
@synthesize offsetInIndex;
@end
