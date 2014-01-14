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
	
    
    NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations:[NSColor colorWithCalibratedRed:0.2 green:0.2 blue:0.2 alpha:1.0], 0.0, [NSColor colorWithCalibratedRed:0.1 green:0.1 blue:0.1 alpha:1.0], 1.0, nil];
     
    
    
    //NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations:[NSColor colorWithCalibratedRed:224/255.0 green:228/255.0 blue:234/255.0 alpha:1.0], 0.0, [NSColor colorWithCalibratedRed:181/255.0 green:189/255.0 blue:201/255.0 alpha:1.0], 1.0, nil];
    [gradient drawInBezierPath:[NSBezierPath bezierPathWithRect:[self bounds]] angle:-90];
    [gradient release];
    
    gradient = [[NSGradient alloc] initWithColorsAndLocations:[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.1], 0.3, [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.05], 0.5, [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.0], 1.0, nil];
    [gradient drawInBezierPath:[NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, 20, [self bounds].size.height)] angle:0];
    [gradient release];
}

@end
