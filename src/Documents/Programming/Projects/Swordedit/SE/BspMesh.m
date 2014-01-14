//
//  BspMesh.m
//  swordedit
//
//  Created by sword on 10/28/07.
//  Copyright 2007 sword Inc. All rights reserved.
//

#import "BspMesh.h"
#import "BitmapTag.h"

#import "TextureManager.h"

@implementation BspMesh
- (id)initWithMapAndBsp:(HaloMap *)map bsp_class:(BSP *)bsp_class texManager:(TextureManager *)texManager bsp_magic:(unsigned long)bsp_magic
{
	if ((self = [super init]) != nil)
	{
		m_SubMeshCount = 0;
		m_activeBsp = 0;
		m_pMesh = 0;
		m_pWeather = nil;
		m_pClusters = nil;
		
		m_Centroid[0] = 0;
		m_Centroid[1] = 0;
		m_Centroid[2] = 0;
		m_TriTotal = 0;
		int x;
		for (x = 0; x < 3; x++)
		{
			m_MapBox.min[x] = 40000;
			m_MapBox.max[x] = -40000;
		}
		
		texturesLoaded = FALSE;
		
		_bspParent = [bsp_class retain];
		_mapfile = [map retain];
		_texManager = [texManager retain];
		_bspMagic = bsp_magic;
	}
	return self;
}
- (void)dealloc
{
	#ifdef __DEBUG__
	NSLog(@"Deallocating BSP Mesh!");
	#endif
	
	[_bspParent release];
	[_mapfile release];
	[_texManager release];
	
	if (m_pMesh->textures)
		free(m_pMesh->textures);
	if (m_pMesh->pVert)
		free(m_pMesh->pVert);
	if (m_pMesh->pIndex)
		free(m_pMesh->pIndex);
	if (m_pMesh->pLightmapVert)
		free(m_pMesh->pLightmapVert);
	free(m_pMesh);
	free(m_pWeather);
	free(m_pLightmaps);
	free(m_pClusters);
	
	#ifdef __DEBUG__
	NSLog(@"BSP Mesh deallocated!");
	#endif
	
	[super dealloc];
}
- (void)freeBSPAllocation
{
	
}
- (SUBMESH_INFO *)m_pMesh:(long)index
{
	return &m_pMesh[index];
}
- (unsigned long)m_SubMeshCount
{
	return m_SubMeshCount;
}
- (void)LoadVisibleBsp:(unsigned long)BspHeaderOffset version:(unsigned long)version
{
	[_mapfile seekToAddress:BspHeaderOffset];
	m_BspHeader.LightmapsTag = [_mapfile readReference];
	NSLog(@"Lightmap tag stuff: ID:[0x%x], %@ name:[%@]", m_BspHeader.LightmapsTag.TagId, [NSString stringWithCString:[[_mapfile tagForId:m_BspHeader.LightmapsTag.TagId] tagClassHigh] encoding:NSMacOSRomanStringEncoding], [[_mapfile tagForId:m_BspHeader.LightmapsTag.TagId] tagName]);
	[_mapfile skipBytes:(0x25 * sizeof(long))];
	m_BspHeader.Shaders = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.CollBspHeader = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Nodes = [_mapfile readBspReflexive:_bspMagic];
	[_mapfile skipBytes:(6 * sizeof(long))];
	m_BspHeader.Leaves = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.LeafSurfaces = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.SubmeshTriIndices = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.SubmeshHeader = [_mapfile readBspReflexive:_bspMagic]; //Lightmaps in eschaton
	m_BspHeader.Chunk10 = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Chunk11 = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Chunk12 = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Clusters = [_mapfile readBspReflexive:_bspMagic];
	[_mapfile readLong:&m_BspHeader.ClusterDataSize];
	[_mapfile readLong:&m_BspHeader.unk11];
	m_BspHeader.Chunk14 = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.ClusterPortals = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Chunk16a = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.BreakableSurfaces = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.FogPlanes = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.FogRegions = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.FogOrWeatherPallette = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Chunk16f = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Chunk16g = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Weather = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.WeatherPolyhedra = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Chunk19 = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Chunk20 = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.PathfindingSurface = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Chunk24 = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.BackgroundSound = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.SoundEnvironment = [_mapfile readBspReflexive:_bspMagic];
	[_mapfile readLong:&m_BspHeader.SoundPASDataSize];
	[_mapfile readLong:&m_BspHeader.unk12];
	m_BspHeader.Chunk25 = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Chunk26 = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Chunk27 = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.Markers = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.DetailObjects = [_mapfile readBspReflexive:_bspMagic];
	m_BspHeader.RuntimeDecals = [_mapfile readBspReflexive:_bspMagic];
	[_mapfile skipBytes:(9 * sizeof(unsigned long))];
    
    
	NSLog(@"LM1");
	[self LoadMaterialMeshHeaders];
    NSLog(@"LM2");
	[self LoadCollisionMeshHeaders];
    NSLog(@"LM3");
	[self LoadPcSubmeshes];
    NSLog(@"LM4");
}
- (void)LoadPcSubmeshes
{
	int i, v, x;
	SUBMESH_INFO *pPcSubMesh;
	[self ResetBoundingBox];
	for (i =0; i < m_SubMeshCount; i++)
	{
		pPcSubMesh = &m_pMesh[i];
		pPcSubMesh->VertCount = pPcSubMesh->header.VertexCount1;
		pPcSubMesh->IndexCount = pPcSubMesh->header.VertIndexCount;
		
		// In Bob's words, "Allocate vertex and index arrays"
		pPcSubMesh->pIndex = malloc(pPcSubMesh->IndexCount * sizeof(TRI_INDICES));
		pPcSubMesh->pVert = malloc(pPcSubMesh->VertCount * sizeof(UNCOMPRESSED_BSP_VERT));
		pPcSubMesh->pCompVert = malloc(pPcSubMesh->VertCount * sizeof(COMPRESSED_BSP_VERT));
		pPcSubMesh->pLightmapVert = malloc(pPcSubMesh->VertCount * sizeof(UNCOMPRESSED_LIGHTMAP_VERT));
		
		[_mapfile seekToAddress:pPcSubMesh->header.PcVertexDataOffset];
		//NSLog(@"%d", pPcSubMesh->header.PcVertexDataOffset);
		for (v = 0; v < pPcSubMesh->VertCount; v++)
			pPcSubMesh->pVert[v] = [_bspParent readUncompressedBspVert]; 
		for (v = 0; v < pPcSubMesh->VertCount; v++)
			pPcSubMesh->pLightmapVert[v] = [_bspParent readUncompressedLightmapVert];
		[_mapfile seekToAddress:pPcSubMesh->header.VertIndexOffset];
		for (v = 0; v < pPcSubMesh->IndexCount; v++)
			pPcSubMesh->pIndex[v] = [_bspParent readIndexFromFile];
		m_TriTotal += pPcSubMesh->VertCount;
		// OH GEE
		// In bob's words, "Update the map extents for analysis
		for (x = 0; x < pPcSubMesh->VertCount; x++)
			[self UpdateBoundingBox:i pCoord:pPcSubMesh->pVert[x].vertex_k version:7];
		
		
	
		//[_mapfile bitmTagForShaderId:pPcSubMesh->header.ShaderTag.TagId]
		

		pPcSubMesh->RenderTextureIndex = [_mapfile bitmTagForShaderId:pPcSubMesh->header.ShaderTag.TagId];
	}
}




