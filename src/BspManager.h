//
//  BspManager.h
//  SparkEdit
//
//  Created by Michael Edgar on Mon Jul 19 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//
@class NSFile;
@class HaloMap;
@class VisibleBsp;
#import <Foundation/Foundation.h>
#import "FileConstants.h"
#import "BSPDefs.h"


@interface BspManager : NSObject {
	
	NSMutableArray *m_BspNames;
	NSMutableArray *m_pBsp;
	long m_ActiveBsp;
	long m_Version;
	NSFile *m_pMapFile;
	long m_Magic;
	SCENARIO_BSP_INFO *m_pBspInfo;
	long m_BspCount;
	HaloMap *myMap;
}

- (id)init;
- (void)Initialize:(NSFile *)pMapFile magic:(long)magic map:(HaloMap *)map;
- (void)LoadVisibleBspInfo:(reflexive) BspChunk version: (unsigned long) version;
- (SUBMESH_INFO*)GetActiveBspPcSubmesh:(unsigned long) mesh_index;
- (void)GetActiveBspCentroid:(float*)x y:(float*)y z:(float*)z;
- (VisibleBsp *)getActiveBsp;
- (unsigned long)GetActiveBspSubmeshCount;
- (HaloMap*)myMap;
- (unsigned short)GetNumberOfBsps;
- (void)setActiveBsp:(unsigned short)bsp;
- (void) LoadBspTextures;
@end
