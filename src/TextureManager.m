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
    _glTextureTable_Alphas = (GLuint **)malloc(sizeof(unsigned int) * capacity);
    _glTextureTable_Compiled = (GLuint **)malloc(sizeof(unsigned int) * capacity);
}
- (void)dealloc
{
	NSLog(@"Texture manager deallocing!");
	int i;
	
	for (i = 0; i < [_textures count]; i++)
    {
		free(_glTextureTable_Alphas[i]);
        free(_glTextureTable_Compiled[i]);
        free(_glTextureTable[i]);
    }
	free(_glTextureTable);
    free(_glTextureTable_Alphas);
    free(_glTextureTable_Compiled);
    
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
	_glTextureTable_Alphas[ _textureCounter ] = (GLuint *)malloc(sizeof(GLuint) * [bitm imageCount]);
	_glTextureTable_Compiled[ _textureCounter ] = (GLuint *)malloc(sizeof(GLuint) * 1);
	
	_textureCounter++;
}


- (void)exportTextureOfIdent:(long)ident subImage:(int)index
{

    
    if (!_textures)
		return;
    
	int texIndex = [[_textureLookupByID objectForKey:[NSNumber numberWithLong:ident]] intValue];
    
	//NSLog(@"Ident: 0x%x and index: %d", ident, texIndex);
    
	BitmapTag *tmpBitm = [[_textures objectAtIndex:texIndex] retain];
    [tmpBitm writeImageToMap:index withBytes:[tmpBitm imagePixelsForImageIndex:index]];
    

	//if (![tmpBitm imageAlreadyLoaded:index])
	//{
		//[tmpBitm loadImage:index];

        if (FALSE)//useNewRenderer() >= 2)
		{
            NSSize size = NSMakeSize([tmpBitm textureSizeForImageIndex:index].width, [tmpBitm textureSizeForImageIndex:index].height);
            NSImage *renderImage = [[NSImage alloc] initWithSize:size];
            
            unsigned int *pixels = [tmpBitm imagePixelsForImageIndex:index];
            
            if (!pixels || size.width == 0 || size.height == 0)
                return;
            
            NSBitmapImageRep *imgRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&pixels
                                                    pixelsWide:size.width
                                                    pixelsHigh:size.height
                                                 bitsPerSample:8
                                               samplesPerPixel:4
                                                      hasAlpha:true
                                                      isPlanar:false
                                                colorSpaceName:NSDeviceRGBColorSpace

                                                   bytesPerRow:0
                                                  bitsPerPixel:0];
            
            NSBitmapImageRep *new_bitmap = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL
                                                                                    pixelsWide: size.width
                                                                                    pixelsHigh: size.height
                                                                                 bitsPerSample: 8
                                                                               samplesPerPixel: 4
                                                                                      hasAlpha: YES
                                                                                      isPlanar: NO
                                                                                colorSpaceName: NSCalibratedRGBColorSpace
                                                                                   bytesPerRow: 0
                                                                                  bitsPerPixel: 0] autorelease];
            NSBitmapImageRep *new_bitmap2 = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL
                                                                                    pixelsWide: size.width
                                                                                    pixelsHigh: size.height
                                                                                 bitsPerSample: 8
                                                                               samplesPerPixel: 4
                                                                                      hasAlpha: YES
                                                                                      isPlanar: NO
                                                                                colorSpaceName: NSCalibratedRGBColorSpace
                                                                                   bytesPerRow: 0
                                                                                  bitsPerPixel: 0] autorelease];
            
            unsigned char *newbytes = (unsigned char *)[new_bitmap bitmapData];
            unsigned char *newbytes2 = (unsigned char *)[new_bitmap2 bitmapData];
            
            unsigned char *from = [imgRep bitmapData];
            
            
            int j = 0;
            int i;
            
            for (i = 0; i < size.width * size.height * 4; i += 4) {
                unsigned char r, g, b, a;
                r = *(from + i+0);
                g = *(from + i+1);
                b = *(from + i+2);
                a = *(from + i + 3);
                
              
                *(newbytes + j + 0) = r;
                *(newbytes + j + 1) = g;
                *(newbytes + j + 2) = b;
                *(newbytes + j + 3) = 255;
    
                j += 4;
            }
            
            for (i = 0; i < size.width * size.height * 4; i += 4) {
                unsigned char r, g, b, a;
                r = *(from + i+0);
                g = *(from + i+1);
                b = *(from + i+2);
                a = *(from + i + 3);
                
                
                *(newbytes2 + i + 0) = a;
                *(newbytes2 + i + 1) = a;
                *(newbytes2 + i + 2) = a;
                *(newbytes2 + i + 3) = 255;
                
                j += 4;
            }
            
            [renderImage addRepresentation:new_bitmap2];
            NSImage *newImage = [[NSImage alloc] initWithSize:NSMakeSize(size.width,size.height)];
            [newImage lockFocus];
            [new_bitmap draw];
            [newImage unlockFocus];
            
            [[NSFileManager defaultManager] createDirectoryAtPath:@"/tmp/swordedit" attributes:nil];
            
            NSData *data = [newImage TIFFRepresentation];
            
            NSString *output = [NSString stringWithFormat:@"/tmp/swordedit/%@_original_%d.tiff", [tmpBitm tagName],index];
            [data writeToFile:output atomically: YES];
    
            
            
           
            NSString *file = [NSString stringWithFormat:@"/tmp/swordedit/%@_alpha_%d.tiff", [tmpBitm tagName],index];
            if (![[NSFileManager defaultManager] fileExistsAtPath:file isDirectory:NO])
            {
                //Write the texture images to the desktop
                [[renderImage TIFFRepresentation] writeToFile:file atomically:YES];

            }
            
                    }
    //}
    return;

}

