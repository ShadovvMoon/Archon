//
//  HaloMap.m
//  swordedit
//
//  Created by Fred Havemeyer on 5/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "HaloMap.h"
#import "Scenario.h"
#import "BSP.h"
#import "ModelTag.h"
#import "BitmapTag.h"
#import "CollisionTag.h"

#import "TextureManager.h"

#define IndexTagSize	-32

#define EndianSwap64(x) (((x & 0xFF00000000000000) >> 56) | ((x & 0x00FF000000000000) >> 40) | ((x & 0x0000FF0000000000) >> 24) | ((x & 0x000000FF00000000) >> 8) | ((x & 0x00000000FF000000) << 8) | ((x & 0x0000000000FF0000) << 24) | ((x & 0x000000000000FF00) << 40) |    ((x & 0x00000000000000FF) << 56))
#define EndianSwap32(x) (((x & 0xFF000000) >> 24) | ((x & 0x00FF0000) >> 8) | ((x & 0x0000FF00) << 8) | ((x & 0x000000FF) << 24))
#define EndianSwap16(x) (((x & 0x00FF) << 8) | ((x & 0xFF00) >> 8))




@implementation HaloMap
- (id)init
{
	if ((self = [super init]) != nil)
	{
	}
	return self;
}
- (id)initWithMapdata:(NSData *)map_data bitmaps:(NSString *)bitmaps
{
	if ((self = [super init]) != nil)
	{
		mapName = @"";
		bitmapFilePath = [bitmaps retain];
        
        // Quick hack
        isPPC = NO;
        
        globalMapSize = [map_data length];
        map_memory = malloc(globalMapSize);
        memcpy(map_memory, [map_data bytes], globalMapSize);
        
        dataReading=YES;
    }
	return self;
}
- (id)initWithMapfiles:(NSString *)mapfile bitmaps:(NSString *)bitmaps
{
	if ((self = [super init]) != nil)
	{
		mapName = [mapfile retain];
		bitmapFilePath = [bitmaps retain];
	}
	return self;
}
- (void)destroy
{	
	[self closeMap];

	[tagArray removeAllObjects];
	[tagLookupDict removeAllObjects];
	[itmcList removeAllObjects];
	[itmcLookupDict removeAllObjects];
	[scenList removeAllObjects];
	[scenLookupDict removeAllObjects];
	[scenNameLookupDict removeAllObjects];
	[modTagList removeAllObjects];
	[modTagLookupDict removeAllObjects];
	[bitmTagList removeAllObjects];
	[bitmTagLookupDict removeAllObjects];
	
	[mapName release];
	[bitmapFilePath release];
	[tagArray release];
	[tagLookupDict release];
	[itmcList release];
	[itmcLookupDict release];
	[scenList release];
	[scenLookupDict release];
	[scenNameLookupDict release];
	[modTagList release];
	[modTagLookupDict release];
	[bitmTagList release];
	[bitmTagLookupDict release];
	
	[_texManager deleteAllTextures];
	[bspHandler destroyObjects];
	
	[_texManager release];
	[mapScenario release];
	[bspHandler release];
}
- (void)dealloc
{
	#ifdef __DEBUG__
	CSLog(@"Mapfile deallocating!");
	#endif
	
	[super dealloc];
}
- (BOOL)checkIsPPC
{
    return NO;
#ifdef MACVERSION
	return (CFByteOrderGetCurrent() == CFByteOrderBigEndian);
#endif
   return NO;
}
/*
	@function loadMap, the actual map-loading function for the HaloMap class.
	
	Returns in the following manner:
		0 = successful load
		1 = lol dongs?
		2 = The map name is invalid
		3 = Could not open map
*/

-(ModelTag*)bipd
{
    return bipd;
}
-(NSMutableArray*)tagIdArray
{
    return tagIdArray;
}
-(NSMutableArray*)plugins
{
    return plugins;
}
int comp(const int32_t *a, const int32_t *b)
{
    if (*a == *b)
        return 0;
    else if (*a < *b)
        return -1;
    else
        return 1;
}
-(void)setVertexSize:(float)size
{
    //Update the index head
    //indexHead.vertex_size = size;
    // Index time!
    [self readint32_tAtAddress:&indexHead.indexMagic address:mapHeader.offsetToIndex];
    [self readint32_t:&indexHead.starting_id];
    [self readint32_t:&indexHead.vertexsize];
    [self readint32_t:&indexHead.tagcount];
    [self readint32_t:&indexHead.vertex_object_count];
    [self readint32_t:&indexHead.vertex_offset];
    [self readint32_t:&indexHead.indices_object_count];
    [self readint32_t:&indexHead.vertex_size];
    [self readint32_t:&indexHead.modelsize];
    [self readint32_t:&indexHead.tagstart];
}
-(int32_t)globalMapSize
{
    return globalMapSize;
}

-(void)setGlobalMapSize:(int32_t)size
{
    globalMapSize = size;
}
-(void)setGlobalMemory:(char*)newMem
{
    map_memory = newMem;
}
-(char*)globalMemory
{
    return map_memory;
}
-(int)readMap
{
    // Quick hack
	isPPC = NO;
	
	// Use this for computing the tag location, mmk?
	if (mapName == nil)
    return 2;
	
	mapFile = fopen([mapName cStringUsingEncoding:NSMacOSRomanStringEncoding],"rb+");
	CSLog(@"Opening map");
    
    
    if (mapFile == NULL)
    {
        NSLog(@"Invalid map file %@", mapName);
        return 2;
    }
    
#ifdef MEMORY_READING
    fseek(mapFile, 0L, SEEK_END);
    globalMapSize = ftell(mapFile);
    fseek(mapFile, 0L, SEEK_SET);
    map_memory = malloc(globalMapSize);
    fread(map_memory, 1, globalMapSize, mapFile);
#endif
    CSLog(@"Loaded map into memory");
    
	if (!mapFile)
	{
		CSLog(mapName);
		CSLog(@"Cannot read map.");
		return 3;
	}
    
}

