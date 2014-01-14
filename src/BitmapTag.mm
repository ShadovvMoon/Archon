//
//  BitmapTag.mm
//  swordedit
//
//  Created by Fred Havemeyer on 6/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//


#import "BitmapTag.h"
#import <Foundation/Foundation.h>
#include <squish.h>
#import "defines.h"
using namespace squish;

#import "colourset.h"
#import "colourfit.h"
#import "singlecolourfit.h"
#import "rangefit.h"
#import "clusterfit.h"

static BOOL isPPC;

int getImageSize (int format, int width, int height);
unsigned int rgba_to_int (rgba_color_t color);
void DecodeLinearX8R8G8B8 (int width, int height, const char *texdata, unsigned int *outdata);
void DecodeLinearA8R8G8B8 (int width, int height, const char *texdata, unsigned int *outdata);
void DecodeLinearR5G6B5 (int width, int height, const char *texdata, unsigned int *outdata);
void EncodeLinearR5G6B5 (int width, int height, const int *texdata, unsigned short *outdata);
inline int32_t bmpEndianSwap32(unsigned int x);

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
			//CSLog(@"A8 / Y8 / AY8 / P8!");
			size = width * height;
			break;
		
		case BITM_FORMAT_A8Y8:
		case BITM_FORMAT_R5G6B5:
            size = width * height * 2;
            break;
		case BITM_FORMAT_A1R5G5B5:
		case BITM_FORMAT_A4R4G4B4:
			//CSLog(@"A8Y8 / R5G6B5 / A1R5G5B5 / A4R4G4B4!");
			size = width * height * 2;
			break;
		
		case BITM_FORMAT_X8R8G8B8:
		case BITM_FORMAT_A8R8G8B8:
			//CSLog(@"X8R8G8B8 / A8R8G8B8");
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
    //return (color.a << 24) | (color.r << 16) | (color.g << 8) | (color.b);
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

			outdata[(y * width) + x] = (255 << 24) | (color.r << 16) | (color.g << 8) | (color.b); //0xff000000 | cdata & 0xffffff;
            
            outdata[(y * width) + x]  = 0xFF000000 |
            (((cdata) & 0xff0000) >> 16)|
            ((cdata) & 0xff00)|
            (((cdata) & 0xff) << 16);

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
            
			color.a = (cdata >> 24) & 0xFF;
			color.r = (cdata >> 16) & 0xFF;
			color.g = (cdata >>  8) & 0xFF;
			color.b = (cdata >>  0) & 0xFF;

            
            
            // //Pretty sky!
            outdata[(y * width) + x]  = (((cdata >> 24) & 0xff) << 24 ) |
            (((cdata) & 0xff0000) >> 16)|
            ((cdata) & 0xff00)|
            (((cdata) & 0xff) << 16);

			//outdata[(y * width) + x] = rgba_to_int (color);
            
		}
	}
}

void EncodeLinearR5G6B5 (int width, int height, const int *texdata, unsigned short *outdata)
{
    //CSLog(@"Encoding");
    rgba_color_t	color;
	unsigned int cdata;
	int x,y;
    
    for (y = 0; y < height; y++)
	{
		for (x = 0; x < width; x++)
		{
            //CSLog(@"decoding..");
			cdata = ((unsigned int *)texdata)[(y * width) + x];
            
            //Double conversion
            unsigned short cdatanew = (( cdata & 0x00F80000) >> 8 |
                                       ( cdata & 0x0000FC00) >> 5 |
                                       ( cdata & 0x000000F8) >> 3);
            
            unsigned int cdatathird = 0xFF000000 |
            ((cdatanew & 0xF800) >> 8)|
            ((cdatanew & 0x07e0) << 5)|
            ((cdatanew & 0x1f) << 19); //rgba_to_int (color);
            
            outdata[(y * width) + x] = (( cdatathird & 0x00F80000) >> 8 |
                                        ( cdatathird & 0x0000FC00) >> 5 |
                                        ( cdatathird & 0x000000F8) >> 3);
            
		}
	}
    //CSLog(@"Finished encoding");
}

/*================================
 * DecodeLinearR5G6B5
 ================================*/
void DecodeLinearR5G6B5 (int width, int height, const char *texdata, unsigned int *outdata)
{
    //CSLog(@"BITM_FORMAT_A8R8G8B8");
	rgba_color_t	color;
	unsigned short cdata;
	int x,y;
	for (y = 0; y < height; y++)
	{
		for (x = 0; x < width; x++)
		{
            //CSLog(@"decoding..");
			cdata = ((unsigned short *)texdata)[(y * width) + x];

            
            outdata[(y * width) + x]  = 0xFF000000 |
            ((cdata & 0xF800) >> 8)|
            ((cdata & 0x07e0) << 5)|
            ((cdata & 0x1f) << 19); //rgba_to_int (color);
            
            
            
            //cdata *= 255.0f;
			//outdata[(y * width) + x]  = 0xFF000000 |
            //		((cdata & 0xF800) << 8)|
            //		((cdata & 0x07E0) << 5)|
            //		((cdata & 0x1F) << 3); //rgba_to_int (color);
            
		}
	}
}

inline int32_t bmpEndianSwap32(unsigned int x)
{
	return (x >> 24) | ((x << 8) & 0x00FF0000) | ((x >> 8) & 0x0000FF00) | (x << 24);
}


