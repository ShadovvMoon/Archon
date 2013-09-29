//
//  RenderView.m
//  swordedit
//
//  Created by sword on 5/6/08.renderO
//  Copyright 2008 sword Inc. All rights reserved.
//

#import "RenderView.h"
#import "defines.h"

#import "Camera.h"

#import "GeneralMath.h"

#import "BSP.h"
#import "ModelTag.h"

#import "TextureManager.h"

#import "SpawnEditorController.h"
#import "unistd.h"
//#import "math.h"


#include <assert.h>
#include <CoreServices/CoreServices.h>

#include <unistd.h>
#import "BitmapTag.h"


#ifndef MACVERSION
#import "glew.h"
#endif

#import <OpenGL/glext.h>
#import <OpenGL/glu.h>





CVector3 AddTwoVectors(CVector3 v1, CVector3 v2);
CVector3 SubtractTwoVectors(CVector3 v1, CVector3 v2);
CVector3 MultiplyTwoVectors(CVector3 v1, CVector3 v2);
CVector3 DivideTwoVectors(CVector3 v1, CVector3 v2);
CVector3 Cross(CVector3 vVector1, CVector3 vVector2);
float Magnitude(CVector3 vNormal);
CVector3 Normalize(CVector3 vVector);
CVector3 Cross(CVector3 vVector1, CVector3 vVector2);
CVector3 NewCVector3(float x,float y,float z);

GLfloat lightPos[]={50.371590,-50.247974,100,0.0};

int selectedBSP = -1;

/* 
 create a matrix that will project the desired shadow */
void
shadowmatrix(GLfloat shadowMat[4][4],
             GLfloat groundplane[4],
             GLfloat lightpos[4])
{
    GLfloat dot;
    
    /* find dot product between light position vector and ground plane normal */
    dot = groundplane[0] * lightpos[0] +
    groundplane[1] * lightpos[1] +
    groundplane[2] * lightpos[2] +
    groundplane[3] * lightpos[3];
    
    shadowMat[0][0] = dot - lightpos[0] * groundplane[0];
    shadowMat[1][0] = 0.f - lightpos[0] * groundplane[1];
    shadowMat[2][0] = 0.f - lightpos[0] * groundplane[2];
    shadowMat[3][0] = 0.f - lightpos[0] * groundplane[3];
    
    shadowMat[0][1] = 0.f - lightpos[1] * groundplane[0];
    shadowMat[1][1] = dot - lightpos[1] * groundplane[1];
    shadowMat[2][1] = 0.f - lightpos[1] * groundplane[2];
    shadowMat[3][1] = 0.f - lightpos[1] * groundplane[3];
    
    shadowMat[0][2] = 0.f - lightpos[2] * groundplane[0];
    shadowMat[1][2] = 0.f - lightpos[2] * groundplane[1];
    shadowMat[2][2] = dot - lightpos[2] * groundplane[2];
    shadowMat[3][2] = 0.f - lightpos[2] * groundplane[3];
    
    shadowMat[0][3] = 0.f - lightpos[3] * groundplane[0];
    shadowMat[1][3] = 0.f - lightpos[3] * groundplane[1];
    shadowMat[2][3] = 0.f - lightpos[3] * groundplane[2];
    shadowMat[3][3] = dot - lightpos[3] * groundplane[3];
    
}

bool   gp;                      // G Pressed? ( New )
GLuint filter;                      // Which Filter To Use
GLuint fogMode[]= { GL_EXP, GL_EXP2, GL_LINEAR };   // Storage For Three Types Of Fog
GLuint fogfilter= 0;                    // Which Fog To Use


/*
	TODO:
		Fucking lookup selection lookup table is being fed very large values for some reason. Something to do with the names, have to check it out.
*/

int useNewRenderer()
{
    return newR;
}

bool drawObjects()
{
    return drawO;
}

@implementation RenderView
/* w
*
*		Begin RenderView Functions 
*
*/

-(IBAction)changeRenderer:(id)sender
{
    newR = (int)[sender indexOfItem:[sender selectedItem]];
}

-(IBAction)changeDrawObjects:(id)sender
{
    drawO = [sender state];
}




-(void)setPID:(int)my_pid
{
	my_pid_v = my_pid;
}

- (id)initWithFrame: (NSRect) frame
{
    USEDEBUG NSLog(@"Init render view");
    

    renderV = self;
    USEDEBUG NSLog(@"Creating");
	// First, we must create an NSOpenGLPixelFormatAttribute
	NSOpenGLPixelFormat *nsglFormat;
    
    
	NSOpenGLPixelFormatAttribute attr[] = 
	{
		NSOpenGLPFADoubleBuffer,
        NSOpenGLPFASupersample,
        NSOpenGLPFASampleBuffers, 1,
        NSOpenGLPFASamples, 4,
		NSOpenGLPFAAccelerated,
		NSOpenGLPFAColorSize, 
		BITS_PER_PIXEL,
		NSOpenGLPFADepthSize, 
		DEPTH_SIZE,
		0 
	};


    lightScene = false;
    //[self setPostsFrameChangedNotifications: YES];
	
    USEDEBUG NSLog(@"More inits");
    
	// Next, we initialize the NSOpenGLPixelFormat itself
    nsglFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attr];
	
	// Check for errors in the creation of the NSOpenGLPixelFormat
    // If we could not create one, return nil (the OpenGL is not initialized, and
    // we should send an error message to the user at this point)
    if(!nsglFormat) { NSLog(@"Invalid format... terminating."); return nil; }
	USEDEBUG  NSLog(@"Still initing");
    
	// Now we create the the CocoaGL instance, using our initial frame and the NSOpenGLPixelFormat
    self = [super initWithFrame:frame pixelFormat:nsglFormat];
    [nsglFormat release];
	
	// If there was an error, we again should probably send an error message to the user
    if(!self) { NSLog(@"Self not created... terminating."); return nil; }
	USEDEBUG NSLog(@"Making contenxt");
	// Now we set this context to the current context (means that its now drawable)
    [[self openGLContext] makeCurrentContext];
	[[self openGLContext] setView:self];
    
	// Finally, we call the initGL method (no need to make this method too long or complex)
    [self initGL];
    USEDEBUG NSLog(@"Finished");
    return self;
    
}
- (void)initGL
{
    NSLog(@"Initing GL");
#ifndef MACVERSION
    GLenum error = glewInit();
    if (error != GLEW_OK)
    {
        
        printf ("An error occurred with glew %d: %s \n", error, (char *) glewGetErrorString(error));
    }
#endif
    
	
	glClearDepth(1.0f);
	glDepthFunc(GL_LESS);
	//glEnable(GL_DEPTH_TEST);
	
   
	/*glHint(GL_POLYGON_SMOOTH_HINT,GL_NICEST);
    
    
    if (lightScene)
    {
        GLfloat ambientLight[]={0.2,0.2,0.2,1.0};    	             // set ambient light parameters
        glLightfv(GL_LIGHT0,GL_AMBIENT,ambientLight);
        
        GLfloat diffuseLight[]={1.0,1.0,1.0,1.0};    	             // set diffuse light parameters
        glLightfv(GL_LIGHT0,GL_DIFFUSE,diffuseLight);

        
        glEnable(GL_LIGHT0);                         	              // activate light0
        glEnable(GL_LIGHTING);                       	              // enable lighting
        glLightModelfv(GL_LIGHT_MODEL_AMBIENT, ambientLight); 	     // set light model
        glEnable(GL_COLOR_MATERIAL);                 	              // activate material
        glColorMaterial(GL_FRONT,GL_AMBIENT_AND_DIFFUSE);
        glEnable(GL_NORMALIZE);                      	              // normalize normal vectors
    }*/
	
	first = YES;

   
}
- (void)prepareOpenGL
{
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClearDepth(1.0f);
	glDepthFunc(GL_LESS);
	//glEnable(GL_DEPTH_TEST);
	
	glHint(GL_POLYGON_SMOOTH_HINT,GL_NICEST);
	
	first = YES;
	//NSLog(@"end initGL");
}

-(void)updateQuickLink:(NSTimer *)abc
{
    //NSLog(@"Update quicklink");
    /*
	[player_1 setTitle:[new_characters objectAtIndex:0]];
	[player_2 setTitle:[new_characters objectAtIndex:1]];
	[player_3 setTitle:[new_characters objectAtIndex:2]];
	[player_4 setTitle:[new_characters objectAtIndex:3]];
	[player_5 setTitle:[new_characters objectAtIndex:4]];
	[player_6 setTitle:[new_characters objectAtIndex:5]];
	[player_7 setTitle:[new_characters objectAtIndex:6]];
	[player_8 setTitle:[new_characters objectAtIndex:7]];
	[player_9 setTitle:[new_characters objectAtIndex:8]];
	[player_10 setTitle:[new_characters objectAtIndex:9]];
	[player_11 setTitle:[new_characters objectAtIndex:10]];
	[player_12 setTitle:[new_characters objectAtIndex:11]];
	[player_13 setTitle:[new_characters objectAtIndex:12]];
	[player_14 setTitle:[new_characters objectAtIndex:13]];
	[player_15 setTitle:[new_characters objectAtIndex:14]];
*/
}

#include <assert.h>
#include <CoreServices/CoreServices.h>

#include <unistd.h>

-(void)renderTimer:(id)object
{
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
    
    //Calculate fps

    int averageFPS = 100;
    int fpsCap = 30;
    
    uint64_t        start;
    uint64_t        end;
    
    
    uint64_t        start2;
    uint64_t        end2;
    uint64_t        elapsed2;
    
    uint64_t        elapsed;

    
    uint64_t        required = ((1000000000.0)/ fpsCap); 
    
    while(1)
    {


        
        
            
            
            
            start = mach_absolute_time();
        
        
            //Cap FPS at 30
        
            int i;
            for (i=0; i < averageFPS; i++)
            {
                [self performSelectorOnMainThread:@selector(timerTick:) withObject:nil waitUntilDone:YES];
            }
        
            end = mach_absolute_time();
            elapsed = end - start;
        
            double fps = ((1000000000.0 * averageFPS)/ elapsed);
            [fpsText performSelectorOnMainThread:@selector(setStringValue:) withObject:[NSString stringWithFormat:@"FPS: %f", fps] waitUntilDone:YES];
            
        if (!performanceMode)
            break;
        //NSLog(@"%f", fps);
         
    }
    
	//[runLoop run];
	//[pool release];
}


-(IBAction)openSettingsPopup:(id)sender
{
    if (popover)
    {
        [popover close];
        popover = nil;
    }
    if (c)
    {
        [c release];
        c=nil;
        return;
    }
 
    
    c = [[NSViewController alloc] init];
    c.view = settingsView;
    
    [popover setContentViewController:c];
    [popover setContentSize:c.view.frame.size];
    
    
    [popover showRelativeToRect:NSMakeRect([sender frame].size.width/2-0.5, 20, 1, 1) ofView:sender preferredEdge:NSMaxYEdge];
}
-(IBAction)reloadBitmapsForMap:(id)sender
{
    
    if (performanceMode)
    {
        [performanceThread cancel];
        performanceMode = FALSE;
        
        [self resetTimerWithClassVariable];
    }
    else
    {
        
        if (NSRunAlertPanel(@"Are you sure you want to enter performance mode?", @"Performance mode will render frames as fast as it can. Presents a smooth visual performance but may stutter on large maps.", @"Cancel", @"Enter Performance Mode", nil) == NSOKButton)
        {
            
        }
        else
        {
            [drawTimer invalidate];
            [drawTimer release];
            drawTimer = nil;
            
            performanceMode = TRUE;
            
            performanceThread = [[NSThread alloc] initWithTarget:self selector:@selector(renderTimer:) object:nil]; //Create a new thread
            [performanceThread start];
        }
        
    }
    
    
    
    
    //[_texManager deleteAllTextures];
    //[mapBSP setActiveBsp:0];
    
    return;
    // First, we must create an NSOpenGLPixelFormatAttribute
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
	
	// Next, we initialize the NSOpenGLPixelFormat itself
    nsglFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attr];
	
	// Check for errors in the creation of the NSOpenGLPixelFormat
    // If we could not create one, return nil (the OpenGL is not initialized, and
    // we should send an error message to the user at this point)
    //if(!nsglFormat) { NSLog(@"Invalid format... terminating."); return nil; }
	
	// Now we create the the CocoaGL instance, using our initial frame and the NSOpenGLPixelFormat
    //self = [super initWithFrame:frame pixelFormat:nsglFormat];
    //[nsglFormat release];
	
	// If there was an error, we again should probably send an error message to the user
    //if(!self) { NSLog(@"Self not created... terminating."); return nil; }
	
	// Now we set this context to the current context (means that its now drawable)
    [[self openGLContext] makeCurrentContext];
	
	// Finally, we call the initGL method (no need to make this method too long or complex)
    [self initGL];
    //glFlush();
}
- (void)awakeFromNib
{
    NSLog(@"Checking mac render view");
   
    /*
#ifndef MACVERSION
    return;
#endif
    */
	//[[self window] setLevel:100];
	
	int i;
	for (i = 0; i < 150; i++)
	{
		playercoords[i] = 0.0;
	}
	
	
	
	is_css = YES;
	//isfull = YES;
	selee = [[Selection alloc] initWithContentRect:NSMakeRect(0, 0, 0, 0) styleMask:NSBorderlessWindowMask backing:nil defer:YES];
	[selee setReleasedWhenClosed:NO];
	
	[spawne setFrame:NSMakeRect([[NSScreen mainScreen] frame].size.width - [spawne frame].size.width,[[NSScreen mainScreen] frame].size.height - [spawne frame].size.height - 44, [spawne frame].size.width, [spawne frame].size.height) display:YES];
	[spawnc setFrame:NSMakeRect([[NSScreen mainScreen] frame].size.width - [spawnc frame].size.width,[[NSScreen mainScreen] frame].size.height - [spawne frame].size.height - [spawnc frame].size.height - 44 - 8, [spawnc frame].size.width, [spawnc frame].size.height) display:YES];
	//[render setFrame:NSMakeRect([[NSScreen mainScreen] frame].size.width - [render frame].size.width,[[NSScreen mainScreen] frame].size.height - [spawne frame].size.height - [spawnc frame].size.height - [render frame].size.height - 44 - 16, [render frame].size.width, [render frame].size.height) display:YES];
	//[camera setFrame:NSMakeRect([[NSScreen mainScreen] frame].size.width - [camera frame].size.width,[[NSScreen mainScreen] frame].size.height - [spawne frame].size.height - [spawnc frame].size.height - [render frame].size.height - [camera frame].size.height - 44 - 24, [camera frame].size.width, [camera frame].size.height) display:YES];
	
	[select setFrame:NSMakeRect([[NSScreen mainScreen] frame].size.width - [select frame].size.width,[[NSScreen mainScreen] frame].size.height - [spawne frame].size.height - [spawnc frame].size.height - [select frame].size.height - 24 - 32, [select frame].size.width, [select frame].size.height) display:YES];
	
	[[self window] setFrame:NSMakeRect(0, 0, [[NSScreen mainScreen] frame].size.width, [[NSScreen mainScreen] frame].size.height) display:YES];
	
	_fps = 30;
	drawTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0/_fps) target:self selector:@selector(timerTick:) userInfo:nil repeats:YES] retain];
	
    //NSThread* timerThread = [[NSThread alloc] initWithTarget:self selector:@selector(renderTimer:) object:nil]; //Create a new thread
	//[timerThread start];

	prefs = [NSUserDefaults standardUserDefaults];
	[self loadPrefs];
	
	shouldDraw = NO;
	
	_camera = [[Camera alloc] init];
	acceleration = 0;
	cameraMoveSpeed = 0.5;
	maxRenderDistance = 3000000.0f;
	
	selectDistance = 300.0f;
	rendDistance = 3000000.0f;
	
	meshColor.blue = 1.0;
	meshColor.green = 0.1;
	meshColor.red = 0.1;
	meshColor.color_count = 0;
	
	color_index = alphaIndex;
    drawO = true;
    
#ifdef MACVERSION
    newR = 3;
#else
    newR = 3;
#endif
    
    [renderEngine selectItemAtIndex:newR];
	
	currentRenderStyle = textured_tris;
	
	_LOD = 4;
	
	_selectType = 0;
	s_acceleration = 1.0f;
	
	[fpsText setFloatValue:50.0];
	[bspNumbersButton removeAllItems];
	
	_mode = rotate_camera;
	[moveCameraMode setState:NSOnState];
	
	[_spawnEditor setUpdateDelegate:self];
	
	selections = [[NSMutableArray alloc] initWithCapacity:2000]; // Default it at 300, but possible to expand if needed lol.
	[selections retain];
	
	//selections = [[NSMutableArray alloc] initWithCapacity:1000];
	
	_lineWidth = 1.5f;
	

	

	//NSTimer *playertimer = [[NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(updatePlayerPosition:) userInfo:nil repeats:YES] retain];
	//[[NSRunLoop currentRunLoop] addTimer:playertimer forMode:(NSString *)kCFRunLoopCommonModes];
	

	[NSApp setDelegate:self];
	
	
	[NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(updateQuickLink:) userInfo:nil repeats:YES];

}

-(void)setTermination:(NSTimer*)ti
{
	
	
}

-(IBAction)FocusOnPlayer:(id)sender
{
    NSLog(@"Focus on plaer");
	int i;
	for (i = 0; i < 16; i++)
	{
		if ([[new_characters objectAtIndex:i] isEqualToString:[sender title]])
		{
			
			float x = playercoords[(i * 8) + 0];
			float y = playercoords[(i * 8) + 1];
			float z = playercoords[(i * 8) + 2];
			
			if (x != 0)
			{
			
			//Focus ont he character
			[_camera PositionCamera:[_camera position][0] positionY:[_camera position][1] positionZ:[_camera position][2] 
							  viewX:x viewY:y viewZ:z
						  upVectorX:0.0f upVectorY:0.0f upVectorZ:1.0f];
			
			[self deselectAllObjects];
			
			//Select the player
			playercoords[(i * 8) + 4] = 1.0;
				
			}
			
			break;
		}
	}
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    
    NSLog(@"Application is terminating why");
    
		//Save main screen window
	if ([[[NSUserDefaults standardUserDefaults]objectForKey:@"automatic"] isEqualToString:@"NO"])
	{
	}
	else
	{
		
	

		NSRect main = [[self window] frame];
		
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults setObject:[NSString stringWithFormat:@"%f, %f, %f, %f", main.origin.x, main.origin.y, main.size.width, main.size.height] forKey:@"windowsize"];
		[userDefaults synchronize];
		
		
		float* pos = [self getCameraPos];
		float* view = [self getCameraView];
		
		[[NSString stringWithFormat:@"%@, %f, %f, %f, %f, %f, %f", [opened stringValue], pos[0],pos[1],pos[2], view[0],view[1],view[2]]  writeToFile:@"/tmp/starlight.auto" atomically:YES];
		
	}
}

