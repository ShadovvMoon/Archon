/*
 *  VectorMath.h
 *  swordedit
 *
 *  Created by sword on 5/19/08.
 *  Copyright 2008 sword Inc. All rights reserved.
 *
 */
 
#ifndef H_VECTORMATH
#define H_VECTORMATH 

CVector3 AddTwoVectors(CVector3 v1, CVector3 v2);
CVector3 SubtractTwoVectors(CVector3 v1, CVector3 v2);
CVector3 MultiplyTwoVectors(CVector3 v1, CVector3 v2);
CVector3 DivideTwoVectors(CVector3 v1, CVector3 v2);
CVector3 Cross(CVector3 vVector1, CVector3 vVector2);
float Magnitude(CVector3 vNormal);
CVector3 Normalize(CVector3 vVector);
CVector3 Cross(CVector3 vVector1, CVector3 vVector2);
CVector3 NewCVector3(float x,float y,float z);

CVector3 AddTwoVectors(CVector3 v1, CVector3 v2)
{
	CVector3 retVector;
	retVector.x = v1.x + v2.x;
	retVector.y = v1.y + v2.y;
	retVector.z = v1.z + v2.z;
	return retVector;
}
CVector3 SubtractTwoVectors(CVector3 v1, CVector3 v2)
{
	CVector3 retVector;
	retVector.x = v1.x - v2.x;
	retVector.y = v1.y - v2.y;
	retVector.z = v1.z - v2.z;
	return retVector;
}
CVector3 MultiplyTwoVectors(CVector3 v1, CVector3 v2)
{
	CVector3 retVector;
	retVector.x = v1.x * v2.x;
	retVector.y = v1.y * v2.y;
	retVector.z = v1.z * v2.z;
	return retVector;
}
CVector3 DivideTwoVectors(CVector3 v1, CVector3 v2)
{
	CVector3 retVector;
	retVector.x = v1.x / v2.x;
	retVector.y = v1.y / v2.y;
	retVector.z = v1.z / v2.z;
	return retVector;
}


/////////////////////////////////////// CROSS \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
/////
/////	This returns a perpendicular vector from 2 given vectors by taking the cross product.
/////
/////////////////////////////////////// CROSS \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*

float Dot(CVector3 vVector1, CVector3 vVector2)
{
	return vVector1.x*vVector2.x+vVector1.y*vVector2.y+vVector1.z*vVector2.z;
}


/////////////////////////////////////// CROSS \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
/////
/////	This returns a perpendicular vector from 2 given vectors by taking the cross product.
/////
/////////////////////////////////////// CROSS \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
												
CVector3 Cross(CVector3 vVector1, CVector3 vVector2)
{
	CVector3 vNormal;	

	// Calculate the cross product with the non communitive equation
	vNormal.x = ((vVector1.y * vVector2.z) - (vVector1.z * vVector2.y));
	vNormal.y = ((vVector1.z * vVector2.x) - (vVector1.x * vVector2.z));
	vNormal.z = ((vVector1.x * vVector2.y) - (vVector1.y * vVector2.x));

	// Return the cross product
	return vNormal;										 
}


/////////////////////////////////////// MAGNITUDE \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
/////
/////	This returns the magnitude of a vector
/////
/////////////////////////////////////// MAGNITUDE \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*

float Magnitude(CVector3 vNormal)
{
	// Here is the equation:  magnitude = sqrt(V.x^2 + V.y^2 + V.z^2) : Where V is the vector
	return (float)sqrt( (vNormal.x * vNormal.x) + 
						(vNormal.y * vNormal.y) + 
						(vNormal.z * vNormal.z) );
}
/////////////////////////////////////// NORMALIZE \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
/////
/////	This returns a normalize vector (A vector exactly of length 1)
/////
/////////////////////////////////////// NORMALIZE \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*

CVector3 Normalize(CVector3 vVector)
{
	// Get the magnitude of our normal
	float magnitude = Magnitude(vVector);				

	// Now that we have the magnitude, we can divide our vector by that magnitude.
	// That will make our vector a total length of 1.  
	vVector.x /= magnitude;
	vVector.y /= magnitude;
	vVector.z /= magnitude;
		
	
	// Finally, return our normalized vector
	return vVector;										
}
CVector3 NewCVector3(float x,float y,float z)
{
	CVector3 v;
	v.x = x;
	v.y = y;
	v.z = z;
	return v;
}
#endif