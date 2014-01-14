//
//  ModelTag.m
//  swordedit
//
//  Created by sword on 5/11/08.
//

#import "CollisionTag.h"
#import "TextureManager.h"
#import "RenderView.h"

@implementation CollisionTag
- (id)initWithMapFile:(HaloMap *)map
{
    self = [super initWithDataFromFile:map];
	if (self != nil)
	{
		//Read all of the collision data
        int i;
        
        _mapfile = [map retain];
        [_mapfile seekToAddress:resolvedOffset + 0x28C];
        
        nodeRef = [_mapfile readReflexive];
        nodes = malloc(nodeRef.chunkcount * sizeof(struct Coll_Node));
        
        total_point_count = 0;
        total_edge_count = 0;
        for (i = 0; i < nodeRef.chunkcount; i++)
		{
            [_mapfile seekToAddress:nodeRef.offset + 0x34 + 64*i];
            reflexive bsp = [_mapfile readReflexive];
            int g;
            for (g=0; g<bsp.chunkcount; g++)
            {
                long bsp_offset = bsp.offset + 96*g;
                
                [_mapfile seekToAddress:bsp_offset + 0x54];
                reflexive verts = [_mapfile readReflexive];
                total_point_count+=verts.chunkcount*3;
                [_mapfile seekToAddress:bsp_offset + 0x48];
                reflexive edges = [_mapfile readReflexive];
                total_edge_count+=edges.chunkcount*2;
            }
        }
        
        //Create the arrays
        point_array = malloc(total_point_count * sizeof(GLfloat));
        edge_array  = malloc(total_edge_count * sizeof(GLuint));
        
        int current_point = 0;
        int current_edge = 0;
		for (i = 0; i < nodeRef.chunkcount; i++)
		{
            [_mapfile seekToAddress:nodeRef.offset + 0x34 + 64*i];
            reflexive bsp = [_mapfile readReflexive];
            float x,y,z;
            int start,end;
            
            int g;
            for (g=0; g<bsp.chunkcount; g++)
            {
                long bsp_offset = bsp.offset + 96*g;
                
                [_mapfile seekToAddress:bsp_offset + 0x54];
                reflexive verts = [_mapfile readReflexive];
                [_mapfile seekToAddress:bsp_offset + 0x48];
                reflexive edges = [_mapfile readReflexive];
                int v;

                
                for (v=0; v < edges.chunkcount; v++)
                {
                    long location = edges.offset + v * sizeof(struct Edges);
                    [_mapfile readIntAtAddress:&start address:location];
                    [_mapfile readIntAtAddress:&end   address:location+4];
                    
                    edge_array[current_edge]    = start + current_point;
                    edge_array[current_edge+1]  = end   + current_point;
                    current_edge+=2;
                }
                
                
                for (v=0; v < verts.chunkcount; v++)
                {
                    long location = verts.offset + v * sizeof(struct Verticies);
                    [_mapfile readFloatAtAddress:&x address:location];
                    [_mapfile readFloatAtAddress:&y address:location+4];
                    [_mapfile readFloatAtAddress:&z address:location+8];
                    
                    point_array[current_point+0] = x;
                    point_array[current_point+1] = y;
                    point_array[current_point+2] = z;
                    current_point+=3;
                }
            }
            
            nodes[i].bsp   = bsp;
        }
	}
    
    
	return self;
}

-(void)positioningFromNode:(int)my_node
{
    if (!tied_model || mod_nodes.offset == -1 || mod_nodes.chunkcount <= 0 || my_node < 0 || my_node >= mod_nodes.chunkcount)
        return;
    
    int16_t parent_node;
    
    long location = mod_nodes.offset + my_node * 156 + 0x24;
    [_mapfile read:&parent_node size:2];
    
    if (parent_node != my_node)
    {
        //[self positioningFromNode:parent_node];
    }
    
    //Search for pathfinding spheres related to this node
    float xo = 0.0f;
    float yo = 0.0f;
    float zo = 0.0f;
    
    float r1o = 0.0f;
    float r2o = 0.0f;
    float r3o = 0.0f;
    float r4o = 0.0f;
    
    if (tied_model && mod_nodes.offset != -1 && my_node < mod_nodes.chunkcount && mod_nodes.chunkcount > 0)
    {
        location = mod_nodes.offset + my_node * 156 + 0x28;
        [_mapfile readFloatAtAddress:&xo address:location];
        [_mapfile readFloatAtAddress:&yo address:location+4];
        [_mapfile readFloatAtAddress:&zo address:location+8];
        
        location = mod_nodes.offset + my_node * 156 + 0x34;
        [_mapfile readFloatAtAddress:&r1o address:location];
        [_mapfile readFloatAtAddress:&r2o address:location+4];
        [_mapfile readFloatAtAddress:&r3o address:location+8];
        [_mapfile readFloatAtAddress:&r4o address:location+12];
    
        glTranslatef(xo,yo,zo);
        glRotatef(r1o, r2o, r3o, r4o);
    }
    
    
    
    
    
    
}

