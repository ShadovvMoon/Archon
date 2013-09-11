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
	
	int _textureCounter;
}
- (id)init;
- (id)initWithCapacity:(int)capacity;
- (void)setCapacity:(int)capacity;
- (void)dealloc;
- (void)addTexture:(BitmapTag *)bitm;
- (void)loadTextureOfIdent:(long)ident subImage:(int)index;
- (void)loadAlTextures;
- (void)deleteAllTextures;
- (void)deleteTextureOfTag:(long)ident;
- (void)activateTextureOfIdent:(long)ident subImage:(int)subImage useAlphas:(BOOL)useAlphas;
- (void)activateTextureAndLightmap:(long)ident lightmap:(long)lightmap subImage:(int)subImage;
@end