- (void)loadTextureOfIdent:(long)ident subImage:(int)index
{
    [self loadTextureOfIdent:ident subImage:index removeAlpha:NO];
}

-(BitmapTag*)bitmapForIdent:(long)ident
{
    if (!_textures)
		return nil;
    
	int texIndex = [[_textureLookupByID objectForKey:[NSNumber numberWithLong:ident]] intValue];
    
	//NSLog(@"Ident: 0x%x and index: %d", ident, texIndex);
    
	BitmapTag *tmpBitm = [[_textures objectAtIndex:texIndex] retain];
    return tmpBitm;
}

-(int)createTextureWithData:(unsigned char *)data withSize:(NSSize)sze
{
    NSLog(@"Creating a new texture at %d", lastShaderIndex);
    lastShaderIndex+=1;
    
    //Whats the last index we used
    glGenTextures(1,&_glTextureTable_Compiled[lastShaderIndex][0]);
    glBindTexture(GL_TEXTURE_2D,_glTextureTable_Compiled[lastShaderIndex][0]);
    
    //if (data !=  NULL)
    //{
        gluBuild2DMipmaps(GL_TEXTURE_2D,
                      GL_RGBA,
                      sze.width,
                      sze.height,
                      GL_RGBA,
                      GL_UNSIGNED_BYTE,
                      data);
    //}
    
    
    return lastShaderIndex;
}

