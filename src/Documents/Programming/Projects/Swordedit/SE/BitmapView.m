//
//  BitmapView.m
//  swordedit
//
//  Created by Fred Havemeyer on 6/2/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BitmapView.h"

#import "HaloMap.h"
#import "BitmapTag.h"
#import "TextureManager.h"

@implementation BitmapView
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
    
    NSLog(@"Creating bitmapview");
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
- (void)awakeFromNib
{
    NSLog(@"Checking mac bitmapview");
#ifndef MACVERSION
    return;
#endif
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewSelectionDidChange:) name:NSTableViewSelectionDidChangeNotification object:bitmapList];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewSelectionDidChange:) name:NSTableViewSelectionDidChangeNotification object:subImageList];
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
    /*
	[[self openGLContext] makeCurrentContext];
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glLoadIdentity();
	glTranslatef(0.0,0.0,-3.0f);
	glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_DECAL);
	glBegin(GL_QUADS);
	{
		glColor3f(1.0f,1.0f,1.0f);
		glTexCoord2f(0.0f,1.0f); glVertex3f(-1.65f,-1.2f,0.0f);
		glTexCoord2f(0.0f,0.0f); glVertex3f(-1.65f,1.2f,0.0f);
		glTexCoord2f(1.0f,0.0f); glVertex3f(1.65f,1.2f,0.0f);
		glTexCoord2f(1.0f,1.0f); glVertex3f(1.65f,-1.2f,0.0f);
	}
	glDisable(GL_TEXTURE_2D);
	glEnd();
	glFlush();*/
}
- (void)releaseAllObjects
{
	[_mapfile release];
	[_texManager release];
}
- (void)setMapfile:(HaloMap *)mapfile
{
	_mapfile = [mapfile retain];
	_texManager = [[_mapfile _texManager] retain];
	[self fillBitmapTable];
}
- (void)fillBitmapTable
{
	[bitmapList setDataSource:self];
	[subImageList setDataSource:self];
}
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (tableView == bitmapList)
	{
		return [[_mapfile bitmTagList] count];
	}
	else if (tableView == subImageList)
	{
		if (_mapfile && [_mapfile isTag:selectedBitmapIdent])
		{
			return [[(BitmapTag *)[_mapfile tagForId:selectedBitmapIdent] subImages] count];
		}
		return 0;
	}
	return 0;
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if (tableView == bitmapList)
	{
		return [[_mapfile bitmTagList] objectAtIndex:row];
	}
	else if (tableView == subImageList)
	{
		return [NSString stringWithFormat:@"Image [%d]", [[[[_mapfile tagForId:selectedBitmapIdent] subImages] objectAtIndex:row] intValue]];
	}
	return nil;
}
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if (aTableView == bitmapList)
	{
		
	}
}
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == bitmapList)
	{	
		selectedBitmap = [bitmapList selectedRow];
		selectedBitmapIdent = [_mapfile bitmIdForKey:selectedBitmap];
		[subImageList deselectAll:self];
		[subImageList reloadData];
	}
	else if ([aNotification object] == subImageList)
	{
		if (!_mapfile || ![_mapfile isTag:selectedBitmapIdent] || [subImageList selectedRow] < 0)
			return;
		
		int selectedTexture = [[aNotification object] selectedRow];
		
		[_texManager loadTextureOfIdent:selectedBitmapIdent subImage:selectedTexture];
		
		[_texManager activateTextureOfIdent:selectedBitmapIdent subImage:selectedTexture useAlphas:YES];
		
		[self setNeedsDisplay:YES];
	}
}
- (IBAction)extractTexture:(id)sender
{
	if (!_mapfile || ![_mapfile isTag:selectedBitmapIdent] || [subImageList selectedRow] < 0)
		return;
		
	NSOpenPanel *saveDir = [NSOpenPanel openPanel];
	if ([saveDir runModalForDirectory:nil file:nil] == NSOKButton)
	{
		
	}
}
@synthesize bitmapList;
@synthesize subImageList;
@synthesize _mapfile;
@synthesize _texManager;
@synthesize selectedBitmap;
@synthesize selectedBitmapIdent;
@synthesize selectedImage;
@end
