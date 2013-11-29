//
//  CSGradientView.m
//  Archon
//
//  Created by Samuco on 29/11/2013.
//
//

#import "CSGradientView.h"

@implementation CSGradientView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}


- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations:[NSColor darkGrayColor], 0.0, [NSColor blackColor], 1.0, nil];
    [gradient drawInBezierPath:[NSBezierPath bezierPathWithRect:[self bounds]] angle:90];
    [gradient release];
    
    gradient = [[NSGradient alloc] initWithColorsAndLocations:[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.2], 0.0, [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.05], 0.5, [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.0], 1.0, nil];
    [gradient drawInBezierPath:[NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, 20, [self bounds].size.height)] angle:0];
    [gradient release];
}

@end
