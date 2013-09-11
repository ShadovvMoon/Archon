//
//  BSPView.m
//  SparkEdit
//
//  Created by Michael Edgar on Tue Jul 20 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "BSPView.h"
#import "BspManager.h"
#import "BitmapTag.h"
#import "HaloMap.h"
#import "ModelTag.h"
#import "Camera.h"
#import "ScenarioTag.h"
#import "ScenarioDefs.h"
@implementation BSPView
- (void)setScenario:(ScenarioTag*)scenario
{
	myScenario = [scenario retain];
}
- (void)setManager:(BspManager*)manager
{
	myManager = [manager retain];
	float x,y,z;
	
	[myManager GetActiveBspCentroid:&x y:&y z:&z];
	[myCamera OnlySetPosition:x y:y z:z];
	[myCamera Look];
	[self setNeedsDisplay:YES];
}
- (void) reshape
{ 
   NSRect sceneBounds;
   

   sceneBounds = [ self bounds ];
   // Reset current viewport
   glViewport( 0, 0, sceneBounds.size.width, sceneBounds.size.height );
   glMatrixMode( GL_PROJECTION );   // Select the projection matrix
   glLoadIdentity();                // and reset it
   // Calculate the aspect ratio of the view
   myDistance = [[NSUserDefaults standardUserDefaults] floatForKey:@"GeneralDrawDistance"];
   if (myDistance == 0)
	{
		myDistance = 100.0f;
		[[NSUserDefaults standardUserDefaults] setFloat:myDistance forKey:@"GeneralDrawDistance"];
	}
   gluPerspective( 40.1f, sceneBounds.size.width / sceneBounds.size.height,
                   0.1f, myDistance );
   glMatrixMode( GL_MODELVIEW );    // Select the modelview matrix
   glLoadIdentity();                // and reset it
}
- (void)prepareOpenGL
{

		
            // Enable texture mapping
      glShadeModel( GL_SMOOTH );                // Enable smooth shading
	glClearColor( 0.0f, 0.0f, 0.0f, 0.1f );   // Black background
   glClearDepth( 1.0f );                     // Depth buffer setup
      glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
   glEnable( GL_DEPTH_TEST );                // Enable depth testing
   glDepthFunc( GL_LEQUAL );                 // Type of depth test to do
}
- (void)drawRect:(NSRect)aRect
{
		[[self openGLContext] makeCurrentContext];
		   glMatrixMode( GL_MODELVIEW );    // Select the modelview matrix
	   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
		glLoadIdentity();   // Reset the current modelview matrix
		[myCamera Look];
		[myCamera Update];
			
		//glBindTexture( GL_TEXTURE_2D , texture[0] );

		

		//RenderVisibleMesh
		
		unsigned long mesh_count;
		SUBMESH_INFO *pMesh;
		mesh_count = [myManager GetActiveBspSubmeshCount];
		[self ResetMeshColors];
		int i;
		for (i=0;i<mesh_count;i++)
		{
			pMesh = [myManager GetActiveBspPcSubmesh:i];
			
			if((m_RenderMode == RENDER_POINTS)||(m_RenderMode == RENDER_TRIS)||
				(m_RenderMode == RENDER_FLAT_SHADING))
			{
				[self SetNextMeshColor];
			}
			switch(m_RenderMode)
			{
				case RENDER_POINTS:
					[self RenderPcPoints:i];
					break;
				case RENDER_TRIS:
					glLineWidth(1.0f);
					[self RenderPcSubmeshLines:i];
					break;
				case RENDER_FLAT_SHADING:
					[self RenderPcFlatShadedPolygons:i];
					break;
				case RENDER_TEXTURED:
					[self RenderTexture:i];
					break;
			}
			
			//[self RenderLocation];

		}

		//done rendering BSP
	
		
		
		//render the vehicles
		long numVehi = [myScenario numberOfVehicleSpawns];
		VEHICLE_SPAWN *vehispawns = [myScenario vehiclespawns];
		int x;
		for (x=0;x<numVehi;x++)
			if ([self distanceToPoint:&vehispawns[x].x]<vehicleDrawDistance)
				[(ModelTag*)[[myManager myMap] modelForIdent:vehispawns[x].modelIdent] drawAtPoint:&vehispawns[x].x lod:4 withView:self index:x type:1 selected:vehispawns[x].selected moving:vehispawns[x].moving];
		
		//render the spawns
		long numPlayerSpawns = [myScenario numberOfPlayerSpawns];
		PLAYER_SPAWN *playerspawns = [myScenario playerspawns];
		for (x=0;x<numPlayerSpawns;x++)
			if ([self distanceToPoint:&playerspawns[x].x]<playerSpawnDrawDistance)
				[self drawPlayerSpawnAtPoint:&playerspawns[x].x team:playerspawns[x].team index:x selected:playerspawns[x].selected];
		//render the items
		long numItems = [myScenario numberOfMpItems];
		MP_EQUIP *itemspawns = [myScenario mpItems];
		for (x=0;x<numItems;x++)
			if ([self distanceToPoint:&itemspawns[x].x]<itemDrawDistance)
				[(ModelTag*)[[myManager myMap] modelForIdent:itemspawns[x].modelIdent] drawAtPoint:&itemspawns[x].x lod:4 withView:self index:x type:3 selected:itemspawns[x].selected moving:itemspawns[x].moving];

		//render the scenery
		long numScen = [myScenario numberOfScenerySpawns];
		SCENERY_SPAWN *scenspawns = [myScenario sceneryspawns];
		
		for (x=0;x<numScen;x++)
			if ([self distanceToPoint:&scenspawns[x].coord[0]]<sceneryDrawDistance)
				[(ModelTag*)[[myManager myMap] modelForIdent:scenspawns[x].modelIdent] drawAtPoint:&scenspawns[x].coord[0] lod:4 withView:self index:x type:2 selected:scenspawns[x].selected moving:scenspawns[x].moving];
		glFlush();
		

}
- (void)RenderPcSubmeshLines:(unsigned long)mesh_index
{
  SUBMESH_INFO *pMesh;
  int i;

  pMesh = [myManager GetActiveBspPcSubmesh:mesh_index];
  
  glBegin(GL_LINES);
  for(i = 0; i < pMesh->IndexCount; i++)
  {
    glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[0]].vertex_k));
    glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[1]].vertex_k));
    glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[1]].vertex_k));
    glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[2]].vertex_k));
    glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[2]].vertex_k));
    glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[0]].vertex_k));
  }
  glEnd();
}
- (void)RenderTexture:(unsigned long) mesh_index
{
  SUBMESH_INFO *pMesh;
  
  pMesh = [myManager GetActiveBspPcSubmesh:mesh_index];
  if (glIsList(1000+mesh_index))
	glCallList(1000+mesh_index);
  else
  {
	glNewList(1000+mesh_index,GL_COMPILE);
	
  if(pMesh->ShaderIndex == -1)
  {
    glColor3f(0.1f, 0.1f, 0.1f);
    [ self RenderPcSubmeshLines:mesh_index];
  }
  else
  {
	glBindTexture( GL_TEXTURE_2D, pMesh->textures[0] );
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,GL_REPEAT);
	
	glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER, GL_LINEAR);

	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
	//glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB_EXT, GL_REPLACE);
	glEnable(GL_TEXTURE_2D);
    //gShaderManager.ActivateSingleTexture(pMesh->RenderTextureIndex);

    glColor3f(1,1,1);
    glVertexPointer(3, GL_FLOAT, 56, pMesh->pVert[0].vertex_k);

    //pglClientActiveTextureARB(GL_TEXTURE0_ARB); 
    glTexCoordPointer(2, GL_FLOAT, 56, pMesh->pVert[0].uv); 
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);

    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glDrawElements(GL_TRIANGLES, pMesh->IndexCount*3, GL_UNSIGNED_SHORT, pMesh->pIndex);

    glDisableClientState(GL_VERTEX_ARRAY);
    //pglClientActiveTextureARB(GL_TEXTURE0_ARB); 
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisable(GL_TEXTURE_2D);
  }
  glEndList();
  glCallList(1000+mesh_index);
  }
}
- (void)RenderPcFlatShadedPolygons:(unsigned long)mesh_index
{
  SUBMESH_INFO *pMesh;
  int i;

  pMesh = [myManager GetActiveBspPcSubmesh:mesh_index];
  
  glBegin(GL_TRIANGLES);
  for(i = 0; i < pMesh->IndexCount; i++)
  {
    glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[0]].vertex_k));
    glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[1]].vertex_k));
    glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[2]].vertex_k));
  }
		
  glEnd();


}
- (float)distanceToPoint:(float*)point
{
	float *point2 = [myCamera position];
	return sqrt(((point2[0]-point[0]) * (point2[0]-point[0])) + ((point2[1]-point[1]) * (point2[1]-point[1])) + ((point2[2]-point[2]) * (point2[2]-point[2])));
}
- (void)RenderPcPoints:(unsigned long)mesh_index
{
  SUBMESH_INFO *pMesh;
  int i;

  pMesh = [myManager GetActiveBspPcSubmesh:mesh_index];
  glBegin(GL_POINTS);
  for(i = 0; i < pMesh->IndexCount; i++)
  {
    glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[0]].vertex_k));
    glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[1]].vertex_k));
    glVertex3fv((float *)(pMesh->pVert[pMesh->pIndex[i].tri_ind[2]].vertex_k));
  }
  glEnd();
}
- (void)awakeFromNib
{   
	m_LastSelectionPos[0] = m_LastSelectionPos[1] = m_LastSelectionPos[2] = 0;
	playerSpawnDrawDistance = [[NSUserDefaults standardUserDefaults] floatForKey:@"PlayerSpawnDrawDistance"];
	if (playerSpawnDrawDistance == 0)
	{
		playerSpawnDrawDistance = 50.0f;
		[[NSUserDefaults standardUserDefaults] setFloat:playerSpawnDrawDistance forKey:@"PlayerSpawnDrawDistance"];
	}
	itemDrawDistance = [[NSUserDefaults standardUserDefaults] floatForKey:@"ItemDrawDistance"];
	if (itemDrawDistance == 0)
	{
		itemDrawDistance = 50.0f;
		[[NSUserDefaults standardUserDefaults] setFloat:itemDrawDistance forKey:@"ItemDrawDistance"];
	}
	vehicleDrawDistance = [[NSUserDefaults standardUserDefaults] floatForKey:@"VehicleDrawDistance"];
	if (vehicleDrawDistance == 0)
	{
		vehicleDrawDistance = 50.0f;
		[[NSUserDefaults standardUserDefaults] setFloat:vehicleDrawDistance forKey:@"VehicleDrawDistance"];
	}
	sceneryDrawDistance = [[NSUserDefaults standardUserDefaults] floatForKey:@"SceneryDrawDistance"];
	if (sceneryDrawDistance == 0)
	{
		sceneryDrawDistance = 50.0f;
		[[NSUserDefaults standardUserDefaults] setFloat:sceneryDrawDistance forKey:@"SceneryDrawDistance"];
	}
		//zoom = -3;
	m_RenderMode = RENDER_TEXTURED;
	myCamera = [[Camera alloc] init];
	moveSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"MoveSize"];
	if (moveSize == 0)
	{
		moveSize = 0.1f;
		[[NSUserDefaults standardUserDefaults] setFloat:moveSize forKey:@"MoveSize"];
	}
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(preferencesChanged)
		name:NSUserDefaultsDidChangeNotification
		object:[NSUserDefaults standardUserDefaults]];

}
- (void)drawPlayerSpawnAtPoint:(float*)point team:(long)team index:(long)index selected:(bool)selected
{
	if (selected)
		glColor3f(0.0f,1.0f,0.0f);
	if (!selected)
		if (team==0)
			glColor3f(1.0f,0.0f,0.0f);
		else if (team == 1)
			glColor3f(0.0f,0.0f,1.0f);
	if (glIsList(TYPE_PLAYERSPAWN * 15000 + index))
		glCallList(TYPE_PLAYERSPAWN * 15000 + index);
	else
	{
		glNewList(TYPE_PLAYERSPAWN * 15000 + index,GL_COMPILE);
		
	glPushMatrix();
	glTranslatef(point[0],point[1],point[2]);
	glRotatef(point[3] * 57.29577951f,0,0,1);
	
			

	glBegin(GL_QUADS);
		glVertex3f(0.2f,0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,0.1f);
		glVertex3f(-0.2f,-0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,0.1f);
		
		glVertex3f(0.2f,0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,-0.1f);
		glVertex3f(0.2f,0.2f,-0.1f);
		
		glVertex3f(-0.2f,-0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,0.1f);
		glVertex3f(0.2f,-0.2f,-0.1f);
		glVertex3f(-0.2f,-0.2f,-0.1f);
		
		glVertex3f(-0.2f,-0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,-0.1f);
		glVertex3f(-0.2f,-0.2f,-0.1f);
		
		glVertex3f(0.2f,0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,0.1f);
		glVertex3f(-0.2f,0.2f,-0.1f);
		glVertex3f(0.2f,0.2f,-0.1f);
		
		glVertex3f(0.2f,0.2f,-0.1f);
		glVertex3f(0.2f,-0.2f,-0.1f);
		glVertex3f(-0.2f,-0.2f,-0.1f);
		glVertex3f(-0.2f,0.2f,-0.1f);
	glEnd();
	glPopMatrix();
	glFlush();
	glEndList();
		glCallList(TYPE_PLAYERSPAWN * 15000 + index);
	}
}
	