- (void)reshape
{
    [self setFrame:[[[self window] contentView] bounds]];
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

- (BOOL)acceptsFirstResponder
{ 
	return YES; 
}

- (IBAction)openSEL:(id)sender
{
	//[select center];
	[select orderFront:nil];
}

- (IBAction)openCamera:(id)sender
{
	[self updateQuickLink:nil];
	
	//[camera center];
	[camera orderFront:nil];
}

- (IBAction)openRender:(id)sender
{
	//[render center];
	[render orderFront:nil];
	
}

- (IBAction)openSXpawn:(id)sender
{
	//[spawne center];
	[spawne orderFront:nil];
}

- (IBAction)openSpawn:(id)sender
{
	//[spawnc center];
	[spawnc orderFront:nil];
}

- (IBAction)openMach:(id)sender
{
	//[machine center];
	[machine orderFront:nil];
}

- (void)scrollWheel:(NSEvent*)theEvent
{
    
#ifdef MACVERSION
    if ([s_xRotation floatValue]+[theEvent scrollingDeltaY] < 0)
    {
        [s_xRotation setFloatValue:360+[s_xRotation floatValue]+[theEvent scrollingDeltaY]];
    }
    else if ([s_xRotation floatValue]+[theEvent scrollingDeltaY] > 360)
    {
        [s_xRotation setFloatValue:[s_xRotation floatValue]+[theEvent scrollingDeltaY]-360];
    }
    else
        [s_xRotation setFloatValue:[s_xRotation floatValue]+[theEvent scrollingDeltaY]];
#endif
    [self rotateFocusedItem:[s_xRotation floatValue] y:[s_yRotation floatValue] z:[s_zRotation floatValue]];
    
    //NSLog(@"test");
}

int wKey = 0;
int aKey = 0;
int sKey = 0;
int dKey = 0;
int cKey = 0;
int spaceKey = 0;

- (void)keyDown:(NSEvent *)theEvent
{
    NSString *characters = [theEvent characters];
    if ([characters length]<=0)
    {
        NSLog(@"No characters!");
    }
    
    int k = [theEvent keyCode];

	unichar character = [characters characterAtIndex:0];
	//NSLog(@"%x", character);
    //NSLog(@"DOWN: %d %x", k, character);
	if (character == NSDeleteCharacter || character == NSBackspaceCharacter)
	{
		//Delete the current shape.
		[self buttonPressed:b_deleteSelected];
		
	}
	else
    {
		
	

	switch (character)
	{
		case 'w':
			move_keys_down[0].direction = forward;
			move_keys_down[0].isDown = YES;
            
            wKey = k;
			break;
		case '1':
			[self buttonPressed:translateMode];
			break;
		case '2':
			[self buttonPressed:selectMode];
			break;
		case '3':
			[self buttonPressed:dirtMode];
			break;
		case '4':
			[self buttonPressed:grassMode];
            break;
        case '5':
			[self buttonPressed:eyedropperMode];
            break;
        case '6':
			[self buttonPressed:lightmapMode];
            break;
		case 's':
			move_keys_down[1].direction = back;
			move_keys_down[1].isDown = YES;
            
            sKey = k;
			break;
		case 'a':
			move_keys_down[2].direction = left;
			move_keys_down[2].isDown = YES;
            
            aKey = k;
			break;
		case 'd':
			move_keys_down[3].direction = right;
			move_keys_down[3].isDown = YES;
            
            dKey = k;
			break;
		case ' ':
			move_keys_down[4].direction = up;
			move_keys_down[4].isDown = YES;
            
            spaceKey = k;
			break;
		case 'c':
			move_keys_down[5].direction = down;
			move_keys_down[5].isDown = YES;
            
            cKey = k;
			break;
		case 0xF700: // Forward Key
			if (_mode == rotate_camera)
				[_camera MoveCamera:0.1];
			if (_mode == translate)
			{
				NSPoint fakeDownPoint = prevDown;
				fakeDownPoint.y += 1;
				[self performTranslation:fakeDownPoint zEdit:FALSE];
			}
			break;
		case 0xF701: // Back Key
			if (_mode == rotate_camera)
				[_camera MoveCamera:-0.1];
			if (_mode == translate)
			{
				NSPoint fakeDownPoint = prevDown;
				fakeDownPoint.y -= 1;
				[self performTranslation:fakeDownPoint zEdit:FALSE];
			}
			break;
		case 0xF702: // Left Key
			if (_mode == rotate_camera)
				[_camera StrafeCamera:-0.1];
			if (_mode == translate)
			{
				NSPoint fakeDownPoint = prevDown;
				fakeDownPoint.x -= 1;
				[self performTranslation:fakeDownPoint zEdit:FALSE];
			}
			break;
		case 0xF703: // Right Key
			if (_mode == rotate_camera)
				[_camera StrafeCamera:0.1f];
			if (_mode == translate)
			{
				NSPoint fakeDownPoint = prevDown;
				fakeDownPoint.x += 1;
				[self performTranslation:fakeDownPoint zEdit:FALSE];
			}
			break;
		case 0x2E: // ? key
			if (_mode == rotate_camera)
				[_camera LevitateCamera:0.1f];
			if (_mode == translate)
			{
				NSPoint fakeDownPoint = prevDown;
				fakeDownPoint.y += 1;
				[self performTranslation:fakeDownPoint zEdit:TRUE];
			}
			break;
		case 0x2C: // > key
			if (_mode == rotate_camera)
				[_camera LevitateCamera:-0.1f];
			if (_mode == translate)
			{
				NSPoint fakeDownPoint = prevDown;
				fakeDownPoint.y -= 1;
				[self performTranslation:fakeDownPoint zEdit:TRUE];
			}
			break;
		case 'l':
			NSLog(@"Camera z coord: %f", [_camera position][2]);
			break;
	}
		
	}
}

- (void)keyUp:(NSEvent *)event
{
#ifdef MACVERSION
	unichar character = [[event characters] characterAtIndex:0];
	switch (character)
	{
		case 'w':
			move_keys_down[0].isDown = NO;
			break;
		case 's':
			move_keys_down[1].isDown = NO;
			break;
		case 'a':
			move_keys_down[2].isDown = NO;
			break;
		case 'd':
			move_keys_down[3].isDown = NO;
			break;
		case ' ':
			move_keys_down[4].isDown = NO;
			break;
		case 'c':
			move_keys_down[5].isDown = NO;
			break;
	}
#else
    NSString *characters = [event characters];
    if ([characters length]<=0)
    {
        NSLog(@"No characters!");
    }
    
    int k = [event keyCode];
    //NSLog(@"UP %d %@", k, characters);
    
    

        if (k == wKey) //W
            move_keys_down[0].isDown = NO;
        else if (k == sKey) //S
            move_keys_down[1].isDown = NO;
        else if (k == aKey) //A
            move_keys_down[2].isDown = NO;
        else if (k == dKey) //D
            move_keys_down[3].isDown = NO;
        else if (k == spaceKey) //Space
            move_keys_down[4].isDown = NO;
        else if (k == cKey) //C
            move_keys_down[5].isDown = NO;
    
/*
        move_keys_down[0].isDown = NO;
        move_keys_down[1].isDown = NO;
        move_keys_down[2].isDown = NO;
        move_keys_down[3].isDown = NO;
        move_keys_down[4].isDown = NO;
        move_keys_down[5].isDown = NO;
*/
#endif
}
- (void)mouseUp:(NSEvent *)theEvent
{
    
}
- (void)mouseDown:(NSEvent *)event
{

    
    NSLog(@"Mouse down %d %d %d %d", (([event modifierFlags] & NSControlKeyMask)!=0), (([event modifierFlags] & NSCommandKeyMask)!=0), (([event modifierFlags] & NSShiftKeyMask)!=0), (([event modifierFlags] & NSAlternateKeyMask)!=0));
    
    duplicatedAlready = NO;
    
	
	
	NSPoint downPoint = [event locationInWindow];
	NSPoint local_point = [self convertPoint:downPoint fromView:[[self window] contentView]];
	prevDown = [NSEvent mouseLocation];
	
	if (_mode == select && _mapfile)
	{
		
	
			
            event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
            NSPoint graphicOrigin = [NSEvent mouseLocation];
                
            NSPoint en = graphicOrigin;
            
            
            CGFloat w = 0.0;
            CGFloat h = 0.0;
        
            if ([msel state])
            {
            while ([event type]!=NSLeftMouseUp)
            {
                
                event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
                NSPoint graphicOrigin = [NSEvent mouseLocation];

                
                if (en.x < graphicOrigin.x)
                {
                    w = graphicOrigin.x - en.x;
                    
                    if (en.y < graphicOrigin.y)
                    {
                        h = graphicOrigin.y - en.y;
                        
                        [selee setFrame:NSMakeRect(en.x, en.y, w, h) display:YES];
                    }
                    else
                    {
                        h =  en.y - graphicOrigin.y;
                        
                        [selee setFrame:NSMakeRect(en.x, graphicOrigin.y, w, h) display:YES];
                    }
                    
                }
                else
                {
                    
                    w = en.x - graphicOrigin.x;
                    
                    if (en.y < graphicOrigin.y)
                    {
                        h = graphicOrigin.y - en.y;
                        
                        [selee setFrame:NSMakeRect(graphicOrigin.x, en.y, w, h) display:YES];
                    }
                    else
                    {
                        
                        h =  en.y - graphicOrigin.y;
                        
                        [selee setFrame:NSMakeRect(graphicOrigin.x, graphicOrigin.y, w, h) display:YES];
                    }
                    
                }
                
                [selee orderFront:nil];
                
            }
            }
        
            int tx = [selee frame].origin.x;
            int ty = [selee frame].origin.y;
                
            int wx =   [[self window] frame].origin.x;
            int wy =  [[self window] frame].origin.y;

            tx -= wx;
            ty -= wy;
        
            if (w < 1.0f)
            {
                w = 1.0f;
                
                tx = local_point.x;
                ty = local_point.y;
            }
            
            if (h < 1.0f)
            {
                h = 1.0f;
                
                tx = local_point.x;
                ty = local_point.y;
            }
            
            
            NSPoint sp = NSMakePoint(tx, ty);
        
        NSLog(@"Trying selection %f %f %f %f", sp.x, sp.y, w, h);
            [self trySelection:sp shiftDown:(([event modifierFlags] & NSShiftKeyMask) != 0) width:[NSNumber numberWithFloat:w] height:[NSNumber numberWithFloat:h]];
        NSLog(@"Finished trying");
        
            [selee close];
			
		

		//[sel release];
	}
    
    
		
}


- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint dragPoint = [NSEvent mouseLocation];
	//if (_mode == rotate_camera)
	//	[_camera HandleMouseMove:(dragPoint.x - prevDown.x) dy:(dragPoint.y - prevDown.y)];
	if (_mode == translate)
	{
        if ([theEvent modifierFlags] & NSShiftKeyMask)
        {
            if (!duplicatedAlready)
            {
                
                //if (dup >= [duplicate_amount doubleValue])
                //{
                    unsigned int type, index, nameLookup;
                    
                    if (!selections || [selections count] == 0)
                        return;
                    
                    nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
                    type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
                    index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);

                //[selections removeAllObjects];
                
                long selection = [_scenario duplicateScenarioObject:type index:index];
                
                NSLog(@"%ld", selection);
                //[selections addObject:[NSNumber numberWithLong:selection]];
                //_selectFocus = [[selections objectAtIndex:0] longValue];
                
                
                //[self processSelection:selection];
                 
                    //[selections removeAllObjects];
                
                    //[selections addObject:[NSNumber numberWithLong:[_scenario duplicateScenarioObject:type index:index]]];
                    //_selectFocus = [[selections objectAtIndex:0] longValue];
                
                    //dup=0;
                //}
                //else
                //{
                    //dup++;
                //}
                
                duplicatedAlready = YES;

            }
        }
        
        //[self performTranslation:dragPoint zEdit:(([theEvent modifierFlags] & NSControlKeyMask) != 0)];
        
#ifdef MACVERSION
		[self performTranslation:dragPoint zEdit:(([theEvent modifierFlags] & NSControlKeyMask) != 0)];
#else
        [self performTranslation:dragPoint zEdit:(([theEvent modifierFlags] & NSCommandKeyMask) != 0)];
#endif
        
        // Now lets apply the transformations.
        unsigned int	i,
        nameLookup,
        type,
        index;
        for (i = 0; i < [selections count]; i++)
        {
            nameLookup = [[selections objectAtIndex:i] unsignedIntValue];
            type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
            index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
            
            switch (type)
            {
                case s_scenery:
                    [self setPositionSliders:[NSNumber numberWithFloat:[_scenario scen_spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario scen_spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario scen_spawns][index].coord[2]]];
                    break;
                case s_vehicle:
                    [self setPositionSliders:[NSNumber numberWithFloat:[_scenario vehi_spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario vehi_spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario vehi_spawns][index].coord[2]]];
                    break;
                case s_playerspawn:
                {
                    /*float *gg = (float*)[self coordtoGround:(float*)[_scenario spawns][index].coord];
                    if (gg[0] != 0.0)
                    {
                        [_scenario spawns][index].coord[0] = gg[0];
                        [_scenario spawns][index].coord[1] = gg[1];
                        [_scenario spawns][index].coord[2] = gg[2];
                    }*/
                    
                    [self setPositionSliders:[NSNumber numberWithFloat:[_scenario spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario spawns][index].coord[2]]];
                    break;
                }
                case s_netgame:
                    [self setPositionSliders:[NSNumber numberWithFloat:[_scenario netgame_flags][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario netgame_flags][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario netgame_flags][index].coord[2]]];
                    break;
                case s_item:
                    [self setPositionSliders:[NSNumber numberWithFloat:[_scenario item_spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario item_spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario item_spawns][index].coord[2]]];
                    break;
                case s_machine:
                    [self setPositionSliders:[NSNumber numberWithFloat:[_scenario mach_spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario mach_spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario mach_spawns][index].coord[2]]];
                    break;
            }
        }
        
        
	}
	else if (_mode == rotate)
	{
        #ifdef MACVERSION
		[self performRotation:dragPoint zEdit:(([theEvent modifierFlags] & NSControlKeyMask) != 0)];
#else
        [self performRotation:dragPoint zEdit:(([theEvent modifierFlags] & NSCommandKeyMask) != 0)];

#endif
	}
    else
    {
        bool PAINT = TRUE;
        
        if ([dirtMode state]||[grassMode state]||[lightmapMode state]||[eyedropperMode state])
        {
            
            NSPoint downPoint = [theEvent locationInWindow];
            NSPoint local_point = [self convertPoint:downPoint fromView:[[self window] contentView]];
            
            NSPoint sp = NSMakePoint(local_point.x, local_point.y);
            
            
            //Are we interescting the bsp anywhere?
            int selection = [self tryBSPSelection:sp shiftDown:NO width:1 height:1];
            
          
            if (selection != -1)
            {
                //Find the image files associated with this
                SUBMESH_INFO *pMesha;
                pMesha = [mapBSP GetActiveBspPCSubmesh:selection];
                
                if (!pMesha)
                    return;
                if (pMesha->DefaultLightmapIndex == -1)
                    return;
                if (pMesha->LightmapIndex == -1)
                    return;
                if (pMesha->DefaultBitmapIndex == -1)
                    return;
                
                
                
               // NSLog(@"%d %d %d %d", selection, pMesha->DefaultLightmapIndex, pMesha->LightmapIndex, pMesha->DefaultBitmapIndex );

                
                //Texture ident
                //NSString *name = [_texManager nameForImage:pMesha->baseMap];
                //NSString *file = [NSString stringWithFormat:@"%@/Desktop/Images/%@_original.tiff", NSHomeDirectory(), name];
                //NSString *alphaim = [NSString stringWithFormat:@"%@/Desktop/Images/%@_alpha.tiff", NSHomeDirectory(), name];
    
                //Where is this texture MAPPED to this image? Like, where does the triangle map to? We need to find the UV coordinates for each vertex.
                //pindex = selectedPIndex;
              
                float *vertex1 =  pMesha->pVert[pMesha->pIndex[selectedPIndex].tri_ind[0]].uv;
                float *vertex2 =  pMesha->pVert[pMesha->pIndex[selectedPIndex].tri_ind[1]].uv;
                float *vertex3 =  pMesha->pVert[pMesha->pIndex[selectedPIndex].tri_ind[2]].uv;
                
                
                float *lmvertex1 =  pMesha->pLightmapVert[pMesha->pIndex[selectedPIndex].tri_ind[0]].uv;
                float *lmvertex2 =  pMesha->pLightmapVert[pMesha->pIndex[selectedPIndex].tri_ind[1]].uv;
                float *lmvertex3 =  pMesha->pLightmapVert[pMesha->pIndex[selectedPIndex].tri_ind[2]].uv;
                
                
                float x = uva1*vertex1[0] + uva2*vertex2[0] + uva3*vertex3[0];
                float y = uva1*vertex1[1] + uva2*vertex2[1] + uva3*vertex3[1];
               
                int index = 0;
                BitmapTag *tmpBitm;
                
                if ([lightmapMode state])
                {
                    index = pMesha->LightmapIndex;
                    
                    tmpBitm = [_texManager bitmapWithIdent:pMesha->DefaultLightmapIndex];
                    
                     x = uva1*lmvertex1[0] + uva2*lmvertex2[0] + uva3*lmvertex3[0];
                     y = uva1*lmvertex1[1] + uva2*lmvertex2[1] + uva3*lmvertex3[1];
                    
                }
                else
                    tmpBitm = [_texManager bitmapWithIdent:pMesha->baseMap];
                
                //Create an image from the bitmap
                
                unsigned char *pixels = [tmpBitm imagePixelsForImageIndex:index];
                
                
                NSSize size = NSMakeSize([tmpBitm textureSizeForImageIndex:index].width, [tmpBitm textureSizeForImageIndex:index].height);
                
                unsigned char *pixels_alpha = malloc(size.width * size.height * 4);
                
                
                
                NSBitmapImageRep *imgRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&pixels
                                                                                   pixelsWide:size.width
                                                                                   pixelsHigh:size.height
                                                                                bitsPerSample:8
                                                                              samplesPerPixel:4
                                                                                     hasAlpha:true
                                                                                     isPlanar:false
                                                                               colorSpaceName:NSDeviceRGBColorSpace
                                            
                                                                                  bytesPerRow:0
                                                                                 bitsPerPixel:0];
                NSBitmapImageRep *imgRepalpha;
                unsigned char *data;
                int as, j = 0;
                
                if (![lightmapMode state])
                {
                    data = [imgRep bitmapData];
                    
                    for (as = 0; as < size.width * size.height * 4; as += 4)
                    {
                        unsigned char r, g, b, a;
                        r = *(pixels + as+0);
                        g = *(pixels + as+1);
                        b = *(pixels + as+2);
                        a = *(pixels + as+3);
                        
                        *(pixels_alpha + as + 0) = a;
                        *(pixels_alpha + as + 1) = a;
                        *(pixels_alpha + as + 2) = a;
                        *(pixels_alpha + as + 3) = a;
                    }
                   
                    //Need to convert this data
                    imgRepalpha = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&pixels_alpha
                                                                                       pixelsWide:size.width
                                                                                       pixelsHigh:size.height
                                                                                    bitsPerSample:8
                                                                                  samplesPerPixel:4
                                                                                         hasAlpha:true
                                                                                         isPlanar:false
                                                                                   colorSpaceName:NSDeviceRGBColorSpace
                                                
                                                                                      bytesPerRow:0
                                                                                     bitsPerPixel:0];
                    
                    
                }
          
                
                float xa = size.width*x;
                float ya =  size.height- size.height*y;
                
                if ([eyedropperMode state])
                {
                    int xap = size.width*x;
                    int yap =  size.height- size.height*y;
                    
                    int as = (size.height-yap-1)*(size.width)*4 + xap*4;
                    
                    unsigned char r, g, b, a;
                    r = *(pixels + as+0);
                    g = *(pixels + as+1);
                    b = *(pixels + as+2);
                    a = *(pixels + as+3);
                    
                    //NSLog(@"%d %d %d %d", r, g, b, a);
                    [paintColor setColor:[NSColor colorWithCalibratedRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]];
                    
                    /*
                    *(data + as + 0) = 0;
                    *(data + as + 1) = 0;
                    *(data + as + 2) = 0;
                    *(data + as + 3) = 255;
                    [_texManager updateBitmapDataWithIdent:pMesha->baseMap data:[imgRep bitmapData] index:index];
                    */
                }
                else
                {
                    float brush_size = [paintSize floatValue];
                    
                    NSRect rect = NSMakeRect(xa-brush_size/2.0, ya-brush_size/2.0, brush_size, brush_size);
                    NSBezierPath* circlePath = [NSBezierPath bezierPath];
                    [circlePath appendBezierPathWithOvalInRect: rect];
                    
                    [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
                    //Need to do this twice unfortunately.
                    [NSGraphicsContext saveGraphicsState];
                    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:imgRep]];
                    [[paintColor color] set];
                    [circlePath fill];
                    [NSGraphicsContext restoreGraphicsState];
                    
                    if (![lightmapMode state])
                    {
                        
                        //Dont need this save?
                        [NSGraphicsContext saveGraphicsState];
                        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:imgRepalpha]];
                        
                        if ([grassMode state])
                            [[NSColor colorWithCalibratedHue:0.0 saturation:0.0 brightness:0.0 alpha:[[paintColor color] alphaComponent]] set];
                        else
                            [[NSColor colorWithCalibratedHue:1.0 saturation:1.0 brightness:1.0 alpha:[[paintColor color] alphaComponent]] set];
                        
                        [circlePath fill];
                        
                        data = [imgRep bitmapData];
                        unsigned char *alpha = [imgRepalpha bitmapData];
                        
                        [NSGraphicsContext restoreGraphicsState];

                        for (as = 0; as < size.width * size.height * 4; as += 4)
                        {
                            unsigned char r, g, b, a;
                            r = *(data + as+0);
                            g = *(data + as+1);
                            b = *(data + as+2);
                            a = *(alpha + as+0);
                            
                            *(data + as + 0) = r;
                            *(data + as + 1) = g;
                            *(data + as + 2) = b;
                            *(data + as + 3) = a;
                        }
                    }
                    
                    //Update the bitmap data
                    if (![lightmapMode state])
                    {
                        [_texManager updateBitmapDataWithIdent:pMesha->baseMap data:[imgRep bitmapData] index:index];
                    }
                    else
                        [_texManager updateBitmapDataWithIdent:pMesha->LightmapIndex data:[imgRep bitmapData] index:index];
                    
                    [imgRep release];
                    
                    if (![lightmapMode state])
                    {
                        [imgRepalpha release];
                    }
                    
                    free(pixels_alpha);
                }

                /*
                //Erase image :P
                NSImage *renderImage = [[NSImage alloc] initWithContentsOfFile:alphaim];
                NSImage *colorImage = [[NSImage alloc] initWithContentsOfFile:file];

                
                
                float brush_size = [paintSize floatValue];
                
                NSRect rect = NSMakeRect(xa-brush_size/2.0, ya-brush_size/2.0, brush_size, brush_size);
                NSBezierPath* circlePath = [NSBezierPath bezierPath];
                [circlePath appendBezierPathWithOvalInRect: rect];
                
                [renderImage lockFocus];
                
                if ([grassMode state])
                    [[NSColor blackColor] set];
                else
                    [[NSColor whiteColor] set];
                
                [circlePath fill];
                [renderImage unlockFocus];
                
                
                [colorImage lockFocus];
                [[paintColor color] set];
                

                
                [circlePath fill];
                [colorImage unlockFocus];
                
                
                //NSBitmapImageRep *alpha = [NSBitmapImageRep imageRepWithContentsOfFile:alphaim];
                //unsigned char *from = [alpha bitmapData];
                
                */
                
                
                /*
                NSLog(@"%d %d %f %f", xa, ya, x,y );
                NSImage *renderImage = [[NSImage alloc] initWithSize:NSMakeSize(alpha.pixelsWide, alpha.pixelsHigh)];
                
                //Paint in a circle around it
                int brushSize = 1;
                
                int as, j = 0;
                for (as = 0; as < alpha.pixelsWide * alpha.pixelsHigh * 4; as += 4)
                {
                    unsigned char r, g, b, a;
                    r = *(from + as+0);
                    g = *(from + as+1);
                    b = *(from + as+2);
                    a = *(from + as+3);
                    
                    
                    
                    if (as == ya*(alpha.pixelsWide)*4 + xa*4)
                    {
                        *(from + as + 0) = 0;
                        *(from + as + 1) = 0;
                        *(from + as + 2) = 0;
                        *(from + as + 3) = 255;
                    }
                    else
                    {
                        *(from + as + 0) = r;
                        *(from + as + 1) = g;
                        *(from + as + 2) = b;
                        *(from + as + 3) = a;
                    }
                    
                    
                    j += 4;
                }
                [renderImage addRepresentation:alpha];
                */
                //Update the texture. horrible method this is. would be shit on non SSD's
                
                
                /*
                [[NSFileManager defaultManager] removeItemAtPath:alphaim error:nil];
                [[renderImage TIFFRepresentation] writeToFile:alphaim atomically:NO];
                
                [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
                [[colorImage TIFFRepresentation] writeToFile:file atomically:NO];
                
                
                [renderImage release];
                [colorImage release];*/
                //[NSThread sleepForTimeInterval:0.1];
            }
        }
    }
    
#ifdef MACVERSION
	if ((([theEvent modifierFlags] & NSControlKeyMask) != 0) && _mode != translate)
		[_camera HandleMouseMove:(dragPoint.x - prevDown.x) dy:(dragPoint.y - prevDown.y)];
#else
    if ((([theEvent modifierFlags] & NSCommandKeyMask) != 0) && _mode != translate)
		[_camera HandleMouseMove:(dragPoint.x - prevDown.x) dy:(dragPoint.y - prevDown.y)];
#endif
	prevDown = dragPoint;
}




- (void)mouseMoved:(NSEvent *)theEvent
{
    
    /*
    if ([first_person_mode state])
    {
        NSPoint dragPoint = [NSEvent mouseLocation];
        
        [_camera HandleMouseMove:(dragPoint.x - prevDown.x) dy:(dragPoint.y - prevDown.y)];
        
        prevDown = dragPoint;
    }
    */
	//NSPoint pt = [theEvent locationInWindow];
    
}
- (void)rightMouseDown:(NSEvent *)event
{
	NSPoint downPoint = [event locationInWindow];
	prevDown = [NSEvent mouseLocation];
}
- (void)rightMouseUp:(NSEvent *)theEvent
{
    
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	NSPoint dragPoint = [NSEvent mouseLocation];
	
	[_camera HandleMouseMove:(dragPoint.x - prevDown.x) dy:(dragPoint.y - prevDown.y)];
	
	prevDown = dragPoint;
}
- (void)timerTick:(NSTimer *)timer
{
    
    
    uint64_t current = mach_absolute_time();
    
    // In here we handle a few things, mmk?
	acceleration = 0;//(int)[cspeed doubleValue] * (current - previous) / 1000000000.0;
    
    
    USEDEBUG NSLog(@"TICK");
    
    float value = 10000000.0;
    
#ifndef MACVERSION
    value = 100000.0;
#endif
    
	float adjustment = ((current - previous) / value);
    
    if (adjustment > 5000)
        adjustment = 0.0;
	//NSLog(@"%f", adjustment);
	int x;
	BOOL key_is_down = NO;
	
	for (x = 0; x < 6; x++)
	{
		if (move_keys_down[x].isDown)
		{
			key_is_down = YES;
			switch (move_keys_down[x].direction)
			{
				case forward:
					[_camera MoveCamera:([cspeed doubleValue] * adjustment)];
					break;
				case back:
					[_camera MoveCamera:(-1 * ([cspeed doubleValue] * adjustment))];
					break;
				case left:
					[_camera StrafeCamera:(-1.0 * ([cspeed doubleValue] * adjustment))];
					break;
				case right:
					[_camera StrafeCamera:([cspeed doubleValue] * adjustment)];
					break;
				case down:
					[_camera LevitateCamera:(-1 * ([cspeed doubleValue] * adjustment))]; 
					break;
				case up:
                {
                    unsigned int	i,
                    nameLookup,
                    type,
                    index;
                    
                    for (i = 0; i < [selections count]; i++)
                    {
                        nameLookup = [[selections objectAtIndex:i] unsignedIntValue];
                        type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
                        index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
                        
                        
                        
                        switch (type)
                        {
                            case s_vehicle:
                            {
                                float *gg = (float*)[self coordtoGround:(float*)[_scenario vehi_spawns][index].coord];
                                if (gg[0] != 0.0)
                                {
                                    [_scenario vehi_spawns][index].coord[0] = gg[0];
                                    [_scenario vehi_spawns][index].coord[1] = gg[1];
                                    [_scenario vehi_spawns][index].coord[2] = gg[2]+0.01;
                                }
                                free(gg);
                                break;
                            }
                            case s_scenery:
                            {
                                float *gg = (float*)[self coordtoGround:(float*)[_scenario scen_spawns][index].coord];
                                if (gg[0] != 0.0)
                                {
                                    [_scenario scen_spawns][index].coord[0] = gg[0];
                                    [_scenario scen_spawns][index].coord[1] = gg[1];
                                    [_scenario scen_spawns][index].coord[2] = gg[2]+0.01;
                                }
                                free(gg);
                                break;
                            }
                            case s_playerspawn:
                            {
                                float *gg = (float*)[self coordtoGround:(float*)[_scenario spawns][index].coord];
                                if (gg[0] != 0.0)
                                {
                                    [_scenario spawns][index].coord[0] = gg[0];
                                    [_scenario spawns][index].coord[1] = gg[1];
                                    [_scenario spawns][index].coord[2] = gg[2]+0.01;
                                }
                                free(gg);
                                break;
                            }
                            case s_netgame:
                            {
                                float *gg = (float*)[self coordtoGround:(float*)[_scenario netgame_flags][index].coord];
                                if (gg[0] != 0.0)
                                {
                                    [_scenario netgame_flags][index].coord[0] = gg[0];
                                    [_scenario netgame_flags][index].coord[1] = gg[1];
                                    [_scenario netgame_flags][index].coord[2] = gg[2]+0.01;
                                }
                                free(gg);
                                break;
                            }
                            case s_item:
                            {
                                float *gg = (float*)[self coordtoGround:(float*)[_scenario item_spawns][index].coord];
                                if (gg[0] != 0.0)
                                {
                                    [_scenario item_spawns][index].coord[0] = gg[0];
                                    [_scenario item_spawns][index].coord[1] = gg[1];
                                    [_scenario item_spawns][index].coord[2] = gg[2]+0.01;
                                }
                                free(gg);
                                break;
                            }
                            case s_machine:
                            {
                                float *gg = (float*)[self coordtoGround:(float*)[_scenario mach_spawns][index].coord];
                                if (gg[0] != 0.0)
                                {
                                    [_scenario mach_spawns][index].coord[0] = gg[0];
                                    [_scenario mach_spawns][index].coord[1] = gg[1];
                                    [_scenario mach_spawns][index].coord[2] = gg[2]+0.01;
                                }
                                free(gg);
                                break;
                            }
                        }
                    }
                    
                    //Drop the current selection to the ground
					//[_camera LevitateCamera:([cspeed doubleValue] * adjustment)];
					break;
                }
			}
		}
	}
   USEDEBUG  NSLog(@"TICK2");
    previous = current;
    
    if ([first_person_mode state])
    {
        [cspeed setDoubleValue:0.04];
        _camera.position[2]=_camera.position[2]-0.65;
        float *gg = (float*)[self coordtoGround:(float*)_camera.position];
        if (gg[0] != 0.0)
        {
            _camera.position[0] = gg[0];
            _camera.position[1] = gg[1];
            _camera.position[2] = gg[2]+0.65;
        }
        free(gg);
    }
  USEDEBUG NSLog(@"TICK3");
	if (key_is_down)
	{
		
		
		
		/*
		if (accelerationCounter > 10 && accelerationCounter < 15)
			acceleration += 0.1;
		if (accelerationCounter > 15 && accelerationCounter < 20)
			acceleration += 0.2;
		if (accelerationCounter > 20 && accelerationCounter < 25 && _fps < 40)
			acceleration += 0.2;
		if (accelerationCounter > 25 && acceleration < 30 && _fps < 30)
			acceleration += 0.2;
		
		accelerationCounter += 1;
		 */
		 
	}
	else
	{
		acceleration = 0;
		accelerationCounter = 0;
	}
	USEDEBUG NSLog(@"TICK4");
	if (shouldDraw)
	{
		[self performSelectorOnMainThread:@selector(reshape) withObject:nil waitUntilDone:YES];
        USEDEBUG NSLog(@"TICK4.5");
		[self setNeedsDisplay:YES];
       USEDEBUG  NSLog(@"TICK5");
	}
    else
    {
        
    }
}
/*
	Override the view's drawRect: to draw our GL content.
*/	 

-(IBAction)DropCamera:(id)sender
{
	unsigned int	i,
	nameLookup,
	type,
	index;
	
	i = 0;
	
	nameLookup = [[selections objectAtIndex:i] unsignedIntValue];
	type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
	index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
		
		
		
	switch (type)
	{
		case s_vehicle:
			
			[self centerObj3:[_scenario vehi_spawns][index].coord move:[_scenario vehi_spawns][index].rotation];
			break;
		case s_scenery:
			[self centerObj3:[_scenario scen_spawns][index].coord move:[_scenario scen_spawns][index].rotation];
			break;
		case s_playerspawn:
			[self centerObj3:[_scenario spawns][index].coord move:nil];
			break;
		case s_netgame:
			[self centerObj3:[_scenario netgame_flags][index].coord move:nil];
			break;
		case s_item:
			[self centerObj3:[_scenario item_spawns][index].coord move:nil];
			break;
		case s_machine:
			[self centerObj3:[_scenario mach_spawns][index].coord move:[_scenario mach_spawns][index].rotation];
			break;
	}
	
}

-(int)usesColor
{
	return 4;
}


-(void)drawView
{
    //Moving
    if (![[self window] isKeyWindow])
    {
        move_keys_down[0].isDown = NO;
        move_keys_down[1].isDown = NO;
        move_keys_down[2].isDown = NO;
        move_keys_down[3].isDown = NO;
        move_keys_down[4].isDown = NO;
        move_keys_down[5].isDown = NO;
    }
    
    if (![NSApp isActive])
    {
        
        return;
    }
    

    glLoadIdentity();
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glClearColor(100/100.0,90/100.0,76/100.0,1.0);          // We'll Clear To The Color Of The Fog ( Modified )
    
	[_camera Look];
	[_camera Update];

	//NSLog(@"%f %f %f", [_camera position][0], [_camera position][1], [_camera position][2]);
	//[self drawAxes];
	
    //shouldDraw = FALSE;
	if (shouldDraw)
	{
        if (useNewRenderer() >= 2)
        {

             
            GLfloat fogColor[4];     // Fog Color
            fogColor[0] = 1.0f;
            fogColor[1] = 1.0f;
            fogColor[2] = 1.0f;
            fogColor[3] = 1.0f;
            
            if (useNewRenderer() == 3)
            {

                fogColor[0] = 0.5f;
                 fogColor[1] = 0.5f;
                 fogColor[2] = 0.5f;
  
            }// Fog Color
            
            
            
            glFogi(GL_FOG_MODE, GL_LINEAR);        // Fog Mode
            glFogfv(GL_FOG_COLOR, fogColor);            // Set Fog Color
            glFogf(GL_FOG_DENSITY, 0.5f);              // How Dense Will The Fog Be
            glHint(GL_FOG_HINT, GL_NICEST);          // Fog Hint Value
            glFogf(GL_FOG_START, 0.3f);             // Fog Start Depth
            glFogf(GL_FOG_END, 200.0f);               // Fog End Depth
                           // Enables GL_FOG
            
        }
        if (useNewRenderer() >= 2)
        {
            glEnable(GL_FOG);
            glEnable(GL_MULTISAMPLE);
            glHint(GL_MULTISAMPLE_FILTER_HINT_NV, GL_NICEST);
            
        }
        else
        {
            glDisable(GL_FOG);
            
            if (useNewRenderer() >= 1)
            {
   
                glEnable(GL_MULTISAMPLE);
                glHint(GL_MULTISAMPLE_FILTER_HINT_NV, GL_NICEST);
                
            }
            
        }
        
        
        /*
        if (lightScene)
        {
        
            glPushMatrix();
            glTranslatef(lightPos[0], lightPos[1], lightPos[2]);
            glColor3f(1.0, 1.0, 0.0);
                
            GLUquadric *sphere=gluNewQuadric();
            gluQuadricDrawStyle( sphere, GLU_FILL);
            gluQuadricNormals( sphere, GLU_SMOOTH);
            gluQuadricOrientation( sphere, GLU_OUTSIDE);
            gluQuadricTexture( sphere, GL_TRUE);
            
            gluSphere(sphere,0.5,10,10);
            gluDeleteQuadric ( sphere );
            glPopMatrix();
        
        
        
        }
        */
        
        if (true)
        {
            glDisable(GL_DEPTH_TEST);
            if (TRUE)//useNewRenderer())
            {
                glEnableClientState(GL_VERTEX_ARRAY);
                glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                
                glEnable(GL_TEXTURE_2D);
                glEnable(GL_BLEND);
            }
            if (useNewRenderer() >= 2)
                glDisable(GL_FOG);
            
            SkyBox *skies;
            skies = [_scenario sky];

            
            USEDEBUG NSLog(@"MP8");
            int x; float pos[6];
            for (x = 0; x < [_scenario skybox_count]; x++)
            {
                // Lookup goes hur
                
                if ([_mapfile isTag:skies[x].modelIdent])
                {
                    
                    pos[0]=0;
                    pos[1]=0;
                    pos[2]=0;//-10000;
                    pos[3]=0;
                    pos[4]=0;
                    pos[5]=0;
                    
                    [[_mapfile tagForId:skies[x].modelIdent] drawAtPoint:pos lod:_LOD isSelected:NO useAlphas:NO distance:0];
                }
            }
            USEDEBUG NSLog(@"MP9");
            if (useNewRenderer() >= 2)
                glEnable(GL_FOG);
            USEDEBUG NSLog(@"MP10");
            if (TRUE)//useNewRenderer())
            {
                glDisableClientState(GL_VERTEX_ARRAY);
                glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                
                glDisable(GL_TEXTURE_2D);
                glDisable(GL_BLEND);
            }
            glEnable(GL_DEPTH_TEST);
        }
        
		if (mapBSP)
		{
			[self renderVisibleBSP:FALSE];
		}

		if (_scenario)
		{
			[self renderAllMapObjects];
		}

       
        
	}
    else
    {
    }

	[[self openGLContext] flushBuffer];

}


