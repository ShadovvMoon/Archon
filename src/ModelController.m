#import "ModelController.h"
#import "HaloMap.h"
#import "ModelView.h"
#import "TextureView.h"
#import "ScenarioTag.h"
#import "BspView.h"
#import "Geometry.h"
#import "BitmapTag.h"
#import "BspManager.h"
#import "ModelTag.h"
#import "NSStringInitWithNumberCategory.h"
@implementation ModelController

- (IBAction)loadMap:(id)sender
{
	[workingIndicator startAnimation:self];
	NSOpenPanel *op = [NSOpenPanel openPanel];
	int ans;
	ans = [op runModalForTypes:[NSArray arrayWithObjects:@"map",nil]];
	if (ans == NSOKButton)
	{
		if (myMap)
			[myMap release];
		myMap = [[HaloMap alloc] initWithPath:[op filename]];
		models = [myMap models];
		bitmaps = [myMap bitmaps];
	}
	[BspView setManager:[[myMap myScenario] myManager]];
	[BspView setScenario:[myMap myScenario]];
	//set up the "number of bsp list"
	[BspNumberPopup removeAllItems];
	int x;
	int max = [[[myMap myScenario] myManager] GetNumberOfBsps];
	for (x=0;x<max;x++)
		[BspNumberPopup addItemWithTitle:[NSString stringWithInt:x+1]];
		
	[models sortUsingDescriptors:[NSArray arrayWithObjects:[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES],nil]];
	bitmapArray = [bitmaps allValues];
	bitmapArray = [bitmapArray sortedArrayUsingDescriptors:[NSArray arrayWithObjects:[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES],nil]];
	bitmapArray = [bitmapArray retain];
	[mapNameField setStringValue:[NSString stringWithFormat:@"%@%@",@"Map: ",[myMap mapName]]];
	[ModelList reloadData];
	[textureList reloadData];
	[workingIndicator stopAnimation:self];
}
- (IBAction)changeBspNumber:(id)sender
{
	[workingIndicator startAnimation:self];
	[[[myMap myScenario] myManager] setActiveBsp:[sender indexOfSelectedItem]];
	[BspView setNeedsDisplay:YES];
	[workingIndicator stopAnimation:self];
}
- (IBAction)zoomIn:(id)sender
{
	[openGLView increaseZoom:0.1f];
}
- (IBAction)zoomOut:(id)sender
{
	[openGLView increaseZoom:-0.1f];
}
- (IBAction)changeRenderMode:(id)sender
{
	[BspView setRenderMode:[sender indexOfSelectedItem] + 1];
	[BspView setNeedsDisplay:YES];
}

- (void)awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(tableViewSelectionDidChange:)
		name:NSTableViewSelectionDidChangeNotification
		object:ModelList];

	
	[ModelList setRowHeight:12];

}
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if (aTableView == ModelList)
		return [models count];
	else if (aTableView == LODList)
		return [currentModel submodelCount];
	else if (aTableView == textureList)
		return [bitmapArray count];
	else if (aTableView == subImageList)
		return [currentBitmap imageCount];
	return 0;
}
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if (aTableView == ModelList)
		return [(ModelTag *)[models objectAtIndex:rowIndex] name];
	else if (aTableView == LODList)
		return [NSString stringWithFormat:@"%@%@",@"LOD ",[NSString stringWithInt:rowIndex]];
	else if (aTableView == textureList)
		return [(BitmapTag *)[bitmapArray objectAtIndex:rowIndex] name];
	else if (aTableView == subImageList)
		return [NSString stringWithFormat:@"%@%@",@"Image ",[NSString stringWithInt:rowIndex]];
	return @"";
}
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	[aCell setFont:[NSFont userFontOfSize:10]];
}
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == ModelList)
	{
		currentModel = (ModelTag *)[models objectAtIndex:[[aNotification object] selectedRow]];
		
		[LODList reloadData];
		if ([LODList selectedRow] != -1)
		{
			
			[openGLView setGeometry:[currentModel geoAtIndex:[LODList selectedRow]]];
			[[currentModel geoAtIndex:[LODList selectedRow]] loadBitmaps];
			[openGLView setNeedsDisplay:YES];
		
		}
	}
	else if ([aNotification object] == LODList)
	{
		if ([[aNotification object] selectedRow] != -1)
		{
			[[currentModel geoAtIndex:[LODList selectedRow]] loadBitmaps];
			[openGLView setGeometry:[currentModel geoAtIndex:[LODList selectedRow]]];
			[openGLView setNeedsDisplay:YES];
		}
	}
	else if ([aNotification object] == textureList)
	{
		if (currentBitmap != nil)
			[currentBitmap freeImagePixels];
		currentBitmap = (BitmapTag *)[bitmapArray objectAtIndex:[textureList selectedRow]];
		[subImageList reloadData];
		if ([subImageList selectedRow] != -1)
		{
			
			[textureView setBitmap:[bitmapArray objectAtIndex:[textureList selectedRow]] withIndex:[subImageList selectedRow]];
			[textureView loadBitmap];
			[textureView setNeedsDisplay:YES];
		
		}
	
	}
	else if ([aNotification object] == subImageList)
	{
		if ([subImageList selectedRow] != -1)
		{
			
			[textureView setBitmap:[bitmapArray objectAtIndex:[textureList selectedRow]] withIndex:[subImageList selectedRow]];
			[textureView loadBitmap];
			[textureView setNeedsDisplay:YES];
		
		}
	
	}
}
@end
