@class NSFile;
#import "FileConstants.h"
typedef struct STRUCT_MODEL_REGION_PERMUTATION
{
  char Name[32];
  unsigned long Flags[8];
  short LOD_MeshIndex[5];
  short Reserved[7];
}MODEL_REGION_PERMUTATION;
typedef struct STRUCT_MODEL_REGION
{
  char Name[64];
  reflexive Permutations;
  
  MODEL_REGION_PERMUTATION *permutations;
}MODEL_REGION;


MODEL_REGION readModelRegionFromFile(NSFile *file,unsigned long magic);