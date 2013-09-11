//
//  BitmapTag.m
//  SparkEdit
//
//  Created by Michael Edgar on Tue Jun 22 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "BitmapTag.h"
#import "HaloMap.h"
#import "NSFile.h"

#define BIT16BMASK (0x01|0x02|0x04|0x08|0x10) 
#define BIT16GMASK (0x20|0x40|0x80|0x100|0x200|0x400) 
#define BIT16RMASK (0x800|0x1000|0x2000|0x4000|0x8000) 
 
#define BIT16BSIZE     32 
#define BIT16GSIZE     64 
#define BIT16RSIZE     32 
 
#define BIT16RDIST     11 
#define BIT16GDIST     5 
#define BIT16BDIST     0 
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
			size = width * height;
			break;
		
		case BITM_FORMAT_A8Y8:
		case BITM_FORMAT_R5G6B5:
		case BITM_FORMAT_A1R5G5B5:
		case BITM_FORMAT_A4R4G4B4:
			size = width * height * 2;
			break;
		
		case BITM_FORMAT_X8R8G8B8:
		case BITM_FORMAT_A8R8G8B8:
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

/*-------------------------------------------------------------------
 * Name: ConvertWORDToRGB()
 * Description:
 *   
 *-----------------------------------------------------------------*/
RGB ConvertWORDToRGB(WORD Color)
{
	//Color = Swap ((short)Color);

	RGB rc;
	rc.R = ((Color&BIT16RMASK)>>BIT16RDIST)*0xff/BIT16RSIZE; 
	rc.G = ((Color&BIT16GMASK)>>BIT16GDIST)*0xff/BIT16GSIZE; 
	rc.B = ((Color&BIT16BMASK)>>BIT16BDIST)*0xff/BIT16BSIZE;
	rc.T = 255;

	return rc;
}

/*-------------------------------------------------------------------
 * Name: RGBToDWORD()
 * Description:
 *   
 *-----------------------------------------------------------------*/
DWORD RGBToDWORD(RGB Color) 
{ 
	return (Color.T<<24)|(Color.R<<16)|(Color.G<<8)|Color.B;
}


/*-------------------------------------------------------------------
 * Name: GradientColors()
 * Description:
 *   
 *-----------------------------------------------------------------*/
rgba_color_t GradientColors (rgba_color_t Col1, rgba_color_t Col2)
{
	rgba_color_t ret;
	ret.r = ((Col1.r*2 + Col2.r))/3;
	ret.g = ((Col1.g*2 + Col2.g))/3;
	ret.b = ((Col1.b*2 + Col2.b))/3;
	ret.a = 255;
	return ret;
}
unsigned int rgba_to_int (rgba_color_t color) 
{ 
	return (color.r << 24) | (color.g << 16) | (color.b << 8) | (color.a);
}

rgba_color_t short_to_rgba (unsigned short color)
{
	rgba_color_t rc;
	rc.r = (((color >> 11) & 0x1F) * 0xFF) / 31;
	rc.g = (((color >>  5) & 0x3F) * 0xFF) / 63;
	rc.b = (((color >>  0) & 0x1F) * 0xFF) / 31;
	rc.a =255;

	return rc;
}
/*-------------------------------------------------------------------
 * Name: GradientColorsHalf()
 * Description:
 *   
 *-----------------------------------------------------------------*/
rgba_color_t GradientColorsHalf (rgba_color_t Col1, rgba_color_t Col2)
{
	rgba_color_t ret;
	ret.r = (Col1.r/2 + Col2.r/2);
	ret.g = (Col1.g/2 + Col2.g/2);
	ret.b = (Col1.b/2 + Col2.b/2);
	ret.a = 255;
	return ret;
}
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
///////////////   C R U C I A L    F U N C T I O N S ////////////////////
////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//Assume the rest work. these are the important ones.

