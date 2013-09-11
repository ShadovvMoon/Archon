//
//  TextureManager.m
//  swordedit
//
//  Created by Fred Havemeyer on 6/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TextureManager.h"
#import "Bitmaptag.h"

#include <OpenGL/glext.h>

@implementation TextureManager
- (id)init
{
	if ((self = [super init]) != nil)
	{
		_textureCounter = 0;
	}
	return self;
}
- (id)initWithCapacity:(int)capacity
{
	if ((self = [super init]) != nil)
	{
		_textures = [[NSMutableArray alloc] initWithCapacity:capacity];
		_textureLookupByID = [[NSMutableDictionary alloc] initWithCapacity:capacity];
		
		/*
			_glTextureTable [tex index]	[0]
										[1]
										[2]
										[n]
		*/
		
		_textureCounter = 0;
	}
	return self;
}
- (void)setCapacity:(int)capacity
{
	_textures = [[NSMutableArray alloc] initWithCapacity:capacity];
	_textureLookupByID = [[NSMutableDictionary alloc] initWithCapacity:capacity];

	_glTextureTable = (GLuint **)malloc(sizeof(unsigned int) * capacity);
}
- (void)dealloc
{
	NSLog(@"Texture manager deallocing!");
	int i;
	
	for (i = 0; i < [_textures count]; i++)
		free(_glTextureTable[i]);
	free(_glTextureTable);

	[_textures removeAllObjects];
	[_textureLookupByID removeAllObjects];
	
	[_textures release];
	[_textureLookupByID release];
	
	[super dealloc];
}
- (void)addTexture:(BitmapTag *)bitm
{
	[_textures addObject:bitm];
	[_textureLookupByID setObject:[NSNumber numberWithInt:_textureCounter] forKey:[NSNumber numberWithLong:[bitm idOfTag]]];
	
	// Now we upload the texture to opengl
	_glTextureTable[ _textureCounter ] = (GLuint *)malloc(sizeof(GLuint) * [bitm imageCount]);
	
	_textureCounter++;
}
- (void)loadTextureOfIdent:(long)ident subImage:(int)index
{
	
	if (!_textures)
		return;
		
	int texIndex = [[_textureLookupByID objectForKey:[NSNumber numberWithLong:ident]] intValue];
		
	//NSLog(@"Ident: 0x%x and index: %d", ident, texIndex);
		
	BitmapTag *tmpBitm = [[_textures objectAtIndex:texIndex] retain];
	
	if (![tmpBitm imageAlreadyLoaded:index])
	{
		[tmpBitm loadImage:index];
		int col = [[[NSApplication sharedApplication] delegate] usesColor];

		// Now lets upload it to OpenGL
		glGenTextures(1,&_glTextureTable[texIndex][index]);
		glBindTexture(GL_TEXTURE_2D,_glTextureTable[texIndex][index]);
		glTexImage2D(GL_TEXTURE_2D,
					0,
					col,
					[tmpBitm textureSizeForImageIndex:index].width,
					[tmpBitm textureSizeForImageIndex:index].height,
					0,
					GL_RGBA,
					GL_UNSIGNED_BYTE,
					[tmpBitm imagePixelsForImageIndex:index]);
	}
	
	[tmpBitm release];
}

/* Yeah, don't use this one. It'll take fucking forever. */
- (void)loadAlTextures
{
	if (!_textures)
		return;
	
	int i, x;
	BitmapTag *tmpBitm;
	for (i = 0; i < [_textures count]; i++)
	{
		tmpBitm = [[_textures objectAtIndex:i] retain];
		for (x = 0; x < [tmpBitm imageCount]; x++)
		{
			if (![tmpBitm imageAlreadyLoaded:x])
				[tmpBitm loadImage:x];
		}
		[tmpBitm release];
	}
}

- (void)deleteAllTextures
{
	int i, x;
	BitmapTag *tmpBitm;
	
	for (i = 0; i < [_textures count]; i++)
	{
		tmpBitm = [[_textures objectAtIndex:i] retain];
		for (x = 0; x < [tmpBitm imageCount]; x++)
		{
			if ([tmpBitm imageAlreadyLoaded:x])
				glDeleteTextures(1,&_glTextureTable[i][x]);
		}
		[tmpBitm release];
	}
}
- (void)deleteTextureOfTag:(long)ident
{
	int texIndex = [[_textureLookupByID objectForKey:[NSNumber numberWithLong:ident]] intValue];
	BitmapTag *tmpBitm = [[_textures objectAtIndex:texIndex] retain];
	int i;
	
	for (i = 0; i < [tmpBitm imageCount]; i++)
	{
		if ([tmpBitm imageAlreadyLoaded:i])
			glDeleteTextures(1,&_glTextureTable[texIndex][i]);
	}
	[tmpBitm release];
}
/* Ok, here comes the fun part. */
- (void)activateTextureOfIdent:(long)ident subImage:(int)subImage useAlphas:(BOOL)useAlphas
{
	if (!_textures)
		return;
		
	int texIndex = [[_textureLookupByID objectForKey:[NSNumber numberWithLong:ident]] intValue];
		
	BitmapTag *tmpBitm = [[_textures objectAtIndex:texIndex] retain];
	
	if (![tmpBitm imageAlreadyLoaded:subImage])
		return;
	
	glEnable(GL_TEXTURE_2D);
	
	// This will be outdated as soon as I implement per-texture type alpha rendering
	if (useAlphas)
	{
		glEnable(GL_BLEND);
		glBlendFunc(GL_DST_ALPHA,GL_ONE_MINUS_DST_ALPHA);
		glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
	}
	
	glBindTexture(GL_TEXTURE_2D,_glTextureTable[texIndex][subImage]);
	glBindTexture(GL_TEXTURE_2D,_glTextureTable[texIndex][subImage]);
				
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT);
	glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
	
	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	
	[tmpBitm release];
}
- (void)activateTextureAndLightmap:(long)ident lightmap:(long)lightmap subImage:(int)subImage
{
	if (!_textures)
		return;
		
	int texIndex = [[_textureLookupByID objectForKey:[NSNumber numberWithLong:ident]] intValue],
		lightmapIndex = [[_textureLookupByID objectForKey:[NSNumber numberWithLong:lightmap]] intValue];
	BitmapTag	*mapBitmap = [[_textures objectAtIndex:texIndex] retain],
				*lightmapBitmap = [[_textures objectAtIndex:lightmapIndex] retain];
				
	glActiveTextureARB(GL_TEXTURE0_ARB);
	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D,_glTextureTable[texIndex][subImage]);
	
	glActiveTextureARB(GL_TEXTURE1_ARB);
	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, _glTextureTable[lightmapIndex][1]);
	
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT);
	glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
				
	[mapBitmap release];
	[lightmapBitmap release];
}
@end
