/* ModelView */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
@class Geometry;
@interface ModelView : NSOpenGLView
{
	Geometry *currentGeometry;
	char submodel;
	float zoom;
	float xrot,yrot,zrot;
	NSPoint downPoint;
	float oldxrot,oldyrot,oldzrot;
	float xtrans,ytrans,ztrans;
	float oldxtrans,oldytrans,oldztrans;
	char dragmode;
}

- (void)setFrameSize:(NSSize)newSize;
- (void)reshape;
- (void)setGeometry:(Geometry *)geo;
- (void)prepareOpenGL;
- (void)drawRect:(NSRect)aRect;
- (void)awakeFromNib;
- (void)scrollWheel:(NSEvent *)theEvent;

- (void)increaseZoom:(float)inc;
@end
