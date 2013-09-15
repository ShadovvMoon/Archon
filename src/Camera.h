//
//  Camera.h
//  SparkEdit
//
//  Created by Michael Edgar on Tue Jul 20 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//
#ifndef MACVERSION
#import "glew.h"
#endif

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import <Foundation/Foundation.h>

#import "defines.h"

@interface Camera : NSObject {
	CVector3 m_vPosition;					
	CVector3 m_vView;						
	CVector3 m_vUpVector;		
	CVector3 m_vStrafe;
	float m_Speed;
    float m_CurrentRotX;
	
	int allow_z;
}
- (void) Look;
- (void)DoUnProject:(float)ifX ifY:(float) ifY ofObjX:(float*)ofObjX ofObjY:(float*)ofObjY ofObjZ:(float*)ofObjZ ifZ:(float)ifZ ibUseZ:(bool)ibUseZ;
- (float*)position;
- (float *)vView;
- (float *)vUp;
- (float *)vStrafe;
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
- (void)orientUp;
- (void) UpdateMouseMove:(int) DeltaX deltaY:(int) DeltaY;
- (void) RotateView:(float) angle x:(float) x y:(float) y z:(float) z;
@property float m_Speed;
@property float m_CurrentRotX;
@property int allow_z;
@end
