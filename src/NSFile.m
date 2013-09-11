//
//  NSFile.m
//  DungeonSiegeEditor
//
//  Created by Michael Edgar on Sat Jun 05 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "NSFile.h"




@implementation NSFile

- (void)writeData:(NSData *)data
{

	fwrite([data bytes],[data length],1,myFile);
}

- (id)initWithPathForReading:(NSString *)path
{
	return [self initWithPath:path forPermissions:"r"];
}
- (id)initWithPathForWriting:(NSString *)path
{
	return [self initWithPath:path forPermissions:"w"];
}
- (id)initWithPath:(NSString *)path forPermissions:(char *)perm
{
	if (self = [super init])
	{
		pathToFile = [[path copy] autorelease];
		myFile = fopen([path cString],perm);
		littleEndian = NO;
	}
	return self;
}
- (void)close
{
	fclose(myFile);
}
- (long)filesize
{
	return [[[[NSFileManager defaultManager] fileAttributesAtPath:pathToFile traverseLink:NO] objectForKey:@"NSFileSize"] longValue];
}
- (void)seekToOffset:(double)offset
{

	fseek(myFile,offset,SEEK_SET);
}
- (NSString *)readCString
{
	char *buffer;
	buffer = malloc(sizeof(char)*1024);
	char tempChar;
	char *bufferPointer = buffer;
	do
	{
		tempChar = [self readByte];
		*buffer=tempChar;
		buffer++;
	} while (tempChar != 0x00);
	return [NSString stringWithCString:bufferPointer];
}
- (void)skipBytes:(long)size
{
	[self seekToOffset:[self offset]+size];
}
- (double)offset
{
	return ftell(myFile);
}

- (void)setLittleEndian:(BOOL)endian
{
	littleEndian = endian;
}
- (BOOL)littleEndian
{
	return littleEndian;
}
- (FILE *)cFile
{
	return myFile;
}
- (NSData *)readDataOfLength:(long long)len
{
	char *buffer;
	buffer = malloc(len);
	if (buffer == NULL)
		NSLog(@"UH OH");
	fread(&buffer[0],len,1,myFile);
	NSData *retData = [[NSData alloc] initWithBytes:buffer length:len];
	return retData;
}
- (DWORD)readDword
{
	DWORD result;
	fread(&result,sizeof(DWORD),1,myFile);
	if (littleEndian) result = endianSwap32(result);
	return result;
}
- (float)readFloat
{
	DWORD tempDword = [self readDword];
	float *retFloat = (float*)&tempDword;
	return *retFloat;
	//return *(float*)(&[self readDword]);
//	float result;
//	fread(&result,sizeof(float),1,myFile);
//	if (littleEndian) result = (float)endianSwap32((long)result);
//	return result;
}
- (void)writeDword:(DWORD)dword
{
	fwrite(&dword,sizeof(DWORD),1,myFile);
}
- (WORD)readWord
{
	WORD result;
	fread(&result,sizeof(WORD),1,myFile);
	if (littleEndian) result = endianSwap16(result);
	return result;
}
- (void)writeWord:(WORD)word
{
	fwrite(&word,sizeof(WORD),1,myFile);
}
- (BYTE)readByte
{
	BYTE result;
	fread(&result,sizeof(BYTE),1,myFile);

	return result;
}
- (void)writeByte:(BYTE)byte
{
	fwrite(&byte,sizeof(BYTE),1,myFile);
}
- (void)readIntoStruct:(void *)myStruct size:(int)size
{
	fread(myStruct,size,1,myFile);
}
- (void)writeDataStruct:(void *)myStruct size:(int)size
{
	fwrite(myStruct,size,1,myFile);
}
- (NSString *)readStringOfLength:(unsigned long)size
{
	char buffer[size];
	fread(buffer,size,1,myFile);
	return [[[NSString stringWithCString:buffer length:size] retain] autorelease];
}
- (NSString *)path
{
	return [[pathToFile retain] autorelease];
}
@end
