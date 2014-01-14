#import "Camera.h"
#import "VectorMath.h"

@implementation Camera
- (id)init
{

	if (self = [super init])
	{
	CVector3 vZero = NewCVector3(0.0, 0.0, 0.0);		// Init a vVector to 0 0 0 for our position
	CVector3 vView = NewCVector3(0.0, 0.0, -0.5);		// Init a starting view vVector (looking up and out the screen) 
	CVector3 vUp   = NewCVector3(0.0, 0.0, 1.0);		// Init a standard up vVector (Rarely ever changes)

	m_vPosition	= vZero;					// Init the position to zero
	m_vView		= vView;					// Init the view to a std starting view
        
	m_vUpVector	= vUp;						// Init the UpVector

	m_Speed = 0.1f;
	}
	return self;
}
- (void) HandleMouseMove:(float)dx dy:(float)dy
{
	float angleY = 0.0f;							// This is the direction for looking up or down
	float angleZ = 0.0f;							// This will be the value we need to rotate around the Y axis (Left and Right)
	static float currentRotX = 0.0f;

  

// Get the direction the mouse moved in, but bring the number down to a reasonable amount
	angleY = (float)( (dx) ) / 200.0;		
	angleZ = (float)( (dy) ) / 200.0f;		

	// Here we keep track of the current rotation (for up and down) so that
	// we can restrict the camera from doing a full 360 loop.
	currentRotX -= angleZ;  

	// If the current rotation (in radians) is greater than 1.0, we want to cap it.
	//if(currentRotX > 0.3f)
		//currentRotX = 0.3f;
	// Check if the rotation is below -1.0, if so we want to make sure it doesn't continue
	//else if(currentRotX < -0.3f)
		//currentRotX = -0.3f;
	// Otherwise, we can rotate the view around our position
//	else
	//{
		// To find the axis we need to rotate around for up and down
		// movements, we need to get a perpendicular vector from the
		// camera's view vector and up vector.  This will be the axis.
		CVector3 vAxis = Cross(SubtractTwoVectors(m_vView , m_vPosition), m_vUpVector);
		vAxis = Normalize(vAxis);
		// Rotate around our perpendicular axis and aint32_t the y-axis
		[self RotateView:angleZ x:vAxis.x y:vAxis.y z:vAxis.z];
		[self RotateView:-1*angleY x:0 y:0 z:1];

	//}
}
- (void) OnlySetPosition:(float)x y:(float)y z:(float)z
{
	m_vPosition = NewCVector3(x,y,z);
}
- (void)lockZ
{
	[self RotateView:0 x:m_vPosition.x y:m_vPosition.y z:m_vPosition.z];
}
-(float)rotationR
{
    return m_CurrentRotX;
}
- (void) UpdateMouseMove:(int) DeltaX deltaY:(int) DeltaY
{
	float angleY = 0.0f;							// This is the direction for looking up or down
	float angleZ = 0.0f;							// This will be the value we need to rotate around the Y axis (Left and Right)
//	static float currentRotX = 0.0f;

  if((DeltaX == 0)&&(DeltaY == 0))
    return;

//  TRACE("DX = %d  DY = %d\n", DeltaX, DeltaY);


	// Get the direction the mouse moved in, but bring the number down to a reasonable amount
	angleY = (float)(DeltaX) / -200.0f;		
	angleZ = (float)(DeltaY) / -200.0f;		

	// Here we keep track of the current rotation (for up and down) so that
	// we can restrict the camera from doing a full 360 loop.
	m_CurrentRotX -= angleZ;  

	// If the current rotation (in radians) is greater than 1.0, we want to cap it.
	if(m_CurrentRotX > 0.5f)
		m_CurrentRotX = 0.5f;
	// Check if the rotation is below -1.0, if so we want to make sure it doesn't continue
	else if(m_CurrentRotX < -1.5f)
		m_CurrentRotX = -1.5f;
	else
	{
		// To find the axis we need to rotate around for up and down
		// movements, we need to get a perpendicular vector from the
		// camera's view vector and up vector.  This will be the axis.
		CVector3 vAxis = Cross(SubtractTwoVectors(m_vView , m_vPosition), m_vUpVector);
		vAxis = Normalize(vAxis);

		// Rotate around our perpendicular axis and aint32_t the y-axis
		//RotateView(angleZ, vAxis.x, vAxis.y, vAxis.z);
		//RotateView(angleY, 0, 1, 0);
		[self RotateView:angleZ x:vAxis.x y:vAxis.y z:vAxis.z];
		[self RotateView:angleY x:0 y:0 z:1];
	}

  //TRACE("ROTX = %.3f\n", m_CurrentRotX);

}

///////////////////////////////// ROTATE VIEW \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
/////
/////	This rotates the view around the position using an axis-angle rotation
/////
///////////////////////////////// ROTATE VIEW \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*

