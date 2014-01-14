//
//  BitmapView.h
//  swordedit
//
//  Created by Fred Havemeyer on 6/2/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifndef MACVERSION
#import "glew.h"
#endif

#include <OpenGL/OpenGL.h>
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#include <OpenGL/glext.h>

#define BITS_PER_PIXEL          32.0
#define DEPTH_SIZE              32.0
#define DEFAULT_TIME_INTERVAL   0.001

@class HaloMap;
@class BitmapTag;
@class TextureManager;

@interface BitmapView : NSOpenGLView {
	IBOutlet NSTableView *bitmapList;
	IBOutlet NSTableView *subImageList;

	HaloMap *_mapfile;
	TextureManager *_texManager;
	
	GLuint texture[1];
	
	int selectedBitmap;
	int selectedBitmapIdent;
	int selectedImage;
}
- (id)initWithFrame:(NSRect)frame;
- (void)initGL;
- (void)reshape;
- (void)drawRect:(NSRect)rect;
- (void)releaseAllObjects;
- (void)setMapfile:(HaloMap *)mapfile;
- (void)fillBitmapTable;

/* Table data related */
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;

/* IB Actions */
- (IBAction)extractTexture:(id)sender;
@property (retain) NSTableView *bitmapList;
@property (retain) NSTableView *subImageList;
@property (retain) HaloMap *_mapfile;
@property (retain) TextureManager *_texManager;
@property int selectedBitmap;
@property int selectedBitmapIdent;
@property int selectedImage;
@end
