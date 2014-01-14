/*
 *  Bitmask.h
 *  swordedit
 *
 *  Created by Fred Havemeyer on 6/26/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#define b1 0x1
#define b2 0x2
#define b3 0x4
#define b4 0x8
#define b5 0x10
#define b6 0x20
#define b7 0x40
#define b8 0x80
#define b9 0x100
#define b10 0x200
#define b11 0x400
#define b12 0x800
#define b13 0x1000
#define b14 0x2000
#define b15 0x4000
#define b16 0x8000
#define b17 0x10000
#define b18 0x20000
#define b19 0x40000
#define b20 0x80000
#define b21 0x100000
#define b22 0x200000
#define b23 0x400000
#define b24 0x800000
#define b25 0x1000000
#define b26 0x2000000
#define b27 0x4000000
#define b28 0x8000000
#define b29 0x10000000
#define b30 0x20000000
#define b31 0x40000000
#define b32 0x80000000

#define bitIsSet(bit, value) ((value & bit) != 0)
#define setBit(bit, value) (value | bit)
#define unsetBit(bit, value) (value ^ bit);

/*bool bitIsSet(unsigned int bit, unsigned int value);
unsigned int setBit(unsigned int bit, unsigned int value);
unsigned int unsetBit(unsigned int bit, unsigned int value);

bool bitIsSet(unsigned int bit, unsigned int value)
{
	return ((value & bit) != 0);
}

unsigned int setBit(unsigned int bit, unsigned int value)
{
	return (value | bit);
}

unsigned int unsetBit(unsigned int bit, unsigned int value)
{
	return (value ^ bit);
}*/