void DecodeBitmSurface (const char *data, int width, int height, int depth, 
                                   int format, int flags, unsigned int *pOutBuf)
{
	if (!width)
		width = 1;
	
	if (!height)
		height = 1;

	//if(flags & BITM_FLAG_LINEAR)
	//{
		switch (format)
		{
			case BITM_FORMAT_A8:		DecodeLinearA8 (width, height, data, pOutBuf); break;
			case BITM_FORMAT_Y8:		DecodeLinearY8 (width, height, data, pOutBuf); break;
			case BITM_FORMAT_AY8:		DecodeLinearAY8 (width, height, data, pOutBuf); break;
			case BITM_FORMAT_A8Y8:		DecodeLinearA8Y8 (width, height, data, pOutBuf); break;
			case BITM_FORMAT_R5G6B5:	DecodeLinearR5G6B5 (width, height, data, pOutBuf); break;
			case BITM_FORMAT_A1R5G5B5:	DecodeLinearA1R5G5B5 (width, height, data, pOutBuf); break;
			case BITM_FORMAT_A4R4G4B4:	DecodeLinearA4R4G4B4 (width, height, data, pOutBuf); break;
			case BITM_FORMAT_X8R8G8B8:	DecodeLinearX8R8G8B8 (width, height, data, pOutBuf); break;
			case BITM_FORMAT_A8R8G8B8:	DecodeLinearA8R8G8B8 (width, height, data, pOutBuf); break;
			case BITM_FORMAT_DXT1:		DecodeDXT1 (height, width, data, pOutBuf); break;
			case BITM_FORMAT_DXT2AND3:	DecodeDXT2And3 (height, width, data, pOutBuf); break;
			case BITM_FORMAT_DXT4AND5:	DecodeDXT4And5 (height, width, data, pOutBuf); break;
			case BITM_FORMAT_P8:		DecodeLinearP8 (width, height, data, pOutBuf); break;
			
		}
	//}
}
void DecodeDXT1(int Height, int Width, const char* IData, unsigned int* PData)
{
	rgba_color_t		Color[4];
	int					i;
	int					dptr;
	rgba_color_t		CColor;
	unsigned int		CData;
	unsigned int		ChunksPerHLine = Width / 4;
	bool				trans;
	static rgba_color_t	zeroColor = {0, 0, 0, 0};
	
	for (i = 0, dptr = 0; i < (Width * Height); i += 16, dptr += 8)
	{
		unsigned short	c1, c2;
		
		c1 = *(unsigned short *)&IData[dptr];
		c1 = bmpEndianSwap16(c1);
		c2 = *(unsigned short *)&IData[dptr+2];
		c2 = bmpEndianSwap16(c2);
		if(c1 > c2)
			trans = false;
		else
			trans = true;
	
		Color[0] = short_to_rgba(c1);
		Color[1] = short_to_rgba(c2);
		if (!trans)
		{
			Color[2] = GradientColors(Color[0], Color[1]);
			Color[3] = GradientColors(Color[1], Color[0]);
		}
		else
		{
			Color[2] = GradientColorsHalf (Color[0], Color[1]);
			Color[3] = zeroColor;
		}
		
		CData = *(unsigned int *)&(IData[dptr+4]);
		CData = bmpEndianSwap32(CData);
		unsigned int ChunkNum = i / 16;
		unsigned int XPos = ChunkNum % ChunksPerHLine;
		unsigned int YPos = (ChunkNum - XPos) / ChunksPerHLine;
		
		int		sizew, sizeh;

		sizeh = (Height < 4) ? Height : 4;
		sizew = (Width < 4) ? Width : 4;
		int x,y;
		for (x = 0; x < sizeh; x++)
		{
			for (y = 0; y < sizew; y++)
			{
				CColor = Color[CData & 0x03];
				CData >>= 2;
				PData[(YPos*4+x)*Width + XPos*4+y] = rgba_to_int(CColor);
			}
		}
	}
}
/*================================
 * DecodeLinearA8 
================================*/
void DecodeLinearA8 (int width, int height, const char *texdata, unsigned int *outdata)
{
	int y,x;
	for (y = 0; y < height; y++)
		for (x = 0; x < width; x++)
			outdata[(y * width) + x] = texdata[(y * width) + x] << 24;
}



/*================================
 * DecodeLinearY8 
================================*/
void DecodeLinearY8 (int width, int height, const char *texdata, unsigned int *outdata)
{
	rgba_color_t	color;
	int y,x;
	for (y = 0; y < height; y++)
	{
		for (x = 0; x < width; x++)
		{
			color.r = color.g = color.b = texdata[(y * width) + x];
			color.a = 0;
			
			outdata[(y * width) + x] = rgba_to_int (color);
		}
	}
}



/*================================
 * DecodeLinearAY8 
================================*/
void DecodeLinearAY8 (int width, int height, const char *texdata, unsigned int *outdata)
{
	rgba_color_t	color;
	int x,y;
	for (y = 0; y < height; y++)
	{
		for (x = 0; x < width; x++)
		{
			color.r = color.g = color.b = color.a = texdata[(y * width) + x];
			outdata[(y * width) + x] = rgba_to_int (color);
		}
	}
}



