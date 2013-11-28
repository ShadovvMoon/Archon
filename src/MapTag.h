//
//  MapTag.h
//  swordedit
//
//  Created by sword on 10/21/07.
//  Copyright 2007 sword Inc. All rights reserved.
//
//	sword@clanhalo.net
//
@class HaloMap;
#import <Cocoa/Cocoa.h>
#import "HaloMap.h"

// Custom Data Structures from Sparkedit by bob and / or Grenadiac
// All of the tags inherit these methods as well as this basic tag structure.
// The tags also inherit the structures such as TAG_REFERENCE and Reflexive from HaloMap.h

@interface MapTag : NSObject {
	char classA[4];
	char classB[4];
	char classC[4];
	long identity;
	long stringOffset;
	long offset;
	long zeros[2];
	long resolvedOffset;
	long resolvedStringOffset;
	char *tagName;
	long offsetInIndex;
    long someNumber;
    long someNumber2;
	unsigned int tagLength;
}
- (id)initWithDataFromFile:(HaloMap *)mapFile;
- (void)dealloc;
- (NSString *)stringTagClassHigh;
- (char *)tagClassHigh;
- (char *)charTagName;
- (NSString *)tagName;
- (long)idOfTag;
- (long)offsetInMap;
- (unsigned int)tagLength;
- (void)setTagLength:(int)length;
- (int)tagLocation;
- (long)stringOffset;
- (long)rawOffset;
@property (getter=idOfTag) long identity;
@property (getter=stringOffset) long stringOffset;
@property (getter=rawOffset) long offset;
@property (getter=offsetInMap) long resolvedOffset;
@property long resolvedStringOffset;
@property long offsetInIndex;
@end