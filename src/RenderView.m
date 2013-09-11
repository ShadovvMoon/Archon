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
#import "math.h"

/*
	TODO:
		Fucking lookup selection lookup table is being fed very large values for some reason. Something to do with the names, have to check it out.
*/

@implementation RenderView
/* 
*
*		Begin RenderView Functions 
*
*/
- (void)writeUnicodeStringFromString:(NSString *)string
							 address:(vm_address_t)address
					  requiredLength:(int)requiredLength
{
	int unicodeLength = [string length];
	unichar unicodeCharacters[unicodeLength];
	[string getCharacters:unicodeCharacters];
	
	int unicodeCharacterIndex;
	for (unicodeCharacterIndex = 0; unicodeCharacterIndex < unicodeLength; unicodeCharacterIndex++)
	{
		unicodeCharacters[unicodeCharacterIndex] = CFSwapInt16BigToHost(unicodeCharacters[unicodeCharacterIndex]);
	}
	
	//(haloProcessID, address, unicodeCharacters, unicodeLength * sizeof(unichar));
	
	if (requiredLength)
	{
		// max length - length of string + zero terminator
		int numberOfBytesToWrite = requiredLength - unicodeLength + 1;
		
		int bytesIndex;
		for (bytesIndex = 0; bytesIndex < numberOfBytesToWrite; bytesIndex++)
		{
			unichar zero = 0;
			//(haloProcessID, address + unicodeLength * sizeof(unichar) + bytesIndex, &zero, sizeof(unichar));
		}
	}
	else
	{
		unichar zero = 0;
		//(haloProcessID, address + unicodeLength * sizeof(unichar), &zero, sizeof(unichar));
	}
}

- (NSString *)readUnicodeStringWithLength:(vm_size_t)length
								  address:(vm_address_t)address
{
	unichar unicodeCharacters[length];
	vm_size_t size = length * sizeof(unichar);
	//VMReadBytes(haloProcessID, address, &unicodeCharacters, &size);
	
	int unicodeCharacterIndex;
	for (unicodeCharacterIndex = 0; unicodeCharacterIndex < length && unicodeCharacters[unicodeCharacterIndex] != 0; unicodeCharacterIndex++)
	{
		unicodeCharacters[unicodeCharacterIndex] = CFSwapInt16BigToHost(unicodeCharacters[unicodeCharacterIndex]);
	}
	
	return [NSString stringWithCharacters:unicodeCharacters
								   length:unicodeCharacterIndex];
}

- (void)assignHaloProcessIDFromApplicationDictionary:(NSDictionary *)applicationDictionary
{
	if ([[applicationDictionary objectForKey:@"NSApplicationName"] rangeOfString:@"Halo Demo" options:NSCaseInsensitiveSearch].location != NSNotFound)
	{
		haloProcessID = [[applicationDictionary objectForKey:@"NSApplicationProcessIdentifier"] intValue];
		NSLog(@"PID %d", haloProcessID);
	}
}

- (void)applicationDidLaunch:(NSNotification *)notification
{
	[self assignHaloProcessIDFromApplicationDictionary:[notification userInfo]];
}

- (void)applicationDidTerminate:(NSNotification *)notification
{
	if ([[[notification userInfo] objectForKey:@"NSApplicationName"] rangeOfString:@"Halo Demo" options:NSCaseInsensitiveSearch].location != NSNotFound)
	{
		haloProcessID = 0;
	}
}

-(void)setPID:(int)my_pid
{
	my_pid_v = my_pid;
}

- (id)initWithFrame: (NSRect) frame
{
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
    if(!nsglFormat) { NSLog(@"Invalid format... terminating."); return nil; }
	
	// Now we create the the CocoaGL instance, using our initial frame and the NSOpenGLPixelFormat
    self = [super initWithFrame:frame pixelFormat:nsglFormat];
    [nsglFormat release];
	
	// If there was an error, we again should probably send an error message to the user
    if(!self) { NSLog(@"Self not created... terminating."); return nil; }
	
	// Now we set this context to the current context (means that its now drawable)
    [[self openGLContext] makeCurrentContext];
	
	// Finally, we call the initGL method (no need to make this method too long or complex)
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
	
	first = YES;
}
- (void)prepareOpenGL
{
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClearDepth(1.0f);
	glDepthFunc(GL_LESS);
	glEnable(GL_DEPTH_TEST);
	
	glHint(GL_POLYGON_SMOOTH_HINT,GL_NICEST);
	
	first = YES;
	//NSLog(@"end initGL");
}

-(void)updateQuickLink:(NSTimer *)abc
{
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

}

