//
//  CoreStamps.h
//  RemarksPDF
//
//  Created by Samuco on 16/09/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

//#import "CoreDocument.h"

@interface Stamps : NSObject
{
    //The image browser
	IBOutlet id mImageBrowser;
    NSMutableArray * mImages;
    NSMutableArray * mImportedImages;
    
    IBOutlet NSPopUpButton *libraries;
    IBOutlet NSPanel *stamp_window;
}

- (void) addAnImageWithPath:(NSString *) path;
- (void) addImagesWithPath:(NSString *) path recursive:(BOOL) recursive;
-(IBAction)showStamps:(id)sender;
-(IBAction)deleteStamp:(id)sender;
@end
