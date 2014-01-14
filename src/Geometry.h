//
//  Geometry.h
//  swordedit
//
//  Created by Fred Havemeyer on 5/11/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "defines.h"

@class HaloMap;
@class ModelTag;
@class TextureManager;

@interface Geometry : NSObject {
	int numParts;
	int vertexSize;
	int vertexOffset;
	
	GLuint *textures;
    
	HaloMap *_mapfile;
	ModelTag *parent;
	
	TextureManager *_texManager;
	
	reflexive partsref;
    int *base_indicies;
    int *detail_indicies;
	part *parts;
	geometry me;
	
    BOOL drawingSetup;
    BOOL doneSetup;
    
    GLuint cubeVBO;
	GLuint cubeIBO;
    
    int indexCount_R;
    
    GLuint geometryList;
    GLfloat* normals;
    GLfloat* vertex_array;
    GLshort* index_array;
    GLfloat* texture_uv;
    
    GLuint geometryVAO;
    GLuint m_Buffers[4];
    
    GLuint vertexVBO;
    GLuint indexVBO;
    GLuint normalVBO;
    GLuint textureVBO;
    
    GLuint *vbo_vertices;
    GLuint *vbo_indicies;
    
	BOOL texturesLoaded;
}
- (id)initWithMap:(HaloMap *)map parent:(ModelTag *)mTag;
- (void)dealloc;
- (void)destroy;
- (void)loadBitmaps;
- (BOUNDING_BOX)determineBoundingBox;
- (void)drawIntoView:(BOOL)useAlphas;
@property int numParts;
@property int vertexSize;
@property int vertexOffset;
@property GLuint *textures;
@property (retain) HaloMap *_mapfile;
@property (retain) ModelTag *parent;
@property (retain) TextureManager *_texManager;
@property part *parts;
@property BOOL texturesLoaded;
@end
