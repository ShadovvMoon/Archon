//
//  ModelView.m
//  swordedit
//
//  Created by Fred Havemeyer on 6/2/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ModelView.h"


@implementation ModelView
- (id)initWithFrame:(NSRect)frame
{
	NSOpenGLPixelFormat *nsglFormat;
	NSOpenGLPixelFormatAttribute attr[] = 
	{
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAAccelerated,
		NSOpenGLPFAColorSize, 
		BITS_PER_PIXEL,
		NSOpenGLPFADepthSize, 
		DEPTH_SIZE,
		0 
	};
    [self setPostsFrameChangedNotifications: YES];
    nsglFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attr];
    if(!nsglFormat) { NSLog(@"Invalid format... terminating."); return nil; }
    self = [super initWithFrame:frame pixelFormat:nsglFormat];
    [nsglFormat release];
    if(!self) { NSLog(@"Self not created... terminating."); return nil; }
    [[self openGLContext] makeCurrentContext];
    [self initGL];
    return self;
}
- (void)initGL
{
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClearDepth(1.0f);
	glDepthFunc(GL_LESS);
	glEnable(GL_DEPTH_TEST);
	glHint(GL_POLYGON_SMOOTH_HINT,GL_NICEST);
}
- (void)reshape
{
	NSSize sceneBounds = [self frame].size;
	glViewport(0,0,sceneBounds.width,sceneBounds.height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective(45.0f,
					(sceneBounds.width / sceneBounds.height),
					0.1f,
					4000000.0f);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
}
- (void)drawRect:(NSRect)rect
{
	[[self openGLContext] makeCurrentContext];
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glLoadIdentity();
	
	
	glEnd();
	glFlush();
}
- (void)releaseAllObjects
{
	[_mapfile release];
}
- (void)setMapfile:(HaloMap *)mapfile
{
	_mapfile = [mapfile retain];
}
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return 0;
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	return nil;
}
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
}
@synthesize _mapfile;
@end
