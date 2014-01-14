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
	int32_t identity;
	int32_t stringOffset;
	int32_t offset;
	int32_t zeros[2];
    
	int32_t resolvedOffset;
	int32_t resolvedStringOffset;
	char *tagName;
	int32_t offsetInIndex;
    int32_t someNumber;
    int32_t someNumber2;
	unsigned int tagLength;
    
    BOOL hasTagName;
}
-(void)fixOffsetWithOldMagic:(int32_t)magic withMap:(HaloMap *)mapFile;
- (id)initWithData:(NSData*)tagData withMapfile:(HaloMap *)mapFile;
- (id)initWithDataFromFile:(HaloMap *)mapFile;
- (void)dealloc;
- (NSString *)stringTagClassHigh;
- (char *)tagClassHigh;
- (char *)tagClassB;
- (char *)tagClassC;
- (int32_t)num1;
- (int32_t)num2;
- (char *)charTagName;
- (NSString *)tagName;
- (int32_t)idOfTag;
- (int32_t)offsetInMap;
- (unsigned int)tagLength;
- (void)setTagLength:(int)length;
- (int)tagLocation;
- (int32_t)stringOffset;
- (int32_t)rawOffset;
@property (getter=idOfTag) int32_t identity;
@property (getter=stringOffset) int32_t stringOffset;
@property (getter=rawOffset) int32_t offset;
@property (getter=offsetInMap) int32_t resolvedOffset;
@property int32_t resolvedStringOffset;
@property int32_t offsetInIndex;
@end