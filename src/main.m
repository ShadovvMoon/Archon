//
//  main.m
//  swordedit
//
//  Created by Fred Havemeyer on 10/21/07.
//  Copyright __MyCompanyName__ 2007. All rights reserved.
//

#import <Cocoa/Cocoa.h>
char *gExecutablePath = NULL;

int main(int argc, char *argv[])
{
	gExecutablePath = argv[0];	
	
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = -1;
    @try {
        retVal = NSApplicationMain(argc,  (const char **) argv);
    }
    @catch (NSException* exception) {
        NSLog(@"Uncaught exception: %@", exception.description);
        NSLog(@"Stack trace: %@", [exception callStackSymbols]);
    }
    [pool release];
    return retVal;
}
