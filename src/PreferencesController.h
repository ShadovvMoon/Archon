/* PreferencesController */

#import <Cocoa/Cocoa.h>

@interface PreferencesController : NSObject
{
    IBOutlet id genericDrawDistanceSlider;
    IBOutlet id genericDrawDistanceText;
	IBOutlet id vehicleDrawDistanceSlider;
    IBOutlet id vehicleDrawDistanceText;
	IBOutlet id sceneryDrawDistanceSlider;
    IBOutlet id sceneryDrawDistanceText;
	IBOutlet id itemDrawDistanceSlider;
    IBOutlet id itemDrawDistanceText;
	IBOutlet id playerSpawnDrawDistanceSlider;
    IBOutlet id playerSpawnDrawDistanceText;
	IBOutlet id moveSizeSlider;
    IBOutlet id moveSizeText;
	IBOutlet id preferencesWindow;
}
- (IBAction)save:(id)sender;
- (IBAction)openPreferences:(id)sender;
- (IBAction)sliderChanged:(id)sender;
@end