- (void)drawRect:(NSRect)rect
{
    [self drawView];
    //[NSThread sleepForTimeInterval:0.01];
}
- (void)loadPrefs
{
	NSLog(@"Loading preferences!");
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	_useAlphas = [userDefaults boolForKey:@"_useAlphas"];
	[useAlphaCheckbox setState:_useAlphas];
	
	NSString *size = [userDefaults stringForKey:@"windowsize"];
	
	if (size)
	{
		
	NSArray *objs = [size componentsSeparatedByString:@","];
	[[self window] setFrame:NSMakeRect([[objs objectAtIndex:0] floatValue], [[objs objectAtIndex:1] floatValue], [[objs objectAtIndex:2] floatValue], [[objs objectAtIndex:3] floatValue]) display:YES];
	
	}
	
	[lodDropdownButton setDoubleValue:[userDefaults integerForKey:@"_LOD"]];
	switch ((int)[lodDropdownButton doubleValue])
	{
		case 0:
			_LOD = 0;
			break;
		case 1:
			_LOD = 2;
			break;
		case 2:
			_LOD = 4;
			break;
	}
}
- (void)releaseMapObjects
{
	shouldDraw = NO;
	[[self openGLContext] flushBuffer];
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	[self initGL];
	[_texManager release];
	[_mapfile release];
	[_scenario release];
	[mapBSP release];
	
	[self deselectAllObjects];
}
- (void)setMapObject:(HaloMap *)mapfile
{
	int i;
	float x,y,z;
	
	_mapfile = [mapfile retain];
	_scenario = [[mapfile scenario] retain];
	mapBSP = [[mapfile bsp] retain];
	_texManager = [[mapfile _texManager] retain];
	if (_mapfile && _scenario && mapBSP)
		shouldDraw = YES;
	[bspNumbersButton removeAllItems];
	for (i = 0; i < [mapBSP NumberOfBsps]; i++)
		[bspNumbersButton addItemWithTitle:[[NSNumber numberWithInt:i+1] stringValue]];
	[mapBSP GetActiveBspCentroid:&x center_y:&y center_z:&z];
	
    [self recenterCamera:self];
    
	if ([[[NSUserDefaults standardUserDefaults]objectForKey:@"automatic"] isEqualToString:@"NO"])
	{
		[self recenterCamera:self];
	}
	else
	{
		
	

	NSString *autoa = [NSString stringWithContentsOfFile:@"/tmp/starlight.auto"];
	
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/starlight.auto"])
	{
		NSLog(@"Loading map file");
		NSArray *settings = [autoa componentsSeparatedByString:@","];
		NSString *pat = [settings objectAtIndex:0];
		if ([[NSFileManager defaultManager] fileExistsAtPath:pat])
		{
			
			[_camera PositionCamera:[[settings objectAtIndex:1] floatValue] positionY:[[settings objectAtIndex:2] floatValue] positionZ:[[settings objectAtIndex:3] floatValue] viewX:[[settings objectAtIndex:4] floatValue] viewY:[[settings objectAtIndex:5] floatValue] viewZ:[[settings objectAtIndex:6] floatValue] upVectorX:0.0f upVectorY:0.0f upVectorZ:1.0f];
			[@"" writeToFile:@"/tmp/starlight.auto" atomically:YES];
			
		}
		
	}
	else
	{
		[self recenterCamera:self];
	}
		}
	activeBSPNumber = 0;
	
	SUBMESH_INFO *pMeshaa;
	
	
	unsigned int mesh_count;
	int m;

	mesh_count = [mapBSP GetActiveBspSubmeshCount];
	
	
	int point = 0;
	for (m = 0; m < mesh_count; m++)
	{
		pMeshaa = [mapBSP GetActiveBspPCSubmesh:m];
		point+=pMeshaa->VertCount;
	}
	
	bsp_point_count=point;
	
	///Create the bsp points
	bsp_points = malloc(bsp_point_count * sizeof(bsp_point));
	
	
	
	int b = 0;
	for (m = 0; m < mesh_count; m++)
	{
				
		pMeshaa = [mapBSP GetActiveBspPCSubmesh:m];
		for (i = 0; i < pMeshaa->VertCount; i++)
		{
			
			float *coord = (float *)(pMeshaa->pVert[i].vertex_k);
			bsp_points[b].coord[0]= coord[0];
			bsp_points[b].coord[1]= coord[1];
			bsp_points[b].coord[2]= coord[2];
			bsp_points[b].mesh=m;
			bsp_points[b].index = 0;
			bsp_points[b].amindex = i;
            bsp_points[b].isSelected = NO;

			b+=1;
		}
	}
	
	//Look, we have all of the collision data
	editable = 1;
	
}
- (void)lookAt:(float)x y:(float)y z:(float)z
{
	//[_camera PositionCamera:[_camera position][0] positionY:[_camera position][1] positionZ:[_camera position][2] 
				//viewX:x viewY:y viewZ:z 
				//upVectorX:0.0f upVectorY:0.0f upVectorZ:1.0f];
}
- (void)stopDrawing
{
	//int i;
	shouldDraw = NO;
	[[self openGLContext] flushBuffer];
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
}
- (void)resetTimerWithClassVariable
{
	[drawTimer invalidate];
	[drawTimer release];
	drawTimer = [[NSTimer timerWithTimeInterval:(1.0/_fps)
						target:self
						selector:@selector(timerTick:)
						userInfo:nil
						repeats:YES]
						retain];
	
	[[NSRunLoop currentRunLoop] addTimer:drawTimer forMode:(NSString *)kCFRunLoopCommonModes];
	shouldDraw = YES;
}
/* 
*
*		End RenderView Functions 
*
*/

/* 
*
*		Begin BSP Rendering 
*
*/
- (void)renderVisibleBSP:(BOOL)selectMode
{
	unsigned int mesh_count;
	int i;
	int m;
	
    
	if (shouldDraw)
	{
		mesh_count = [mapBSP GetActiveBspSubmeshCount];
		
		[self resetMeshColors];
		
		NSString *points = @"";
		
		for (i = 0; i < mesh_count; i++)
		{
            
            
			
			/*SUBMESH_INFO *pMesh;
			pMesh = [mapBSP GetActiveBspPCSubmesh:i];
	
			for (m = 0; m < pMesh->IndexCount; m++)
			{
				points = [points stringByAppendingString:[NSString stringWithFormat:@"%f,%f,%f,", (float)(pMesh->pVert[pMesh->pIndex[m].tri_ind[0]].vertex_k[0]), (float)(pMesh->pVert[pMesh->pIndex[m].tri_ind[0]].vertex_k[1]), (float)(pMesh->pVert[pMesh->pIndex[m].tri_ind[0]].vertex_k[2])]];
				points = [points stringByAppendingString:[NSString stringWithFormat:@"%f,%f,%f,", (float)(pMesh->pVert[pMesh->pIndex[m].tri_ind[1]].vertex_k[0]), (float)(pMesh->pVert[pMesh->pIndex[m].tri_ind[1]].vertex_k[1]), (float)(pMesh->pVert[pMesh->pIndex[m].tri_ind[1]].vertex_k[2])]];
				points = [points stringByAppendingString:[NSString stringWithFormat:@"%f,%f,%f,", (float)(pMesh->pVert[pMesh->pIndex[m].tri_ind[2]].vertex_k[0]), (float)(pMesh->pVert[pMesh->pIndex[m].tri_ind[2]].vertex_k[1]), (float)(pMesh->pVert[pMesh->pIndex[m].tri_ind[2]].vertex_k[2])]];
			}*/
			//[points writeToFile:@"/tmp/BSPPoint.txt" atomically:YES];
			//NSRunAlertPanel(@"DUN", @"", @"", @"", @"");
			//sleep(2000)
			
			if ((currentRenderStyle == point) || (currentRenderStyle == wireframe) || (currentRenderStyle == flat_shading))
				[self setNextMeshColor];
			
            currentRenderStyle = textured_tris;
			switch (currentRenderStyle)
			{
				case point:
					[self renderBSPAsPoints:i];
					break;
				case wireframe:
					glLineWidth(1.0f);
					[self renderBSPAsWireframe:i];
					break;
				case flat_shading:
					[self renderBSPAsFlatShadedPolygon:i];
					break;
				case textured_tris:
                    glColor3f(1.0, 1.0, 1.0);
					[self renderBSPAsTexturedAndLightmaps:i];
                    //[self renderHighlighted:indexMesh];
                    //glLineWidth(1.0f);
					//[self renderBSPAsWireframe:i];
					//[self renderBSPAsPoints:i];
					glLineWidth(2.0f);
					glColor3f(1.0, 1.0, 1.0);
					break;
			}
			 
		}
		
		
	}
}
- (void)renderBSPAsPoints:(int)mesh_index
{
	SUBMESH_INFO *pMesh;
	int i;
	
	pMesh = [mapBSP GetActiveBspPCSubmesh:mesh_index];
	
	glPointSize(15.0);
	glBegin(GL_POINTS);
	glPointSize(15.0);
	
	BspMesh *mesh = [mapBSP mesh];
	
	for (i = 0; i < [mesh coll_count]; i++)
	{
		vert *v = [mesh collision_verticies];
		
		float *coord = malloc(12);
		coord[0]=v[i].x;
		coord[1]=v[i].y;
		coord[2]=v[i].z;
		
		glVertex3fv(coord);
	}
	glEnd();

	//sleep(20000);
}
- (void)renderBSPAsWireframe:(int)mesh_index
{
	SUBMESH_INFO *pMesh;
	int i;
	
	pMesh = [mapBSP GetActiveBspPCSubmesh:mesh_index];
	
	
	glLineWidth(_lineWidth);
	
	glBegin(GL_LINES);
	for (i = 0; i < pMesh->IndexCount; i++)
	{
		// First line:(0 -> 1)
		{
			glVertex3fv(pMesh->pVert[pMesh->pIndex[i].tri_ind[0]].vertex_k);
			glVertex3fv(pMesh->pVert[pMesh->pIndex[i].tri_ind[1]].vertex_k);
		}
		// Second line :(1 -> 2)
		{
			glVertex3fv(pMesh->pVert[pMesh->pIndex[i].tri_ind[1]].vertex_k);
			glVertex3fv(pMesh->pVert[pMesh->pIndex[i].tri_ind[2]].vertex_k);
		}
		// Third line :(2 -> 0)
		{
			glVertex3fv(pMesh->pVert[pMesh->pIndex[i].tri_ind[2]].vertex_k);
			glVertex3fv(pMesh->pVert[pMesh->pIndex[i].tri_ind[0]].vertex_k);
		}
	}
	glEnd();
}
- (void)renderHighlighted:(int)mesh_index
{
    glDepthFunc(GL_LEQUAL);
    
	SUBMESH_INFO *pMesh;
	int i;
	
	pMesh = [mapBSP GetActiveBspPCSubmesh:mesh_index];
	//NSLog(@"%d %d", indexMesh, indexHighlight);
	glBegin(GL_TRIANGLE_STRIP);
	glColor4f(1.0f, 0.0f, 0.0f, 1.0f);
	i=indexHighlight;
    glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[0]].vertex_k));
    glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[1]].vertex_k));
    glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[2]].vertex_k));

	glEnd();
    
    glDepthFunc(GL_LESS);
    
}

- (void)renderBSPAsFlatShadedPolygon:(int)mesh_index
{
	SUBMESH_INFO *pMesh;
	int i;
	
	pMesh = [mapBSP GetActiveBspPCSubmesh:mesh_index];
	
	glBegin(GL_TRIANGLES);
	//[self setNextMeshColor];
	for (i = 0; i < pMesh->IndexCount; i++)
	{
		glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[0]].vertex_k));
		glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[1]].vertex_k));
		glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[2]].vertex_k));
	}
	glEnd();
}

-(void)renderSkybox
{
    NSLog(@"Rendering skyboxes");
    
	SkyBox *skies;
	skies = [_scenario sky];

	float pos[6];
	pos[0] = 0;
	pos[1] = 0;
	pos[2] = 0;
	pos[3] = 0;
	pos[4] = 0;
	pos[5] = 0;
    
    
    
    
    [[_mapfile bipd] drawAtPoint:pos lod:_LOD isSelected:YES useAlphas:NO];
    
    BOUNDING_BOX*bb = [[_mapfile bipd] bounding_box];
    if (bb != NULL)
        NSLog(@"Determining bounding box %f %f %f %f %f %f", bb->min[0], bb->min[1], bb->min[2], bb->max[0], bb->max[1], bb->max[2]);

    
	//[[_mapfile tagForId:skies[0].modelIdent] drawAtPoint:pos lod:_LOD isSelected:YES useAlphas:_useAlphas];
}



- (void)renderBSPAsTexturedAndLightmaps:(int)mesh_index
{
    
	pMesh = [mapBSP GetActiveBspPCSubmesh:mesh_index];
	
    
    if (mesh_index == selectedBSP)
    {
        //Update the texture using the photoshop file
        [_texManager refreshTextureOfIdent:pMesh->baseMap];
        [_texManager refreshTextureOfIdent:pMesh->DefaultLightmapIndex index:pMesh->LightmapIndex];
        
        
        
        //[_texManager exportTextureOfIdent:pMesh->baseMap subImage:0];
    }
   
    
	/*if (pMesh->ShaderIndex == -1)
	{
        NSLog(@"Missing shader!");
		//glColor3f(0.1f, 0.1f, 0.1f);
        glColor3f(1.0f, 1.0f, 1.0f);
	}
	else
	{*/
	
		if (pMesh->LightmapIndex != -1)
		{
			//glEnable(GL_TEXTURE_2D);
		}
        
        if (useNewRenderer() != 2)
        {
            glDisable(GL_ALPHA_TEST);
            glDisable(GL_BLEND);
        }
        
        if (pMesh->baseMap != -1 && useNewRenderer() >= 1)
        {
           
            
            
            //glEnable(GL_DEPTH_TEST);
            bool useLightmaps = TRUE;
            
        if (useNewRenderer() == 1)
        {
            useLightmaps = FALSE;
        }
            if (!useLightmaps)
            {
                glDepthFunc(GL_LEQUAL);
                
                
                /*
                glDisable(GL_BLEND);
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                glDepthMask(1); // Disable writing to depth buffer
                
                [_texManager activateTextureOfIdent:pMesh->secondaryMap subImage:0 useAlphas:NO];
                glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
                
                glColor4f(1,1,1,1);
                
                glEnableClientState(GL_VERTEX_ARRAY);
                glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                glMatrixMode(GL_TEXTURE);
                glPushMatrix();
                glScalef(pMesh->secondaryMapScale,pMesh->secondaryMapScale, 0.0);
                glVertexPointer(3, GL_FLOAT, 56, pMesh->pVert[0].vertex_k);
                glTexCoordPointer(2, GL_FLOAT, 56, pMesh->pVert[0].uv);
                
                glDrawElements(GL_TRIANGLES, (pMesh->IndexCount * 3), GL_UNSIGNED_SHORT, pMesh->pIndex);
                glPopMatrix();
                glDisableClientState(GL_VERTEX_ARRAY);
                glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                
                glDisable(GL_TEXTURE_2D);
                glDisable(GL_BLEND);
                */
                
                
                
                glDisable(GL_BLEND);
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                //glDepthMask(1); // Disable writing to depth buffer
                
                [_texManager activateTextureOfIdent:pMesh->baseMap subImage:0 useAlphas:NO];
                glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
                
                glColor4f(1,1,1,1);
                
                glEnableClientState(GL_VERTEX_ARRAY);
                glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                
                glVertexPointer(3, GL_FLOAT, 56, pMesh->pVert[0].vertex_k);
                glTexCoordPointer(2, GL_FLOAT, 56, pMesh->pVert[0].uv);
                
                glDrawElements(GL_TRIANGLES, (pMesh->IndexCount * 3), GL_UNSIGNED_SHORT, pMesh->pIndex);
                
                glDisableClientState(GL_VERTEX_ARRAY);
                glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                
                glDisable(GL_TEXTURE_2D);
                glDisable(GL_BLEND);
                
                
                //Need to make the lightmap fully transparent (on lite anyway)
                [_texManager activateTextureOfIdent:pMesh->DefaultLightmapIndex subImage:pMesh->LightmapIndex useAlphas:YES];
                
                glEnable(GL_BLEND);
                glBlendFunc(GL_DST_ALPHA,GL_ONE_MINUS_DST_ALPHA);
                glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
   
                
                glColor4f(1,1,1,0.2);
                
                glEnableClientState(GL_VERTEX_ARRAY);
                glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                
                glVertexPointer(3, GL_FLOAT, 56, pMesh->pVert[0].vertex_k);
                glTexCoordPointer(2, GL_FLOAT, 20, pMesh->pLightmapVert[0].uv);
                
                glDrawElements(GL_TRIANGLES, (pMesh->IndexCount * 3), GL_UNSIGNED_SHORT, pMesh->pIndex);
                
                glDisableClientState(GL_VERTEX_ARRAY);
                glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                
                glDisable(GL_TEXTURE_2D);
                glDisable(GL_BLEND);
                
                
                glDisable(GL_BLEND);
                glDepthMask(1); // Re-enable writing to depth buffer

                
                glDepthFunc(GL_LESS);
                
                return;
            }
            else
            {
                
                
                
if (useNewRenderer() != 1)
{
    
                glActiveTextureARB(GL_TEXTURE3_ARB);
                glDisable(GL_TEXTURE_2D);
                
                glActiveTextureARB(GL_TEXTURE2_ARB);
                glDisable(GL_TEXTURE_2D);
                
                glActiveTextureARB(GL_TEXTURE1_ARB);
                glDisable(GL_TEXTURE_2D);
                
                glActiveTextureARB(GL_TEXTURE0_ARB);
                glDisable(GL_TEXTURE_2D);
                
                
                    glDepthFunc(GL_LEQUAL);
                
                
                    glDisable(GL_BLEND);
                    glColor4f(1.0f,1.0f,1.0f,1.0f);
                
                    //if (mesh_index == selectedBSP)
                    //    glColor4f(0,1,1,5);
                
                    bool showDetail = true;
                    bool showDetail2 = true;
                    useLightmaps = true;
                
                
                    //glPushMatrix();
                    [_texManager activateTextureAndLightmap:pMesh->baseMap lightmap:pMesh->secondaryMap secondary:pMesh->DefaultLightmapIndex subImage:pMesh->LightmapIndex];
                    //[_texManager activateTextureOfIdent:pMesh->baseMap subImage:0 useAlphas:NO];
                
                    //Whats the diffuse colour? Really need to extend this class to use the shaders
                    //senv
                
                    //
                    glActiveTextureARB(GL_TEXTURE2_ARB);
                
                    glEnableClientState(GL_VERTEX_ARRAY);
                    glVertexPointer(3, GL_FLOAT, 56, pMesh->pVert[0].vertex_k);
    
    if (useNewRenderer() == 3)
    {
        if (pMesh->isWaterShader)
        {
            glEnable(GL_BLEND);
                glColor4f(1.0, 0, 0, 0.3f);
        }
            else
                glColor4f(pMesh->r, pMesh->g, pMesh->b, 1.0);
    }
    else
         glColor4f(pMesh->r, pMesh->g, pMesh->b, 1.0f);
                //
                
                    // texture coord 0
                    glClientActiveTextureARB(GL_TEXTURE0_ARB); // program texcoord unit 0
                    glTexCoordPointer(2, GL_FLOAT, 56, pMesh->pVert[0].uv);
                    glNormalPointer(GL_FLOAT, 56, pMesh->pVert[0].normal);
                    
                    glEnableClientState(GL_TEXTURE_COORD_ARRAY); // enable array data to shader
                
                    if (useLightmaps)
                    {
                        glClientActiveTextureARB(GL_TEXTURE2_ARB);
                        glTexCoordPointer(2, GL_FLOAT, 20, pMesh->pLightmapVert[0].uv);
                        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                    }
                
                   
                
                    if (showDetail)
                    {
                        //texture coord 1
                        glClientActiveTextureARB(GL_TEXTURE1_ARB);
                        glTexCoordPointer(2, GL_FLOAT, 56, pMesh->pVert[0].uv);
                        glNormalPointer(GL_FLOAT, 56, pMesh->pVert[0].normal);
                        
                        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                        
                        glActiveTextureARB(GL_TEXTURE1_ARB);
                        glMatrixMode(GL_TEXTURE);
                        glPushMatrix();
                        glScalef(pMesh->secondaryMapScale,pMesh->secondaryMapScale, 0.0);
                    }
                    else
                    {
                        glActiveTextureARB(GL_TEXTURE1_ARB);
                        glDisable(GL_TEXTURE_2D);
                        
                        glClientActiveTextureARB(GL_TEXTURE0_ARB);
                        glActiveTextureARB(GL_TEXTURE0_ARB);
                    }
                
                
                    
                    glDrawElements(GL_TRIANGLES, (pMesh->IndexCount * 3), GL_UNSIGNED_SHORT, pMesh->pIndex);
                    
                    if (showDetail)
                    {
                        glActiveTextureARB(GL_TEXTURE1_ARB);
                        glPopMatrix();
                        glMatrixMode(GL_MODELVIEW);
                        
                        glClientActiveTextureARB(GL_TEXTURE1_ARB);
                        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                    }
                    
                    glClientActiveTextureARB(GL_TEXTURE0_ARB);
                    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                    
                    glDisableClientState(GL_VERTEX_ARRAY);
                
                    glActiveTextureARB(GL_TEXTURE2_ARB);
                    glDisable(GL_TEXTURE_2D);
                
                    glActiveTextureARB(GL_TEXTURE1_ARB);
                    glDisable(GL_TEXTURE_2D);
                    
                    glActiveTextureARB(GL_TEXTURE0_ARB);
                    glDisable(GL_TEXTURE_2D);
                    glDisable(GL_BLEND);
                
                    
                    
                    
                    
                    
                    
                    
                
                    if (showDetail2)
                    {
                    //[_texManager activateTextureOfIdent:pMesh->DefaultBitmapIndex subImage:0 useAlphas:NO];
                    glEnable(GL_BLEND);
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                glBlendFunc(GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA);
            
                //glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
                
 
                //if (mesh_index == selectedBSP)
                //    glColor4f(0.5,1,1,1);
                
                    //glPushMatrix();
                    [_texManager activateTextureAndLightmap:pMesh->baseMap lightmap:pMesh->primaryMap secondary:pMesh->DefaultLightmapIndex subImage:pMesh->LightmapIndex];
                    
                    //glColor4f(1,1,1,1);
                glActiveTextureARB(GL_TEXTURE0_ARB);
                
                glEnableClientState(GL_VERTEX_ARRAY);
                glVertexPointer(3, GL_FLOAT, 56, pMesh->pVert[0].vertex_k);
                
                // texture coord 0
                glClientActiveTextureARB(GL_TEXTURE0_ARB); // program texcoord unit 0
                glTexCoordPointer(2, GL_FLOAT, 56, pMesh->pVert[0].uv);
                glNormalPointer(GL_FLOAT, 56, pMesh->pVert[0].normal);
                
                glEnableClientState(GL_TEXTURE_COORD_ARRAY); // enable array data to shader
                
                if (useLightmaps)
                {
                    glClientActiveTextureARB(GL_TEXTURE2_ARB);
                    glTexCoordPointer(2, GL_FLOAT, 20, pMesh->pLightmapVert[0].uv);
                    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                }
                
                if (showDetail)
                {
                    //texture coord 1
                    glClientActiveTextureARB(GL_TEXTURE1_ARB);
                    glTexCoordPointer(2, GL_FLOAT, 56, pMesh->pVert[0].uv);
                    glNormalPointer(GL_FLOAT, 56, pMesh->pVert[0].normal);
                    
                    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                    
                    glActiveTextureARB(GL_TEXTURE1_ARB);
                    glMatrixMode(GL_TEXTURE);
                    glPushMatrix();
                    glScalef(pMesh->primaryMapScale,pMesh->primaryMapScale, 0.0);
                }
                    
                    else
                    {
                        glActiveTextureARB(GL_TEXTURE1_ARB);
                        glDisable(GL_TEXTURE_2D);
                        
                        glClientActiveTextureARB(GL_TEXTURE0_ARB);
                        glActiveTextureARB(GL_TEXTURE0_ARB);
                    }
                
                
                
                
                glDrawElements(GL_TRIANGLES, (pMesh->IndexCount * 3), GL_UNSIGNED_SHORT, pMesh->pIndex);
                
                if (showDetail)
                {
                    glActiveTextureARB(GL_TEXTURE1_ARB);
                    glPopMatrix();
                    glMatrixMode(GL_MODELVIEW);
                    
                    glClientActiveTextureARB(GL_TEXTURE1_ARB);
                    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                }
                
                glClientActiveTextureARB(GL_TEXTURE0_ARB);
                glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                
                glDisableClientState(GL_VERTEX_ARRAY);
                
                glActiveTextureARB(GL_TEXTURE2_ARB);
                glDisable(GL_TEXTURE_2D);
                
                glActiveTextureARB(GL_TEXTURE1_ARB);
                glDisable(GL_TEXTURE_2D);
                
                glActiveTextureARB(GL_TEXTURE0_ARB);
                glDisable(GL_TEXTURE_2D);
                glDisable(GL_BLEND);
                    }
                
                
                
                //No fog ;)
                
if (useNewRenderer() == 3)
{
                //Third pass - brighten your day!
                if (showDetail2 && pMesh->isWaterShader == NO)
                {
                    glEnable(GL_BLEND);
                    glBlendFunc(GL_DST_COLOR, GL_ONE);
                    
                    glColor4f(1.0f,1.0f,1.0f,0.8f);
                    
                    glEnableClientState(GL_VERTEX_ARRAY);
                    glVertexPointer(3, GL_FLOAT, 56, pMesh->pVert[0].vertex_k);
                    glDrawElements(GL_TRIANGLES, (pMesh->IndexCount * 3), GL_UNSIGNED_SHORT, pMesh->pIndex);
                    glDisableClientState(GL_VERTEX_ARRAY);
                }
            }
            
                
                
                
                    glDepthFunc(GL_LESS);
}
            
            }
            //glPopMatrix();
        }

        else if (true)
        {
            //glAlphaFunc ( GL_GREATER, 0.1 ) ;
            //glEnable ( GL_ALPHA_TEST ) ;
            
    
            
if (useNewRenderer() != 1)
{
            glActiveTextureARB(GL_TEXTURE2_ARB);
            glDisable(GL_TEXTURE_2D);
            glActiveTextureARB(GL_TEXTURE1_ARB);
            glDisable(GL_TEXTURE_2D);
            glActiveTextureARB(GL_TEXTURE0_ARB);
            glDisable(GL_TEXTURE_2D);
            glDisable(GL_BLEND);
}
            
            if (useNewRenderer() >= 2)
                [_texManager activateTextureOfIdent:pMesh->DefaultBitmapIndex subImage:0 useAlphas:YES];
            else
                [_texManager activateTextureOfIdent:pMesh->DefaultBitmapIndex subImage:0 useAlphas:NO];
            
            
            if (pMesh->isWaterShader)
            {
                glEnable(GL_BLEND);
                glColor4f(pMesh->r, pMesh->g, pMesh->b, 0.5f);
                
                glDisable(GL_FOG);
            }

            
            glEnableClientState(GL_VERTEX_ARRAY);
            glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        
            glVertexPointer(3, GL_FLOAT, 56, pMesh->pVert[0].vertex_k);
            glTexCoordPointer(2, GL_FLOAT, 56, pMesh->pVert[0].uv);
            
            glDrawElements(GL_TRIANGLES, (pMesh->IndexCount * 3), GL_UNSIGNED_SHORT, pMesh->pIndex);
            
            glDisableClientState(GL_VERTEX_ARRAY);
            glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                
            glDisable(GL_TEXTURE_2D);
            glDisable(GL_BLEND);
            
            if (pMesh->isWaterShader)
            {
                glDisable(GL_BLEND);
                glEnable(GL_FOG);
            }

        }
		else
        {
            int x;
            unsigned short index, index2, index3;
            
    
            [_texManager activateTextureOfIdent:pMesh->DefaultBitmapIndex subImage:0 useAlphas:NO];
            
            
            glBegin(GL_TRIANGLES);
            for (x = 0; x < (pMesh->IndexCount); x++)
            {
                index = pMesh->pIndex[x].tri_ind[0];
                index2 = pMesh->pIndex[x].tri_ind[1];
                index3 = pMesh->pIndex[x].tri_ind[2];
                
                Vector *tempVector = pMesh->pVert[index].vertex_k;
                glNormal3f(tempVector->normalx,tempVector->normaly,tempVector->normalz);
                glTexCoord2f(pMesh->pVert[index].uv[0],pMesh->pVert[index].uv[1]);
                glVertex3f(tempVector->x,tempVector->y,tempVector->z);
                
                Vector *tempVector2 = pMesh->pVert[index2].vertex_k;
                glNormal3f(tempVector2->normalx,tempVector2->normaly,tempVector2->normalz);
                glTexCoord2f(pMesh->pVert[index2].uv[0], pMesh->pVert[index2].uv[1]);
                glVertex3f(tempVector2->x,tempVector2->y,tempVector2->z);
                
                Vector *tempVector3 = pMesh->pVert[index3].vertex_k;
                glNormal3f(tempVector3->normalx,tempVector3->normaly,tempVector3->normalz);
                glTexCoord2f(pMesh->pVert[index3].uv[0],pMesh->pVert[index3].uv[1]);
                glVertex3f(tempVector3->x,tempVector3->y,tempVector3->z);
            }
            glEnd();
        }
	//}
    
    
    
}
- (void)drawAxes
{
	// Red is X
	// White is Y
	// Blue is Z
	/*glBegin(GL_LINES);
		glColor3f(1.0f,0.0f,0.0f);
		glVertex3f(15.0f,0.0f,0.0f);
		glVertex3f(-15.0f,0.0f,0.0f);
		
		glColor3f(1.0f, 1.0f, 1.0f);
		glVertex3f(0.0f,15.0f,0.0f);
		glVertex3f(0.0f,-15.0f,0.0f);
		
		glColor3f(0.0f,0.0f, 1.0f);
		glVertex3f(0.0f, 0.0f, 15.0f);
		glVertex3f(0.0f, 0.0f, -15.0f);
	glEnd();*/
        glBegin(GL_LINES);
		// Z
		glColor3f(0,0,1);
		glVertex3f(0,0,0);
		glVertex3f(0,0,20);

		// Y
		glColor3f(0,1,0);
		glVertex3f(0,0,0);
		glVertex3f(0,20,0);
  
		// X
		glColor3f(1,0,0);
		glVertex3f(0,0,0);
		glVertex3f(20,0,0);
	
	
		// Z
		//glColor3f(1,1,0);
		//glVertex3f(0,0,0);
		//glVertex3f(0,0,20);
	
	
  glEnd();
}
- (void)resetMeshColors
{
	meshColor.red = meshColor.green = meshColor.blue = 1.0f;
	meshColor.color_count = 0;
}
- (void)setNextMeshColor
{
	if (meshColor.red < 0.2)
		meshColor.red = 1;
	if (meshColor.blue < 0.2)
		meshColor.blue = 1;
	if (meshColor.green < 0.2)
		meshColor.green = 1;
	
	if ((meshColor.color_count%3) == 0);
		meshColor.red -= 0.1f;
	if ((meshColor.color_count%3) == 1)
		meshColor.blue -= 0.1f;
	if ((meshColor.color_count%3) == 2)
		meshColor.green -= 0.1f;
	
	meshColor.color_count++;
	
	glColor4f(1.0f, 0.0f, 0.0f, 1.0f);
}
/* 
*
*		End BSP Rendering 
*
*/