- (int)loadMap
{
    if (!dataReading && mapFile == NULL)
        return 2;
    
    //CSLog(bitmapFilePath);
	
	bitmapsFile = fopen([bitmapFilePath cString], "rb+");
	
	// Lets load the map header, ok?
	[self readint32_tAtAddress:&mapHeader.map_id address:0x0];
	
	//#ifdef __DEBUG__
	printf("\n");
	//CSLog(@"Header: 0x%x, swapped: 0x%x", mapHeader.map_id, EndianSwap32(mapHeader.map_id));
	//#endif
	
	/* LETS SEE WHAT DIS IS */
	isPPC = [self checkIsPPC];
	/* SO IS IT PPC OR NOT?! */
	
	// Reload the map header
	[self readint32_tAtAddress:&mapHeader.map_id address:0x0];
	
	BOOL tmpPPC = isPPC;
	
	int super_mode = 0;
    int32_t mapLocation;
	//CSLog(@"MAP ID: %d", (int)mapHeader.map_id);
	if (mapHeader.map_id == 0x18309 || mapHeader.map_id == 50028 || mapHeader.map_id == 0x0 || super_mode)
	{
		mapHeader.version = 0x06000000;
		isPPC = NO;
		[self readBlockOfDataAtAddress:&mapHeader.builddate size_of_buffer:0x20 address:0x2C8]; // Map seeked to 0x2C4 now.
		[self readBlockOfDataAtAddress:&mapHeader.name size_of_buffer:0x20 address:0x58C];
		isPPC = tmpPPC;
		[self readint32_tAtAddress:&mapHeader.map_length address:0x5E8];
		[self readint32_t:&mapHeader.offsetToIndex];
		mapHeader.maptype = 0x01000000;
	}
	else
	{
		[self readint32_t:&mapHeader.version]; //Check for halo2
		[self readint32_t:&mapHeader.map_length]; //Check for halo2
		[self readint32_t:&mapHeader.zeros]; //Not sure
        
        mapLocation = [self currentOffset];
        
        #ifdef __DEBUG__
        CSLog(@"INDEX OFFSET LOCATION 0x%lx", mapLocation);
#endif
        
		[self readint32_t:&mapHeader.offsetToIndex];
		[self readint32_t:&mapHeader.metaSize];
        
        if (mapHeader.version == 8) //Halo 2
        {
            [self skipBytes:396];
            
            isPPC = NO;
            [self readBlockOfData:&mapHeader.name size_of_buffer:0x20];
            [self readBlockOfData:&mapHeader.builddate size_of_buffer:0x20];
            isPPC = tmpPPC;
            [self readint32_t:&mapHeader.maptype];
            
        }
        else //Halo 1
        {
            [self skipBytes:8];
        
            isPPC = NO;
            [self readBlockOfData:&mapHeader.name size_of_buffer:0x20];
            [self readBlockOfData:&mapHeader.builddate size_of_buffer:0x20];
            isPPC = tmpPPC;
            [self readint32_t:&mapHeader.maptype];
        }
        
	}
	
	#ifdef __DEBUG__
	CSLog(@"File Header Version: 0x%x", mapHeader.version);
	CSLog(@"File Length: 0x%x", mapHeader.map_length);
	CSLog(@"Offset To Index: 0x%x", mapHeader.offsetToIndex);
	CSLog(@"Total Metadata Size: 0x%x", mapHeader.metaSize);
    CSLog(@"Map type: 0x%x", mapHeader.maptype);
    
	CSLog(@"File Name: %s \n", (char *)mapHeader.name);
	CSLog(@"Build Date: %s \n", (char *)mapHeader.builddate);
	#endif
    
    if (mapHeader.version == 8) //Halo 2
    {
        [self readint32_tAtAddress:&indexHead.indexMagic address:mapHeader.offsetToIndex];
        [self readint32_t:&indexHead.tagcount];
        [self readint32_t:&indexHead.vertex_offset];
        [self skipBytes:0x4]; //scenarioId
        [self readint32_t:&indexHead.starting_id];
        [self skipBytes:0x4]; //unknown
        [self readint32_t:&indexHead.vertex_object_count];
        [self skipBytes:0x4]; //tags
    }
    else
    {
        // Index time!
        [self readint32_tAtAddress:&indexHead.indexMagic address:mapHeader.offsetToIndex];
        [self readint32_t:&indexHead.starting_id];
        [self readint32_t:&indexHead.vertexsize];
        
        mapLocation = [self currentOffset];
        
        #ifdef __DEBUG__
        CSLog(@"TAG COUNT COUNT 0x%lx", mapLocation);
#endif
        
        [self readint32_t:&indexHead.tagcount];
        
        #ifdef __DEBUG__
        CSLog(@"TAG COUNT %ld", indexHead.tagcount);
#endif
        
        [self readint32_t:&indexHead.vertex_object_count];
        [self readint32_t:&indexHead.vertex_offset];
        
        mapLocation = [self currentOffset];
        
        #ifdef __DEBUG__
        CSLog(@"INDEX COUNT 0x%lx", mapLocation);
#endif
        
        [self readint32_t:&indexHead.indices_object_count];
        [self readint32_t:&indexHead.vertex_size];
        [self readint32_t:&indexHead.modelsize];
        [self readint32_t:&indexHead.tagstart];
    }
	
    /*
    CSLog(@"Offset To Index: 0x%x", mapHeader.offsetToIndex);
	CSLog(@"Tag count: %d", indexHead.tagcount);
	CSLog(@"Tag starting id: 0x%x", indexHead.starting_id);
    CSLog(@"Tag starting: %d", indexHead.tagstart);
    */
    
    
	_magic = (indexHead.indexMagic - (mapHeader.offsetToIndex + 40));
	
	#ifdef __DEBUG__
	CSLog(@"Magic: [0x%x]", _magic);
    CSLog(@"Index Offset: [0x%x]", mapHeader.offsetToIndex);
    
    //0x40440000
    
    //indexHead.indexMagic = 0x40440028;
    //_magic = (indexHead.indexMagic - 0x40440000);
	//CSLog(@"New Magic: [0x%x]", _magic);
    CSLog(@"Primary Magic: [0x%x]", indexHead.indexMagic);
    
    
    
	printf("\n");
	#endif
    
    
	//0x1400000
    int32_t offset = 0x40440000;
    if (mapHeader.version == 8) //Halo 2
    {
        offset=0x1400000;
    }
    
    
    //Beat the protection
    int32_t someOffset = offset-mapHeader.offsetToIndex;
    int32_t newOffset = indexHead.indexMagic-someOffset;
    
    if (mapHeader.version == 8) //Halo 2
    {
        newOffset = someOffset;
    }
    

    [self seekToAddress:newOffset];
    
    #ifdef __DEBUG__
    CSLog(@"NEW OFFSET 0x%lx", newOffset);
#endif
    
	// Now lets create and load our tag arrays
    originalTagCount = indexHead.tagcount;
    
    #ifdef __DEBUG__
    CSLog(@"Capacity3 %ld 0x%lx", indexHead.tagcount);
    
#endif
    
	tagArray = [[NSMutableArray alloc] initWithCapacity:indexHead.tagcount];
	tagLookupDict = [[NSMutableDictionary alloc] initWithCapacity:indexHead.tagcount];
    
    #ifdef __DEBUG__
	CSLog(@"Capacity2");
#endif
    
	// Create our texture manager
	_texManager = [[TextureManager alloc] init];
	
	// Now I'm going to create a temporary tag pointer
	// We'll use this when loading... stuff
	MapTag *tempTag;
	
	int i,
		vehi_count = 0,
		scen_count = 0,
		itmc_count = 0,
		mach_count = 0,
		mod2_count = 0,
        coll_count = 0,
		bitm_count = 0,
		nextOffset,
		scenario_offset,
		globals_offset,
		itmc_counter = 0,
		scen_counter = 0,
		mod2_counter = 0,
        coll_counter = 0,
		bitm_counter = 0,
		mach_counter = 0;
		
	NSMutableArray *mach_offsets = [[NSMutableArray alloc] init];
	plugins = [[NSMutableArray alloc] init];
    //tagIdArray = [[NSMutableArray alloc] init];
    
    tagFastArray = malloc(sizeof(int32_t)*indexHead.tagcount);
    tagArraySize = 0;
    
    char *cleaned = malloc(4);
    int scnrTag = 0;
    int32_t tagLocation;
	for (i = 0; i < indexHead.tagcount; i++)
	{
        
		int r = 1;
        tagLocation=[self currentOffset];
		tempTag = [[MapTag alloc] initWithDataFromFile:self];
		nextOffset = [self currentOffset];
		
        #ifdef __DEBUG__
        CSLog(@"%d/%ld %.4s %@ 0x%lx 0x%lx 0x%lx", i, indexHead.tagcount, [tempTag tagClassHigh], [tempTag tagName], [tempTag offsetInMap], tagLocation, [self _magic]);
#endif
        
		//CSLog(@"Tag name: %@, id: 0x%x, offset in map: 0x%x offset in mapfile: 0x%x  %@", [tempTag tagName], [tempTag idOfTag], [tempTag offsetInMap],[self currentOffset], [NSString stringWithCString:[tempTag tagClassHigh] encoding:NSMacOSRomanStringEncoding]);
	
		if (i != 0)//Surely theres a better methid?
        {
            
            if ([[tagArray objectAtIndex:(i - 1)] offsetInMap] > [tempTag offsetInMap])
            {
                //Stupid 002's protection
                //CSLog(@"Protected");
                //[[tagArray objectAtIndex:(i -1)] setTagLength:([[tagArray objectAtIndex:(i - 1)] offsetInMap]-[tempTag offsetInMap])];
            }
            else
                [[tagArray objectAtIndex:(i -1)] setTagLength:([tempTag offsetInMap] - [[tagArray objectAtIndex:(i - 1)] offsetInMap])];
		}
        
      
        memcpy(cleaned, [tempTag tagClassHigh], 4);
        
        NSString *cleanedStr = [NSString stringWithCString:cleaned encoding:NSMacOSRomanStringEncoding];
        
        if (cleanedStr)
            [plugins addObject:cleanedStr];
        
        tagFastArray[i] = [tempTag idOfTag];
        //[tagIdArray addObject:[NSNumber numberWithLong:[tempTag idOfTag]]];
    
		if (memcmp([tempTag tagClassHigh], (isPPC ? "scnr" : "rncs"), 4) == 0)
		{
			[self skipBytes:IndexTagSize];
			scenario_offset = [self currentOffset];
			// I'll load the scenario later
			[tagArray addObject:tempTag];
            scnrTag = [tagArray count]-1;
			[self seekToAddress:nextOffset];
		}
		else if (memcmp([tempTag tagClassHigh], (isPPC ? "matg" : "gtam"), 4) == 0)
		{
			//CSLog(@"GLOBALS ARRAY");
			[self skipBytes:IndexTagSize];
			globals_offset = [self currentOffset];
			// I'll load the scenario later
			[tagArray addObject:tempTag];
			[self seekToAddress:nextOffset];
		}
        /*
        else if (memcmp([tempTag tagClassHigh], (isPPC ? "bipd" : "dpib"), 4) == 0)
		{
            [self skipBytes:IndexTagSize];
			scenario_offset = [self currentOffset];
			// I'll load the scenario later
			[tagArray addObject:tempTag];
			[self seekToAddress:nextOffset];
        }*/
		else if (memcmp([tempTag tagClassHigh], (isPPC ? "mod2" : "2dom"), 4) == 0)
		{
			[self skipBytes:IndexTagSize];
			ModelTag *tempModel = [[ModelTag alloc] initWithMapFile:self texManager:_texManager];
            [tagArray addObject:tempModel];
			mod2_count++;
			[self seekToAddress:nextOffset];
		}
        else if (memcmp([tempTag tagClassHigh], (isPPC ? "coll" : "lloc"), 4) == 0)
		{
			[self skipBytes:IndexTagSize];
			CollisionTag *tempModel = [[CollisionTag alloc] initWithMapFile:self];
            [tagArray addObject:tempModel];
			coll_count++;
			[self seekToAddress:nextOffset];
		}
		else if (memcmp([tempTag tagClassHigh], (isPPC ? "bitm" : "mtib"), 4) == 0)
		{
			[self skipBytes:IndexTagSize];
            
			BitmapTag *tempBitmap = [[BitmapTag alloc] initWithMapFiles:self
														bitmap:bitmapsFile
														ppc:isPPC];
            
            
    
                [tagArray addObject:tempBitmap];
                [tempBitmap release];
                    
                // Increment our counter
                bitm_count++;
          
			
			
			
			[self seekToAddress:nextOffset];
		}
		else if (memcmp([tempTag tagClassHigh], (isPPC ? "mach" : "hcam"), 4) == 0)
		{
			mach_count++;
			[tagArray addObject:tempTag];
			[mach_offsets addObject:tempTag];
			[self seekToAddress:nextOffset];
			
			r=0;
		}
		else
		{
			if (memcmp([tempTag tagClassHigh], (isPPC ? "vehi" : "ihev"), 4) == 0)
			{
				vehi_count++;
			}
			else if (memcmp([tempTag tagClassHigh], (isPPC ? "scen" : "necs"), 4) == 0)
			{
				scen_count++;
			}
			else if (memcmp([tempTag tagClassHigh], (isPPC ? "itmc" : "cmti"), 4) == 0)
			{
				itmc_count++;
			}
			[tagArray addObject:tempTag];
		}
		
        
        
		// Add the identity of the tag to the lookup dictionary
		[tagLookupDict setObject:[NSNumber numberWithInt:i] forKey:[NSNumber numberWithLong:[tempTag idOfTag]]];
		
		// Here is where we'd add text to a view, mmk?
		
		// Now we release our temporary tag
		if (r)
			[tempTag release];
	}

    //Sort the array. Used for rapid tag extraction.
    qsort(tagFastArray, indexHead.tagcount, sizeof(int32_t), comp);
    tagArraySize = indexHead.tagcount;
    
    #ifdef __DEBUG__
    CSLog(@"Capacity1");
#endif
    
	// Its texture manager time!
	[_texManager setCapacity:bitm_count];
	
	// Now lets quickly make our scenario item list
	itmcList = [[NSMutableArray alloc] initWithCapacity:itmc_count];
	itmcLookupDict = [[NSMutableDictionary alloc] initWithCapacity:itmc_count];
	scenList = [[NSMutableArray alloc] initWithCapacity:scen_count];
	scenLookupDict = [[NSMutableDictionary alloc] initWithCapacity:scen_count];
	scenNameLookupDict = [[NSMutableDictionary alloc] initWithCapacity:scen_count];
	modTagList = [[NSMutableArray alloc] initWithCapacity:mod2_count];
	modTagLookupDict = [[NSMutableDictionary alloc] initWithCapacity:mod2_count];
	bitmTagList = [[NSMutableArray alloc] initWithCapacity:bitm_count];
	bitmTagLookupDict = [[NSMutableDictionary alloc] initWithCapacity:bitm_count];
	machList = [[NSMutableArray alloc] initWithCapacity:itmc_count];
	machLookupDict = [[NSMutableDictionary alloc] initWithCapacity:itmc_count];
	NSMutableArray* bipdList = [[NSMutableArray alloc] initWithCapacity:itmc_count];
	/*
		Second pass here to create some arrays
	*/
	[self seekToAddress:(mapHeader.offsetToIndex + 0x28)];
    CSLog(@"Loaded tag array");
    
    int32_t tagOffset;
	for (i = 0; i < indexHead.tagcount; i++)
	{
		int r = 1;
        tagOffset = [self currentOffset];
        
		tempTag = [[MapTag alloc] initWithDataFromFile:self];
		
		if (memcmp([tempTag tagClassHigh],(isPPC ? "itmc" : "cmti"),4) == 0)
		{
			[itmcLookupDict setObject:[NSNumber numberWithLong:[tempTag idOfTag]] forKey:[NSNumber numberWithInt:itmc_counter]];
			[itmcList addObject:[tempTag tagName]];
			itmc_counter++;
		}
		else if (memcmp([tempTag tagClassHigh],(isPPC ? "mach" : "hcam"),4) == 0)
		{
			[machLookupDict setObject:[NSNumber numberWithLong:[tempTag idOfTag]] forKey:[NSNumber numberWithInt:mach_counter]];
			[machList addObject:[tempTag tagName]];
			mach_counter++;
			r=0;
		}
        else if (memcmp([tempTag tagClassHigh], (isPPC ? "bipd" : "dpib"), 4) == 0)
        {
            [tempTag retain];
            [bipdList addObject:tempTag];
        }
		else if (memcmp([tempTag tagClassHigh], (isPPC ? "scen" : "necs"), 4) == 0)
		{
			[scenLookupDict setObject:[NSNumber numberWithLong:[tempTag idOfTag]] forKey:[NSNumber numberWithInt:scen_counter]];
			[scenNameLookupDict setObject:[NSNumber numberWithLong:[tempTag idOfTag]] forKey:[tempTag tagName]];
			[scenList addObject:[tempTag tagName]];
			scen_counter++;
		}
		else if (memcmp([tempTag tagClassHigh], (isPPC ? "mod2" : "2dom"), 4) == 0)
		{
            NSNumber *idOfTag = [NSNumber numberWithLong:(long)[tempTag idOfTag]];
            NSNumber *key = [NSNumber numberWithInt:mod2_counter];
            
			//[modTagLookupDict setObject:idOfTag forKey:key];
			[modTagList addObject:[tempTag tagName]];
			mod2_counter++;
		}
        else if (memcmp([tempTag tagClassHigh], (isPPC ? "coll" : "lloc"), 4) == 0)
		{
            NSNumber *idOfTag = [NSNumber numberWithLong:(long)[tempTag idOfTag]];
            NSNumber *key = [NSNumber numberWithInt:mod2_counter];
            
			//[modTagLookupDict setObject:idOfTag forKey:key];
			//[modTagList addObject:[tempTag tagName]];
			coll_counter++;
		}
		else if (memcmp([tempTag tagClassHigh], (isPPC ? "bitm" : "mtib"), 4) == 0)
		{
			[bitmTagLookupDict setObject:[NSNumber numberWithLong:[tempTag idOfTag]] forKey:[NSNumber numberWithInt:bitm_counter]];
			[bitmTagList addObject:[tempTag tagName]];
			
            if (i < [tagArray count])
            {
                #ifdef __DEBUG__
                CSLog(@"BITMAP %@ %ld", [[tagArray objectAtIndex:i] tagName], tagOffset);
#endif
                
                [_texManager addTexture:[tagArray objectAtIndex:i]];
                
                bitm_counter++;
            }
		}
		
		if (r)
			[tempTag release];
	}
    CSLog(@"Loaded tags");
    

    //Third pass
    int32_t current = [self currentOffset];
    int g;
    for (g = 0; g < [bipdList count]; g++)
	{
		tempTag = [bipdList objectAtIndex:g];
		
        if (memcmp([tempTag tagClassHigh], (isPPC ? "bipd" : "dpib"), 4) == 0)
        {
            
            int32_t modelOffset =  [tempTag offsetInMap] + 0x28;
            [self seekToAddress:modelOffset];
            
            TAG_REFERENCE ref = [self readReference];
            
            ModelTag*tag = (ModelTag *)[self tagForId:ref.TagId];
            
            if ([tag respondsToSelector:@selector(loadAllBitmaps)])
                [tag loadAllBitmaps];
            
            bipd = tag; //0x28
            [bipd retain];
            
            
        }
    }
    [self seekToAddress:current];
    
	// Next we load the scenario
	
	USEDEBUG CSLog(@"Loading map...");
	[self seekToAddress:scenario_offset];
    USEDEBUG CSLog(@"Allocating");
	mapScenario = [[Scenario alloc] initWithMapFile:self];
	//USEDEBUG CSLog([tagArray description]);
    
    globalScenarioOffset+=scenario_offset;
    USEDEBUG CSLog(@"Tag count: %d", [tagArray count]);
    USEDEBUG CSLog(@"%d", [[tagArray objectAtIndex:scnrTag] tagLength]);
	[mapScenario setTagLength:[[tagArray objectAtIndex:scnrTag] tagLength]];

#ifdef __DEBUG__
	if ([mapScenario loadScenario])
		CSLog(@"Scenario Loaded!");
	#else
	[mapScenario loadScenario];
	#endif
	[mapScenario pairModelsWithSpawn];
	[tagArray replaceObjectAtIndex:0 withObject:mapScenario];
	CSLog(@"Loaded bitmaps");
    
    
	// Then we load the BSP
	bspHandler = [[BSP alloc] initWithMapFile:self texManager:_texManager];
	[bspHandler loadVisibleBspInfo:[mapScenario header].StructBsp version:mapHeader.version];
	[bspHandler setActiveBsp:0];
	
    CSLog(@"Loaded BSP");
    
    
	if ([mapScenario mach_ref_count] < mach_counter)
	{
		int response = NSRunAlertPanel(@"Machines detected", @"Swordedit has detected machinery tags which are not referenced in the scenario. Would you like to rebuild references?", @"No", @"OK", nil);
		if (response != NSOKButton)
		{
		
			[mapScenario resetMachineReferences];
			
			CSLog(@"CREATING MACHINE REFERENCES");
			//CREATE THE MACHINE REFERENCES
			CSLog(@"Total machines... %d", [mach_offsets count]);
			for (i=0; i<[mach_offsets count];i++)
			{
				MapTag *tag = [mach_offsets objectAtIndex:i];
                CSLog([tag stringTagClassHigh]);
                
				TAG_REFERENCE machine;
				
				machine.tag[0] = 'h';
				machine.tag[1] = 'c';
				machine.tag[2] = 'a';
				machine.tag[3] = 'm';
				
                machine.unknown = 0;
				machine.NamePtr = [tag stringOffset];
				machine.TagId = [tag idOfTag];
				
				CSLog(@"Creating reference %d", i);
				
				[mapScenario createMachineReference:machine];
			}
			
		}
	}
	
	
	/*CSLog(@"BSPs are loaded!");
	printf("\n");
	
	CSLog(@"Scenery spawn count: %d", [mapScenario scenery_spawn_count]);
	CSLog(@"Vehicle spawn count: %d", [mapScenario vehicle_spawn_count]);
	CSLog(@"Item spawn count: %d", [mapScenario item_spawn_count]);
	CSLog(@"Player spawn count: %d", [mapScenario player_spawn_count]);
	CSLog(@"Machine spawn count: %d", [mapScenario mach_spawn_count]);*/
    
    
	//CSLog([machLookupDict description]);
	// Now lets load all of the bitmaps for shit
    
    if ([self respondsToSelector:@selector(loadAllBitmaps)])
    {
        //CSLog(@"LOADING BITMAPS");
        [self loadAllBitmaps];
    }
	CSLog(@"Loaded bitmaps again");
    
    
    BOOL skipImageGeneration = YES;
    
    if (skipImageGeneration)
    {
        CSLog(@"Skipping image generation");
    }
    else
    {
        
    
    //New object images
    //Generate a 128x128 image for this object.
    [[NSFileManager defaultManager] removeItemAtPath:@"/tmp/Archon/scen" error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:@"/tmp/Archon/scen" withIntermediateDirectories:YES attributes:Nil error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:@"/tmp/Archon/vehi" withIntermediateDirectories:YES attributes:Nil error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:@"/tmp/Archon/mach" withIntermediateDirectories:YES attributes:Nil error:nil];
    
    int m;
    for (m=0; m < [mapScenario scen_ref_count]; m++)
    {
        NSString *name = [[self tagForId:[mapScenario scen_references][m].scen_ref.TagId] tagName];
        int32_t modelIdent = [mapScenario baseModelIdent:[mapScenario scen_references][m].scen_ref.TagId];
        ModelTag *model = [self tagForId:modelIdent];
        
        if ([model respondsToSelector:@selector(generateImage:)])
        [model generateImage:[NSString stringWithFormat:@"/tmp/Archon/scen/%@.tiff", name]];
    }
    
    for (m=0; m < [mapScenario vehi_ref_count]; m++)
    {
        NSString *name = [[self tagForId:[mapScenario vehi_references][m].vehi_ref.TagId] tagName];
        int32_t modelIdent = [mapScenario baseModelIdent:[mapScenario vehi_references][m].vehi_ref.TagId];
        ModelTag *model = [self tagForId:modelIdent];
        
        if ([model respondsToSelector:@selector(generateImage:)])
        [model generateImage:[NSString stringWithFormat:@"/tmp/Archon/vehi/%@.tiff", name]];
    }
    
    for (m=0; m < [mapScenario mach_ref_count]; m++)
    {
        NSString *name = [[self tagForId:[mapScenario mach_references][m].machTag.TagId] tagName];
        int32_t modelIdent = [mapScenario baseModelIdent:[mapScenario mach_references][m].machTag.TagId];
        ModelTag *model = [self tagForId:modelIdent];
        
        if ([model respondsToSelector:@selector(generateImage:)])
        [model generateImage:[NSString stringWithFormat:@"/tmp/Archon/mach/%@.tiff", name]];
    }
    
    [renderV updateObjectTable];
    CSLog(@"Generated images");
    
    }
	//CSLog(@"LOGGING THE TARG INFO");
	//CSLog([tagArray description]);

    CSLog(@"Finished reading");
	return 0;
}

