//
//  Selection.m
//  Finder
//
//  Created by Samuco on 6/07/09.
//  Copyright 2009 Samuco. All rights reserved.
//

#import "Selection.h"


@implementation Selection
- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
	
    NSWindow* result = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    [result setBackgroundColor: [NSColor clearColor]];
	
	
	[result setOpaque:NO];
	[result setLevel: 200];
	
	
    [result setAlphaValue:1.0];
	[result setHasShadow: YES];
	
	//[result setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	
	SelectView *sv = [[SelectView alloc] initWithFrame:contentRect];
	[sv setAutoresizingMask: (NSViewWidthSizable |
									 NSViewHeightSizable)];
	[[self contentView] addSubview:sv];
    return result;
}


@end
