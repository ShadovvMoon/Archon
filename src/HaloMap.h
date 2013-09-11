//
//  HaloMap.h
//  SparkEdit
//
//  Created by Michael Edgar on Mon Jun 21 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NSFile;
@class BitmapTag;
@class BspManager;
@class ModelTag;
@class ScenarioTag;
typedef struct
{
	long id;
	long version;
	long decomp_len;
	long zeros;
	long offset_to_index_decomp;
	long metadatasize;
	long zeros2[2];
	char name[32];
	char builddate[32];
	long maptype;
	long id2;
} fileheader;
typedef struct
{
	long magic;
	long starting_id;
	long vertexsize;
	long tagcount;
	long vertex_object_count;
	long vertex_offset;
	long indices_object_count;
	long vertex_size;
	long modelsize;
	long tagstart;
} indexheader;
#import "FileConstants.h"
@interface HaloMap : NSObject {
	NSString *path;
	fileheader fileHeader;
	indexheader indexHeader;
	ScenarioTag *myScenario;
	NSMutableArray *models;
	NSMutableDictionary *modelsDict;
	NSMutableDictionary *bitmaps;
	NSMutableDictionary *allOtherTags;
}
- (NSString *)mapName;
- (id)initWithPath:(NSString *)path;
- (NSMutableArray *)models;
- (indexheader)indexHeader;
- (BitmapTag *)bitmForIdent:(long)ident;
- (ModelTag *)modelForIdent:(long)ident;
- (long)offsetForIdent:(long)ident;
- (NSMutableDictionary *)bitmaps;
- (long)version;
- (long)baseBitmapIdentForShader:(long)ident file:(NSFile *)file;
- (ScenarioTag*)myScenario;
@end