-(void)writePcSubmeshes
{
	int i, v, x;
	SUBMESH_INFO *pPcSubMesh;
	for (i =0; i < m_SubMeshCount; i++)
	{
		pPcSubMesh = &m_pMesh[i];
		pPcSubMesh->VertCount = pPcSubMesh->header.VertexCount1;
		pPcSubMesh->IndexCount = pPcSubMesh->header.VertIndexCount;

		int address = pPcSubMesh->header.PcVertexDataOffset;
		for (v = 0; v < pPcSubMesh->VertCount; v++)
		{
			[_mapfile writeAnyDataAtAddress:&(pPcSubMesh->pVert[v]) size:sizeof(UNCOMPRESSED_BSP_VERT) address:address];
			address+=sizeof(UNCOMPRESSED_BSP_VERT);
		}
		for (v = 0; v < pPcSubMesh->VertCount; v++)
		{
			[_mapfile writeAnyDataAtAddress:&(pPcSubMesh->pLightmapVert[v]) size:sizeof(UNCOMPRESSED_LIGHTMAP_VERT) address:address];
			address+=sizeof(UNCOMPRESSED_LIGHTMAP_VERT);
		}

		address = pPcSubMesh->header.VertIndexOffset;
		for (v = 0; v < pPcSubMesh->IndexCount; v++)
		{
			[_mapfile writeAnyDataAtAddress:&(pPcSubMesh->pIndex[v]) size:6 address:address];
			address+=6;
		}
	}

    
    NSLog(@"Saving collision data.");
    
    unsigned long offset;
    int j;
    int cv=0;
    for (i = 0; i < m_BspHeader.CollBspHeader.chunkcount; i++)
    {
        for (j = 0; j < m_pCollisions[i].Material.chunkcount; j++)
        {
            offset = (m_pCollisions[i].Material.offset + (16 * j));
            [_mapfile writeAnyDataAtAddress:&coll_verts[cv].x size:4 address:offset];
            [_mapfile writeAnyDataAtAddress:&coll_verts[cv].y size:4 address:offset+4];
            [_mapfile writeAnyDataAtAddress:&coll_verts[cv].z size:4 address:offset+8];
            cv++;
        }
    }
	
}

-(void)exportTextures
{
    int i;
	
	
	NSLog(@"SUbmeshes: %d", m_SubMeshCount);
    
	for (i = 0; i < m_SubMeshCount; i++)
	{
		
		int gm = 1;
		if (TRUE)//useNewRenderer() == 2)
		{
        
            [_texManager exportTextureOfIdent:m_pMesh[i].baseMap subImage:0];
            [_texManager exportTextureOfIdent:m_pMesh[i].DefaultLightmapIndex subImage:m_pMesh[i].LightmapIndex];
        }
    }
}

- (void)LoadPcSubmeshTextures
{
	int i;
	
	if (texturesLoaded)
		return;
	
	NSLog(@"SUbmeshes: %d", m_SubMeshCount);
	
    
	for (i = 0; i < m_SubMeshCount; i++)
	{
		
		int gm = 1;
		if (TRUE)//useNewRenderer() == 2)
		{
            //NSMutableArray *bitms = [_mapfile bitmsTagForShaderId:m_pMesh[i].header.ShaderTag.TagId];
            m_pMesh[i].DefaultLightmapIndex = m_BspHeader.LightmapsTag.TagId;
            
            if ([[NSString stringWithCString: m_pMesh[i].header.ShaderTag.tag length:4] isEqualToString:@"vnes"])
            {  
                m_pMesh[i].DefaultBitmapIndex = [[_mapfile bitmTagForShaderId:m_pMesh[i].header.ShaderTag.TagId] idOfTag];
                [_texManager loadTextureOfIdent:m_pMesh[i].DefaultBitmapIndex subImage:0];
                
                senv *shader = (senv *)malloc(sizeof(senv));
                [_mapfile loadShader:shader forID:m_pMesh[i].header.ShaderTag.TagId];
            
                //BASE MAP
				m_pMesh[i].baseMap = shader->baseMapBitm.TagId;
				[_texManager loadTextureOfIdent:m_pMesh[i].baseMap subImage:0];
 
                
                
                m_pMesh[i].primaryMap = shader->primaryMapBitm.TagId;
                m_pMesh[i].primaryMapScale = shader->primaryMapScale;
                [_texManager loadTextureOfIdent:m_pMesh[i].primaryMap subImage:0];
            
                
                //SECONDARY DETAIL MAP
                m_pMesh[i].secondaryMap = shader->secondaryMapBitm.TagId;
                m_pMesh[i].secondaryMapScale = shader->secondaryMapScale;
                [_texManager loadTextureOfIdent:m_pMesh[i].secondaryMap subImage:0];
				
                //MICRO DETAIL MAP
                //m_pMesh[i].microMap = [[bitmaps objectAtIndex:3] idOfTag];
                //[_texManager loadTextureOfIdent:m_pMesh[i].microMap subImage:0];
            }
            else if ([[NSString stringWithCString: m_pMesh[i].header.ShaderTag.tag length:4] isEqualToString:@"algs"])
            {
                m_pMesh[i].DefaultBitmapIndex = [[[_mapfile bitmsTagForShaderId:m_pMesh[i].header.ShaderTag.TagId] objectAtIndex:2] idOfTag];
                [_texManager loadTextureOfIdent:m_pMesh[i].DefaultBitmapIndex subImage:0];
                
                m_pMesh[i].baseMap = -1;// m_pMesh[i].DefaultBitmapIndex;
            }
            else
            {
                m_pMesh[i].DefaultBitmapIndex = [[[_mapfile bitmsTagForShaderId:m_pMesh[i].header.ShaderTag.TagId] objectAtIndex:0] idOfTag];
                [_texManager loadTextureOfIdent:m_pMesh[i].DefaultBitmapIndex subImage:0];
                
                m_pMesh[i].baseMap = -1;// m_pMesh[i].DefaultBitmapIndex;
            }
			
		}
		else
		{
            
            m_pMesh[i].DefaultBitmapIndex = [[_mapfile bitmTagForShaderId:m_pMesh[i].header.ShaderTag.TagId] idOfTag];
           // m_pMesh[i].DefaultBitmapIndex = m_BspHeader.LightmapsTag.TagId;
            
            [_texManager loadTextureOfIdent:m_pMesh[i].DefaultBitmapIndex subImage:0];
            m_pMesh[i].baseMap = -1;// m_pMesh[i].DefaultBitmapIndex;
            //[_texManager loadTextureOfIdent:m_BspHeader.LightmapsTag.TagId subImage:0];
            
            
		}
		
	}
	texturesLoaded = TRUE;
}






