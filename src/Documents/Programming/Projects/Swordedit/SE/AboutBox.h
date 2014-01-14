//
//  AboutBox.h
//  swordedit
//
//  Created by Fred Havemeyer on 5/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AboutBox : NSObject
{
    IBOutlet id appNameField;
    IBOutlet id copyrightField;
    IBOutlet id creditsField;
    IBOutlet id versionField;
    NSTimer *scrollTimer;
    float currentPosition;
    float maxScrollHeight;
    NSTimeInterval startTime;
    BOOL restartAtTop;
}
+ (AboutBox *)sharedInstance;
- (IBAction)showPanel:(id)sender;
- (void)windowDidBecomeKey:(NSNotification *)notification;
- (void)windowDidResignKey:(NSNotification *)notification;
- (void)scrollCredits:(NSTimer *)timer;
@property (retain) id appNameField;
@property (retain) id copyrightField;
@property (retain) id creditsField;
@property (retain) id versionField;
@property (retain) NSTimer *scrollTimer;
@property float currentPosition;
@property float maxScrollHeight;
@property NSTimeInterval startTime;
@property BOOL restartAtTop;
@end
