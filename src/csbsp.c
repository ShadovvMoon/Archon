//
//  csbsp.c
//  swordedit
//
//  Created by Samuco on 13/09/2013.
//
//

#include <stdio.h>

/*
int findClusterForPoint(Point P)
{
    return traverseBspTree(0, P);
}
*/

/*
int traverseBspTree(int node, Point P)
{
    if(node == -1) // I'm still not 100% sure what -1 means, but I'm almost positive it means that the point fell outside the BSP.
    return -1;

    if(node < 0) // we've hit a leaf, return the cluster
    return Leaves[node &0x7FFFFFFF].cluster;

    Plane N = getPlane(Node3d[node].plane);
    float d = dot3(N.abc,P.xyz) - N.d; // if this is < 0 the point is behind the plane, if > 0 it's in front
    if(d > 0)
    return traverseBspTree(Node3d[node].frontNode, P);
    return traverseBspTree(Node3d[node].backNode, P);
}
*/


int buildBSP()
{
    // Note that these are an extension to the Leaf3d block of the collision structure
    struct Leaves{
        int cluster;
        int surfaceRefCount;
        int surfaceRef;
    };
}