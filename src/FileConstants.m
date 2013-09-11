/*
 *  ScenarioDefs.c
 *  SparkEdit
 *
 *  Created by Michael Edgar on Mon Jul 19 2004.
 *  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
 *
 */

#include "FileConstants.h"
#import "NSFile.h"
reflexive readReflexiveFromFile(NSFile *file, long magic)
{
	reflexive retRef;
	retRef.chunkcount = [file readDword];
	retRef.offset = [file readDword]-magic;
	retRef.zero = [file readDword];
	return retRef;
}
TAG_REFERENCE readReferenceFromFile(NSFile *file, long magic)
{
	TAG_REFERENCE retRef;
	*(long *)retRef.tag = [file readDword];
	
	retRef.NamePtr = [file readDword]-magic;
	retRef.unknown = [file readDword];
	retRef.TagId = [file readDword];
	return retRef;
}