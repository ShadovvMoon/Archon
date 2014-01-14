//
//  SelectView.m
//  swordedit
//
//  Created by Samuco on 10/01/10.
//  Copyright 2010 Samuco. All rights reserved.
//

#import "SelectView.h"


@implementation SelectView

-(void)drawRect:(NSRect)rect
{
	NSBezierPath *path = [NSBezierPath bezierPathWithRect:rect];
	
	[path setLineWidth: 3];
	
	[[NSColor cyanColor] set]; 
	[path stroke];
	
	[[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:0.1] set]; 
	[path fill];
}

@end
