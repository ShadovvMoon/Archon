//
//  StampLibrary.m
//  MacPDF
//
//  Created by Samuco on 16/01/11.
//  Copyright 2011 Samuco. All rights reserved.
//

#import "StampLibrary.h"


@implementation StampLibrary

-(void)awakeFromNib
{
    [self setValue:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.0] forKey:IKImageBrowserBackgroundColorKey];
    [self setValue:[NSColor clearColor] forKey:IKImageBrowserBackgroundColorKey];
    
    [self setAllowsDroppingOnItems:NO];
    [self setAllowsReordering:NO];
    [self setCellsStyleMask:IKCellsStyleNone];
    
}

-(void)keyDown:(NSEvent *)theEvent
{
//	NSLog(@"KEY");
	[[self delegate] keyDown:theEvent];
}
@end
