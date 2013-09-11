//
//  AboutBox.m
//  swordedit
//
//  Created by Fred Havemeyer on 5/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AboutBox.h"


@implementation AboutBox
static AboutBox *sharedInstance = nil;

+ (AboutBox *)sharedInstance
{
	return sharedInstance ? sharedInstance : [[self alloc] init];
}
- (id)init
{
	if (sharedInstance)
		[self dealloc];
	else
		sharedInstance = [super init];
	return sharedInstance;
}
- (IBAction)showPanel:(id)sender
{
	if (!appNameField)
	{
		NSWindow *theWindow;
		NSString *creditsPath;
		NSAttributedString *creditsString;
		NSString *appName;
		NSString *versionString;
		NSString *copyrightString;
		NSDictionary *infoDictionary;
		CFBundleRef localInfoBundle;
		NSDictionary *localInfoDict;
		
		if (![NSBundle loadNibNamed:@"AboutBox" owner:self])
		{
			NSLog(@"Failed to load AboutBox.nib");
			NSBeep();
			return;
		}
		
		theWindow = [appNameField window];
		
		infoDictionary = [[NSBundle mainBundle] infoDictionary];

		
		localInfoBundle = CFBundleGetMainBundle();
		localInfoDict = (NSDictionary *)CFBundleGetLocalInfoDictionary(localInfoBundle);
		
		// Set the app name field
		appName = @"swordedit 'starlight'";
		[appNameField setStringValue:appName];
	
		// Set the about box window title
		[theWindow setTitle:[NSString stringWithFormat:@"About %@", appName]];
		
		// Setup the version field
		versionString = [infoDictionary objectForKey:@"CFBundleVersion"];
        [versionField setStringValue:[NSString stringWithFormat:@"Version: %@", 
                                                          versionString]];
		
		// Setup our credits
		creditsPath = [[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtf"];
		creditsString = [[NSAttributedString alloc] initWithPath:creditsPath
								documentAttributes:nil];
		
		[creditsField replaceCharactersInRange:NSMakeRange(0,0) 
										withRTF:[creditsString RTFFromRange:NSMakeRange(0, [creditsString length])
										documentAttributes:nil]];
										
		// Setup the copyright field
		copyrightString = [localInfoDict objectForKey:@"NSHumanReadableCopyright"];
		[copyrightField setStringValue:copyrightString];
		
		// Prepare some scroll info
		maxScrollHeight = [[creditsField string] length];
		
		// Setup the window
		[theWindow setExcludedFromWindowsMenu:YES];
		[theWindow setMenu:nil];
		[theWindow center];
	}
	if (![[appNameField window] isVisible])
	{
		currentPosition = 0;
		restartAtTop = NO;
		startTime = [NSDate timeIntervalSinceReferenceDate] + 3.0;
		[creditsField scrollPoint:NSMakePoint(0,0)];
	}
	[[appNameField window] makeKeyAndOrderFront:nil];
}
- (void)windowDidBecomeKey:(NSNotification *)notification
{
	scrollTimer = [NSTimer scheduledTimerWithTimeInterval:(1/4)
						target:self 
						selector:@selector(scrollCredits:) 
						userInfo:nil
						repeats:YES];
}
- (void)windowDidResignKey:(NSNotification *)notification
{
	[scrollTimer invalidate];
}
- (void)scrollCredits:(NSTimer *)timer
{
	if ([NSDate timeIntervalSinceReferenceDate] >= startTime)
	{
		if (restartAtTop)
		{
			startTime = [NSDate timeIntervalSinceReferenceDate] + 3.0;
			restartAtTop = NO;
			
			[creditsField scrollPoint:NSMakePoint(0,0)];
			return;
		}
		if (currentPosition >= maxScrollHeight)
		{
			startTime = [NSDate timeIntervalSinceReferenceDate] + 3.0;
			
			currentPosition = 0;
			restartAtTop = YES;
		}
		else
		{
			[creditsField scrollPoint:NSMakePoint(0, currentPosition)];
			currentPosition += 0.01;
		}
	}
}
@synthesize appNameField;
@synthesize copyrightField;
@synthesize creditsField;
@synthesize versionField;
@synthesize scrollTimer;
@synthesize currentPosition;
@synthesize maxScrollHeight;
@synthesize startTime;
@synthesize restartAtTop;
@end
