#import "ModelView.h"
#import "Geometry.h"
@implementation ModelView


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
                   0.1f, 10000.0f );
   glMatrixMode( GL_MODELVIEW );    // Select the modelview matrix
   glLoadIdentity();                // and reset it
}
- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];

    [self reshape];
}
- (void)setGeometry:(Geometry *)geo
{
	currentGeometry = [[geo retain] autorelease];
	xrot = 0.0f;
	yrot = 0.0f;
	zrot = 0.0f;
	oldxrot = 0.0f;
	oldyrot = 0.0f;
	oldzrot = 0.0f;
	oldxtrans = xtrans = oldytrans=ytrans =	oldztrans=ztrans = 0.0f;
	
}
-(void)awakeFromNib
{
	zoom = -1.0f;
	xrot = 0.0f;
	yrot = 0.0f;
	zrot = 0.0f;
	oldxrot = 0.0f;
	oldyrot = 0.0f;
	oldzrot = 0.0f;
	oldxtrans = xtrans = oldytrans=ytrans =	oldztrans=ztrans = 0.0f;	
	
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
   GLfloat LightPosition[4] = {2.0f,0.0f,-5.0f,1.0f};
   GLfloat LightDiffuse[4] = {1.0f,1.0f,1.0f,1.0f};
   GLfloat LightAmbient[4] = {0.5f,0.5f,0.5f,1.0f};
   GLfloat light0Specular[4] = {0.0f, 0.0f, 0.0f, 1.0f};
   GLfloat lightModelAmbient[4] = {0.0f,0.0f,0.0f,1.0f};
   GLfloat materialSpecular[4] = {0.0f, 0.0f, 0.0f, 0.0f};
   GLfloat materialEmission[4] = {0.0f, 0.0f, 0.0f, 0.0f};
   GLfloat materialAmbient[4] = {0.0f, 0.0f, 0.0f, 0.0f};
   GLfloat materialDiffuse[4] = {1.0f, 1.0f, 1.0f, 1.0f};
   glLightModelfv(GL_LIGHT_MODEL_AMBIENT, lightModelAmbient);
   glMaterialfv(GL_FRONT, GL_AMBIENT, materialAmbient);
   glMaterialfv(GL_FRONT, GL_DIFFUSE, materialDiffuse);
   glMaterialfv(GL_FRONT, GL_SPECULAR, materialSpecular);
   glMaterialfv(GL_FRONT, GL_EMISSION, materialEmission);
 
   glLightfv(GL_LIGHT1, GL_AMBIENT, LightAmbient); 
   glLightfv(GL_LIGHT1, GL_DIFFUSE, LightDiffuse);   
   glLightfv(GL_LIGHT1, GL_POSITION,LightPosition);   
   glLightfv(GL_LIGHT1, GL_SPECULAR, light0Specular);
   glEnable(GL_LIGHTING);
   glEnable(GL_LIGHT1); 

}

- (void)drawRect:(NSRect)aRect
{
		[[self openGLContext] makeCurrentContext];
	    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
	    glClearColor(0.0f,0.0f,0.0f,1.0f);
		glLoadIdentity();   // Reset the current modelview matrix	
		glTranslatef(0.0f,0.0f,zoom);
		glRotatef(xrot,0.0f,1.0f,0.0f);
		glRotatef(yrot,1.0f,0.0f,0.0f);
		glRotatef(zrot,0.0f,0.0f,1.0f);
		glTranslatef(xtrans,ytrans,ztrans);
		if (currentGeometry != nil)
			[currentGeometry drawIntoView:self x:0 y:0 z:0];

}
- (void)mouseDown:(NSEvent *)event
{
	downPoint = [NSEvent mouseLocation];
	if ([event modifierFlags] & NSCommandKeyMask)
		dragmode = 2;
	else if ([event modifierFlags] & NSAlternateKeyMask)
		dragmode = 3;
	else if ([event modifierFlags] & NSControlKeyMask)
		dragmode = 4;
	else
		dragmode = 1;
}
- (void)mouseUp:(NSEvent *)event
{
	oldxrot = xrot;
	oldyrot = yrot;
	oldzrot = zrot;
	
	oldxtrans=xtrans;
	oldytrans=ytrans;
	oldztrans=ztrans;
	dragmode=0;
}
- (void)mouseDragged:(NSEvent *)event
{
	if (dragmode == 1)
	{
		xrot = oldxrot + (0.5f * (float)([NSEvent mouseLocation].x - downPoint.x));
		yrot = oldyrot + (-1) * (0.5f * (float)([NSEvent mouseLocation].y - downPoint.y));
	}
	else if (dragmode == 2)
	{
		xtrans = oldxtrans + (0.003f * zoom * zoom * (float)([NSEvent mouseLocation].x - downPoint.x));
		ytrans = oldytrans + (0.003f * zoom * zoom * (float)([NSEvent mouseLocation].y - downPoint.y));
	}
	else if (dragmode == 3)
	{
		zrot = oldzrot + (0.5f * (float)([NSEvent mouseLocation].y - downPoint.y));
	}
	else if (dragmode == 4)
	{
		ztrans = oldztrans + (0.003f * zoom * zoom * (float)([NSEvent mouseLocation].y - downPoint.y));
	}
	[self setNeedsDisplay:YES];
}
- (void)increaseZoom:(float)inc
{
	zoom += inc;
	[self setNeedsDisplay:YES];
}
- (void)scrollWheel:(NSEvent *)theEvent
{
	[self increaseZoom:(float)[theEvent deltaY] * 0.04f];
}

@end