- (void) RotateView:(float) angle x:(float) x y:(float) y z:(float) z
{
	CVector3 vNewView;
	allow_z = YES;
	// Get the view vector (The direction we are facing)
	CVector3 vView = SubtractTwoVectors(m_vView , m_vPosition);		

	// Calculate the sine and cosine of the angle once
	float cosTheta = (float)cos(angle);
	float sinTheta = (float)sin(angle);

	// Find the new x position for the new rotated point
	vNewView.x  = (cosTheta + (1 - cosTheta) * x * x)		* vView.x;
	vNewView.x += ((1 - cosTheta) * x * y - z * sinTheta)	* vView.y;
	vNewView.x += ((1 - cosTheta) * x * z + y * sinTheta)	* vView.z;

	// Find the new y position for the new rotated point
	vNewView.y  = ((1 - cosTheta) * x * y + z * sinTheta)	* vView.x;
	vNewView.y += (cosTheta + (1 - cosTheta) * y * y)		* vView.y;
	vNewView.y += ((1 - cosTheta) * y * z - x * sinTheta)	* vView.z;

	// Find the new z position for the new rotated point
	
	if (allow_z)
	{
		vNewView.z  = ((1 - cosTheta) * x * z - y * sinTheta)	* vView.x;
		vNewView.z += ((1 - cosTheta) * y * z + x * sinTheta)	* vView.y;
		vNewView.z += (cosTheta + (1 - cosTheta) * z * z)		* vView.z;
	}
	
	// Now we just add the newly rotated vector to our position to set
	// our new rotated view of our camera.
	m_vView = AddTwoVectors(m_vPosition , vNewView);
}
- (void) PositionCamera:(float)positionX positionY:(float)positionY positionZ:(float)positionZ
				viewX:(float)viewX viewY:(float)viewY viewZ:(float)viewZ
				upVectorX:(float)upVectorX upVectorY:(float)upVectorY upVectorZ:(float)upVectorZ
{
	CVector3 vPosition	= NewCVector3(positionX, positionY, positionZ);
	CVector3 vView		= NewCVector3(viewX, viewY, viewZ);
	CVector3 vUpVector	= NewCVector3(upVectorX, upVectorY, upVectorZ);

	// The code above just makes it cleaner to set the variables.
	// Otherwise we would have to set each variable x y and z.

	m_vPosition = vPosition;					// Assign the position
	m_vView     = vView;						// Assign the view
	m_vUpVector = vUpVector;					// Assign the up vector

  //TRACE("View = (%.2f %.2f %.2f)\n", m_vView.x, m_vView.y, m_vView.z);
  m_CurrentRotX = 0;
}
- (void) StrafeCamera:(float)delta;
{
	// Strafing is quite simple if you understand what the cross product is.
	// If you have 2 vectors (say the up vVector and the view vVector) you can
	// use the cross product formula to get a vVector that is 90 degrees from the 2 vectors.
	// For a better explanation on how this works, check out the OpenGL "Normals" tutorial at our site.
	// In our new Update() function, we set the strafing vector (m_vStrafe).  Due
	// to the fact that we need this vector for many things including the strafing
	// movement and camera rotation (up and down), we just calculate it once.
	//
	// Like our MoveCamera() function, we add the strafing vector to our current position 
	// and view.  It's as simple as that.  It has already been calculated in Update().
	
	// Add the strafe vector to our position
	//m_vPosition.x += m_vStrafe.x * speed;
	//m_vPosition.z += m_vStrafe.z * speed;

	// Add the strafe vector to our view
	//m_vView.x += m_vStrafe.x * speed;
	//m_vView.z += m_vStrafe.z * speed;

	m_vPosition.x += m_vStrafe.x * delta;
	m_vPosition.y += m_vStrafe.y * delta;
	m_vView.x += m_vStrafe.x * delta;
	m_vView.y += m_vStrafe.y * delta;
}
- (void) MoveCameraStraight:(float)delta;
{
	// Get the current view vector (the direction we are looking)
    CVector3 m_vViewNew = NewCVector3(m_vView.x, m_vView.y, m_vView.z);
	CVector3 vVector = SubtractTwoVectors(m_vViewNew , m_vPosition);
    
    
    /////// * /////////// * /////////// * NEW * /////// * /////////// * /////////// *
    
	// I snuck this change in here!  We now normalize our view vector when
	// moving throughout the world.  This is a MUST that needs to be done.
	// That way you don't move faster than you strafe, since the strafe vector
	// is normalized too.
	vVector = Normalize(vVector);
	
    /////// * /////////// * /////////// * NEW * /////// * /////////// * /////////// *
    
    
	//m_vPosition.x += vVector.x * speed;		// Add our acceleration to our position's X
	//m_vPosition.z += vVector.z * speed;		// Add our acceleration to our position's Z
	//m_vView.x += vVector.x * speed;			// Add our acceleration to our view's X
	//m_vView.z += vVector.z * speed;			// Add our acceleration to our view's Z
    //	delta = 1;
	
    m_vPosition.x += vVector.x * delta;		// Add our acceleration to our position's X
	m_vPosition.y += vVector.y * delta;		// Add our acceleration to our position's Z
	m_vPosition.z += vVector.z * delta;
	m_vView.x += vVector.x * delta;			// Add our acceleration to our view's X
	m_vView.y += vVector.y * delta;			// Add our acceleration to our view's Z
	m_vView.z += vVector.z * delta;
    
}

