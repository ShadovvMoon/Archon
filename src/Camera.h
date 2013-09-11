//
//  Camera.h
//  SparkEdit
//
//  Created by Michael Edgar on Tue Jul 20 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import <Foundation/Foundation.h>
typedef struct
{
	float x,y,z;
} CVector3;
CVector3 AddTwoVectors(CVector3 v1, CVector3 v2);
CVector3 SubtractTwoVectors(CVector3 v1, CVector3 v2);
CVector3 MultiplyTwoVectors(CVector3 v1, CVector3 v2);
CVector3 DivideTwoVectors(CVector3 v1, CVector3 v2);

@interface Camera : NSObject {
	CVector3 m_vPosition;					
	CVector3 m_vView;						
	CVector3 m_vUpVector;		
	CVector3 m_vStrafe;
	float m_Speed;
    float m_CurrentRotX;
}
- (void) Look;
- (void)DoUnProject:(float)ifX ifY:(float) ifY ofObjX:(float*)ofObjX ofObjY:(float*)ofObjY ofObjZ:(float*)ofObjZ ifZ:(float)ifZ ibUseZ:(bool)ibUseZ;
- (float*)position;
- (void) Update;
- (void) MoveCamera:(float)delta;
- (void) LevitateCamera:(float)delta;
- (void) StrafeCamera:(float)delta;
- (void) PositionCamera:(float)positionX positionY:(float)positionY positionZ:(float)positionZ
				viewX:(float)viewX viewY:(float)viewY viewZ:(float)viewZ
				upVectorX:(float)upVectorX upVectorY:(float)upVectorY upVectorZ:(float)upVectorZ;
- (id)init;
- (void) HandleMouseMove:(float)dx dy:(float)dy;
- (void) OnlySetPosition:(float)x y:(float)y z:(float)z;
- (void) UpdateMouseMove:(int) DeltaX deltaY:(int) DeltaY;
- (void) RotateView:(float) angle x:(float) x y:(float) y z:(float) z;
@end
