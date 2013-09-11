/*
 *  FileConstants.h
 *  SparkEdit
 *
 *  Created by Michael Edgar on Mon Jun 21 2004.
 *  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
 *
 */
@class NSFile;
typedef char BYTE;
typedef short WORD;
typedef unsigned short WCHAR;
typedef char CHAR;
typedef int DWORD;
typedef int FOURCC;
typedef struct
{
	long chunkcount;
	long offset;
	long zero;
} reflexive;
typedef struct
{
  char tag[4];
  long NamePtr;
  long unknown;
  long TagId;
}TAG_REFERENCE;
typedef struct
{
	char classA[4];
	char classB[4];
	char classC[4];
	long ident;
	long stringOffset;
	long offset;
	long zeros[2];
} tag;
typedef struct
{
  float min[3];
  float max[3];
}BOUNDING_BOX;
reflexive readReflexiveFromFile(NSFile *file, long magic);
TAG_REFERENCE readReferenceFromFile(NSFile *file, long magic);