#import "NSFile.h"
#import "ModelDefs.h"


MODEL_REGION readModelRegionFromFile(NSFile *file,unsigned long magic)
{
	MODEL_REGION reg;
	[file readIntoStruct:&reg.Name size:64];
	reg.Permutations = readReflexiveFromFile(file,magic);
	unsigned long currentOffset = [file offset];
	[file seekToOffset:reg.Permutations.offset];
	reg.permutations = malloc(reg.Permutations.chunkcount * sizeof(MODEL_REGION_PERMUTATION));
	int x,y;
	for (x=0;x<reg.Permutations.chunkcount;x++)
	{
		[file readIntoStruct:&reg.permutations[x].Name size:32];
		[file skipBytes:8*sizeof(unsigned long)];
		for (y=0;y<5;y++)
			reg.permutations[x].LOD_MeshIndex[y] = [file readWord];
		[file skipBytes:7*4];
	}
	[file seekToOffset:currentOffset];
	return reg;
}