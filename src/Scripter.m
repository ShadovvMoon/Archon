//
//  Scripter.m
//  swordedit
//
//  Created by sword on 5/28/08.
//  Copyright 2008 sword Inc. All rights reserved.
//

#import "Scripter.h"
#import "defines.h"

@implementation Scripter
- (id)init
{
	if ((self = [super init]) != nil)
	{
	}
	return self;
}
- (id)initWithMapFile:(HaloMap *)map
{
	if ((self = [super init]) != nil)
	{
		// Map reading shit goes here
	}
	return self;
}
- (void)dealloc
{
	
	[super dealloc];
}
- (int)decompileScript
{
	return 0;
}
- (int)compileScript
{	
	return 0;
}
@end
