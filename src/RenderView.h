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
#import "Stamps.h"

#include "SDMPluginHandler.h"
#import "SeparatorCell.h"

#ifdef MODZY_RENDERING
#define BITS_PER_PIXEL          32.0
#define DEPTH_SIZE              32.0
#else
#define BITS_PER_PIXEL          64.0
#define DEPTH_SIZE              64.0
#endif

#define DEFAULT_TIME_INTERVAL   0.001

//@class Camera;
@class HaloMap;
@class BSP;
@class Scenario;
@class ModelTag;
@class TextureManager;
@class SpawnEditorController;

float fromPt[3];
float toPt[3];
int docopyme;
int packetReady;
int didReceive;

float insX, insY, insZ;
struct sockaddr *peeraddress;
int socketAddress;
int currentPacketNumberFirst;

BOOL skipTheFog;
@interface RenderView : NSOpenGLView
{
    IBOutlet NSOutlineView *tag_listing;
    
    GLuint water_normal;
    GLuint refraction_map;
    
    BOOL reflectionIsRequired;
    float reflectionHeight;
    

    GLuint reflect_texture;
    
    BOOL fastRendering;
    BOOL renderingWater;

    
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
	IBOutlet Stamps *stamp;
	/* Begin object rendering options */
	IBOutlet NSSlider *lodDropdownButton;
	IBOutlet NSButton *useAlphaCheckbox;
	/* End object rendering options */
	
	IBOutlet NSTextField *opened;
	
	IBOutlet NSTextField *cam_p;
    
	IBOutlet NSTextField *serveraddress;
	IBOutlet NSTextField *serverport;
	
    IBOutlet NSTextField *ai_playerNumber;
    IBOutlet NSButton *ai_seek;
    IBOutlet NSButton *ai_move;
    IBOutlet NSButton *ai_shoot;
    IBOutlet NSButton *ai_crouch;
    IBOutlet NSButton *ai_headers;
    IBOutlet NSButton *ai_team;
    IBOutlet NSButton *ai_team1;
    IBOutlet NSButton *ai_grenade;
    IBOutlet NSButton *ai_teamswitch;
    IBOutlet NSButton *ai_action;
    IBOutlet NSButton *ai_melee;
    IBOutlet NSTextField *playerNumberImpersonate;
    float gah;
	/* Begin mouse movement style */
	IBOutlet NSButton *selectMode;
    IBOutlet NSButton *newMode;
	IBOutlet NSButton *translateMode;
    IBOutlet NSButton *dirtMode;
    IBOutlet NSButton *grassMode;
    IBOutlet NSButton *eyedropperMode;
    IBOutlet NSButton *lightmapMode;
	IBOutlet NSButton *moveCameraMode;
	IBOutlet NSButton *duplicateSelected;
	IBOutlet NSButton *b_deleteSelected;
	IBOutlet NSButton *filterNetwork;
	IBOutlet NSButton *isStrafed;
	
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
	
	Key_In_Use move_keys_down[7];

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
	
    CVector3 initialPosition;
    CVector3 initialMouse;
    CVector3 initialObjectPosition;
    NSNumber *moveNameLookup;
    NSMutableArray *cacheTagArray;
    
	// Current selection mode
	int _mode;
	dynamic_object map_objects[8000];
	// Scenario stuff
	Selection *selee;
	struct KnownTypes *know_types;
    
    float globalYCoordinate;
    IBOutlet NSView *tagClipView;
    
	// Selections managing
	NSMutableArray *selections;
	GLuint *_lookup;
    GLsizei loopupSize;
    
	int _selectType;
	int _selectFocus;
	float s_acceleration;
	int isfull;
	int should_update;
	uint64_t        previous;
    
    NSPopover *settingsPopover;
    IBOutlet NSView *settingsView;
    NSViewController *settingsViewController;
    
	// Render settings
	float _lineWidth;
	double selectDistance;
	
    IBOutlet NSPopUpButton *renderGametype;
	IBOutlet NSButton *msel;
	
	IBOutlet NSPanel *camera;
	IBOutlet NSPanel *render;
	IBOutlet NSPanel *spawnc;
	IBOutlet NSPanel *spawne;
	IBOutlet NSPanel *select_panel;
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
    
    IBOutlet NSScrollView *scroll_settings;
    
    IBOutlet NSPanel *settings_Window_Object;
    
	SUBMESH_INFO *pMesh;
    id popover;
    NSViewController *c;
   
    BOOL duplicatedAlready;
    BOOL didMoveObject;
    float lastExtreme;
    
    BOOL isJumping;
    BOOL isInAir;
    float xv,yv,zv;
    
