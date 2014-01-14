//
//  ArchonMap.h
//  Archon
//
//  Created by Samuco on 30/11/2013.
//
//

#import <Cocoa/Cocoa.h>
#import "RenderView.h"

@interface ArchonMap : NSDocument
{
    IBOutlet NSWindow *mainWindow;
    IBOutlet RenderView *renderView;
    HaloMap *mapfile;
    
    NSURL *mapurl;
}
@end