/*================================
 * DecodeLinearA8Y8 
================================*/
void DecodeLinearA8Y8 (int width, int height, const char *texdata, unsigned int *outdata)
{
	rgba_color_t	color;
	unsigned short	cdata;
	int y,x;
	for (y = 0; y < height; y++)
	{
		for (x = 0; x < width; x++)
		{
			cdata = ((short *)texdata)[(y * width) + x];
			color.r = color.g = color.b = cdata >> 8;
			color.a = cdata & 0xFF;
			outdata[(y * width) + x] = rgba_to_int (color);
		}
	}
}



/*================================
 * DecodeLinearR5G6B5 
================================*/
void DecodeLinearR5G6B5 (int width, int height, const char *texdata, unsigned int *outdata)
{
	int x,y;
	for (y = 0; y < height; y++)
		for (x = 0; x < width; x++)
			outdata[(y * width) + x] = rgba_to_int (short_to_rgba (bmpEndianSwap16(((short *)texdata)[(y * width) + x])));
}


/*================================
 * DecodeLinearA1R5G5B5 
================================*/
void DecodeLinearA1R5G5B5 (int width, int height, const char *texdata, unsigned int *outdata)
{
	rgba_color_t	color;
	unsigned short	cdata;
	int x,y;
	for (y = 0; y < height; y++)
	{
		for (x = 0; x < width; x++)
		{
			cdata = ((short *)texdata)[(y * width) + x];
			cdata = bmpEndianSwap16(cdata);
			color.a = (cdata >> 15) * 0xFF;
			color.r = (((cdata >> 10) & 0x1F) * 0xFF) / 31;
			color.g = (((cdata >>  5) & 0x1F) * 0xFF) / 31;
			color.b = (((cdata >>  0) & 0x1F) * 0xFF) / 31;

			outdata[(y * width) + x] = rgba_to_int (color);
		}
	}
}


/*================================
 * DecodeLinearA4R4G4B4 
================================*/
void DecodeLinearA4R4G4B4 (int width, int height, const char *texdata, unsigned int *outdata)
{
	rgba_color_t	color;
	unsigned short	cdata;
	int x,y;
	for (y = 0; y < height; y++)
	{
		for (x = 0; x < width; x++)
		{
			cdata = ((short *)texdata)[(y * width) + x];
			cdata = bmpEndianSwap16(cdata);
			color.a = ((cdata >> 12) * 0xFF) / 15;
			color.r = (((cdata >>  8) & 0x0F) * 0xFF) / 15;
			color.g = (((cdata >>  4) & 0x0F) * 0xFF) / 15;
			color.b = (((cdata >>  0) & 0x0F) * 0xFF) / 15;

			outdata[(y * width) + x] = rgba_to_int (color);
		}
	}
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
			cdata = bmpEndianSwap32(cdata);	
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
			cdata = bmpEndianSwap32(cdata);
			color.a = (cdata >> 24);
			color.r = (cdata >> 16) & 0xFF;
			color.g = (cdata >>  8) & 0xFF;
			color.b = (cdata >>  0) & 0xFF;

			outdata[(y * width) + x] = rgba_to_int (color);
		}
	}
}



/*================================
 * DecodeLinearP8 
================================*/
void DecodeLinearP8 (int width, int height, const char *texdata, unsigned int *outdata)
{
	rgba_color_t	color;
	int x,y;
	for (y = 0; y < height; y++)
	{
		for (x = 0; x < width; x++)
		{
			color.a = 0;
			color.r = color.g = color.b = texdata[(y * width) + x];
			outdata[(y * width) + x] = rgba_to_int (color);
		}
	}
}


