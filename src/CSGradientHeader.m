//
//  CSGradientHeader.m
//  Archon
//
//  Created by Samuco on 29/11/2013.
//
//

#import "CSGradientHeader.h"

@implementation CSGradientHeader

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
	
    NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations:[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:0.3], 0.0, [NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:0], 1.0, nil];
    
    //gradient = [[NSGradient alloc] initWithColorsAndLocations:[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1.0], 0.0, [NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:0.0], 1.0, nil];
    
    
    
    
    [gradient drawInBezierPath:[NSBezierPath bezierPathWithRect:[self bounds]] angle:-90];
    [gradient release];
    

}

@end