- (void)loadTextureOfIdent:(long)ident subImage:(int)index removeAlpha:(BOOL)ra
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
   
        unsigned char *imageData = [tmpBitm imagePixelsForImageIndex:index];
        if (ra)
        {
            NSSize size = [tmpBitm textureSizeForImageIndex:index];
            unsigned char *newData = malloc(size.width * size.height * 4);
            
            //Make white.
            int i;
            for (i = 0; i < size.width * size.height * 4; i += 4) {
                unsigned char a;
                a = *(imageData + i+3);
                *(newData + i+0) = *(imageData + i+0);
                *(newData + i+1) = *(imageData + i+1);
                *(newData + i+2) = *(imageData + i+2);
                
                //If black, alpha
                *(newData + i+3)= ((*(imageData + i+0))+(*(imageData + i+1))+(*(imageData + i+2)))/3;
            }
            imageData = newData;
        }
        
        if (imageData !=  NULL)
        {
            gluBuild2DMipmaps(GL_TEXTURE_2D,
                                  GL_RGBA,
                                   [tmpBitm textureSizeForImageIndex:index].width,
                                   [tmpBitm textureSizeForImageIndex:index].height,
                                   GL_RGBA,
                                   GL_UNSIGNED_BYTE,
                                   imageData);
            
        }
       
     

        //Create the equivalent alpha image
        glGenTextures(1,&_glTextureTable_Alphas[texIndex][index]);
        glBindTexture(GL_TEXTURE_2D,_glTextureTable_Alphas[texIndex][index]);
        
        NSSize size = [tmpBitm textureSizeForImageIndex:index];
        unsigned char *newData = malloc(size.width * size.height * 4);
        *newData = *imageData;
        
        //Make white.
        int i;
        for (i = 0; i < size.width * size.height * 4; i += 4) {
            unsigned char a;
            a = *(imageData + i+3);
            *(newData + i+0)=255;
            *(newData + i+1)=255;
            *(newData + i+2)=255;
            *(newData + i+3)=a;
        }
        
        
        if (newData !=  NULL)
        {
            gluBuild2DMipmaps(GL_TEXTURE_2D,
                              GL_RGBA,
                              [tmpBitm textureSizeForImageIndex:index].width,
                              [tmpBitm textureSizeForImageIndex:index].height,
                              GL_RGBA,
                              GL_UNSIGNED_BYTE,
                              newData);
            
        }
        
        free(newData);
        
        
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
            {
				glDeleteTextures(1,&_glTextureTable[i][x]);
                glDeleteTextures(1,&_glTextureTable_Alphas[i][x]);
                glDeleteTextures(1, &_glTextureTable_Compiled[i][x]);
            }
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
        {
			glDeleteTextures(1,&_glTextureTable[texIndex][i]);
            glDeleteTextures(1,&_glTextureTable_Alphas[texIndex][i]);
            glDeleteTextures(1, &_glTextureTable_Compiled[texIndex][i]);
        }
	}
	[tmpBitm release];
}

-(NSString*)nameForImage:(long)ident
{
    if (!_textures)
		return @"";
    
    int texIndex = [[_textureLookupByID objectForKey:[NSNumber numberWithLong:ident]] intValue];
	BitmapTag *tmpBitm = [_textures objectAtIndex:texIndex];
    return [tmpBitm tagName];
}

-(BitmapTag*)updateBitmapDataWithIdent:(long)ident data:(unsigned char*)dat index:(int)index
{
    if (!_textures)
		return nil;
    
    int texIndex = [[_textureLookupByID objectForKey:[NSNumber numberWithLong:ident]] intValue];
    BitmapTag *temp = [_textures objectAtIndex:texIndex];
    [temp setImagePixelsForImageIndex:index withBytes:(unsigned int*)dat];
    [_textures replaceObjectAtIndex:texIndex withObject:temp];
}


-(BitmapTag*)bitmapWithIdent:(long)ident
{
    if (!_textures)
		return nil;
    
    int texIndex = [[_textureLookupByID objectForKey:[NSNumber numberWithLong:ident]] intValue];
    return [_textures objectAtIndex:texIndex];
}

- (void)refreshTextureOfIdent:(long)ident
{
    [self refreshTextureOfIdent:ident index:0];
}