/*
* 
*		Begin scenario rendering
* 
*/
- (float)distanceToObject:(float *)d
{
	return (float)sqrt(powf(d[0] - [_camera position][0],2) + powf(d[1] - [_camera position][1], 2) + powf(d[2] - [_camera position][2], 2));
}

- (void)renderAllMapObjects
{
	/*double time = mach_absolute_time();
     NSLog(@"%fd", (mach_absolute_time()-time)/100000000.0);*/
    
   USEDEBUG NSLog(@"RENDERING MAP OBJECTS");
    bool nameBSP = false;
	
	int x, i, name = 1;
	float pos[6], distanceTo;
	
    vehicle_reference *vehi_refs;
	vehicle_spawn *vehi_spawns;
	scenery_spawn *scen_spawns;
	mp_equipment *equipSpawns;
	machine_spawn *mach_spawns;
	encounter *encounters;
	SkyBox *skies;
	player_spawn *spawns;
	bipd_reference *bipd_refs;
    
	glInitNames();
	glPushName(0);
    
    
	
	// This one does its own namings
    USEDEBUG NSLog(@"Render netgames");
    if (!nameBSP)
        [self renderNetgameFlags:&name];
	USEDEBUG NSLog(@"Load others");
	bipd_refs = [_scenario bipd_references];
    vehi_refs = [_scenario vehi_references];
	vehi_spawns = [_scenario vehi_spawns];
	scen_spawns = [_scenario scen_spawns];
	equipSpawns = [_scenario item_spawns];
	spawns = [_scenario spawns];
	mach_spawns = [_scenario mach_spawns];
	encounters = [_scenario encounters];
	skies = [_scenario sky];
    
    //--------------------------------
    //The copyright for the following code is owned by Samuel Colbran (Samuco).
    //The copyright for other smaller segments that are not identified by these comments are also owned by Samuel Colbran (Samuco).
    //--------------------------------
    
    
    glLineWidth(_lineWidth);
	
	//glBegin(GL_LINES);

    /*
    glPushMatrix();
    glTranslatef(toPt[0], toPt[1], toPt[2]);
    glColor3f(1.0, 0.0, 0.0);
    
    GLUquadric *sphere=gluNewQuadric();
    gluQuadricDrawStyle( sphere, GLU_FILL);
    gluQuadricNormals( sphere, GLU_SMOOTH);
    gluQuadricOrientation( sphere, GLU_OUTSIDE);
    gluQuadricTexture( sphere, GL_TRUE);
    
    gluSphere(sphere,0.5,20,20);
    gluDeleteQuadric ( sphere );
    glPopMatrix();
    */
    
	//glEnd();
    

    MapTag *bipd = [_mapfile bipd];

	glColor4f(0.0f,0.0f,0.0f,1.0f);
	
    BOOL ignoreDrawing = FALSE;
    //rendDistance = 50;
    
    USEDEBUG NSLog(@"MP0");
    if (!ignoreDrawing)
    {
        USEDEBUG NSLog(@"MP0.1");
    if (TRUE)//useNewRenderer())
    {
        USEDEBUG NSLog(@"MP0.2");
        glEnableClientState(GL_VERTEX_ARRAY);
        USEDEBUG NSLog(@"MP0.3");
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        USEDEBUG NSLog(@"MP0.4");
    }
	for (x = 0; x < [_scenario player_spawn_count]; x++)
	{
        USEDEBUG NSLog(@"MP0.5 %d", x );
        if (!nameBSP)
        {
            // Lookup goes hur
            if (_lookup)
                _lookup[name] = (long)(s_playerspawn * MAX_SCENARIO_OBJECTS + x);
            glLoadName(name);
            name++;
        }
        USEDEBUG NSLog(@"MP0.6 %d", x );
		if (spawns[x].bsp_index == activeBSPNumber)
        {
             if (TRUE)//useNewRenderer())
            {
                if (bipd && [bipd respondsToSelector:@selector(drawAtPoint:lod:isSelected:useAlphas:)])
                {
                    
                    USEDEBUG NSLog(@"MP0.7 %d", x );
                    int type1 = spawns[x].type1;
          
                    USEDEBUG NSLog(@"MP0.8 %d", x );
                    int showType = [[renderGametype selectedItem] tag];
                    
                    if (showType == -1)
                        continue;
                    
                    USEDEBUG NSLog(@"MP0.9 %d", x );
                    //This visbility is a mess xD
                    BOOL visible = FALSE;
                    if (showType == 12)
                        visible = TRUE;
                    else if (showType == 13)
                    {
                        if (type1 != 1)
                            visible = TRUE;
                    }
                    else if (showType == 14)
                    {
                        if (type1 != 1 && type1 != 5)
                            visible = TRUE;
                    }
                    else
                    {
                        if (type1 == showType)
                            visible = TRUE;
                        else if (type1 == 12)
                            visible = TRUE;
                        else if (type1 == 13)
                        {
                            if (showType != 1)
                                visible = TRUE;
                        }
                        else if (type1 == 14)
                        {
                            if (showType != 1 && showType != 5)
                                visible = TRUE;
                        }
                    }
                    USEDEBUG NSLog(@"MP1.1 %d", x );
                    int team = spawns[x].team_index;
                    if (type1 != 1  && !(type1 == 12 && showType == 1))
                    {
                        glColor4f(1.0,1.0,1.0, 1.0);
                        if (spawns[x].isSelected)
                        {
                            glColor4f(1.0,1.0,0.0, 1.0);
                        }
                    }
                    else
                    {
                        if (team == 0)
                        {
                            glColor4f(1.0,0.3,0.3, 1.0);
                            
                            if (spawns[x].isSelected)
                            {
                                glColor4f(1.0,0.8,0.0, 1.0);
                            }
                        }
                        else if (team == 1)
                        {
                            glColor4f(0.3,0.3,1.0, 1.0);
                            if (spawns[x].isSelected)
                            {
                                glColor4f(0.0,1.0,1.0, 1.0);
                            }
                        }
                        else if (team == 5)
                            glColor4f(1.0,1.0,0.0, 1.0);
                        else if (team == 3)
                            glColor4f(0.0,1.0,0.0, 1.0);
                        else if (team == 2)
                            glColor4f(1.0,1.0,0.0, 1.0);
                        else if (team == 9)
                            glColor4f(0.0,1.0,1.0, 1.0);
                        else
                            if (spawns[x].isSelected)
                            {
                                glColor4f(1.0,1.0,0.0, 1.0);
                            }
                    }
                    
                     USEDEBUG NSLog(@"MP1.2 %d", x );
                    
                    
                    if (visible)
                    {
                         USEDEBUG NSLog(@"MP1.3 %d", x );
                        for (i = 0; i < 3; i++)
                            pos[i] = spawns[x].coord[i];
                         USEDEBUG NSLog(@"MP1.4 %d", x );
                        pos[3] = 0;
                        pos[4] = pos[5] = 0.0f;
                         USEDEBUG NSLog(@"MP1.5 %d", x );
                        distanceTo = [self distanceToObject:pos];
                         USEDEBUG NSLog(@"MP1.6 %d", x );
                        if (distanceTo < rendDistance || spawns[x].isSelected)
                        {
                             USEDEBUG NSLog(@"MP1.7 %d", x );
                            [bipd drawAtPoint:spawns[x].coord lod:5 isSelected:NO useAlphas:_useAlphas distance:distanceTo];
                        }
                    }
                }
                else
                {
                    [self renderPlayerSpawn:spawns[x].coord team:spawns[x].team_index isSelected:spawns[x].isSelected];
                }
                
            }
            else
            {
                [self renderPlayerSpawn:spawns[x].coord team:spawns[x].team_index isSelected:spawns[x].isSelected];
            }
        }
	}
        
     if (TRUE)//useNewRenderer())
    {
        glDisableClientState(GL_VERTEX_ARRAY);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        
        glDisable(GL_TEXTURE_2D);
        glDisable(GL_BLEND);
    }
        
    
    
        /*
        
	for (x = 0; x < bsp_point_count; x++)
	{
		// Lookup goes hur
		if (_lookup)
			_lookup[name] = (long)(s_bsppoint * MAX_SCENARIO_OBJECTS + x);
		glLoadName(name);
		name++;
		[self renderPoint:bsp_points[x].coord isSelected:bsp_points[x].isSelected];
	}
         */
        
    
        /*
	for (x = 0; x < [[mapBSP mesh] coll_count]; x++)
	{
		// Lookup goes hur
		if (_lookup)
			_lookup[name] = (long)(s_colpoint * MAX_SCENARIO_OBJECTS + x);
		glLoadName(name);
		name++;
		
		pos[0]=[[mapBSP mesh] collision_verticies][x].x;
		pos[1]=[[mapBSP mesh] collision_verticies][x].y;
		pos[2]=[[mapBSP mesh] collision_verticies][x].z;
		
		//NSLog(@"%f", pos[0]);
	
		
		
		[self renderCP:pos isSelected:[[mapBSP mesh] collision_verticies][x].isSelected];
	}
         */
     
        
    //--------------------------------
    //END CODE
    //--------------------------------
    
        USEDEBUG NSLog(@"Encounters");
    glColor4f(0.0f,0.0f,0.0f,1.0f);
	for (i=0; i < [_scenario encounter_count]; i++)
	{
		player_spawn *encounter_spawns;
		encounter_spawns = encounters[i].start_locs;
		
		for (x = 0; x < encounters[i].start_locs_count; x++)
		{
            if (!nameBSP)
            {
                // Lookup goes hur
                if (_lookup)
                    _lookup[name] = (long)(s_encounter * MAX_SCENARIO_OBJECTS + i);
                glLoadName(name);
                name++;
            }
			
			if (encounter_spawns[x].bsp_index == activeBSPNumber)
				[self renderPlayerSpawn:encounter_spawns[x].coord team:1 isSelected:encounter_spawns[x].isSelected];
		}
	}
}
USEDEBUG NSLog(@"MP1");
    
    
if (drawObjects())
{
    USEDEBUG NSLog(@"MP2");
    if (TRUE)//useNewRenderer())
    {
        glEnableClientState(GL_VERTEX_ARRAY);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glColor3f(1.0f,1.0f,1.0f);
    }
    USEDEBUG NSLog(@"MP3");
    glColor4f(1.0f,1.0f,1.0f,1.0f);
    
	for (x = 0; x < [_scenario item_spawn_count]; x++)
	{
		// Lookup goes hur
        if (!nameBSP)
        {
            if (_lookup)
                _lookup[name] = (long)(s_item * MAX_SCENARIO_OBJECTS + x); 
            glLoadName(name);
            name++;
        }
		if ([_mapfile isTag:equipSpawns[x].modelIdent])
		{
			//NSRunAlertPanel([NSString stringWithFormat:@"%d",(int)equipSpawns[x].modelIdent], @"", @"", @"", @"");
			
			for (i = 0; i < 3; i++)
				pos[i] = equipSpawns[x].coord[i];
			pos[3] = equipSpawns[x].yaw;
			pos[4] = pos[5] = 0.0f;
			distanceTo = [self distanceToObject:pos];
			if (distanceTo < rendDistance || equipSpawns[x].isSelected)
				[[_mapfile tagForId:equipSpawns[x].modelIdent] drawAtPoint:pos lod:_LOD isSelected:equipSpawns[x].isSelected useAlphas:_useAlphas distance:distanceTo];
		}
	}
    USEDEBUG NSLog(@"MP4");

    
	for (x = 0; x < [_scenario mach_spawn_count]; x++)
	{
        if (!nameBSP)
        {
		if (_lookup)
			_lookup[name] = (long)(s_machine * MAX_SCENARIO_OBJECTS + x);
		glLoadName(name);
		name++;
        }
		if ([_mapfile isTag:[_scenario mach_references][mach_spawns[x].numid].machTag.TagId])
		{
			distanceTo = [self distanceToObject:pos];
			
			if ((distanceTo < rendDistance || mach_spawns[x].isSelected) && mach_spawns[x].desired_permutation == activeBSPNumber)
				[[_mapfile tagForId:[_scenario mach_references][mach_spawns[x].numid].modelIdent] drawAtPoint:mach_spawns[x].coord lod:_LOD isSelected:mach_spawns[x].isSelected useAlphas:_useAlphas distance:distanceTo];
		}
	}
    
        USEDEBUG NSLog(@"MP5");

	for (x = 0; x < [_scenario vehicle_spawn_count]; x++)
	{
        if (!nameBSP)
        {
		// Lookup goes hur
		if (_lookup)
			_lookup[name] = (long)(s_vehicle * MAX_SCENARIO_OBJECTS + x);
		glLoadName(name);
		name++;
        }
		if ([_mapfile isTag:vehi_spawns[x].modelIdent])
		{	
			//NSLog(@"%d", (int)vehi_spawns[x].modelIdent);
			//NSLog(@"Vehi Model Ident: 0x%x", vehi_spawns[x].modelIdent);
			for (i = 0; i < 3; i++)
				pos[i] = vehi_spawns[x].coord[i];
			for (i = 3; i < 6; i++)
				pos[i] = vehi_spawns[x].rotation[i - 3];
            
			distanceTo = [self distanceToObject:pos];
			if ((distanceTo < rendDistance || vehi_spawns[x].isSelected) && vehi_spawns[x].desired_permutation == activeBSPNumber)
				[[_mapfile tagForId:vehi_spawns[x].modelIdent] drawAtPoint:pos lod:_LOD isSelected:vehi_spawns[x].isSelected useAlphas:_useAlphas distance:distanceTo];
		}
	}
USEDEBUG NSLog(@"MP6");
    
    
	for (x = 0; x < [_scenario scenery_spawn_count]; x++)
	{
        if (!nameBSP)
        {
		// Lookup goes hur
		if (_lookup)
			_lookup[name] = (long)(s_scenery * MAX_SCENARIO_OBJECTS + x);
		glLoadName(name);
        
		name++;
        }
        
		if ([_mapfile isTag:scen_spawns[x].modelIdent])
		{
			for (i = 0; i < 3; i++)
				pos[i] = scen_spawns[x].coord[i];
			for (i = 3; i < 6; i++)
				pos[i] = scen_spawns[x].rotation[i - 3];
			distanceTo = [self distanceToObject:pos];

			if ((distanceTo < rendDistance || scen_spawns[x].isSelected) && scen_spawns[x].desired_permutation == activeBSPNumber)
				[[_mapfile tagForId:scen_spawns[x].modelIdent] drawAtPoint:pos lod:_LOD isSelected:scen_spawns[x].isSelected useAlphas:_useAlphas distance:distanceTo];
		}
	}
USEDEBUG NSLog(@"MP7");
    
    

     if (TRUE)//useNewRenderer())
    {
        glDisableClientState(GL_VERTEX_ARRAY);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        
        glDisable(GL_TEXTURE_2D);
        glDisable(GL_BLEND);
    }
    USEDEBUG NSLog(@"MP11");
}


}


- (void)renderObject:(dynamic_object)obj
{
	
	float x = obj.x;
	float y = obj.y;
	float z = obj.z;
	
	glColor3f(1.0,1.0,1.0);
	
	glPushMatrix();
	glTranslatef(x, y, z);
	//glRotatef(coord[3] * 57.29577, 0, 0,1);
	float height = 0.6;
	glBegin(GL_QUADS);
	{
		glVertex3f(0.2f,0.2f,height);
		glVertex3f(0.2f,-0.2f,height);
		glVertex3f(-0.2f,-0.2f,height);
		glVertex3f(-0.2f,0.2f,height);
		
		glVertex3f(0.2f,0.2f,height);
		glVertex3f(0.2f,-0.2f,height);
		glVertex3f(0.2f,-0.2f,-height);
		glVertex3f(0.2f,0.2f,-height);
		
		glVertex3f(-0.2f,-0.2f,height);
		glVertex3f(0.2f,-0.2f,height);
		glVertex3f(0.2f,-0.2f,-height);
		glVertex3f(-0.2f,-0.2f,-height);
		
		glVertex3f(-0.2f,-0.2f,height);
		glVertex3f(-0.2f,0.2f,height);
		glVertex3f(-0.2f,0.2f,-height);
		glVertex3f(-0.2f,-0.2f,-height);
		
		glVertex3f(0.2f,0.2f,height);
		glVertex3f(-0.2f,0.2f,height);
		glVertex3f(-0.2f,0.2f,-height);
		glVertex3f(0.2f,0.2f,-height);
		
		glVertex3f(0.2f,0.2f,-height);
		glVertex3f(0.2f,-0.2f,-height);
		glVertex3f(-0.2f,-0.2f,-height);
		glVertex3f(-0.2f,0.2f,-height);	
	}
	glEnd();
	glPopMatrix();
	glEndList();
}

- (void)renderPlayerCharacter:(int)player_number team:(int)teamss
{
	
	float x = playercoords[(player_number * 8) + 0];
	float y = playercoords[(player_number * 8) + 1];
	float z = playercoords[(player_number * 8) + 2];
	float team = playercoords[(player_number * 8) + 3];
	float isSelected = playercoords[(player_number * 8) + 4];
	
	if (team == 0.0)
		glColor3f(1.0,0.0,0.0);
	else if (team == 1.0)
		glColor3f(0.0,0.0,1.0);
	else if (team == 8.0)
		glColor3f(0.0,1.0,1.0);

	if (isSelected == 1.0)
		glColor3f(1.0,1.0,0.0);
	
	glPushMatrix();
	glTranslatef(x, y, z);
	
	
	glRotatef(piradToDeg( playercoords[(player_number * 8) + 6]),0,0,1);
	
	float height = 0.6;
	glBegin(GL_QUADS);
	{
		glVertex3f(0.2f,0.2f,height);
		glVertex3f(0.2f,-0.2f,height);
		glVertex3f(-0.2f,-0.2f,height);
		glVertex3f(-0.2f,0.2f,height);
		
		glVertex3f(0.2f,0.2f,height);
		glVertex3f(0.2f,-0.2f,height);
		glVertex3f(0.2f,-0.2f,-height);
		glVertex3f(0.2f,0.2f,-height);
		
		glVertex3f(-0.2f,-0.2f,height);
		glVertex3f(0.2f,-0.2f,height);
		glVertex3f(0.2f,-0.2f,-height);
		glVertex3f(-0.2f,-0.2f,-height);
		
		glVertex3f(-0.2f,-0.2f,height);
		glVertex3f(-0.2f,0.2f,height);
		glVertex3f(-0.2f,0.2f,-height);
		glVertex3f(-0.2f,-0.2f,-height);
		
		glVertex3f(0.2f,0.2f,height);
		glVertex3f(-0.2f,0.2f,height);
		glVertex3f(-0.2f,0.2f,-height);
		glVertex3f(0.2f,0.2f,-height);
		
		glVertex3f(0.2f,0.2f,-height);
		glVertex3f(0.2f,-0.2f,-height);
		glVertex3f(-0.2f,-0.2f,-height);
		glVertex3f(-0.2f,0.2f,-height);	
		
	}
	glEnd();
	glBegin(GL_LINES);
	{
		// Now to try some other stuffs! Bwahaha!
		// set these lines to white
		glLineWidth(2.0f);
		// x
		glColor3f(1.0f,1.0f,1.0f);
		glVertex3f(0.0f,0.0f,0.0f);
		glVertex3f(50.0f,0.0f,0.0f);
		
	
		
		
	}
	glEnd();
	glPopMatrix();
	glEndList();
}

