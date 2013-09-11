//
//  BitmapTag.h
//  swordedit
//
//  Created by sword on 6/17/08.
//  Copyright 2008 sword Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HaloMap.h"
#import "MapTag.h"

#define BITM_FORMAT_A8			0x00
#define BITM_FORMAT_Y8			0x01
#define BITM_FORMAT_AY8			0x02
#define BITM_FORMAT_A8Y8		0x03
#define BITM_FORMAT_R5G6B5		0x06
#define BITM_FORMAT_A1R5G5B5	0x08
#define BITM_FORMAT_A4R4G4B4	0x09
#define BITM_FORMAT_X8R8G8B8	0x0A
#define BITM_FORMAT_A8R8G8B8	0x0B
#define BITM_FORMAT_DXT1		0x0E
#define BITM_FORMAT_DXT2AND3	0x0F
#define BITM_FORMAT_DXT4AND5	0x10
#define BITM_FORMAT_P8			0x11

// Types
#define BITM_TYPE_2D			0x00
#define BITM_TYPE_3D			0x01
#define BITM_TYPE_CUBEMAP		0x02

// Flags
#define BITM_FLAG_LINEAR		(1 << 4)

typedef char BYTE;
typedef short WORD;
typedef unsigned short WCHAR;
typedef char CHAR;
typedef int DWORD;
typedef int FOURCC;

typedef struct
{
	long unknown[0x15];
	reflexive reflexive_to_first;
	reflexive image_reflexive;
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
	//short						flags;
	char						flag0;
	char						internalized;
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

typedef struct
{
	int R,G,B,T;
} RGB;
typedef struct
{
	unsigned int r, g, b, a;
} rgba_color_t;


@interface BitmapTag : MapTag {
	HaloMap *_mapfile;
	FILE *bitmapFile;
	
	BOOL _isPPC;
	
	BOOL hasDecoded;
	
	bitm_header_t header;
	bitm_image_t *images;
	
	unsigned int *imageBytesLookup;
	BOOL *imageLoaded;
	
	NSMutableArray *subImages;
}
- (id)initWithMapFiles:(HaloMap *)mapfile bitmap:(FILE *)bitmap ppc:(BOOL)ppc;
- (void)dealloc;
- (void)freeImagePixels:(int)image;
- (void)freeAllImages;
- (void)seekToOffset:(long)_offset;
- (unsigned int)currentOffset;
- (void)readData:(const void *)buffer address:(long)address size:(int)size;
- (NSSize)textureSizeForImageIndex:(int)index;
- (unsigned int *)imagePixelsForImageIndex:(int)index; // backwards compatability lolz
- (BOOL)loadImage:(int)index;
- (BOOL)imageAlreadyLoaded:(int)index;
- (int)imageCount;
- (NSMutableArray *)subImages;
@end