/* Ok, here comes the fun part. */
- (void)refreshTextureOfIdent:(long)ident index:(int)index
{
	if (!_textures)
		return;
    
    int texIndex = [[_textureLookupByID objectForKey:[NSNumber numberWithLong:ident]] intValue];
	BitmapTag *tmpBitm = [[_textures objectAtIndex:texIndex] retain];
    
    [tmpBitm changed];
    
    //Delete texture
    if( &_glTextureTable[texIndex][index] != 0 )
    {
        glDeleteTextures( 1, &_glTextureTable[texIndex][index] );
        glDeleteTextures( 1, &_glTextureTable_Alphas[texIndex][index] );
        //glDeleteTextures( 1, &_glTextureTable_Compiled[texIndex][index] );
    }
    
    // Now lets upload it to OpenGL
    glGenTextures(1,&_glTextureTable[texIndex][index]);
    glBindTexture(GL_TEXTURE_2D,_glTextureTable[texIndex][index]);
        
    if ([tmpBitm imagePixelsForImageIndex:index] !=  NULL)
    {
        gluBuild2DMipmaps(GL_TEXTURE_2D,
                          GL_RGBA,
                          [tmpBitm textureSizeForImageIndex:index].width,
                          [tmpBitm textureSizeForImageIndex:index].height,
                          GL_RGBA,
                          GL_UNSIGNED_BYTE,
                          [tmpBitm imagePixelsForImageIndex:index]);
    }
   
    // Now lets upload it to OpenGL
    glGenTextures(1,&_glTextureTable_Alphas[texIndex][index]);
    glBindTexture(GL_TEXTURE_2D,_glTextureTable_Alphas[texIndex][index]);
    
    if ([tmpBitm imagePixelsForImageIndex:index] !=  NULL)
    {
        gluBuild2DMipmaps(GL_TEXTURE_2D,
                          GL_RGBA,
                          [tmpBitm textureSizeForImageIndex:index].width,
                          [tmpBitm textureSizeForImageIndex:index].height,
                          GL_RGBA,
                          GL_UNSIGNED_BYTE,
                          [tmpBitm imagePixelsForImageIndex:index]);
    }
    
	
	[tmpBitm release];
}


/* Ok, here comes the fun part. */
- (void)refreshTextureOfIdentOld:(long)ident
{
    
	if (!_textures)
		return;
    
    int texIndex = [[_textureLookupByID objectForKey:[NSNumber numberWithLong:ident]] intValue];
	BitmapTag *tmpBitm = [[_textures objectAtIndex:texIndex] retain];
	//imagePixelsForImageIndex
    NSString *file = [NSString stringWithFormat:@"%@/Desktop/Images/%@_original.tiff", NSHomeDirectory(), [tmpBitm tagName]];
    NSString *alphaim = [NSString stringWithFormat:@"%@/Desktop/Images/%@_alpha.tiff", NSHomeDirectory(), [tmpBitm tagName]];
    //NSImage *image = [[NSImage alloc] initWithContentsOfFile:file];
    
    NSRect bigRect;
    NSBitmapImageRep *upsideDown, *_imageRep, *alpha;
    int bytesPerRow, bitsPerPixel, height, hasAlpha, i;
    unsigned char *from, *to, *ald;
    
    bigRect.origin = NSZeroPoint;
    
    /*[image setBackgroundColor:[NSColor clearColor]];
    [image lockFocus];
    upsideDown = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, image.size.width, image.size.height)];
    [image unlockFocus];*/
    
    upsideDown = [[NSBitmapImageRep imageRepWithContentsOfFile:file] retain];
    alpha = [[NSBitmapImageRep imageRepWithContentsOfFile:alphaim] retain];
    bigRect.size = [upsideDown size];

    
    from = [upsideDown bitmapData];
    ald = [alpha bitmapData];
    [upsideDown release];
    [alpha release];
    
    int j;
    int cell_width = [upsideDown pixelsWide];
    int cell_height = [upsideDown pixelsHigh];
    
    NSBitmapImageRep *new_bitmap = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL
                                                                            pixelsWide: cell_width
                                                                            pixelsHigh: cell_height
                                                                         bitsPerSample: 8
                                                                       samplesPerPixel: 4
                                                                              hasAlpha: YES
                                                                              isPlanar: NO
                                                                        colorSpaceName: NSCalibratedRGBColorSpace
                                                                           bytesPerRow: 0
                                                                          bitsPerPixel: 0] autorelease];
    unsigned char *newbytes = (unsigned char *)[new_bitmap bitmapData];
    
    j = 0;
    for (i = 0; i < cell_width * cell_height * 4; i += 4) {
        unsigned char r, g, b, a;
        r = *(from + i+0);
        g = *(from + i+1);
        b = *(from + i+2);
        a = *(ald  + i);
        
     
        *(newbytes + j + 0) = r;
        *(newbytes + j + 1) = g;
        *(newbytes + j + 2) = b;
        *(newbytes + j + 3) = a;
        
        
        j += 4;
    }
    /*
    NSImage *newImage = [[NSImage alloc] initWithSize:NSMakeSize(cell_width,cell_height)];
    [newImage lockFocus];
    [new_bitmap draw];
    [newImage unlockFocus];
    
    NSData *data = [newImage TIFFRepresentation];
    
    NSString *output = [NSString stringWithFormat:@"%@/Desktop/Images/%@.tiff", NSHomeDirectory(), @"Out"];
    [data writeToFile:output atomically: YES];
    */
    
    
    [tmpBitm setImagePixelsForImageIndex:0 withBytes:from];
    [_textures replaceObjectAtIndex:texIndex withObject:tmpBitm];
    // create the texture
    
    //Delete texture
    if( &_glTextureTable[texIndex][texIndex] != 0 )
    {
        glDeleteTextures( 1, &_glTextureTable[texIndex][texIndex] );
        //glDeleteTextures( 1, &_glTextureTable_Alphas[texIndex][texIndex] );
    }
    
    
    
    

        glGenTextures(1,&_glTextureTable[texIndex][texIndex]);
        glBindTexture(GL_TEXTURE_2D,_glTextureTable[texIndex][0]);
    
    
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        glPixelStorei(GL_UNPACK_ROW_LENGTH, bytesPerRow / (bitsPerPixel >> 3));

    
        gluBuild2DMipmaps(GL_TEXTURE_2D,
                     GL_RGBA,
                     bigRect.size.width,
                     bigRect.size.height,
                     GL_RGBA,
                     GL_UNSIGNED_BYTE,
                     newbytes);
    
    //Unbind texture
    glBindTexture( GL_TEXTURE_2D, NULL );

    
    //glEnable(GL_ALPHA);
    
}

