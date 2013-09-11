//
//  BSPView.h
//  SparkEdit
//
//  Created by Michael Edgar on Tue Jul 20 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//
@class BspManager;
@class Camera;
@class HaloMap;
@class ScenarioTag;
@class BitmapTag;
@class ModelTag;
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

#define RENDER_POINTS        1
#define RENDER_TRIS          2
#define RENDER_FLAT_SHADING  3
#define RENDER_TEXTURED      4
#define RENDER_TEXTURED_TRIS 5

#define TYPE_VEHICLE 1
#define TYPE_SCENERY 2
#define TYPE_ITEM    3
#define TYPE_PLAYERSPAWN 4

#define ROTATE_CAMERA_MODE 1
#define SELECT_MODE        2
#define TRANSLATE_MODE     3

typedef struct
{
	float red;
	float blue;
	float green;
	long color_count;
} rgb;

@interface BSPView : NSOpenGLView {
	IBOutlet id rotateCamButton;
	IBOutlet id selectButton;
	IBOutlet id translateButton;

	float zoom;
	BspManager *myManager;
	ScenarioTag *myScenario;
	rgb m_PolyColor;
	long m_RenderMode;
	Camera *myCamera;
	NSPoint downPoint;
	
	unsigned long mode;
	
	float rotx,roty,rotz;
	float myDistance;
	float moveSize;
	float vehicleDrawDistance;
	float sceneryDrawDistance;
	float itemDrawDistance;
	float playerSpawnDrawDistance;
	
	float m_LastSelectionPos[3];
}
- (void)PerformTranslationEdit:(NSEvent *)event;
- (IBAction)changeMode:(id)sender;
- (void)drawPlayerSpawnAtPoint:(float*)point team:(long)team index:(long)index selected:(bool)selected;
- (float)distanceToPoint:(float*)point;
- (void)reshape;
- (void)setManager:(BspManager*)manager;
- (void)setScenario:(ScenarioTag*)scenario;
- (void)prepareOpenGL;
- (void)awakeFromNib;
- (void)setRenderMode:(short)newmode;
- (void)ResetMeshColors;
- (void)SetNextMeshColor;
- (void)drawRect:(NSRect)aRect;
- (void)mouseDown:(NSEvent *)event;
- (void)mouseDragged:(NSEvent *)event;
- (void)increaseZoom:(float)inc;
- (void)RotateX:(float)x;
- (void)RotateY:(float)y;
- (void)RotateZ:(float)z;
- (void)preferencesChanged;
- (void)pickInstance:(long)px y:(long)y shift:(BOOL)shift;
- (void)RenderTexture:(unsigned long) mesh_index;
- (void)scrollWheel:(NSEvent *)theEvent;
- (void)RenderPcPoints:(unsigned long)mesh_index;
- (void)RenderPcSubmeshLines:(unsigned long)mesh_index;
- (void)RenderPcFlatShadedPolygons:(unsigned long)mesh_index;
@end