- (void)setRenderMode:(short)newmode
{
	m_RenderMode = newmode;
}
- (void)preferencesChanged
{
	[self reshape];
	moveSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"MoveSize"];
	vehicleDrawDistance = [[NSUserDefaults standardUserDefaults] floatForKey:@"VehicleDrawDistance"];
	sceneryDrawDistance = [[NSUserDefaults standardUserDefaults] floatForKey:@"SceneryDrawDistance"];
	itemDrawDistance = [[NSUserDefaults standardUserDefaults] floatForKey:@"ItemDrawDistance"];
	playerSpawnDrawDistance = [[NSUserDefaults standardUserDefaults] floatForKey:@"PlayerSpawnDrawDistance"];
	[self setNeedsDisplay:YES];
}
- (void)keyDown:(NSEvent *)theEvent
{
	NSString *result = [theEvent characters];

	switch([result characterAtIndex:0])
	{
		case 'w':
			[myCamera MoveCamera:moveSize];
			[self setNeedsDisplay:YES];
			break;
		case 's':
			[myCamera MoveCamera:-1 * moveSize];
			[self setNeedsDisplay:YES];
			break;
		case ' ':
			[myCamera LevitateCamera:moveSize];
			[self setNeedsDisplay:YES];
			break;
		case 'c':
			[myCamera LevitateCamera:-1 * moveSize];
			[self setNeedsDisplay:YES];
			break;
		case 'd':
			[myCamera StrafeCamera:moveSize];
			[self setNeedsDisplay:YES];
			break;
		case 'a':
			[myCamera StrafeCamera:-1 * moveSize];
			[self setNeedsDisplay:YES];
			break;
		case 'q':
			[myCamera RotateView:0.04 x:0 y:0 z:1.0];
			[self setNeedsDisplay:YES];
			break;
		case 'e':
			[myCamera RotateView:-0.04 x:0 y:0 z:1.0];
			[self setNeedsDisplay:YES];
			break;
				
		
	}

	
}
- (void)SetNextMeshColor
{
  /* Select the color for this mesh */ 
  if(m_PolyColor.red < 0.2)
    m_PolyColor.red = 1;
  if(m_PolyColor.blue < 0.2)
    m_PolyColor.blue = 1;
  if(m_PolyColor.green < 0.2)
    m_PolyColor.green = 1;
  
  if((m_PolyColor.color_count%3)==0)
    m_PolyColor.red -= 0.1f;
  
  if((m_PolyColor.color_count%3)==1)
    m_PolyColor.blue -= 0.1f;
  
  if((m_PolyColor.color_count%3)==2)
    m_PolyColor.green -= 0.1f;
  
  m_PolyColor.color_count++;
  
  glColor3f(m_PolyColor.red, m_PolyColor.green, m_PolyColor.blue);
}
- (void)mouseUp:(NSEvent *)event
{
	if (mode == TRANSLATE_MODE)
		[myScenario resetMoving];
}
- (void)mouseDown:(NSEvent *)event
{
	downPoint = [NSEvent mouseLocation];
	if (mode == SELECT_MODE)
	{
		NSPoint p = [event locationInWindow];
		//hoo boy here we go
		[self pickInstance:p.x y:p.y shift:(([event modifierFlags] & NSShiftKeyMask) != 0)];
		//that was tough
		
		
	}
}
- (void)pickInstance:(long)px y:(long)y shift:(BOOL)shift
{
	px -= 49;
	y -= 72;
	y = abs(y - [self bounds].size.height);
	GLuint hits[1024];
	GLint viewport[4];
	GLuint name_lookup[1024];
	GLuint currentname = 1;
	glGetIntegerv (GL_VIEWPORT, viewport);
	glSelectBuffer( 1024, hits );
    //  OpenGL select mode does not need lighting, depth test and culling is used
    (void)glRenderMode( GL_SELECT );
    glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
    glInitNames();
    glPushName( 0 );
    glCullFace( GL_BACK );
    glEnable( GL_CULL_FACE );
    glEnable( GL_DEPTH_TEST );
    glDisable( GL_LIGHTING );
    glMatrixMode (GL_PROJECTION);
    glPushMatrix ();
    glLoadIdentity ();
    gluPickMatrix((GLdouble) px, (GLdouble) (viewport[3] - y),  5.0, 5.0, viewport);
	NSRect sceneBounds;
   

	sceneBounds = [ self bounds ];
       gluPerspective( 40.1f, sceneBounds.size.width / sceneBounds.size.height,
                   0.1f, myDistance );
    glMatrixMode(GL_MODELVIEW);
    
    //render the stuff
    		//render the vehicles
		long numVehi = [myScenario numberOfVehicleSpawns];
		VEHICLE_SPAWN *vehispawns = [myScenario vehiclespawns];
		int x;
		for (x=0;x<numVehi;x++)
			if ([self distanceToPoint:&vehispawns[x].x]<vehicleDrawDistance)
			{
				name_lookup[currentname]=1 * 15000 + x;
				
				glLoadName(currentname);
				currentname++;
				[(ModelTag*)[[myManager myMap] modelForIdent:vehispawns[x].modelIdent] drawAtPoint:&vehispawns[x].x lod:4 withView:self index:x type:1 selected:vehispawns[x].selected moving:vehispawns[x].moving];
		
		    }
		//render the spawns
		long numPlayerSpawns = [myScenario numberOfPlayerSpawns];
		PLAYER_SPAWN *playerspawns = [myScenario playerspawns];
		for (x=0;x<numPlayerSpawns;x++)
			if ([self distanceToPoint:&playerspawns[x].x]<playerSpawnDrawDistance)
			{
				name_lookup[currentname]=4 * 15000 + x;
				
			     glLoadName(currentname);
				 currentname++;
				[self drawPlayerSpawnAtPoint:&playerspawns[x].x team:playerspawns[x].team index:x selected:playerspawns[x].selected];
            }
		//render the items
		long numItems = [myScenario numberOfMpItems];
		MP_EQUIP *itemspawns = [myScenario mpItems];
		for (x=0;x<numItems;x++)
			if ([self distanceToPoint:&itemspawns[x].x]<itemDrawDistance)
			{
				name_lookup[currentname]=3 * 15000 + x;
				
			    glLoadName(currentname);
				currentname++;
				[(ModelTag*)[[myManager myMap] modelForIdent:itemspawns[x].modelIdent] drawAtPoint:&itemspawns[x].x lod:4 withView:self index:x type:3 selected:itemspawns[x].selected moving:itemspawns[x].moving];
            }
		//render the scenery
		long numScen = [myScenario numberOfScenerySpawns];
		SCENERY_SPAWN *scenspawns = [myScenario sceneryspawns];
		
		for (x=0;x<numScen;x++)
			if ([self distanceToPoint:&scenspawns[x].coord[0]]<sceneryDrawDistance)
			{
				name_lookup[currentname]=2 * 15000 + x;
				
			    glLoadName(currentname);
				currentname++;
				[(ModelTag*)[[myManager myMap] modelForIdent:scenspawns[x].modelIdent] drawAtPoint:&scenspawns[x].coord[0] lod:4 withView:self index:x type:2 selected:scenspawns[x].selected moving:scenspawns[x].moving];
            }
    
        GLuint num_hits = glRenderMode( GL_RENDER );
		[self reshape];
        GLuint *ptr = hits;
        GLuint  names;
        GLuint  z_min;
        GLuint  z_max;
        GLuint  hit_name;
        GLuint  nearest = 0xffffffff;
        unsigned long selection;
		int i,j;
        for(i=0; i<num_hits; i++ ){
                names = *ptr++;
                z_min = *ptr++;
                z_max = *ptr++;
                for(j=0; j<names; j++ ){
                        hit_name = *ptr++;
                        if( z_min<nearest ){
                                nearest = z_min;
                                selection =  name_lookup[hit_name];
                        }
                }
        }
        [myScenario setSelection:selection add:shift];
		glCullFace( GL_NONE );
		[self reshape];
		[self setNeedsDisplay:YES];
}
- (void)mouseDragged:(NSEvent *)event
{
	if (mode == ROTATE_CAMERA_MODE)
	{
		NSPoint mousePos = [NSEvent mouseLocation];
		// Get the direction the mouse moved in, but bring the number down to a reasonable amount
		[myCamera HandleMouseMove:mousePos.x-downPoint.x dy:mousePos.y-downPoint.y];
		downPoint = [NSEvent mouseLocation];
		[self setNeedsDisplay:YES];
	}
	if([myScenario isObjectSelected])
	{
		if(mode == TRANSLATE_MODE)
		{
			[self PerformTranslationEdit:event];
		}
	}
}
- (void)PerformTranslationEdit:(NSEvent *)event
{
	NSPoint p = [NSEvent mouseLocation];
	float deltax,deltay;
	float move_x,move_y,move_z;
	deltax = p.x - downPoint.x;
	deltay = p.y - downPoint.y;
	if (([event modifierFlags] & NSControlKeyMask)>0)
	{
		//x-y movement
		move_x = deltax * 0.1;
		move_z = deltay * 0.1;
		move_y = 0.0f;
		
		
	}
	else
	{

		//x-z movement
		move_x = deltax * 0.1;
		move_y = deltay * 0.1;
		move_z = 0.0f;
	}
	downPoint = p;
	[myScenario moveSelection:move_x move_y:move_y move_z:move_z rotz:0 roty:0 rotx:0 enableAcc:FALSE];
	[self setNeedsDisplay:YES];
}
/*- (void)PerformTranslationEdit:(NSEvent *)event
{
	float move_x = 0;
	float move_y = 0;
	float move_z = 0;
	float ox,oy,oz;
	float *cam_pos;
	float sel_pos[3];
	float obj_pos[6];

	ox = 0;
	oy = 0;
	oz = 0;
	
	NSPoint point = [event locationInWindow];
	long x,y;
	x = point.x - 49;
	y = point.y - 72;
	point.x -= 49;
	point.y -= 72;
	
	
	
	[myCamera DoUnProject:x ifY:y ofObjX:&ox ofObjY:&oy ofObjZ:&oz ifZ:0.5 ibUseZ:FALSE];

	cam_pos = [myCamera position];

	if ([event modifierFlags] & NSControlKeyMask)
	{
    	//do calculation to determine selection plane intersect point for XZ plane
        if((cam_pos[1] - oy) != 0)
        {
            float u = (cam_pos[1] - obj_pos[1])/(cam_pos[1] - oy);
            
            sel_pos[0] = cam_pos[0] + u*(ox - cam_pos[0]);
            sel_pos[1] = cam_pos[1] + u*(oy - cam_pos[1]);
            sel_pos[2] = cam_pos[2] + u*(oz - cam_pos[2]);
            
            move_x = 0;
            move_y = 0;
            move_z = sel_pos[2] - m_LastSelectionPos[2];
        }
    }
    else //X-Y Object Movement
    {
      //do calculation to determine selection plane intersect point for XY plane
        if((cam_pos[2] - oz) != 0)
        {
            float u = (cam_pos[2] - obj_pos[2])/(cam_pos[2] - oz);
            
            sel_pos[0] = cam_pos[0] + u*(ox - cam_pos[0]);
            sel_pos[1] = cam_pos[1] + u*(oy - cam_pos[1]);
            sel_pos[2] = cam_pos[2] + u*(oz - cam_pos[2]);
            
            move_x = sel_pos[0] - m_LastSelectionPos[0];
            move_y = sel_pos[1] - m_LastSelectionPos[1];
            move_z = 0;
        }
    }

    m_LastSelectionPos[0] = sel_pos[0];
    m_LastSelectionPos[1] = sel_pos[1];
    m_LastSelectionPos[2] = sel_pos[2];
    [myScenario moveSelection:move_x move_y:move_y move_z:move_z rotz:0 roty:0 rotx:0 enableAcc:FALSE];
	[self setNeedsDisplay:YES];
}*/
- (void) ResetMeshColors
{
	m_PolyColor.red = 1.0;
	m_PolyColor.green = 1.0;
	m_PolyColor.blue = 1.0;
	m_PolyColor.color_count = 0;
}
- (void)increaseZoom:(float)inc
{
	zoom += inc;
	[self setNeedsDisplay:YES];
}
- (void)scrollWheel:(NSEvent *)theEvent
{
	[self increaseZoom:(float)[theEvent deltaY] * 1.0f];
}
- (IBAction)changeMode:(id)sender
{
	if (sender == rotateCamButton)
	{
		mode = ROTATE_CAMERA_MODE;
		[selectButton setState:NSOffState];
		[translateButton setState:NSOffState];
	}
	else if (sender == selectButton)
	{
		mode = SELECT_MODE;
		[rotateCamButton setState:NSOffState];
		[translateButton setState:NSOffState];
	}
	else if (sender == translateButton)
	{
		mode = TRANSLATE_MODE;
		[rotateCamButton setState:NSOffState];
		[selectButton setState:NSOffState];
	}
}
- (void)RotateX:(float)x
{
	[myCamera RotateView:x x:1.0 y:0.0 z:0.0];
	[self setNeedsDisplay:YES];
}
- (void)RotateY:(float)y
{
	[myCamera RotateView:y x:0.0 y:1.0 z:0.0];
	[self setNeedsDisplay:YES];
}
- (void)RotateZ:(float)z
{
	[myCamera RotateView:z x:0.0 y:0.0 z:1.0];
	[self setNeedsDisplay:YES];
}
@end