//OFFSETS
//9DC68
//F4F10 FOUND!
//164578
#define EPSILON 0.0001
//New bsp methods!
-(float*)findIntersection:(float*)p withOther:(float*)q
{
    return [self traverseBspTree:p withOther:q andNode:0];
}

float dot3n(struct Plane a, float*p)
{
    return a.a*p[0]+a.b*p[1]+a.c*p[2];
}
float mag3p(float*a)
{
    return sqrtf(powf(a[0], 2)+powf(a[1], 2)+powf(a[2], 2));
}
float dot3p(float*a, float*p)
{
    return a[0]*p[0]+a[1]*p[1]+a[2]*p[2];
}
float dot3no(struct Bsp2dNodes a, float*p)
{
    return a.a*p[0]+a.b*p[1];
}

float *subtractPoints(float *a, float *b)
{
    float *V = malloc(sizeof(float)*3);
    V[0] = a[0]-b[0];
    V[1] = a[1]-b[1];
    V[2] = a[2]-b[2];
    return V;
}
float *vert2Pt(vert *a)
{
    float *V = malloc(sizeof(float)*3);
    V[0] = a->x;
    V[1] = a->y;
    V[2] = a->z;
    return V;
}

float *subtractVerts(vert *a, vert *b)
{
    float *V = malloc(sizeof(float)*3);
    V[0] = a->x-b->x;
    V[1] = a->y-b->y;
    V[2] = a->z-b->z;
    return V;
}


float *addPoints(float *a, float *b)
{
    float *V = malloc(sizeof(float)*3);
    V[0] = a[0]+b[0];
    V[1] = a[1]+b[1];
    V[2] = a[2]+b[2];
    return V;
}

float *multPoint(float scalar, float *b)
{
    float *V = malloc(sizeof(float)*3);
    V[0] = scalar*b[0];
    V[1] = scalar*b[1];
    V[2] = scalar*b[2];
    return V;
}

float *newPt(float x, float y, float z)
{
    float *V = malloc(sizeof(float)*3);
    V[0] = x;
    V[1] = y;
    V[2] = z;
    return V;
}

-(BOOL)surfaceTest:(int)surface withPoint:(float*)T
{
    // Follow the edges with our surface
    // Compute the angles between the point and all the edges
    // if they add up to 2*PI, then the point is inside the polygon
    //NSLog(@"Surface test %d %f %f %f %d", surface, T[0], T[1], T[2], surfaces[surface].firstEdge);
    
    vert P, Q;
    float angleSum = 0;
    
    int currentEdge;
    int nextEdge = surfaces[surface].firstEdge;
    do
    {
        currentEdge = nextEdge;
        P = coll_verts[edges[currentEdge].endVertex];
        Q = coll_verts[edges[currentEdge].startVertex];
        
        if (surface == edges[currentEdge].leftFace)
        {
            nextEdge = edges[currentEdge].forwardEdge;
        }
        else
        {
            nextEdge = edges[currentEdge].reverseEdge;
        }
        
        float *v1 = subtractVerts(&Q,&P);
        float *v2 = (subtractPoints(T, vert2Pt(&P)));
        
        float *v3 = subtractVerts(&P,&Q);
        float *v4 = (subtractPoints(T, vert2Pt(&Q)));
        
        // Get the angle between (Q-P) and (P-T)
        angleSum += acos(dot3p(v1, v2)/(mag3p(v1)*mag3p(v2)));

        // Get the angle between (P-Q) and (Q-T)
        angleSum += acos(dot3p(v3, v4)/(mag3p(v3)*mag3p(v4)));
        
        //NSLog(@"%f %d", angleSum, nextEdge);
    }
    while(nextEdge != surfaces[surface].firstEdge);
    
    if(fabs(angleSum - 2*M_PI )< EPSILON)
        return true;
    //NSLog(@"%f", fabs(angleSum - 2*M_PI ));
    return true;
}

-(BOOL)HitTestBsp2d:(int)node withT:(float*)T andTp:(float*)Tp
{
    NSLog(@"Hittest 2d %d %d", node, node & 0x7FFFFFFF);
    if(node < 0)
        return [self surfaceTest:node & 0x7FFFFFFF withPoint:T];
    
    float s = dot3no(bsp2dnode[node], Tp) - bsp2dnode[node].d;
    
    if( s > 0)
        return [self HitTestBsp2d:bsp2dnode[node].rightChild withT:T andTp:Tp];
    return [self HitTestBsp2d:bsp2dnode[node].leftChild withT:T andTp:Tp];
}

