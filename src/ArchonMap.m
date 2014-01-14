//
//  ArchonMap.m
//  Archon
//
//  Created by Samuco on 30/11/2013.
//
//

#import "ArchonMap.h"

@implementation ArchonMap

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"ArchonMap";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    
    [[NSApp delegate] closeWelcomeWindow];
    
    [renderView loadPrefs];
    [[renderView openGLContext] makeCurrentContext];
    

    if (mapfile)
    {
        int success = [mapfile loadMap];
        
        switch (success)
        {
            case 0:
                [mainWindow makeKeyAndOrderFront:self];
                
                [renderView setPID:0];
                [renderView setMapObject:mapfile];
                
                break;
            case 1:
                break;
            case 2:
                CSLog(@"The map name is invalid!");
                break;
            case 3:
                CSLog(@"Could not open the map!");
                break;
            default:
                break;
        }
    }
}

-(BOOL)writeToURL:(NSURL *)url ofType:(NSString *)type error:(NSError **)error
{
    return [mapfile saveMapToPath:[url path]];
    

}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    mapfile = [[HaloMap alloc] initWithMapdata:data bitmaps:[[NSUserDefaults standardUserDefaults] stringForKey:@"bitmapFileLocation"]];
    return YES;
}

/*
-(BOOL)readFromURL:(NSURL *)url ofType:(NSString *)type error:(NSError **)error;
{
    mapurl = [url retain];
    
    CSLog(@"Opening %@", [mapurl path]);
    mapfile = [[HaloMap alloc] initWithMapfiles:[mapurl path] bitmaps:[[NSUserDefaults standardUserDefaults] stringForKey:@"bitmapFileLocation"]];
    int success = [mapfile readMap];
    
    return YES;
}
 */

-(id)renderView
{
    return renderView;
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

@end
