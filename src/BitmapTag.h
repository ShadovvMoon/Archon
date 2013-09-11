//
//  BitmapTag.h
//  SparkEdit
//
//  Created by Michael Edgar on Tue Jun 22 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


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

#define bmpEndianSwap64(x) (((x & 0xFF00000000000000) >> 56) | ((x & 0x00FF000000000000) >> 40) | ((x & 0x0000FF0000000000) >> 24) | ((x & 0x000000FF00000000) >> 8) | ((x & 0x00000000FF000000) << 8) | ((x & 0x0000000000FF0000) << 24) | ((x & 0x000000000000FF00) << 40) |    ((x & 0x00000000000000FF) << 56))
#define bmpEndianSwap32(x) (((x & 0xFF000000) >> 24) | ((x & 0x00FF0000) >> 8) | ((x & 0x0000FF00) << 8) | ((x & 0x000000FF) << 24))
#define bmpEndianSwap16(x) (((x & 0x00FF) << 8) | ((x & 0xFF00) >> 8))


@class NSFile;
@class HaloMap;
#import "FileConstants.h"
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

typedef struct
{
	DWORD R,G,B,T;
} RGB;
typedef struct
{
	unsigned int r, g, b, a;
} rgba_color_t;
@interface BitmapTag : NSObject {
	tag myTag;
	bitm_header_t header;
	bitm_image_t *images;
	NSString *pathToMap;
	NSString *myName;
	unsigned int *bytes;
}
- (id)initWithFile:(NSFile *)file atOffset:(long)offset map:(HaloMap *)map;
- (NSSize)textureSizeForImageIndex:(unsigned short)idx;
- (unsigned int *)imagePixelsForImageIndex:(unsigned short)idx;
- (NSString *)name;
- (char)imageCount;
- (void)freeImagePixels;
@end
int getImageSize (int format, int width, int height);
RGB ConvertWORDToRGB(WORD Color);
DWORD RGBToDWORD(RGB Color);
rgba_color_t GradientColorsHalf (rgba_color_t Col1, rgba_color_t Col2);
unsigned int rgba_to_int (rgba_color_t color);
rgba_color_t short_to_rgba (unsigned short color);
void DecodeDXT1(int Height, int Width, const char* IData, unsigned int* PData);
void DecodeBitmSurface (const char *data, int width, int height, int depth, 
                                   int format, int flags, unsigned int *pOutBuf);
  void DecodeLinearA8 (int width, int height, const char *texdata, unsigned int *outdata);
  void DecodeLinearY8 (int width, int height, const char *texdata, unsigned int *outdata);
  void DecodeLinearAY8 (int width, int height, const char *texdata, unsigned int *outdata);
  void DecodeLinearA8Y8 (int width, int height, const char *texdata, unsigned int *outdata);
  void DecodeLinearR5G6B5 (int width, int height, const char *texdata, unsigned int *outdata);
  void DecodeLinearA1R5G5B5 (int width, int height, const char *texdata, unsigned int *outdata);
  void DecodeLinearA4R4G4B4 (int width, int height, const char *texdata, unsigned int *outdata);
  void DecodeLinearX8R8G8B8 (int width, int height, const char *texdata, unsigned int *outdata);
  void DecodeLinearA8R8G8B8 (int width, int height, const char *texdata, unsigned int *outdata);
  void DecodeLinearP8 (int width, int height, const char *texdata, unsigned int *outdata);
  void DecodeDXT2And3 (int Height, int Width, const char* IData, unsigned int* PData);
  void DecodeDXT4And5 (int Height, int Width, const char* IData, unsigned int* PData);