-(float*)HaloProjectPoint2D:(struct Plane)N withT:(float*)p
{
    // First find the component of the plane normal that is the most significant
    float x = fabs(N.a);
    float y = fabs(N.b);
    float z = fabs(N.c);
    int projectionAxis = 0;
    int sign = 0; // 0 means the projection axis was negative, 1 means positive
    
    
    float letter = 0;
    if (z < y || z < x)
    {
        if (y < x) // X axis has the greatest contribution
        {
            projectionAxis = 0;
            letter = N.a;
        }
        else // Y axis has the greatest contribution
        {
            projectionAxis = 1;
            letter = N.b;
        }
    }
    else // otherwise Z had the greatest contribution
    {
        projectionAxis = 2;
        letter = N.c;
    }
    
    if(letter > 0.f)
    {
        sign = 1;
    }
    
    // Choose the projection plane
    static short planeIndex[3][3][3] = {
        // Negative
        {{2, 1},  //Z,Y
            {0, 2}, //X,Z
            {1, 0}}, //Y,X
        
        // Positive
        { {1, 2},  // Y, Z
            {2, 0}, // Z, X
            {0, 1}}};// X, Y
    
    
    //
    int xyz = planeIndex[sign][projectionAxis][0];
    int xyz2 = planeIndex[sign][projectionAxis][1];
    
    return newPt(p[xyz], p[xyz2], 0);
}

-(float*)hitTestLeaf:(float*)p withOther:(float*)q andLeaf:(int)leaf
{
    //5920
    NSLog(@"Leaf %d %d %d %f %f", leaf, leaves[leaf].bsp2dRef, leaves[leaf].bsp2dCount, p[2], q[2]);
    
    int reference = leaves[leaf].bsp2dRef;
    float *S = malloc(sizeof(float)*3);
    S[0] = 100000000.0;
    S[1] = 100000000.0;
    S[2] = 100000000.0;
    float *T = nil;
    
    // For every bsp2d reference in the leaf
    for(int i = 0; i < leaves[leaf].bsp2dCount; i++)
    {
        struct Plane N = planes[bsp2dref[reference+i].plane];
    
        // check if the line segment crosses the 2d plane upon which the 2dBsp was projected
        float s = dot3n(N,p) - N.d;
        float t = dot3n(N,q) - N.d;
        if(s*t >= 0) // if the line does not cross the plane, don't consider it
            continue;
        
        NSLog(@"CONSIDER");
        float* V = subtractPoints(q,p);
        float ins = -(N.d + dot3n(N,p))/dot3n(N, V);
        T = addPoints(p, multPoint(ins, V));
        float *Tp = [self HaloProjectPoint2D:N withT:T];
        
        float distanceS = sqrtf(powf(S[0]-p[0], 2) + powf(S[1]-p[1], 2) + powf(S[2]-p[2], 2));
        float distanceT = sqrtf(powf(T[0]-p[0], 2) + powf(T[1]-p[1], 2) + powf(T[2]-p[2], 2));
        
        NSLog(@"%d %d", reference, i);
        if ([self HitTestBsp2d:bsp2dref[reference+i].node withT:T andTp:Tp] && distanceT < distanceS)
            S = T;
    }
    
    return S;
}

-(float*)traverseBspTree:(float*)p withOther:(float*)q andNode:(int)node
{
    if (node == -1)
        return nil;
    
    if (node < 0) // we've hit a leaf, perform hit test
    {
        return [self hitTestLeaf:p withOther:q andLeaf:node & 0x7FFFFFFF];
    }
    
    struct Plane N = planes[bsp3d_nodes[node].plane];
    float s = N.a*p[0]+ N.b*p[1]+ N.c*p[2] - N.d; // if this is < 0 the point is behind the plane, > 0 in front
    float t = N.a*q[0]+ N.b*q[1]+ N.c*q[2] - N.d; // same as above, but for Q
    
   // NSLog(@"%f %f %f %f", N.a, N.b, N.c, N.d);
   // NSLog(@"S %f T %f", s, t);
    
    /*
     If both s and t are > 0 then we know the line segment is completely to the front of the plane.
     Likewise if s and t are < 0 then we know they're both behind the plane.
     But if  s > 0 and t  < 0  or s < 0 and t > 0, we know the segment straddles the plane, so we need to compute two line segments
     (P, Pn) (Qn,Q) where Pn and Qn almost lie on the plane N.
     */
    if(s > 0 && t > 0)
        return [self traverseBspTree:p withOther:q andNode:bsp3d_nodes[node].frontNode];
    if(s < 0 && t < 0)
        return [self traverseBspTree:p withOther:q andNode:bsp3d_nodes[node].backNode];
    
    float *V = malloc(sizeof(float)*3);
    V[0] = q[0]-p[0];
    V[1] = q[1]-p[1];
    V[2] = q[2]-p[2];
    
    float ins = -(N.d + (p[0]*N.a+p[1]*N.b+p[2]*N.c))/(V[0]*N.a+V[1]*N.b+V[2]*N.c);
    
    // Now we have it that so that P+ins*V lies on the plane N
    
    // we have to make sure that the new line (P, Pn) can still intersect the splitting plane
    // so we fudge ins a little bit to make sure that it can still intersect with N (since the splitting plane may contain
    // the surface that we want to have an intersection test against in the leaf)
    
    float *Pn = malloc(sizeof(float)*3);
    Pn[0] = p[0] + (ins + EPSILON)*V[0];
    Pn[1] = p[1] + (ins + EPSILON)*V[1];
    Pn[2] = p[2] + (ins + EPSILON)*V[2];
    
    float *Qn = malloc(sizeof(float)*3);
    Qn[0] = q[0] + (ins - EPSILON)*V[0];
    Qn[1] = q[1] + (ins - EPSILON)*V[1];
    Qn[2] = q[2] + (ins - EPSILON)*V[2];
    
    float *S, *T;
    if(s < 0) // If P,Pn is behind the plane we need to test the new segment against the back-node
    {
        S = [self traverseBspTree:p withOther:Pn andNode:bsp3d_nodes[node].backNode];
        T = [self traverseBspTree:Qn withOther:q andNode:bsp3d_nodes[node].frontNode];
    }
    else
    {
        S = [self traverseBspTree:p withOther:Pn andNode:bsp3d_nodes[node].frontNode];
        T = [self traverseBspTree:Qn withOther:q andNode:bsp3d_nodes[node].backNode];
    }
    
    if (!S)
        return T;
    
    if (!T)
        return S;
    
    float distanceS = sqrtf(powf(S[0]-p[0], 2) + powf(S[1]-p[1], 2) + powf(S[2]-p[2], 2));
    float distanceT = sqrtf(powf(T[0]-p[0], 2) + powf(T[1]-p[1], 2) + powf(T[2]-p[2], 2));
    
    if(distanceS<distanceT)
        return S;
    return T;
    
}