/* Ok, here comes the fun part. */
- (void)blendTextureOfIdent:(long)ident subImage:(int)subImage useAlphas:(BOOL)useAlphas
{
	if (!_textures)
		return;
    
	int texIndex = [[_textureLookupByID objectForKey:[NSNumber numberWithLong:ident]] intValue];
    
	BitmapTag *tmpBitm = [[_textures objectAtIndex:texIndex] retain];
	
	if (![tmpBitm imageAlreadyLoaded:subImage])
		return;
    
    //Remove alphas!
    unsigned char *pixels = [tmpBitm imagePixelsForImageIndex:subImage];
    if (pixels)
    {
    NSSize size = NSMakeSize([tmpBitm textureSizeForImageIndex:subImage].width, [tmpBitm textureSizeForImageIndex:subImage].height);
    long as;
    for (as = 0; as < size.width * size.height * 4; as += 4)
    {
        
        *(pixels + as + 3) = ((255-*(pixels + as + 0))+(255-*(pixels + as + 1))+(255-*(pixels + as + 2)))/3;
    }
    
    //Delete texture
    if( &_glTextureTable[texIndex][subImage] != 0 )
    {
        glDeleteTextures( 1, &_glTextureTable[texIndex][subImage] );
        glDeleteTextures( 1, &_glTextureTable_Alphas[texIndex][subImage] );
    }
    // Now lets upload it to OpenGL
    glGenTextures(1,&_glTextureTable[texIndex][subImage]);
    glBindTexture(GL_TEXTURE_2D,_glTextureTable[texIndex][subImage]);
    
    if ([tmpBitm imagePixelsForImageIndex:subImage] !=  NULL)
    {
        gluBuild2DMipmaps(GL_TEXTURE_2D,
                          GL_RGBA,
                          [tmpBitm textureSizeForImageIndex:subImage].width,
                          [tmpBitm textureSizeForImageIndex:subImage].height,
                          GL_RGBA,
                          GL_UNSIGNED_BYTE,
                          pixels);
    }
   
    
    // Now lets upload it to OpenGL
    glGenTextures(1,&_glTextureTable_Alphas[texIndex][subImage]);
    glBindTexture(GL_TEXTURE_2D,_glTextureTable_Alphas[texIndex][subImage]);
    
    if ([tmpBitm imagePixelsForImageIndex:subImage] !=  NULL)
    {
        gluBuild2DMipmaps(GL_TEXTURE_2D,
                          GL_RGBA,
                          [tmpBitm textureSizeForImageIndex:subImage].width,
                          [tmpBitm textureSizeForImageIndex:subImage].height,
                          GL_RGBA,
                          GL_UNSIGNED_BYTE,
                          pixels);
    }
    

    }
    
    
	glEnable(GL_TEXTURE_2D);
	
	// This will be outdated as soon as I implement per-texture type alpha rendering
	if (YES)
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
	//glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
	glTexEnvf(GL_TEXTURE_ENV, GL_BLEND, GL_MODULATE);
	
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
	//glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
	glTexEnvf(GL_TEXTURE_ENV, GL_BLEND, GL_MODULATE);
	
	[tmpBitm release];
}

