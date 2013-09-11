//
//  HaloMap.h
//  swordedit
//
//  Created by Fred Havemeyer on 5/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "defines.h"

#import "MapTag.h"


#define reflexiveSize = 0xC

@class RenderView;
@class Scenario;
@class BSP;
@class ModelTag;
@class BitmapTag;
@class TextureManager;

enum MapFileReadResult
{
	success,
	file_already_open,
	wrong_version,
	unknown
};

@interface HaloMap : NSObject {
	NSString *mapName;
	FILE *mapFile;
	
	NSString *bitmapFilePath;
	FILE *bitmapsFile;
	
	Scenario *mapScenario;
	BSP *bspHandler;
	
	TextureManager *_texManager;

	bool isPPC;

	long _magic;
	
	Header mapHeader;
	IndexHeader indexHead;
	
	NSMutableArray *tagArray;
	NSMutableDictionary *tagLookupDict;
	
	NSMutableArray *itmcList;
	NSMutableDictionary *itmcLookupDict;
	
	NSMutableArray *scenList;
	NSMutableDictionary *scenLookupDict;
	NSMutableDictionary *scenNameLookupDict;
	
	NSMutableArray *modTagList;
	NSMutableDictionary *modTagLookupDict;
	
	NSMutableArray *bitmTagList;
	NSMutableDictionary *bitmTagLookupDict;
}
- (id)init;
- (id)initWithMapfiles:(NSString *)mapfile bitmaps:(NSString *)bitmaps;
- (void)destroy;
- (void)dealloc;
- (BOOL)checkIsPPC;
- (int)loadMap;
- (void)closeMap;
- (FILE *)currentFile;
- (BOOL)isPPC;
- (void)seekToAddress:(unsigned long)address;
- (void)skipBytes:(long)bytesToSkip;
- (BOOL)writeByte:(void *)byte;
- (BOOL)writeShort:(void *)byte;
- (BOOL)writeFloat:(float *)toWrite;
- (BOOL)writeInt:(int *)myInt;
- (BOOL)writeLong:(long *)myLong;
- (BOOL)writeAnyData:(void *)data size:(unsigned int)size;
- (BOOL)writeAnyArrayData:(void *)data size:(unsigned int)size array_size:(unsigned int)array_size;
- (BOOL)writeByteAtAddress:(void *)byte address:(unsigned long)address;
- (BOOL)writeFloatAtAddress:(float *)toWrite address:(unsigned long)address;
- (BOOL)writeIntAtAddress:(int *)myInt address:(unsigned long)address;
- (BOOL)writeLongAtAddress:(long *)myLong address:(unsigned long)address;
- (BOOL)writeAnyDataAtAddress:(void *)data size:(unsigned int)size address:(unsigned long)address;
- (BOOL)writeAnyArrayDataAtAddress:(void *)data size:(unsigned int)size array_size:(unsigned int)array_size address:(unsigned long)address;
- (BOOL)read:(void *)buffer size:(unsigned int)size;
- (BOOL)readByte:(void *)buffer;
- (BOOL)readShort:(void *)buffer;
- (char)readSimpleByte;
- (BOOL)readLong:(void *)buffer;
- (BOOL)readFloat:(void *)floatBuffer;
- (BOOL)readInt:(void *)intBuffer;
- (BOOL)readBlockOfData:(void *)buffer size_of_buffer:(unsigned int)size;
- (BOOL)readByteAtAddress:(void *)buffer address:(unsigned long)address;
- (BOOL)readIntAtAddress:(void *)buffer address:(unsigned long)address;
- (BOOL)readFloatAtAddress:(void *)buffer address:(unsigned long)address;
- (BOOL)readLongAtAddress:(void *)buffer address:(unsigned long)address;
- (BOOL)readBlockOfDataAtAddress:(void *)buffer size_of_buffer:(unsigned int)size address:(unsigned long)address;
- (char *)readCString;
- (reflexive)readReflexive;
- (reflexive)readBspReflexive:(long)magic;
- (TAG_REFERENCE)readReference;
- (id)bitmTagForShaderId:(long)shaderId;
- (long)currentOffset;
- (long)getMagic;
- (long)magic;
- (IndexHeader)indexHead;
- (NSString *)mapName;
- (NSString *)mapLocation;
- (id)tagForId:(long)identity;
- (Scenario *)scenario;
- (BSP *)bsp;
- (TextureManager *)_texManager;
- (void)loadAllBitmaps;
- (BOOL)isTag:(long)tagId;
- (NSMutableArray *)itmcList;
- (NSMutableDictionary *)itmcLookup;
- (NSMutableArray *)scenList;
- (NSMutableDictionary *)scenLookup;
- (NSMutableDictionary *)scenLookupByName;
- (NSMutableArray *)modTagList;
- (NSMutableDictionary *)modTagLookup;
- (NSMutableArray *)bitmTagList;
- (NSMutableDictionary *)bitmLookup;
- (NSMutableArray *)constructArrayForTagType:(char *)tagType;
- (void)constructArrayAndLookupForTagType:(char *)tagType array:(NSMutableArray *)array dictionary:(NSMutableDictionary *)dictionary;
- (long)itmcIdForKey:(int)key;
- (long)modIdForKey:(int)key;
- (long)bitmIdForKey:(int)key;
- (void)saveMap;
@end
