//
//  RenderView.h
//  swordedit
//
//  Created by sword on 5/6/08.
//  Copyright 2008 sword Inc. All rights reserved.
//
#ifndef MACVERSION
#import "glew.h"
#endif

#import <Cocoa/Cocoa.h>


#import  <OpenGL/OpenGL.h>
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#include <OpenGL/glext.h>
#import "Selection.h"
#import "Camera.h"
#import "Scenario.h"
#import "BspMesh.h"

#define BITS_PER_PIXEL          64.0
#define DEPTH_SIZE              64.0
#define DEFAULT_TIME_INTERVAL   0.001

//@class Camera;
@class HaloMap;
@class BSP;
@class Scenario;
@class ModelTag;
@class TextureManager;
@class SpawnEditorController;


@interface RenderView : NSOpenGLView
{
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
    IBOutlet NSButton *dirtMode;
    IBOutlet NSButton *grassMode;
    IBOutlet NSButton *eyedropperMode;
    IBOutlet NSButton *lightmapMode;
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
	IBOutlet NSSlider *paintSize;
	/* Begin Selction Related */
	IBOutlet NSTextField *selectText;
	IBOutlet NSTextField *selectedName;
	IBOutlet NSTextField *selectedAddress;
	IBOutlet NSTextField *selectedType;
	IBOutlet NSPopUpButton *selectedSwapButton;
	IBOutlet NSPopUpButton *selectedTypeSwapButton;
	IBOutlet NSPopUpButton *renderEngine;
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
    
    IBOutlet NSTextField *s_xText;
	IBOutlet NSTextField *s_yText;
	IBOutlet NSTextField *s_zText;
    
    IBOutlet NSTextField *fps;
	
	// Spawn creation related
	IBOutlet NSPopUpButton *s_spawnTypePopupButton;
	IBOutlet NSButton *s_spawnCreateButton;
	IBOutlet NSButton *s_spawnEditWindowButton;
	IBOutlet NSButton *s_skullCreateButton;
	IBOutlet NSButton *s_machineCreateButton;
	IBOutlet SpawnEditorController *_spawnEditor;
	/* End Scenario Editing Related */
	
    IBOutlet NSButton *rendererSwitch;
    IBOutlet NSButton *renderObject;
    IBOutlet NSColorWell *paintColor;
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
	
	bsp_point *bsp_points;
	int bsp_point_count;
	int editable;

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
	int ignoreCSS;
    
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
	uint64_t        previous;
    
	// Render settings
	float _lineWidth;
	double selectDistance;
	
    IBOutlet NSPopUpButton *renderGametype;
	IBOutlet NSButton *msel;
	
	IBOutlet NSPanel *camera;
	IBOutlet NSPanel *render;
	IBOutlet NSPanel *spawnc;
	IBOutlet NSPanel *spawne;
	IBOutlet NSPanel *select;
	IBOutlet NSPanel *machine;
	IBOutlet NSTextField *statusMessage;
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
	IBOutlet NSButton *first_person_mode;
	IBOutlet NSSlider *duplicate_amount;
	IBOutlet NSPopUpButton *createType;
    int indexHighlight;
    int indexMesh;
    
    
    IBOutlet NSPanel *settings_Window_Object;
    
	SUBMESH_INFO *pMesh;
    id popover;
    NSViewController *c;
    IBOutlet NSView *settingsView;
    
    BOOL duplicatedAlready;
    
    float lastExtreme;
}


-(IBAction)reloadBitmapsForMap:(id)sender;
-(IBAction)openSettingsPopup:(id)sender;
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
-(NSNumber*)isAboveGround:(float*)pos;
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
- (IBAction)openMach:(id)sender;

