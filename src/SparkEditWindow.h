/* SparkEditWindow */

#import <Cocoa/Cocoa.h>

@interface SparkEditWindow : NSWindow
{
    IBOutlet id BspView;
    IBOutlet id TabView;
}
- (void)keyDown:(NSEvent *)theEvent;
@end