- (void)LoadCollisionMeshHeaders
{
	int am = 0;
	int pla = 0;
	
		if (!am)
		{
			if (!pla)
			{
				
                unsigned long offset;
                int x, i, j, hdr_count;
                
                m_pCollisions = malloc(sizeof(BSP_COLLISION) * m_BspHeader.CollBspHeader.chunkcount);
                
                
                //EXTEND THIS CLASS TO READ THE FULL BSP
                
                
                NSLog(@"offset %d", m_BspHeader.CollBspHeader.offset);
                
                [_mapfile seekToAddress:m_BspHeader.CollBspHeader.offset];
                int col_mesh_count = 0;
                int node3dcount = 0;
                int planecount = 0;
                int leafcount = 0;
                int surfacecount = 0;
                int edgecount = 0;
                int bsp2dnode22 = 0;
                int bsp2dref22 = 0;
                for (x = 0; x< m_BspHeader.CollBspHeader.chunkcount; x++)
                {
                    [_mapfile readShort:&m_pCollisions[x].LightmapIndex];
                    [_mapfile readShort:&m_pCollisions[x].unk1];
              
                    
                    [_mapfile skipBytes:0x54-4-12*7];
                    m_pCollisions[x].Node3D = [_mapfile readBspReflexive:_bspMagic]; //Verticies
                    m_pCollisions[x].Planes = [_mapfile readBspReflexive:_bspMagic]; //Verticies
                    m_pCollisions[x].Leaves = [_mapfile readBspReflexive:_bspMagic]; //Verticies
                    m_pCollisions[x].BSP2DRef = [_mapfile readBspReflexive:_bspMagic]; //Verticies
                    m_pCollisions[x].BSP2DNodes = [_mapfile readBspReflexive:_bspMagic]; //Verticies
                    m_pCollisions[x].Surfaces = [_mapfile readBspReflexive:_bspMagic]; //Verticies
                    m_pCollisions[x].Edges = [_mapfile readBspReflexive:_bspMagic]; //Verticies
                    m_pCollisions[x].Material = [_mapfile readBspReflexive:_bspMagic]; //Verticies
                    
    
                    col_mesh_count += m_pCollisions[x].Material.chunkcount;
                    node3dcount += m_pCollisions[x].Node3D.chunkcount;
                    planecount += m_pCollisions[x].Planes.chunkcount;
                    leafcount += m_pCollisions[x].Leaves.chunkcount;
                    surfacecount += m_pCollisions[x].Surfaces.chunkcount;
                    edgecount += m_pCollisions[x].Edges.chunkcount;
                    bsp2dnode22 += m_pCollisions[x].BSP2DNodes.chunkcount;
                    bsp2dref22 += m_pCollisions[x].BSP2DRef.chunkcount;
                    
                }
                
                NSLog(@"BSP COUNT %ld", m_BspHeader.CollBspHeader.chunkcount);
                NSLog(@"PLANE COUNT %ld", m_pCollisions[0].Planes.chunkcount);
                NSLog(@"BSP2dRef COUNT %ld", m_pCollisions[0].BSP2DRef.chunkcount);
                NSLog(@"BSP2dnode COUNT %ld", m_pCollisions[0].BSP2DNodes.chunkcount);
                NSLog(@"SURFACE COUNT %ld", m_pCollisions[0].Surfaces.chunkcount);
                NSLog(@"Edges COUNT %ld", m_pCollisions[0].Edges.chunkcount);
                NSLog(@"MATERIAL COUNT %ld", m_pCollisions[0].Material.chunkcount);
                NSLog(@"LEAVES COUNT %ld", m_pCollisions[0].Leaves.chunkcount);
                NSLog(@"3d COUNT %ld", m_pCollisions[0].Node3D.chunkcount);

                coll_count = col_mesh_count;
                coll_verts = malloc(col_mesh_count * sizeof(vert));
                
                node3d_count = node3dcount;
                bsp3d_nodes = malloc(node3dcount * sizeof(struct Bsp3dNode));
                
                leaf_count = leafcount;
                plane_count = planecount;
                planes = malloc(planecount * sizeof(struct Plane));
                leaves = malloc(leafcount * sizeof(struct Leaves));
                bsp2dref = malloc(bsp2dref22 * sizeof(struct Bsp2dRef));
                bsp2dnode = malloc(bsp2dnode22 * sizeof(struct Bsp2dNodes));
                surfaces = malloc(surfacecount * sizeof(struct Surfaces));
                edges = malloc(edgecount * sizeof(struct Edges));
                
                hdr_count = 0;
                for (i = 0; i < m_BspHeader.CollBspHeader.chunkcount; i++)
                {
                    for (j = 0; j < m_pCollisions[i].Material.chunkcount; j++)
                    {
                        offset = (m_pCollisions[i].Material.offset + (16 * j));
                        [_mapfile seekToAddress:offset];
                        
                        
                        long x;
                        
                        
                        [_mapfile readFloat:&(coll_verts[hdr_count].x)];
                        [_mapfile readFloat:&coll_verts[hdr_count].y];
                        
                        [_mapfile readFloat:&coll_verts[hdr_count].z];
                        [_mapfile readInt:&coll_verts[hdr_count].edge];
                        
                        
                        hdr_count++;
                    }
                }
                
                hdr_count = 0;
                for (i = 0; i < m_BspHeader.CollBspHeader.chunkcount; i++)
                {
                    for (j = 0; j < m_pCollisions[i].Node3D.chunkcount; j++)
                    {
                        offset = (m_pCollisions[i].Node3D.offset + (12 * j));
                        [_mapfile seekToAddress:offset];

                        [_mapfile readInt:&(bsp3d_nodes[hdr_count].plane)];
                        [_mapfile readInt:&bsp3d_nodes[hdr_count].backNode];
                        [_mapfile readInt:&bsp3d_nodes[hdr_count].frontNode];
                        
                        hdr_count++;
                    }
                }
                
                hdr_count = 0;
                for (i = 0; i < m_BspHeader.CollBspHeader.chunkcount; i++)
                {
                    for (j = 0; j < m_pCollisions[i].Planes.chunkcount; j++)
                    {
                        offset = (m_pCollisions[i].Planes.offset + (16 * j));
                        [_mapfile seekToAddress:offset];
                        
                        [_mapfile readInt:&(planes[hdr_count].a)];
                        [_mapfile readInt:&planes[hdr_count].b];
                        [_mapfile readInt:&planes[hdr_count].c];
                        [_mapfile readInt:&planes[hdr_count].d];
                        
                        hdr_count++;
                    }
                }
                
                hdr_count = 0;
                for (i = 0; i < m_BspHeader.CollBspHeader.chunkcount; i++)
                {
                    for (j = 0; j < m_pCollisions[i].Leaves.chunkcount; j++)
                    {
                        offset = (m_pCollisions[i].Leaves.offset + (8 * j));
                        [_mapfile seekToAddress:offset];
                        
                        [_mapfile readShort:&(leaves[hdr_count].flags)];
                        [_mapfile readShort:&leaves[hdr_count].bsp2dCount];
                        [_mapfile readInt:&leaves[hdr_count].bsp2dRef];
                        
                        hdr_count++;
                    }
                }
                
                hdr_count = 0;
                for (i = 0; i < m_BspHeader.CollBspHeader.chunkcount; i++)
                {
                    for (j = 0; j < m_pCollisions[i].BSP2DNodes.chunkcount; j++)
                    {
                        offset = (m_pCollisions[i].BSP2DNodes.offset + (20 * j));
                        [_mapfile seekToAddress:offset];
                        
                        [_mapfile readFloat:&(bsp2dnode[hdr_count].a)];
                        [_mapfile readFloat:&bsp2dnode[hdr_count].b];
                        [_mapfile readFloat:&bsp2dnode[hdr_count].d];
                        [_mapfile readInt:&bsp2dnode[hdr_count].leftChild];
                        [_mapfile readInt:&bsp2dnode[hdr_count].rightChild];
                        
                        hdr_count++;
                    }
                }
                
                hdr_count = 0;
                for (i = 0; i < m_BspHeader.CollBspHeader.chunkcount; i++)
                {
                    for (j = 0; j < m_pCollisions[i].BSP2DRef.chunkcount; j++)
                    {
                        offset = (m_pCollisions[i].BSP2DRef.offset + (8 * j));
                        [_mapfile seekToAddress:offset];
                        

                        [_mapfile readInt:&bsp2dref[hdr_count].plane];
                        [_mapfile readInt:&bsp2dref[hdr_count].node];
                        
                        hdr_count++;
                    }
                }
                
                hdr_count = 0;
                for (i = 0; i < m_BspHeader.CollBspHeader.chunkcount; i++)
                {
                    for (j = 0; j < m_pCollisions[i].Surfaces.chunkcount; j++)
                    {
                        offset = (m_pCollisions[i].Surfaces.offset + (12 * j));
                        [_mapfile seekToAddress:offset];
                        
                        
                        [_mapfile readInt:&surfaces[hdr_count].plane];
                        [_mapfile readInt:&surfaces[hdr_count].firstEdge];
                        [_mapfile readInt:&surfaces[hdr_count].SomeOtherstuffs];
                        
                        hdr_count++;
                    }
                }
                
                hdr_count = 0;
                for (i = 0; i < m_BspHeader.CollBspHeader.chunkcount; i++)
                {
                    for (j = 0; j < m_pCollisions[i].Edges.chunkcount; j++)
                    {
                        offset = (m_pCollisions[i].Edges.offset + (24 * j));
                        [_mapfile seekToAddress:offset];
                        
                        
                        [_mapfile readInt:&edges[hdr_count].startVertex];
                        [_mapfile readInt:&edges[hdr_count].endVertex];
                        [_mapfile readInt:&edges[hdr_count].forwardEdge];
                        [_mapfile readInt:&edges[hdr_count].reverseEdge];
                        [_mapfile readInt:&edges[hdr_count].leftFace];
                        [_mapfile readInt:&edges[hdr_count].rightFace];
                        
                        hdr_count++;
                    }
                }
			}
			else
			{
				unsigned long offset;
				int x, i, j, hdr_count;
				
				m_pCollisions = malloc(sizeof(BSP_COLLISION) * m_BspHeader.CollBspHeader.chunkcount);
				
				[_mapfile seekToAddress:m_BspHeader.CollBspHeader.offset];
				int col_mesh_count = 0;
				for (x = 0; x< m_BspHeader.CollBspHeader.chunkcount; x++)
				{
					[_mapfile readShort:&m_pCollisions[x].LightmapIndex];
					[_mapfile readShort:&m_pCollisions[x].unk1];
					[_mapfile skipBytes:0x0C-4];
					m_pCollisions[x].Material = [_mapfile readBspReflexive:_bspMagic]; //Verticies
					col_mesh_count += m_pCollisions[x].Material.chunkcount;
				}
				coll_count = col_mesh_count;
				coll_verts = malloc(col_mesh_count * sizeof(vert));
				hdr_count = 0;
				for (i = 0; i < m_BspHeader.CollBspHeader.chunkcount; i++)
				{
					for (j = 0; j < m_pCollisions[i].Material.chunkcount; j++)
					{
						offset = (m_pCollisions[i].Material.offset + (16 * j));
						[_mapfile seekToAddress:offset];
						
						
						long x;
						
						
						
						[_mapfile readLong:&(coll_verts[hdr_count].x)];
						
						[_mapfile readLong:&coll_verts[hdr_count].z];
						[_mapfile readLong:&coll_verts[hdr_count].edge];
						[_mapfile readLong:&coll_verts[hdr_count].y];
						
						
						
						
						hdr_count++;
					}
				}
			}
		}
		else
		{
			int i, v, x;
			SUBMESH_INFO *pPcSubMesh;
			[self ResetBoundingBox];
			
			int size;
			for (i =0; i < m_SubMeshCount; i++)
			{
				pPcSubMesh = &m_pMesh[i];
				pPcSubMesh->VertCount = pPcSubMesh->header.VertexCount1;
				size+=(pPcSubMesh->VertCount);
			}
			
			coll_count=size;
			coll_verts = malloc(size*sizeof(COMPRESSED_BSP_VERT));
			
			for (i =0; i < m_SubMeshCount; i++)
			{
				pPcSubMesh = &m_pMesh[i];
				pPcSubMesh->VertCount = pPcSubMesh->header.VertexCount1;
				pPcSubMesh->IndexCount = pPcSubMesh->header.VertIndexCount;
				
				// In Bob's words, "Allocate vertex and index arrays"
				pPcSubMesh->pIndex = malloc(pPcSubMesh->IndexCount * sizeof(TRI_INDICES));
				pPcSubMesh->pVert = malloc(pPcSubMesh->VertCount * sizeof(UNCOMPRESSED_BSP_VERT));
				pPcSubMesh->pCompVert = malloc(pPcSubMesh->VertCount * sizeof(COMPRESSED_BSP_VERT));
				pPcSubMesh->pLightmapVert = malloc(pPcSubMesh->VertCount * sizeof(UNCOMPRESSED_LIGHTMAP_VERT));
				
				[_mapfile seekToAddress:pPcSubMesh->header.VertexDataOffset];
				
				for (v = 0; v < pPcSubMesh->VertCount; v++)
					pPcSubMesh->pVert[v] = [_bspParent readUncompressedBspVert]; 
				for (v = 0; v < pPcSubMesh->VertCount; v++)
					pPcSubMesh->pLightmapVert[v] = [_bspParent readUncompressedLightmapVert]; 
				
				[_mapfile seekToAddress:pPcSubMesh->header.CompVert_Reflexive];
				for (v = 0; v < pPcSubMesh->VertCount; v++)
				{
					COMPRESSED_BSP_VERT verts = [_bspParent readCompressedBspVert]; 
					coll_verts[v].x= verts.vertex_k[0];
					coll_verts[v].y= verts.vertex_k[1];
					coll_verts[v].z= verts.vertex_k[2];
				}
			
				// OH GEE
				// In bob's words, "Update the map extents for analysis
		
			}
		}
		
	
}