-(void)drawAtPoint:(float*)point withModel:(ModelTag*)tag
{
    tied_model = tag;
    
    /*
    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_BLEND);
    */
    
    
    long location;
    float x,y,z;
    int16_t node;
    int32_t start, end;
    
    [_mapfile seekToAddress:resolvedOffset + 0x280];
    reflexive path_finding = [_mapfile readReflexive];
    
    if (tag)
    {
        [_mapfile seekToAddress:[tag offsetInMap] + 0xB8];
        mod_nodes = [_mapfile readReflexive];
    }
    
    if (nodeRef.chunkcount < 1)
        return;
    
    
    glUseProgram(0);
    glColor4f(1.0, 1.0, 1.0, 1.0);
    
    glActiveTexture(GL_TEXTURE0);
    glDisable(GL_TEXTURE_2D);
    glActiveTexture(GL_TEXTURE1);
    glDisable(GL_TEXTURE_2D);
    glActiveTexture(GL_TEXTURE2);
    glDisable(GL_TEXTURE_2D);
    glActiveTexture(GL_TEXTURE3);
    glDisable(GL_TEXTURE_2D);
    
    glEnableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_NORMAL_ARRAY);
    glLineWidth(2.0);
    
    int current_drawing = 0;
    int g;
    int currentEdge = 0;
    
    int i;
    for (i=0; i < 1; i++)//nodeRef.chunkcount; i++)
    {
        
        glPushMatrix();
        glTranslatef(point[0],point[1],point[2]);
        
        glColor4f(1.0f,1.0f,1.0f, 1.0f);
        glLineWidth(2.0);
        
        /* Perform rotation */
        glRotatef(point[5] * (57.29577951), 1, 0, 0);
        glRotatef(-point[4] * (57.29577951), 0, 1, 0);
        glRotatef(point[3] * (57.29577951), 0, 0, 1);

        [self positioningFromNode:i];
        
        reflexive bsp = nodes[i].bsp;


        for (g=0; g<bsp.chunkcount; g++)
        {
            long bsp_offset = bsp.offset + 96*g;
            
            [_mapfile seekToAddress:bsp_offset + 0x54];
            reflexive verts = [_mapfile readReflexive];
            
            [_mapfile seekToAddress:bsp_offset + 0x48];
            reflexive edges = [_mapfile readReflexive];
            
            [_mapfile seekToAddress:bsp_offset + 0x0C];
            reflexive planes = [_mapfile readReflexive];
            
#ifdef IMMEDIATE_MODE
            glBegin(GL_LINES);
            {
                int v;
                for (v=0; v < edges.chunkcount; v++)
                {
                    location = edges.offset + v * sizeof(struct Edges);
                    [_mapfile readFloatAtAddress:&start address:location];
                    [_mapfile readFloatAtAddress:&end   address:location+4];
                    
                    //Find the coordinates for these vertices
                    location = verts.offset + start * sizeof(struct Verticies);
                    [_mapfile readFloatAtAddress:&x address:location];
                    [_mapfile readFloatAtAddress:&y address:location+4];
                    [_mapfile readFloatAtAddress:&z address:location+8];
                    glVertex3f(x,y,z);
                    
                    location = verts.offset + end * sizeof(struct Verticies);
                    [_mapfile readFloatAtAddress:&x address:location];
                    [_mapfile readFloatAtAddress:&y address:location+4];
                    [_mapfile readFloatAtAddress:&z address:location+8];
                    glVertex3f(x,y,z);
                }
            }
            glEnd();
#else
            glVertexPointer(3, GL_FLOAT, 0, point_array);
            glDrawElements(GL_LINES, edges.chunkcount*2, GL_UNSIGNED_INT, &edge_array[currentEdge]);
            currentEdge+=edges.chunkcount*2;
            
            /*
            //glEnable(GL_BLEND);
            //glColor4f(1.0, 1.0, 1.0, 0.2);
            glBegin(GL_TRIANGLES);
            {
                float a,b,c,d;
                int v;
                for (v=0; v < planes.chunkcount; v++)
                {
                    location = planes.offset + v * sizeof(struct Plane);
                    [_mapfile readFloatAtAddress:&a   address:location];
                    [_mapfile readFloatAtAddress:&b   address:location+4];
                    [_mapfile readFloatAtAddress:&c   address:location+8];
                    [_mapfile readFloatAtAddress:&d   address:location+12];

                    //http://www.gamedev.net/topic/340803-drawing-a-plane-as-a-quad/
                    
                    float big_number = 1000.0;
                    if (b == 0.0 && c == 0.0) //x = d/a
                    {
                        glVertex3f(d/a,+big_number,+big_number);
                        glVertex3f(d/a,-big_number,-big_number);
                        glVertex3f(d/a,+big_number,-big_number);
                        glVertex3f(d/a,+big_number,+big_number);
                        glVertex3f(d/a,-big_number,-big_number);
                        glVertex3f(d/a,-big_number,+big_number);
                    }
                    else if (a == 0.0 && c == 0.0) //x = d/a
                    {
                        glVertex3f(+big_number,d/a,+big_number);
                        glVertex3f(-big_number,d/a,-big_number);
                        glVertex3f(+big_number,d/a,-big_number);
                        glVertex3f(+big_number,d/a,+big_number);
                        glVertex3f(-big_number,d/a,-big_number);
                        glVertex3f(-big_number,d/a,+big_number);
                    }
                    else if (a == 0.0 && b == 0.0) //x = d/a
                    {
                        glVertex3f(+big_number,+big_number, d/a);
                        glVertex3f(-big_number,-big_number, d/a);
                        glVertex3f(+big_number,-big_number, d/a);
                        glVertex3f(+big_number,+big_number, d/a);
                        glVertex3f(-big_number,-big_number, d/a);
                        glVertex3f(-big_number,+big_number, d/a);
                    }
                    else
                    {
                        glVertex3f(d/a,0.0,0.0);
                        glVertex3f(0.0,d/b,0.0);
                        glVertex3f(0.0,0.0,d/c);
                    }
                }
            }
            glEnd();
            glColor4f(1.0, 1.0, 1.0, 1.0);
             */
#endif
        }
        
        
        glPopMatrix();
    }
    
    if (!legacyMode)
        activateNormalProgram();
    
    
    /*
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_BLEND);
     */
}
@end
