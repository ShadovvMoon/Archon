//
//  AppController.h
//  swordedit
//
//  Created by sword on 10/21/07.
//  Copyright 2007 sword Inc. All rights reserved.
//
//	sword@clanhalo.net
//

#import <Cocoa/Cocoa.h>

//#import <PreferencePanes/NSPreferencePane.h>

#import "HaloMap.h"

@class BitmapView;
@class ModelView;
@class SpawnEditorController;

@interface AppController : NSObject {
	IBOutlet NSWindow *mainWindow;
    IBOutlet NSWindow *connectWindow;
    IBOutlet NSTextField *server_ip;
    IBOutlet NSTextField *server_port;
	IBOutlet RenderView *rendView;
	IBOutlet NSTextField *opened;
	IBOutlet SpawnEditorController *spawnEditor;
	
	IBOutlet BitmapView *bitmapView;
	
    IBOutlet NSWindow *preferencesWindow;
	IBOutlet NSWindow *loadWindow;
	IBOutlet NSProgressIndicator *loadProgressBar;
	IBOutlet NSTextView *loadText;
	IBOutlet NSScrollView *outputScroller;
		IBOutlet NSButton *color;
	IBOutlet NSTextField *bitmapLocationText;
	
	IBOutlet NSWindow *prefsWindow;
	IBOutlet NSWindow *selecte;
	IBOutlet NSProgressIndicator *tpro;
	BOOL firstTime;
	int haloProcessID;
	
	NSMutableDictionary *newGlobalPreferences;
	NSDictionary *globalPreferences;

	NSUserDefaults *userDefaults;

	HaloMap *mapfile;
	NSString *bitmapFilePath;
    
    IBOutlet NSWindow *selectionWindow;
    IBOutlet NSWindow *editorWindow;
    IBOutlet NSWindow *renderingWindow;
    IBOutlet NSWindow *selectionSWindow;
    
    IBOutlet NSMenu *recentMenu;
    
    
    IBOutlet NSWindow *welcomeWindow;
	//NSString *opened;
    
    
    
    BOOL serverStarted;
    
    int server_sock;
    BOOL hasServer;
    
    int tickCountdown;
    BOOL connectionTried;
    
    int maxsocks;
    
    int clientsock[50];
    
    BOOL usingSocket[50];
    struct sockaddr_in *udpsockets;
    
    int serversock;
    fd_set fds;
    
    NSMutableDictionary *vehicle_tags;
    
    int numsocks;
}
- (IBAction)startServer:(id)sender;
- (IBAction)connect:(id)sender;
- (IBAction)connectToServer:(id)sender;
- (IBAction)showPreferences:(id)sender;
- (void)awakeFromNib;
-(int)PID;
- (IBAction)loadMap:(id)sender;
- (IBAction)saveFile:(id)sender;
- (IBAction)close:(id)sender;
-(void)OpenMap:(NSString *)t;
- (IBAction)showAboutBox:(id)sender;
- (int)loadMapFile:(NSString *)location;
- (void)closeMapFile;
- (void)loadPrefs;
- (void)runIntroShit;
- (BOOL)selectBitmapLocation;
- (IBAction)setNewBitmaps:(id)sender;
+ (void)aMethod:(id)param;
-(void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)finishedPlaying;
@end