- (IBAction)killKeys:(id)sender;
- (void)setRotationSliders:(float)x y:(float)y z:(float)z;
- (void)unpressButtons;
- (void)updateSpawnEditorInterface;
/* End GUI interface section */
-(int)usesColor;
/* Begin Scenario Editing Functions */
//- (void)trySelection:(NSPoint)downPoint shiftDown:(BOOL)shiftDown width:(CGFloat)w height:(CGFloat)h;
//- (void)deselectAllObjects;
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
@property (retain) NSMenuItem *pointsItem;
@property (retain) NSMenuItem *wireframeItem;
@property (retain) NSMenuItem *shadedTrisItem;
@property (retain) NSMenuItem *texturedItem;
@property (retain) NSView *view_glo;
@property (setter=setPID:) int my_pid_v;
@property (getter=ID) int haloProcessID;
@property (retain) NSButton *buttonPoints;
@property (retain) NSButton *buttonWireframe;
@property (retain) NSButton *buttonShadedFaces;
@property (retain) NSButton *buttonTextured;
@property (retain) NSButton *wall;
@property (retain) NSWindow *selecte;
@property (retain) NSPopUpButton *bspNumbersButton;
@property (retain) NSSlider *framesSlider;
@property (retain) NSTextField *fpsText;
@property (retain) NSSlider *lodDropdownButton;
@property (retain) NSButton *useAlphaCheckbox;
@property (retain) NSTextField *opened;
@property (retain) NSTextField *cam_p;
@property (retain) NSButton *selectMode;
@property (retain) NSButton *translateMode;
@property (retain) NSButton *moveCameraMode;
@property (retain) NSButton *duplicateSelected;
@property (retain) NSButton *b_deleteSelected;
@property (retain) NSSlider *cspeed;
@property (retain) NSMenuItem *m_MoveCamera;
@property (retain) NSMenuItem *m_SelectMode;
@property (retain) NSMenuItem *m_TranslateMode;
@property (retain) NSMenuItem *m_duplicateSelected;
@property (retain) NSMenuItem *m_deleteFocused;
@property (retain) NSTextField *selectText;
@property (retain) NSTextField *selectedName;
@property (retain) NSTextField *selectedAddress;
@property (retain) NSTextField *selectedType;
@property (retain) NSPopUpButton *selectedSwapButton;
@property (retain) NSTextField *s_accelerationText;
@property (retain) NSSlider *s_accelerationSlider;
@property (retain) NSSlider *s_xRotation;
@property (retain) NSSlider *s_yRotation;
@property (retain) NSSlider *s_zRotation;
@property (retain) NSTextField *s_xRotText;
@property (retain) NSTextField *s_yRotText;
@property (retain) NSTextField *s_zRotText;
@property (retain) NSPopUpButton *s_spawnTypePopupButton;
@property (retain) NSButton *s_spawnCreateButton;
@property (retain) NSButton *s_spawnEditWindowButton;
@property (retain) SpawnEditorController *_spawnEditor;
@property (retain) NSUserDefaults *prefs;
@property 	bool shouldDraw;
@property 	bool FullScreen;
@property 	bool first;
@property BOOL _useAlphas;
@property int _LOD;
@property (retain) Camera *_camera;
@property (retain) NSTimer *drawTimer;
@property (retain) HaloMap *_mapfile;
@property (retain) Scenario *_scenario;
@property (retain) BSP *mapBSP;
@property (retain) TextureManager *_texManager;
@property int activeBSPNumber;
@property float _fps;
@property float rendDistance;
@property int currentRenderStyle;
@property float maxRenderDistance;
@property int dup;
@property float cameraMoveSpeed;
@property float acceleration;
@property int accelerationCounter;
@property int is_css;
@property (retain) NSMutableArray *new_characters;
@property int _mode;
@property (retain) Selection *selee;
@property (retain) NSMutableArray *selections;
@property GLuint *_lookup;
@property int _selectType;
@property int _selectFocus;
@property float s_acceleration;
@property int isfull;
@property int should_update;
@property float _lineWidth;
@property double selectDistance;
@property (retain) NSButton *msel;
@property (retain) NSPanel *camera;
@property (retain) NSPanel *render;
@property (retain) NSPanel *spawnc;
@property (retain) NSPanel *spawne;
@property (retain) NSPanel *select;
@property (retain) NSButton *player_1;
@property (retain) NSButton *player_2;
@property (retain) NSButton *player_3;
@property (retain) NSButton *player_4;
@property (retain) NSButton *player_5;
@property (retain) NSButton *player_6;
@property (retain) NSButton *player_7;
@property (retain) NSButton *player_8;
@property (retain) NSButton *player_9;
@property (retain) NSButton *player_10;
@property (retain) NSButton *player_11;
@property (retain) NSButton *player_12;
@property (retain) NSButton *player_13;
@property (retain) NSButton *player_14;
@property (retain) NSButton *player_15;
@property (retain) NSSlider *duplicate_amount;
@end


float uva1;
float uva2;
float uva3;

int selectedPIndex;
