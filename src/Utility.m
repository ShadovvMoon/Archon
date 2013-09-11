//
//  Utility.m
//  swordedit
//
//  Created by Samuco on 10/01/10.
//  Copyright 2010 Samuco. All rights reserved.
//

#import "Utility.h"


@implementation Utility

-(BOOL)canBecomeKeyWindow
{
	return NO;
}

-(void)awakeFromNib
{
	[[self contentView] addTrackingRect:[[self contentView] bounds] owner:self userData:nil assumeInside:YES];
	[self setAlphaValue:0.2];
}

- (void)mouseEntered:(NSEvent *)theEvent {
	[self setAlphaValue:1.0];
}

- (void)mouseExited:(NSEvent *)theEvent {
	[self setAlphaValue:0.2];
}


@end
