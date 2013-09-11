//
//  NSDataBitmapCategory.h
//  SparkEdit
//
//  Created by Michael Edgar on Tue Jun 22 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NSFile;
typedef struct
{
	int							unknown[22]; // [7] == [6]+108[9]
	int							offset_to_first;
	int							unknown23;	// always 0x0
	int							image_count;
	int							image_offset;
	int							unknown25;	// always 0x0

} bitm_header_t;


typedef struct
{
	int							unknown[16];

} bitm_first_t;

typedef struct
{
	int							id;			// 'bitm'
	short						width;
	short						height;
	short						depth;
	short						type;
	short						format;
	short						flags;
	short						reg_point_x;
	short						reg_point_y;
	short						num_mipmaps;
	short						pixel_offset;
	int         				offset;
	int							size;
	int							unknown8;
	int							unknown9;	// always 0xFFFFFFFF?
	int							unknown10;	// always 0x00000000?
	int							unknown11;	// always 0x024F0040?
} bitm_image_t;
@interface NSData (NSDataBitmapCategory)

- (NSBitmapImageRep *)readBitmFromMap:(HaloMap *)map ident:(long)ident 

@end