//
//  BitmapTag.mm
//  swordedit
//
//  Created by Fred Havemeyer on 6/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <squish/squish.h>
#import "BitmapTag.h"

using namespace squish;

static BOOL isPPC;

int getImageSize (int format, int width, int height);
unsigned int rgba_to_int (rgba_color_t color);
void DecodeLinearX8R8G8B8 (int width, int height, const char *texdata, unsigned int *outdata);
void DecodeLinearA8R8G8B8 (int width, int height, const char *texdata, unsigned int *outdata);
inline long bmpEndianSwap32(unsigned int x);

int getImageSize (int format, int width, int height)
{
	int		size = 0;
	
	if (!width)
		width = 1;
	
	if (!height)
		height = 1;
	
	if (format == BITM_FORMAT_DXT1 || format == BITM_FORMAT_DXT2AND3 || format == BITM_FORMAT_DXT4AND5)
	{
		if (width < 4)
			width = 4;
		if (height < 4)
			height = 4;
	}

	switch (format)
	{
		case BITM_FORMAT_A8:
		case BITM_FORMAT_Y8:
		case BITM_FORMAT_AY8:
		case BITM_FORMAT_P8:
			//NSLog(@"A8 / Y8 / AY8 / P8!");
			size = width * height;
			break;
		
		case BITM_FORMAT_A8Y8:
		case BITM_FORMAT_R5G6B5:
		case BITM_FORMAT_A1R5G5B5:
		case BITM_FORMAT_A4R4G4B4:
			//NSLog(@"A8Y8 / R5G6B5 / A1R5G5B5 / A4R4G4B4!");
			size = width * height * 2;
			break;
		
		case BITM_FORMAT_X8R8G8B8:
		case BITM_FORMAT_A8R8G8B8:
			//NSLog(@"X8R8G8B8 / A8R8G8B8");
			size = width * height * 4;
			break;
		
		case BITM_FORMAT_DXT1:
			size = (width >> 2) * (height >> 2) * 8;
			break;

		case BITM_FORMAT_DXT2AND3:
		case BITM_FORMAT_DXT4AND5:
			size = (width >> 2) * (height >> 2) * 16;
			break;
		
		default:
			fprintf (stderr, "Unknown format in GetImageSize!\n");
			break;
	}
	
	return size;
}

unsigned int rgba_to_int (rgba_color_t color) 
{ 
	return (color.r << 24) | (color.g << 16) | (color.b << 8) | (color.a);
}

/*================================
 * DecodeLinearX8R8G8B8 
================================*/
void DecodeLinearX8R8G8B8 (int width, int height, const char *texdata, unsigned int *outdata)
{
	rgba_color_t	color;
	unsigned int	cdata;
	int x,y;
	for (y = 0; y < height; y++)
	{
		for (x = 0; x < width; x++)
		{
			cdata = ((int *)texdata)[(y * width) + x];
			color.a = 255;
			color.r = (cdata >> 16) & 0xFF;
			color.g = (cdata >>  8) & 0xFF;
			color.b = (cdata >>  0) & 0xFF;

			outdata[(y * width) + x] = rgba_to_int (color);
		}
	}
}
/*================================
 * DecodeLinearA8R8G8B8 
================================*/
void DecodeLinearA8R8G8B8 (int width, int height, const char *texdata, unsigned int *outdata)
{
	rgba_color_t	color;
	unsigned int	cdata;
	int x,y;
	for (y = 0; y < height; y++)
	{
		for (x = 0; x < width; x++)
		{
			cdata = ((int *)texdata)[(y * width) + x];
			//cdata = bmpEndianSwap32(cdata);
			color.a = (cdata >> 24);
			color.r = (cdata >> 16) & 0xFF;
			color.g = (cdata >>  8) & 0xFF;
			color.b = (cdata >>  0) & 0xFF;

			outdata[(y * width) + x] = rgba_to_int (color);
		}
	}
}

