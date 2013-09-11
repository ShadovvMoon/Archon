#import "TextureView.h"
#import "BitmapTag.h"
@implementation TextureView


- (void) reshape
{ 
   NSRect sceneBounds;
   

   sceneBounds = [ self bounds ];
   // Reset current viewport
   glViewport( 0, 0, sceneBounds.size.width, sceneBounds.size.height );
   glMatrixMode( GL_PROJECTION );   // Select the projection matrix
   glLoadIdentity();                // and reset it
   // Calculate the aspect ratio of the view
   gluPerspective( 45.0f, sceneBounds.size.width / sceneBounds.size.height,
                   0.1f, 100.0f );
   glMatrixMode( GL_MODELVIEW );    // Select the modelview matrix
   glLoadIdentity();                // and reset it
}
- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];

    [self reshape];
}


- (void)prepareOpenGL
{

	
            // Enable texture mapping
      glShadeModel( GL_SMOOTH );                // Enable smooth shading
	glClearColor( 0.0f, 0.0f, 0.0f, 0.5f );   // Black background
   glClearDepth( 1.0f );                     // Depth buffer setup
      glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
   glEnable( GL_DEPTH_TEST );                // Enable depth testing
   glDepthFunc( GL_LEQUAL );                 // Type of depth test to do
}
- (void)setBitmap:(BitmapTag *)tag withIndex:(char)idx
{
	currentTag = [[tag retain] autorelease];
	currentIndex = idx;
}
- (void)loadBitmap
{
	unsigned int *texData = [currentTag imagePixelsForImageIndex:currentIndex];
	glGenTextures( 1 , &texture[0] );
	glBindTexture( GL_TEXTURE_2D, texture[ 0 ] );
	glTexImage2D( GL_TEXTURE_2D, 0, 4, [currentTag textureSizeForImageIndex:currentIndex].width,
                    [currentTag textureSizeForImageIndex:currentIndex].height, 0, GL_RGBA,
                    GL_UNSIGNED_BYTE, texData );
	glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,
		GL_NEAREST);
	glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,
		GL_NEAREST);
		      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
	glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE, GL_DECAL);
	glEnable(GL_TEXTURE_2D);
}
- (void)drawRect:(NSRect)aRect
{
	[[self openGLContext] makeCurrentContext];
	   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
	   
		glLoadIdentity();   // Reset the current modelview matrix	
		//glBindTexture( GL_TEXTURE_2D , texture[0] );
		glTranslatef(0.0,0.0,-3.0);
		glBegin(GL_QUADS);
		
			glColor3f(0.0,0.0,0.0);
		glTexCoord2f(0.0,1.0); glVertex3f(-1.0,-1.0,0.0);
		glTexCoord2f(0.0,0.0); glVertex3f(-1.0,1.0,0.0);
		glTexCoord2f(1.0,0.0); glVertex3f(1.0,1.0,0.0);
		glTexCoord2f(1.0,1.0); glVertex3f(1.0,-1.0,0.0);
		glEnd();
		glFlush();
		

}

@end
