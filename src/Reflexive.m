//
//  Reflexive.m
//  SparkEdit
//
//  Created by Michael Edgar on Mon Jul 19 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "Reflexive.h"


@implementation Reflexive
- (id)initWithFile:(NSFile *)file magic:(long)magic
{
	count = [file readDword];
	offset = [file readDword]-magic;
	zero = [file readDword];
}
- (long)count
{
	return count;
}
- (long)offset
{
	return offset;
}
@end
