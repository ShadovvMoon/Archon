
#import <Cocoa/Cocoa.h>
#import "defines.h"

#import "HaloMap.h"
#import "MapTag.h"

@interface CollisionTag : MapTag
{
	HaloMap *_mapfile;
    reflexive nodeRef;
    
    GLfloat *point_array;
    GLuint total_point_count;
    GLuint *edge_array;
    GLuint total_edge_count;
    
    ModelTag *tied_model;
    reflexive mod_nodes;
    
    struct Coll_Node *nodes;
}
- (id)initWithMapFile:(HaloMap *)map;
-(void)drawAtPoint:(float*)position withModel:(ModelTag*)tag;
@end
