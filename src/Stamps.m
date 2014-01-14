//
//  CoreStamps.m
//  RemarksPDF
//
//  Created by Samuco on 16/09/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "Stamps.h"

@interface MyImageObject : NSObject
{
    NSString * mPath;
}
@end
@implementation MyImageObject

- (void) dealloc
{
    [mPath release];
    [super dealloc];
}

- (void) setPath:(NSString *) path
{
    if(mPath != path){
        [mPath release];
        mPath = [path retain];
    }
}

- (NSString *)  imageRepresentationType
{
    return IKImageBrowserPathRepresentationType;
}

- (id)  imageRepresentation
{
    return mPath;
}

- (NSString *) imageUID
{
    return mPath;
}


@end

@implementation Stamps

-(void)reclick:(NSTimer*)t
{
    [libraries selectItemAtIndex:0];
    [self setLibrary:[libraries itemAtIndex:0] ];
  //  [self setLibrary:[t userInfo]];
}

-(IBAction)setLibrary:(id)sender
{
    NSString *top_path = [[sender menu] title];
    NSString *folder = [sender title];
    
    NSString *images_path = [NSString stringWithFormat:@"%@%@", top_path, folder];
    [libraries setTitle:folder];
    
    NSString *stamp_path = @"/tmp/Archon/";
    [[NSFileManager defaultManager] createDirectoryAtPath:stamp_path attributes:nil];
    [self loadImages:images_path];
}

-(NSMenu*)pathToMenu:(NSString*)path
{
    NSMenu *the_menu = [[NSMenu alloc] initWithTitle:path];
    
    //Get the folders
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    for (int i = 0; i < [contents count]; i++)
    {
        NSString *item_name = [contents objectAtIndex:i];
        
        BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@%@", path,item_name]  isDirectory:&isDirectory];
        
        if (isDirectory)
        {
            
            NSMenu *path_menu = [[NSMenu alloc] initWithTitle:item_name];
            NSMenuItem *new_menu = [[NSMenuItem alloc] initWithTitle:item_name action:@selector(setLibrary:) keyEquivalent:@""];
            
            
            [new_menu setTarget:self];
            [new_menu setSubmenu:[self pathToMenu:[NSString stringWithFormat:@"%@%@/", path,item_name]]];
            [the_menu addItem:new_menu];
        }
    }

    if ([[the_menu itemArray] count] == 0)
    {
        return nil;
    }
    
    return the_menu;
}

- (void) addAnImageWithPath:(NSString *) path
{
    MyImageObject *p;
	
    p = [[MyImageObject alloc] init];
    [p setPath:path];
    [mImportedImages addObject:p];
    [p release];
}

- (void) dealloc
{
    [mImages release];
    [mImportedImages release];
    [super dealloc];
}

- (void) updateDatasource
{
    [mImages addObjectsFromArray:mImportedImages];
    [mImportedImages removeAllObjects];
    [mImageBrowser reloadData];
}

- (int) numberOfItemsInImageBrowser:(IKImageBrowserView *) view
{
    return [mImages count];
}

- (id) imageBrowser:(IKImageBrowserView *) view itemAtIndex:(int) index
{
    return [mImages objectAtIndex:index];
}

- (void) imageBrowserSelectionDidChange:(IKImageBrowserView *) aBrowser
{
	
}

-(void)imageBrowser:(IKImageBrowserView *)aBrowser cellWasDoubleClickedAtIndex:(NSUInteger)index;
{
    
    MyImageObject *imagess = [mImages objectAtIndex:index];
    NSString *image_path = [imagess imageRepresentation];
    
    NSImage *the_image = [[NSImage alloc] initWithContentsOfFile:image_path];
    
	NSDocument *current = [[NSDocumentController sharedDocumentController] currentDocument];
	[current createStamp:the_image];
}

- (void) addImagesWithPath:(NSString *) path recursive:(BOOL) recursive
{
    int i, n;
    BOOL dir;
	
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dir];
    if(dir){
        NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
        n = [content count];
		for(i=0; i<n; i++){
            if(recursive)
				[self addImagesWithPath:
				 [path stringByAppendingPathComponent:
				  [content objectAtIndex:i]]
							  recursive:NO];
            else
				[self addAnImageWithPath:
				 [path stringByAppendingPathComponent:
				  [content objectAtIndex:i]]];
        }
    }
    else
        [self addAnImageWithPath:path];
}

-(void) addImagesWithPaths:(NSArray *) paths
{
    int i, n;
	
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [paths  retain];
	
    n = [paths count];
    for(i=0; i<n; i++){
        NSString *path = [paths objectAtIndex:i];
        [self addImagesWithPath:path recursive:YES];
    }
	
    [self performSelectorOnMainThread:@selector(updateDatasource)
                           withObject:nil
                        waitUntilDone:YES];
	
    [paths release];
    [pool release];
}

-(void)update:(NSTimer*)t
{
    [self updateDatasource];
}

-(void)loadImages:(NSString*)path
{
    
    
    //Load up some images
    mImages = [[NSMutableArray alloc] init];
    mImportedImages = [[NSMutableArray alloc] init];
    
    [self addImagesWithPath:path recursive:YES];
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(update:) userInfo:nil repeats:NO];
}

-(void)updateStart:(NSTimer*)t
{
    
    NSString *stamp_path = @"/tmp/Archon/";
    NSMenu *the_menu = [self pathToMenu:stamp_path];
    [libraries setMenu:the_menu];
    
    [self setLibrary:[[the_menu itemArray] objectAtIndex:0]];
}

