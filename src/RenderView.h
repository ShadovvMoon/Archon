//
//  RenderView.h
//  swordedit
//
//  Created by sword on 5/6/08.
//  Copyright 2008 sword Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import  <OpenGL/OpenGL.h>
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#include <OpenGL/glext.h>
#import "Selection.h"
#import "Camera.h"
#import "Scenario.h"

#define BITS_PER_PIXEL          32.0
#define DEPTH_SIZE              32.0
#define DEFAULT_TIME_INTERVAL   0.001

//@class Camera;
@class HaloMap;
@class BSP;
@class Scenario;
@class ModelTag;
@class TextureManager;
@class SpawnEditorController;


@interface RenderView : NSOpenGLView {
	/* Render Option Buttons */
	IBOutlet NSMenuItem *pointsItem;
	IBOutlet NSMenuItem *wireframeItem;
	IBOutlet NSMenuItem *shadedTrisItem;
	IBOutlet NSMenuItem *texturedItem;
	NSView *view_glo;
	NSPoint graphicOrigin_glo;
	int my_pid_v;
	int haloProcessID;
	NSPoint en_glo;
	IBOutlet NSButton *buttonPoints;
	IBOutlet NSButton *buttonWireframe;
	IBOutlet NSButton *buttonShadedFaces;
	IBOutlet NSButton *buttonTextured;
    IBOutlet NSButton *wall;
	/* End Render Option Buttons */
	IBOutlet NSWindow *selecte;
	
	/* BSP Rendering Related */
	IBOutlet NSPopUpButton *bspNumbersButton;
	IBOutlet NSSlider *framesSlider;
	IBOutlet NSTextField *fpsText;
	/* End BSP Rendering */
	
	/* Begin object rendering options */
	IBOutlet NSSlider *lodDropdownButton;
	IBOutlet NSButton *useAlphaCheckbox;
	/* End object rendering options */
	
	IBOutlet NSTextField *opened;
	
	IBOutlet NSTextField *cam_p;
	
	/* Begin mouse movement style */
	IBOutlet NSButton *selectMode;
	IBOutlet NSButton *translateMode;
	IBOutlet NSButton *moveCameraMode;
	IBOutlet NSButton *duplicateSelected;
	IBOutlet NSButton *b_deleteSelected;
	
	IBOutlet NSSlider *cspeed;
	
	IBOutlet NSMenuItem *m_MoveCamera;
	IBOutlet NSMenuItem *m_SelectMode;
	IBOutlet NSMenuItem *m_TranslateMode;
	IBOutlet NSMenuItem *m_duplicateSelected;
	IBOutlet NSMenuItem *m_deleteFocused;
	/* End mouse movement style */
	
	/* Begin Selction Related */
	IBOutlet NSTextField *selectText;
	IBOutlet NSTextField *selectedName;
	IBOutlet NSTextField *selectedAddress;
	IBOutlet NSTextField *selectedType;
	IBOutlet NSPopUpButton *selectedSwapButton;
	/* End Selection Related */
	
	/* Begin Scenario Editing Related */
	IBOutlet NSTextField *s_accelerationText;
	IBOutlet NSSlider *s_accelerationSlider;
	
	// rotation Sliders
	IBOutlet NSSlider *s_xRotation;
	IBOutlet NSSlider *s_yRotation;
	IBOutlet NSSlider *s_zRotation;
	
	// rotation text
	IBOutlet NSTextField *s_xRotText;
	IBOutlet NSTextField *s_yRotText;
	IBOutlet NSTextField *s_zRotText;
	
	// Spawn creation related
	IBOutlet NSPopUpButton *s_spawnTypePopupButton;
	IBOutlet NSButton *s_spawnCreateButton;
	IBOutlet NSButton *s_spawnEditWindowButton;
	IBOutlet SpawnEditorController *_spawnEditor;
	/* End Scenario Editing Related */
	
	NSUserDefaults *prefs;
	
	bool shouldDraw;
	
	bool FullScreen;
	bool first;
	
	BOOL _useAlphas;
	int _LOD;
	float playercoords[200];
	
	ClearColors color_index;
	
	// RenderView mandatory objects
	Camera *_camera;
	NSTimer *drawTimer;
	
	// RenderView map-related objects
	HaloMap *_mapfile;
	Scenario *_scenario;
	BSP *mapBSP;
	TextureManager *_texManager;
	
	int activeBSPNumber;
	CVector3 camCenter[3];
	
	Key_In_Use move_keys_down[6];

	// Moving on...
	float _fps;
	float rendDistance;
	int currentRenderStyle;
	float maxRenderDistance;
	rgb meshColor;
	
	int dup;
	
	// Camera Variables
	float cameraMoveSpeed;
	float acceleration;
	int accelerationCounter;
	int is_css;
	
	NSMutableArray *new_characters;
	NSPoint prevDown;
	NSPoint prevRightDown;
	
	// Current selection mode
	int _mode;
	dynamic_object map_objects[8000];
	// Scenario stuff
	Selection *selee;
	
	// Selections managing
	NSMutableArray *selections;
	GLuint *_lookup;
	int _selectType;
	int _selectFocus;
	float s_acceleration;
	int isfull;
	int should_update;
	
	// Render settings
	float _lineWidth;
	double selectDistance;
	
	IBOutlet NSButton *msel;
	
	IBOutlet NSPanel *camera;
	IBOutlet NSPanel *render;
	IBOutlet NSPanel *spawnc;
	IBOutlet NSPanel *spawne;
	IBOutlet NSPanel *select;
	
