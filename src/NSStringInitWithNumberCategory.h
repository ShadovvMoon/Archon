//
//  NSStringInitWithNumberCategory.h
//  DungeonSiegeEditor
//
//  Created by Michael Edgar on Wed May 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (InitWithNumberCategory)

+ (NSString *)stringWithInt:(int)myInt;
- (NSString *)removeNulls;
@end
