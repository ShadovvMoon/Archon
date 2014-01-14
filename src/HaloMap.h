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
	NSMutableArray *plugins;
    NSMutableArray *tagIdArray;
    
	Scenario *mapScenario;
	BSP *bspHandler;
	
	TextureManager *_texManager;
    ModelTag *bipd;
    
	int32_t _magic;
	
	Header mapHeader;
	IndexHeader indexHead;
	
	NSMutableArray *tagArray;
	NSMutableDictionary *tagLookupDict;
	
	NSMutableArray *itmcList;
	NSMutableDictionary *itmcLookupDict;
	
	NSMutableArray *machList;
	NSMutableDictionary *machLookupDict;
	
	NSMutableArray *scenList;
	NSMutableDictionary *scenLookupDict;
	NSMutableDictionary *scenNameLookupDict;
	
	NSMutableArray *modTagList;
	NSMutableDictionary *modTagLookupDict;
	
	NSMutableArray *bitmTagList;
	NSMutableDictionary *bitmTagLookupDict;
    
    
    int originalTagCount;
    
    
    int32_t currentOffset;
    int32_t globalMapSize;
    char *map_memory;
    
    BOOL dataReading;
    uint32_t globalScenarioOffset;
}
- (id)initWithMapdata:(NSData *)map_data bitmaps:(NSString *)bitmaps;
-(int32_t)globalMapSize;
-(char*)globalMemory;
-(void)setVertexSize:(float)size;
-(ModelTag*)bipd;
- (id)init;
-(void)rebuildTagArrayToPath:(NSString*)filename withDataAtIndexes:(int32_t*)insertEnd lengths:(int32_t*)dataLength offsets:(int)count;
- (BOOL)insertDataInFile:(NSString*)filename withData:(void *)data size:(unsigned int)newsize address:(uint32_t)address;
- (id)initWithMapfiles:(NSString *)mapfile bitmaps:(NSString *)bitmaps;
- (void)destroy;
- (void)dealloc;
- (int)loadMap;
- (void)closeMap;
- (FILE *)currentFile;
- (void)loadShader:(senv*)shader forID:(int32_t)shaderId ;
- (void)seekToAddress:(uint32_t)address;
- (void)skipBytes:(int32_t)bytesToSkip;
- (BOOL)writeChar:(char)byte;
- (BOOL)writeByte:(void *)byte;
- (BOOL)writeShort:(void *)byte;
- (BOOL)writeFloat:(float *)toWrite;
- (BOOL)writeInt:(int *)myInt;
- (BOOL)writeint32_t:(int32_t *)myint32_t;
- (BOOL)writeAnyData:(void *)data size:(unsigned int)size;
- (BOOL)writeAnyArrayData:(void *)data size:(unsigned int)size array_size:(unsigned int)array_size;
- (BOOL)writeByteAtAddress:(void *)byte address:(uint32_t)address;
- (BOOL)writeFloatAtAddress:(float *)toWrite address:(uint32_t)address;
- (BOOL)writeIntAtAddress:(int *)myInt address:(uint32_t)address;
- (BOOL)writeint32_tAtAddress:(int32_t *)myint32_t address:(uint32_t)address;
- (BOOL)writeAnyDataAtAddress:(void *)data size:(unsigned int)size address:(uint32_t)address;
- (BOOL)writeAnyArrayDataAtAddress:(void *)data size:(unsigned int)size array_size:(unsigned int)array_size address:(uint32_t)address;
- (BOOL)read:(void *)buffer size:(unsigned int)size;
- (BOOL)readByte:(void *)buffer;
- (BOOL)readShort:(void *)buffer;
- (char)readSimpleByte;
- (BOOL)readint32_t:(void *)buffer;
-(Header)mapHeader;
- (BOOL)readFloat:(void *)floatBuffer;
- (BOOL)readInt:(void *)intBuffer;
- (BOOL)readBlockOfData:(void *)buffer size_of_buffer:(unsigned int)size;
- (BOOL)readByteAtAddress:(void *)buffer address:(uint32_t)address;
- (BOOL)readIntAtAddress:(void *)buffer address:(uint32_t)address;
- (BOOL)readFloatAtAddress:(void *)buffer address:(uint32_t)address;
- (BOOL)readint32_tAtAddress:(void *)buffer address:(uint32_t)address;
- (BOOL)readBlockOfDataAtAddress:(void *)buffer size_of_buffer:(unsigned int)size address:(uint32_t)address;
- (char *)readCString;
- (reflexive)readReflexive;
- (reflexive)readBspReflexive:(int32_t)magic;
- (TAG_REFERENCE)readReference;
- (id)bitmTagForShaderId:(int32_t)shaderId;
- (int32_t)currentOffset;
- (int32_t)getMagic;
- (int32_t)magic;
- (IndexHeader)indexHead;
- (NSString *)mapName;
- (NSString *)mapLocation;
- (id)tagForId:(int32_t)identity;
- (Scenario *)scenario;
- (BSP *)bsp;
- (TextureManager *)_texManager;
- (void)loadAllBitmaps;
- (BOOL)isTag:(int32_t)tagId;
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
- (int32_t)itmcIdForKey:(int)key;
- (int32_t)modIdForKey:(int)key;
- (int32_t)bitmIdForKey:(int)key;
- (void)saveMap;
@property (getter=currentFile) FILE *mapFile;
@property (retain) NSString *bitmapFilePath;
@property FILE *bitmapsFile;
@property (retain,getter=scenario) Scenario *mapScenario;
@property (retain,getter=bsp) BSP *bspHandler;
@property (retain,getter=_texManager) TextureManager *_texManager;
@property int32_t _magic;
@property (retain) NSMutableArray *tagArray;
@property (retain) NSMutableDictionary *tagLookupDict;
@property (retain,getter=itmcList) NSMutableArray *itmcList;
@property (retain,getter=itmcLookup) NSMutableDictionary *itmcLookupDict;
@property (retain,getter=scenList) NSMutableArray *scenList;
@property (retain,getter=scenLookup) NSMutableDictionary *scenLookupDict;
@property (retain,getter=scenLookupByName) NSMutableDictionary *scenNameLookupDict;
@property (retain,getter=modTagList) NSMutableArray *modTagList;
@property (retain,getter=modTagLookup) NSMutableDictionary *modTagLookupDict;
@property (retain,getter=bitmTagList) NSMutableArray *bitmTagList;
@property (retain,getter=bitmLookup) NSMutableDictionary *bitmTagLookupDict;
@end