    float jumpSpeed;
    float jumpStrafe;
    
    float currentHeight;
    float goalHeight;
    
    float lastPosition[6];
    float Gg[6];
    
    BOOL hasn;
    float normalAmount;
    float *n;
    
    uint64_t initialTime;
    float jumpZ;
    
    IBOutlet NSSlider *tickSlider;
    IBOutlet NSPanel *debugWindow;
    
    IBOutlet NSTextField *tickAmount;
    IBOutlet NSButton *paintDebug;
    IBOutlet NSButton *wireframeBSP;
    
    IBOutlet NSButton *teleporterLines;
    IBOutlet NSButton *raceLines;
    IBOutlet NSButton *hillLines;
    IBOutlet NSButton *clipPaint;
    IBOutlet NSButton *pixelPaint;
    
    IBOutlet NSSlider *netgamesize;
    IBOutlet NSSlider *spherequality;
    
    
    IBOutlet NSTextField *normalHeight;
    IBOutlet NSTextField *crouchHeight;
    IBOutlet NSTextField *changeSpeed;
    
    IBOutlet NSTextField *gravityAmount;
    IBOutlet NSTextField *jumpVelocity;
    IBOutlet NSTextField *forwardSpeed;
    IBOutlet NSTextField *colorRGBA;
    
    IBOutlet NSButton *copyMe;
    IBOutlet NSButton *doHost;
    int32_t globalModelIdentifier;
    NSMutableDictionary *tagIdConversion;
    
    NSMutableArray *modelData;
    NSMutableArray *indexData;
    NSMutableArray *soundData;
    NSMutableArray *bitmapData;
    
    BOOL alreadyInitialised;
    IBOutlet NSButton *render_playerSpawns;
    IBOutlet NSButton *render_Encounters;
    IBOutlet NSButton *render_itemSpawns;
    IBOutlet NSButton *render_machines;
    IBOutlet NSButton *render_vehicles;
    IBOutlet NSButton *render_scen;
    IBOutlet NSButton *render_sky;
    IBOutlet NSButton *render_netgame;
    
    IBOutlet NSButton *render_bsp;
    IBOutlet NSButton *render_objects;
    IBOutlet NSButton *render_settings;
    IBOutlet NSButton *render_flush;
    
    IBOutlet NSButton *render_reshape;
    IBOutlet NSButton *render_junk;
    IBOutlet NSButton *render_colours;
    IBOutlet NSButton *render_idents;
    IBOutlet NSButton *render_meshc;
    IBOutlet NSButton *render_scaling;
     IBOutlet NSButton *render_det1;
     IBOutlet NSButton *render_det2;
    IBOutlet NSButton *render_LM;
    IBOutlet NSButton *render_sun;
    IBOutlet NSButton *render_SP;
    NSDate *jumpTime;
    
    
    BOOL needsReshape;
    NSRect lastRectShape;
    
    BOOL alreadyRefreshing;
    
    BOOL needsPaintRefresh;
    BOOL isUnfocused;
    
    
    /*
    NSMutableArray				*contents;
	
	// cached images for generic folder and url document
	NSImage						*folderImage;
	NSImage						*urlImage;
	
	NSView						*currentView;

	
	BOOL						buildingOutlineView; // signifies building the outline view at launch time
    
	BOOL						retargetWebView;
	
	SeparatorCell				*separatorCell;	// the cell used to draw a separator line in the outline view
    */
    
    NSMutableArray *list_of_tag_types;
    NSMutableDictionary *list_of_tag_subgroups;
    
    BOOL shadersDefined;
    GLuint scex_program;
    GLuint schi_program;
    GLuint sgla_program;
    GLuint light_program;
    GLuint normal_program;
    GLuint water_program;
    GLuint Water_Normal_Texture, Water_Normal_TextureID;

    IBOutlet NSPopUpButton *render_type_new;
    
    IBOutlet NSButton *paint_tool_archon;
    IBOutlet NSButton *selection_tool_archon;
    IBOutlet NSButton *structural_tool_archon;
    
    IBOutlet NSPopUpButton *paint_type;
    
    BOOL isRenderingAllBSPS;
    
}
    
-(IBAction)renderAllBSPS:(id)sender;

-(IBAction)toggleCollisionModels:(id)sender;
-(IBAction)rowClicked:(id)sender;
-(IBAction)pasteTag:(id)sender;
-(IBAction)doubleLightmaps:(id)sender;
-(IBAction)connectToServer:(id)sender;

-(IBAction)changeGametype:(id)sender;
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
//@property 	bool shouldDraw;
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
@property (retain) NSPanel *select_panel;
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
