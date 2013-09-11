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
	return NSApplicationMain(argc,  (const char **) argv);
}