-(int)coll_count
{
	return coll_count;
}

-(vert*)collision_verticies
{
	return coll_verts;
}

- (void)LoadMaterialMeshHeaders
{
	unsigned long offset;
	int x, i, j, hdr_count;
	
    NSLog(@"NUMBER OF LIGHTMAPS %d %d %d", sizeof(BSP_LIGHTMAP) * m_BspHeader.SubmeshHeader.chunkcount, sizeof(short), m_BspHeader.SubmeshHeader.offset);
	m_pLightmaps = malloc(sizeof(BSP_LIGHTMAP) * m_BspHeader.SubmeshHeader.chunkcount);
	
	[_mapfile seekToAddress:m_BspHeader.SubmeshHeader.offset];
	
    m_SubMeshCount = 0;
	for (x = 0; x< m_BspHeader.SubmeshHeader.chunkcount; x++)
	{
        
        
		[_mapfile readShort:&m_pLightmaps[x].LightmapIndex];
		[_mapfile readShort:&m_pLightmaps[x].unk1];
        
        NSLog(@"LIGHTMAP INDEX %d %d %d", (int)(m_pLightmaps[x].LightmapIndex), (int)(m_pLightmaps[x].LightmapIndex -1 ), sizeof(m_pLightmaps[x].LightmapIndex));
        
        
		[_mapfile skipBytes:(4 * sizeof(unsigned long))];
        
        
		m_pLightmaps[x].Material = [_mapfile readBspReflexive:_bspMagic];
		m_SubMeshCount += m_pLightmaps[x].Material.chunkcount;
        
        
        
        
	}
	NSLog(@"Complete. Loading verticies %d", m_SubMeshCount * sizeof(SUBMESH_INFO));
	m_pMesh = malloc(m_SubMeshCount * sizeof(SUBMESH_INFO));
	hdr_count = 0;
	for (i = 0; i < m_BspHeader.SubmeshHeader.chunkcount; i++)
	{
		for (j =0; j < m_pLightmaps[i].Material.chunkcount; j++)
		{
			offset = (m_pLightmaps[i].Material.offset + (sizeof(MATERIAL_SUBMESH_HEADER) * j));
			[_mapfile seekToAddress:offset];
			m_pMesh[hdr_count].header = [_bspParent readMaterialSubmeshHeader];
			
			m_pMesh[hdr_count].header.Vert_Reflexive -= _bspMagic;
			m_pMesh[hdr_count].header.CompVert_Reflexive -= _bspMagic;
			m_pMesh[hdr_count].header.VertexDataOffset -= _bspMagic;
			m_pMesh[hdr_count].header.PcVertexDataOffset -= _bspMagic;
			m_pMesh[hdr_count].header.VertIndexOffset = ((sizeof(TRI_INDICES) * m_pMesh[hdr_count].header.VertIndexOffset)
														 + m_BspHeader.SubmeshTriIndices.offset);
			m_pMesh[hdr_count].LightmapIndex = m_pLightmaps[i].LightmapIndex;
			hdr_count++;
		}
	}
    for (i = 0; i< m_BspHeader.SubmeshHeader.chunkcount; i++)
	{
        if (m_pLightmaps[i].LightmapIndex != -1 && [_mapfile isTag:m_BspHeader.LightmapsTag.TagId])
            [_texManager loadTextureOfIdent:m_BspHeader.LightmapsTag.TagId subImage:m_pLightmaps[i].LightmapIndex];
    }
    NSLog(@"Loading4");
}