-(void)rebuildTagArrayToPath:(NSString*)filename withDataAtIndexes:(int32_t*)insertEnd lengths:(int32_t*)dataLength offsets:(int)tagdatacount flipped:(BOOL)isFlipped isChangingData:(BOOL)changingIndex
{
    #ifdef __DEBUG__
    CSLog(@"REBUILDING TAG ARRAY");
    CSLog(@"%ld %d", indexHead.tagcount, [tagArray count]);
#endif
    
    //Increase map size by 8
    int32_t mapSize;
    [self readint32_tAtAddress:&mapSize address:0x8];
    
    int32_t total_new_data = 0;
    int g;
    for (g=0; g < tagdatacount; g++)
    {
        mapSize+=dataLength[g];
        
        if (globalScenarioOffset > insertEnd[g])
            globalScenarioOffset += dataLength[g];
        
        
        total_new_data+=dataLength[g];
    }

    [self writeint32_tAtAddress:(int32_t*)(&mapSize) address:0x8];
    
    //Increase metadata size
    if (isFlipped)
    {
        int32_t metaSize;
        [self readint32_tAtAddress:&metaSize address:20];
        
            int g;
            for (g=0; g < tagdatacount; g++)
            {
                metaSize+=dataLength[g];
            }
            
        [self writeint32_tAtAddress:(int32_t*)(&metaSize) address:20];
    }
    
    
    int i;
    int itemtagLength = 32;

    //------------------------------------------------------------------------------------------
    // Updates the index offsets if any data is written before them. Also updates the tag totals
    //------------------------------------------------------------------------------------------

    #ifdef __DEBUG__
    CSLog(@"Writing new tag count");
#endif
    
    int32_t oldTagCount = indexHead.tagcount;
    
    int32_t offsetToIndex;
    [self readint32_tAtAddress:&offsetToIndex address:0x10];
        
    int32_t oldIndexOffset = offsetToIndex;
    
    
    if (!isFlipped)
    {
        
        #ifdef __DEBUG__
        CSLog(@"Original offset 0x%lx", offsetToIndex);
#endif
        
        int g;
        for (g=0; g < tagdatacount; g++)
        {
            if (indexHead.indexMagic + offsetToIndex - 0x40440000 >= insertEnd[g])
            {
                offsetToIndex+=dataLength[g];
                [self writeint32_tAtAddress:(int32_t*)(&offsetToIndex) address:0x10];
            }
        }

        mapHeader.offsetToIndex = offsetToIndex;
        
        int32_t newData = 0;
        for (g=0; g< tagdatacount; g++)
        {
            newData+=dataLength[g];
        }
        
        #ifdef __DEBUG__
        CSLog(@"Total new data: %ld", newData);
        CSLog(@"New offset 0x%lx", offsetToIndex);
#endif
    }
    
    if (isFlipped)
    {
        //Update the tag counter
        int32_t newCount = [tagArray count];
        [self writeint32_tAtAddress:(int32_t*)(&newCount) address:mapHeader.offsetToIndex+12];
        
        #ifdef __DEBUG__
        CSLog(@"Tags offset %ld 0x%lx", newCount, mapHeader.offsetToIndex+12);
    #endif
        
        indexHead.tagcount = newCount;
    }
    
    //Loop through all of the tags and update
    int32_t newOffset = indexHead.indexMagic + mapHeader.offsetToIndex - 0x40440000;
    [self seekToAddress:newOffset];

    int32_t tagEnd = newOffset + [tagArray count]*itemtagLength;
    
    //NSMutableArray *alreadyUpdated = [[NSMutableArray alloc] initWithCapacity:3000];
    
    //Update tag offsets
    //CSLog(@"Updating tag offsets %lx %ld %d %d", newOffset, indexHead.tagcount, dataLength, insertEnd);
    
    int32_t oldMagic = _magic;
    BOOL magicChanged = NO;
    if (!isFlipped)
    {
        if (oldIndexOffset != mapHeader.offsetToIndex)
        {
#ifdef __DEBUG__
            CSLog(@"MAGIC CHANGED");
#endif
            
            magicChanged = YES;

            _magic = (indexHead.indexMagic - (mapHeader.offsetToIndex + 40));
            //[mapScenario updateReflexiveOffsetsWithOldMagic:oldMagic];
        }
    }

    //------------------------------------------------------------------------------------------
    // Loops through the tags in the mapfile and updates the offsets. No need! Magic may be changed
    //------------------------------------------------------------------------------------------

    
    if (!magicChanged)
    {
#ifdef __DEBUG__
        CSLog(@"Updating tag index offset");
#endif
        
        int loopAmount = [tagArray count];
        if (isFlipped)
        {
            loopAmount = oldTagCount;
        }
        
        for (i = 0; i < loopAmount; i++)
        {
            [self seekToAddress:newOffset+i*itemtagLength];
            int32_t originalOffset, originalOffset2;
            
            //Update the string offset
            [self readint32_tAtAddress:&originalOffset address:newOffset+i*itemtagLength+16];

            int g;
            for (g=0; g< tagdatacount; g++)
            {
                if (originalOffset-[self magic] >= insertEnd[g])
                {
                    originalOffset+=dataLength[g];
                    [self writeint32_tAtAddress:(int32_t*)(&originalOffset) address:newOffset+i*itemtagLength+16];
                }
            }

            //Update the next offset
            [self seekToAddress:newOffset+i*itemtagLength+20];
            [self readint32_t:&originalOffset2];
            
            for (g=0; g< tagdatacount; g++)
            {
                if (originalOffset2-[self magic] >= insertEnd[g])
                {
#ifdef __DEBUG__
                    CSLog(@"MAIN OFFSET CHANGED FORM 0x%lx to 0x%lx", originalOffset2-[self magic], originalOffset2-[self magic]+dataLength[g]);
#endif
                    
                    originalOffset2+=dataLength[g];
                    [self writeint32_tAtAddress:(int32_t*)(&originalOffset2) address:newOffset+i*itemtagLength+20];
                }
            }
        }
    }
    
    
    //Update the tag arrays
    if (!isFlipped)
    {
        #ifdef __DEBUG__
        CSLog(@"Updating tag array");
        #endif
        
        for (i = 0; i < oldTagCount; i++)
        {
            [self seekToAddress:newOffset+i*itemtagLength];
            [[tagArray objectAtIndex:i] updateTag:self];
        }
        
        for (i = oldTagCount; i < [tagArray count]; i++)
        {
            CSLog(@"Fixing magic for tag %.4s %@", [[tagArray objectAtIndex:i] tagClassHigh], [[tagArray objectAtIndex:i] tagName]);
            [[tagArray objectAtIndex:i] fixOffsetWithOldMagic:oldMagic withMap:self];
            
            /*MapTag *tag = [tagArray objectAtIndex:i];
             int32_t offset = [tag rawOffset];
             
             if (offset-_magic >= insertEnd)
             {
             offset+=dataLength;
             CSLog(@"Updating for tag %@ offset 0x%lx 0x%lx to 0x%lx", [tag tagName], newOffset+i*itemtagLength+16, offset-dataLength, offset);
             }
             
             [tag updateOffset:offset withMap:self];*/
            
        }
    }
    
    if (!magicChanged)
    {
        
        #ifdef MEMORY_READING
            char *mapdata = malloc(globalMapSize);
            memcpy(mapdata, map_memory, globalMapSize);
        
            int32_t size = globalMapSize;
        #else
            fseek(mapFile, 0L, SEEK_END);
            int32_t size = ftell(mapFile);
            char *mapdata = malloc(size);
            fseek(mapFile, 0L, SEEK_SET);
            fread(mapdata, size, 1, mapFile);
        #endif
        
        int32_t tempValue, prevValue = 0;
        
        #ifdef __DEBUG__
        CSLog(@"Fix reflexive offsets");
        #endif
        
        for (i = 0; i < [tagArray count]; i++)
        {
            MapTag *mapstag = [tagArray objectAtIndex:i];
            
            int32_t offsetInMap = [mapstag offsetInMap];
            int32_t tagLength = [mapstag tagLength];
#ifdef __DEBUG__
            CSLog(@"%.4s %@ %ld 0x%lx %ld 0x%lx", [mapstag tagClassHigh], [mapstag tagName], tagLength, offsetInMap, offsetInMap, size);
#endif
            if (tagLength <= 0)
            {
                continue;
            }
            
            int a;
            for (a=0; a < tagLength; a+=4)
            {
                int32_t location = offsetInMap + a;
                if (location < 0 || location >= size)
                {
                    prevValue = tempValue;
                    continue;
                }
                
                if (location >= newOffset && location <= tagEnd) //No reflexives in this tag
                {
                    prevValue = tempValue;
                    continue;
                }
                
                memcpy(&tempValue, &mapdata[location], 4);
                if (tempValue != 0 && tempValue != 0xFFFFFFFF && tempValue != 0xCACACACA)
                {
                    int32_t pos = tempValue - _magic;
                    if (pos <= offsetInMap+tagLength && pos >= offsetInMap && pos > location)
                    {
                        
                        if (a>=4)
                        {
                            int32_t count, zeroes;
                            count = prevValue;
                            
                            memcpy(&count, &mapdata[location-4], 4);
                            
                            if (count > 0)
                            {
                                if (location+4 < offsetInMap+tagLength)
                                {
                                    memcpy(&zeroes, &mapdata[location+4], 4);
                                    if (zeroes == 0)
                                    {
                                        memset(&mapdata[location], 0, 4);

                                        /*
                                        NSNumber *location_number = [NSNumber numberWithLong:location];
                                        if ([alreadyUpdated containsObject:location_number])
                                        {
                                            prevValue = tempValue;
                                            continue;
                                        }
                                        
                                        [alreadyUpdated addObject:location_number];
                                        */
                                        //CSLog(@"Updating reflexive 0x%lx 0x%lx", location, pos);

                                        int32_t newOffsetint32_t=tempValue;
                                        int g;
                                        for (g=0; g< tagdatacount; g++)
                                        {
                                            if (newOffsetint32_t-[self magic] >= insertEnd[g])
                                            {
                                                #ifdef __DEBUG__
                                                CSLog(@"Updating reflexive at 0x%lx from 0x%lx to 0x%lx", location, newOffsetint32_t-[self magic], newOffsetint32_t-[self magic]+dataLength[g]);
                                                #endif
                                                
                                                newOffsetint32_t+=dataLength[g];
                                                
                                                //if (newOffsetint32_t - _magic - [mapstag offsetInMap] > tagLength)
                                                //{
                                                //    tagLength = newOffsetint32_t - _magic - [mapstag offsetInMap];
                                                //}
                                                
                                                if (![self writeint32_tAtAddress:(int32_t*)(&newOffsetint32_t) address:location])
                                                {
#ifdef __DEBUG__
                                                    CSLog(@"WRITE ISSUE");
#endif
                                                    
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                prevValue = tempValue;
            }
        }
        
        free(mapdata);
            
     }
    
    
    
    if (changingIndex)
    {
    
        
    #ifdef MEMORY_READING
        char *mapdata_new = malloc(globalMapSize);
        memcpy(mapdata_new, map_memory, globalMapSize);
        
        int32_t mapSize = globalMapSize;
    #else
        fseek(mapFile, 0L, SEEK_END);
        int32_t mapSize = ftell(mapFile);
        char *mapdata_new = malloc(mapSize);
        fseek(mapFile, 0L, SEEK_SET);
        fread(mapdata_new, mapSize, 1, mapFile);
    #endif
    
    int32_t vertexSize = [self indexHead].vertex_size;
    int32_t vertexOffset = [self indexHead].vertex_offset;
    
    for (i = 0; i < [tagArray count]; i++)
	{
        MapTag *mapstag = [tagArray objectAtIndex:i];
        
        int32_t offsetInMap = [mapstag offsetInMap];
        int32_t tagLength = [mapstag tagLength];
        
        if (memcmp([mapstag tagClassHigh], "2dom", 4) == 0)
        {
#ifdef __DEBUG__
            CSLog(@"Updating model data %@ 0x%lx 0x%lx", [mapstag tagName], [mapstag offsetInMap], [mapstag offsetInIndex]-32);
#endif
            
            //modelData
            int32_t initial = ([mapstag offsetInMap]+48+4+4+140+12);
            
#ifdef __DEBUG__
            CSLog(@"Count offset 0x%lx", initial);
#endif
            
            if (initial < 0 || initial >= mapSize) { continue; }
            
            int32_t chunk_count = 0;
            memcpy(&chunk_count, &mapdata_new[initial], 4);

#ifdef __DEBUG__
            CSLog(@"Offset 0x%lx", initial+4);
#endif
            
            int32_t geometry_offset;
            memcpy(&geometry_offset, &mapdata_new[initial+4], 4);
            int32_t geoOffsetResolved = geometry_offset-[self magic];
            
#ifdef __DEBUG__
            CSLog(@"Chunk count: %ld 0x%lx", chunk_count, geoOffsetResolved);
#endif
            
            int a;
            for (a=0; a < chunk_count; a++)
            {
                int32_t parts_count = 0, parts_offset = 0;
                initial = (geoOffsetResolved + (a * 48)) + 36;
                
                if (initial < 0 || initial >= mapSize)
                {
                    continue;
                }
                
                memcpy(&parts_count, &mapdata_new[initial], 4); initial+=4;
                memcpy(&parts_offset, &mapdata_new[initial], 4);
                initial = parts_offset-[self magic];
                
                #ifdef __DEBUG__
                CSLog(@"Parts: %ld 0x%lx 0x%lx", parts_count, initial, (geoOffsetResolved + (a * 48)) + 36);
                #endif
                
                int x;
                for (x=0; x < parts_count; x++)
                {
                    initial+=72;
                    
                    int32_t indexPointer_count = 0, indexPointerRaw1= 0, indexPointerRaw2= 0;
                    int32_t vertPointer_count= 0, vertPointerRaw= 0;

                    if (initial < 0 || initial >= mapSize)
                    {
                        break;
                    }
                    
                    memcpy(&indexPointer_count, &mapdata_new[initial], 4); initial+=4;
                    
                    int32_t indexLocation = initial;
                    memcpy(&indexPointerRaw1, &mapdata_new[initial], 4); initial+=4;
                    memcpy(&indexPointerRaw2, &mapdata_new[initial], 4); initial+=4;
                    initial+=4;
                    memcpy(&vertPointer_count, &mapdata_new[initial], 4); initial+=4;
                    initial+=8;
                    
                    int32_t vertLocation = initial;
                    memcpy(&vertPointerRaw, &mapdata_new[initial], 4); initial+=4;
                    initial+=28;
                    
                    int32_t endOfPart = initial;
                    
                    //Update vertex pointer
                    int g;
                    
                    if (changingIndex)
                        g = 0;
          
                    if (vertPointerRaw+vertexOffset >= insertEnd[g])
                    {
                        vertPointerRaw+=dataLength[g];
                        [self writeint32_tAtAddress:(int32_t*)(&vertPointerRaw) address:vertLocation];
                    }
                
                    
                    //Update index pointer
                    if (changingIndex)
                        g = 1;
          
                    if (indexPointerRaw1+vertexOffset+vertexSize >= insertEnd[g])
                    {
                        #ifdef __DEBUG__
                        CSLog(@"Modifying index location from 0x%lx to 0x%lx", indexPointerRaw1, indexPointerRaw1+dataLength[g]);
                        #endif
                        
                        indexPointerRaw1+=dataLength[g];
                        indexPointerRaw2+=dataLength[g];
                        [self writeint32_tAtAddress:(int32_t*)(&indexPointerRaw1) address:indexLocation];
                        [self writeint32_tAtAddress:(int32_t*)(&indexPointerRaw2) address:indexLocation+4];
                        
                        
                    }
                   
                    
                    initial = endOfPart;
                }
            }
        }
    }
    
    free(mapdata_new);
    }
    
  
    CSLog(@"Rebuild complete");

    
    /*//correct bsp_data name_offset info
     for i as integer = 0 to UBound(bsp_data)
     - 101 -
     if tagIDTable.HasKey(bsp_data(i).tagID) then
     bsp_data(i).dep_name_offset = tags(tagIDTable.Value(bsp_data(i).tagID)).nameoffset
     end next
     for i as integer = 0 to UBound(tags)
     //tag data is allocated 45%, total is 95% dim d as double = i
     dim num as double = (d*45) + 1
     dim denom as double = ubound(tags) + 1 dim add as integer = round(num/denom) w.tick("Writing tag data", progress + add) if tags(i).class1 <> "psbs" then
     tags(i).offset = bw.Position
     writeTag(bw, tags(i), map_magic, map_magic) else
     dim scnr_bsp as boolean = false
     for j as integer = 0 to UBound(bsp_data)
     if tags(i).tagID = bsp_data(j).tagID then scnr_bsp = true
     exit for j
     end next
     if not scnr_bsp then
     tags(i).offset = bw.Position
     writeTag(bw, tags(i), map_magic, map_magic)
     end end
     if tags(i).tagID = basetagID then
     //fix the scenario listing for bsp info
     dim temp_offset as integer = bw.position
     bw.close //necessary because windows doesn't like multiple streams attached to the same file dim br as BinaryStream = f.openasbinaryfile
     br.LittleEndian = true
     br.Position = tags(i).offset + &h5A4
     dim count_offset as integer = br.Position
     dim count as integer = br.ReadInt32
     dim offset as integer = br.ReadInt32 - map_magic br.close
     bw = f.openasbinaryfile(true)
     bw.littleendian = true
     bw.position = temp_offset
     if count <> UBound(bsp_data) + 1 then bw.Position = count_offset
     count = UBound(bsp_data) + 1 bw.WriteUInt32(count)
     end
     bw.Position = offset
     for j as integer = 0 to UBound(bsp_data)
     bsp_data(j).write(bw, map_magic) next
     - 102 -
     bw.Position = temp_offset end
     next
     progress = 95
     dim length as integer = bw.Position
     //rewrite header
     bw.Position = 0
     Header.decomp_len = length
     Header.TagIndexOffset = index_offset Header.TagIndexMetaLength = length - index_offset Header.write(bw)
     //rewrite index
     bw.Position = index_offset Index_Header.BaseTag = basetagID Index_Header.write(bw, Header.version <> 5) for i as integer = 0 to UBound(tags)
     tags(i).write(bw, map_magic) next
     //rewrite bsp datas to include updated for i as integer = 0 to UBound(bsp_data)
     bw.Position = bsp_data(i).offset
     //bsp data is allocated 5%, total is 100%
     dim d as double = i
     dim num as double = (d*5) + 1
     dim denom as double = ubound(bsp_data) + 1 dim add as integer = round(num/denom) w.tick("Writing bsp index data", progress + add) if tagIDTable.HasKey(bsp_data(i).tagID) then
     writeTag(bw, tags(tagIDTable.Value(bsp_data(i).tagID)), bsp_data(i).magic, map_magic, true) else
     break end
     next
     Progress = 100 w.tick("Finishing up", progress)
     bw.Close
     Return true End Function
*/
    
    
    
    
    /*
	// Then we load the BSP
	bspHandler = [[BSP alloc] initWithMapFile:self texManager:_texManager];
	[bspHandler loadVisibleBspInfo:[mapScenario header].StructBsp version:mapHeader.version];
	[bspHandler setActiveBsp:0];
	*/
    
    //Update the map magic
    //index offset
    
    
    //Insert blank data into the file
    //[_]
    //[_mapfile writeAnyDataInFile:filename atAddress:scnr size:[self tagLength] address:[self offsetInMap]];
}


- (void)closeMap
{
    if (!dataReading)
        fclose(mapFile);
    
	fclose(bitmapsFile);
}
- (void)setFile:(FILE *)map
{
	mapFile = map;
}
- (FILE *)currentFile
{
    if (dataReading)
    {
        NSLog(@"Current file");
        return nil;
    }
	return mapFile;
}
- (BOOL)isPPC
{
	return isPPC;
}

- (void)swapBufferEndian32:(void *)buffer size:(int)size
{
	if (size == 1)
	{
		return;
	}
	else if (size == 2)
	{
		short *tmpShort = (short *)buffer;
	
		*tmpShort = EndianSwap16(*tmpShort);
	}
	else if (size >= 4)
	{
		
	}
}

#ifdef MEMORY_WRITING
/* This is directly accessing the buffer, dammit */
- (BOOL)write:(void *)buffer size:(int)size
{
    if (currentOffset >= 0 && currentOffset <= globalMapSize && currentOffset+size <= globalMapSize && size >= 0)
    {
        memcpy(&map_memory[currentOffset], buffer, size);
        currentOffset+=size;
        return YES;
    }
    currentOffset+=size;
    return NO;
}
- (BOOL)writeChar:(char)byte
{
    if ([self write:byte size:1] == 1)
        return YES;
    return NO;
}
- (BOOL)writeByte:(void *)byte
{
    if ([self write:byte size:1] == 1)
        return YES;
    return NO;
}
- (BOOL)writeShort:(void *)byte
{
    if ([self write:byte size:sizeof(short)] == 1)
        return YES;
    return NO;
}
- (BOOL)writeFloat:(float *)toWrite
{
	if ([self write:toWrite size:sizeof(float)] == 1)
        return YES;
    return NO;
}
- (BOOL)writeInt:(int *)myInt
{
	if ([self write:myInt size:sizeof(int)] == 1)
        return YES;
    return NO;
}
- (BOOL)writeint32_t:(int32_t *)myint32_t
{
	if ([self write:myint32_t size:sizeof(int32_t)] == 1)
        return YES;
    return NO;
}
- (BOOL)writeAnyData:(void *)data size:(unsigned int)size
{
    if ([self write:data size:size] == 1)
        return YES;
    return NO;
}
- (BOOL)writeByteAtAddress:(void *)byte address:(uint32_t)address
{
	currentOffset = address;
    if ([self write:byte size:1] == 1)
        return YES;
    return NO;
}
- (BOOL)writeFloatAtAddress:(float *)toWrite address:(uint32_t)address
{
	currentOffset = address;
    if ([self write:toWrite size:sizeof(float)] == 1)
        return YES;
    return NO;
}
- (BOOL)writeIntAtAddress:(int *)myInt address:(uint32_t)address
{
	currentOffset = address;
    if ([self write:myInt size:sizeof(int)] == 1)
        return YES;
    return NO;
}
- (BOOL)writeint32_tAtAddress:(int32_t *)myint32_t address:(uint32_t)address
{
	currentOffset = address;
    if ([self write:myint32_t size:sizeof(int32_t)] == 1)
        return YES;
    return NO;
}
- (BOOL)writeAnyDataAtAddress:(void *)data size:(unsigned int)size address:(uint32_t)address
{
	currentOffset = address;
	return [self write:data size:size];
}
#else
/* This is directly accessing the buffer, dammit */
- (BOOL)write:(void *)buffer size:(int)size
{
    //CSLog(@"Writing to map");
    
    
	int i;
	if (isPPC)
	{
        CSLog(@"PPC Write");
		/*
			lol, this takes some work, doesn't it?
			
			What I'm doing is going through the buffer and swapping the bytes
			This way we can build once and run on all macs
		*/

		if (size == 1)
		{
			if (fwrite(buffer, size, 1, mapFile) == 1)
				return YES;
		}
		else if (size == 2)
		{
			short tmpShort;
			tmpShort = EndianSwap16(tmpShort);
			if (fwrite(&tmpShort, size, 1, mapFile) == 1);
				return YES;
		}
		else if (size >= 4)
		{
			int32_t *pointint32_t = buffer;
			int32_t tmpint32_t;
			for (i = 0; i < (size / 4); i++)
			{	
				tmpint32_t = EndianSwap32(pointint32_t[i]);
				fwrite(&tmpint32_t, 4, 1, mapFile);
			}
			if ((size % 4) > 0)
			{
				char *bytes = buffer;
				int x;
				
				for (x = size; x >  (size % 4); x--)
				{
					fwrite(&bytes[x],1,1,mapFile);
				}
			}
			FILE *tmpFile = fopen("test.scnr","wrb+");
	
			fwrite(buffer,size,1,tmpFile);
		
			fclose(tmpFile);

			return YES;
		}
	}
	else
	{
		// Howwwwww embarrassing, I had it as fread rather than fwrite
		if (fwrite(buffer, size, 1, mapFile) == 1)
        {
			return YES;
        }
		else
        {

			return NO;
        }
	}
	return NO;
}
- (BOOL)writeChar:(char)byte
{
	if (fwrite(byte,1,1,mapFile) == 1)
		return YES;
	else
		return NO;
}
- (BOOL)writeByte:(void *)byte
{
	if (fwrite(byte,1,1,mapFile) == 1)
		return YES;
	else
		return NO;
}
- (BOOL)writeShort:(void *)byte
{
	if (fwrite(byte,2,1,mapFile) == 1)
		return YES;
	else
		return NO;
}
- (BOOL)writeFloat:(float *)toWrite
{	
	if (fwrite(toWrite, sizeof(float),1,mapFile) == 1)
		return YES;
	else
		return NO;
}
- (BOOL)writeInt:(int *)myInt
{
	if (fwrite(myInt, sizeof(int),1,mapFile) == 1)
		return YES;
	else
		return NO;
}
- (BOOL)writeint32_t:(int32_t *)myint32_t
{
	if (fwrite(myint32_t, sizeof(int32_t),1,mapFile) == 1)
		return YES;
	else
		return NO;
}
- (BOOL)writeAnyData:(void *)data size:(unsigned int)size
{
	if (fwrite(data, size,1,mapFile) == 1)
		return YES;
	else
		return NO;
}
- (BOOL)writeAnyArrayData:(void *)data size:(unsigned int)size array_size:(unsigned int)array_size
{
	if (fwrite(data, size,array_size,mapFile) == array_size)
		return YES;
	else
		return NO;
}
- (BOOL)writeByteAtAddress:(void *)byte address:(uint32_t)address
{
	fseek(mapFile, address, SEEK_SET);
	if (fwrite(byte,1,1,mapFile) == 1)
		return YES;
	else
		return NO;
}
- (BOOL)writeFloatAtAddress:(float *)toWrite address:(uint32_t)address
{	
	fseek(mapFile, address, SEEK_SET);
	if (fwrite(toWrite, sizeof(float),1,mapFile) == 1)
		return YES;
	else
		return NO;
}
- (BOOL)writeIntAtAddress:(int *)myInt address:(uint32_t)address
{
	fseek(mapFile, address, SEEK_SET);
	if (fwrite(myInt, sizeof(int),1,mapFile) == 1)
		return YES;
	else
		return NO;
}
- (BOOL)writeint32_tAtAddress:(int32_t *)myint32_t address:(uint32_t)address
{
	fseek(mapFile, address, SEEK_SET);
	if (fwrite(myint32_t, sizeof(int32_t),1,mapFile) == 1)
		return YES;
	else
		return NO;
}



- (BOOL)writeAnyDataInFile:(NSString*)filename atAddress:(void *)data size:(unsigned int)size address:(uint32_t)address
{
    //CSLog(mapName);
    //CSLog(filename);
    
    if (![mapName isEqualToString:filename])
    {
       
        if ([[NSFileManager defaultManager] fileExistsAtPath:filename])
            [[NSFileManager defaultManager] removeItemAtPath:filename error:nil];
        
        [[NSFileManager defaultManager] copyItemAtPath:mapName toPath:filename error:nil];
        
        FILE *oldMap = mapFile;
        mapFile = fopen([filename cString],"rwb+");

        fseek(mapFile, address, SEEK_SET);
        return [self write:data size:size];
    
        fclose(mapFile);
        mapFile = oldMap;
    }
    else
    {
        if (mapFile)
        {
            fseek(mapFile, address, SEEK_SET);
            return [self write:data size:size];
        }
    }
   
    return NO;
}

- (BOOL)writeAnyDataAtAddress:(void *)data size:(unsigned int)size address:(uint32_t)address
{
	fseek(mapFile, address, SEEK_SET);
	return [self write:data size:size];
}
- (BOOL)writeAnyArrayDataAtAddress:(void *)data size:(unsigned int)size array_size:(unsigned int)array_size address:(uint32_t)address
{
	fseek(mapFile,address, SEEK_SET);
	if (fwrite(data, size,array_size,mapFile) == array_size)
		return YES;
	else
		return NO;
}
#endif

- (BOOL)insertDataInFile:(NSString*)filename withData:(void *)data size:(unsigned int)newsize address:(uint32_t)address
{
    //CSLog([self mapLocation]);
    //CSLog(filename);
    
    isPPC = NO;
    
#ifdef __DEBUG__
    CSLog(@"Logging");
    CSLog(@"Open map %d 0x%lx", newsize, address);
#endif
    
    char *start_data = malloc(address);
    if (![self readBlockOfDataAtAddress:start_data size_of_buffer:address address:0])
        CSLog(@"READ ERROR");
    
    //Get the current size using memory?
#ifdef MEMORY_READING
    int32_t size = globalMapSize;
#else
    fseek(mapFile, 0, SEEK_END);
    int32_t size = ftell(mapFile);
#endif
    
    int32_t readSize = size-address;
    char *data_buffer = malloc(readSize);
    if (![self readBlockOfDataAtAddress:data_buffer size_of_buffer:readSize address:address])
        CSLog(@"READ ERROR");
    
#ifdef MEMORY_READING
    //Update the map data in memory
    free(map_memory);
    
    globalMapSize = address+newsize+readSize;
    map_memory = malloc(globalMapSize);
    
    memcpy(&map_memory[0]               , start_data     , address);
    memcpy(&map_memory[address]         , data           , newsize);
    memcpy(&map_memory[address+newsize] , data_buffer    , readSize);
    
    free(start_data);
    free(data_buffer);
#else
    FILE *oldMap;
    if ([filename isEqualToString:[self mapLocation]])
    {
        fclose(mapFile);
        oldMap = fopen([filename cStringUsingEncoding:NSASCIIStringEncoding],"wb+");
    }
    else
        oldMap = fopen([filename cStringUsingEncoding:NSASCIIStringEncoding],"wb+");
    
#ifdef __DEBUG__
    CSLog(@"Writing to %@", filename);
#endif
    
    fseek(oldMap, 0, SEEK_SET);
    fwrite(start_data, address, 1, oldMap);
    fwrite(data, newsize, 1, oldMap);
    fwrite(data_buffer, readSize, 1, oldMap);
    
    if ([filename isEqualToString:mapName])
    {
        fclose(oldMap);
        mapFile = fopen([filename cStringUsingEncoding:NSASCIIStringEncoding],"rb+");
    }
    else
        fclose(oldMap);
#endif
    
    return YES;
}

//NEW FASTER METHODS FOR READING THINGS
#ifdef MEMORY_READING
- (int32_t)currentOffset
{
	return currentOffset;
	//return [[NSNumber numberWithDouble:ftell(mapFile)] longValue];
}
- (void)seekToAddress:(uint32_t)address
{
	currentOffset = address;
}
- (void)skipBytes:(int32_t)bytesToSkip
{
    currentOffset += bytesToSkip;
}
- (void)reverseBytes:(int32_t)bytesToSkip
{
	currentOffset -= bytesToSkip;
}
- (BOOL)read:(void *)buffer size:(unsigned int)size
{
    if (currentOffset >= 0 && currentOffset <= globalMapSize && currentOffset+size <= globalMapSize)
    {
        memcpy(buffer, &(map_memory[currentOffset]), size);
        currentOffset+=size;
        return YES;
    }
    currentOffset+=size;
    return NO;
}
- (BOOL)readByte:(void *)buffer
{
	return [self read:buffer size:1];
}
- (BOOL)readShort:(void *)buffer
{
	return [self read:buffer size:sizeof(short)];
}
- (BOOL)readint32_t:(void *)buffer
{
	return [self read:buffer size:4];
}
- (BOOL)readFloat:(void *)floatBuffer
{
	return [self read:floatBuffer size:4];
}
- (BOOL)readInt:(void *)intBuffer
{
	return [self read:intBuffer size:4];
}
- (BOOL)readBlockOfData:(void *)buffer size_of_buffer:(unsigned int)size
{
	// Need to remove this at some point
	return [self read:buffer size:size];
}
- (BOOL)readByteAtAddress:(void *)buffer address:(uint32_t)address
{
	currentOffset = address;
	return [self read:buffer size:1];
}
- (BOOL)readIntAtAddress:(void *)buffer address:(uint32_t)address
{
	currentOffset = address;
	return [self read:buffer size:4];
}
- (BOOL)readFloatAtAddress:(void *)buffer address:(uint32_t)address
{
	currentOffset = address;
	return [self read:buffer size:4];
}
- (BOOL)readint32_tAtAddress:(void *)buffer address:(uint32_t)address
{
	currentOffset = address;
	return [self read:buffer size:4];
}
- (BOOL)readBlockOfDataAtAddress:(void *)buffer size_of_buffer:(unsigned int)size address:(uint32_t)address
{
    currentOffset = address;
	return [self read:buffer size:size];
}
#else
- (int32_t)currentOffset
{
	return ftell(mapFile);
	//return [[NSNumber numberWithDouble:ftell(mapFile)] longValue];
}
- (void)seekToAddress:(uint32_t)address
{
	fseek(mapFile, address, SEEK_SET);
}
- (void)skipBytes:(int32_t)bytesToSkip
{
	fseek(mapFile, (ftell(mapFile) + bytesToSkip), SEEK_SET);
}
- (void)reverseBytes:(int32_t)bytesToSkip
{
	fseek(mapFile, (ftell(mapFile) - bytesToSkip), SEEK_SET);
}

- (BOOL)read:(void *)buffer size:(unsigned int)size
{
	int i;
	if (isPPC)
	{
		if (size == 1)
		{
			if (fread(buffer, size, 1, mapFile) == 1)
				return YES;
		}
		else if (size == 2)
		{
			short tmpShort;
			fread(&tmpShort, size, 1, mapFile);
			tmpShort = EndianSwap16(tmpShort);
			memcpy(buffer, &tmpShort, 2);
			return YES;
		}
		else if (size >= 4)
		{
			int32_t *pointint32_t = buffer;
			for (i = 0; i < (size / 4); i++)
			{
				fread(&pointint32_t[i], 4, 1, mapFile);
				pointint32_t[i] = EndianSwap32(pointint32_t[i]);
			}
			if ((size % 4) > 0)
			{
				int32_t tempint32_t;
				pointint32_t = &tempint32_t;
				char *bytes;
				int x, byteToTranscribe;
				
				fread(pointint32_t, 4, 1, mapFile);
				
				bytes = (char *)&pointint32_t;
				
				for (x = size; x >  (size % 4); x--)
				{
					bytes[x] = bytes[byteToTranscribe];
					byteToTranscribe++;
				}
			}
			return YES;
		}
	}
	else
	{
		if (fread(buffer, size, 1, mapFile) == 1)
			return YES;
		else
			return NO;
	}
	return NO;
}
- (BOOL)readByte:(void *)buffer
{
	return [self read:buffer size:1];
}
- (BOOL)readShort:(void *)buffer
{
	return [self read:buffer size:sizeof(short)];
}
- (char)readSimpleByte
{
	char buffer;
	fread(&buffer,1,1,mapFile);
	return buffer;
}
- (BOOL)readint32_t:(void *)buffer
{
	return [self read:buffer size:4];
}
- (BOOL)readFloat:(void *)floatBuffer
{
	return [self read:floatBuffer size:4];
}
- (BOOL)readInt:(void *)intBuffer
{
	return [self read:intBuffer size:4];
}
- (BOOL)readBlockOfData:(void *)buffer size_of_buffer:(unsigned int)size
{
	// Need to remove this at some point
	return [self read:buffer size:size];
}
- (BOOL)readByteAtAddress:(void *)buffer address:(uint32_t)address
{
	fseek(mapFile,address,SEEK_SET);
	return [self read:buffer size:1];
}
- (BOOL)readIntAtAddress:(void *)buffer address:(uint32_t)address
{
	fseek(mapFile,address,SEEK_SET);
	return [self read:buffer size:4];
}
- (BOOL)readFloatAtAddress:(void *)buffer address:(uint32_t)address
{
	fseek(mapFile,address,SEEK_SET);
	return [self read:buffer size:4];
}
- (BOOL)readint32_tAtAddress:(void *)buffer address:(uint32_t)address
{
	fseek(mapFile,address,SEEK_SET);
	return [self read:buffer size:4];
}
- (BOOL)readBlockOfDataAtAddress:(void *)buffer size_of_buffer:(unsigned int)size address:(uint32_t)address
{
	fseek(mapFile,address,SEEK_SET);
	return [self read:buffer size:size];
}
#endif




- (char *)readCString
{
	char *buffer, *tempBuffer, tempChar;
	int i  = 0;
	
	buffer = malloc(sizeof(char)*1024);
	
	tempBuffer = buffer;
	do
	{
		[self readByte:&tempChar];
		*buffer=tempChar;
		buffer++;
		i++;
	} while (tempChar != 0x00 && i <= 1024);
	return tempBuffer;
}
- (reflexive)readReflexive
{
	reflexive reflex;
	reflex.location_in_mapfile = [self currentOffset];
	[self readint32_t:&reflex.chunkcount];
	[self readint32_t:&reflex.offset];
	[self readint32_t:&reflex.zero];
	reflex.offset -= _magic;
	return reflex;
}
- (reflexive)readBspReflexive:(int32_t)magic
{
	reflexive reflex;
	reflex.location_in_mapfile = [self currentOffset];
	[self readint32_t:&reflex.chunkcount];
	[self readint32_t:&reflex.offset];
	[self readint32_t:&reflex.zero];
	reflex.offset -= magic;
	return reflex;
}
- (TAG_REFERENCE)readReference
{
	TAG_REFERENCE ref;
	[self readint32_t:&ref.tag];
	[self readint32_t:&ref.NamePtr];
	ref.NamePtr -= _magic;
	[self readint32_t:&ref.unknown];
	[self readint32_t:&ref.TagId];
    
    //CSLog(@"Reference unknown %ld", ref.unknown);
	return ref;
}

- (void)loadSCEX:(scex*)shader forID:(int32_t)shaderId //FUNCTION WHICH FINDS MULTIPLE BITMAPS
{
    int32_t currentOffset = [self currentOffset];
	
	// ok, so lets lookup the shader tag
	MapTag *tempShaderTag = [[self tagForId:shaderId] retain]; // Now we have the shader! Yay!
	[self seekToAddress:[tempShaderTag offsetInMap]];
    int i;
    
    [self seekToAddress:[tempShaderTag offsetInMap]+0x29];
    [self readInt:&shader->extended_flags];
    
    [self seekToAddress:[tempShaderTag offsetInMap]+0x54];
    
    shader->maps = [self readReflexive];
    shader->maps2 = [self readReflexive];
    
    shader->read_maps = (map*)malloc(sizeof(map) * (shader->maps.chunkcount + shader->maps2.chunkcount));
    [self seekToAddress:shader->maps.offset];
    for (i=0; i < shader->maps.chunkcount; i++)
    {
        [self skipBytes:11*4];
        [self readShort:&shader->read_maps[shader->maps.chunkcount-1-i].colorFunction];
        [self readShort:&shader->read_maps[shader->maps.chunkcount-1-i].alphaFunction];
        [self skipBytes:9*4];
        [self readFloat:&shader->read_maps[shader->maps.chunkcount-1-i].uscale];
        [self readFloat:&shader->read_maps[shader->maps.chunkcount-1-i].vscale];
        [self skipBytes:4*4];
        shader->read_maps[shader->maps.chunkcount-1-i].bitm = [self readReference];
        [self skipBytes:42];
        [self readShort:&shader->read_maps[shader->maps.chunkcount-1-i].uFunction];
        [self skipBytes:14];
        [self readShort:&shader->read_maps[shader->maps.chunkcount-1-i].vFunction];
        [self readFloat:&shader->read_maps[shader->maps.chunkcount-1-i].animation_period];
        [self skipBytes:24*4 - 42-2-14-2-4];
    }
    [self seekToAddress:shader->maps2.offset];
    for (i=0; i < shader->maps2.chunkcount; i++)
    {
        [self skipBytes:11*4];
        [self readShort:&shader->read_maps[shader->maps.chunkcount+shader->maps2.chunkcount-1-+i].colorFunction];
        [self readShort:&shader->read_maps[shader->maps.chunkcount+shader->maps2.chunkcount-1-+i].alphaFunction];
        [self skipBytes:9*4];
        [self readFloat:&shader->read_maps[shader->maps.chunkcount+shader->maps2.chunkcount-1-+i].uscale];
        [self readFloat:&shader->read_maps[shader->maps.chunkcount+shader->maps2.chunkcount-1-+i].vscale];
        [self skipBytes:4*4];
        shader->read_maps[shader->maps.chunkcount+shader->maps2.chunkcount-1-+i].bitm = [self readReference];
        [self skipBytes:42];
        [self readShort:&shader->read_maps[shader->maps.chunkcount+shader->maps2.chunkcount-1-+i].uFunction];
        [self skipBytes:14];
        [self readShort:&shader->read_maps[shader->maps.chunkcount+shader->maps2.chunkcount-1-+i].vFunction];
        [self readFloat:&shader->read_maps[shader->maps.chunkcount+shader->maps2.chunkcount-1-+i].animation_period];
        [self skipBytes:24*4 - 42-2-14-2-4];
    }
    [self seekToAddress:currentOffset];
}


- (void)loadSCHI:(schi*)shader forID:(int32_t)shaderId //FUNCTION WHICH FINDS MULTIPLE BITMAPS
{
    int32_t currentOffset = [self currentOffset];
	
	// ok, so lets lookup the shader tag
	MapTag *tempShaderTag = [[self tagForId:shaderId] retain]; // Now we have the shader! Yay!
	[self seekToAddress:[tempShaderTag offsetInMap]];
    int i;
    [self skipBytes:21*4];
    
    shader->maps = [self readReflexive];
    shader->read_maps = (map*)malloc(sizeof(map) * shader->maps.chunkcount);
    [self seekToAddress:shader->maps.offset];
    for (i=0; i < shader->maps.chunkcount; i++)
    {
        [self skipBytes:11*4];
        [self readShort:&shader->read_maps[i].colorFunction];
        [self readShort:&shader->read_maps[i].alphaFunction];
        [self skipBytes:9*4];
        [self readFloat:&shader->read_maps[i].uscale];
        [self readFloat:&shader->read_maps[i].vscale];
        [self skipBytes:4*4];
        shader->read_maps[i].bitm = [self readReference];
        [self skipBytes:42];
        [self readShort:&shader->read_maps[i].uFunction];
        [self skipBytes:14];
        [self readShort:&shader->read_maps[i].vFunction];
        [self readFloat:&shader->read_maps[i].animation_period];
        [self skipBytes:24*4 - 42-2-14-2-4];
    }
    [self seekToAddress:currentOffset];
}

- (void)loadSOSO:(soso*)shader forID:(int32_t)shaderId //FUNCTION WHICH FINDS MULTIPLE BITMAPS
{
    int32_t currentOffset = [self currentOffset];
	
	// ok, so lets lookup the shader tag
	MapTag *tempShaderTag = [[self tagForId:shaderId] retain]; // Now we have the shader! Yay!
    
    #ifdef __DEBUG__
    CSLog(@"Shader offset 0x%lx 0x%lx %@", shaderId, [tempShaderTag offsetInMap], [tempShaderTag tagName]);
#endif
    
    
	[self seekToAddress:[tempShaderTag offsetInMap]];
    
    int i;
    for (i=0; i<41; i++)
        [self readint32_t:&shader->junk1[i]];
    
    //CSLog(@"Offset to reference", [tempShaderTag offsetInMap]);
    shader->baseMap = [self readReference];
    for (i=0; i<2; i++)
        [self readint32_t:&shader->junk3[i]];
    
    shader->multiPurpose = [self readReference];
    
    for (i=0; i<3; i++)
        [self readint32_t:&shader->junk2[i]];
    
    [self readFloat:&shader->detailScale];
    shader->detailMap = [self readReference];
    
    [self seekToAddress:currentOffset];
}


- (void)loadSWAT:(swat*)shader forID:(int32_t)shaderId //FUNCTION WHICH FINDS MULTIPLE BITMAPS
{
    int32_t currentOffset = [self currentOffset];
	
	// ok, so lets lookup the shader tag
	MapTag *tempShaderTag = [[self tagForId:shaderId] retain]; // Now we have the shader! Yay!
	[self seekToAddress:[tempShaderTag offsetInMap]];
    
    [self skipBytes:0x70];
    
    //Read the material diffuse colour
    [self readFloat:&shader->r];
    [self readFloat:&shader->g];
    [self readFloat:&shader->b];
    
    USEDEBUG CSLog(@"Diffuse colour: %f %f %f", shader->r, shader->g, shader->b);
    
    [self seekToAddress:currentOffset];
}

- (void)loadShader:(senv*)shader forID:(int32_t)shaderId //FUNCTION WHICH FINDS MULTIPLE BITMAPS
{
    
    //CSLog(@"LOADING SHADER");
    int32_t currentOffset = [self currentOffset];
	
	// ok, so lets lookup the shader tag
	MapTag *tempShaderTag = [[self tagForId:shaderId] retain]; // Now we have the shader! Yay!
	[self seekToAddress:[tempShaderTag offsetInMap]];
    
    int i;
    for (i=0; i<34; i++)
        [self readint32_t:&shader->junk1[i]];
    
    shader->baseMapBitm = [self readReference];
    for (i=0; i<7; i++)
        [self readint32_t:&shader->junk2[i]];
    
    [self readFloat:&shader->primaryMapScale];
    shader->primaryMapBitm = [self readReference];
    
    [self readFloat:&shader->secondaryMapScale];
    shader->secondaryMapBitm = [self readReference];
    
    [self skipBytes:0x40-16];
    
    //Read the material diffuse colour
    [self readFloat:&shader->r];
    [self readFloat:&shader->g];
    [self readFloat:&shader->b];
    
    //USEDEBUG CSLog(@"Diffuse colour: %f %f %f", shader->r, shader->g, shader->b);
    
    [self seekToAddress:currentOffset];
   // CSLog(@"DONE");
}

- (NSMutableArray*)bitmsTagForShaderId:(int32_t)shaderId //FUNCTION WHICH FINDS MULTIPLE BITMAPS
{
	int32_t currentOffset = [self currentOffset];
	
	// ok, so lets lookup the shader tag
	MapTag *tempShaderTag = [[self tagForId:shaderId] retain]; // Now we have the shader! Yay!
	[self seekToAddress:[tempShaderTag offsetInMap]];
	
	[tempShaderTag release];
	
	NSMutableArray *bitmaps = [[NSMutableArray alloc] init];
	
	int32_t bitm = 'bitm', tempInt;
	int x;
	x = 0;
	
	int cso = currentOffset;
	while (x < 1000)
	{
		[self readint32_t:&tempInt];
		x++;
		cso+=4;
		
		if (tempInt == bitm)
		{
			[self skipBytes:8];
			
			int32_t identOfBitm;
			[self readint32_t:&identOfBitm];
			
			
			if (identOfBitm != 0xFFFFFFFF)
			{
				[bitmaps addObject:[self tagForId:identOfBitm]];
			}
			[self reverseBytes:8];
		}
	}
	[self seekToAddress:currentOffset];
	return bitmaps;
}

- (id)bitmTagForShaderId:(int32_t)shaderId
{
	int32_t currentOffset = [self currentOffset];
	
	// ok, so lets lookup the shader tag
	MapTag *tempShaderTag = [[self tagForId:shaderId] retain]; // Now we have the shader! Yay!
	[self seekToAddress:[tempShaderTag offsetInMap]];
	
	[tempShaderTag release];
	
	int32_t bitm = 'bitm', tempInt;
	int x;
	x = 0;
	do
	{
		[self readint32_t:&tempInt];
		x++;
	} while (tempInt != bitm && x < 1000);
	if (x != 1000)
	{
		[self skipBytes:8];
		int32_t identOfBitm;
		[self readint32_t:&identOfBitm];
		[self seekToAddress:currentOffset];
		
		
		return (identOfBitm != 0xFFFFFFFF) ? [self tagForId:identOfBitm] : nil;
	}
	
	[self seekToAddress:currentOffset];
	return nil;
}

// I have duplicates here since I'm going to be switcing over from get_magic to _magic
- (int32_t)getMagic
{
	return _magic;
}
- (int32_t)magic
{
	return _magic;
}

-(Header)mapHeader
{
    return mapHeader;
}

- (IndexHeader)indexHead
{
	return indexHead;
}
- (NSString *)mapName
{
	return [NSString stringWithCString:mapHeader.name];
}
- (NSString *)mapLocation
{
	return mapName;
}
- (id)tagForId:(int32_t)identity
{
	//CSLog(@"Tag for ID: %d 0x%lx", [[tagLookupDict objectForKey:[NSNumber numberWithLong:identity]] intValue], identity);
    NSNumber *num = [NSNumber numberWithLong:identity];
    NSNumber *tag_dict = [tagLookupDict objectForKey:num];
    int index = [tag_dict intValue];
	return [tagArray objectAtIndex:index];
}
- (Scenario *)scenario
{
	return mapScenario;
}
- (BSP *)bsp
{
	return bspHandler;
}
- (TextureManager *)_texManager
{
	return _texManager;
}
- (void)loadAllBitmaps
{
	int x;
	int32_t tempIdent;
	
    bipd_reference *bipd_ref = [mapScenario bipd_references];
	vehicle_reference *vehi_ref = [mapScenario vehi_references];
	scenery_reference *scen_ref = [mapScenario scen_references];
	mp_equipment *mp_equip = [mapScenario item_spawns];
	//multiplayer_flags *mp_flags = [mapScenario netgame_flags];
	
	//CSLog(@"0x%x", vehi_ref[0].vehi_ref.TagId);
	//0xE3D402BC
	for (x = 0; x < [mapScenario vehi_ref_count]; x++)
	{
        USEDEBUG CSLog(@"Loading vehicles");
		if ([self isTag:vehi_ref[x].vehi_ref.TagId])
        {
            if ([[self tagForId:[mapScenario baseModelIdent:vehi_ref[x].vehi_ref.TagId]] respondsToSelector:@selector(loadAllBitmaps)])
                [(ModelTag *)[self tagForId:[mapScenario baseModelIdent:vehi_ref[x].vehi_ref.TagId]] loadAllBitmaps];
        }
	}
    /*
    for (x = 0; x < [mapScenario bipd_ref_count]; x++)
	{
        CSLog(@"Loading bipds");
		if ([self isTag:bipd_ref[x].bipd_ref.TagId])
        {
			[(ModelTag *)[self tagForId:[mapScenario baseModelIdent:bipd_ref[x].bipd_ref.TagId]] loadAllBitmaps];
        }
	}
     */
    
	for (x = 0; x < [mapScenario scen_ref_count]; x++)
	{
        USEDEBUG CSLog(@"Loading scen");
		if ([self isTag:scen_ref[x].scen_ref.TagId])
		{
			//CSLog(@"Tag id and index: [%d], index:[0x%x], next tag index:[0x%x]", x, scen_ref[x].scen_ref.TagId, scen_ref[x+1].scen_ref.TagId);
			if ([self tagForId:[mapScenario baseModelIdent:scen_ref[x].scen_ref.TagId]] != mapScenario)
            {
                ModelTag *tag = (ModelTag *)[self tagForId:[mapScenario baseModelIdent:scen_ref[x].scen_ref.TagId]];
                
                if ([tag respondsToSelector:@selector(loadAllBitmaps)])
                    [tag loadAllBitmaps];
            }
		}
	}
    for (x = 0; x < [mapScenario skybox_count]; x++)
	{
        USEDEBUG CSLog(@"Loading skybox");
        if ([self isTag:[mapScenario sky][x].modelIdent])
        {
            if ([[self tagForId:[mapScenario sky][x].modelIdent] respondsToSelector:@selector(loadAllBitmaps)])
                [(ModelTag *)[self tagForId:[mapScenario sky][x].modelIdent] loadAllBitmaps];
        }
    }
	for (x = 0; x < [mapScenario item_spawn_count]; x++)
	{
        USEDEBUG CSLog(@"Loading item");
		[self seekToAddress:([[self tagForId:mp_equip[x].itmc.TagId] offsetInMap] + 0x8C)];
		[self readint32_t:&tempIdent];
		if ([self isTag:tempIdent])
        {
            if ([[self tagForId:[mapScenario baseModelIdent:tempIdent]] respondsToSelector:@selector(loadAllBitmaps)])
                [(ModelTag *)[self tagForId:[mapScenario baseModelIdent:tempIdent]] loadAllBitmaps];
        }
	}
	for (x = 0; x < [mapScenario mach_ref_count]; x++)
	{
       USEDEBUG  CSLog(@"Loading mach");
		if ([self tagForId:[mapScenario mach_references][x].modelIdent] != mapScenario)
        {
            if ([[self tagForId:[mapScenario mach_references][x].modelIdent] respondsToSelector:@selector(loadAllBitmaps)])
                [(ModelTag *)[self tagForId:[mapScenario mach_references][x].modelIdent] loadAllBitmaps];
        }
	}
	// Then we put netgame flags in a bit
}
- (BOOL)isTag:(int32_t)tagId
{
	if (tagId == 0xFFFFFFFF)
		return NO;
	if (tagId == [mapScenario idOfTag])
		return NO;
	if ((tagId < (indexHead.tagcount + indexHead.starting_id)) || (unsigned int)tagId < (unsigned int)indexHead.starting_id)
		return NO;
	//CSLog(@"Int val: 0x%x", [[tagLookupDict objectForKey:[NSNumber numberWithLong:tagId]] intValue]);
	
	return TRUE;
}
- (NSMutableArray *)itmcList
{
	return itmcList;
}
- (NSMutableDictionary *)itmcLookup
{
	return itmcLookupDict;
}
- (NSMutableArray *)scenList
{
	return scenList;
}
- (NSMutableDictionary *)scenLookup
{
	return scenLookupDict;
}
- (NSMutableDictionary *)scenLookupByName
{
	return scenNameLookupDict;
}
- (NSMutableArray *)modTagList
{
	return modTagList;
}
- (NSMutableDictionary *)modTagLookup
{
	return modTagLookupDict;
}
- (NSMutableArray *)bitmTagList
{
	return bitmTagList;
}
- (NSMutableDictionary *)bitmLookup
{
	return bitmTagLookupDict;
}
- (NSMutableArray *)constructArrayForTagType:(char *)tagType
{
	int i,
		tagCount = 0;
	MapTag *tmptag;
	
	NSMutableArray *tmpArray;
	
	[self seekToAddress:(mapHeader.offsetToIndex + 0x40)];
	for (i = 0; i < indexHead.tagcount; i++)
	{
		tmptag = [[MapTag alloc] initWithDataFromFile:self];
		if (memcmp([tmptag tagClassHigh], tagType, 4) == 0)
			tagCount++;
		[tmptag release];
	}
	
	tmpArray = [[NSMutableArray alloc] initWithCapacity:tagCount];
	tagCount = 0;
	
	[self seekToAddress:(mapHeader.offsetToIndex + 0x40)];
	for (i = 0; i < indexHead.tagcount; i++)
	{
		tmptag = [[MapTag alloc] initWithDataFromFile:self];
		if (memcmp([tmptag tagClassHigh], tagType, 4) == 0)
		{
			[tmpArray addObject:[tmptag tagName]];
		}
		[tmptag release];
	}
	
	return tmpArray;
}
- (void)constructArrayAndLookupForTagType:(char *)tagType array:(NSMutableArray *)array dictionary:(NSMutableDictionary *)dictionary
{
	int i, 
		tagCount = 0;
	MapTag *tmptag;
	
	NSMutableDictionary *tmpDict;
	NSMutableArray *tmpArray;
	
	[self seekToAddress:(mapHeader.offsetToIndex + 0x40)];
	for (i = 0; i < indexHead.tagcount; i++)
	{
		tmptag = [[MapTag alloc] initWithDataFromFile:self];
		if (memcmp([tmptag tagClassHigh],tagType,4) == 0)
			tagCount++;
		[tmptag release];
	}

	tmpArray = [[NSMutableArray alloc] initWithCapacity:tagCount];
	tmpDict = [[NSMutableDictionary alloc] initWithCapacity:tagCount];
	tagCount = 0;
	
	[self seekToAddress:(mapHeader.offsetToIndex + 0x40)];
	for (i = 0; i < indexHead.tagcount; i++)
	{
		tmptag = [[MapTag alloc] initWithDataFromFile:self];
		if (memcmp([tmptag tagClassHigh], tagType, 4) == 0)
		{
			[tmpDict setObject:[NSNumber numberWithLong:[tmptag idOfTag]] forKey:[NSNumber numberWithInt:tagCount]];
			[tmpArray addObject:[tmptag tagName]];
		}
		[tmptag release];
	}
	
	dictionary = [tmpDict retain];
	array = [tmpArray retain];
	
	[tmpDict release];
	[tmpArray release];
}
- (NSString*)keyForItemid:(int32_t)keyv
{
    int i;
    for (i=0; i < [[itmcLookupDict allKeys] count]; i++)
    {
        NSString *key = [[itmcLookupDict allKeys] objectAtIndex:i];
        if ([[itmcLookupDict objectForKey:[NSNumber numberWithInt:key] ] longValue] == keyv)
        {
            return key;
        }
    }
    return @"Missing ID";
	//return [[itmcLookupDict objectForKey:[NSNumber numberWithInt:key]] longValue];
}
- (int32_t)itmcIdForKey:(int)key
{
	return [[itmcLookupDict objectForKey:[NSNumber numberWithInt:key]] longValue];
}
- (int32_t)modIdForKey:(int)key
{
	return [[modTagLookupDict objectForKey:[NSNumber numberWithInt:key]] longValue];
}
- (int32_t)bitmIdForKey:(int)key
{
	return [[bitmTagLookupDict objectForKey:[NSNumber numberWithInt:key]] longValue];
}
- (BOOL)saveMapToPath:(NSString*)saveURL
{
    //NSRunAlertPanel(@"You cannot save map files in this alpha version.", @"Please wait until the beta release.", @"OK", Nil, nil);
    
    //return NO;
    NSString *tempFile = @"/tmp/archon_export.map";
#ifndef MEMORY_WRITING

    //Copy the map
    if ([[NSFileManager defaultManager] fileExistsAtPath:tempFile])
        [[NSFileManager defaultManager] removeItemAtPath:tempFile error:nil];
    


    FILE *tempFilePath = fopen([tempFile cStringUsingEncoding:NSASCIIStringEncoding],"wb+");
    
    fseek(mapFile, 0, SEEK_END);
    int32_t end_address = ftell(mapFile);
    
    void *data = malloc(end_address);
    fseek(mapFile, 0, SEEK_SET);
    fread(data, end_address, 1, mapFile);
    fwrite(data, end_address, 1, tempFilePath);
    fseek(tempFilePath, 0, SEEK_SET);
    fclose(mapFile);
    free(data);

    

    //Save changes to a temportary file
    //CSLog(tempFile);
    mapFile = tempFilePath;
#endif
   
    
    
    //Lets free up some space after the scenario?
    uint32_t added_space = ADDITIONAL_SCENARIO_SPACE;
    
    if (added_space > 0)
    {
        int32_t *indexes = malloc(sizeof(int32_t)*2);
        int32_t *lengths = malloc(sizeof(int32_t)*2);
        indexes[0]=[mapScenario offsetInMap] + [mapScenario tagLength];
        lengths[0]=added_space;
        [self rebuildTagArrayToPath:[self mapLocation] withDataAtIndexes:indexes lengths:lengths offsets:1 flipped:YES isChangingData:NO];

        void *spacing_data = malloc(added_space);
        memset(spacing_data, 0, added_space);
        [self insertDataInFile:[self mapLocation] withData:spacing_data size:added_space address:[mapScenario offsetInMap] + [mapScenario tagLength]];
        free(spacing_data);
    }
    
    [mapScenario rebuildScenario];
    [mapScenario saveScenario];
    
    
    
        //Add new tags to the file
        //Add the new tags
        int32_t oldTagCount = indexHead.tagcount;
        CSLog(@"Adding new tags %ld %d", oldTagCount, [tagArray count]);
        int itemtagLength = 32;
        
        int newTags = [tagArray count]-oldTagCount;
    
    
    if (newTags > 0)
    {
        int32_t dataLength = newTags*itemtagLength;
        
        //Loop through all of the tags and update
        int32_t newOffset = indexHead.indexMagic+mapHeader.offsetToIndex-0x40440000;
        [self seekToAddress:newOffset];
        int32_t insertEnd = newOffset + oldTagCount*itemtagLength;
        
        //NOW, update the old file
        CSLog(saveURL);
        
        int32_t *insEnd = malloc(1);
        insEnd[0]=insertEnd;
        int32_t *datLen = malloc(1);
        datLen[0]=dataLength;
        
        int i;
        
        //Fix the new tags offset
        /*
        for (i = oldTagCount; i < [tagArray count]; i++)
        {
            MapTag *tag = [tagArray objectAtIndex:i];
            int32_t offset = [tag rawOffset];
            
            if (offset-_magic >= insertEnd)
            {
                offset+=dataLength;
                CSLog(@"Updating for tag %@ offset 0x%lx 0x%lx to 0x%lx", [tag tagName], newOffset+i*itemtagLength+16, offset-dataLength, offset);
            }
            
            [tag updateOffset:offset withMap:self];
        }
        */
        
        [self rebuildTagArrayToPath:tempFile withDataAtIndexes:insEnd lengths:datLen offsets:1 flipped:YES isChangingData:NO];
        
        void *tagSpace = malloc(dataLength);
        memset(tagSpace, 0, dataLength);
        CSLog(@"Set memory");

        
        for (i = oldTagCount; i < [tagArray count]; i++)
        {
            MapTag *tag = [tagArray objectAtIndex:i];
            int dataOffset = (i-oldTagCount)*itemtagLength;
            
            char *classA = [tag tagClassHigh];
            char *classB = [tag tagClassB];
            char *classC = [tag tagClassC];
            int32_t identity = [tag idOfTag];
            int32_t stringOffset = [tag stringOffset];
            int32_t offset = [tag rawOffset];
            int32_t someNumber = [tag num1];
            int32_t someNumber2 = [tag num2];
            
            
             //Update the offsets
             if (stringOffset-_magic >= insertEnd)
                 stringOffset+=dataLength;
            
            
             if (offset-_magic >= insertEnd)
             {
                 offset+=dataLength;
                 CSLog(@"Updating for tag %@ offset 0x%lx 0x%lx to 0x%lx", [tag tagName], newOffset+i*itemtagLength+16, offset-dataLength-_magic, offset-_magic);
             }
            
            
            //Write all of the tag data to the file
            memcpy(tagSpace+dataOffset  , classA, 4);
            memcpy(tagSpace+dataOffset+ 4, classB, 4);
            memcpy(tagSpace+dataOffset+ 8, classC, 4);
            memcpy(tagSpace+dataOffset+12, (int32_t*)(&identity), 4);
            memcpy(tagSpace+dataOffset+16, (int32_t*)(&stringOffset), 4);
            memcpy(tagSpace+dataOffset+20, (int32_t*)(&offset), 4);
            memcpy(tagSpace+dataOffset+24, (int32_t*)(&someNumber), 4);
            memcpy(tagSpace+dataOffset+28, (int32_t*)(&someNumber2), 4);
        }
        
        CSLog(@"Inserting new tags %ld", dataLength);
        [self insertDataInFile:tempFile withData:tagSpace size:dataLength address:insertEnd];
   
        
        //Loop through all of the tags and update
        newOffset = indexHead.indexMagic+mapHeader.offsetToIndex-0x40440000;
        [self seekToAddress:newOffset];
        
        //Repair the program status
        for (i = 0; i < [tagArray count]; i++)
        {
            [self seekToAddress:newOffset+i*32];
            [[tagArray objectAtIndex:i] updateTag:self];
        }
    }
    
    //Update the scenario tag
    //[self seekToAddress:globalScenarioOffset];
    [mapScenario updateReflexiveOffsetsFromFile];
    
    
#ifdef MEMORY_WRITING
    //Output the map memory to the file
    FILE *outfile = fopen([saveURL cStringUsingEncoding:NSASCIIStringEncoding], "wb+");
    fwrite(map_memory, 1, globalMapSize, outfile);
    fclose(outfile);
#else
    //Copy the temp file to the save URL
    [[NSFileManager defaultManager] copyItemAtPath:tempFile toPath:saveURL error:nil];

    fclose(mapFile);
    mapFile = fopen([mapName cStringUsingEncoding:NSASCIIStringEncoding],"rb+");
#endif
    
	return YES;//[mapScenario saveScenarioToFile:saveURL];
}

- (void)saveMap
{
	CSLog(@"hur?");
	[mapScenario rebuildScenario];
	CSLog(@"Or hur!?");
	[mapScenario saveScenario];
	CSLog(@"Asdf.");
	
    //Export all of the textures.
    
    
	//[mapScenario loadScenario];
    
	//bspHandler
	
    [[bspHandler mesh] exportTextures];
	
	//WRITE THE BSP MESH
	//[[bspHandler mesh] writePcSubmeshes];
	//[self writeAnyDataAtAddress:scnr size:[self tagLength] address:[self offsetInMap]];
}
@synthesize mapFile;
@synthesize bitmapFilePath;
@synthesize bitmapsFile;
@synthesize mapScenario;
@synthesize bspHandler;
@synthesize _texManager;
@synthesize _magic;
@synthesize tagArray;
@synthesize tagLookupDict;
@synthesize itmcList;
@synthesize itmcLookupDict;
@synthesize scenList;
@synthesize scenLookupDict;
@synthesize scenNameLookupDict;
@synthesize modTagList;
@synthesize modTagLookupDict;
@synthesize bitmTagList;
@synthesize bitmTagLookupDict;
@end
