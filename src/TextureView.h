/* ModelView */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
@class BitmapTag;

@interface TextureView : NSOpenGLView
{
	BitmapTag *currentTag;
	GLuint texture[1];
	char currentIndex;
}

- (void)setFrameSize:(NSSize)newSize;
- (void)reshape;

- (void)prepareOpenGL;
- (void)drawRect:(NSRect)aRect;
- (void)loadBitmap;
- (void)setBitmap:(BitmapTag *)tag withIndex:(char)idx;
@end