- (void)getMapCentroid:(float *)center_x center_y:(float *)center_y center_z:(float *)center_z
{
	if (m_CentroidCount == 0)
	{
		*center_x = 0;
		*center_y = 0;
		*center_z = 0;
	}
	else
	{
		*center_x = (m_Centroid[0]/m_CentroidCount);
		*center_y = (m_Centroid[1]/m_CentroidCount);
		*center_z = (m_Centroid[2]/m_CentroidCount);
	}
}
- (void)UpdateBoundingBox:(int)mesh_index pCoord:(float *)pCoord version:(unsigned long)version
{
  if((mesh_index >= 0)&&(mesh_index <m_SubMeshCount))
  {
    //update total map extents
    if(pCoord[0] > m_MapBox.max[0])m_MapBox.max[0] = pCoord[0];
    if(pCoord[1] > m_MapBox.max[1])m_MapBox.max[1] = pCoord[1];
    if(pCoord[2] > m_MapBox.max[2])m_MapBox.max[2] = pCoord[2];

    if(pCoord[0] < m_MapBox.min[0])m_MapBox.min[0] = pCoord[0];
    if(pCoord[1] < m_MapBox.min[1])m_MapBox.min[1] = pCoord[1];
    if(pCoord[2] < m_MapBox.min[2])m_MapBox.min[2] = pCoord[2];

    m_Centroid[0] += pCoord[0];
    m_Centroid[1] += pCoord[1];
    m_Centroid[2] += pCoord[2];
    m_CentroidCount++;

    //update current mesh extents
    if(pCoord[0] > m_pMesh[mesh_index].Box.max[0])m_pMesh[mesh_index].Box.max[0] = pCoord[0];
    if(pCoord[1] > m_pMesh[mesh_index].Box.max[1])m_pMesh[mesh_index].Box.max[1] = pCoord[1];
    if(pCoord[2] > m_pMesh[mesh_index].Box.max[2])m_pMesh[mesh_index].Box.max[2] = pCoord[2];
    
    if(pCoord[0] < m_pMesh[mesh_index].Box.min[0])m_pMesh[mesh_index].Box.min[0] = pCoord[0];
    if(pCoord[1] < m_pMesh[mesh_index].Box.min[1])m_pMesh[mesh_index].Box.min[1] = pCoord[1];
    if(pCoord[2] < m_pMesh[mesh_index].Box.min[2])m_pMesh[mesh_index].Box.min[2] = pCoord[2];
  }
}
- (void)ResetBoundingBox
{
  m_MapBox.min[0] = 40000;
  m_MapBox.min[1] = 40000;
  m_MapBox.min[2] = 40000;
  m_MapBox.max[0] = -40000;
  m_MapBox.max[1] = -40000;
  m_MapBox.max[2] = -40000;

  m_Centroid[0] = 0;
  m_Centroid[1] = 0;
  m_Centroid[2] = 0;
  m_CentroidCount = 0;
  #ifdef __DEBUG__
  NSLog(@"Bounding box reset!");
  #endif
}
- (void)ExportPcMeshToObj:(NSString *)path
{
	FILE *outFile;
	NSString *str;
	int i, x, j;
	float vertex[3];
	long face[3];
	
	outFile = fopen([path cString],"wb+");
	if (!outFile)
	{
	}
	else
	{
		int base_count = 1;
		int vert_count = 1;
		
		for (i = 0; i < m_SubMeshCount; i++)
		{
			// lol thats tough
			//str = [str stringByAppendingString:[[[NSNumber numberWithInt:i] stringValue] stringByAppendingString:[NSString stringWithString:@"\n"]]];
			str = [NSString stringWithFormat:@"g Submesh_%d\n", i];
			//[str release];
			fwrite([str cString],[str cStringLength],1,outFile);
			for (x = 0; x < m_pMesh[i].VertCount; x++)
			{
				vertex[0] = m_pMesh[i].pVert[x].vertex_k[0];
				vertex[1] = m_pMesh[i].pVert[x].vertex_k[1];
				vertex[2] = m_pMesh[i].pVert[x].vertex_k[2];
				
				str = [NSString stringWithFormat:@"v %f %f %f\n", vertex[0], vertex[1], vertex[2]];
				fwrite([str cString],[str cStringLength],1,outFile);
				[str release];
				
				if ((x % 10) == 0)
				{
					str = [NSString stringWithFormat:@"#vertex %d %d (%d)\n", x, vert_count+=10, m_pMesh[i].VertCount];
					fwrite([str cString], [str cStringLength], 1, outFile);
					[str release];
				}
			}
			for (j = 0; j < m_pMesh[i].IndexCount; j++)
			{
				face[0] = m_pMesh[i].pIndex[j].tri_ind[0]+base_count;
				face[1] = m_pMesh[i].pIndex[j].tri_ind[1]+base_count;
				face[2] = m_pMesh[i].pIndex[j].tri_ind[2]+base_count;
		
				str = [NSString stringWithFormat:@"f %d %d %d\n", face[0], face[1], face[2]];
				fwrite([str cString], [str cStringLength], 1, outFile);
				[str release];
			}
			base_count += m_pMesh[i].VertCount;
		}
	}
	fclose(outFile);
}
/*
ExportPcMeshToObj(CString path)
{
  CStdioFile OutFile;
  CString str;
  int i,v,f;
  float vertex[3];
  UINT face[3];

  if(!OutFile.Open(path, CFile::modeCreate|CFile::modeWrite))
  {
    AfxMessageBox("Failed to create exported mesh file.");
  }
  else
  {
    int base_count=1;
    int vert_count=1;
    for(i=0; i<m_SubMeshCount; i++)
    {
      str.Format("g Submesh_%03d\n", i);
      OutFile.WriteString(str);

      for(v=0; v<m_pMesh[i].VertCount; v++)
      {
        vertex[0] = m_pMesh[i].pVert[v].vertex_k[0];
        vertex[1] = m_pMesh[i].pVert[v].vertex_k[1];
        vertex[2] = m_pMesh[i].pVert[v].vertex_k[2];

        str.Format("v %f %f %f\n", vertex[0], vertex[1], vertex[2]);
        OutFile.WriteString(str);

        if((v%10)==0)
        {
          str.Format("#vertex %d %d (%d)\n", v, vert_count+=10,m_pMesh[i].VertCount);
          OutFile.WriteString(str);
        }
      }

      for(f=0; f<m_pMesh[i].IndexCount; f++)
      {
        face[0] = m_pMesh[i].pIndex[f].tri_ind[0]+base_count;
        face[1] = m_pMesh[i].pIndex[f].tri_ind[1]+base_count;
        face[2] = m_pMesh[i].pIndex[f].tri_ind[2]+base_count;

        str.Format("f %d %d %d\n", face[0], face[1], face[2]);
        OutFile.WriteString(str);
      }
      base_count+=m_pMesh[i].VertCount;
    }    
  }

  OutFile.Close();
}
*/
@synthesize _mapfile;
@synthesize _bspParent;
@synthesize _texManager;
@synthesize m_SubMeshCount;
@synthesize _bspMagic;
@synthesize m_pMesh;
@synthesize m_pWeather;
@synthesize m_pLightmaps;
@synthesize m_pClusters;
@synthesize texturesLoaded;
@synthesize m_CentroidCount;
@synthesize m_activeBsp;
@synthesize m_TriTotal;
@end