- (void)renderPlayerSpawn:(float *)coord team:(int)team isSelected:(BOOL)isSelected
{
    
    
    
    
    
    
	if (team == 0)
		glColor3f(1.0,0.0,0.0);
	else if (team == 1)
		glColor3f(0.0,0.0,1.0);
	else if (team == 5)
		glColor3f(1.0,1.0,0.0);
	else if (team == 3)
		glColor3f(0.0,1.0,0.0);
	else if (team == 2)
		glColor3f(1.0,1.0,0.0);
	else if (team == 9)
		glColor3f(0.0,1.0,1.0);
	
	if (isSelected)
		glColor3f(0.0f, 1.0f, 0.0f);
	
	
	glPushMatrix();
	glTranslatef(coord[0], coord[1], coord[2]);
	glRotatef(coord[3] * 57.29577, 0, 0,1);

	glBegin(GL_QUADS);
	{
		glVertex3f(0.2f,0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,0.1f);
		glVertex3f(-0.2f,-0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,0.1f);
		
		glVertex3f(0.2f,0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,-0.1f);
		glVertex3f(0.2f,0.2f,-0.1f);
		
		glVertex3f(-0.2f,-0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,-0.1f);
		glVertex3f(-0.2f,-0.2f,-0.1f);
		
		glVertex3f(-0.2f,-0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,-0.1f);
		glVertex3f(-0.2f,-0.2f,-0.1f);
		
		glVertex3f(0.2f,0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,-0.1f);
		glVertex3f(0.2f,0.2f,-0.1f);
		
		glVertex3f(0.2f,0.2f,-0.1f);
		glVertex3f(0.2f,-0.2f,-0.1f);
		glVertex3f(-0.2f,-0.2f,-0.1f);
		glVertex3f(-0.2f,0.2f,-0.1f);	
	}
	glEnd();
	if (isSelected)
	{
		glBegin(GL_LINES);
		{
			// Now to try some other stuffs! Bwahaha!
			// set these lines to white
			glLineWidth(2.0f);
			// x
			glColor3f(1.0f,0.0f,0.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(50.0f,0.0f,0.0f);
			// y
			glColor3f(0.0f,1.0f,0.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(0.0f,50.0f,0.0f);
			// z
			glColor3f(0.0f,0.0f,1.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(0.0f,0.0f,50.0f);
			
			
			/*
			float my_x = coord[0];
			float my_y = coord[1];
			float my_z = coord[2];
			
			float c_x = [_camera position][0];
			float c_y = [_camera position][1];
			float c_z = [_camera position][2];
			
			c_x = my_x - c_x;
			c_y = my_y - c_y;
			c_z = my_z - c_z;
			
			glColor3f(1.0f, 1.0f, 0.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(c_x, c_y, c_z);
			
			//COMEBACK*/
		}
		glEnd();
	}
	glPopMatrix();
	glEndList();
}

- (void)renderCube:(float *)coord rotation:(float *)rotation color:(float *)color selected:(BOOL)selected
{
	glPushMatrix();
	glTranslatef(coord[0], coord[1], coord[2]);
	glRotatef(piradToDeg( rotation[0]),0,0,1);
	glColor3f(color[0],color[1],color[2]);
	
	// lol, override
	if (selected)
		glColor3f(0.0f, 1.0f, 0.0f);
	
	glBegin(GL_QUADS);
	{
		glVertex3f(0.2f,0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,0.1f);
		glVertex3f(-0.2f,-0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,0.1f);
		
		glVertex3f(0.2f,0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,-0.1f);
		glVertex3f(0.2f,0.2f,-0.1f);
		
		glVertex3f(-0.2f,-0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,-0.1f);
		glVertex3f(-0.2f,-0.2f,-0.1f);
		
		glVertex3f(-0.2f,-0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,-0.1f);
		glVertex3f(-0.2f,-0.2f,-0.1f);
		
		glVertex3f(0.2f,0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,-0.1f);
		glVertex3f(0.2f,0.2f,-0.1f);
		
		glVertex3f(0.2f,0.2f,-0.1f);
		glVertex3f(0.2f,-0.2f,-0.1f);
		glVertex3f(-0.2f,-0.2f,-0.1f);
		glVertex3f(-0.2f,0.2f,-0.1f);
	}
	glEnd();
	glPopMatrix();
}


- (void)renderBox:(float *)coord rotation:(float *)rotation color:(float *)color selected:(BOOL)selected
{

    if (useNewRenderer() >= 2)
    {
        glPushMatrix();
        glTranslatef(coord[0], coord[1], coord[2]);
        glRotatef(piradToDeg( rotation[0]),0,0,1);
        glColor3f(color[0],color[1],color[2]);
        
        if (selected)
            glColor3f(0.0f, 1.0f, 0.0f);
		if (selected)
        {
            /*
            glBegin(GL_LINES);
            {
                // Now to try some other stuffs! Bwahaha!
                // set these lines to white
                glLineWidth(4.0f);
                // x
                glColor3f(1.0f,0.0f,0.0f);
                glVertex3f(0.0f,0.0f,0.0f);
                glVertex3f(50.0f,0.0f,0.0f);
                // y
                glColor3f(0.0f,1.0f,0.0f);
                glVertex3f(0.0f,0.0f,0.0f);
                glVertex3f(0.0f,50.0f,0.0f);
                // z
                glColor3f(0.0f,0.0f,1.0f);
                glVertex3f(0.0f,0.0f,0.0f);
                glVertex3f(0.0f,0.0f,50.0f);
                
                // pointer arrow
                glColor3f(1.0f,1.0f,1.0f);
                glVertex3f(0.5f,0.0f,0.0f);
                glVertex3f(0.3f,0.2f,0.0f);
                glVertex3f(0.5f,0.0f,0.0f);
                glVertex3f(0.3f,-0.2f,0.0f);
            }
            glEnd();
             */
        }
        
        
        GLUquadric *sphere=gluNewQuadric();
        gluQuadricDrawStyle( sphere, GLU_FILL);
        gluQuadricOrientation( sphere, GLU_OUTSIDE);

        gluSphere(sphere,0.1,10,10);
        gluDeleteQuadric ( sphere );
        glPopMatrix();
        return;
    }
    
	glPushMatrix();
	glTranslatef(coord[0], coord[1], coord[2]);
	glRotatef(piradToDeg( rotation[0]),0,0,1);
	glColor3f(color[0],color[1],color[2]);
	
	// lol, override
	if (selected)
		glColor3f(0.0f, 1.0f, 0.0f);
		
	glBegin(GL_QUADS);
	{
		glVertex3f(0.2f,0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,0.1f);
		glVertex3f(-0.2f,-0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,0.1f);
		
		glVertex3f(0.2f,0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,-0.1f);
		glVertex3f(0.2f,0.2f,-0.1f);
		
		glVertex3f(-0.2f,-0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,-0.1f);
		glVertex3f(-0.2f,-0.2f,-0.1f);
		
		glVertex3f(-0.2f,-0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,-0.1f);
		glVertex3f(-0.2f,-0.2f,-0.1f);
		
		glVertex3f(0.2f,0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,-0.1f);
		glVertex3f(0.2f,0.2f,-0.1f);
		
		glVertex3f(0.2f,0.2f,-0.1f);
		glVertex3f(0.2f,-0.2f,-0.1f);
		glVertex3f(-0.2f,-0.2f,-0.1f);
		glVertex3f(-0.2f,0.2f,-0.1f);	
	}
	glEnd();
	if (selected)
	{
		glBegin(GL_LINES);
		{
			// Now to try some other stuffs! Bwahaha!
			// set these lines to white
			glLineWidth(4.0f);
			// x
			glColor3f(1.0f,0.0f,0.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(50.0f,0.0f,0.0f);
			// y
			glColor3f(0.0f,1.0f,0.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(0.0f,50.0f,0.0f);
			// z
			glColor3f(0.0f,0.0f,1.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(0.0f,0.0f,50.0f);
			
			//glColor3f(1.0f,1.0f, 0.0f);
		//	glVertex3f(0.0f,0.0f,0.0f);
			//glVertex3f([_camera position][0], [_camera position][1], [_camera position][2]);
			
			
			// pointer arrow
			glColor3f(1.0f,1.0f,1.0f);
			glVertex3f(0.5f,0.0f,0.0f);
			glVertex3f(0.3f,0.2f,0.0f);
			glVertex3f(0.5f,0.0f,0.0f);
			glVertex3f(0.3f,-0.2f,0.0f);
		}
		glEnd();
	}
	glPopMatrix();
}

- (void)renderCP:(float *)coord isSelected:(BOOL)isSelected
{	
	glPushMatrix();
	glTranslatef(coord[0], coord[1], coord[2]);
	
	if (isSelected)
		glColor3f(1.0f, 1.0f, 0.0f);
	else 
		glColor3f(0.0,1.0,1.0);
	
	glBegin(GL_QUADS);
	{
		glVertex3f(0.1f,0.05f,0.05f);
		glVertex3f(0.1f,-0.05f,0.05f);
		glVertex3f(-0.1f,-0.05f,0.05f);
		glVertex3f(-0.1f,0.05f,0.05f);
		
		glVertex3f(0.1f,0.05f,0.05f);
		glVertex3f(0.1f,-0.05f,0.05f);
		glVertex3f(0.1f,-0.05f,-0.05f);
		glVertex3f(0.1f,0.05f,-0.05f);
		
		glVertex3f(-0.1f,-0.05f,0.05f);
		glVertex3f(0.1f,-0.05f,0.05f);
		glVertex3f(0.1f,-0.05f,-0.05f);
		glVertex3f(-0.1f,-0.05f,-0.05f);
		
		glVertex3f(-0.1f,-0.05f,0.05f);
		glVertex3f(-0.1f,0.05f,0.05f);
		glVertex3f(-0.1f,0.05f,-0.05f);
		glVertex3f(-0.1f,-0.05f,-0.05f);
		
		glVertex3f(0.1f,0.05f,0.05f);
		glVertex3f(-0.1f,0.05f,0.05f);
		glVertex3f(-0.1f,0.05f,-0.05f);
		glVertex3f(0.1f,0.05f,-0.05f);
		
		glVertex3f(0.1f,0.05f,-0.05f);
		glVertex3f(0.1f,-0.05f,-0.05f);
		glVertex3f(-0.1f,-0.05f,-0.05f);
		glVertex3f(-0.1f,0.05f,-0.05f);
	}
	glEnd();
	if (isSelected)
	{
		glBegin(GL_LINES);
		{
			// Now to try some other stuffs! Bwahaha!
			// set these lines to white
			glLineWidth(2.0f);
			// x
			glColor3f(1.0f,0.0f,0.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(50.0f,0.0f,0.0f);
			// y
			glColor3f(0.0f,1.0f,0.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(0.0f,50.0f,0.0f);
			// z
			glColor3f(0.0f,0.0f,1.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(0.0f,0.0f,50.0f);
		}
		glEnd();
	}
	glPopMatrix();
}

- (void)renderPoint:(float *)coord isSelected:(BOOL)isSelected
{
    
    glPushMatrix();
    glTranslatef(coord[0], coord[1], coord[2]);
    glColor3f(0.0, 1.0, 1.0);
    
    if (isSelected)
        glColor3f(0.0f, 1.0f, 0.0f);
    
    GLUquadric *sphere=gluNewQuadric();
    gluQuadricDrawStyle( sphere, GLU_FILL);
    gluQuadricNormals( sphere, GLU_SMOOTH);
    gluQuadricOrientation( sphere, GLU_OUTSIDE);
    gluQuadricTexture( sphere, GL_TRUE);
    
    gluSphere(sphere,0.01,10,10);
    gluDeleteQuadric ( sphere );
    glPopMatrix();
    
    return;
    
	glPushMatrix();
	glTranslatef(coord[0], coord[1], coord[2]);
	
	if (isSelected)
		glColor3f(1.0f, 1.0f, 0.0f);
	else
		glColor3f(0.0,1.0,0.0);
	
	glBegin(GL_QUADS);
	{
		glVertex3f(0.1f,0.05f,0.05f);
		glVertex3f(0.1f,-0.05f,0.05f);
		glVertex3f(-0.1f,-0.05f,0.05f);
		glVertex3f(-0.1f,0.05f,0.05f);
		
		glVertex3f(0.1f,0.05f,0.05f);
		glVertex3f(0.1f,-0.05f,0.05f);
		glVertex3f(0.1f,-0.05f,-0.05f);
		glVertex3f(0.1f,0.05f,-0.05f);
		
		glVertex3f(-0.1f,-0.05f,0.05f);
		glVertex3f(0.1f,-0.05f,0.05f);
		glVertex3f(0.1f,-0.05f,-0.05f);
		glVertex3f(-0.1f,-0.05f,-0.05f);
		
		glVertex3f(-0.1f,-0.05f,0.05f);
		glVertex3f(-0.1f,0.05f,0.05f);
		glVertex3f(-0.1f,0.05f,-0.05f);
		glVertex3f(-0.1f,-0.05f,-0.05f);
		
		glVertex3f(0.1f,0.05f,0.05f);
		glVertex3f(-0.1f,0.05f,0.05f);
		glVertex3f(-0.1f,0.05f,-0.05f);
		glVertex3f(0.1f,0.05f,-0.05f);
		
		glVertex3f(0.1f,0.05f,-0.05f);
		glVertex3f(0.1f,-0.05f,-0.05f);
		glVertex3f(-0.1f,-0.05f,-0.05f);
		glVertex3f(-0.1f,0.05f,-0.05f);
	}
	glEnd();
	if (isSelected)
	{
		glBegin(GL_LINES);
		{
			// Now to try some other stuffs! Bwahaha!
			// set these lines to white
			glLineWidth(2.0f);
			// x
			glColor3f(1.0f,0.0f,0.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(50.0f,0.0f,0.0f);
			// y
			glColor3f(0.0f,1.0f,0.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(0.0f,50.0f,0.0f);
			// z
			glColor3f(0.0f,0.0f,1.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(0.0f,0.0f,50.0f);
		}
		glEnd();
	}
	glPopMatrix();
}

- (void)renderFlag:(float *)coord team:(int)team isSelected:(BOOL)isSelected
{	
	glPushMatrix();
	glTranslatef(coord[0], coord[1], coord[2]);
	
	if (team == 0)
		glColor3f(1.0,0.0,0.0);
	else if (team == 1)
		glColor3f(0.0,0.0,1.0);
	if (isSelected)
		glColor3f(0.0f, 1.0f, 0.0f);
		
	glBegin(GL_QUADS);
	{
		glVertex3f(0.1f,0.05f,0.6f);
		glVertex3f(0.1f,-0.05f,0.6f);
		glVertex3f(-0.1f,-0.05f,0.6f);
		glVertex3f(-0.1f,0.05f,0.6f);
		
		glVertex3f(0.1f,0.05f,0.6f);
		glVertex3f(0.1f,-0.05f,0.6f);
		glVertex3f(0.1f,-0.05f,-0.2f);
		glVertex3f(0.1f,0.05f,-0.2f);
		
		glVertex3f(-0.1f,-0.05f,0.6f);
		glVertex3f(0.1f,-0.05f,0.6f);
		glVertex3f(0.1f,-0.05f,-0.2f);
		glVertex3f(-0.1f,-0.05f,-0.2f);
		
		glVertex3f(-0.1f,-0.05f,0.6f);
		glVertex3f(-0.1f,0.05f,0.6f);
		glVertex3f(-0.1f,0.05f,-0.2f);
		glVertex3f(-0.1f,-0.05f,-0.2f);
		
		glVertex3f(0.1f,0.05f,0.6f);
		glVertex3f(-0.1f,0.05f,0.6f);
		glVertex3f(-0.1f,0.05f,-0.2f);
		glVertex3f(0.1f,0.05f,-0.2f);
		
		glVertex3f(0.1f,0.05f,-0.2f);
		glVertex3f(0.1f,-0.05f,-0.2f);
		glVertex3f(-0.1f,-0.05f,-0.2f);
		glVertex3f(-0.1f,0.05f,-0.2f);
	}
	glEnd();
	if (isSelected)
	{
		glBegin(GL_LINES);
		{
			// Now to try some other stuffs! Bwahaha!
			// set these lines to white
			glLineWidth(2.0f);
			// x
			glColor3f(1.0f,0.0f,0.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(50.0f,0.0f,0.0f);
			// y
			glColor3f(0.0f,1.0f,0.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(0.0f,50.0f,0.0f);
			// z
			glColor3f(0.0f,0.0f,1.0f);
			glVertex3f(0.0f,0.0f,0.0f);
			glVertex3f(0.0f,0.0f,50.0f);
		}
		glEnd();
	}
	glPopMatrix();
}
- (void)renderNetgameFlags:(int *)name
{
	int i;
	float color[3];
	float rotation[3];
	multiplayer_flags *mp_flags;
	
	mp_flags = [_scenario netgame_flags];
	
	for (i = 0; i < [_scenario multiplayer_flags_count]; i++)
	{	
		// Name convention is going to be the following:
		/*
			10000 * the type + the index
			This way, I can go like so:
		*/
		
		rotation[0] = mp_flags[i].rotation; rotation[1] = rotation[2] = 0.0f;
		
        
		glLoadName(*name);
		// Lookup goes hur
		if (_lookup)
			_lookup[*name] = (long)((s_netgame * MAX_SCENARIO_OBJECTS) + i);
		*name += 1; // For some reason it won't increment when I go *name++;
        
        int showType = [[renderGametype selectedItem] tag];
        
        
		switch (mp_flags[i].type)
		{
			case ctf_flag:
                if (showType == 1||showType == 12)
                {
                    [self renderFlag:mp_flags[i].coord team:mp_flags[i].team_index isSelected:mp_flags[i].isSelected];
                }
				break;
			case ctf_vehicle:
				break;
			case oddball:
                if (showType == 3||showType == 12)
                {
                    color[0] = 1.0f; color [1] = 1.0f; color[2] = 0.3f;
                    [self renderBox:mp_flags[i].coord rotation:rotation color:color selected:mp_flags[i].isSelected];
                }
                
				
				break;
			case race_track:
                //Only show if race is selected
                if (showType == 5||showType == 12||showType == 13)
                {
                    
                    color[0] = 1.0f; color [1] = 0.2f; color[2] = 0.0f;
                    [self renderBox:mp_flags[i].coord rotation:rotation color:color selected:mp_flags[i].isSelected];
                    
                    
                    //How many race tracks are there?
                    int highest=0;
                    int count = 0;
                    int a;
                    for (a = 0; a < [_scenario multiplayer_flags_count]; a++)
                    {
                        if (mp_flags[a].type == race_track)
                        {
                            if (mp_flags[a].team_index > highest)
                                highest = mp_flags[a].team_index;
                            count++;
                        }
                    }
                    
                    if (showType == 5)
                    {
                        [statusMessage setStringValue:[NSString stringWithFormat:@"Track: %d/32", highest+1]];
                    }
                    
                    //Create lines between this and the one to the immediate right.
                    BOOL found = false;
                    int smallest = 1000;
                    multiplayer_flags nextItem;
                    for (a = 0; a < [_scenario multiplayer_flags_count]; a++)
                    {
                        if (a == i)
                            continue;
                        
                        if (mp_flags[a].type == race_track)
                        {
                            if (mp_flags[i].team_index == highest)
                            {
                                //Link to 0
                                if (mp_flags[a].team_index == 0)
                                {
                                    found = true;
                                    nextItem = mp_flags[a];
                                }
                            }
                            else
                            {
                                if (mp_flags[a].team_index > mp_flags[i].team_index && mp_flags[a].team_index < smallest)
                                {
                                    smallest=mp_flags[a].team_index;
                                    found = true;
                                    nextItem = mp_flags[a];
                                }
                            }
                        }
                        
                    }
                    
                    if (found)
                    {
                        //Connect these two objects with a line.
                        //mp_flags[i].coord
                        //mp_flags[i+1].coord
                        
                        
                        
                        float *coord = mp_flags[i].coord;
                        float *coord2 = nextItem.coord;
                        
                        glLineWidth(5.0f);
                        glBegin(GL_LINES);
                        {
                            // pointer arrow
                            glColor3f(((mp_flags[i].team_index)/(highest*1.0)),((mp_flags[i].team_index)/(highest*1.0)),((highest-mp_flags[i].team_index)/(highest*1.0)));
                            
                            glVertex3f(coord[0],coord[1],coord[2]);
                            glVertex3f(coord2[0],coord2[1],coord2[2]);
                        }
                        glEnd();
                        
                        
                        
                    }
                    
                }
				break;
			case race_vehicle:
				break;
			case vegas_bank:
				break;
			case teleporter_entrance:
				color[0] = 1.0f; color[1] = 1.0f; color[2] = 0.2f;
                
                BOOL found = false;
                multiplayer_flags mp_exit;
                int a;
                for (a = 0; a < [_scenario multiplayer_flags_count]; a++)
                {
                    if (a == i)
                        continue;
                    
                    if (mp_flags[a].type == teleporter_exit)
                    {
                        if (mp_flags[a].team_index == mp_flags[i].team_index)
                        {
                            found = true;
                            mp_exit = mp_flags[a];
                            break;
                        }
                    }
                        
                }
                
                if (found)
                {
                    //Connect these two objects with a line.
                    //mp_flags[i].coord
                    //mp_flags[i+1].coord
  
                    
                    
                    float *coord = mp_flags[i].coord;
                    float *coord2 = mp_exit.coord;
                    
                    glLineWidth(0.01f);
                    glBegin(GL_LINES);
                    {
                        // Now to try some other stuffs! Bwahaha!
                        // set these lines to white
                        
                        
                        // pointer arrow
                        glColor3f(1.0f,0.5f,0.5f);
                        glVertex3f(coord[0],coord[1],coord[2]);
                        glVertex3f(coord2[0],coord2[1],coord2[2]);
                    }
                    glEnd();
                 
                    
                    
                }
                
				[self renderBox:mp_flags[i].coord rotation:rotation color:color selected:mp_flags[i].isSelected];
				break;
			case teleporter_exit:
				color[0] = 0.2f; color[1] = 1.0f; color[2] = 1.0f;
                
                //mp_flags[i].team_index
                
				[self renderBox:mp_flags[i].coord rotation:rotation color:color selected:mp_flags[i].isSelected];
				break;
			case hill_flag:
                if (showType == 4||showType == 12||showType == 13||showType == 14)
                {
                    color[0] = 0.4f; color [1] = color[2] = 0.0f;
                    [self renderBox:mp_flags[i].coord rotation:rotation color:color selected:mp_flags[i].isSelected];
                    
                    
                    //Link each hill marker
                    //Create lines between this and the one to the immediate right.
                    BOOL found = false;
                    
                    float closestDistance = 1000;
                    float secondcloSsestDistance = 1000;
                    int nid = -1;
                    struct multiplayer_flags nextItem;
                    struct  multiplayer_flags nextItem1 ;

                    for (a = 0; a < [_scenario multiplayer_flags_count]; a++)
                    {
                        if (a == i)
                            continue;
                        
              
                        if (mp_flags[a].type == hill_flag)
                        {
                            if (mp_flags[a].team_index == mp_flags[i].team_index)
                            {
                                float *coord = mp_flags[i].coord;
                                float *coord2 = mp_flags[a].coord;
                                
                                float distance = sqrtf(powf(coord[0]-coord2[0], 2) + powf(coord[1]-coord2[1], 2) + powf(coord[2]-coord2[2], 2));
                            
                                if (distance < closestDistance)
                                {
                                    closestDistance = distance;
                                    nextItem = mp_flags[a];
                                    nid=a;
                                    found = YES;
                                }
                            }
                        }
                        
                    }
                    
                    
                    for (a = 0; a < [_scenario multiplayer_flags_count]; a++)
                    {
                        if (a == i || a == nid)
                            continue;
                        
                        
                        if (mp_flags[a].type == hill_flag)
                        {
                            if (mp_flags[a].team_index == mp_flags[i].team_index)
                            {
                                float *coord = mp_flags[i].coord;
                                float *coord2 = mp_flags[a].coord;
                                
                                float distance = sqrtf(powf(coord[0]-coord2[0], 2) + powf(coord[1]-coord2[1], 2) + powf(coord[2]-coord2[2], 2));
                                
                                if (distance < secondcloSsestDistance)
                                {
                                    secondcloSsestDistance = distance;
                                    nextItem1 = mp_flags[a];
                                    
                                    found = YES;
                                }
                            }
                        }
                        
                    }
                    
                    
                    
                    if (found)
                    {
                        //Connect these two objects with a line.
                        //mp_flags[i].coord
                        //mp_flags[i+1].coord
                        
                        
                        
                        float *coord = mp_flags[i].coord;
                        float *coord2 = nextItem.coord;
                        float *coord3 = nextItem1.coord;
                        
                        glLineWidth(5.0f);
                        glBegin(GL_LINES);
                        {
                            // pointer arrow
                            glColor3f(1.0, 0.8, 0.3);
                            
                            glVertex3f(coord[0],coord[1],coord[2]);
                            glVertex3f(coord2[0],coord2[1],coord2[2]);
                            
                            glVertex3f(coord[0],coord[1],coord[2]);
                            glVertex3f(coord3[0],coord3[1],coord3[2]);
                        }
                        glEnd();
                        
                        
                        
                    }

                    
                }
				break;
		}
	}
}
/*
* 
*		End scenario rendering
* 
*/

/*
* 
*		Begin GUI interfacing functions
* 
*/
- (IBAction)renderBSPNumber:(id)sender
{
	activeBSPNumber = [sender indexOfSelectedItem];
	[mapBSP setActiveBsp:[sender indexOfSelectedItem]];
	[self recenterCamera:self];
}
- (IBAction)sliderChanged:(id)sender
{
	if (sender == framesSlider)
	{
        if (performanceMode)
        {
            NSRunAlertPanel(@"You cannot change the frames per second while in performance mode.", @"Please turn off performance mode and try again.", @"OK", nil, nil);
            return;
        }
		_fps = roundf([framesSlider floatValue]);
		[fpsText setFloatValue:_fps];
		[self resetTimerWithClassVariable];
	}
	else if (sender == s_accelerationSlider)
	{
		// Time to abuse floor()
		s_acceleration = floorf([s_accelerationSlider floatValue] * 10 + 0.5)/10;
		[s_accelerationText setStringValue:[[[NSNumber numberWithFloat:s_acceleration] stringValue] stringByAppendingString:@"x"]];
	}
	else if ((sender == s_xRotation) || (sender == s_yRotation) || (sender == s_zRotation))
	{
		[self rotateFocusedItem:[s_xRotation floatValue] y:[s_yRotation floatValue] z:[s_zRotation floatValue]];
        [self setNeedsDisplay:YES];
	}
	else if ((sender == s_xRotText) || (sender == s_yRotText) || (sender == s_zRotText))
	{
		[s_xRotation setFloatValue:[[s_xRotText stringValue] floatValue]];
		[s_yRotation setFloatValue:[[s_yRotText stringValue] floatValue]];
		[s_zRotation setFloatValue:[[s_zRotText stringValue] floatValue]];
        
		[self rotateFocusedItem:[s_xRotText floatValue] y:[s_yRotText floatValue] z:[s_zRotText floatValue]];
	}
    else if ((sender == s_xText) || (sender == s_yText) || (sender == s_zText))
	{
		[self moveFocusedItem:[s_xText floatValue] y:[s_yText floatValue] z:[s_zText floatValue]];
	}
}


-(IBAction)SelectAll:(id)sender;
{
	unsigned int type, index, nameLookup;
	if (!selections || [selections count] == 0)
		return;
	
	nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
	
	type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
	index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
	
	@try {
		int i;
		for (i = 0; i < 200; i++)
		{
			[_scenario vehi_spawns][i].isSelected = YES;
		}
	}
	@catch (NSException * e) {
		
	}
	@finally {
		
	}
	
}


-(void)writeFloat:(float)value to:(int)address
{
	// Kill the host!
	float new_value = value;
	
	int *valueP = (int *)&new_value;
	*valueP = CFSwapInt32HostToBig(*((int *)&new_value));
	
	//(haloProcessID, address, &new_value, sizeof(float));
}

-(void)writeUInt16:(int)value to:(int)address
{
	// Kill the host!
	int new_value = value;
	short teamNumber = CFSwapInt16HostToBig(new_value);
	//(haloProcessID, address, &teamNumber, sizeof(short));
}



-(void)setSpeed:(float)speed_number player:(int)index
{
	[self writeFloat:8.0 to:0x4BD7B038 + 0x200 * index];
}


-(void)setSize:(float)plsize player:(int)index
{
	float newHostXValue = plsize;
	
	int haloObjectPointer = [self getDynamicPlayer:index];
	if (haloObjectPointer)
	{
		
		const int offsetToPlayerXCoordinate = 0x5C + 0x4 + 0x4+ 0x4+ 0x4+ 0x4+ 0x4+ 0x4+ 0x4+ 0x4;
		
		// Kill the host!
		[self writeFloat:newHostXValue to:haloObjectPointer + offsetToPlayerXCoordinate];
		[self writeFloat:newHostXValue to:haloObjectPointer + offsetToPlayerXCoordinate + 0x4];
		[self writeFloat:newHostXValue to:haloObjectPointer + offsetToPlayerXCoordinate + 0x8];
	}
	
}

-(void)setShield:(float)shield player:(int)index
{
	float newHostXValue = shield;
	
	int haloObjectPointer = [self getDynamicPlayer:index];
	if (haloObjectPointer)
	{
			
		const int offsetToPlayerXCoordinate = 0x5C + 0x4 + 0x4+ 0x4+ 0x4+ 0x4+ 0x4+ 0x4+ 0x4+ 0x4+ 0x4+ 0x4 + 0x58;
			
		// Kill the host!
		[self writeFloat:newHostXValue to:haloObjectPointer + offsetToPlayerXCoordinate];
		[self writeFloat:newHostXValue to:haloObjectPointer + offsetToPlayerXCoordinate + 0x4];
	}
	
}


-(void)setTeam:(int)team_number player:(int)index
{
	[self writeUInt16:team_number to:0x4BD7AFD0 + 0x1E + 0x200 * index];
	[self killPlayer:index];
}



-(IBAction)REDTEAM:(id)sender
{
	unsigned int type, index, nameLookup;
	
	if (!selections || [selections count] == 0)
		return;
	
	nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
	
	type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
	index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
	
	//Tell the server to delete the player
	int player_number = index;
	
	[self setTeam:0	player:player_number];
}


-(IBAction)BLUETEAM:(id)sender
{
	unsigned int type, index, nameLookup;
	
	if (!selections || [selections count] == 0)
		return;
	
	nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
	
	type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
	index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
	
	//Tell the server to delete the player
	int player_number = index;
	[self setTeam:1	player:player_number];
}

-(IBAction)GODPOWER:(id)sender
{
	unsigned int type, index, nameLookup;
	
	if (!selections || [selections count] == 0)
		return;
	
	nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
	
	type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
	index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
	
	//Tell the server to delete the player
	int player_number = index;
	
	[self setShield:100000000.0 player:player_number];
	[self setSpeed:8.0 player:player_number];
	[self setSize:12.0 player:player_number];
}

-(IBAction)GUARDIANTEAM:(id)sender
{
	unsigned int type, index, nameLookup;
	
	if (!selections || [selections count] == 0)
		return;
	
	nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
	
	type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
	index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
	
	//Tell the server to delete the player
	int player_number = index;
	
	[self setTeam:8	player:player_number];
	[self setSpeed:8.0	player:player_number];
}

-(IBAction)JAILTEAM:(id)sender
{
	unsigned int type, index, nameLookup;
	
	if (!selections || [selections count] == 0)
		return;
	
	nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
	
	type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
	index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
	
	//Tell the server to delete the player
	int player_number = index;
	
	[self setTeam:3	player:player_number];
}

- (IBAction)buttonPressed:(id)sender
{
	if (sender == selectMode || sender == m_SelectMode)
	{
		_mode = select;
		[self unpressButtons];
		[selectMode setState:NSOnState];
	}
	else if (sender == translateMode || sender == m_TranslateMode)
	{
		_mode = translate;
		[self unpressButtons];
		[translateMode setState:NSOnState];
	}
	else if (sender == moveCameraMode || sender == m_MoveCamera)
	{
		_mode = rotate_camera;
		[self unpressButtons];
		[moveCameraMode setState:NSOnState];
	}
    /*else if (sender == grassMode || sender == dirtMode || sender == eyedropperMode || sender == lightmapMode)
	{
        [self unpressButtons];
        NSRunAlertPanel(@"Painting has been disabled in this version of swordedit.", @"Please try using a newer version.", @"OK", nil, nil);
    }*/
    else if (sender == grassMode)
	{
		_mode = grass;
		[self unpressButtons];
		[grassMode setState:NSOnState];
	}
    else if (sender == dirtMode )
	{
		_mode = dirt;
		[self unpressButtons];
		[dirtMode setState:NSOnState];
	}
    else if (sender == eyedropperMode)
	{
		_mode = eyedrop;
		[self unpressButtons];
		[eyedropperMode setState:NSOnState];
	}
    else if (sender == lightmapMode )
	{
		_mode = lightmapMode;
		[self unpressButtons];
		[lightmapMode setState:NSOnState];
	}
	else if (sender == duplicateSelected || sender == m_duplicateSelected)
	{
		unsigned int type, index, nameLookup;

		if (!selections || [selections count] == 0)
			return;
		
		nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
	
		type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
		index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
		[selections replaceObjectAtIndex:0 withObject:[NSNumber numberWithUnsignedInt:[_scenario duplicateScenarioObject:type index:index]]];
		_selectFocus = [[selections objectAtIndex:0] longValue];
	}
	else if (sender == s_spawnCreateButton)
	{
		// Since I only have the option to create a teleporter pair now, lets just do that.
		if (_mapfile)
		{
			[self deselectAllObjects];
            
            if ([[[createType selectedItem] title] isEqualToString:@"Teleporter Pair"])
                [self processSelection:(unsigned int)[_scenario createTeleporterPair:[_camera vView]]];
            else if ([[[createType selectedItem] title] isEqualToString:@"Scenery"])
                [self processSelection:(unsigned int)[_scenario createSkull:[_camera vView]]];
            else if ([[[createType selectedItem] title] isEqualToString:@"Vehicle"])
                [self processSelection:(unsigned int)[_scenario createVehicle:[_camera vView]]];
            else if ([[[createType selectedItem] title] isEqualToString:@"Item"])
                [self processSelection:(unsigned int)[_scenario createItem:[_camera vView]]];
            else if ([[[createType selectedItem] title] isEqualToString:@"Red Spawn"])
                [self processSelection:(unsigned int)[_scenario createRedSpawn:[_camera vView]]];
            else if ([[[createType selectedItem] title] isEqualToString:@"Blue Spawn"])
                [self processSelection:(unsigned int)[_scenario createBlueSpawn:[_camera vView]]];
            else if ([[[createType selectedItem] title] isEqualToString:@"Machine"])
                [self processSelection:(unsigned int)[_scenario createMachine:[_camera vView]]];
		}
	}
	else if (sender == s_skullCreateButton)
	{
		// Since I only have the option to create a teleporter pair now, lets just do that.
		if (_mapfile)
		{
			[self deselectAllObjects];
			[self processSelection:(unsigned int)[_scenario createSkull:[_camera vView]]];
		}
	}
	else if (sender == s_machineCreateButton)
	{
		// Since I only have the option to create a teleporter pair now, lets just do that.
		if (_mapfile)
		{
			[self deselectAllObjects];
			[self processSelection:(unsigned int)[_scenario createMachine:[_camera vView]]];
		}
	}
	else if (sender == b_deleteSelected || sender == m_deleteFocused)
	{
		unsigned int type, index, nameLookup;

		if (!selections || [selections count] == 0)
			return;
		for (id loopItem in selections)
		{
		
		nameLookup = [loopItem unsignedIntValue];
	
		type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
		index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
		
		
		if (type == s_playerobject)
		{
			//Tell the server to delete the player
			int player_number = index;

			//[self setTeam:1	player:player_number];
					
			[self killPlayer:player_number];
			
		}
		else if (type == s_mapobject)
		{
			//Tell the server to delete the object
			int player_number = index;
			
			//[self setTeam:1	player:player_number];
			
			int object = map_objects[index].address;
			[self writeFloat:10000.0 to:object + 0x5C];
		}
		else
		{
		
		[_scenario deleteScenarioObject:type index:index];
		}
		}
		
		[self deselectAllObjects];
		
		[_spawnEditor reloadAllData];
	}
	else if (sender == selectedTypeSwapButton)
	{
		unsigned int type, index;
		short *numid;
		
		type = (unsigned int)(_selectFocus / MAX_SCENARIO_OBJECTS);
		index = (unsigned int)(_selectFocus % MAX_SCENARIO_OBJECTS);
		
		switch (type)
		{
			case s_scenery:
				//Delete this as a scenery
				//[_scenario scen_spawns][index].modelIdent = [_scenario baseModelIdent:[_scenario scen_references][*numid].scen_ref.TagId];
				
				
				break;
		}
	}
	else if (sender == selectedSwapButton)
	{
		unsigned int type, index;
		short *numid;
		
		type = (unsigned int)(_selectFocus / MAX_SCENARIO_OBJECTS);
		index = (unsigned int)(_selectFocus % MAX_SCENARIO_OBJECTS);
		
		switch (type)
		{
			case s_scenery:
				numid = &[_scenario scen_spawns][index].numid;
				*numid = [sender indexOfSelectedItem];
				[_scenario scen_spawns][index].modelIdent = [_scenario baseModelIdent:[_scenario scen_references][*numid].scen_ref.TagId];
				#ifdef __DEBUG__
				NSLog([[_mapfile tagForId:[_scenario scen_spawns][index].modelIdent] tagName]);
				#endif
				break;
			case s_item:
				[_scenario item_spawns][index].itmc.TagId = [_mapfile itmcIdForKey:[sender indexOfSelectedItem]];
				[_scenario item_spawns][index].modelIdent = [_scenario itmcModelForId:[_scenario item_spawns][index].itmc.TagId];
				break;
			case s_machine:
                NSLog(@"%d", [sender indexOfSelectedItem]);
				[_scenario mach_spawns][index].numid = [sender indexOfSelectedItem];
				break;
			case s_vehicle:
				NSLog(@"Change vehicle ref");
				numid = [_scenario vehi_spawns][index].numid;
				
				//Switch the types of vehicles
				//long original_mt = [_scenario vehi_references][*numid].vehi_ref.TagId;
				//long new_mt = [_scenario vehi_references][[sender indexOfSelectedItem]].vehi_ref.TagId;
				
				//[_scenario vehi_references][*numid].vehi_ref.TagId = new_mt;
				//[_scenario vehi_references][[sender indexOfSelectedItem]].vehi_ref.TagId = original_mt;
                
                [_scenario vehi_spawns][index].numid = [sender indexOfSelectedItem];
				[_scenario vehi_spawns][index].modelIdent = [_scenario baseModelIdent:[_scenario vehi_references][[sender indexOfSelectedItem]].vehi_ref.TagId];
                
                //[_scenario pairModelsWithSpawn];
				break;
		}
		[self fillSelectionInfo];
	}
	else if (sender == useAlphaCheckbox)
	{
		_useAlphas = ([useAlphaCheckbox state] ? TRUE : FALSE);
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults setBool:_useAlphas forKey:@"_useAlphas"];
		[userDefaults synchronize];
	}
	else if (sender == lodDropdownButton)
	{
		
		int ti = (int)[lodDropdownButton doubleValue];
		
		if (ti == 0) _LOD = 0;
		else if (ti == 2) _LOD = 4;
		else _LOD = 2;


	}
    
    //[self loadPrefs];
}
- (void)lookAtFocusedItem
{
	float *coord;
	unsigned int type, index;
	type = (unsigned int)(_selectFocus / MAX_SCENARIO_OBJECTS);
	index = (unsigned int)(_selectFocus % MAX_SCENARIO_OBJECTS);
	
	switch (type)
	{
		case s_scenery:
			coord = [_scenario scen_spawns][index].coord;
			break;
		case s_item:
			coord = [_scenario item_spawns][index].coord;
			break;
		case s_playerspawn:
			coord = [_scenario spawns][index].coord;
			break;
		
	}
	
	//[_camera PositionCamera:[_camera position][0] positionY:[_camera position][1] positionZ:[_camera position][2] 
	//						viewX:coord[0] viewY:coord[1] viewZ:coord[2] 
	//						upVectorX:0.0f upVectorY:0.0f upVectorZ:1.0f];
}

-(float *)getCameraPos
{
	return [_camera position];
}

-(float *)getCameraView
{
	return [_camera vView];
}




- (IBAction)recenterCamera:(id)sender
{
	float x,y,z;
		[mapBSP GetActiveBspCentroid:&x center_y:&y center_z:&z];
		[_camera PositionCamera:(x + 5.0f) positionY:(y + 5.0f) positionZ:(z + 5.0f)
						viewX:x viewY:y viewZ:z
						upVectorX:0.0f upVectorY:0.0f upVectorZ:1.0f];
}
- (IBAction)orientCamera:(id)sender
{

}
- (IBAction)changeRenderStyle:(id)sender
{
	[pointsItem setState:NSOffState];
	[wireframeItem setState:NSOffState];
	[shadedTrisItem setState:NSOffState];
	[texturedItem setState:NSOffState];
	if (sender == pointsItem || sender == buttonPoints)
		currentRenderStyle = point;
	else if (sender == wireframeItem || sender == buttonWireframe)
		currentRenderStyle = wireframe;
	else if (sender == shadedTrisItem || sender == buttonShadedFaces)
		currentRenderStyle = flat_shading;
	else if (sender == texturedItem || sender == buttonTextured)
		currentRenderStyle = textured_tris;
	[sender setState:NSOnState];
}
- (IBAction)setCameraSpawn:(id)sender
{
	NSData *camDat = [NSData dataWithBytes:&camCenter[0] length:12];
	[prefs setObject:camDat forKey:[[_mapfile mapName] stringByAppendingFormat:@"camDat_0%d", activeBSPNumber]];
	//[prefs setObject:camDat forKey:[[[_mapfile mapName] stringByAppendingString:@"camDat_0"] stringByAppendingString:[[NSNumber numberWithInt:activeBSPNumber] stringValue]]];
	camDat = [NSData dataWithBytes:&camCenter[1] length:12];
	[prefs setObject:camDat forKey:[[[_mapfile mapName] stringByAppendingString:@"camDat_1"] stringByAppendingString:[[NSNumber numberWithInt:activeBSPNumber] stringValue]]];
	camDat = [NSData dataWithBytes:&camCenter[2] length:12];
	[prefs setObject:camDat forKey:[[[_mapfile mapName] stringByAppendingString:@"camDat_@"] stringByAppendingString:[[NSNumber numberWithInt:activeBSPNumber] stringValue]]];
	[prefs synchronize];
	
}
- (IBAction)setSelectionMode:(id)sender
{
	_selectType = [sender indexOfSelectedItem];
}
- (IBAction)killKeys:(id)sender
{
	int i;
	for (i = 0; i < 6; i++)
		move_keys_down[i].isDown = NO;
}

- (void)setPositionSliders:(NSNumber*)aax y:(NSNumber*)aay z:(NSNumber*)aaz
{
    [s_xText setStringValue:[aax stringValue]];
	[s_yText setStringValue:[aay stringValue]];
	[s_zText setStringValue:[aaz stringValue]];
	
	[s_xText setEnabled:YES];
	[s_yText setEnabled:YES];
	[s_zText setEnabled:YES];
	[s_xText setEditable:YES];
	[s_yText setEditable:YES];
	[s_zText setEditable:YES];
}

- (void)setPositionSlidersOld:(float)aax y:(float)aay z:(float)aaz
{
	[s_xText setStringValue:[NSString stringWithFormat:@"%f",aax]];
	[s_yText setStringValue:[NSString stringWithFormat:@"%f",aay]];
	[s_zText setStringValue:[NSString stringWithFormat:@"%f",aaz]];
	
	[s_xText setEnabled:YES];
	[s_yText setEnabled:YES];
	[s_zText setEnabled:YES];
	[s_xText setEditable:YES];
	[s_yText setEditable:YES];
	[s_zText setEditable:YES];
}
- (void)setRotationSliders:(float)x y:(float)y z:(float)z
{
	x = fabs(piradToDeg(x));
	y = fabs(piradToDeg(y));
	z = fabs(piradToDeg(z));
	
	[s_xRotation setFloatValue:x];
	[s_yRotation setFloatValue:y];
	[s_zRotation setFloatValue:z];
	
	[s_xRotText setStringValue:[NSString stringWithFormat:@"%f",x]];
	[s_yRotText setStringValue:[NSString stringWithFormat:@"%f",y]];
	[s_zRotText setStringValue:[NSString stringWithFormat:@"%f",z]];
	
    [s_xRotation setEnabled:YES];
	[s_yRotation setEnabled:YES];
	[s_zRotation setEnabled:YES];
    
	[s_xRotText setEnabled:YES];
	[s_yRotText setEnabled:YES];
	[s_zRotText setEnabled:YES];
	[s_xRotText setEditable:YES];
	[s_yRotText setEditable:YES];
	[s_zRotText setEditable:YES];
}
- (void)unpressButtons
{
	[selectMode setState:NSOffState];
	[translateMode setState:NSOffState];
	[moveCameraMode setState:NSOffState];
    [dirtMode setState:NSOffState];
    [grassMode setState:NSOffState];
    [eyedropperMode setState:NSOffState];
    [lightmapMode setState:NSOffState];
}
- (void)updateSpawnEditorInterface
{
	unsigned int type, index;
	type = (unsigned int)(_selectFocus / MAX_SCENARIO_OBJECTS);
	index = (unsigned int)(_selectFocus % MAX_SCENARIO_OBJECTS);
	
	// Here we now send these values to the spawn editor.
}
// This little baby will go ahead and find the location of a spawn where the ray from the mouse intersects the BSP, thus you can select stuff.
- (void)findSelectedSpawnCoord
{
}
/*
* 
*		End GUI interfacing functions
* 
*/


/*
*
*	Begin Scenario Editing Functions
*
*/

-(IBAction)GoFullscreen:(id)sender
{
	if (!isfull)
	{
		
		NSWindow *main = [self window];
	
		//[main setLevel:100]; //Higher than the menu bar
		[spawne setLevel:101];
		[spawnc setLevel:101];
		[render setLevel:101];
		[camera setLevel:101];
		[select setLevel:101];
	
		[main setStyleMask:NSBorderlessWindowMask]; //Allow menu bar exceeding.
		//[main setFrame:NSMakeRect(0, 0, [[NSScreen mainScreen] frame].size.width, [[NSScreen mainScreen] frame].size.height /*for window title bar height*/) display:YES];
	
		//Make the application the 'main'
		[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
		[main makeKeyAndOrderFront:nil];
		
		[sender setTitle:@"Exit Fullscreen"];
		isfull = 1;	
	}
	else {
		
		NSWindow *main = [self window];
		
		[main setLevel:NSNormalWindowLevel]; //Higher than the menu bar
		[spawne setLevel:NSFloatingWindowLevel];
		[spawnc setLevel:NSFloatingWindowLevel];
		[render setLevel:NSFloatingWindowLevel];
		[camera setLevel:NSFloatingWindowLevel];
		[select setLevel:NSFloatingWindowLevel];
		[main setStyleMask:(NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask)]; //Allow menu bar exceeding.
		[main setFrame:NSMakeRect(0, 0, [[NSScreen mainScreen] frame].size.width, [[NSScreen mainScreen] frame].size.height /*for window title bar height*/) display:YES];
		
		[sender setTitle:@"Fullscreen"];
		isfull = 0;	
	}

	
}

float dp(float*v1,float*v2)
{
    return (float)((float)v1[0]*(float)v2[0] + (float)v1[1]*(float)v2[1]);// + (float)v1[2]*(float)v2[2]);
}

// Start Code
// must include at least these
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define SAME_CLOCKNESS 1
#define DIFF_CLOCKNESS 0

typedef struct fpoint_tag
{
    float x;
    float y;
    float z;
} fpoint;

fpoint pt1 = {0.0, 0.0, 0.0};
fpoint pt2 = {0.0, 3.0, 3.0};
fpoint pt3 = {2.0, 0.0, 0.0};
fpoint linept = {0.0, 0.0, 6.0};
fpoint vect = {0.0, 2.0, -4.0};
fpoint pt_int = {0.0, 0.0, 0.0};

int check_same_clock_dir(fpoint pt1, fpoint pt2, fpoint pt3, fpoint norm)
{
    float testi, testj, testk;
    float dotprod;
    // normal of trinagle
    testi = (((pt2.y - pt1.y)*(pt3.z - pt1.z)) - ((pt3.y - pt1.y)*(pt2.z - pt1.z)));
    testj = (((pt2.z - pt1.z)*(pt3.x - pt1.x)) - ((pt3.z - pt1.z)*(pt2.x - pt1.x)));
    testk = (((pt2.x - pt1.x)*(pt3.y - pt1.y)) - ((pt3.x - pt1.x)*(pt2.y - pt1.y)));
    
    // Dot product with triangle normal
    dotprod = testi*norm.x + testj*norm.y + testk*norm.z;
    
    //answer
    if(dotprod < 0)
        return DIFF_CLOCKNESS;
    else
        return SAME_CLOCKNESS;
}

int check_intersect_tri(fpoint pt1, fpoint pt2, fpoint pt3, fpoint linept, fpoint vect, fpoint* pt_int)
{
    float V1x, V1y, V1z;
    float V2x, V2y, V2z;
    fpoint norm;
    float dotprod;
    float t;
    
    // vector form triangle pt1 to pt2
    V1x = pt2.x - pt1.x;
    V1y = pt2.y - pt1.y;
    V1z = pt2.z - pt1.z;
    
    // vector form triangle pt2 to pt3
    V2x = pt3.x - pt2.x;
    V2y = pt3.y - pt2.y;
    V2z = pt3.z - pt2.z;
    
    // vector normal of triangle
    norm.x = V1y*V2z-V1z*V2y;
    norm.y = V1z*V2x-V1x*V2z;
    norm.z = V1x*V2y-V1y*V2x;
    
    // dot product of normal and line's vector if zero line is parallel to triangle
    dotprod = norm.x*vect.x + norm.y*vect.y + norm.z*vect.z;
    
    //if(dotprod < 0)
    //{
        //Find point of intersect to triangle plane.
        //find t to intersect point
        t = -(norm.x*(linept.x-pt1.x)+norm.y*(linept.y-pt1.y)+norm.z*(linept.z-pt1.z))/
        (norm.x*vect.x+norm.y*vect.y+norm.z*vect.z);
        
        // if ds is neg line started past triangle so can't hit triangle.
        if(t < 0) return 0;
            
        pt_int->x = linept.x + vect.x*t;
        pt_int->y = linept.y + vect.y*t;
        pt_int->z = linept.z + vect.z*t;
        
       
        if(check_same_clock_dir(pt1, pt2, *pt_int, norm) == SAME_CLOCKNESS)
        {
            if(check_same_clock_dir(pt2, pt3, *pt_int, norm) == SAME_CLOCKNESS)
            {
                if(check_same_clock_dir(pt3, pt1, *pt_int, norm) == SAME_CLOCKNESS)
                {
                    // answer in pt_int is insde triangle
                    return 1;
                }
            }
        }
    //}
    return 0;
}

-(float*)coordtoGround:(float*)pos
{
    SUBMESH_INFO *pMesh2;
	int a;
	int i;
    int mesh_count;
    float *closest;
    BOOL found = NO;
    BOOL collison = NO;
    float closestDistance = 1000;
    
    BspMesh *mesh = [mapBSP mesh];
    closest = [mesh findIntersection:pos withOther:pos];
    
    float *currentPos = malloc(sizeof(float)*3);
    currentPos[0] = pos[0];
    currentPos[1] = pos[1];
    currentPos[2] = pos[2];
    
    if (!closest)
    {
        currentPos[2] = pos[2]+30;
    }
    
    //LAZY METHOD (which MIGHT work!) Similar to newtons method
    int iterations = 20;
    float distance = 1000.0f;

    
    for (i=0; i < iterations; i++)
    {
        
        distance/=2.0;
        //First, is currentPos above or below the plane?
        float *closest = [mesh findIntersection:currentPos withOther:currentPos];
        if (closest)
        {
            //Above the plane. Move down by distance/=2.0
            currentPos[2] = currentPos[2] - distance;
        }
        else
        {
            //Below the plane
            currentPos[2] = currentPos[2] + distance;
        }
        
        
    }
    
    currentPos[2] = currentPos[2] + 0.01;
    closest = [mesh findIntersection:currentPos withOther:currentPos];
    if (!closest)
    {
        currentPos[2] = pos[2];
    }
    
    return currentPos;
    
    
    mesh_count = [mapBSP GetActiveBspSubmeshCount];
    for (a = 0; a < mesh_count; a++)
    {
        
        pMesh2 = [mapBSP GetActiveBspPCSubmesh:a];
        
        //Find the closest x,y coordinate for this.
        for (i = 0; i < pMesh2->IndexCount; i++)
        {
            float *pt1 = ((pMesh2->pVert[pMesh2->pIndex[i].tri_ind[0]].vertex_k));
            float *pt2 = ((float *)(pMesh2->pVert[pMesh2->pIndex[i].tri_ind[1]].vertex_k));
            float *pt3 = ((float *)(pMesh2->pVert[pMesh2->pIndex[i].tri_ind[2]].vertex_k));
            
            //Calculate a distance function
            float dist1 = (float)sqrt(powf(pos[0] - pt1[0],2) + powf(pos[1] - pt1[1], 2) + powf(pos[2] - pt1[2], 2));
            float dist2 = (float)sqrt(powf(pos[0] - pt2[0],2) + powf(pos[1] - pt2[1], 2) + powf(pos[2] - pt2[2], 2));
            float dist3 = (float)sqrt(powf(pos[0] - pt3[0],2) + powf(pos[1] - pt3[1], 2) + powf(pos[2] - pt3[2], 2));
            
            float total = dist1+dist2+dist3;
            dist1=total-dist1;
            dist2=total-dist2;
            dist3=total-dist3;
            total = dist1+dist2+dist3;
            
            if (total > closestDistance)
            {
                continue;
            }
            
            if (pt1[0] == pt2[0] || pt1[1] == pt2[1])
            {
                continue;
            }
            
            fpoint fpt1 = {pt1[0], pt1[1], pt1[2]};
            fpoint fpt2 = {pt2[0], pt2[1], pt2[2]};
            fpoint fpt3 = {pt3[0], pt3[1], pt3[2]};
            fpoint fpt4 = {pos[0], pos[1], pos[2]+100};
            fpoint v = {0,0,-1};
            fpoint* pt_int = malloc(sizeof(fpoint));
            
            //Is our point on this plane (x,y) wise
            float *v0 = malloc(sizeof(float)*3);
            v0[0]=pt3[0]-pt1[0];
            v0[1]=pt3[1]-pt1[1];
            v0[2]=pt3[2]-pt1[2];
            
            float *v1 = malloc(sizeof(float)*3);
            v1[0]=pt2[0]-pt1[0];
            v1[1]=pt2[1]-pt1[1];
            v1[2]=pt2[2]-pt1[2];
            
            float *v2 = malloc(sizeof(float)*3);
            v2[0]=pos[0]-pt1[0];
            v2[1]=pos[1]-pt1[1];
            v2[2]=pos[2]-pt1[2];
            
            float dot00 = dp(v0,v0);
            float dot01 = dp(v0,v1);
            float dot02 = dp(v0,v2);
            float dot11 = dp(v1,v1);
            float dot12 = dp(v1,v2);
            
            float invDenom = 1/(dot00 * dot11 - dot01 * dot01);
            float u = (dot11 * dot02 - dot01 * dot12) * invDenom;
            float v32 = (dot00 * dot12 - dot01 * dot02) * invDenom;

            free(v0);
            free(v1);
            free(v2);
            
            if ((u >= 0) && (v32 >= 0) && (u + v32 < 1))
            {
                float dist1 = (float)sqrt(powf(pos[0] - pt1[0],2) + powf(pos[1] - pt1[1], 2) + powf(pos[2] - pt1[2], 2));
                float dist2 = (float)sqrt(powf(pos[0] - pt2[0],2) + powf(pos[1] - pt2[1], 2) + powf(pos[2] - pt2[2], 2));
                float dist3 = (float)sqrt(powf(pos[0] - pt3[0],2) + powf(pos[1] - pt3[1], 2) + powf(pos[2] - pt3[2], 2));
                
                float total = dist1+dist2+dist3;
                dist1=total-dist1;
                dist2=total-dist2;
                dist3=total-dist3;
                total = dist1+dist2+dist3;
                
                //float z=((dist3/total)*pt3[2]+(dist2/total)*pt2[2]+(dist1/total)*pt1[2]);
                
                if (check_intersect_tri(fpt1, fpt2, fpt3, fpt4, v, pt_int))
                {
                    indexMesh = a;
                    indexHighlight = i;

                    if (pt_int->z > pos[2] && pt_int->z - pos[2] > 0.3)
                    {
                        collison = YES;
                    }
                    
                    float dist = (float)sqrt(powf(pos[0] - pt_int->x,2) + powf(pos[1] - pt_int->y, 2) + powf(pos[2] - pt_int->z, 2));
                    if (dist < closestDistance)
                    {
                        if (found)
                            free(closest);
                        
                        closestDistance = dist;
                        
                        //Inside triangle
                        closest = malloc(sizeof(float)*3);
                        closest[0]=pt_int->x;
                        closest[1]=pt_int->y;
                        closest[2]=pt_int->z;

                        found = YES;
                    }
                }
            }
            
            free(pt_int);
              
             
        }
    }
	
    if (found)
        return closest;
    if (collison)
        return pos;
    
    float *ret = malloc(sizeof(float)*3);
    ret[0]=0;
    ret[1]=0;
    ret[2]=0;
    
    return ret;
}

-(BOOL)isAboveGround:(float*)pos
{
    //New smexy method
    BspMesh *mesh = [mapBSP mesh];
    float *closest = [mesh findIntersection:pos withOther:pos];
    if (closest)
    {
        return TRUE;
    }
    return FALSE;
}


float fromPt[3];
float toPt[3];
float Dot(CVector3 vVector1, CVector3 vVector2);

BOOL isPainting;

- (int)tryBSPSelection:(NSPoint)downPoint shiftDown:(BOOL)shiftDown width:(CGFloat)w height:(CGFloat)h
{

    isPainting = YES;
   
    
    //Based on our mouse location and camera location.
    GLsizei bufferSize = (GLsizei) ([mapBSP GetActiveBspSubmeshCount]+1);
    
    GLuint nameBuf[bufferSize];
	GLuint tmpLookup[bufferSize];
	GLint viewport[4];
	GLuint hits;
	unsigned int i, j, z1, z2;
    int mesh_index;

	glGetIntegerv(GL_VIEWPORT,viewport);
	unsigned int mesh_count = [mapBSP GetActiveBspSubmeshCount];
    
	//glMatrixMode(GL_PROJECTION);
	
    /*
	glSelectBuffer(bufferSize,nameBuf);
	glRenderMode(GL_SELECT);
	
	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity();
	
	gluPickMatrix((GLdouble)downPoint.x + w / 2,(GLdouble)downPoint.y + h / 2,w,h,viewport);
	
    
    float z_distance = 400.0f;
    float n_distance = 0.1f;
    
	gluPerspective(45.0f,(GLfloat)(viewport[2] - viewport[0])/(GLfloat)(viewport[3] - viewport[1]),n_distance,z_distance);

	glMatrixMode(GL_MODELVIEW);
	glColor4f(1.0f,1.0f,1.0f,1.0f);
    
    glInitNames();
	glPushName(0);
    
	
     
	int m, mesh_index;
    
    int name = 1;

		mesh_count = [mapBSP GetActiveBspSubmeshCount];
		[self resetMeshColors];
	
		
            // Lookup goes hu
            glLoadName(name);
            name++;
            
            SUBMESH_INFO *pMesha;
            pMesha = [mapBSP GetActiveBspPCSubmesh:mesh_index];
            
            glBegin(GL_TRIANGLES);
            for (i = 0; i < pMesha->IndexCount; i++)
            {
                glVertex3fv((float *)(pMesha->pVert[pMesha->pIndex[i].tri_ind[0]].vertex_k));
                glVertex3fv((float *)(pMesha->pVert[pMesha->pIndex[i].tri_ind[1]].vertex_k));
                glVertex3fv((float *)(pMesha->pVert[pMesha->pIndex[i].tri_ind[2]].vertex_k));
            }
            glEnd();
    
    
    
	//[self reshape];
	hits = glRenderMode(GL_RENDER);
    glPopMatrix();
    
	GLuint names, *ptr = (GLuint *)nameBuf;
	unsigned int type;
	BOOL hasFound = FALSE;

    //glRasterPos() 
    if (hits != 0)
    {
        */
    
        //Where did the ray intersect?
        //ptr+=3;
       
        //selectedBSP = (*(ptr) -1 );
        
        
        //Calculate a vector using the camera
        float cx = [_camera position][0];
        float cy = [_camera position][1];
        float cz = [_camera position][2];
        
        float vx = [_camera vView][0];
        float vy = [_camera vView][1];
        float vz = [_camera vView][2];
        
        
        float sx = [_camera vStrafe][0];
        float sy = [_camera vStrafe][1];
        float sz = [_camera vStrafe][2];
        
        
        //How wide is the view?
        float nw = [self bounds].size.width;
        float nh = [self bounds].size.height;
        
        float far = 500;
        
        float xp = ((downPoint.x/nw)*2-1.0);
        float yp = -((downPoint.y/nh)*2-1.0);
        
        float vector_x = (vx-cx);
        float vector_y = (vy-cy);
        float vector_z = (vz-cz);
        
        NSSize sceneBounds = [self frame].size;
        
        
        float ySize = 1.01*sin((22.5*M_PI)/180);
        float xSize = (sceneBounds.width / sceneBounds.height) * ySize;
        
        fromPt[0] = cx+vector_x*0.1;
        fromPt[1] = cy+vector_y*0.1;
        fromPt[2] = cz+vector_z*0.1;
        
        /*
        
        //sx/=20;
        //sy/=20;
        ////sz/=20;
        
        //(z_distance / n_distance)
        
        CVector3 vView = NewCVector3(vx,vy,vz);
        CVector3 vPosition= NewCVector3(cx,cy,cz);
        CVector3 vStrage= NewCVector3(sx,sy,sz);
        
        CVector3 vCross = Cross(SubtractTwoVectors(vView , vPosition), vStrage);
        CVector3 upward = Normalize(vCross);
        
        toPt[0] = cx+ (cx+vector_x*0.1+(xp*xSize*sx + yp*ySize*upward.x)-cx)*far;
        toPt[1] = cy+ (cy+vector_y*0.1+(xp*xSize*sy + yp*ySize*upward.y)-cy)*far;
        toPt[2] = cz+ (cz+vector_z*0.1+(xp*xSize*sz + yp*ySize*upward.z)-cz)*far;
        
        */
        
        //get the matrices for their passing to gluUnProject
        double afModelviewMatrix[16];
        double afProjectionMatrix[16];
        glGetDoublev(GL_MODELVIEW_MATRIX, afModelviewMatrix);
        glGetDoublev(GL_PROJECTION_MATRIX, afProjectionMatrix);
        
        GLint anViewport[4];
        glGetIntegerv(GL_VIEWPORT, anViewport);
        
        float fMouseX, fMouseY, fMouseZ;
        fMouseX = downPoint.x;
        fMouseY = downPoint.y;
        fMouseZ = 0.0f;
        
        glReadPixels(fMouseX, fMouseY, 1, 1, GL_DEPTH_COMPONENT, GL_FLOAT, &fMouseZ);
        
        double dTempX, dTempY, dTempZ;
        gluUnProject(fMouseX, fMouseY, fMouseZ, afModelviewMatrix, afProjectionMatrix, anViewport, &dTempX, &dTempY, &dTempZ);
        //ofObjX, Y and Z should be populated and returned now
        
       
        CVector3 vPosition= NewCVector3(cx,cy,cz);
        CVector3 vFar= NewCVector3(dTempX,dTempY,dTempZ);
        
        //Check intersection
        CVector3 l = SubtractTwoVectors(vFar, vPosition);
        float *closest;
        BOOL found = NO;
    float closestDistance = 1000;

        //mesh_index = selectedBSP;
        for (mesh_index = 0; mesh_index < mesh_count; mesh_index++)
		{
            
        SUBMESH_INFO *pMesha;
        pMesha = [mapBSP GetActiveBspPCSubmesh:mesh_index];
        
        
        for (i = 0; i < pMesha->IndexCount; i++)
        {
            float *vertex = pMesha->pVert[pMesha->pIndex[i].tri_ind[0]].vertex_k;
            float *vertex2 = pMesha->pVert[pMesha->pIndex[i].tri_ind[1]].vertex_k;
            float *vertex3 = pMesha->pVert[pMesha->pIndex[i].tri_ind[2]].vertex_k;
            float *normal = pMesha->pVert[pMesha->pIndex[i].tri_ind[0]].normal;
          
            CVector3 a= NewCVector3(vertex[0],vertex[1],vertex[2]);
            CVector3 n= NewCVector3(normal[0],normal[1],normal[2]);
            
            /*
            float dot = Dot(n, l);
            
            if (dot <= 0.0)
                continue;
            
            float d = Dot(n, SubtractTwoVectors(a, vPosition)) / dot;
            if (d < 0.0f || d > 1.0f) // plane is beyond the ray we consider
                continue;
            */
            
            //CVector3 p = AddTwoVectors(vPosition, NewCVector3(d*l.x, d*l.y, d*l.z)); // p intersect the plane (triangle)
            
            /*
            CVector3 b = NewCVector3(vertex2[0],vertex2[1],vertex2[2]);
            CVector3 cvec = NewCVector3(vertex3[0],vertex3[1],vertex3[2]);
            
            CVector3 n1 = Cross(SubtractTwoVectors(b, a), SubtractTwoVectors(p, a));
            CVector3 n2 = Cross(SubtractTwoVectors(cvec, b), SubtractTwoVectors(p, b));
            CVector3 n3 = Cross(SubtractTwoVectors(a, cvec), SubtractTwoVectors(p, cvec));
            
            if (Dot(n,n1) >= 0.0f &&
                Dot(n,n2) >= 0.0f &&
                Dot(n,n3) >= 0.0f)
            {*/
                /* We have found one of the triangle that
                 intersects the line/ray
                 */
            
                
                //Where does it intersect?
                
                
                
                float *pt1 = vertex;
                float *pt2 = vertex2;
                float *pt3 = vertex3;
                
                if (pt1[0] == pt2[0] || pt1[1] == pt2[1])
                {
                    continue;
                }
                
                fpoint fpt1 = {pt1[0], pt1[1], pt1[2]};
                fpoint fpt2 = {pt2[0], pt2[1], pt2[2]};
                fpoint fpt3 = {pt3[0], pt3[1], pt3[2]};
                fpoint fpt4 = {vPosition.x, vPosition.y, vPosition.z};
                
                fpoint v = {l.x, l.y, l.z};
                fpoint* pt_int = malloc(sizeof(fpoint));
                
   
                if (check_intersect_tri(fpt1, fpt2, fpt3, fpt4, v, pt_int))
                {
                    float dist = (float)sqrt(powf(vPosition.x - pt_int->x,2) + powf(vPosition.y - pt_int->y, 2) + powf(vPosition.z - pt_int->z, 2));
                    if (dist < closestDistance)
                    {
                        if (found)
                            free(closest);
                        
                        closestDistance = dist;
                        
                        //Inside triangle
                        closest = malloc(sizeof(float)*3);
                        closest[0]=pt_int->x;
                        closest[1]=pt_int->y;
                        closest[2]=pt_int->z;
                        //}
                        //return closest;
                     
                    selectedBSP = mesh_index;
                    indexMesh = selectedBSP;
                    //indexHighlight = i;
                    selectedPIndex = i;
          
                    toPt[0] = pt_int->x;
                    toPt[1] = pt_int->y;
                    toPt[2] = pt_int->z;
                    
                    //now, where ON the triangle does it intersect?
                    
                    // calculate vectors from point f to vertices p1, p2 and p3:
                    CVector3 f = NewCVector3(pt_int->x, pt_int->y, pt_int->z);
                    CVector3 p1 = NewCVector3(pt1[0], pt1[1], pt1[2]);
                    CVector3 p2 = NewCVector3(pt2[0], pt2[1], pt2[2]);
                    CVector3 p3 = NewCVector3(pt3[0], pt3[1], pt3[2]);
                    
                    CVector3 f1 = SubtractTwoVectors(p1, f);
                    CVector3 f2 = SubtractTwoVectors(p2, f);
                    CVector3 f3 = SubtractTwoVectors(p3, f);
                    
                    // calculate the areas and factors (order of parameters doesn't matter):
                    float a = Magnitude(Cross(SubtractTwoVectors(p1, p2), SubtractTwoVectors(p1, p3)));
                     uva1 = Magnitude(Cross(f2, f3)) / a;
                     uva2 = Magnitude(Cross(f3, f1)) / a;
                     uva3 = Magnitude(Cross(f1, f2)) / a;
                    
                   

                    // find the uv corresponding to point f (uv1/uv2/uv3 are associated to p1/p2/p3):
                    //var uv: Vector2 = uv1 * a1 + uv2 * a2 + uv3 * a3;
                    
                    
                        found = YES;
                    }
                    
                    
                   
                }
                //}
        }

        }
        
            
            

        //}

    
        if (found)
        {
          
            isPainting= NO;
            //NSLog(@"%f %f %f", p.x, p.y, p.z);
            return selectedBSP;
        }

    
        //This function is broken but it'll do for now. We can always hide the mouse cursor. Find where this line intersects the bsp
        

    
    isPainting = NO;
    return -1;
    
    
}

- (void)trySelection:(NSPoint)downPoint shiftDown:(BOOL)shiftDown width:(NSNumber*)aw height:(NSNumber*)ah
{
	_lookup = NULL;
	
	// Thank you, http://glprogramming.com/red/chapter13.html

		
	/*SHARPY NOTE
	 -----------------
	 The try statement has been added to this function to prevent the application crashing.
	 It's really frustrating to lose your map.
	 
	 
	 ------------------*/
	
	// Adjustment that, for some reason, is necessary.
	//downPoint.x -= 25.0f;
	//downPoint.y -= 71.0f;
	
	GLsizei bufferSize = (GLsizei) ([_scenario vehicle_spawn_count] + 
									[_scenario scenery_spawn_count] + 
									[_scenario item_spawn_count] + 
									[_scenario multiplayer_flags_count] +
									[_scenario player_spawn_count] +
									[_scenario mach_spawn_count]+
									[_scenario encounter_count]+bsp_point_count);
    
    float some_non_genericvaluew = [aw floatValue];
    float some_non_genericvalueh = [ah floatValue];

	bufferSize += 50;
	
	GLuint nameBuf[bufferSize];
	GLuint tmpLookup[bufferSize];
	GLint viewport[4];
	GLuint hits;
	unsigned int i, j, z1, z2;
	
	if (!selections)
		selections = [[NSMutableArray alloc] init]; // Three times too big for meh.
	
	// Lookup is our name lookup table for the hits we get.
	_lookup = (GLuint *)tmpLookup;
	
	
	glGetIntegerv(GL_VIEWPORT,viewport);
	
	//glMatrixMode(GL_PROJECTION);
	
	glSelectBuffer(bufferSize,nameBuf);
    
	glRenderMode(GL_SELECT);
	glMatrixMode(GL_PROJECTION);
    
	glPushMatrix();
	glLoadIdentity();
	
	gluPickMatrix((GLdouble)downPoint.x + some_non_genericvaluew / 2,(GLdouble)downPoint.y + some_non_genericvalueh / 2,some_non_genericvaluew,some_non_genericvalueh,viewport);
	gluPerspective(45.0f,(GLfloat)(viewport[2] - viewport[0])/(GLfloat)(viewport[3] - viewport[1]),0.1f,400000.0f);
	
	glMatrixMode(GL_MODELVIEW);
    
	glColor4f(1.0f,1.0f,1.0f,1.0f);
        
	// This kick starts names
	[self renderAllMapObjects];
	
	
	
	//[self reshape];
	hits = glRenderMode(GL_RENDER);

	GLuint names, *ptr = (GLuint *)nameBuf;
	unsigned int type;
	BOOL hasFound = FALSE;
	
	if (hits == 0 || !shiftDown)
	{
		[self deselectAllObjects];
	}
    
    glPopMatrix();
    
	/*
	type = (long)(tableVal / 10000);
	index = (tableVal % 10000);
	*/
    
    NSLog(@"HIT: %d", hits);
    
        ignoreCSS = 0;
		for (i = 0; i < hits; i++)
		{
            
			names = *ptr;
            
    
			
            
			ptr++;
			z1 = (float)*ptr/0x7fffffff;
			ptr++;
			z2 = (float)*ptr/0x7fffffff;
			ptr++;
			for ( j = 0; j < names; j++)
			{
				if (z2 < selectDistance)
				{
					type = (unsigned int)(_lookup[*ptr] / MAX_SCENARIO_OBJECTS);
					if (type == _selectType || _selectType == s_all)
					{
						
						
						[self processSelection:(unsigned int)_lookup[*ptr]];
						hasFound = TRUE;
					}
					ptr++;
					
					if (![msel state])
					{
						if (hasFound)
							break;
					}
				}
			}
			if (![msel state])
			{
				if (hasFound)
					break;
			}
		}

	
	
	
	_lookup = NULL;
}


-(int)ID
{
	return haloProcessID;
}

- (void)deselectAllObjects
{
	//[self updateVehiclesLive];
	[spawne setAlphaValue:0.2];
	
	int x;
	for (x = 0; x < [_scenario vehicle_spawn_count]; x++)
		[_scenario vehi_spawns][x].isSelected = NO;
	for (x = 0; x < [_scenario scenery_spawn_count]; x++)
		[_scenario scen_spawns][x].isSelected = NO;
	for (x = 0; x < [_scenario item_spawn_count]; x++)
		[_scenario item_spawns][x].isSelected = NO;
	for (x = 0; x < [_scenario player_spawn_count]; x++)
		[_scenario spawns][x].isSelected = NO;
	for (x = 0; x < [_scenario encounter_count]; x++)
		[_scenario encounters][x].start_locs[0].isSelected = NO;
	for (x = 0; x < [_scenario multiplayer_flags_count]; x++)
		[_scenario netgame_flags][x].isSelected = NO;
	for (x = 0; x < [_scenario mach_spawn_count]; x++)
		[_scenario mach_spawns][x].isSelected = NO;
	for (x = 0; x < 16; x++)
		playercoords[(x * 8) + 4] = 0.0;
	
	
	
	if (editable)
	{
		for (x = 0; x < [[mapBSP mesh] coll_count]; x++)
			[[mapBSP mesh] collision_verticies][x].isSelected=NO;
		
		for (x = 0; x < bsp_point_count; x++)
			bsp_points[x].isSelected = NO;
	}
	
	[selectText setStringValue:[[NSNumber numberWithInt:0] stringValue]];
	[selectedName setStringValue:@""];
	[selectedType setStringValue:@""];
	[selectedAddress setStringValue:@""];
	[selections removeAllObjects];
	[selectedSwapButton removeAllItems];
}

#define kBitmask @"Bitmask"
#define kPopup @"Popup"
#define kName @"Name"
#define kType @"Type"
#define kData @"Data"
#define kSelection @"Selection"
#define kPointer @"Pointer"

-(IBAction)updateValueForUserInterface:(NSPopUpButton*)sender
{
    if ([selections count] == 1)
    {
        unsigned int nameLookup,
        type,
        index;
        
        nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
		type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
		index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
		
		long *pointer = [[sender toolTip] longLongValue];
        (*pointer) = (short)[sender indexOfItem:[sender selectedItem]];
    }
}

-(IBAction)updateValueForBITMASKUserInterface:(NSPopUpButton*)sender
{
    //pointer|new value
    if ([selections count] == 1)
    {
        unsigned int nameLookup,
        type,
        index;
        
        nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
		type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
		index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
		
        NSString *str = [sender toolTip];
        int d = (int)[[str substringFromIndex:[str rangeOfString:@"|"].location+1] intValue];
        
        long *pointer = [[str substringToIndex:[str rangeOfString:@"|"].location] longLongValue];
        short cVal = *pointer;
        
        //((sel>>(31-val)) & 1)
        
        if (cVal & (int)pow(2, (31-d)))
        {
            NSLog(@"Removing %ld %d %d", pointer, cVal, d);
            (*pointer) = (int)cVal & ~ (int)pow(2, (31-d));
        }
        else
        {
            NSLog(@"Adding %ld %d %d", pointer, cVal, d);
            (*pointer) = (int)cVal | (int)pow(2, (31-d)); //Add a value
        }
    }
}


char *int2bin(int a, char *buffer, int buf_size) {
    buffer += (buf_size - 1);

    int i;
    for (i = 31; i >= 0; i--) {
        *buffer-- = (a & 1) + '0';
        
        a >>= 1;
    }
    
    return buffer;
}

#define BUF_SIZE 33


-(void)createUserInterfaceForSettings:(NSArray*)settings;
{
    
    
    float maxWidth = 100;
    float border = 20;
    float elementHeight = 22;
    
    float totalHeight = border;
    
    //NSArray *subviews = [[settings_Window_Object contentView] subviews];
    
    [[settings_Window_Object contentView] setSubviews:[NSArray array]];
    
    int i;
    //for (i=0; i < [subviews count]; i++)
    //{
     //   [[subviews objectAtIndex:i] removeFromSuperview];
    //}
    
    
    
    NSRect old = [settings_Window_Object frame];
    NSRect new = NSMakeRect([settings_Window_Object frame].origin.x, settings_Window_Object.frame.origin.y, settings_Window_Object.frame.size.width, 2*border + (elementHeight+10)*([settings count]));
    
    [settings_Window_Object setFrame:NSMakeRect(new.origin.x - (new.size.width - old.size.width), new.origin.y - (new.size.height - old.size.height), new.size.width, new.size.height) display:YES];
    
    
    float y = [[settings_Window_Object contentView] bounds].size.height - border;
    
    
    
    for(i=0; i < [settings count]; i++)
    {
        float x = border;
        
        NSDictionary *data = [settings objectAtIndex:i];
        NSString *text = [data objectForKey:kName];

        y-=elementHeight;
        
        NSTextField *title = [[NSTextField alloc] initWithFrame:NSMakeRect(x, y, maxWidth, elementHeight)];
        [title setStringValue:text];
        [title sizeToFit];
        
        [title setBordered:NO];
        [title setEditable:NO];
        [title setSelectable:NO];
        [title setBackgroundColor:[NSColor clearColor]];
        
        x+=maxWidth;
        
        //Add the appropriate value
        if ([[data objectForKey:kType] isEqualToString:kPopup])
        {
            NSPopUpButton *button = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(x, y, [settings_Window_Object frame].size.width-border-x, elementHeight)];
            
            NSArray *kdata = [data objectForKey:kData];
            [button addItemsWithTitles:kdata];
            
            NSLog(@"%@: %d", text, [[data objectForKey:kSelection] intValue]);
        
            if ([[data objectForKey:kSelection] intValue] > 0 && [[data objectForKey:kSelection] intValue] < [kdata count])
                [button selectItemAtIndex:[[data objectForKey:kSelection] intValue]];
            
            [button setTarget:self];
            [button setAction:@selector(updateValueForUserInterface:)];
            
            if ([data objectForKey:kPointer])
                [button setToolTip:[NSString stringWithFormat:@"%ld", [[data objectForKey:kPointer] longValue]]];
            
            [[settings_Window_Object contentView] addSubview:button];
        }
        else if ([[data objectForKey:kType] isEqualToString:kBitmask])
        {
            NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(x, y, [settings_Window_Object frame].size.width-border-x, elementHeight)];
            [button setButtonType:NSSwitchButton];
            [button setTitle:@""];
            
            
            int val = [[data objectForKey:kData] intValue];
            int sel = [[data objectForKey:kSelection] intValue];
            

      
            //NSLog(@"%@: %d %d %d %d", text, val, sel, sel&val, ((sel>>(31-val)) & 1));
            
            
        
            if ((sel>>(31-val)) & 1)
            {
                [button setState:1];
            }
            
            [button setTarget:self];
            [button setAction:@selector(updateValueForBITMASKUserInterface:)];
            
            
            if ([data objectForKey:kPointer])
                [button setToolTip:[NSString stringWithFormat:@"%ld|%d", [[data objectForKey:kPointer] longValue], (int)val]];
            
            
            [[settings_Window_Object contentView] addSubview:button];
        }
        
        [[settings_Window_Object contentView] addSubview:title];
        
        totalHeight+=elementHeight+10;
        y-=10;
    }
    totalHeight+=border;
    
    [[settings_Window_Object contentView] setNeedsDisplay:YES];
    
    //Type0 Popup
    //Type1 Popup
    //Type2 Popup
    //Type3 Popup
    //Team Index Popup
    
    //settings_Window_Object
}

- (void)processSelection:(unsigned int)tableVal
{
	[spawne setAlphaValue:1.0];
	
	unsigned int type, index;
	long mapIndex;
	BOOL overrideString;
	
	type = (long)(tableVal / MAX_SCENARIO_OBJECTS);
	index = (tableVal % MAX_SCENARIO_OBJECTS);
	
	_selectFocus = tableVal;
	
	[selections addObject:[NSNumber numberWithLong:tableVal]];
	[selectText setStringValue:[[NSNumber numberWithInt:[selections count]] stringValue]];
	
	[selectedSwapButton removeAllItems];
	
	[_spawnEditor loadFocusedItemData:_selectFocus];
	
    NSLog(@"%d", type);
	switch (type)
	{
		case s_scenery:
			if (_selectType == s_all || _selectType == s_scenery)
			{
				/*
                if (ignoreCSS)
                {
                    [self deselectAllObjects];
                    break;
                }
				else if (is_css)
				{
					if (NSRunAlertPanel(@"Cascading Server Side (CSS)", @"If you move this object (scenery), other players will not be able to see it without the mod. Lag may occur when players collide with it.", @"Cancel", @"Continue", nil) == NSOKButton)
					{
                        ignoreCSS = 1;
						[self deselectAllObjects];
						break;
					}
				else
                {
					is_css = NO;
                }
				}
				*/
                
				[_scenario scen_spawns][index].isSelected = YES;
				mapIndex = [_scenario scen_references][[_scenario scen_spawns][index].numid].scen_ref.TagId;
				[self setRotationSliders:[_scenario scen_spawns][index].rotation[0] y:[_scenario scen_spawns][index].rotation[1] z:[_scenario scen_spawns][index].rotation[2]];
				[self setPositionSliders:[NSNumber numberWithFloat:[_scenario scen_spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario scen_spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario scen_spawns][index].coord[2]]];
				[selectedSwapButton addItemsWithTitles:(NSArray *)[_scenario scenTagArray]];
			}
			break;
		case s_playerspawn:
			if (_selectType == s_all || _selectType == s_playerspawn)
			{
                
#ifdef MACVERSION
                NSArray *gametypeList = @[@"None", @"CTF", @"Slayer", @"Oddball", @"King of the Hill", @"Race", @"Terminator", @"Stub", @"Ignored 1", @"Ignored 2", @"Ignored 3", @"Ignored 4", @"All Games", @"All except CTF", @"All except Race and CTF"];
                NSArray *settings = @[@{kName:@"Gametype 1", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario spawns][index].type1], kPointer:[NSNumber numberWithLong:&([_scenario spawns][index].type1)]},
                                      @{kName:@"Gametype 2", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario spawns][index].type2], kPointer:[NSNumber numberWithLong:&([_scenario spawns][index].type2)]},
                                      @{kName:@"Gametype 3", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario spawns][index].type3], kPointer:[NSNumber numberWithLong:&([_scenario spawns][index].type3)]},
                                      @{kName:@"Gametype 4", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario spawns][index].type4], kPointer:[NSNumber numberWithLong:&([_scenario spawns][index].type4)]},
                                      @{kName:@"Team Index", kType:kPopup, kData:@[@"Red", @"Blue", @"2", @"3"], kSelection:[NSNumber numberWithShort:[_scenario spawns][index].team_index], kPointer:[NSNumber numberWithLong:&([_scenario spawns][index].team_index)]}];
                
                [self performSelectorOnMainThread:@selector(createUserInterfaceForSettings:) withObject:settings waitUntilDone:YES];
      #endif
                
				[_scenario spawns][index].isSelected = YES;
				switch ([_scenario spawns][index].team_index)
				{
					case 0:
						[selectedType setStringValue:@"Red Team"];
						break;
					case 1:
						[selectedType setStringValue:@"Blue Team"];
						break;
                    case 2:
						[selectedType setStringValue:@"2"];
						break;
                    case 3:
						[selectedType setStringValue:@"3"];
						break;
				}
				[self setRotationSliders:[_scenario spawns][index].rotation y:0 z:0];
                [self setPositionSliders:[NSNumber numberWithFloat:[_scenario spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario spawns][index].coord[2]]];
				overrideString = TRUE;

			}
			break;
		case s_encounter:
			if (_selectType == s_all)
			{
				[_scenario encounters][index].start_locs[0].isSelected = YES;
				switch ([_scenario encounters][index].start_locs[0].team_index)
				{
					case 0:
						[selectedType setStringValue:@"Red Team"];
						break;
					case 1:
						[selectedType setStringValue:@"AI Encounter"];
						break;
				}
				[self setRotationSliders:[_scenario encounters][index].start_locs[0].rotation y:0 z:0];
                //[self setPositionSliders:[NSNumber numberWithFloat:[_scenario encounters][index].start_locs.coord[0]] y:[NSNumber numberWithFloat:[_scenario encounters][index].start_locs.coord[1]] z:[NSNumber numberWithFloat:[_scenario encounters][index].coord[2]]];
				overrideString = TRUE;
			}
			break;
		case s_mapobject:
			if (_selectType == s_all || _selectType == s_mapobject)
			{
				map_objects[index].isSelected = YES;
				[selectedType setStringValue:[NSString stringWithFormat:@"%d",map_objects[index].address]];
				[self setRotationSliders:0 y:0 z:0];
                //[self setPositionSliders:[_scenario scen_spawns][index].coord[0] y:[_scenario scen_spawns][index].coord[1] z:[_scenario scen_spawns][index].coord[2]];
			}
			break;
		case s_vehicle:
			if (_selectType == s_all || _selectType == s_vehicle)
			{
                //88 //56
                
                #ifdef MACVERSION
                short *pointer;
                pointer = &([_scenario vehi_spawns][index].unknown2[14]);
                pointer = pointer + 1;
                
                NSArray *settings = @[@{kName:@"Team Index", kType:kPopup, kData:@[@"Red", @"Blue"], kSelection:[NSNumber numberWithShort:[_scenario vehi_spawns][index].unknown2[14]], kPointer:[NSNumber numberWithLong:&([_scenario vehi_spawns][index].unknown2[14])]},
                                      @{kName:@"CTF", kType:kBitmask, kData:[NSNumber numberWithInteger:30], kSelection:[NSNumber numberWithInteger:*pointer], kPointer:[NSNumber numberWithLong:pointer]},
                                      @{kName:@"Slayer", kType:kBitmask, kData:[NSNumber numberWithInteger:31], kSelection:[NSNumber numberWithInteger:*pointer], kPointer:[NSNumber numberWithLong:pointer]},
                                      @{kName:@"King", kType:kBitmask, kData:[NSNumber numberWithInteger:29], kSelection:[NSNumber numberWithInteger:*pointer], kPointer:[NSNumber numberWithLong:pointer]},
                                      @{kName:@"Oddball", kType:kBitmask, kData:[NSNumber numberWithInteger:28], kSelection:[NSNumber numberWithInteger:*pointer], kPointer:[NSNumber numberWithLong:pointer]}];
                [self performSelectorOnMainThread:@selector(createUserInterfaceForSettings:) withObject:settings waitUntilDone:YES];
                #endif
				[_scenario vehi_spawns][index].isSelected = YES;
				mapIndex = [_scenario vehi_references][[_scenario vehi_spawns][index].numid].vehi_ref.TagId;
				[self setRotationSliders:[_scenario vehi_spawns][index].rotation[0] y:[_scenario vehi_spawns][index].rotation[1] z:[_scenario vehi_spawns][index].rotation[2]];
				[self setPositionSliders:[NSNumber numberWithFloat:[_scenario vehi_spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario vehi_spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario vehi_spawns][index].coord[2]]];
				[selectedSwapButton addItemsWithTitles:(NSArray *)[_scenario vehiTagArray]];

			}
			break;
		case s_machine:
			if (_selectType == s_all || _selectType == s_machine)
			{
                #ifdef MACVERSION
                
                NSArray *shorts = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10",
                                    @"11", @"12", @"13", @"14", @"15", @"16", @"17", @"18", @"19", @"20",
                                    @"21", @"22", @"23", @"24", @"25", @"26", @"27", @"28", @"29", @"30",
                                    @"31", @"32", @"33", @"34", @"35", @"36", @"37", @"38", @"39", @"40",
                                    @"41", @"42", @"43", @"44", @"45", @"46", @"47", @"48", @"49", @"50",
                                    @"51", @"52", @"53", @"54", @"55", @"56", @"57", @"58", @"59", @"60"];
                NSArray *settings = @[@{kName:@"Power Group", kType:kPopup, kData:shorts, kSelection:[NSNumber numberWithShort:[_scenario mach_spawns][index].powerGroup], kPointer:[NSNumber numberWithLong:&([_scenario mach_spawns][index].powerGroup)]},
                                      @{kName:@"Position Group", kType:kPopup, kData:shorts, kSelection:[NSNumber numberWithShort:[_scenario mach_spawns][index].positionGroup], kPointer:[NSNumber numberWithLong:&([_scenario mach_spawns][index].positionGroup)]}
                                      ];
                [self performSelectorOnMainThread:@selector(createUserInterfaceForSettings:) withObject:settings waitUntilDone:YES];
                #endif
                
				[_scenario mach_spawns][index].isSelected = YES;
				mapIndex = [_scenario mach_references][[_scenario mach_spawns][index].numid].machTag.TagId;
				[self setRotationSliders:[_scenario mach_spawns][index].rotation[0] y:[_scenario mach_spawns][index].rotation[1] z:[_scenario mach_spawns][index].rotation[2]];
                [self setPositionSliders:[NSNumber numberWithFloat:[_scenario mach_spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario mach_spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario mach_spawns][index].coord[2]]];
				[selectedSwapButton addItemsWithTitles:(NSArray *)[_scenario machTagArray]];

			}
			break;
		case s_netgame:
			if (_selectType == s_all || _selectType == s_netgame)
			{
                #ifdef MACVERSION
                NSArray *gametypeList = @[@"CTF Flag", @"CTF Vehicle", @"Oddball Spawn", @"Race Track", @"Race Vehicle", @"Vegas Bank", @"Teleport From", @"Teleport To", @"Hill Flag"];
                NSArray *settings = nil;
                NSArray *channels = @[@"Alpha", @"Bravo", @"Charlie", @"Delta", @"Echo", @"Foxtrot", @"Golf", @"Hotel", @"India", @"Juliet", @"Kilo",
                                      @"Lima", @"Mike", @"November", @"Oscar", @"Papa", @"Quebec", @"Romeo", @"Sierra", @"Tango", @"Uniform", @"Victor", @"Whiskey", @"X-ray", @"Yankee", @"Zulu"];
                NSArray *teams = @[@"Red", @"Blue"];
                
                NSMutableArray *teamIndicies = [[NSMutableArray alloc] init];
                
                int a;
                for (a=0; a < 255; a++)
                {
                    [teamIndicies addObject:[NSString stringWithFormat:@"%d", a]];
                }
                
               // NSArray *teamIndicies = @[@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11", @"12", @"13", @"14", @"15", @"16", @"17", @"18", @"19", @"20"];
                
                switch ([_scenario netgame_flags][index].type)
				{
					case teleporter_entrance:
						settings = @[@{kName:@"Type", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario netgame_flags][index].type], kPointer:[NSNumber numberWithLong:&([_scenario netgame_flags][index].type)]},
                                     @{kName:@"Channel", kType:kPopup, kData:channels, kSelection:[NSNumber numberWithShort:[_scenario netgame_flags][index].team_index], kPointer:[NSNumber numberWithLong:&([_scenario netgame_flags][index].team_index)]}];
						break;
					case teleporter_exit:
						settings = @[@{kName:@"Type", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario netgame_flags][index].type], kPointer:[NSNumber numberWithLong:&([_scenario netgame_flags][index].type)]},
                                     @{kName:@"Channel", kType:kPopup, kData:channels, kSelection:[NSNumber numberWithShort:[_scenario netgame_flags][index].team_index], kPointer:[NSNumber numberWithLong:&([_scenario netgame_flags][index].team_index)]}];
						break;
                    case hill_flag:
                        settings = @[@{kName:@"Type", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario netgame_flags][index].type], kPointer:[NSNumber numberWithLong:&([_scenario netgame_flags][index].type)]},
                                     @{kName:@"Hill Index", kType:kPopup, kData:teamIndicies, kSelection:[NSNumber numberWithShort:[_scenario netgame_flags][index].team_index], kPointer:[NSNumber numberWithLong:&([_scenario netgame_flags][index].team_index)]}];
                        break;
                    case race_track:
                        settings = @[@{kName:@"Type", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario netgame_flags][index].type], kPointer:[NSNumber numberWithLong:&([_scenario netgame_flags][index].type)]},
                                     @{kName:@"Track Index", kType:kPopup, kData:teamIndicies, kSelection:[NSNumber numberWithShort:[_scenario netgame_flags][index].team_index], kPointer:[NSNumber numberWithLong:&([_scenario netgame_flags][index].team_index)]}];
                        break;
					default:
                        settings = @[@{kName:@"Type", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario netgame_flags][index].type], kPointer:[NSNumber numberWithLong:&([_scenario netgame_flags][index].type)]},
                                     @{kName:@"Team Index", kType:kPopup, kData:teams, kSelection:[NSNumber numberWithShort:[_scenario netgame_flags][index].team_index], kPointer:[NSNumber numberWithLong:&([_scenario netgame_flags][index].team_index)]}];
                        
                        break;
                }
                
                
                
                if (settings != nil)
                    [self performSelectorOnMainThread:@selector(createUserInterfaceForSettings:) withObject:settings waitUntilDone:YES];
                #endif
				[_scenario netgame_flags][index].isSelected = YES;
				switch ([_scenario netgame_flags][index].type)
				{
					case teleporter_entrance:
						[selectedType setStringValue:@"Teleporter Entrance"];
						break;
					case teleporter_exit:
						[selectedType setStringValue:@"Teleporter Exit"];
						break;
					case ctf_flag:
						[selectedType setStringValue:@"CTF Flag"];
						break;
					case ctf_vehicle:
						[selectedType setStringValue:@"CTF Vehicle"];
						break;
					case oddball:
						[selectedType setStringValue:@"Oddball"];
						break;
					case race_track:
						[selectedType setStringValue:@"Race Track Marker"];
						break;
					case race_vehicle:
						[selectedType setStringValue:@"Race Vehicle"];
						break;
					case vegas_bank:
						[selectedType setStringValue:@"Vegas Bank?"];
						break;
					case hill_flag:
						[selectedType setStringValue:@"KotH Hill Marker"];
						break;
				}
				[self setRotationSliders:[_scenario netgame_flags][index].rotation y:0 z:0];
                [self setPositionSliders:[NSNumber numberWithFloat:[_scenario netgame_flags][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario netgame_flags][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario netgame_flags][index].coord[2]]];
				overrideString = YES;

			}
			break;
		case s_item:
			if (_selectType == s_all || _selectType == s_item)
			{
                #ifdef MACVERSION
                NSLog(@"%ld", [_scenario item_spawns][index].bitmask32);
                NSArray *gametypeList = @[@"None", @"CTF", @"Slayer", @"Oddball", @"King of the Hill", @"Race", @"Terminator", @"Stub", @"Ignored 1", @"Ignored 2", @"Ignored 3", @"Ignored 4", @"All Games", @"All except CTF", @"All except Race and CTF"];
                NSArray *settings = @[@{kName:@"Levitate", kType:kPopup, kData:@[@"No", @"Yes"], kSelection:[NSNumber numberWithShort:[_scenario item_spawns][index].bitmask32], kPointer:[NSNumber numberWithLong:&([_scenario item_spawns][index].bitmask32)]},
                                      @{kName:@"Gametype 1", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario item_spawns][index].type1], kPointer:[NSNumber numberWithLong:&([_scenario item_spawns][index].type1)]},
                                      @{kName:@"Gametype 2", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario item_spawns][index].type2], kPointer:[NSNumber numberWithLong:&([_scenario item_spawns][index].type2)]},
                                      @{kName:@"Gametype 3", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario item_spawns][index].type3], kPointer:[NSNumber numberWithLong:&([_scenario item_spawns][index].type3)]},
                                      @{kName:@"Gametype 4", kType:kPopup, kData:gametypeList, kSelection:[NSNumber numberWithShort:[_scenario item_spawns][index].type4], kPointer:[NSNumber numberWithLong:&([_scenario item_spawns][index].type4)]},
                                      @{kName:@"Team Index", kType:kPopup, kData:@[@"Red", @"Blue"], kSelection:[NSNumber numberWithShort:[_scenario item_spawns][index].team_index], kPointer:[NSNumber numberWithLong:&([_scenario item_spawns][index].team_index)]}];
                [self createUserInterfaceForSettings:settings];
                #endif
				[_scenario item_spawns][index].isSelected = YES;
				mapIndex = [_scenario item_spawns][index].itmc.TagId;
				[self setRotationSliders:[_scenario item_spawns][index].yaw y:0 z:0];
				[self setPositionSliders:[NSNumber numberWithFloat:[_scenario item_spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario item_spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario item_spawns][index].coord[2]]];
				
				[selectedSwapButton addItemsWithTitles:(NSArray *)[_mapfile itmcList]];

			}
			break;
		case s_playerobject:
			if (_selectType == s_all || _selectType == s_item)
			{
				//LIVE
				playercoords[(index * 8) + 4] = 1.0;
				[self setRotationSliders:0 y:0 z:0];
				//[self setPositionSliders:[_scenario scen_spawns][index].coord[0] y:[_scenario scen_spawns][index].coord[1] z:[_scenario scen_spawns][index].coord[2]];
				[selectedType setStringValue:[new_characters objectAtIndex:index]];
			}
			break;
		case s_bsppoint:
			if (_selectType == s_all || _selectType == s_item)
			{
                NSLog(@"BSP POINT");
				bsp_points[index].isSelected = YES;
				
				//LIVE
				[self setRotationSliders:0 y:0 z:0];
                //[self setPositionSliders:[_scenario scen_spawns][index].coord[0] y:[_scenario scen_spawns][index].coord[1] z:[_scenario scen_spawns][index].coord[2]];
				[selectedName setStringValue:@"BSP Point"];
			}
			break;
		case s_colpoint:
			if (_selectType == s_all || _selectType == s_item)
			{
				[[mapBSP mesh] collision_verticies][index].isSelected = YES;
				
				//LIVE
				[self setRotationSliders:0 y:0 z:0];
                //[self setPositionSliders:[_scenario scen_spawns][index].coord[0] y:[_scenario scen_spawns][index].coord[1] z:[_scenario scen_spawns][index].coord[2]];
				[selectedName setStringValue:@"Collision Point"];
			}
			break;
	}
	if (type == s_playerspawn)
		[selectedName setStringValue:@"Player Spawn"];
	else if (type == s_netgame)
		[selectedName setStringValue:@"Netgame Flag"];
	else if (type == s_playerobject)
		[selectedName setStringValue:[new_characters objectAtIndex:index]];
	else
		[selectedName setStringValue:[[_mapfile tagForId:mapIndex] tagName]];
		 
	if (type != s_netgame && type != s_playerspawn && type != s_playerobject)
		[selectedType setStringValue:[[NSString stringWithCString:[[_mapfile tagForId:mapIndex] tagClassHigh]] substringToIndex:4]];
	else if (overrideString)
		return; // lol, quick fix hur
	else
		[selectedType setStringValue:@"Non-Tag Object"];
}
- (void)fillSelectionInfo
{
	int type = (long)(_selectFocus / MAX_SCENARIO_OBJECTS);
	int index = (_selectFocus % MAX_SCENARIO_OBJECTS);
	long mapIndex;
	
	switch (type)
	{
		case s_scenery:
			if (_selectType == s_all || _selectType == s_scenery)
			{
				[_scenario scen_spawns][index].isSelected = YES;
				mapIndex = [_scenario scen_references][[_scenario scen_spawns][index].numid].scen_ref.TagId;
				[selectedName setStringValue:[[_mapfile tagForId:mapIndex] tagName]];
				[self setRotationSliders:[_scenario scen_spawns][index].rotation[0] y:[_scenario scen_spawns][index].rotation[1] z:[_scenario scen_spawns][index].rotation[2]];
                [self setPositionSliders:[NSNumber numberWithFloat:[_scenario scen_spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario scen_spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario scen_spawns][index].coord[2]]];
			}
			break;
		case s_item:
			if (_selectType == s_all || _selectType == s_item)
			{
				[_scenario item_spawns][index].isSelected = YES;
				mapIndex = [_scenario item_spawns][index].itmc.TagId;
				[self setRotationSliders:[_scenario item_spawns][index].yaw y:0 z:0];
                [self setPositionSliders:[NSNumber numberWithFloat:[_scenario item_spawns][index].coord[0]] y:[NSNumber numberWithFloat:[_scenario item_spawns][index].coord[1]] z:[NSNumber numberWithFloat:[_scenario item_spawns][index].coord[2]]];
			}
			break;
	}
}
/*

*	Object Translation

*/