/*================================
 * DecodeDXT2And3 
================================*/
void DecodeDXT2And3 (int Height, int Width, const char* IData, unsigned int* PData)
{
	rgba_color_t	Color[4];
	int				i;
	rgba_color_t	CColor;
	unsigned int	CData;
	unsigned int	ChunksPerHLine = Width / 4;
	unsigned short	Alpha;
	
	if (!ChunksPerHLine)
		ChunksPerHLine = 1;
	
	for (i = 0; i < (Width * Height); i += 16)
	{
		Color[0] = short_to_rgba(bmpEndianSwap16(*(unsigned short *)&IData[i+8]));
		Color[1] = short_to_rgba(bmpEndianSwap16(*(unsigned short *)&IData[i+10]));
		Color[2] = GradientColors(Color[0], Color[1]);
		Color[3] = GradientColors(Color[1], Color[0]);

		CData = *(unsigned int *)&IData[i+12];
		CData = bmpEndianSwap32(CData);
		unsigned int ChunkNum = i / 16;
		unsigned int XPos = ChunkNum % ChunksPerHLine;
		unsigned int YPos = (ChunkNum - XPos) / ChunksPerHLine;
		
		int		sizew, sizeh;

		sizeh = (Height < 4) ? Height : 4;
		sizew = (Width < 4) ? Width : 4;
		int x,y;
		for(x = 0; x < sizeh; x++)
		{
			Alpha = *(short *)&IData[i + (2 * x)];
			Alpha = bmpEndianSwap16(Alpha);
			for(y = 0; y < sizew; y++)
			{
				CColor = Color[CData & 0x03];
				CData >>= 2;

				CColor.a = (Alpha & 0x0F) * 16;
				Alpha >>= 4;

				PData[(YPos*4+x)*Width + XPos*4+y] = rgba_to_int(CColor);
			}
		}
	}
}

/*================================
 * DecodeDXT4And5 
================================*/
void DecodeDXT4And5 (int Height, int Width, const char* IData, unsigned int* PData)
{
	rgba_color_t	Color[4];
	int				i;
	rgba_color_t	CColor;
	unsigned int	CData;
	unsigned int	ChunksPerHLine = Width / 4;
	unsigned char	Alpha[8];
	uint64_t		AlphaDat;
	
	if (!ChunksPerHLine)
		ChunksPerHLine = 1;
	
	for (i = 0; i < (Width * Height); i += 16)
	{
		Color[0] = short_to_rgba(bmpEndianSwap16(*(unsigned short *)&IData[i+8]));
		Color[1] = short_to_rgba(bmpEndianSwap16(*(unsigned short *)&IData[i+10]));
		Color[2] = GradientColors(Color[0], Color[1]);
		Color[3] = GradientColors(Color[1], Color[0]);

		CData = (int)*(unsigned int *)&IData[i+12];
		CData = bmpEndianSwap32(CData);
		Alpha[0] = IData[i];
		Alpha[1] = IData[i+1];

		// Do the alphas
		if (Alpha[0] > Alpha[1])
		{    
			// 8-alpha block:  derive the other six alphas.
			// Bit code 000 = alpha_0, 001 = alpha_1, others are interpolated.
			Alpha[2] = (6 * Alpha[0] + 1 * Alpha[1] + 3) / 7;	// bit code 010
			Alpha[3] = (5 * Alpha[0] + 2 * Alpha[1] + 3) / 7;	// bit code 011
			Alpha[4] = (4 * Alpha[0] + 3 * Alpha[1] + 3) / 7;	// bit code 100
			Alpha[5] = (3 * Alpha[0] + 4 * Alpha[1] + 3) / 7;	// bit code 101
			Alpha[6] = (2 * Alpha[0] + 5 * Alpha[1] + 3) / 7;	// bit code 110
			Alpha[7] = (1 * Alpha[0] + 6 * Alpha[1] + 3) / 7;	// bit code 111
		}
		else
		{
			// 6-alpha block.
			// Bit code 000 = alpha_0, 001 = alpha_1, others are interpolated.
			Alpha[2] = (4 * Alpha[0] + 1 * Alpha[1] + 2) / 5;	// Bit code 010
			Alpha[3] = (3 * Alpha[0] + 2 * Alpha[1] + 2) / 5;	// Bit code 011
			Alpha[4] = (2 * Alpha[0] + 3 * Alpha[1] + 2) / 5;	// Bit code 100
			Alpha[5] = (1 * Alpha[0] + 4 * Alpha[1] + 2) / 5;	// Bit code 101
			Alpha[6] = 0;										// Bit code 110
			Alpha[7] = 255;										// Bit code 111
		}
		
		// Byte	Alpha
		// 0	Alpha_0
		// 1	Alpha_1 
		// 2	[0][2] (2 LSBs), [0][1], [0][0]
		// 3	[1][1] (1 LSB), [1][0], [0][3], [0][2] (1 MSB)
		// 4	[1][3], [1][2], [1][1] (2 MSBs)
		// 5	[2][2] (2 LSBs), [2][1], [2][0]
		// 6	[3][1] (1 LSB), [3][0], [2][3], [2][2] (1 MSB)
		// 7	[3][3], [3][2], [3][1] (2 MSBs)
		// [0
		
		// Read an int and a short
		unsigned int	tmpdword;
		unsigned short	tmpword;
		
		tmpword = bmpEndianSwap16((short)*(unsigned short *)&IData[i + 2]);
		tmpdword = bmpEndianSwap32((int)*(unsigned int *)&IData[i + 4]);

		AlphaDat = tmpword | bmpEndianSwap64((uint64_t)tmpdword << 16);
		
		unsigned int ChunkNum = i / 16;
		unsigned int XPos = ChunkNum % ChunksPerHLine;
		unsigned int YPos = (ChunkNum - XPos) / ChunksPerHLine;
		
		int		sizew, sizeh;

		sizeh = (Height < 4) ? Height : 4;
		sizew = (Width < 4) ? Width : 4;
		int x,y;
		for (x = 0; x < sizeh; x++)
		{
			for (y = 0; y < sizew; y++)
			{
				CColor = Color[CData & 0x03];
				CData >>= 2;

				CColor.a = Alpha[AlphaDat & 0x07];
				AlphaDat >>= 3;

				PData[(YPos*4+x)*Width + XPos*4+y] = rgba_to_int(CColor);
			}
		}
	}
}
@implementation BitmapTag
- (char)imageCount
{
	return header.image_count;
}