	IBOutlet NSButton *player_1;
	IBOutlet NSButton *player_2;
	IBOutlet NSButton *player_3;
	IBOutlet NSButton *player_4;
	IBOutlet NSButton *player_5;
	IBOutlet NSButton *player_6;
	IBOutlet NSButton *player_7;
	IBOutlet NSButton *player_8;
	IBOutlet NSButton *player_9;
	IBOutlet NSButton *player_10;
	IBOutlet NSButton *player_11;
	IBOutlet NSButton *player_12;
	IBOutlet NSButton *player_13;
	IBOutlet NSButton *player_14;
	IBOutlet NSButton *player_15;
}
/* Begin Renderview-Specific Functions */
- (id)initWithFrame: (NSRect) frame;
- (void)initGL;
- (void)prepareOpenGL;
- (void)awakeFromNib;
- (void)reshape;
- (BOOL)acceptsFirstResponder;
- (void)keyDown:(NSEvent *)theEvent;
- (void)keyUp:(NSEvent *)event;
- (void)centerObj:(float *)coord move:(float *)move;
- (void)centerObj3:(float *)coord move:(float *)move;
- (void)mouseUp:(NSEvent *)theEvent;
-(IBAction)DropCamera:(id)sender;
- (void)mouseDown:(NSEvent *)event;
- (void)mouseDragged:(NSEvent *)theEvent;
- (void)mouseMoved:(NSEvent *)theEvent;
-(void)rightMouseDown:(NSEvent *)event;
- (void)rightMouseUp:(NSEvent *)theEvent;
- (void)rightMouseDragged:(NSEvent *)event;
-(IBAction)GoFullscreen:(id)sender;
- (void)timerTick:(NSTimer *)timer;
- (void)drawRect:(NSRect)Rect;
- (void)loadPrefs;
- (void)releaseMapObjects;
- (void)setMapObject:(HaloMap *)mapfile;
- (void)lookAt:(float)x y:(float)y z:(float)z;
- (void)stopDrawing;
- (void)resetTimerWithClassVariable;
/* End Renderview-Specific Functions */

-(IBAction)MovetoBSD:(id)sender;
/* Begin BSP rendering */
- (void)renderVisibleBSP:(BOOL)selectMode;
- (void)renderBSPAsPoints:(int)mesh_index;
- (void)renderBSPAsWireframe:(int)mesh_index;
- (void)renderBSPAsFlatShadedPolygon:(int)mesh_index;
- (void)renderBSPAsTexturedAndLightmaps:(int)mesh_index;
- (void)drawAxes;
- (void)resetMeshColors;
- (void)setNextMeshColor;

-(float *)getCameraPos;
-(float *)getCameraView;
/* End BSP rendering */

/* Begin scenario rendering */
- (void)renderAllMapObjects;
- (void)renderPlayerSpawn:(float *)coord team:(int)team isSelected:(BOOL)isSelected;
- (void)renderBox:(float *)coord rotation:(float *)rotation color:(float *)color selected:(BOOL)selected;
- (void)renderFlag:(float *)coord team:(int)team isSelected:(BOOL)isSelected;
- (void)renderNetgameFlags:(int *)name;
/* End scenario rendering */

/* Begin GUI interface section */
- (IBAction)renderBSPNumber:(id)sender;
- (IBAction)sliderChanged:(id)sender;
- (IBAction)buttonPressed:(id)sender;
- (IBAction)recenterCamera:(id)sender;
- (IBAction)orientCamera:(id)sender;
- (IBAction)changeRenderStyle:(id)sender;
- (IBAction)setCameraSpawn:(id)sender;
- (IBAction)setSelectionMode:(id)sender;
-(IBAction)SelectAll:(id)sender;
- (IBAction)openSEL:(id)sender;
- (IBAction)openCamera:(id)sender;
- (IBAction)openRender:(id)sender;
- (IBAction)openSXpawn:(id)sender;
- (IBAction)openSpawn:(id)sender;

- (IBAction)killKeys:(id)sender;
- (void)setRotationSliders:(float)x y:(float)y z:(float)z;
- (void)unpressButtons;
- (void)updateSpawnEditorInterface;
/* End GUI interface section */
-(int)usesColor;
/* Begin Scenario Editing Functions */
- (void)trySelection:(NSPoint)downPoint shiftDown:(BOOL)shiftDown width:(CGFloat)w height:(CGFloat)h;
- (void)deselectAllObjects;
- (void)processSelection:(unsigned int)name;
- (void)fillSelectionInfo;
- (void)performTranslation:(NSPoint)downPoint zEdit:(BOOL)zEdit;
- (void)performRotation:(NSPoint)downPoint zEdit:(BOOL)zEdit;
- (void)calculateTranslation:(float *)coord move:(float *)move;
- (float *)getTranslation:(float *)coord move:(float *)move;
- (void)applyMove:(float *)coord move:(float *)move;
- (void)rotateFocusedItem:(float)x y:(float)y z:(float)z;
-(IBAction)FocusOnPlayer:(id)sender;
-(IBAction)REDTEAM:(id)sender;
-(IBAction)BLUETEAM:(id)sender;
-(IBAction)GUARDIANTEAM:(id)sender;
-(IBAction)JAILTEAM:(id)sender;
-(IBAction)GODPOWER:(id)sender;
/* End Scenario Editing Functions */

/* Begin miscellaneous functions */
- (void)loadCameraPrefs;
- (void)renderPartyTriangle;
/* End miscellaneous functions */
@end