- (void)updatePlayerPosition:(NSTimer *)timersa
{
	if (haloProcessID)
	{

		
	NSMutableArray *old_characters = new_characters;
	new_characters = [[NSMutableArray alloc] initWithCapacity:16];
	
	int i;
	for (i = 0; i < 16; i++)
	{
		const int hostObjectIDAddress = 0x4BD7B002 + 0x200 * i;
		const int firstTableObjectArrayAddress = 0x4BB206EC;
		const int tableObjectArraySize = 12;
		const unsigned short invalidHostObjectID = 0xFFFF;
		const int offsetToObjectArrayTablePointer = 0x8;
		
		unsigned short hostObjectID;
		vm_size_t size = sizeof(short);
		//VMReadBytes(haloProcessID, hostObjectIDAddress, &hostObjectID, &size);
		hostObjectID = CFSwapInt16BigToHost(hostObjectID);
		
		if (hostObjectID != 0 && hostObjectID != invalidHostObjectID)
		{
			// the host is alive
			
			unsigned int haloObjectPointerAddress = firstTableObjectArrayAddress + hostObjectID * tableObjectArraySize + offsetToObjectArrayTablePointer;
			
			int haloObjectPointer;
			size = sizeof(int);
			//VMReadBytes(haloProcessID, haloObjectPointerAddress, &haloObjectPointer, &size);
			haloObjectPointer = CFSwapInt32BigToHost(haloObjectPointer);
			
			const int offsetToPlayerXCoordinate = 0x5C;
			const int offsetToPlayerYCoordinate = 0x5C + 0x4;
			const int offsetToPlayerZCoordinate = 0x5C + 0x4 + 0x4;
			
			float newHostXValue;
			float newHostYValue;
			float newHostZValue;
			
			float newHostXValueR;
			float newHostYValueR;
			float newHostZValueR;
			size = sizeof(float);
			
			
			
			//VMReadBytes(haloProcessID, haloObjectPointer + offsetToPlayerXCoordinate, &newHostXValue, &size);
			////VMReadBytes(haloProcessID, haloObjectPointer + offsetToPlayerYCoordinate, &newHostYValue, &size);
			//VMReadBytes(haloProcessID, haloObjectPointer + offsetToPlayerZCoordinate, &newHostZValue, &size);
			
			//VMReadBytes(haloProcessID, haloObjectPointer + offsetToPlayerXCoordinate + 0x4 + 0x4 + 0x4 + 0x4 + 0x4 + 0x4, &newHostXValueR, &size);
			//VMReadBytes(haloProcessID, haloObjectPointer + offsetToPlayerYCoordinate + 0x4 + 0x4 + 0x4 + 0x4 + 0x4 + 0x4, &newHostYValueR, &size);
			//VMReadBytes(haloProcessID, haloObjectPointer + offsetToPlayerZCoordinate + 0x4 + 0x4 + 0x4 + 0x4 + 0x4 + 0x4, &newHostZValueR, &size);
			
			
			// Kill the host!
			int *newHostXValuePointer = (int *)&newHostXValue;
			int *newHostYValuePointer = (int *)&newHostYValue;
			int *newHostZValuePointer = (int *)&newHostZValue;
			*newHostXValuePointer = CFSwapInt32BigToHost(*((int *)&newHostXValue));
			*newHostYValuePointer = CFSwapInt32BigToHost(*((int *)&newHostYValue));
			*newHostZValuePointer = CFSwapInt32BigToHost(*((int *)&newHostZValue));
			
			
			
			// Kill the host!
			int *newHostXValuePointerR = (int *)&newHostXValueR;
			int *newHostYValuePointerR = (int *)&newHostYValueR;
			int *newHostZValuePointerR = (int *)&newHostZValueR;
			*newHostXValuePointerR = CFSwapInt32BigToHost(*((int *)&newHostXValueR));
			*newHostYValuePointerR = CFSwapInt32BigToHost(*((int *)&newHostYValueR));
			*newHostZValuePointerR = CFSwapInt32BigToHost(*((int *)&newHostZValueR));
			
			
			newHostXValueR = newHostXValueR;
			newHostYValueR = newHostYValueR;
			newHostZValueR = newHostZValueR;
			
			playercoords[(i * 8) + 0] = newHostXValue;
			playercoords[(i * 8) + 1] = newHostYValue;
			playercoords[(i * 8) + 2] = newHostZValue;
			
			playercoords[(i * 8) + 5] = newHostXValueR * (180 / M_PI);
			playercoords[(i * 8) + 6] = (180 / M_PI) * newHostYValueR;
			playercoords[(i * 8) + 7] = (180 / M_PI) * newHostZValueR;
			
			//[[self window] setLevel:100];
			
			//NSRunAlertPanel([NSString stringWithFormat:@"%f", playercoords[(i * 8) + 6]], @"", @"", nil, nil);
			
			//Get the team
			short hostTeamNumber;
			vm_size_t hostTeamNumberSize = sizeof(short);
			//VMReadBytes(haloProcessID, 0x4BD7AFEE + 0x200 * i, &hostTeamNumber, &hostTeamNumberSize);
			hostTeamNumber = CFSwapInt16BigToHost(hostTeamNumber);
			
			if (hostTeamNumber == 0)
			{
				playercoords[(i * 8) + 3] = 0.0;
			}
			else if (hostTeamNumber == 1)
			{
				playercoords[(i * 8) + 3] = 1.0;
			}
			else if (hostTeamNumber == 8)
			{
				playercoords[(i * 8) + 3] = 8.0;
			}
			
			NSString *playerName = [self readUnicodeStringWithLength:24 address:0x4BD7AFD0 + 0x200 * i];
			[new_characters addObject:playerName];
			//glRotatef(piradToDeg( playercoords[(player_number * 8) + 6]),0,0,1);
			
			
			//[self RotateView:-1*angleY x:0 y:0 z:1];
			
			if (i == 0)
			{
				//[_camera PositionCamera:newHostXValue positionY:newHostYValue positionZ:newHostZValue + 1.0 viewX:0.0 viewY:0.0 viewZ:0.0 upVectorX:0.0f upVectorY:0.0f upVectorZ:1.0f];
				//[_camera RotateView:fabs(newHostYValueR) x:0 y:0 z:1];
			}//CMHERE

			
		}
		else
		{
			playercoords[(i * 8) + 0] = 0.0;
			playercoords[(i * 8) + 1] = 0.0;
			playercoords[(i * 8) + 2] = 0.0;
		}
		
	}
	
	}
	
	//[_camera PositionCamera:(x + 0.01f) positionY:(y + 0.01f) positionZ:(z + 1.0f) viewX:1.0f viewY:1.0f viewZ:(z + 1.0f) upVectorX:0.0f upVectorY:0.0f upVectorZ:1.0f];
}

-(void)renderTimer:(id)object
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
	//[runLoop run];
	[pool release];
}


- (void)awakeFromNib
{
	
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
	
	_fps = 130;
	drawTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0/_fps) target:self selector:@selector(timerTick:) userInfo:nil repeats:YES] retain];
	
	prefs = [NSUserDefaults standardUserDefaults];
	[self loadPrefs];
	
	shouldDraw = NO;
	
	_camera = [[Camera alloc] init];
	acceleration = 0;
	cameraMoveSpeed = 0.5;
	maxRenderDistance = 300.0f;
	
	selectDistance = 300.0f;
	rendDistance = 300.0;
	
	meshColor.blue = 1.0;
	meshColor.green = 0.1;
	meshColor.red = 0.1;
	meshColor.color_count = 0;
	
	color_index = alphaIndex;
	
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
	
	NSDictionary *applicationDictionary;
	NSEnumerator *launchedApplicationsEnumerator = [[[NSWorkspace sharedWorkspace] launchedApplications] objectEnumerator];
	while ((applicationDictionary = [launchedApplicationsEnumerator nextObject]))
	{
		[self assignHaloProcessIDFromApplicationDictionary:applicationDictionary];
	}
	
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
														   selector:@selector(applicationDidLaunch:)
															   name:NSWorkspaceDidLaunchApplicationNotification
															 object:nil];
	
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
														   selector:@selector(applicationDidTerminate:)
															   name:NSWorkspaceDidTerminateApplicationNotification
															 object:nil];
	
	//NSTimer *playertimer = [[NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(updatePlayerPosition:) userInfo:nil repeats:YES] retain];
	//[[NSRunLoop currentRunLoop] addTimer:playertimer forMode:(NSString *)kCFRunLoopCommonModes];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
	[NSApp setDelegate:self];
	//NSThread* timerThread = [[NSThread alloc] initWithTarget:self selector:@selector(renderTimer:) object:nil]; //Create a new thread
	//[timerThread start]; 
	
	[NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(updateQuickLink:) userInfo:nil repeats:YES];

}