- (id)initWithFile:(NSFile *)file atOffset:(long)offset map:(HaloMap *)map
{
	if (self = [super init])
	{
		pathToMap = [file path];
	    long offsetInHeader;
    	long magic = [map indexHeader].magic;
    	offsetInHeader = offset;
    	[file seekToOffset:offset];
    	[file readIntoStruct:&myTag.classA size:12];
    	myTag.ident = [file readDword];
    	myTag.stringOffset = [file readDword];
    	myTag.offset = [file readDword];
    	[file skipBytes:8];
    	//header
		[file seekToOffset:myTag.stringOffset - magic];
		myName = [[file readCString] retain];
    	[file seekToOffset:myTag.offset - magic];
    	[file skipBytes:22*sizeof(long)];
    	header.offset_to_first=[file readDword];
    	header.unknown23=[file readDword];
    	header.image_count=[file readDword];
    	header.image_offset=[file readDword];
    	header.unknown25=[file readDword];
    	//let's do the images
    	images = malloc(header.image_count * sizeof(bitm_image_t));
    	[file seekToOffset:header.image_offset-magic];
    	int x;
    	for (x=0;x<header.image_count;x++)
    	{
    		bitm_image_t *tempImage = &images[x];
    		tempImage->id = [file readDword];
    		tempImage->width = [file readWord];
    		tempImage->height = [file readWord];
    		tempImage->depth = [file readWord];
    		tempImage->type = [file readWord];
    		tempImage->format = [file readWord];
    		tempImage->flags = [file readWord];
    		tempImage->reg_point_x = [file readWord];
    		tempImage->reg_point_y = [file readWord];
    		tempImage->num_mipmaps = [file readWord];
    		tempImage->pixel_offset = [file readWord];
    		tempImage->offset = [file readDword];
    		tempImage->size = [file readDword];
    		tempImage->unknown8 = [file readDword];
    		tempImage->unknown9 = [file readDword];
    		tempImage->unknown10 = [file readDword];
    		tempImage->unknown11 = [file readDword];
    	}
		[file seekToOffset:offsetInHeader+32];
	}
	return self;
}

- (unsigned int *)imagePixelsForImageIndex:(unsigned short)idx
{
	const char *inData;
	NSFile *bitmapsmap = [[NSFile alloc] initWithPathForReading:
				[NSString stringWithFormat:@"%@/%@",
					[pathToMap stringByDeletingLastPathComponent],
					@"bitmaps.map"]];
	[bitmapsmap seekToOffset:images[idx].offset];
	int lengthOfData = getImageSize(images[idx].format,images[idx].width,images[idx].height);
	inData = [[bitmapsmap readDataOfLength:lengthOfData] bytes];
	
	unsigned int *outData = malloc(1 * 4 * images[idx].width * images[idx].height);
	DecodeBitmSurface (inData, images[idx].width,images[idx].height,images[idx].depth, 
                                   images[idx].format,images[idx].flags, outData);
	bytes = outData;
	
	[bitmapsmap close];
	return outData;
}
- (void)freeImagePixels
{
	free(bytes);
}
- (NSString *)name
{
	return [[myName retain] autorelease];
}
- (NSSize)textureSizeForImageIndex:(unsigned short)idx
{
	return NSMakeSize( images[idx].width,images[idx].height );
}
@end
