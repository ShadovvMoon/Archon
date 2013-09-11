//
//  NSStringInitWithNumberCategory.m
//  DungeonSiegeEditor
//
//  Created by Michael Edgar on Wed May 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "NSStringInitWithNumberCategory.h"


@implementation NSString (NSStringInitWithNumberCategory)

+ (NSString *)stringWithInt:(int)myInt
{

	return [NSString stringWithString:[[NSNumber numberWithInt:myInt] stringValue]];
}

@end
