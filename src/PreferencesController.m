#import "PreferencesController.h"

@implementation PreferencesController
	IBOutlet id playerSpawnDrawDistanceSlider;
    IBOutlet id playerSpawnDrawDistanceText;
- (IBAction)save:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setFloat:[genericDrawDistanceSlider floatValue] forKey:@"GeneralDrawDistance"];
	[[NSUserDefaults standardUserDefaults] setFloat:[vehicleDrawDistanceSlider floatValue] forKey:@"VehicleDrawDistance"];
	[[NSUserDefaults standardUserDefaults] setFloat:[sceneryDrawDistanceSlider floatValue] forKey:@"SceneryDrawDistance"];
	[[NSUserDefaults standardUserDefaults] setFloat:[itemDrawDistanceSlider floatValue] forKey:@"ItemDrawDistance"];
	[[NSUserDefaults standardUserDefaults] setFloat:[playerSpawnDrawDistanceSlider floatValue] forKey:@"PlayerSpawnDrawDistance"];
	[[NSUserDefaults standardUserDefaults] setFloat:[moveSizeSlider floatValue] forKey:@"MoveSize"];

}
- (IBAction)openPreferences:(id)sender
{
	[preferencesWindow makeKeyAndOrderFront:self];
	[genericDrawDistanceSlider setFloatValue:[[NSUserDefaults standardUserDefaults] floatForKey:@"GeneralDrawDistance"]];
	[genericDrawDistanceText setFloatValue:[[NSUserDefaults standardUserDefaults] floatForKey:@"GeneralDrawDistance"]];
	[vehicleDrawDistanceSlider setFloatValue:[[NSUserDefaults standardUserDefaults] floatForKey:@"VehicleDrawDistance"]];
	[vehicleDrawDistanceText setFloatValue:[[NSUserDefaults standardUserDefaults] floatForKey:@"VehicleDrawDistance"]];
	[sceneryDrawDistanceSlider setFloatValue:[[NSUserDefaults standardUserDefaults] floatForKey:@"SceneryDrawDistance"]];
	[sceneryDrawDistanceText setFloatValue:[[NSUserDefaults standardUserDefaults] floatForKey:@"SceneryDrawDistance"]];
	[itemDrawDistanceSlider setFloatValue:[[NSUserDefaults standardUserDefaults] floatForKey:@"ItemDrawDistance"]];
	[itemDrawDistanceText setFloatValue:[[NSUserDefaults standardUserDefaults] floatForKey:@"ItemDrawDistance"]];
	[playerSpawnDrawDistanceSlider setFloatValue:[[NSUserDefaults standardUserDefaults] floatForKey:@"PlayerSpawnDrawDistance"]];
	[playerSpawnDrawDistanceText setFloatValue:[[NSUserDefaults standardUserDefaults] floatForKey:@"PlayerSpawnDrawDistance"]];
	[moveSizeSlider setFloatValue:[[NSUserDefaults standardUserDefaults] floatForKey:@"MoveSize"]];
	[moveSizeText setFloatValue:[[NSUserDefaults standardUserDefaults] floatForKey:@"MoveSize"]];
	


}
- (IBAction)sliderChanged:(id)sender
{
	if (sender == genericDrawDistanceSlider)
		[genericDrawDistanceText setFloatValue:[genericDrawDistanceSlider floatValue]];
	else if (sender == vehicleDrawDistanceSlider)
		[vehicleDrawDistanceText setFloatValue:[vehicleDrawDistanceSlider floatValue]];
	else if (sender == sceneryDrawDistanceSlider)
		[sceneryDrawDistanceText setFloatValue:[sceneryDrawDistanceSlider floatValue]];
	else if (sender == itemDrawDistanceSlider)
		[itemDrawDistanceText setFloatValue:[itemDrawDistanceSlider floatValue]];
	else if (sender == playerSpawnDrawDistanceSlider)
		[playerSpawnDrawDistanceText setFloatValue:[playerSpawnDrawDistanceSlider floatValue]];
	else if (sender == moveSizeSlider)
		[moveSizeText setFloatValue:[moveSizeSlider floatValue]];

}
@end