-(IBAction)MovetoBSD:(id)sender;
{
	//[self DropCamera:sender];
	
	
	unsigned int	i,
	nameLookup,
	type,
	index;
	
	for (i = 0; i < [selections count]; i++)
	{
		nameLookup = [[selections objectAtIndex:i] unsignedIntValue];
		type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
		index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
		
		
		
		switch (type)
		{
			case s_vehicle:
				
				[self centerObj:[_scenario vehi_spawns][index].coord move:nil];
				break;
			case s_scenery:
				[self centerObj:[_scenario scen_spawns][index].coord move:nil];
				break;
			case s_playerspawn:
				[self centerObj:[_scenario spawns][index].coord move:nil];
				break;
			case s_netgame:
				[self centerObj:[_scenario netgame_flags][index].coord move:nil];
				break;
			case s_item:
				[self centerObj:[_scenario item_spawns][index].coord move:nil];
				break;
			case s_machine:
				[self centerObj:[_scenario mach_spawns][index].coord move:nil];
				break;
		}
	}
	
}

- (void)calculatePlayer:(int)player move:(float *)move
{
	
	int offsetToPlayerXCoordinate = 0x5C;
	int offsetToPlayerYCoordinate = 0x5C + 0x4;
	int offsetToPlayerZCoordinate = 0x5C + 0x4 + 0x4;
	
	
	int haloObjectPointer = [self getDynamicPlayer:player];
	
	int xCoord = [self readFloat:(haloObjectPointer + offsetToPlayerXCoordinate)];
	int yCoord = [self readFloat:(haloObjectPointer + offsetToPlayerYCoordinate)];
	int zCoord = [self readFloat:(haloObjectPointer + offsetToPlayerZCoordinate)];
	
	/* God damn this is being a bitch with the vector functions */
	CVector3 viewDirection, cross;
	
	// Z-axis movement, return after done since we don't want this to conflict with xy plane movement.
	if (move[2])
	{
		zCoord += (move[2] * s_acceleration);
		return;
	}
	
	//viewDirection = (CVector3)SubtractTwoVectors(NewCVector3([_camera position][0],[_camera position][1],[_camera position][2]),NewCVector3(coord[0], coord[1], coord[2]));
	viewDirection.x = [_camera position][0] - xCoord;
	viewDirection.y = [_camera position][1] - yCoord;
	viewDirection.z = [_camera position][2] - zCoord;
	
	
	xCoord += (s_acceleration * move[1] * viewDirection.x);
	yCoord += (s_acceleration * move[1] * viewDirection.y);
	
	//cross = (CVector3)Cross(NewCVector3(0,0,1),viewDirection);
	cross.x = ((0 * viewDirection.z) - (1 * viewDirection.y));
	cross.y = ((1 * viewDirection.x) - (0 * viewDirection.z));
	
	
	xCoord += (s_acceleration * move[0] * cross.x);
	yCoord += (s_acceleration * move[0] * cross.y);
	
	[self writeFloat:xCoord to:(haloObjectPointer + offsetToPlayerXCoordinate)];
	[self writeFloat:yCoord to:(haloObjectPointer + offsetToPlayerYCoordinate)];
	[self writeFloat:zCoord to:(haloObjectPointer + offsetToPlayerZCoordinate)];
}