@implementation BitmapTag
-(void)resetDouble:(int)index
{
    images[index].loadedAlready = NO;
}
-(BOOL)alreadyDouble:(int)index
{
    return images[index].loadedAlready;
}
-(void)doubleImage:(int)index withFactor:(NSNumber*)factor
{
    if (images[index].loadedAlready)
        return;
    images[index].loadedAlready = YES;
    
    float scalingFactor = [factor floatValue];
    
    images[index].width *= scalingFactor;
    images[index].height *= scalingFactor;
    
    images[index].reg_point_x *= scalingFactor;
    images[index].reg_point_y *= scalingFactor;
    
    images[index].width=(int)images[index].width;
    images[index].height=(int)images[index].height;
    images[index].reg_point_x=(int)images[index].reg_point_x;
    images[index].reg_point_y=(int)images[index].reg_point_y;
    
    //Update the actual mapfile to fix the image values we just added.
    int32_t currentOffset = [_mapfile currentOffset];
    
    [_mapfile seekToAddress:([self offsetInMap] + 0x54)];
    header.reflexive_to_first = [_mapfile readReflexive];
    header.image_reflexive = [_mapfile readReflexive];
    
    //Where is the end of the file?
    [_mapfile seekToAddress:(header.image_reflexive.offset) + (48*index)+4];
    [_mapfile writeShort:(void*)(&images[index].width)];
    [_mapfile seekToAddress:(header.image_reflexive.offset) + (48*index)+6];
    [_mapfile writeShort:(void*)(&images[index].height)];
    
    [_mapfile seekToAddress:(header.image_reflexive.offset) + (48*index)+0x10];
    [_mapfile writeShort:(void*)(&images[index].reg_point_x)];
    [_mapfile seekToAddress:(header.image_reflexive.offset) + (48*index)+0x12];
    [_mapfile writeShort:(void*)(&images[index].reg_point_y)];
    //Update the image size.
    
    
    [_mapfile seekToAddress:currentOffset];
}

-(void)forceImageWriteToMap:(int)index
{
    void *imageBytes = [self imagePixelsForImageIndex:index];

    unsigned short *outData;
	int lengthOfData;
	
    if (!imageBytes)
        return;
	
	lengthOfData = getImageSize(images[index].format, images[index].width, images[index].height);
	outData = (unsigned short *)malloc(lengthOfData);
	
	switch (images[index].format)
	{
        case BITM_FORMAT_R5G6B5:
			EncodeLinearR5G6B5(images[index].width,images[index].height,(const int*)imageBytes,(unsigned short*)outData);
            break;
        case BITM_FORMAT_DXT1:
			CompressImage((u8*)imageBytes,images[index].width,images[index].height,(u8 *)outData,kDxt1);
            break;
        case BITM_FORMAT_DXT2AND3:
			CompressImage((u8*)imageBytes,images[index].width,images[index].height,(u8 *)outData,kDxt3);
            break;
        case BITM_FORMAT_DXT4AND5:
			CompressImage((u8*)imageBytes,images[index].width,images[index].height,(u8 *)outData,kDxt5);
			break;
        default:
        {
            return ;
        }
	}
    

    [self internaliseImage:index size:lengthOfData withBytes:outData];

    
    return;

}



- (id)initWithData:(NSData *)data withMapfile:(HaloMap*)mapfile bitmap:(FILE *)bitmap ppc:(BOOL)ppc
{
	if ((self = [super initWithData:data withMapfile:mapfile]) != nil)
	{
		int x;
		_mapfile = [mapfile retain];
		bitmapFile = bitmap;
		hasDecoded = NO;
        
		[_mapfile seekToAddress:([self offsetInMap] + 0x54)];
		header.reflexive_to_first = [_mapfile readReflexive];
		header.image_reflexive = [_mapfile readReflexive];
        
        
        if (header.image_reflexive.chunkcount > 1000)
            return self;
        else if (header.image_reflexive.chunkcount < 0)
            return self;
        
		imageBytesLookup = (uint64_t *)malloc(sizeof(uint64_t) * header.image_reflexive.chunkcount);
		memset(imageBytesLookup,0,(sizeof(unsigned int) * header.image_reflexive.chunkcount));
        
        
		imageLoaded = (BOOL *)malloc(sizeof(BOOL) * header.image_reflexive.chunkcount);
		memset(imageLoaded, 0, (sizeof(BOOL) * header.image_reflexive.chunkcount));
        
		images = (bitm_image_t *)malloc(header.image_reflexive.chunkcount * sizeof(bitm_image_t));
		[_mapfile seekToAddress:(header.image_reflexive.offset)];
        
        //#ifdef MACVERSION
        subImages = (int*)malloc(sizeof(int)*100);
        
		//subImageee = [[NSMutableArray alloc] initWithCapacity:header.image_reflexive.chunkcount];
		
		for (x = 0; x < header.image_reflexive.chunkcount; x++)
		{
            subImages[cImage] = x;
            cImage++;
            
			//[subImageee addObject:[[NSNumber alloc] initWithInt:x]];
			bitm_image_t *tempImage = &images[x];
			[_mapfile readint32_t:&tempImage->id];
			[_mapfile readShort:&tempImage->width]; //Changed 4
			[_mapfile readShort:&tempImage->height]; //Changed 6
			[_mapfile readShort:&tempImage->depth]; //8
			[_mapfile readShort:&tempImage->type]; //10
			[_mapfile readShort:&tempImage->format]; //12
			[_mapfile readByte:&tempImage->flag0]; //14
			[_mapfile readByte:&tempImage->internalized]; //15
			[_mapfile readShort:&tempImage->reg_point_x]; //Changed 16
			[_mapfile readShort:&tempImage->reg_point_y]; //Changed 18
			[_mapfile readShort:&tempImage->num_mipmaps]; //20
			[_mapfile readShort:&tempImage->pixel_offset]; //22
			[_mapfile readint32_t:&tempImage->offset]; //24
			[_mapfile readint32_t:&tempImage->size]; //28
			[_mapfile readint32_t:&tempImage->unknown8]; //32
			[_mapfile readint32_t:&tempImage->unknown9]; //36
			[_mapfile readint32_t:&tempImage->unknown10]; //40
			[_mapfile readint32_t:&tempImage->unknown11]; //48
		}
	}
	return self;
}



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


        if (header.image_reflexive.chunkcount > 1000)
            return self;
        else if (header.image_reflexive.chunkcount < 0)
            return self;
        
		imageBytesLookup = (uint64_t *)malloc(sizeof(uint64_t) * header.image_reflexive.chunkcount);
		memset(imageBytesLookup,0,(sizeof(unsigned int) * header.image_reflexive.chunkcount));
        
        
		imageLoaded = (BOOL *)malloc(sizeof(BOOL) * header.image_reflexive.chunkcount);
		memset(imageLoaded, 0, (sizeof(BOOL) * header.image_reflexive.chunkcount));
				
		images = (bitm_image_t *)malloc(header.image_reflexive.chunkcount * sizeof(bitm_image_t));
		[_mapfile seekToAddress:(header.image_reflexive.offset)];

        //#ifdef MACVERSION
        subImages = (int*)malloc(sizeof(int)*100);
        
		//subImageee = [[NSMutableArray alloc] initWithCapacity:header.image_reflexive.chunkcount];
		
		for (x = 0; x < header.image_reflexive.chunkcount; x++)
		{
            subImages[cImage] = x;
            cImage++;
            
			//[subImageee addObject:[[NSNumber alloc] initWithInt:x]];
			bitm_image_t *tempImage = &images[x];
			[_mapfile readint32_t:&tempImage->id];
			[_mapfile readShort:&tempImage->width]; //Changed 4
			[_mapfile readShort:&tempImage->height]; //Changed 6
			[_mapfile readShort:&tempImage->depth]; //8
			[_mapfile readShort:&tempImage->type]; //10
			[_mapfile readShort:&tempImage->format]; //12
			[_mapfile readByte:&tempImage->flag0]; //14
			[_mapfile readByte:&tempImage->internalized]; //15
			[_mapfile readShort:&tempImage->reg_point_x]; //Changed 16
			[_mapfile readShort:&tempImage->reg_point_y]; //Changed 18
			[_mapfile readShort:&tempImage->num_mipmaps]; //20
			[_mapfile readShort:&tempImage->pixel_offset]; //22
			[_mapfile readint32_t:&tempImage->offset]; //24
			[_mapfile readint32_t:&tempImage->size]; //28
			[_mapfile readint32_t:&tempImage->unknown8]; //32
			[_mapfile readint32_t:&tempImage->unknown9]; //36
			[_mapfile readint32_t:&tempImage->unknown10]; //40
			[_mapfile readint32_t:&tempImage->unknown11]; //48
		}
	}
	return self;
}

