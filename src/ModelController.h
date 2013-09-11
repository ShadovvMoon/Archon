/* ModelController */

#import <Cocoa/Cocoa.h>
@class HaloMap;
@class Geometry;
@class ModelView;
@class TextureView;
@class BitmapTag;
@class BspManager;
@class ScenarioTag;
@class ModelTag;
@interface ModelController : NSObject
{
    IBOutlet id LODList;
	IBOutlet id mapNameField;
    IBOutlet id ModelList;
    IBOutlet id openGLView;
	IBOutlet id textureList;
	IBOutlet id workingIndicator;
	IBOutlet id subImageList;
	IBOutlet id textureView;
	IBOutlet id BspView;
	IBOutlet id renderModePopup;
	IBOutlet id BspNumberPopup;
	HaloMap *myMap;
	NSMutableArray *models;
	ModelTag *currentModel;
	BitmapTag *currentBitmap;
	NSMutableDictionary *bitmaps;
	NSArray *bitmapArray;
}
- (IBAction)loadMap:(id)sender;
- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;
- (IBAction)changeRenderMode:(id)sender;
- (IBAction)changeBspNumber:(id)sender;
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;

@end
