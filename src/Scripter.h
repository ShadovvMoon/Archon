//
//  Scripter.h
//  swordedit
//
//  Created by sword on 5/28/08.
//  Copyright 2008 sword Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "HaloMap.h"
#import "Scenario.h"

@interface Scripter : NSObject {
	HaloMap *_mapfile;
	Scenario *_scenario;
}

@end