-(void)movePlayer:(int)playern move:(float *)mo
{	
	int offsetToPlayerXCoordinate = 0x5C;
	int offsetToPlayerYCoordinate = 0x5C + 0x4;
	int offsetToPlayerZCoordinate = 0x5C + 0x4 + 0x4;
	
	int haloObjectPointer = [self getDynamicPlayer:playern];
	
	int xCoord = [self readFloat:(haloObjectPointer + offsetToPlayerXCoordinate)];
	int yCoord = [self readFloat:(haloObjectPointer + offsetToPlayerYCoordinate)];
	int zCoord = [self readFloat:(haloObjectPointer + offsetToPlayerZCoordinate)];
	
	xCoord = xCoord + mo[0];
	yCoord = yCoord + mo[1];
	zCoord = zCoord + mo[2];
	
	[self writeFloat:xCoord to:(haloObjectPointer + offsetToPlayerXCoordinate)];
	[self writeFloat:yCoord to:(haloObjectPointer + offsetToPlayerYCoordinate)];
	[self writeFloat:zCoord to:(haloObjectPointer + offsetToPlayerZCoordinate)];
}

- (void)performTranslation:(NSPoint)downPoint zEdit:(BOOL)zEdit
{
	// Ok, lets see exactly where it is that the mouse is down and see what the delta value is.
	float move[3];
	unsigned int	i,
					nameLookup,
					type,
					index;
	
	move[2] = 0;
	
	if (!zEdit)
	{
		move[0] = (downPoint.x - prevDown.x);
		move[1] = (downPoint.y - prevDown.y);
		move[2] = 0;
	}
	else
	{
		move[0] = 0;
		move[1] = 0;
		move[2] = (downPoint.y - prevDown.y)/10;
	}
	
	// Lets proportion the changes.
	move[0] /= 200;
	move[1] /= 200;
	move[2] /= 10;
	
	// correct something now
	move[1] *= -1;
	
	if ([selections count] > 1)
	{
		//[self calculateTranslation:multi_move move:move];
		float *rMove;
		nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
		type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
		index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
		
		/*
			Bad code standards from the start means that I have to explicetly choose the array of spawns to edit
			This looks so shitty
		*/
		switch (type)
		{
			case s_vehicle:
				rMove = [self getTranslation:[_scenario vehi_spawns][index].coord move:move];
				break;
			case s_scenery:
				rMove = [self getTranslation:[_scenario scen_spawns][index].coord move:move];
				break;
			case s_playerspawn:
				rMove = [self getTranslation:[_scenario spawns][index].coord move:move];
				break;
			case s_netgame:
				rMove = [self getTranslation:[_scenario netgame_flags][index].coord move:move];
				break;
			case s_item:
				rMove = [self getTranslation:[_scenario item_spawns][index].coord move:move];
				break;
			case s_machine:
				rMove = [self getTranslation:[_scenario mach_spawns][index].coord move:move];
				break;
			case s_bsppoint:
				rMove = [self getTranslation:bsp_points[index].coord move:move];
				break;
			case s_colpoint:
			{
				float *coord = malloc(12);
				coord[0]=[[mapBSP mesh] collision_verticies][index].x;
				coord[1]=[[mapBSP mesh] collision_verticies][index].y;
				coord[2]=[[mapBSP mesh] collision_verticies][index].z;
				rMove = [self getTranslation:coord move:move];
				free(coord);
				break;
			}
			case s_playerobject:
				rMove = [self getPTranslation:index move:move];
				break;
				
		}
		
		/*
			Now we apply these moves.
			
			Oh my god this code looks like shit. 
			
			Sorry about this, when I began writing this program I didn't think it was necessary to
			have a way to ambiguously access scenario attributes.
		*/
		
		
		
		for (i = 0; i < [selections count]; i++)
		{
			nameLookup = [[selections objectAtIndex:i] unsignedIntValue];
			type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
			index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
			
			
			
			switch (type)
			{
				case s_vehicle:
					//[self centerObj:[_scenario vehi_spawns][index].coord move:rMove];
					[self applyMove:[_scenario vehi_spawns][index].coord move:rMove];
					break;
				case s_scenery:
					[self applyMove:[_scenario scen_spawns][index].coord move:rMove];
					break;
				case s_playerspawn:
					[self applyMove:[_scenario spawns][index].coord move:rMove];
					break;
				case s_netgame:
					[self applyMove:[_scenario netgame_flags][index].coord move:rMove];
					break;
				case s_item:
					[self applyMove:[_scenario item_spawns][index].coord move:rMove];
					break;
				case s_machine:
					[self applyMove:[_scenario mach_spawns][index].coord move:rMove];
					break;
				case s_bsppoint:
					[self applyMove:bsp_points[index].coord move:rMove];
					[self updateBSPPoint:bsp_points[index].coord index:bsp_points[index].index amindex:bsp_points[index].amindex mesh:bsp_points[index].mesh];
					break;
				case s_colpoint:
				{
					float *coord = malloc(12);
					coord[0]=[[mapBSP mesh] collision_verticies][index].x;
					coord[1]=[[mapBSP mesh] collision_verticies][index].y;
					coord[2]=[[mapBSP mesh] collision_verticies][index].z;
					[self applyMove:coord move:rMove];
					[[mapBSP mesh] collision_verticies][index].x = coord[0];
					[[mapBSP mesh] collision_verticies][index].y = coord[1];
					[[mapBSP mesh] collision_verticies][index].z = coord[2];
					free(coord);
					break;
				}
				case s_encounter:
					[self applyMove:[_scenario encounters][index].start_locs[0].coord move:rMove];
					break;
				case s_playerobject:
					[self movePlayer:index move:rMove];
					break;
			}
		}
		
		free(rMove);
	}
	else if ([selections count] == 1)
	{
		nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
		type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
		index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);
		
		switch (type)
		{
			case s_vehicle:
				[self calculateTranslation:[_scenario vehi_spawns][index].coord move:move];
				break;
			case s_scenery:
				[self calculateTranslation:[_scenario scen_spawns][index].coord move:move];
				break;
			case s_playerspawn:
				[self calculateTranslation:[_scenario spawns][index].coord move:move];
				break;
			case s_encounter:
				[self calculateTranslation:[_scenario encounters][index].start_locs[0].coord move:move];
				break;
			case s_netgame:
				[self calculateTranslation:[_scenario netgame_flags][index].coord move:move];
				break;
			case s_item:
				[self calculateTranslation:[_scenario item_spawns][index].coord move:move];
				break;
			case s_bsppoint:
				[self calculateTranslation:bsp_points[index].coord move:move];
				[self updateBSPPoint:bsp_points[index].coord index:bsp_points[index].index amindex:bsp_points[index].amindex mesh:bsp_points[index].mesh];
				break;
			case s_colpoint:
			{
				float *coord = malloc(12);
				coord[0]=[[mapBSP mesh] collision_verticies][index].x;
				coord[1]=[[mapBSP mesh] collision_verticies][index].y;
				coord[2]=[[mapBSP mesh] collision_verticies][index].z;
				[self calculateTranslation:coord move:move];
				[[mapBSP mesh] collision_verticies][index].x = coord[0];
				[[mapBSP mesh] collision_verticies][index].y = coord[1];
				[[mapBSP mesh] collision_verticies][index].z = coord[2];
				free(coord);
				
				break;
			}
			case s_machine:
				[self calculateTranslation:[_scenario mach_spawns][index].coord move:move];
				break;
			case s_playerobject:
				[self calculatePlayer:index move:move];
		}
	}
	
    
    
    
	
	[_spawnEditor loadFocusedItemData:_selectFocus];
}

