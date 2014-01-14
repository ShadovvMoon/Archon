//
//  main.m
//  swordedit
//
//  Created by Fred Havemeyer on 10/21/07.
//  Copyright __MyCompanyName__ 2007. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifndef MACVERSION
#include <glew.h>
#endif

char *gExecutablePath = NULL;
/*
void CSLog(int n, ...)
{
    register int i;
    int max, a;
    va_list ap;
    
    va_start(ap, n);
    max = va_arg(ap, int);
    for(i = 2; i <= n; i++) {
        if((a = va_arg(ap, int)) > max)
            max = a;
    }
    
    va_end(ap);
}*/
int main(int argc, char *argv[])
{
	gExecutablePath = argv[0];
 
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = -1;
    @try
    {
        retVal = NSApplicationMain(argc, (const char **) argv);
        NSLog(@"Closing?");
    }
    @catch (NSException* exception) {
        CSLog(@"Uncaught exception: %@", exception.description);
       // CSLog(@"Stack trace: %@", [exception callStackSymbols]);
    }
    [pool release];
    return retVal;
}
