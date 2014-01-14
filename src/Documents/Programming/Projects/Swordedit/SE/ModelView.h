//
//  ModelView.h
//  swordedit
//
//  Created by sword on 6/2/08.
//  Copyright 2008 sword Inc. All rights reserved.
//
#ifndef MACVERSION
#import "glew.h"
#endif

#import <Cocoa/Cocoa.h>

#include  <OpenGL/OpenGL.h>
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#include <OpenGL/glext.h>

#define BITS_PER_PIXEL          32.0
#define DEPTH_SIZE              32.0
#define DEFAULT_TIME_INTERVAL   0.001

@class HaloMap;
@class ModelTag;

@interface ModelView : NSOpenGLView {
	HaloMap *_mapfile;
}
- (id)initWithFrame:(NSRect)frame;
- (void)initGL;
- (void)reshape;
- (void)drawRect:(NSRect)rect;
- (void)releaseAllObjects;
- (void)setMapfile:(HaloMap *)mapfile;
@property (retain) HaloMap *_mapfile;
@end
