//
//  Preferences.m
//  swordedit
//
//  Created by sword on 8/30/08.
//  Copyright 2008 sword Inc. All rights reserved.
//

#import "LoadWindow.h"

@implementation LoadWindow

static LoadWindow *sharedInstance = nil;

+ (LoadWindow *)sharedInstance
{
	return sharedInstance ? sharedInstance : [[self alloc] init];
}

- (id)init
{
    CSLog(@"Load window");
    
    
	if (sharedInstance)
		[self dealloc];
	else
		sharedInstance = [super init];
	return sharedInstance;
}

- (IBAction)showPanel:(id)sender
{	
	
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
	
}

- (void)windowDidResignKey:(NSNotification *)notification
{
	
}
@end
