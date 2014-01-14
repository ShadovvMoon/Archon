//
//  TextureManager.h
//  swordedit
//
//  Created by Fred Havemeyer on 6/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>

@class BitmapTag;

@interface TextureManager : NSObject {
	NSMutableArray *_textures;
	NSMutableDictionary *_textureLookupByID;
	unsigned int *_glTextureNameLookup;
	GLuint *_glTextureNames;
	
	GLuint **_glTextureTable;
    GLuint **_glTextureTable_Alphas;
	GLuint **_glTextureTable_Compiled;
    
	int _textureCounter;
    int lastShaderIndex;
}
    -(NSMutableDictionary*)_textureLookupByID;
-(BitmapTag*)bitmapForIdent:(int32_t)ident;
- (id)init;
- (id)initWithCapacity:(int)capacity;
- (void)setCapacity:(int)capacity;
- (void)dealloc;
- (void)addTexture:(BitmapTag *)bitm;
- (void)loadTextureOfIdent:(int32_t)ident subImage:(int)index;
- (void)loadAlTextures;
- (void)deleteAllTextures;
- (void)deleteTextureOfTag:(int32_t)ident;
- (void)activateTextureOfIdent:(int32_t)ident subImage:(int)subImage useAlphas:(BOOL)useAlphas;
- (void)activateTextureAndLightmap:(int32_t)ident lightmap:(int32_t)lightmap subImage:(int)subImage;
@property (retain) NSMutableArray *_textures;
@property unsigned int *_glTextureNameLookup;
@property GLuint *_glTextureNames;
@property GLuint **_glTextureTable;
@property GLuint **_glTextureTable_Alphas;
@property GLuint **_glTextureTable_Compiled;
@property int _textureCounter;
@end