-(void)setTermination:(NSTimer*)ti
{
	
	
}

-(IBAction)FocusOnPlayer:(id)sender
{
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
	NSSize sceneBounds = [self frame].size;
	glViewport(0,0,sceneBounds.width,sceneBounds.height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective(45.0f,
					(sceneBounds.width / sceneBounds.height),
					0.1f,
					400.0f);
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


- (void)keyDown:(NSEvent *)theEvent
{
	NSString *characters = [theEvent characters];
	unichar character = [characters characterAtIndex:0];
	//NSLog(@"%x", character);
	if (character == NSDeleteCharacter || character == NSBackspaceCharacter)
	{
		//Delete the current shape.
		[self buttonPressed:b_deleteSelected];
		
	}
	else {
		
	

	switch (character)
	{
		case 'w':
			move_keys_down[0].direction = forward;
			move_keys_down[0].isDown = YES;
			break;
		case '1':
			[self buttonPressed:translateMode];
			break;
		case '2':
			[self buttonPressed:selectMode];
			break;
		case '3':
			[self buttonPressed:duplicateSelected];
			break;
		case '4':
			[self MovetoBSD:nil];
			break;
		case 's':
			move_keys_down[1].direction = back;
			move_keys_down[1].isDown = YES;
			break;
		case 'a':
			move_keys_down[2].direction = left;
			move_keys_down[2].isDown = YES;
			break;
		case 'd':
			move_keys_down[3].direction = right;
			move_keys_down[3].isDown = YES;
			break;
		case ' ':
			move_keys_down[4].direction = up;
			move_keys_down[4].isDown = YES;
			break;
		case 'c':
			move_keys_down[5].direction = down;
			move_keys_down[5].isDown = YES;
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
}
- (void)mouseUp:(NSEvent *)theEvent
{
}
- (void)mouseDown:(NSEvent *)event
{

    
    
    
    
    
	
	
	NSPoint downPoint = [event locationInWindow];
	NSPoint local_point = [self convertPoint:downPoint fromView:[[self window] contentView]];
	prevDown = [NSEvent mouseLocation];
	
	if (_mode == select && _mapfile)
	{
		
		if ([msel state])
		{
			
		event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
		NSPoint graphicOrigin = [NSEvent mouseLocation];
			
		NSPoint en = graphicOrigin;
		
		
		CGFloat w = 0.0;
		CGFloat h = 0.0;
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
		[self trySelection:sp shiftDown:(([event modifierFlags] & NSShiftKeyMask) != 0) width:w height:h];
	
		[selee close];
			
		}
		else
		{
			float selection_size = 1.0f;
			[self trySelection:local_point shiftDown:(([event modifierFlags] & NSShiftKeyMask) != 0) width:selection_size height:selection_size ];
		}

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
		if ([wall state])
		{
			
			if (dup >= [duplicate_amount doubleValue])
			{
				unsigned int type, index, nameLookup;
				
				if (!selections || [selections count] == 0)
					return;
				
				nameLookup = [[selections objectAtIndex:0] unsignedIntValue];
				type = (unsigned int)(nameLookup / MAX_SCENARIO_OBJECTS);
				index = (unsigned int)(nameLookup % MAX_SCENARIO_OBJECTS);

				
				[_scenario duplicateScenarioObjectLocation:type index:index coord:1];
				_selectFocus = [[selections objectAtIndex:0] longValue];
				dup=0;
			}
			else
			{
				dup++;
			}

		}
        
        //[self performTranslation:dragPoint zEdit:(([theEvent modifierFlags] & NSControlKeyMask) != 0)];
		[self performTranslation:dragPoint zEdit:(([theEvent modifierFlags] & NSControlKeyMask) != 0)];
	}
	else if (_mode == rotate)
	{
		[self performRotation:dragPoint zEdit:(([theEvent modifierFlags] & NSControlKeyMask) != 0)];
	}
	if ((([theEvent modifierFlags] & NSControlKeyMask) != 0) && _mode != translate)
		[_camera HandleMouseMove:(dragPoint.x - prevDown.x) dy:(dragPoint.y - prevDown.y)];
	prevDown = dragPoint;
}



- (void)mouseMoved:(NSEvent *)theEvent
{
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
	// In here we handle a few things, mmk?
	acceleration = (int)[cspeed doubleValue];
	
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
					[_camera MoveCamera:(cameraMoveSpeed + acceleration)];
					break;
				case back:
					[_camera MoveCamera:(-1 * (cameraMoveSpeed + acceleration))];
					break;
				case left:
					[_camera StrafeCamera:(-1 * (cameraMoveSpeed + acceleration))];
					break;
				case right:
					[_camera StrafeCamera:(cameraMoveSpeed + acceleration)];
					break;
				case down:
					[_camera LevitateCamera:(-1 * (cameraMoveSpeed + acceleration))]; 
					break;
				case up:
					[_camera LevitateCamera:(cameraMoveSpeed + acceleration)];
					break;
			}
		}
	}
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
	
	if (shouldDraw)
	{
		[self reshape];
		[self setNeedsDisplay:YES];
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

- (void)drawRect:(NSRect)rect
{	
	glLoadIdentity();
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	[_camera Look];
	[_camera Update];
	
	[self drawAxes];
	
	if (shouldDraw)
	{
		if (mapBSP)
		{
			[self renderVisibleBSP:FALSE];
		}
		
	
		
		if (_scenario)
		{
			[self renderAllMapObjects];
		}
	}
	
	[[self openGLContext] flushBuffer];
}
- (void)loadPrefs
{
	//NSLog(@"Loading preferences!");
	
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
	
	if ([[[NSUserDefaults standardUserDefaults]objectForKey:@"automatic"] isEqualToString:@"NO"])
	{
		[self recenterCamera:self];
	}
	else
	{
		
	

	NSString *autoa = [NSString stringWithContentsOfFile:@"/tmp/starlight.auto"];
	
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/starlight.auto"])
	{
		
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
	
	SUBMESH_INFO *pMesh;
	
	
	unsigned int mesh_count;
	int m;

	mesh_count = [mapBSP GetActiveBspSubmeshCount];
	
	
	int point = 0;
	for (m = 0; m < mesh_count; m++)
	{
		pMesh = [mapBSP GetActiveBspPCSubmesh:m];
		point+=pMesh->IndexCount*3;
	}
	
	bsp_point_count=point;
	
	///Create the bsp points
	bsp_points = malloc(bsp_point_count * sizeof(bsp_point));
	
	
	
	int b = 0;
	for (m = 0; m < mesh_count; m++)
	{
				
		pMesh = [mapBSP GetActiveBspPCSubmesh:m];
		for (i = 0; i < pMesh->IndexCount; i++)
		{
			
			float *coord = (float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[0]].vertex_k);
			bsp_points[b].coord[0]= coord[0];
			bsp_points[b].coord[1]= coord[1];
			bsp_points[b].coord[2]= coord[2];
			bsp_points[b].mesh=m;
			bsp_points[b].index = 0;
			bsp_points[b].amindex = i;
            bsp_points[b].isSelected = NO;
			
			coord = (float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[1]].vertex_k);
			bsp_points[b+1].coord[0]= coord[0];
			bsp_points[b+1].coord[1]= coord[1];
			bsp_points[b+1].coord[2]= coord[2];
			bsp_points[b+1].index = 1;
			bsp_points[b+1].mesh=m;
			bsp_points[b+1].amindex = i;
           bsp_points[b+1].isSelected = NO;
			
			coord = (float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[2]].vertex_k);
			bsp_points[b+2].coord[0]= coord[0];
			bsp_points[b+2].coord[1]= coord[1];
			bsp_points[b+2].coord[2]= coord[2];
			bsp_points[b+2].index = 2;
			bsp_points[b+2].mesh=m;
			bsp_points[b+2].amindex = i;
            bsp_points[b+2].isSelected = NO;
			
			b+=3;
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
					[self renderBSPAsTexturedAndLightmaps:i];
					//[self renderBSPAsPoints:i];
					glLineWidth(2.0f);
					glColor3f(0.5f, 0.5f, 0.5f);
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
	
	for (i = 0; i < [mesh  coll_count]; i++)
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
- (void)renderBSPAsFlatShadedPolygon:(int)mesh_index
{
	SUBMESH_INFO *pMesh;
	int i;
	
	pMesh = [mapBSP GetActiveBspPCSubmesh:mesh_index];
	
	glBegin(GL_TRIANGLES);
	[self setNextMeshColor];
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
	SkyBox *skies;
	skies = [_scenario sky];

	float pos[3];
	pos[0] = 0;
	pos[1] = 0;
	pos[2] = 0;
	
	[[_mapfile tagForId:skies[0].modelIdent] drawAtPoint:pos lod:_LOD isSelected:FALSE useAlphas:_useAlphas];
}

- (void)renderBSPAsTexturedAndLightmaps:(int)mesh_index
{
	pMesh = [mapBSP GetActiveBspPCSubmesh:mesh_index];
	
	if (pMesh->ShaderIndex == -1)
	{
		glColor3f(0.1f, 0.1f, 0.1f);
	}
	else
	{
	
		if (pMesh->LightmapIndex != -1)
		{
			glEnable(GL_TEXTURE_2D);
		}
		
		[_texManager activateTextureOfIdent:pMesh->DefaultBitmapIndex subImage:0 useAlphas:NO];
		
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
		
	}
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
	
	glColor3f(meshColor.red, meshColor.green, meshColor.blue);
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
	
	
	int x, i, name = 1;
	float pos[6], distanceTo;
	
	vehicle_spawn *vehi_spawns;
	scenery_spawn *scen_spawns;
	mp_equipment *equipSpawns;
	machine_spawn *mach_spawns;
	encounter *encounters;
	SkyBox *skies;
	player_spawn *spawns;
	
	glInitNames();
	glPushName(0);
	
	// This one does its own namings
	[self renderNetgameFlags:&name];
	
	
	vehi_spawns = [_scenario vehi_spawns];
	scen_spawns = [_scenario scen_spawns];
	equipSpawns = [_scenario item_spawns];
	spawns = [_scenario spawns];
	mach_spawns = [_scenario mach_spawns];
	encounters = [_scenario encounters];
	skies = [_scenario sky];
	
	glColor4f(0.0f,0.0f,0.0f,1.0f);
	

	for (x = 0; x < [_scenario player_spawn_count]; x++)
	{
		// Lookup goes hur
		if (_lookup)
			_lookup[name] = (long)(s_playerspawn * MAX_SCENARIO_OBJECTS + x);
		glLoadName(name);
		name++;
		if (spawns[x].bsp_index == activeBSPNumber)
			[self renderPlayerSpawn:spawns[x].coord team:spawns[x].team_index isSelected:spawns[x].isSelected];
	}
	for (x = 0; x < bsp_point_count; x++)
	{
		// Lookup goes hur
		if (_lookup)
			_lookup[name] = (long)(s_bsppoint * MAX_SCENARIO_OBJECTS + x);
		glLoadName(name);
		name++;
		[self renderPoint:bsp_points[x].coord isSelected:bsp_points[x].isSelected];
	}
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
		/*
		SUBMESH_INFO *pMesh;
		int i;
		

		glBegin(GL_TRIANGLES);
		[self setNextMeshColor];
		pos[0]=[[mapBSP mesh] collision_verticies][x].x;
		pos[1]=[[mapBSP mesh] collision_verticies][x].y;
		pos[2]=[[mapBSP mesh] collision_verticies][x].z;
		
		
			glVertex3fv(pos);
		
		pos[0]=[[mapBSP mesh] collision_verticies][x+1].x;
		pos[1]=[[mapBSP mesh] collision_verticies][x+1].y;
		pos[2]=[[mapBSP mesh] collision_verticies][x+1].z;
		
		
			glVertex3fv(pos);
		
		
		pos[0]=[[mapBSP mesh] collision_verticies][x+2].x;
		pos[1]=[[mapBSP mesh] collision_verticies][x+2].y;
		pos[2]=[[mapBSP mesh] collision_verticies][x+2].z;
			glVertex3fv(pos);
		glEnd();*/
		
		
		[self renderCP:pos isSelected:[[mapBSP mesh] collision_verticies][x].isSelected];
	}
	for (i=0; i < [_scenario encounter_count]; i++)
	{
		player_spawn *encounter_spawns;
		encounter_spawns = encounters[i].start_locs;
		
		for (x = 0; x < encounters[i].start_locs_count; x++)
		{
			// Lookup goes hur
			if (_lookup)
				_lookup[name] = (long)(s_encounter * MAX_SCENARIO_OBJECTS + i);
			glLoadName(name);
			name++;
			
			if (encounter_spawns[x].bsp_index == activeBSPNumber)
				[self renderPlayerSpawn:encounter_spawns[x].coord team:1 isSelected:encounter_spawns[x].isSelected];
		}
	}
	for (x = 0; x < [_scenario item_spawn_count]; x++)
	{
		// Lookup goes hur
		if (_lookup)
			_lookup[name] = (long)(s_item * MAX_SCENARIO_OBJECTS + x); 
		glLoadName(name);
		name++;
		if ([_mapfile isTag:equipSpawns[x].modelIdent])
		{
			//NSRunAlertPanel([NSString stringWithFormat:@"%d",(int)equipSpawns[x].modelIdent], @"", @"", @"", @"");
			
			for (i = 0; i < 3; i++)
				pos[i] = equipSpawns[x].coord[i];
			pos[3] = equipSpawns[x].yaw;
			pos[4] = pos[5] = 0.0f;
			distanceTo = [self distanceToObject:pos];
			if (distanceTo < rendDistance || equipSpawns[x].isSelected)
				[[_mapfile tagForId:equipSpawns[x].modelIdent] drawAtPoint:pos lod:_LOD isSelected:equipSpawns[x].isSelected useAlphas:_useAlphas];
		}
	}
	for (x = 0; x < [_scenario mach_spawn_count]; x++)
	{
		if (_lookup)
			_lookup[name] = (long)(s_machine * MAX_SCENARIO_OBJECTS + x);
		glLoadName(name);
		name++;
		if ([_mapfile isTag:[_scenario mach_references][mach_spawns[x].numid].machTag.TagId])
		{
			distanceTo = [self distanceToObject:pos];
			
			if ((distanceTo < rendDistance || mach_spawns[x].isSelected) && mach_spawns[x].desired_permutation == activeBSPNumber)
				[[_mapfile tagForId:[_scenario mach_references][mach_spawns[x].numid].modelIdent] drawAtPoint:mach_spawns[x].coord lod:_LOD isSelected:mach_spawns[x].isSelected useAlphas:_useAlphas];
		}
	}
	for (x = 0; x < [_scenario vehicle_spawn_count]; x++)
	{
		// Lookup goes hur
		if (_lookup)
			_lookup[name] = (long)(s_vehicle * MAX_SCENARIO_OBJECTS + x);
		glLoadName(name);
		name++;
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
				[[_mapfile tagForId:vehi_spawns[x].modelIdent] drawAtPoint:pos lod:_LOD isSelected:vehi_spawns[x].isSelected useAlphas:_useAlphas];
		}
	}
	for (x = 0; x < [_scenario scenery_spawn_count]; x++)
	{	
		// Lookup goes hur
		if (_lookup)
			_lookup[name] = (long)(s_scenery * MAX_SCENARIO_OBJECTS + x);
		glLoadName(name);
		name++;
		if ([_mapfile isTag:scen_spawns[x].modelIdent])
		{
			for (i = 0; i < 3; i++)
				pos[i] = scen_spawns[x].coord[i];
			for (i = 3; i < 6; i++)
				pos[i] = scen_spawns[x].rotation[i - 3];
			distanceTo = [self distanceToObject:pos];

			if ((distanceTo < rendDistance || scen_spawns[x].isSelected) && scen_spawns[x].desired_permutation == activeBSPNumber)
				[[_mapfile tagForId:scen_spawns[x].modelIdent] drawAtPoint:pos lod:_LOD isSelected:scen_spawns[x].isSelected useAlphas:_useAlphas];
		}
	}		
	for (x = 0; x < 1; x++)
	{	
		// Lookup goes hur

		if ([_mapfile isTag:skies[x].modelIdent])
		{
			pos[0]=0;
			pos[1]=0;
			pos[2]=0;
			pos[3]=0;
			pos[4]=0;
			pos[5]=0;

			distanceTo = [self distanceToObject:pos];
			
			if ((distanceTo < rendDistance))
				[[_mapfile tagForId:skies[x].modelIdent] drawAtPoint:pos lod:_LOD isSelected:YES useAlphas:_useAlphas];
		}
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
		switch (mp_flags[i].type)
		{
			case ctf_flag:
				[self renderFlag:mp_flags[i].coord team:mp_flags[i].team_index isSelected:mp_flags[i].isSelected];
				break;
			case ctf_vehicle:
				break;
			case oddball:
				//NSLog(@"Oddball attempt ID: 0x%x", mp_flags[i].item_used.TagId);
				break;
			case race_track:
				break;
			case race_vehicle:
				break;
			case vegas_bank:
				break;
			case teleporter_entrance:
				color[0] = 1.0f; color[1] = 1.0f; color[2] = 0.2f;
				[self renderBox:mp_flags[i].coord rotation:rotation color:color selected:mp_flags[i].isSelected];
				break;
			case teleporter_exit:
				color[0] = 0.2f; color[1] = 1.0f; color[2] = 1.0f;
				[self renderBox:mp_flags[i].coord rotation:rotation color:color selected:mp_flags[i].isSelected];
				break;
			case hill_flag:
				color[0] = 0.4f; color [1] = color[2] = 0.0f;
				[self renderBox:mp_flags[i].coord rotation:rotation color:color selected:mp_flags[i].isSelected];
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
	}
	else if ((sender == s_xRotText) || (sender == s_yRotText) || (sender == s_zRotText))
	{
		[s_xRotation setFloatValue:[[s_xRotText stringValue] floatValue]];
		[s_yRotation setFloatValue:[[s_yRotText stringValue] floatValue]];
		[s_zRotation setFloatValue:[[s_zRotText stringValue] floatValue]];
		[self rotateFocusedItem:[s_xRotText floatValue] y:[s_yRotText floatValue] z:[s_zRotText floatValue]];
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

-(int)readFloat:(int)address
{
	float newHostXValue;
	vm_size_t size = sizeof(float);
	
	//VMReadBytes(haloProcessID, address, &newHostXValue, &size);
	int *newHostXValuePointer = (int *)&newHostXValue;
	*newHostXValuePointer = CFSwapInt32BigToHost(*((int *)&newHostXValue));
	return newHostXValue;
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

-(int)readUInt16:(int)address
{
	short newHostXValue;
	vm_size_t size = sizeof(short);
	
	////VMReadBytes(haloProcessID, address, &newHostXValue, &size);
	int *newHostXValuePointer = (int *)&newHostXValue;
	*newHostXValuePointer = CFSwapInt16BigToHost(*((int *)&newHostXValue));
	return newHostXValue;
}

-(int)readUInt32:(int)address
{
	int newHostXValue;
	vm_size_t size = sizeof(int);
	
	//VMReadBytes(haloProcessID, address, &newHostXValue, &size);
	int *newHostXValuePointer = (int *)&newHostXValue;
	*newHostXValuePointer = CFSwapInt32BigToHost(*((int *)&newHostXValue));
	return newHostXValue;
}

-(void)setSpeed:(float)speed_number player:(int)index
{
	[self writeFloat:8.0 to:0x4BD7B038 + 0x200 * index];
}


-(void)getVehicles:(NSTimer*)at
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (haloProcessID)
	{
		
	const int firstTableObjectArrayAddress = 0x4BB206EC;
	const int tableObjectArraySize = 12;
	const unsigned short invalidHostObjectID = 0xFFFF;
	const int offsetToObjectArrayTablePointer = 0x8;
	
	int i;
	for (i = 0; i < 2048; i++)
	{
		
		//address = 
		const int tablez_address = firstTableObjectArrayAddress + (i * tableObjectArraySize);
		

			// the host is alive02086790 = "Sharpy"
			
			unsigned int haloObjectPointerAddress = tablez_address + 0x8;
		
			int haloObjectPointer;
			vm_size_t size = sizeof(int);
			//VMReadBytes(haloProcessID, haloObjectPointerAddress, &haloObjectPointer, &size);
			haloObjectPointer = CFSwapInt32BigToHost(haloObjectPointer);
			
			//We have the object!
			//int x = [self readFloat:haloObjectPointer + 0x5C];
			dynamic_object object;
		
			object.x = [self readFloat:haloObjectPointer + 92];
			object.y = [self readFloat:haloObjectPointer + 96];
			object.z = [self readFloat:haloObjectPointer + 100];
		
		
		    object.sx = [self readFloat:haloObjectPointer + 116];
		    object.sy = [self readFloat:haloObjectPointer + 120];
		    object.sz = [self readFloat:haloObjectPointer + 124];
		
			object.address = haloObjectPointer;
	
			
			int haloObjectPointer222 = [self readUInt16:haloObjectPointer+0x2];
			//I THINK this is some kind of tag?
			//NSRunAlertPanel([NSString stringWithFormat:@"%d", haloObjectPointer222], @"", @"", @"", @"");
			//Grrreaat >_>
			//We need to somehow workout the tag of the weapon?
		
		long IndexMagic = (long)[self readUInt32:0x4BF10000];
		long BaseIdent = (long)[self readUInt32:0x006A2000+2+2+700+4];
		long Unknown = (long)[self readUInt32:0x4BF10000+8];
		long NumOfTags = (long)[self readUInt32:0x4BF10000+12];
		long VertexObjectCount = (long)[self readUInt32:0x4BF10000+16];
		long ModelRawDataOffset = (long)[self readUInt32:0x4BF10000+20];	
		long IndicesObjectCount = (long)[self readUInt32:0x4BF10000+24];
		long IndicesOffset = (long)[self readUInt32:0x4BF10000+28];
		long ModelRawDataSize = (long)[self readUInt32:0x4BF10000+32];
		
		
		long tagID = (long)[self readUInt32:IndexMagic + (haloObjectPointer222 * 32) + 12];
		long newtagIdent;
		
		MapTag *tempTag = [_mapfile tagForId:tagID];
		[_mapfile seekToAddress:([tempTag offsetInMap] + 0x34)];
		[_mapfile readLong:&newtagIdent];
	
		object.id_tag = newtagIdent;


		map_objects[i] = object;
		}//RETURN HERE
		
	}
	[pool release];
}

-(int)getDynamicPlayer:(int)index
{
	
	if (haloProcessID)
	{
		
	const int hostObjectIDAddress = 0x4BD7B002 + 0x200 * index;
	const int firstTableObjectArrayAddress = 0x4BB206EC;
	const int tableObjectArraySize = 12;
	const unsigned short invalidHostObjectID = 0xFFFF;
	const int offsetToObjectArrayTablePointer = 0x8;
	
	unsigned short hostObjectID;
	vm_size_t size = sizeof(short);
	//VMReadBytes(haloProcessID, hostObjectIDAddress, &hostObjectID, &size);
	hostObjectID = CFSwapInt16BigToHost(hostObjectID);
	
	
	
	if (hostObjectID != 0 && hostObjectID != invalidHostObjectID)
	{
		// the host is alive02086790 = "Sharpy"
		
		unsigned int haloObjectPointerAddress = firstTableObjectArrayAddress + hostObjectID * tableObjectArraySize + offsetToObjectArrayTablePointer;
		
		int haloObjectPointer;
		size = sizeof(int);
		//VMReadBytes(haloProcessID, haloObjectPointerAddress, &haloObjectPointer, &size);
		haloObjectPointer = CFSwapInt32BigToHost(haloObjectPointer);
		
		return haloObjectPointer;
	}
	
	return 0;
		
	}
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
			[self processSelection:(unsigned int)[_scenario createTeleporterPair:[_camera vView]]];
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
				[_scenario mach_spawns][index].numid = [sender indexOfSelectedItem];
				break;
			case s_vehicle:
				NSLog(@"Change vehicle ref");
				numid = &[_scenario vehi_spawns][index].numid;
				
				//Switch the types of vehicles
				long original_mt = [_scenario vehi_references][*numid].vehi_ref.TagId;
				long new_mt = [_scenario vehi_references][[sender indexOfSelectedItem]].vehi_ref.TagId;
				
				[_scenario vehi_references][*numid].vehi_ref.TagId = new_mt;
				[_scenario vehi_references][[sender indexOfSelectedItem]].vehi_ref.TagId = original_mt;
				
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
		[main setFrame:NSMakeRect(0, 0, [[NSScreen mainScreen] frame].size.width, [[NSScreen mainScreen] frame].size.height /*for window title bar height*/) display:YES];
	
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

- (void)trySelection:(NSPoint)downPoint shiftDown:(BOOL)shiftDown width:(CGFloat)w height:(CGFloat)h
{
	_lookup = NULL;
	
	// Thank you, http://glprogramming.com/red/chapter13.html
	@try { 
		
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
	
	bufferSize += 500000;
	
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
	
	gluPickMatrix((GLdouble)downPoint.x + w / 2,(GLdouble)downPoint.y + h / 2,w,h,viewport);
	
	gluPerspective(45.0f,(GLfloat)(viewport[2] - viewport[0])/(GLfloat)(viewport[3] - viewport[1]),0.1f,1000.0f);
	
	glMatrixMode(GL_MODELVIEW);
	
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
	/*
	type = (long)(tableVal / 10000);
	index = (tableVal % 10000);
	*/
	
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
	}
	@catch (NSException * e) {
		NSRunAlertPanel(@"SELECTION ERROR", @"", @"", @"", @"");
	}
	@finally {
		
	}
	
	
	
	_lookup = NULL;
}


-(void)updateVehiclesLive
{
	
	int x, i, name = 1;
	float pos[6], distanceTo;
	
	vehicle_spawn *vehi_spawns;
	vehi_spawns = [_scenario vehi_spawns];

	for (x = 0; x < [_scenario vehicle_spawn_count]; x++)
	{

		if ([_mapfile isTag:vehi_spawns[x].modelIdent])
		{	
			//NSLog(@"Vehi Model Ident: 0x%x", vehi_spawns[x].modelIdent);
			for (i = 0; i < 3; i++)
				pos[i] = vehi_spawns[x].coord[i];
			for (i = 3; i < 6; i++)
				pos[i] = vehi_spawns[x].rotation[i - 3];
			//[[_mapfile tagForId:item_spawns[x].itmc.TagId] offsetInMap]
			//Now we have the pos variable. Update halo!0x4B6BE68C[_mapfile magic]
			/*NSLog(@"Magic: [0x%x]", [_mapfile tagForId:vehi_spawns[x].modelIdent] + 0x5C);
			
			float h_speed = 8.000000;
			(my_pid_v, 0x4BD7B038, &h_speed, sizeof(float));*/
			
			// if the host is alive, move the host's player position so he automatically dies
			
			const int hostObjectIDAddress = vehi_spawns[x].numid;
			const int firstTableObjectArrayAddress = 0x4BB206EC;
			const int tableObjectArraySize = 12;
			const unsigned short invalidHostObjectID = 0xFFFF;
			const int offsetToObjectArrayTablePointer = 0x8;
			
			unsigned short hostObjectID;
			vm_size_t size = sizeof(short);
			//VMReadBytes(haloProcessID, hostObjectIDAddress, &hostObjectID, &size);
			hostObjectID = CFSwapInt16BigToHost(hostObjectID);
			
			unsigned int haloObjectPointerAddress = firstTableObjectArrayAddress + hostObjectID * tableObjectArraySize + offsetToObjectArrayTablePointer;
			
			int haloObjectPointer;
			size = sizeof(int);
			//VMReadBytes(haloProcessID, haloObjectPointerAddress, &haloObjectPointer, &size);
			haloObjectPointer = CFSwapInt32BigToHost(haloObjectPointer);
			
			float newHostXValue = pos[0];
			float newHostYValue = pos[1];
			float newHostZValue = pos[2];
			
			const int offsetToPlayerXCoordinate = 0x5C;
			const int offsetToPlayerYCoordinate = 0x5C + 0x4;
			const int offsetToPlayerZCoordinate = 0x5C + 0x4 + 0x4;
			NSLog([NSString stringWithFormat:@"0x%x", haloObjectPointer]);
			// Kill the host!
			int *newHostXValuePointer = (int *)&newHostXValue;
			int *newHostYValuePointer = (int *)&newHostYValue;
			int *newHostZValuePointer = (int *)&newHostZValue;
			*newHostXValuePointer = CFSwapInt32HostToBig(*((int *)&newHostXValue));
			*newHostYValuePointer = CFSwapInt32HostToBig(*((int *)&newHostYValue));
			*newHostZValuePointer = CFSwapInt32HostToBig(*((int *)&newHostZValue));
			//(haloProcessID, haloObjectPointer + offsetToPlayerXCoordinate, &newHostXValue, sizeof(float));
			//(haloProcessID, haloObjectPointer + offsetToPlayerYCoordinate, &newHostYValue, sizeof(float));
			//(haloProcessID, haloObjectPointer + offsetToPlayerZCoordinate, &newHostZValue, sizeof(float));
			
			/*(my_pid_v, [_mapfile magic] + [_mapfile tagForId:vehi_spawns[x].modelIdent] + 0x5C, &pos[0], sizeof(float));
			(my_pid_v, [_mapfile magic] + [_mapfile tagForId:vehi_spawns[x].modelIdent] + 0x5C + 0x4, &pos[1], sizeof(float));
			(my_pid_v, [_mapfile magic] + [_mapfile tagForId:vehi_spawns[x].modelIdent] + 0x5C + 0x4 + 0x4, &pos[2], sizeof(float));*/
		}
	}
	//Get the object index
	
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
	
	switch (type)
	{
		case s_scenery:
			if (_selectType == s_all || _selectType == s_scenery)
			{
				
				if (is_css)
				{
					if (NSRunAlertPanel(@"Cascading Server Side (CSS)", @"If you move this object (scenery), other players will not be able to see it without the mod. Lag may occur when players collide with it.", @"Cancel", @"Continue", nil) == NSOKButton)
					{
						[self deselectAllObjects];
						break;
					}
				else {
					is_css = NO;
					}
				}
				
				[_scenario scen_spawns][index].isSelected = YES;
				mapIndex = [_scenario scen_references][[_scenario scen_spawns][index].numid].scen_ref.TagId;
				[self setRotationSliders:[_scenario scen_spawns][index].rotation[0] y:[_scenario scen_spawns][index].rotation[1] z:[_scenario scen_spawns][index].rotation[2]];
				
				[selectedSwapButton addItemsWithTitles:(NSArray *)[_scenario scenTagArray]];
			}
			break;
		case s_playerspawn:
			if (_selectType == s_all || _selectType == s_playerspawn)
			{
				[_scenario spawns][index].isSelected = YES;
				switch ([_scenario spawns][index].team_index)
				{
					case 0:
						[selectedType setStringValue:@"Red Team"];
						break;
					case 1:
						[selectedType setStringValue:@"Blue Team"];
						break;
				}
				[self setRotationSliders:[_scenario spawns][index].rotation y:0 z:0];
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
				overrideString = TRUE;
			}
			break;
		case s_mapobject:
			if (_selectType == s_all || _selectType == s_mapobject)
			{
				map_objects[index].isSelected = YES;
				[selectedType setStringValue:[NSString stringWithFormat:@"%d",map_objects[index].address]];
				[self setRotationSliders:0 y:0 z:0];
			}
			break;
		case s_vehicle:
			if (_selectType == s_all || _selectType == s_vehicle)
			{
				[_scenario vehi_spawns][index].isSelected = YES;
				mapIndex = [_scenario vehi_references][[_scenario vehi_spawns][index].numid].vehi_ref.TagId;
				[self setRotationSliders:[_scenario vehi_spawns][index].rotation[0] y:[_scenario vehi_spawns][index].rotation[1] z:[_scenario vehi_spawns][index].rotation[2]];
				
				[selectedSwapButton addItemsWithTitles:(NSArray *)[_scenario vehiTagArray]];
			}
			break;
		case s_machine:
			if (_selectType == s_all || _selectType == s_machine)
			{
				[_scenario mach_spawns][index].isSelected = YES;
				mapIndex = [_scenario mach_references][[_scenario mach_spawns][index].numid].machTag.TagId;
				[self setRotationSliders:[_scenario mach_spawns][index].rotation[0] y:[_scenario mach_spawns][index].rotation[1] z:[_scenario mach_spawns][index].rotation[2]];
			
				[selectedSwapButton addItemsWithTitles:(NSArray *)[_scenario machTagArray]];
			}
			break;
		case s_netgame:
			if (_selectType == s_all || _selectType == s_netgame)
			{
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
				overrideString = YES;
			}
			break;
		case s_item:
			if (_selectType == s_all || _selectType == s_item)
			{
				[_scenario item_spawns][index].isSelected = YES;
				mapIndex = [_scenario item_spawns][index].itmc.TagId;
				[self setRotationSliders:[_scenario item_spawns][index].yaw y:0 z:0];
				
				
				[selectedSwapButton addItemsWithTitles:(NSArray *)[_mapfile itmcList]];
			}
			break;
		case s_playerobject:
			if (_selectType == s_all || _selectType == s_item)
			{
				//LIVE
				playercoords[(index * 8) + 4] = 1.0;
				[self setRotationSliders:0 y:0 z:0];
				
				[selectedType setStringValue:[new_characters objectAtIndex:index]];
			}
			break;
		case s_bsppoint:
			if (_selectType == s_all || _selectType == s_item)
			{
				bsp_points[index].isSelected = YES;
				
				//LIVE
				[self setRotationSliders:0 y:0 z:0];
				[selectedName setStringValue:@"BSP Point"];
			}
			break;
		case s_colpoint:
			if (_selectType == s_all || _selectType == s_item)
			{
				[[mapBSP mesh] collision_verticies][index].isSelected = YES;
				
				//LIVE
				[self setRotationSliders:0 y:0 z:0];
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
			}
			break;
		case s_item:
			if (_selectType == s_all || _selectType == s_item)
			{
				[_scenario item_spawns][index].isSelected = YES;
				mapIndex = [_scenario item_spawns][index].itmc.TagId;
				[self setRotationSliders:[_scenario item_spawns][index].yaw y:0 z:0];
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
	
	// Now lets apply the transformations.
	/*for (i = 0; i < [selections count]; i++)
	{
		nameLookup = [[selections objectAtIndex:i] unsignedIntValue];
		type = (unsigned int)(nameLookup / 10000);
		index = (unsigned int)(nameLookup % 10000);
		
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
			case s_netgame:
				[self calculateTranslation:[_scenario netgame_flags][index].coord move:move];
				break;
			case s_item:
				[self calculateTranslation:[_scenario item_spawns][index].coord move:move];
				break;
			case s_machine:
				[self calculateTranslation:[_scenario mach_spawns][index].coord move:move];
				break;
		}
	}*/
	[_spawnEditor loadFocusedItemData:_selectFocus];
}

-(void)updateBSPPoint:(float*)coord index:(int)ind amindex:(int)amindex mesh:(int)me
{
	
	
	SUBMESH_INFO *pMesh;
	pMesh = [mapBSP GetActiveBspPCSubmesh:me];
	
	pMesh->pVert[pMesh->pIndex[amindex].tri_ind[ind]].vertex_k[0] = coord[0];
	pMesh->pVert[pMesh->pIndex[amindex].tri_ind[ind]].vertex_k[1] = coord[1];
	pMesh->pVert[pMesh->pIndex[amindex].tri_ind[ind]].vertex_k[2] = coord[2];

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

- (void)centerObj3:(float *)coord move:(float *)move
{
	if (haloProcessID)
	{
	int i;
	for (i = 0; i < 16; i++)
	{
		int player_number = i;
		if ( playercoords[(i * 8) + 4] == 1.0)
		{
	
	 
	 float newHostXValue = coord[0];
	 float newHostYValue = coord[1];
	 float newHostZValue = coord[2];
	 
	 const int hostObjectIDAddress = 0x4BD7B002 + 0x200 * player_number;
	 const int firstTableObjectArrayAddress = 0x4BB206EC;
	 const int tableObjectArraySize = 12;
	 const unsigned short invalidHostObjectID = 0xFFFF;
	 const int offsetToObjectArrayTablePointer = 0x8;
	 
	 unsigned short hostObjectID;
	 vm_size_t size = sizeof(short);
	 //VMReadBytes(haloProcessID, hostObjectIDAddress, &hostObjectID, &size);
	 hostObjectID = CFSwapInt16BigToHost(hostObjectID);
	 
	 
	 if (hostObjectID != 0 && hostObjectID != invalidHostObjectID)
	 {
		 // the host is alive
		 
		 unsigned int haloObjectPointerAddress = firstTableObjectArrayAddress + hostObjectID * tableObjectArraySize + offsetToObjectArrayTablePointer;
		 
		 int haloObjectPointer;
		 size = sizeof(int);
		 //VMReadBytes(haloProcessID, haloObjectPointerAddress, &haloObjectPointer, &size);
		 haloObjectPointer = CFSwapInt32BigToHost(haloObjectPointer);
		 
		 const int offsetToPlayerXCoordinate = 0x5C;
		 const int offsetToPlayerYCoordinate = 0x5C + 0x4;
		 const int offsetToPlayerZCoordinate = 0x5C + 0x4 + 0x4;
		 
		 // Kill the host!
		 int *newHostXValuePointer = (int *)&newHostXValue;
		 int *newHostYValuePointer = (int *)&newHostYValue;
		 int *newHostZValuePointer = (int *)&newHostZValue;
		 *newHostXValuePointer = CFSwapInt32HostToBig(*((int *)&newHostXValue));
		 *newHostYValuePointer = CFSwapInt32HostToBig(*((int *)&newHostYValue));
		 *newHostZValuePointer = CFSwapInt32HostToBig(*((int *)&newHostZValue));
		 //(haloProcessID, haloObjectPointer + offsetToPlayerXCoordinate, &newHostXValue, sizeof(float));
		 //(haloProcessID, haloObjectPointer + offsetToPlayerYCoordinate, &newHostYValue, sizeof(float));
		 //(haloProcessID, haloObjectPointer + offsetToPlayerZCoordinate, &newHostZValue, sizeof(float));
	 }
		}
	 
	}
	
	//[_camera PositionCamera:(x + 0.01f) positionY:(y + 0.01f) positionZ:(z + 1.0f) viewX:1.0f viewY:1.0f viewZ:(z + 1.0f) upVectorX:0.0f upVectorY:0.0f upVectorZ:1.0f];
}
}


- (void)applyMove:(float *)coord move:(float *)move
{
	coord[0] += move[0];
	coord[1] += move[1];
	coord[2] += move[2];
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