- (void)activateShader:(soso)shader
{
    
}


- (void)activateTextureAndLightmap:(long)ident lightmap:(long)lightmap secondary:(long)secondary subImage:(int)subImage
{
    [self activateTextureAndLightmap:ident lightmap:lightmap secondary:secondary subImage:subImage isAlphaType:NO];
}

- (void)activateTextureAndLightmap:(long)ident lightmap:(long)lightmap secondary:(long)secondary subImage:(int)subImage isAlphaType:(BOOL)iat
{
	if (!_textures)
		return;
		
	int texIndex = [[_textureLookupByID objectForKey:[NSNumber numberWithLong:ident]] intValue],
		lightmapIndex = [[_textureLookupByID objectForKey:[NSNumber numberWithLong:lightmap]] intValue],
        secondaryIndex = [[_textureLookupByID objectForKey:[NSNumber numberWithLong:secondary]] intValue];
    
	BitmapTag	*mapBitmap = [[_textures objectAtIndex:texIndex] retain],
				*lightmapBitmap = [[_textures objectAtIndex:lightmapIndex] retain];
		

if (useNewRenderer() != 1)
{
    if (lightmapIndex)
    {
        
        glActiveTextureARB(GL_TEXTURE1_ARB);
        glEnable(GL_TEXTURE_2D);
        
        if (iat)
            glBindTexture(GL_TEXTURE_2D, _glTextureTable_Alphas[lightmapIndex][0]);
        else
            glBindTexture(GL_TEXTURE_2D, _glTextureTable[lightmapIndex][0]);
        
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT);
        glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_LINEAR);
        glTexEnvi( GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_ADD );
        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE); 
    }
    
    
    glActiveTextureARB(GL_TEXTURE0_ARB);
    glEnable(GL_TEXTURE_2D);
    if (iat)
        glBindTexture(GL_TEXTURE_2D, _glTextureTable_Alphas[texIndex][0]);
    else
        glBindTexture(GL_TEXTURE_2D, _glTextureTable[texIndex][0]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT);
	glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_LINEAR);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
    
   
    if (secondaryIndex)
    {
        glActiveTextureARB(GL_TEXTURE2_ARB);
        glEnable(GL_TEXTURE_2D);
        glBindTexture(GL_TEXTURE_2D, _glTextureTable[secondaryIndex][subImage]);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT);
        glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_LINEAR);
        glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
    }
}
    else
    {
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, _glTextureTable[texIndex][0]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT);
	glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_LINEAR);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
    }
    
	[mapBitmap release];
	[lightmapBitmap release];
}
@synthesize _textures;
@synthesize _textureLookupByID;
@synthesize _glTextureNameLookup;
@synthesize _glTextureNames;
@synthesize _glTextureTable;
@synthesize _glTextureTable_Alphas;
@synthesize _glTextureTable_Compiled;
@synthesize _textureCounter;
@end
