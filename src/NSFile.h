//
//  NSFile.h
//  DungeonSiegeEditor
//
//  Created by Michael Edgar on Sat Jun 05 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//
#define endianSwap32(x) (((x & 0xFF000000) >> 24) | ((x & 0x00FF0000) >> 8) | ((x & 0x0000FF00) << 8) | ((x & 0x000000FF) << 24))
#define endianSwap16(x) (((x & 0x00FF) << 8) | ((x & 0xFF00) >> 8))
#import <Foundation/Foundation.h>
#include <stdio.h>
//cool names
#import "FileConstants.h"

//
@interface NSFile : NSObject {
	NSString *pathToFile;
	FILE *myFile;
	BOOL littleEndian;
}

- (id)initWithPathForReading:(NSString *)path;
- (id)initWithPathForWriting:(NSString *)path;
- (void)close;
- (id)initWithPath:(NSString *)path forPermissions:(char *)perm;
- (NSString *)path;
- (void)seekToOffset:(double)offset;
- (double)offset;

- (long)filesize;

- (void)setLittleEndian:(BOOL)endian;
- (BOOL)littleEndian;

- (FILE *)cFile;

- (void)writeData:(NSData *)data;

- (DWORD)readDword;
- (void)writeDword:(DWORD)dword;
- (WORD)readWord;
- (float)readFloat;
- (void)writeWord:(WORD)word;
- (BYTE)readByte;
- (void)writeByte:(BYTE)byte;
- (void)readIntoStruct:(void *)myStruct size:(int)size;
- (void)writeDataStruct:(void *)myStruct size:(int)size;
- (NSString *)readStringOfLength:(unsigned long)size;
- (NSString *)readCString;
- (NSData *)readDataOfLength:(long long)len;
- (void)skipBytes:(long)size;
@end
