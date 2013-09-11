#import "BSPDefs.h"
#import "NSFile.h"

UNCOMPRESSED_BSP_VERT readUncompressedBspVert(NSFile *file)
{
	UNCOMPRESSED_BSP_VERT retVert;
	retVert.vertex_k[0] = [file readFloat];
	retVert.vertex_k[1] = [file readFloat];
	retVert.vertex_k[2] = [file readFloat];
	retVert.normal[0] = [file readFloat];
	retVert.normal[1] = [file readFloat];
	retVert.normal[2] = [file readFloat];
	retVert.binormal[0] = [file readFloat];
	retVert.binormal[1] = [file readFloat];
	retVert.binormal[2] = [file readFloat];
	retVert.tangent[0] = [file readFloat];
	retVert.tangent[1] = [file readFloat];
	retVert.tangent[2] = [file readFloat];
	retVert.uv[0] = [file readFloat];
	retVert.uv[1] = [file readFloat];
	return retVert;
}			
SCENARIO_BSP_INFO readBspInfoFromFile(NSFile *file)
{
	SCENARIO_BSP_INFO v;
	v.BspStart = [file readDword];
	v.BspSize = [file readDword];
	v.Magic = [file readDword];
	v.Zero1 = [file readDword];
	[file readIntoStruct:v.bsptag size:4];
	v.NamePtr = [file readDword];
	v.unknown2 = [file readDword];
	v.TagId = [file readDword];
	v.Magic -= v.BspStart;
	return v;
}
UNCOMPRESSED_LIGHTMAP_VERT readUncompressedLightmapVert(NSFile *file)
{
	UNCOMPRESSED_LIGHTMAP_VERT retLight;
	retLight.normal[0] = [file readFloat];
	retLight.normal[1] = [file readFloat];
	retLight.normal[2] = [file readFloat];
	retLight.uv[0] = [file readFloat];
	retLight.uv[1] = [file readFloat];
	return retLight;
}
TRI_INDICES readIndexFromFile(NSFile *file)
{

	TRI_INDICES tempTri;
	tempTri.tri_ind[0] = [file readWord];
	tempTri.tri_ind[1] = [file readWord];
	tempTri.tri_ind[2] = [file readWord];
	
	return tempTri;
}
MATERIAL_SUBMESH_HEADER readMaterialSubmeshHeader(NSFile *file, unsigned long magic)
{
	  MATERIAL_SUBMESH_HEADER retHeader;
	  retHeader.ShaderTag = readReferenceFromFile(file,magic);
	  retHeader.UnkZero2 = [file readDword];
	  retHeader.VertIndexOffset = [file readDword];
	  retHeader.VertIndexCount = [file readDword];
	  
	  retHeader.Centroid[0] = [file readFloat];
	  retHeader.Centroid[1] = [file readFloat];
	  retHeader.Centroid[2] = [file readFloat];
	  retHeader.AmbientColor[0] = [file readFloat];
	  retHeader.AmbientColor[1] = [file readFloat];
	  retHeader.AmbientColor[2] = [file readFloat];
	  retHeader.DistLightCount = [file readDword];
	  retHeader.DistLight1[0] = [file readFloat];
	  retHeader.DistLight1[1] = [file readFloat];
	  retHeader.DistLight1[2] = [file readFloat];
	  retHeader.DistLight1[3] = [file readFloat];
	  retHeader.DistLight1[4] = [file readFloat];
	  retHeader.DistLight1[5] = [file readFloat];
	  retHeader.DistLight2[0] = [file readFloat];
	  retHeader.DistLight2[1] = [file readFloat];
	  retHeader.DistLight2[2] = [file readFloat];
	  retHeader.DistLight2[3] = [file readFloat];
	  retHeader.DistLight2[4] = [file readFloat];
	  retHeader.DistLight2[5] = [file readFloat];
	  retHeader.unkFloat2[0] = [file readFloat];
	  retHeader.unkFloat2[1] = [file readFloat];
	  retHeader.unkFloat2[2] = [file readFloat];
	  retHeader.ReflectTint[0] = [file readFloat];
	  retHeader.ReflectTint[1] = [file readFloat];
	  retHeader.ReflectTint[2] = [file readFloat];
	  retHeader.ReflectTint[3] = [file readFloat];	
	  retHeader.ShadowVector[0] = [file readFloat];
	  retHeader.ShadowVector[1] = [file readFloat];
	  retHeader.ShadowVector[2] = [file readFloat];	 
	  retHeader.ShadowColor[0] = [file readFloat];
	  retHeader.ShadowColor[1] = [file readFloat];
	  retHeader.ShadowColor[2] = [file readFloat];
	  retHeader.Plane[0] = [file readFloat];
	  retHeader.Plane[1] = [file readFloat];
	  retHeader.Plane[2] = [file readFloat];
	  retHeader.Plane[3] = [file readFloat];
	  retHeader.UnkFlag2 = [file readDword];
	  retHeader.UnkCount1 = [file readDword];
	  retHeader.VertexCount1 = [file readDword];
	  retHeader.UnkZero4 = [file readDword];
	  retHeader.VertexOffset = [file readDword];
	  retHeader.Vert_Reflexive = [file readDword];
	  retHeader.UnkAlways3 = [file readDword];
	  retHeader.VertexCount2 = [file readDword];
	  retHeader.UnkZero9 = [file readDword];
	  retHeader.UnkLightmapOffset = [file readDword];
	  retHeader.CompVert_Reflexive = [file readDword];
	  retHeader.UnkZero5[0] = [file readDword];
	  retHeader.UnkZero5[1] = [file readDword];
	  retHeader.SomeOffset1 = [file readDword];
	  retHeader.PcVertexDataOffset = [file readDword];
	  retHeader.UnkZero6 = [file readDword];
	  retHeader.CompVertBufferSize = [file readDword];
	  retHeader.UnkZero7 = [file readDword];
	  retHeader.SomeOffset2 = [file readDword];
	  retHeader.VertexDataOffset = [file readDword];
	  retHeader.UnkZero8 = [file readDword];
	  return retHeader;
}