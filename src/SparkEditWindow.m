#import "SparkEditWindow.h"

@implementation SparkEditWindow
- (void)keyDown:(NSEvent *)theEvent
{
	if ([[[TabView selectedTabViewItem] identifier] isEqualTo:@"BSP"])
		[BspView keyDown:theEvent];
}
@end