- (void) MoveCamera:(float)delta;
{
	// Get the current view vector (the direction we are looking)
	CVector3 vVector = SubtractTwoVectors(m_vView , m_vPosition);


/////// * /////////// * /////////// * NEW * /////// * /////////// * /////////// *

	// I snuck this change in here!  We now normalize our view vector when
	// moving throughout the world.  This is a MUST that needs to be done.
	// That way you don't move faster than you strafe, since the strafe vector
	// is normalized too.
	vVector = Normalize(vVector);
	
/////// * /////////// * /////////// * NEW * /////// * /////////// * /////////// *


	//m_vPosition.x += vVector.x * speed;		// Add our acceleration to our position's X
	//m_vPosition.z += vVector.z * speed;		// Add our acceleration to our position's Z
	//m_vView.x += vVector.x * speed;			// Add our acceleration to our view's X
	//m_vView.z += vVector.z * speed;			// Add our acceleration to our view's Z
//	delta = 1;
	
    m_vPosition.x += vVector.x * delta;		// Add our acceleration to our position's X
	m_vPosition.y += vVector.y * delta;		// Add our acceleration to our position's Z
	m_vPosition.z += vVector.z * delta;
	m_vView.x += vVector.x * delta;			// Add our acceleration to our view's X
	m_vView.y += vVector.y * delta;			// Add our acceleration to our view's Z
	m_vView.z += vVector.z * delta;

}
- (void) LevitateCamera:(float)delta;
{
	m_vPosition.z += delta;
	m_vView.z += delta;
}
- (void) Update;
{
	// Below we calculate the strafe vector every time we update
	// the camera.  This is because many functions use it so we might
	// as well calculate it only once.  

	// Initialize a variable for the cross product result
	CVector3 vCross = Cross(SubtractTwoVectors(m_vView , m_vPosition), m_vUpVector);

	// Normalize the strafe vector
	m_vStrafe = Normalize(vCross);

  //CheckKeyboard();
  //CheckMouse();
}
- (void)DoUnProject:(float)ifX ifY:(float) ifY ofObjX:(float*)ofObjX ofObjY:(float*)ofObjY ofObjZ:(float*)ofObjZ ifZ:(float)ifZ ibUseZ:(bool)ibUseZ
{

	//this function is basically just a wrapper for gluUnProject.
	//It does all of the getting of the projection and modelview
	//matrices, and if you pass true in the parameter ibUseZ,
	//it will use the ifZ parameter you passed in, otherwise it
	//will use glReadPixels to calculate it.
	//
	//ifX and ifY are expected to be relative to the upper-left
	//corner of the OpenGL context.  The calls to ReadPixels
	//and UnProject expect coordinates relative to the *lower*
	//left corner, so we will convert them here.

	float fMouseX, fMouseY, fMouseZ;
	fMouseX = ifX;
	fMouseY = ifY;
	fMouseZ = 0.0f;

	//now, fMouseX and fMouseY are relative to the *upper* left
	//corner of the OpenGL context, but OpenGL expects 
	//coordinates relative to the *lower* left corner of the 
	//screen, so we need to reverse Y.
	GLint anViewport[4];
	glGetIntegerv(GL_VIEWPORT, anViewport);

	if (ibUseZ)
	{
		fMouseZ = ifZ;
	}
	else
	{
		glReadPixels(fMouseX, fMouseY, 1, 1, GL_DEPTH_COMPONENT, GL_FLOAT, &fMouseZ);
	}
	//get the matrices for their passing to gluUnProject
	double afModelviewMatrix[16];
	double afProjectionMatrix[16];
	glGetDoublev(GL_MODELVIEW_MATRIX, afModelviewMatrix);
	glGetDoublev(GL_PROJECTION_MATRIX, afProjectionMatrix);

	double dTempX, dTempY, dTempZ;
	gluUnProject(fMouseX, fMouseY, fMouseZ, afModelviewMatrix, afProjectionMatrix, anViewport, &dTempX, &dTempY, &dTempZ);
	//ofObjX, Y and Z should be populated and returned now
	*ofObjX = (float)dTempX;
	*ofObjY = (float)dTempY;
	*ofObjZ = (float)dTempZ;

}
- (float*)position
{
	return (float *)&m_vPosition;
}
- (float *)vView
{
	return (float *)&m_vView;
}
- (float *)vUp
{
	return (float *)&m_vUpVector;
}
- (float *)vStrafe
{
	return (float *)&m_vStrafe;
}


- (void) Look;
{
	// Give openGL our camera position, then camera view, then camera up vector
	gluLookAt(m_vPosition.x, m_vPosition.y, m_vPosition.z,	
			  m_vView.x,	 m_vView.y,     m_vView.z,	
			  m_vUpVector.x, m_vUpVector.y, m_vUpVector.z);

	//gluLookAt(100, 100, 0,	
	//		      0, 0, 0, 
	//		  0, 0, 0);
}
@synthesize m_Speed;
@synthesize m_CurrentRotX;
@synthesize allow_z;
@end
