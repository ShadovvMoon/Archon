//
//  IndexTag.h
//  swordedit
//
//  Created by sword on 10/21/07.
//  Copyright 2007 sword Inc. All rights reserved.
//
//	sword@clanhalo.net
//
@class MapTag;
#import <Cocoa/Cocoa.h>"
#import "MapTag.h"

typedef struct
{
	char classA[4];
	char classB[4];
	char classC[4];
} TagClass;

typedef struct
{
	long tagPointer;
	long stringPointer;
	long identity;
	TagClass classes;
	long zeros[2];
} IndexReference;

@interface IndexTag : MapTag {
	
}
- (id)init;
@end
