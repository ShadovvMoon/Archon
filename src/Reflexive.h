//
//  Reflexive.h
//  SparkEdit
//
//  Created by Michael Edgar on Mon Jul 19 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NSFile;

@interface Reflexive : NSObject {
	long count;
	long offset;
	long zero;
}
- (id)initWithFile:(NSFile *)file magic:(long)magic;
- (long)count;
- (long)offset;

@end