inline long bmpEndianSwap32(unsigned int x)
{
	return (x >> 24) | ((x << 8) & 0x00FF0000) | ((x >> 8) & 0x0000FF00) | (x << 24);
}


@implementation BitmapTag
- (id)initWithMapFiles:(HaloMap *)mapfile bitmap:(FILE *)bitmap ppc:(BOOL)ppc
{
	if ((self = [super initWithDataFromFile:mapfile]) != nil)
	{
		int x;
		_mapfile = [mapfile retain];
		bitmapFile = bitmap;
		hasDecoded = NO;
		
		[_mapfile seekToAddress:([self offsetInMap] + 0x54)];
		header.reflexive_to_first = [_mapfile readReflexive];
		header.image_reflexive = [_mapfile readReflexive];
		
		//if (header.image_reflexive.chunkcount < 0 || header.image_reflexive.chunkcount > 20)
		//	return nil;
		
		imageBytesLookup = (unsigned int *)malloc(sizeof(unsigned int) * header.image_reflexive.chunkcount);
		memset(imageBytesLookup,0,(sizeof(unsigned int) * header.image_reflexive.chunkcount));
		
		imageLoaded = (BOOL *)malloc(sizeof(BOOL) * header.image_reflexive.chunkcount);
		memset(imageLoaded, 0, (sizeof(BOOL) * header.image_reflexive.chunkcount));
				
		images = (bitm_image_t *)malloc(header.image_reflexive.chunkcount * sizeof(bitm_image_t));
		
		[_mapfile seekToAddress:(header.image_reflexive.offset)];
		
		subImages = [[NSMutableArray alloc] initWithCapacity:header.image_reflexive.chunkcount];
		
		for (x = 0; x < header.image_reflexive.chunkcount; x++)
		{
			[subImages addObject:[NSNumber numberWithInt:x]];
			bitm_image_t *tempImage = &images[x];
			[_mapfile readLong:&tempImage->id];
			[_mapfile readShort:&tempImage->width];
			[_mapfile readShort:&tempImage->height];
			[_mapfile readShort:&tempImage->depth];
			[_mapfile readShort:&tempImage->type];
			[_mapfile readShort:&tempImage->format];
			//[_mapfile readShort:&tempImage->flags];
			[_mapfile readByte:&tempImage->flag0];
			[_mapfile readByte:&tempImage->internalized];
			[_mapfile readShort:&tempImage->reg_point_x];
			[_mapfile readShort:&tempImage->reg_point_y];
			[_mapfile readShort:&tempImage->num_mipmaps];
			[_mapfile readShort:&tempImage->pixel_offset];
			[_mapfile readLong:&tempImage->offset];
			[_mapfile readLong:&tempImage->size];
			[_mapfile readLong:&tempImage->unknown8];
			[_mapfile readLong:&tempImage->unknown9];
			[_mapfile readLong:&tempImage->unknown10];
			[_mapfile readLong:&tempImage->unknown11];
			//NSLog(@"Maybe internalized flag? 0x%d", tempImage->flags);
		}
	}
	return self;
}
- (void)dealloc
{	
	[_mapfile release];
	
	[self freeAllImages];
	
	[subImages removeAllObjects];
	[subImages release];
	
	bitmapFile = NULL;
	
	free(imageBytesLookup);
	free(imageLoaded);
	
	if (images) 
		free(images);
		
	[super dealloc];
}
- (void)freeImagePixels:(int)image
{
	unsigned int *imageBytes;
	if (imageLoaded[image])
	{
		imageBytes = (unsigned int *)imageBytesLookup[image];
		if (imageBytes)
			free(imageBytes);
	}
}
- (void)freeAllImages
{
	int i;
	unsigned int *imageBytes;
	
	for (i = 0; i < [subImages count]; i++)
	{
		if (imageLoaded[i])
		{
			imageBytes = (unsigned int *)imageBytesLookup[i];
			free(imageBytes);
		}
	}
}
- (void)seekToOffset:(long)_offset
{
	fseek(bitmapFile, _offset, SEEK_SET);
}
- (unsigned int)currentOffset
{
	return ftell(bitmapFile);
}
- (void)readData:(void *)buffer address:(long)address size:(int)size
{	

	fread(buffer,size,1,bitmapFile);
		
	if (isPPC)
	{
		long *tmpLong = (long *)buffer;
		int i;
	
		// I need to make a working PPC hack here.
		//NSLog(@"Were in PPC!");
		fread(buffer, size, 1, bitmapFile); // Need to flip the endians in this one
		/* Everything here is being read in multiples of 4, so lets get cracking. */
		
		for (i = 0; i < (size / 4); i++)
		{
			tmpLong[i] = bmpEndianSwap32(tmpLong[i]);
		}
	}
}
- (NSSize)textureSizeForImageIndex:(int)index
{
	return NSMakeSize(images[index].width, images[index].height);
}
- (unsigned int *)imagePixelsForImageIndex:(int)index
{
	if (imageLoaded[index])
	{
		return (unsigned int *)imageBytesLookup[index];
	}
	else
	{
		if ([self loadImage:index])
			return (unsigned int *)imageBytesLookup[index];
		else
			return NULL;
	}
}
- (BOOL)loadImage:(int)index
{
	char *inData;
	unsigned int *imageBytes = NULL;
	int lengthOfData;
	
	//if (((unsigned int)index) < 0 || ((unsigned int)index) > ((unsigned int)header.image_reflexive.chunkcount))
	//	return NULL;
		
	if (!bitmapFile)
		return FALSE;
	
	imageBytes = (unsigned int *)imageBytesLookup[index];
		
	lengthOfData = getImageSize(images[index].format, images[index].width, images[index].height);
	
	inData = (char *)malloc(lengthOfData);
	
	if (images[index].internalized == 0)
	{
		//NSLog(@"Size of data: 0x%x, at address: 0x%x", lengthOfData, images[index].offset);
		[_mapfile readBlockOfDataAtAddress:inData size_of_buffer:lengthOfData address:images[index].offset];
	}
	else
	{
		[self seekToOffset:images[index].offset];
		[self readData:inData address:[self currentOffset] size:lengthOfData];
	}
	
	imageBytes = (unsigned int *)malloc(4 * images[index].width * images[index].height);
	
	switch (images[index].format)
	{
		case BITM_FORMAT_DXT2AND3:
			//NSLog(@"DXT 2 and 3");
			DecompressImage((u8 *)imageBytes,images[index].width,images[index].height,inData,kDxt3);
			break;
		case BITM_FORMAT_DXT4AND5:
			//NSLog(@"DXT 4 and 5");
			DecompressImage((u8 *)imageBytes,images[index].width,images[index].height,inData,kDxt5);
			break;
		case BITM_FORMAT_X8R8G8B8:
			DecodeLinearX8R8G8B8(images[index].width,images[index].height,inData,imageBytes);
			break;
		case BITM_FORMAT_A8R8G8B8:
			//NSLog(@"BITM_FORMAT_A8R8G8B8");
			DecodeLinearA8R8G8B8(images[index].width,images[index].height,inData,imageBytes);
			break;
		case BITM_FORMAT_DXT1:
			//NSLog(@"DXT 1");
			DecompressImage((u8 *)imageBytes,images[index].width,images[index].height,inData,kDxt1);
			break;
	
	}
	
	imageBytesLookup[index] = (unsigned int)imageBytes;
	return (imageLoaded[index] = TRUE);
}
- (BOOL)imageAlreadyLoaded:(int)index
{
	return imageLoaded[index];
}
- (int)imageCount
{
	return [subImages count];
}
- (NSMutableArray *)subImages
{
	return subImages;
}
@end