-(void)updateBSPPoint:(float*)coord index:(int)ind amindex:(int)amindex mesh:(int)me
{
	
	
	SUBMESH_INFO *pMesh;
	pMesh = [mapBSP GetActiveBspPCSubmesh:me];
	
	pMesh->pVert[amindex].vertex_k[0] = coord[0];
	pMesh->pVert[amindex].vertex_k[1] = coord[1];
	pMesh->pVert[amindex].vertex_k[2] = coord[2];

}

- (void)calculateTranslation:(float *)coord move:(float *)move
{
	/* God damn this is being a bitch with the vector functions */
	CVector3 viewDirection, cross;
	
	// Z-axis movement, return after done since we don't want this to conflict with xy plane movement.
	if (move[2])
	{
		coord[2] += (move[2] * s_acceleration);
		return;
	}
	
	//viewDirection = (CVector3)SubtractTwoVectors(NewCVector3([_camera position][0],[_camera position][1],[_camera position][2]),NewCVector3(coord[0], coord[1], coord[2]));
	viewDirection.x = [_camera position][0] - coord[0];
	viewDirection.y = [_camera position][1] - coord[1];
	viewDirection.z = [_camera position][2] - coord[2];
	
	
	coord[0] += (s_acceleration * move[1] * viewDirection.x);
	coord[1] += (s_acceleration * move[1] * viewDirection.y);
	
	//cross = (CVector3)Cross(NewCVector3(0,0,1),viewDirection);
	cross.x = ((0 * viewDirection.z) - (1 * viewDirection.y));
	cross.y = ((1 * viewDirection.x) - (0 * viewDirection.z));
	
	
	coord[0] += (s_acceleration * move[0] * cross.x);
	coord[1] += (s_acceleration * move[0] * cross.y);
}
- (float *)getTranslation:(float *)coord move:(float *)move
{
	CVector3 viewDirection, cross;
	float *rMove;
	
	rMove = malloc(sizeof(float) * 3);
	
	rMove[0] = rMove[1] = rMove[2] = 0.0f;
	
	if (move[2])
	{
		rMove[2] = (move[2] * s_acceleration);
		return rMove;
	}
	
	viewDirection.x = [_camera position][0] - coord[0];
	viewDirection.y = [_camera position][1] - coord[1];
	viewDirection.z = [_camera position][2] - coord[2];
	
	rMove[0] = (s_acceleration * move[1] * viewDirection.x);
	rMove[1] = (s_acceleration * move[1] * viewDirection.y);
	
	cross.x = ((0 * viewDirection.z) - (1 * viewDirection.y));
	cross.y = ((1 * viewDirection.x) - (0 * viewDirection.z));
	
	rMove[0] += (s_acceleration * move[0] * cross.x);
	rMove[1] += (s_acceleration * move[0] * cross.y);
	
	return rMove;
}

- (float *)getPTranslation:(int)index move:(float *)move
{
	CVector3 viewDirection, cross;
	float *rMove;
	
	rMove = malloc(sizeof(float) * 3);
	
	rMove[0] = rMove[1] = rMove[2] = 0.0f;
	
	if (move[2])
	{
		rMove[2] = (move[2] * s_acceleration);
		return rMove;
	}
	
	int offsetToPlayerXCoordinate = 0x5C;
	int offsetToPlayerYCoordinate = 0x5C + 0x4;
	int offsetToPlayerZCoordinate = 0x5C + 0x4 + 0x4;
	
	int haloObjectPointer = [self getDynamicPlayer:index];
	
	int xCoord = [self readFloat:(haloObjectPointer + offsetToPlayerXCoordinate)];
	int yCoord = [self readFloat:(haloObjectPointer + offsetToPlayerYCoordinate)];
	int zCoord = [self readFloat:(haloObjectPointer + offsetToPlayerZCoordinate)];
	
	viewDirection.x = [_camera position][0] - xCoord;
	viewDirection.y = [_camera position][1] - yCoord;
	viewDirection.z = [_camera position][2] - zCoord;
	
	rMove[0] = (s_acceleration * move[1] * viewDirection.x);
	rMove[1] = (s_acceleration * move[1] * viewDirection.y);
	
	cross.x = ((0 * viewDirection.z) - (1 * viewDirection.y));
	cross.y = ((1 * viewDirection.x) - (0 * viewDirection.z));
	
	rMove[0] += (s_acceleration * move[0] * cross.x);
	rMove[1] += (s_acceleration * move[0] * cross.y);
	
	return rMove;
}



//[self centerObj:[_scenario vehi_spawns][index].coord move:rMove];
- (void)centerObj:(float *)coord move:(float *)move
{
	float x,y,z;
	[mapBSP GetActiveBspCentroid:&x center_y:&y center_z:&z];
	
	coord[0] = x;
	coord[1] = y;
	coord[2] = z;
}
//renderPlayerCharacter
-(void)getPlayers
{

}

- (void)applyMove:(float *)coord move:(float *)move
{
	coord[0] += move[0];
	coord[1] += move[1];
	coord[2] += move[2];
}

- (void)moveFocusedItem:(float)x y:(float)y z:(float)z
{
	int type, index;
	type = (_selectFocus / MAX_SCENARIO_OBJECTS);
	index = (_selectFocus % MAX_SCENARIO_OBJECTS);
	
	switch (type)
	{
		case s_vehicle:
			[_scenario vehi_spawns][index].coord[0] = x;
			[_scenario vehi_spawns][index].coord[1] = y;
			[_scenario vehi_spawns][index].coord[2] = z;
			break;
		case s_scenery:
			[_scenario scen_spawns][index].coord[0] = x;
			[_scenario scen_spawns][index].coord[1] = y;
			[_scenario scen_spawns][index].coord[2] = z;
			break;
		case s_playerspawn:
			[_scenario spawns][index].coord[0] = x;
			[_scenario spawns][index].coord[1] = y;
			[_scenario spawns][index].coord[2] = z;
			break;
		case s_netgame:
			[_scenario netgame_flags][index].coord[0] = x;
			[_scenario netgame_flags][index].coord[1] = y;
			[_scenario netgame_flags][index].coord[2] = z;
			break;
		case s_item:
			[_scenario item_spawns][index].coord[0] = x;
			[_scenario item_spawns][index].coord[1] = y;
			[_scenario item_spawns][index].coord[2] = z;
			break;
		case s_machine:
			[_scenario mach_spawns][index].coord[0] = x;
			[_scenario mach_spawns][index].coord[1] = y;
			[_scenario mach_spawns][index].coord[2] = z;
			break;
	}
	[_spawnEditor loadFocusedItemData:_selectFocus];
}

- (void)rotateFocusedItem:(float)x y:(float)y z:(float)z
{
	int type, index;
	type = (_selectFocus / MAX_SCENARIO_OBJECTS);
	index = (_selectFocus % MAX_SCENARIO_OBJECTS);
	
	switch (type)
	{
		case s_vehicle:
			[_scenario vehi_spawns][index].rotation[0] = degToPiRad(x);
			[_scenario vehi_spawns][index].rotation[1] = degToPiRad(y);
			[_scenario vehi_spawns][index].rotation[2] = degToPiRad(z);
			[s_xRotText setFloatValue:x];
			[s_yRotText setFloatValue:y];
			[s_zRotText setFloatValue:z];
			break;
		case s_scenery:
			[_scenario scen_spawns][index].rotation[0] = degToPiRad(x);
			[_scenario scen_spawns][index].rotation[1] = degToPiRad(y);
			[_scenario scen_spawns][index].rotation[2] = degToPiRad(z);
			[s_xRotText setFloatValue:x];
			[s_yRotText setFloatValue:y];
			[s_zRotText setFloatValue:z];
			break;
		case s_playerspawn:
			[_scenario spawns][index].rotation = degToPiRad(x);
			[s_xRotText setFloatValue:x];
			[s_yRotText setFloatValue:0];
			[s_zRotText setFloatValue:0];
			break;
		case s_netgame:
			[_scenario netgame_flags][index].rotation = degToPiRad(x);
			[s_xRotText setFloatValue:x];
			[s_yRotText setFloatValue:0];
			[s_zRotText setFloatValue:0];
			break;
		case s_item:
			[_scenario item_spawns][index].yaw = degToPiRad(x);
			[s_xRotText setFloatValue:x];
			[s_yRotText setFloatValue:0];
			[s_zRotText setFloatValue:0];
			break;
		case s_machine:
			[_scenario mach_spawns][index].rotation[0] = degToPiRad(x);
			[_scenario mach_spawns][index].rotation[1] = degToPiRad(y);
			[_scenario mach_spawns][index].rotation[2] = degToPiRad(z);
			[s_xRotText setFloatValue:x];
			[s_yRotText setFloatValue:y];
			[s_zRotText setFloatValue:z];
			break;
	}
	[_spawnEditor loadFocusedItemData:_selectFocus];
}
/*
*
*	End Scenario Editing Functions
*
*/

/*
*
*	Begin miscellaneous functions
*
*/
- (void)loadCameraPrefs
{
	if (!_mapfile)
		return;
		
	NSData *camDat;
	
	camDat = [prefs objectForKey:[[[_mapfile mapName] stringByAppendingString:@"camDat_0"] stringByAppendingString:[[NSNumber numberWithInt:activeBSPNumber] stringValue]]];
	[camDat getBytes:&camCenter[0] length:12];
	camDat = [prefs objectForKey:[[[_mapfile mapName] stringByAppendingString:@"camDat_1"] stringByAppendingString:[[NSNumber numberWithInt:activeBSPNumber] stringValue]]];
	[camDat getBytes:&camCenter[1] length:12];
	camDat = [prefs objectForKey:[[[_mapfile mapName] stringByAppendingString:@"camDat_2"] stringByAppendingString:[[NSNumber numberWithInt:activeBSPNumber] stringValue]]];
	[camDat getBytes:&camCenter[2] length:12];
	
	[self recenterCamera:self];
}

- (void)renderPartyTriangle
{
	
	glTranslatef(2.0f,2.0f,0.0f);
	
	glBegin( GL_TRIANGLES );              // Draw a triangle
		glColor3f( 1.0f, 0.0f, 0.0f );        // Set color to red
		glVertex3f(  0.0f,  1.0f, 0.0f );     // Top of front
		glColor3f( 0.0f, 1.0f, 0.0f );        // Set color to green
		glVertex3f( -1.0f, -1.0f, 1.0f );     // Bottom left of front
		glColor3f( 0.0f, 0.0f, 1.0f );        // Set color to blue
		glVertex3f(  1.0f, -1.0f, 1.0f );     // Bottom right of front
			
		glColor3f( 1.0f, 0.0f, 0.0f );        // Red
		glVertex3f( 0.0f, 1.0f, 0.0f );       // Top of right side
		glColor3f( 0.0f, 0.0f, 1.0f );        // Blue
		glVertex3f( 1.0f, -1.0f, 1.0f );      // Left of right side
		glColor3f( 0.0f, 1.0f, 0.0f );        // Green
		glVertex3f( 1.0f, -1.0f, -1.0f );     // Right of right side

		glColor3f( 1.0f, 0.0f, 0.0f );        // Red
		glVertex3f( 0.0f, 1.0f, 0.0f );       // Top of back side
		glColor3f( 0.0f, 1.0f, 0.0f );        // Green
		glVertex3f( 1.0f, -1.0f, -1.0f );     // Left of back side
		glColor3f( 0.0f, 0.0f, 1.0f );        // Blue
		glVertex3f( -1.0f, -1.0f, -1.0f );    // Right of back side

		glColor3f( 1.0f, 0.0f, 0.0f );        // Red
		glVertex3f( 0.0f, 1.0f, 0.0f );       // Top of left side
		glColor3f( 0.0f, 0.0f, 1.0f );        // Blue
		glVertex3f( -1.0f, -1.0f, -1.0f );    // Left of left side
		glColor3f( 0.0f, 1.0f, 0.0f );        // Green
		glVertex3f( -1.0f, -1.0f, 1.0f );     // Right of left side
	glEnd();  // Done with triangle
}
/*
*
*	End miscellaneous functions
*
*/
    
    
@synthesize pointsItem;
@synthesize wireframeItem;
@synthesize shadedTrisItem;
@synthesize texturedItem;
@synthesize view_glo;
@synthesize my_pid_v;
@synthesize haloProcessID;
@synthesize buttonPoints;
@synthesize buttonWireframe;
@synthesize buttonShadedFaces;
@synthesize buttonTextured;
@synthesize wall;
@synthesize selecte;
@synthesize bspNumbersButton;
@synthesize framesSlider;
@synthesize fpsText;
@synthesize lodDropdownButton;
@synthesize useAlphaCheckbox;
@synthesize opened;
@synthesize cam_p;
@synthesize selectMode;
@synthesize translateMode;
@synthesize moveCameraMode;
@synthesize duplicateSelected;
@synthesize b_deleteSelected;
@synthesize cspeed;
@synthesize m_MoveCamera;
@synthesize m_SelectMode;
@synthesize m_TranslateMode;
@synthesize m_duplicateSelected;
@synthesize m_deleteFocused;
@synthesize selectText;
@synthesize selectedName;
@synthesize selectedAddress;
@synthesize selectedType;
@synthesize selectedSwapButton;
@synthesize s_accelerationText;
@synthesize s_accelerationSlider;
@synthesize s_xRotation;
@synthesize s_yRotation;
@synthesize s_zRotation;
@synthesize s_xRotText;
@synthesize s_yRotText;
@synthesize s_zRotText;
@synthesize s_spawnTypePopupButton;
@synthesize s_spawnCreateButton;
@synthesize s_spawnEditWindowButton;
@synthesize _spawnEditor;
@synthesize prefs;
@synthesize shouldDraw;
@synthesize FullScreen;
@synthesize first;
@synthesize _useAlphas;
@synthesize _LOD;
@synthesize _camera;
@synthesize drawTimer;
@synthesize _mapfile;
@synthesize _scenario;
@synthesize mapBSP;
@synthesize _texManager;
@synthesize activeBSPNumber;
@synthesize _fps;
@synthesize rendDistance;
@synthesize currentRenderStyle;
@synthesize maxRenderDistance;
@synthesize dup;
@synthesize cameraMoveSpeed;
@synthesize acceleration;
@synthesize accelerationCounter;
@synthesize is_css;
@synthesize new_characters;
@synthesize _mode;
@synthesize selee;
@synthesize selections;
@synthesize _lookup;
@synthesize _selectType;
@synthesize _selectFocus;
@synthesize s_acceleration;
@synthesize isfull;
@synthesize should_update;
@synthesize _lineWidth;
@synthesize selectDistance;
@synthesize msel;
@synthesize camera;
@synthesize render;
@synthesize spawnc;
@synthesize spawne;
@synthesize select;
@synthesize player_1;
@synthesize player_2;
@synthesize player_3;
@synthesize player_4;
@synthesize player_5;
@synthesize player_6;
@synthesize player_7;
@synthesize player_8;
@synthesize player_9;
@synthesize player_10;
@synthesize player_11;
@synthesize player_12;
@synthesize player_13;
@synthesize player_14;
@synthesize player_15;
@synthesize duplicate_amount;
@end