-(IBAction)showStamps:(id)sender
{
    NSString *stamp_path = @"/tmp/Archon";
    [[NSWorkspace sharedWorkspace] openFile:stamp_path];
}

-(void)openStamps
{
    [stamp_window makeKeyAndOrderFront:nil];
}

-(void)refresh
{
    [self updateStart:nil];
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStart:) name:NSPopUpButtonWillPopUpNotification object:libraries];
        
        /*
        NSBundle *main = [NSBundle bundleForClass:[self class]];
        NSString *smiley_path = [NSString stringWithFormat:@"%@/Stamps/RemarksPDF/Smiley/", [main resourcePath]];
        [self addImagesWithPath:smiley_path recursive:YES];
        
        [self loadImages:smiley_path];*/
        
    }
    return self;
}



- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
	int low_res=0;
	int high_res = 1;
    NSData *data = nil;
    NSString *errorDescription;
    NSPasteboard *pasteboard = [sender draggingPasteboard];
	
    if ([[pasteboard types] containsObject:NSFilenamesPboardType])
        data = [pasteboard dataForType:NSFilenamesPboardType];
    if(data){
        NSArray *filenames = [NSPropertyListSerialization
							  propertyListFromData:data
							  mutabilityOption:kCFPropertyListImmutable
							  format:nil
							  errorDescription:&errorDescription];
        int i;
        int n = [filenames count];
        for(i=0; i<n; i++)
		{
			NSImage *sourceImage = [NSImage alloc];
			[sourceImage initWithContentsOfFile:[filenames objectAtIndex:i]];
			

			if ([mImages count] > 0)
			{
				MyImageObject *imagess = [mImages objectAtIndex:0];
				NSString *image_path = [[imagess imageRepresentation] stringByDeletingLastPathComponent ];
				image_path = [image_path stringByAppendingFormat:@"/"];
				

				
				NSString *name = [[filenames objectAtIndex:i] lastPathComponent];//[[NSFileManager defaultManager] displayNameAtPath:[filenames objectAtIndex:i]];
			//	name = [name stringByAppendingFormat:@".%@", [[filenames objectAtIndex:i] pathExtension]];
				//CSLog(name);
				if (![[NSFileManager defaultManager] fileExistsAtPath:[image_path stringByAppendingString: name]])
				{
					//SAVE AS PNG TO SAVE SPACE
					NSBitmapImageRep *bits = [[sourceImage representations] objectAtIndex: 0];
					
					NSData *data;
					data = [bits representationUsingType:NSPNGFileType properties: nil];
					
					
					[data writeToFile:[image_path stringByAppendingString:name] atomically:YES];
					
					[self loadImages:image_path];
					[mImageBrowser reloadData];
					
					break;
				}
				
			
			}
			
			//NSString *stamp_path = [NSString stringWithFormat:@"%@/Stamps/", [main resourcePath]];
		}
	}
}



- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    return NSDragOperationCopy;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    return NSDragOperationCopy;
}



- (void)keyDown:(NSEvent *)theEvent
{
    //Handle key press
    NSString *characters = [theEvent characters];
	unichar character = [characters characterAtIndex:0];
	//CSLog(@"%x", character);
	if (character == NSDeleteCharacter || character == NSBackspaceCharacter)
	{

		if ([[mImageBrowser selectionIndexes] firstIndex] < [mImages count])
		{
			
			if ([[mImageBrowser selectionIndexes] firstIndex] >= 0)
			{
			
				MyImageObject *imagess = [mImages objectAtIndex:[[mImageBrowser selectionIndexes] firstIndex]];
				NSString *image_path = [imagess imageRepresentation];
				
				if (image_path)
				{
					if ([[NSFileManager defaultManager] fileExistsAtPath:image_path])
					{
						int kill = NSRunAlertPanel(@"Confirm deletion of stamp.", @"Are you sure you want to delete this stamp?", @"Delete", @"Cancel", nil);
						if (kill==NSOKButton)
						{
							[[NSFileManager defaultManager] removeItemAtPath:image_path error:nil];
						}
					}
				}
				
				[self loadImages:[[image_path stringByDeletingLastPathComponent] stringByAppendingFormat:@"/"]];
				[mImageBrowser reloadData];
					
			}
			
		}
	}
}

-(IBAction)deleteStamp:(id)sender
{
	
	MyImageObject *imagess = [mImages objectAtIndex:[[mImageBrowser selectionIndexes] firstIndex]];
    NSString *image_path = [imagess imageRepresentation];
    
	if (image_path)
	{
		if ([[NSFileManager defaultManager] fileExistsAtPath:image_path])
		{
			int kill = NSRunAlertPanel(@"Confirm deletion of stamp.", @"Are you sure you want to delete this stamp?", @"Delete", @"Cancel", nil);
			if (kill==NSOKButton)
			{
				[[NSFileManager defaultManager] removeItemAtPath:image_path error:nil];
			}
		}
	}
	
	[self loadImages:[[image_path stringByDeletingLastPathComponent] stringByAppendingFormat:@"/"]];
	[mImageBrowser reloadData];

	
	//MyImageObject *imagess = [mImages objectAtIndex:0];
	//NSString *image_path = [[imagess imageRepresentation] stringByDeletingLastPathComponent ];
	
	
	
	
}



@end