- (void)dealloc
{	
	[_mapfile release];
	
	[self freeAllImages];
	
    cImage=0;
    free(subImages);
    
	//[subImageee removeAllObjects];
	//[subImageee release];
	
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
	
	for (i = 0; i < cImage; i++)
	{
		if (imageLoaded[i])
		{
			imageBytes = (unsigned int *)imageBytesLookup[i];
			free(imageBytes);
		}
	}
}
- (void)seekToOffset:(int32_t)_offset
{
	fseek(bitmapFile, _offset, SEEK_SET);
}
- (unsigned int)currentOffset
{
	return ftell(bitmapFile);
}
- (void)writeData:(void *)buffer address:(int32_t)address size:(int)size
{
    
    fwrite(buffer, size, 1, bitmapFile);
    
    /*
	if (isPPC)
	{
		int32_t *tmpint32_t = (int32_t *)buffer;
		int i;
        
		// I need to make a working PPC hack here.
		//CSLog(@"Were in PPC!");
		fread(buffer, size, 1, bitmapFile); // Need to flip the endians in this one
		
		for (i = 0; i < (size / 4); i++)
		{
			tmpint32_t[i] = bmpEndianSwap32(tmpint32_t[i]);
		}
	}
     */
}
- (void)readData:(void *)buffer address:(int32_t)address size:(int)size
{	

	fread(buffer,size,1,bitmapFile);
		
	if (isPPC)
	{
		int32_t *tmpint32_t = (int32_t *)buffer;
		int i;
	
		// I need to make a working PPC hack here.
		//CSLog(@"Were in PPC!");
		fread(buffer, size, 1, bitmapFile); // Need to flip the endians in this one
		/* Everything here is being read in multiples of 4, so lets get cracking. */
		
		for (i = 0; i < (size / 4); i++)
		{
			tmpint32_t[i] = bmpEndianSwap32(tmpint32_t[i]);
		}
	}
}
- (NSSize)textureSizeForImageIndex:(int)index
{
	return NSMakeSize(images[index].width, images[index].height);
}
- (void)setImagePixelsForImageIndex:(int)index withBytes:(unsigned int*)imageBytes
{
    imageBytesLookup[index] = (uint64_t)imageBytes;
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

-(void)changed
{
    bitmapModified = YES;
}

/*! @brief Decompresses an image in memory.
 
 @param rgba		Storage for the decompressed pixels.
 @param width	The width of the source image.
 @param height	The height of the source image.
 @param blocks	The compressed DXT blocks.
 @param flags	Compression flags.
 
 The decompressed pixels will be written as a contiguous array of width*height
 16 rgba values, with each component as 1 byte each. In memory this is:
 
 { r1, g1, b1, a1, .... , rn, gn, bn, an } for n = width*height
 
 The flags parameter should specify either kDxt1, kDxt3 or kDxt5 compression,
 however, DXT1 will be used by default if none is specified. All other flags
 are ignored.
 
 Internally this function calls squish::Decompress for each block.
 */

/*
static uint32_t PackRGBA (uint8_t r, uint8_t g, uint8_t b, uint8_t a)
{
    return r | (g << 8) | (b << 16) | (a << 24);
}

static void DecompressBlockDXT1Internal (const uint8_t* block,
                                         uint32_t* output,
                                         uint32_t outputStride,
                                         uint8_t* alphaValues)
{
    uint32_t temp, code;
    
    uint16_t color0, color1;
    uint8_t r0, g0, b0, r1, g1, b1;
    
    int i, j;
    
    color0 = *(const uint16_t*)(block);
    color1 = *(const uint16_t*)(block + 2);
    
    temp = (color0 >> 11) * 255 + 16;
    r0 = (uint8_t)((temp/32 + temp)/32);
    temp = ((color0 & 0x07E0) >> 5) * 255 + 32;
    g0 = (uint8_t)((temp/64 + temp)/64);
    temp = (color0 & 0x001F) * 255 + 16;
    b0 = (uint8_t)((temp/32 + temp)/32);
    
    temp = (color1 >> 11) * 255 + 16;
    r1 = (uint8_t)((temp/32 + temp)/32);
    temp = ((color1 & 0x07E0) >> 5) * 255 + 32;
    g1 = (uint8_t)((temp/64 + temp)/64);
    temp = (color1 & 0x001F) * 255 + 16;
    b1 = (uint8_t)((temp/32 + temp)/32);
    
    code = *(const uint32_t*)(block + 4);
    
    for (j = 0; j < 4; j++) {
        for (i = 0; i < 4; i++) {
            uint32_t finalColor, positionCode;
            uint8_t alpha;
            
            if (alphaValues == NULL) {
                alpha = 255;
            } else {
                alpha = alphaValues [j*4+i];
            }
            
            finalColor = 0;
            positionCode = (code >>  2*(4*j+i)) & 0x03;
            
            if (color0 > color1) {
                switch (positionCode) {
                    case 0:
                        finalColor = PackRGBA(r0, g0, b0, alpha);
                        break;
                    case 1:
                        finalColor = PackRGBA(r1, g1, b1, alpha);
                        break;
                    case 2:
                        finalColor = PackRGBA((2*r0+r1)/3, (2*g0+g1)/3, (2*b0+b1)/3, alpha);
                        break;
                    case 3:
                        finalColor = PackRGBA((r0+2*r1)/3, (g0+2*g1)/3, (b0+2*b1)/3, alpha);
                        break;
                }
            } else {
                switch (positionCode) {
                    case 0:
                        finalColor = PackRGBA(r0, g0, b0, alpha);
                        break;
                    case 1:
                        finalColor = PackRGBA(r1, g1, b1, alpha);
                        break;
                    case 2:
                        finalColor = PackRGBA((r0+r1)/2, (g0+g1)/2, (b0+b1)/2, alpha);
                        break;
                    case 3:
                        finalColor = PackRGBA(0, 0, 0, alpha);
                        break;
                }
            }
            
            output [j*outputStride + i] = finalColor;
        }
    }
}


void DecompressBlockDXT1(uint32_t x, uint32_t y, uint32_t width,
                         const uint8_t* blockStorage,
                         uint32_t* image)
{
    DecompressBlockDXT1Internal (blockStorage,
                                 image + x + (y * width), width, NULL);
}


void DecompressBlockDXT5(uint32_t x, uint32_t y, uint32_t width,
                         const uint8_t* blockStorage,
                         uint32_t* image)
{
    uint8_t alpha0, alpha1;
    const uint8_t* bits;
    uint32_t alphaCode1;
    uint16_t alphaCode2;
    
    uint16_t color0, color1;
    uint8_t r0, g0, b0, r1, g1, b1;
    
    int i, j;
    
    uint32_t temp, code;
    
    alpha0 = *(blockStorage);
    alpha1 = *(blockStorage + 1);
    
    bits = blockStorage + 2;
    alphaCode1 = bits[2] | (bits[3] << 8) | (bits[4] << 16) | (bits[5] << 24);
    alphaCode2 = bits[0] | (bits[1] << 8);
    
    color0 = *(const uint16_t*)(blockStorage + 8);
    color1 = *(const uint16_t*)(blockStorage + 10);
    
    temp = (color0 >> 11) * 255 + 16;
    r0 = (uint8_t)((temp/32 + temp)/32);
    temp = ((color0 & 0x07E0) >> 5) * 255 + 32;
    g0 = (uint8_t)((temp/64 + temp)/64);
    temp = (color0 & 0x001F) * 255 + 16;
    b0 = (uint8_t)((temp/32 + temp)/32);
    
    temp = (color1 >> 11) * 255 + 16;
    r1 = (uint8_t)((temp/32 + temp)/32);
    temp = ((color1 & 0x07E0) >> 5) * 255 + 32;
    g1 = (uint8_t)((temp/64 + temp)/64);
    temp = (color1 & 0x001F) * 255 + 16;
    b1 = (uint8_t)((temp/32 + temp)/32);
    
    code = *(const uint32_t*)(blockStorage + 12);
    
    for (j = 0; j < 4; j++) {
        for (i = 0; i < 4; i++) {
            uint8_t finalAlpha;
            int alphaCode, alphaCodeIndex;
            uint8_t colorCode;
            uint32_t finalColor;
            
            alphaCodeIndex = 3*(4*j+i);
            if (alphaCodeIndex <= 12) {
                alphaCode = (alphaCode2 >> alphaCodeIndex) & 0x07;
            } else if (alphaCodeIndex == 15) {
                alphaCode = (alphaCode2 >> 15) | ((alphaCode1 << 1) & 0x06);
            } else{
                alphaCode = (alphaCode1 >> (alphaCodeIndex - 16)) & 0x07;
            }
            
            if (alphaCode == 0) {
                finalAlpha = alpha0;
            } else if (alphaCode == 1) {
                finalAlpha = alpha1;
            } else {
                if (alpha0 > alpha1) {
                    finalAlpha = (uint8_t)(((8-alphaCode)*alpha0 + (alphaCode-1)*alpha1)/7);
                } else {
                    if (alphaCode == 6) {
                        finalAlpha = 0;
                    } else if (alphaCode == 7) {
                        finalAlpha = 255;
                    } else {
                        finalAlpha = (uint8_t)(((6-alphaCode)*alpha0 + (alphaCode-1)*alpha1)/5);
                    }
                }
            }
            
            colorCode = (code >> 2*(4*j+i)) & 0x03;
            finalColor = 0;
            
            switch (colorCode) {
                case 0:
                    finalColor = PackRGBA(r0, g0, b0, finalAlpha);
                    break;
                case 1:
                    finalColor = PackRGBA(r1, g1, b1, finalAlpha);
                    break;
                case 2:
                    finalColor = PackRGBA((2*r0+r1)/3, (2*g0+g1)/3, (2*b0+b1)/3, finalAlpha);
                    break;
                case 3:
                    finalColor = PackRGBA((r0+2*r1)/3, (g0+2*g1)/3, (b0+2*b1)/3, finalAlpha);
                    break;
            }
            
            image [i + x + (width* (y+j))] = finalColor;
        }
    }
}


void DecompressBlockDXT3(uint32_t x, uint32_t y, uint32_t width,
                         const uint8_t* blockStorage,
                         uint32_t* image)
{
    int i;
    
    uint8_t alphaValues [16] = { 0 };
    
    for (i = 0; i < 4; ++i) {
        const uint16_t* alphaData = (const uint16_t*) (blockStorage);
        
        alphaValues [i*4 + 0] = (((*alphaData) >> 0) & 0xF ) * 17;
        alphaValues [i*4 + 1] = (((*alphaData) >> 4) & 0xF ) * 17;
        alphaValues [i*4 + 2] = (((*alphaData) >> 8) & 0xF ) * 17;
        alphaValues [i*4 + 3] = (((*alphaData) >> 12) & 0xF) * 17;
        
        blockStorage += 2;
    }
    
    DecompressBlockDXT1Internal (blockStorage,
                                 image + x + (y * width), width, alphaValues);
}

typedef unsigned char u8;

// -----------------------------------------------------------------------------


void DecompressImage( u8* rgba, int width, int height, void const* blocks, int flags );

static int Unpack565( u8 const* packed, u8* colour )
{
	// build the packed value
	int value = ( int )packed[0] | ( ( int )packed[1] << 8 );
	
	// get the components in the stored range
	u8 red = ( u8 )( ( value >> 11 ) & 0x1f );
	u8 green = ( u8 )( ( value >> 5 ) & 0x3f );
	u8 blue = ( u8 )( value & 0x1f );
    
	// scale up to 8 bits
	colour[0] = ( red << 3 ) | ( red >> 2 );
	colour[1] = ( green << 2 ) | ( green >> 4 );
	colour[2] = ( blue << 3 ) | ( blue >> 2 );
	colour[3] = 255;
	
	// return the value
	return value;
}

void DecompressColour( u8* rgba, void const* block, bool isDxt1 )
{
	// get the block bytes
	u8 const* bytes = (u8 const*)( block );
	
	// unpack the endpoints
	u8 codes[16];
	int a = Unpack565( bytes, codes );
	int b = Unpack565( bytes + 2, codes + 4 );
	
	// generate the midpoints
	for( int i = 0; i < 3; ++i )
	{
		int c = codes[i];
		int d = codes[4 + i];
        
		if( isDxt1 && a <= b )
		{
			codes[8 + i] = ( u8 )( ( c + d )/2 );
			codes[12 + i] = 0;
		}
		else
		{
			codes[8 + i] = ( u8 )( ( 2*c + d )/3 );
			codes[12 + i] = ( u8 )( ( c + 2*d )/3 );
		}
	}
	
	// fill in alpha for the intermediate values
	codes[8 + 3] = 255;
	codes[12 + 3] = ( isDxt1 && a <= b ) ? 0 : 255;
	
	// unpack the indices
	u8 indices[16];
	for( int i = 0; i < 4; ++i )
	{
		u8* ind = indices + 4*i;
		u8 packed = bytes[4 + i];
		
		ind[0] = packed & 0x3;
		ind[1] = ( packed >> 2 ) & 0x3;
		ind[2] = ( packed >> 4 ) & 0x3;
		ind[3] = ( packed >> 6 ) & 0x3;
	}
    
	// store out the colours
	for( int i = 0; i < 16; ++i )
	{
		u8 offset = 4*indices[i];
		for( int j = 0; j < 4; ++j )
			rgba[4*i + j] = codes[offset + j];
	}
}

static int FixFlags( int flags )
{
	// grab the flag bits
	int method = flags & ( kDxt1 | kDxt3 | kDxt5 );
	int fit = flags & ( kColourIterativeClusterFit | kColourClusterFit | kColourRangeFit );
	int metric = flags & ( kColourMetricPerceptual | kColourMetricUniform );
	int extra = flags & kWeightColourByAlpha;
	
	// set defaults
	if( method != kDxt3 && method != kDxt5 )
		method = kDxt1;
	if( fit != kColourRangeFit )
		fit = kColourClusterFit;
	if( metric != kColourMetricUniform )
		metric = kColourMetricPerceptual;
    
	// done
	return method | fit | metric | extra;
}


void DecompressAlphaDxt3( u8* rgba, void const* block )
{
	u8 const* bytes = (u8 const*)( block );
	
	// unpack the alpha values pairwise
	for( int i = 0; i < 8; ++i )
	{
		// quantise down to 4 bits
		u8 quant = bytes[i];
		
		// unpack the values
		u8 lo = quant & 0x0f;
		u8 hi = quant & 0xf0;
        
		// convert back up to bytes
		rgba[8*i + 3] = lo | ( lo << 4 );
		rgba[8*i + 7] = hi | ( hi >> 4 );
	}
}

void DecompressAlphaDxt5( u8* rgba, void const* block )
{
	// get the two alpha values
	u8 const* bytes = (u8 const*)( block );
	int alpha0 = bytes[0];
	int alpha1 = bytes[1];
	
	// compare the values to build the codebook
	u8 codes[8];
	codes[0] = ( u8 )alpha0;
	codes[1] = ( u8 )alpha1;
	if( alpha0 <= alpha1 )
	{
		// use 5-alpha codebook
		for( int i = 1; i < 5; ++i )
			codes[1 + i] = ( u8 )( ( ( 5 - i )*alpha0 + i*alpha1 )/5 );
		codes[6] = 0;
		codes[7] = 255;
	}
	else
	{
		// use 7-alpha codebook
		for( int i = 1; i < 7; ++i )
			codes[1 + i] = ( u8 )( ( ( 7 - i )*alpha0 + i*alpha1 )/7 );
	}
	
	// decode the indices
	u8 indices[16];
	u8 const* src = bytes + 2;
	u8* dest = indices;
	for( int i = 0; i < 2; ++i )
	{
		// grab 3 bytes
		int value = 0;
		for( int j = 0; j < 3; ++j )
		{
			int byte = *src++;
			value |= ( byte << 8*j );
		}
		
		// unpack 8 3-bit values from it
		for( int j = 0; j < 8; ++j )
		{
			int index = ( value >> 3*j ) & 0x7;
			*dest++ = ( u8 )index;
		}
	}
	
	// write out the indexed codebook values
	for( int i = 0; i < 16; ++i )
		rgba[4*i + 3] = codes[indices[i]];
}


void Decompress( u8* rgba, void const* block, int flags )
{
	// fix any bad flags
	flags = FixFlags( flags );
    
	// get the block locations
	void const* colourBlock = block;
	void const* alphaBock = block;
	if( ( flags & ( kDxt3 | kDxt5 ) ) != 0 )
		colourBlock = (u8 const*)( block ) + 8;
    
	// decompress colour
	DecompressColour( rgba, colourBlock, ( flags & kDxt1 ) != 0 );
    
	// decompress alpha separately if necessary
	if( ( flags & kDxt3 ) != 0 )
		DecompressAlphaDxt3( rgba, alphaBock );
	else if( ( flags & kDxt5 ) != 0 )
		DecompressAlphaDxt5( rgba, alphaBock );
}


static int FloatToInt( float a, int limit )
{
	// use ANSI round-to-zero behaviour to get round-to-nearest
	int i = ( int )( a + 0.5f );
    
	// clamp to the limit
	if( i < 0 )
		i = 0;
	else if( i > limit )
		i = limit;
    
	// done
	return i;
}


void CompressAlphaDxt3( u8 const* rgba, int mask, void* block )
{
	u8* bytes = (u8*)( block );
	
	// quantise and pack the alpha values pairwise
	for( int i = 0; i < 8; ++i )
	{
		// quantise down to 4 bits
		float alpha1 = ( float )rgba[8*i + 3] * ( 15.0f/255.0f );
		float alpha2 = ( float )rgba[8*i + 7] * ( 15.0f/255.0f );
		int quant1 = FloatToInt( alpha1, 15 );
		int quant2 = FloatToInt( alpha2, 15 );
		
		// set alpha to zero where masked
		int bit1 = 1 << ( 2*i );
		int bit2 = 1 << ( 2*i + 1 );
		if( ( mask & bit1 ) == 0 )
			quant1 = 0;
		if( ( mask & bit2 ) == 0 )
			quant2 = 0;
        
		// pack into the byte
		bytes[i] = ( u8 )( quant1 | ( quant2 << 4 ) );
	}
}

static void FixRange( int min, int max, int steps )
{
	if( max - min < steps )
		max = fmin( min + steps, 255 );
	if( max - min < steps )
		min = fmin( 0, max - steps );
}

static int FitCodes( u8 const* rgba, int mask, u8 const* codes, u8* indices )
{
	// fit each alpha value to the codebook
	int err = 0;
	for( int i = 0; i < 16; ++i )
	{
		// check this pixel is valid
		int bit = 1 << i;
		if( ( mask & bit ) == 0 )
		{
			// use the first code
			indices[i] = 0;
			continue;
		}
		
		// find the least error and corresponding index
		int value = rgba[4*i + 3];
		int least = INT_MAX;
		int index = 0;
		for( int j = 0; j < 8; ++j )
		{
			// get the squared error from this code
			int dist = ( int )value - ( int )codes[j];
			dist *= dist;
			
			// compare with the best so far
			if( dist < least )
			{
				least = dist;
				index = j;
			}
		}
		
		// save this index and accumulate the error
		indices[i] = ( u8 )index;
		err += least;
	}
	
	// return the total error
	return err;
}

static void WriteAlphaBlock( int alpha0, int alpha1, u8 const* indices, void* block )
{
	u8* bytes = (u8*)( block );
	
	// write the first two bytes
	bytes[0] = ( u8 )alpha0;
	bytes[1] = ( u8 )alpha1;
	
	// pack the indices with 3 bits each
	u8* dest = bytes + 2;
	u8 const* src = indices;
	for( int i = 0; i < 2; ++i )
	{
		// pack 8 3-bit values
		int value = 0;
		for( int j = 0; j < 8; ++j )
		{
			int index = *src++;
			value |= ( index << 3*j );
		}
        
		// store in 3 bytes
		for( int j = 0; j < 3; ++j )
		{
			int byte = ( value >> 8*j ) & 0xff;
			*dest++ = ( u8 )byte;
		}
	}
}

static void WriteAlphaBlock5( int alpha0, int alpha1, u8 const* indices, void* block )
{
	// check the relative values of the endpoints
	if( alpha0 > alpha1 )
	{
		// swap the indices
		u8 swapped[16];
		for( int i = 0; i < 16; ++i )
		{
			u8 index = indices[i];
			if( index == 0 )
				swapped[i] = 1;
			else if( index == 1 )
				swapped[i] = 0;
			else if( index <= 5 )
				swapped[i] = 7 - index;
			else
				swapped[i] = index;
		}
		
		// write the block
		WriteAlphaBlock( alpha1, alpha0, swapped, block );
	}
	else
	{
		// write the block
		WriteAlphaBlock( alpha0, alpha1, indices, block );
	}
}

static void WriteAlphaBlock7( int alpha0, int alpha1, u8 const* indices, void* block )
{
	// check the relative values of the endpoints
	if( alpha0 < alpha1 )
	{
		// swap the indices
		u8 swapped[16];
		for( int i = 0; i < 16; ++i )
		{
			u8 index = indices[i];
			if( index == 0 )
				swapped[i] = 1;
			else if( index == 1 )
				swapped[i] = 0;
			else
				swapped[i] = 9 - index;
		}
		
		// write the block
		WriteAlphaBlock( alpha1, alpha0, swapped, block );
	}
	else
	{
		// write the block
		WriteAlphaBlock( alpha0, alpha1, indices, block );
	}
}


void CompressAlphaDxt5( u8 const* rgba, int mask, void* block )
{
	// get the range for 5-alpha and 7-alpha interpolation
	int min5 = 255;
	int max5 = 0;
	int min7 = 255;
	int max7 = 0;
	for( int i = 0; i < 16; ++i )
	{
		// check this pixel is valid
		int bit = 1 << i;
		if( ( mask & bit ) == 0 )
			continue;
        
		// incorporate into the min/max
		int value = rgba[4*i + 3];
		if( value < min7 )
			min7 = value;
		if( value > max7 )
			max7 = value;
		if( value != 0 && value < min5 )
			min5 = value;
		if( value != 255 && value > max5 )
			max5 = value;
	}
	
	// handle the case that no valid range was found
	if( min5 > max5 )
		min5 = max5;
	if( min7 > max7 )
		min7 = max7;
    
	// fix the range to be the minimum in each case
	FixRange( min5, max5, 5 );
	FixRange( min7, max7, 7 );
	
	// set up the 5-alpha code book
	u8 codes5[8];
	codes5[0] = ( u8 )min5;
	codes5[1] = ( u8 )max5;
	for( int i = 1; i < 5; ++i )
		codes5[1 + i] = ( u8 )( ( ( 5 - i )*min5 + i*max5 )/5 );
	codes5[6] = 0;
	codes5[7] = 255;
	
	// set up the 7-alpha code book
	u8 codes7[8];
	codes7[0] = ( u8 )min7;
	codes7[1] = ( u8 )max7;
	for( int i = 1; i < 7; ++i )
		codes7[1 + i] = ( u8 )( ( ( 7 - i )*min7 + i*max7 )/7 );
    
	// fit the data to both code books
	u8 indices5[16];
	u8 indices7[16];
	int err5 = FitCodes( rgba, mask, codes5, indices5 );
	int err7 = FitCodes( rgba, mask, codes7, indices7 );
	
	// save the block with least error
	if( err5 <= err7 )
		WriteAlphaBlock5( min5, max5, indices5, block );
	else
		WriteAlphaBlock7( min7, max7, indices7, block );
}


void CompressMasked( u8 const* rgba, int mask, void* block, int flags )
{
	// fix any bad flags
	flags = FixFlags( flags );
    
	// get the block locations
	void* colourBlock = block;
	void* alphaBock = block;
	if( ( flags & ( kDxt3 | kDxt5 ) ) != 0 )
		colourBlock = (u8*)( block ) + 8;
   
	// create the minimal point set
	ColourSet colours( rgba, mask, flags );
	
	// check the compression type and compress colour
	if( colours.GetCount() == 1 )
	{
		// always do a single colour fit
		SingleColourFit fit( &colours, flags );
		fit.Compress( colourBlock );
	}
	else if( ( flags & kColourRangeFit ) != 0 || colours.GetCount() == 0 )
	{
		// do a range fit
		RangeFit fit( &colours, flags );
		fit.Compress( colourBlock );
	}
	else
	{
		// default to a cluster fit (could be iterative or not)
		ClusterFit fit( &colours, flags );
		fit.Compress( colourBlock );
	}

    
	// compress alpha separately if necessary
	if( ( flags & kDxt3 ) != 0 )
		CompressAlphaDxt3( rgba, mask, alphaBock );
	else if( ( flags & kDxt5 ) != 0 )
		CompressAlphaDxt5( rgba, mask, alphaBock );
}

void CompressImage( u8 const* rgba, int width, int height, void* blocks, int flags )
{
	// fix any bad flags
	flags = FixFlags( flags );
    
	// initialise the block output
	u8* targetBlock = (u8*)( blocks );
	int bytesPerBlock = ( ( flags & kDxt1 ) != 0 ) ? 8 : 16;
    
	// loop over blocks
	for( int y = 0; y < height; y += 4 )
	{
		for( int x = 0; x < width; x += 4 )
		{
			// build the 4x4 block of pixels
			u8 sourceRgba[16*4];
			u8* targetPixel = sourceRgba;
			int mask = 0;
			for( int py = 0; py < 4; ++py )
			{
				for( int px = 0; px < 4; ++px )
				{
					// get the source pixel in the image
					int sx = x + px;
					int sy = y + py;
					
					// enable if we're in the image
					if( sx < width && sy < height )
					{
						// copy the rgba value
						u8 const* sourcePixel = rgba + 4*( width*sy + sx );
						for( int i = 0; i < 4; ++i )
							*targetPixel++ = *sourcePixel++;
                        
						// enable this pixel
						mask |= ( 1 << ( 4*py + px ) );
					}
					else
					{
						// skip this pixel as its outside the image
						targetPixel += 4;
					}
				}
			}
			
			// compress it into the output
			CompressMasked( sourceRgba, mask, targetBlock, flags );
			
			// advance
			targetBlock += bytesPerBlock;
		}
	}
}


void DecompressImage( u8* rgba, int width, int height, void const* blocks, int flags )
{
	// fix any bad flags
	flags = FixFlags( flags );
    
	// initialise the block input
	u8 const* sourceBlock = (u8 const*)( blocks );
	int bytesPerBlock = ( ( flags & kDxt1 ) != 0 ) ? 8 : 16;
    
	// loop over blocks
	for( int y = 0; y < height; y += 4 )
	{
		for( int x = 0; x < width; x += 4 )
		{
			// decompress the block
			u8 targetRgba[4*16];
			Decompress( targetRgba, sourceBlock, flags );
			
			// write the decompressed pixels to the correct image locations
			u8 const* sourcePixel = targetRgba;
			for( int py = 0; py < 4; ++py )
			{
				for( int px = 0; px < 4; ++px )
				{
					// get the target location
					int sx = x + px;
					int sy = y + py;
					if( sx < width && sy < height )
					{
						u8* targetPixel = rgba + 4*( width*sy + sx );
						
						// copy the rgba value
						for( int i = 0; i < 4; ++i )
							*targetPixel++ = *sourcePixel++;
					}
					else
					{
						// skip this pixel as its outside the image
						sourcePixel += 4;
					}
				}
			}
			
			// advance
			sourceBlock += bytesPerBlock;
		}
	}
}
*/


-(void)internaliseImage:(int)index size:(int32_t)lengthOfData withBytes:(void *)imageBytes
{
    
    NSLog(@"Internalising image");
    
    int32_t oldOffset = images[index].offset;
    int32_t oldSize = images[index].size;
    
    fseek([_mapfile currentFile], 0L, SEEK_END);
    int32_t sz = ftell([_mapfile currentFile]);
    
    //Update the actual mapfile to fix the image values we just added.
    int32_t currentOffset = [_mapfile currentOffset];
    
    [_mapfile seekToAddress:([self offsetInMap] + 0x02)];
    [_mapfile readShort:&format];
    
    [_mapfile seekToAddress:([self offsetInMap] + 0x04)];
    [_mapfile readShort:&usage];
    
    [_mapfile seekToAddress:([self offsetInMap] + 0x54)];
    header.reflexive_to_first = [_mapfile readReflexive];
    header.image_reflexive = [_mapfile readReflexive];
    
    //Where is the end of the file?
    images[index].offset = sz;
    images[index].internalized = 0;

    [_mapfile seekToAddress:(header.image_reflexive.offset) + (48*index)+15];
    [_mapfile writeByteAtAddress:(void*)(&images[index].internalized) address:((header.image_reflexive.offset) + (48*index)+15)];
    [_mapfile seekToAddress:(header.image_reflexive.offset) + (48*index)+24];
    [_mapfile writeint32_t:(int32_t*)(&images[index].offset)];
    
    
    if (images[index].num_mipmaps <=1)
    {
    
    [_mapfile seekToAddress:(header.image_reflexive.offset) + (48*index)+28];
    [_mapfile writeint32_t:(int32_t*)(&lengthOfData)];
    }
    
    //&tempImage->size
    
    
    [_mapfile seekToAddress:currentOffset];
    
    //Copy across the old data from the bitmaps file
    
    char *inData;
	inData = (char *)malloc(oldSize);
    [self seekToOffset:oldOffset];
    [self readData:inData address:[self currentOffset] size:oldSize];
        
    [_mapfile writeAnyDataAtAddress:inData size:oldSize address:images[index].offset];
    [_mapfile writeAnyDataAtAddress:imageBytes size:lengthOfData address:images[index].offset];
    
    free(inData);
}

-(BOOL)writeImageToMap:(int)index withBytes:(unsigned int *)imageBytes
{
    if (!bitmapModified)
        return NO;
    
    unsigned short *outData;
	int lengthOfData;
	
    if (!imageBytes)
        return NO;
    
	if (!bitmapFile)
		return FALSE;
	
	lengthOfData = getImageSize(images[index].format, images[index].width, images[index].height);
	outData = (unsigned short *)malloc(lengthOfData);
	
	switch (images[index].format)
	{
        case BITM_FORMAT_R5G6B5:
			EncodeLinearR5G6B5(images[index].width,images[index].height,(const int*)imageBytes,(unsigned short*)outData);
            break;
        case BITM_FORMAT_DXT1:
			CompressImage((u8*)imageBytes,images[index].width,images[index].height,(u8 *)outData,kDxt1);
            break;
        case BITM_FORMAT_DXT2AND3:
			CompressImage((u8*)imageBytes,images[index].width,images[index].height,(u8 *)outData,kDxt3);
            break;
        case BITM_FORMAT_DXT4AND5:
			CompressImage((u8*)imageBytes,images[index].width,images[index].height,(u8 *)outData,kDxt5);
			break;
        default:
        {
            return NO;
        }
	}
    
    if (images[index].internalized == 0)
	{
        [_mapfile writeAnyDataAtAddress:outData size:lengthOfData address:images[index].offset];
    }
    else
    {
        [self internaliseImage:index size:lengthOfData withBytes:outData];
    }
    
    return YES;
}

-(BOOL)needsAlpha:(int)index
{
    if (images[index].format == BITM_FORMAT_X8R8G8B8)
        return YES;
    
    if (format == 4 && usage == 1)// && (images[index].format == BITM_FORMAT_X8R8G8B8 || images[index].format == BITM_FORMAT_DXT1))
        return YES;
    return NO;
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
	
    if (lengthOfData >= 0)
    {
        inData = (char *)malloc(lengthOfData);
        
        if (images[index].internalized == 0)
        {
            //CSLog(@"Size of data: 0x%x, at address: 0x%x", lengthOfData, images[index].offset);
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
                DecompressImage((u8 *)imageBytes,images[index].width,images[index].height,inData,kDxt3);
                break;
            case BITM_FORMAT_DXT4AND5:
                DecompressImage((u8 *)imageBytes,images[index].width,images[index].height,inData,kDxt5);
                break;
            case BITM_FORMAT_X8R8G8B8:
                DecodeLinearX8R8G8B8(images[index].width,images[index].height,inData,imageBytes);
                break;
            case BITM_FORMAT_A8R8G8B8:
                DecodeLinearA8R8G8B8(images[index].width,images[index].height,inData,imageBytes);
                break;
            case BITM_FORMAT_R5G6B5:
                DecodeLinearR5G6B5(images[index].width,images[index].height,inData,imageBytes);
                break;
            case BITM_FORMAT_DXT1:
                //CSLog(@"DXT 1");
                DecompressImage((u8 *)imageBytes,images[index].width,images[index].height,inData,kDxt1);
                break;
            default:
                return NO;
        
        }
        
        free(inData);
    }
   
    
    /*
    float width    = images[index].width;
    float height   = images[index].height;
    int   channels = 4;
    
    // create a buffer for our image after converting it from 565 rgb to 8888rgba
    u_int8_t* rawData = (u_int8_t*)malloc(width*height*channels);
    
    // unpack the 5,6,5 pixel data into 24 bit RGBA
    for (int i=0; i<width*height; ++i)
    {
        // append two adjacent bytes in texture->data into a 16 bit int
        u_int16_t pixel16 = (imageBytes[i*2] << 8) + imageBytes[i*2+1];
        // mask and shift each pixel into a single 8 bit unsigned, then normalize by 5/6 bit
        // max to 8 bit integer max.  Alpha set to 0.
        rawData[channels*i]   = ((pixel16 & 63488)       >> 11) / 31.0 * 255;
        rawData[channels*i+1] = ((pixel16 & 2016)  << 5  >> 10) / 63.0 * 255;
        rawData[channels*i+2] = ((pixel16 & 31)    << 11 >> 11) / 31.0 * 255;
        
        rawData[channels*4+3] = 0;
    }
    
    // same as before
    int                    bitsPerComponent = 8;
    int                    bitsPerPixel     = channels*bitsPerComponent;
    int                    bytesPerRow      = channels*width;
    CGColorSpaceRef        colorSpaceRef    = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo           bitmapInfo       = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent  = kCGRenderingIntentDefault;
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL,
                                                              rawData,
                                                              channels*width*height,
                                                              NULL);
    free( rawData );
    CGImageRef        imageRef = CGImageCreate(width,
                                               height,
                                               bitsPerComponent,
                                               bitsPerPixel,
                                               bytesPerRow,
                                               colorSpaceRef,
                                               bitmapInfo,
                                               provider,NULL,NO,renderingIntent);
    
    
    
    [[[[NSImage alloc] initWithCGImage:imageRef size:NSMakeSize(width, height)] TIFFRepresentation] writeToFile:@"/Users/colbrans/Desktop/Images/bitmap.tif" atomically:YES];
    */
    
    
	imageBytesLookup[index] = (uint64_t)imageBytes;
	return (imageLoaded[index] = TRUE);
}
- (BOOL)imageAlreadyLoaded:(int)index
{
    //if (index >= header.image_reflexive.chunkcount)
    //    return NO;
    
    //CSLog(@"Chunks: %ld", header.image_reflexive.chunkcount);
	return imageLoaded[index];
}
- (int)imageCount
{
    return cImage;
	//return [subImageee count];
}
- (int *)subImages
{
	return subImages;
}
@end