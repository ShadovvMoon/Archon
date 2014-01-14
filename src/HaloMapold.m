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
	NSLog(@"Mapfile deallocating!");
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
int comp(const long *a, const long *b)
{
    if (*a == *b)
        return 0;
    else if (*a < *b)
        return -1;
    else
        return 1;
}
- (int)loadMap
{
	// Quick hack
	isPPC = NO;
	
	// Use this for computing the tag location, mmk?
	if (mapName == nil)
		return 2;
	
	mapFile = fopen([mapName cStringUsingEncoding:NSASCIIStringEncoding],"rb+");
	
	if (!mapFile)
	{
		NSLog(mapName);
		NSLog(@"Cannot read map.");
		return 3;
	}
    
    //NSLog(bitmapFilePath);
	
	bitmapsFile = fopen([bitmapFilePath cString], "rb+");
	
	// Lets load the map header, ok?
	[self readLongAtAddress:&mapHeader.map_id address:0x0];
	
	//#ifdef __DEBUG__
	printf("\n");
	//NSLog(@"Header: 0x%x, swapped: 0x%x", mapHeader.map_id, EndianSwap32(mapHeader.map_id));
	//#endif
	
	/* LETS SEE WHAT DIS IS */
	isPPC = [self checkIsPPC];
	/* SO IS IT PPC OR NOT?! */
	
	// Reload the map header
	[self readLongAtAddress:&mapHeader.map_id address:0x0];
	
	BOOL tmpPPC = isPPC;
	
	int super_mode = 0;
    long mapLocation;
	//NSLog(@"MAP ID: %d", (int)mapHeader.map_id);
	if (mapHeader.map_id == 0x18309 || mapHeader.map_id == 50028 || mapHeader.map_id == 0x0 || super_mode)
	{
		mapHeader.version = 0x06000000;
		isPPC = NO;
		[self readBlockOfDataAtAddress:&mapHeader.builddate size_of_buffer:0x20 address:0x2C8]; // Map seeked to 0x2C4 now.
		[self readBlockOfDataAtAddress:&mapHeader.name size_of_buffer:0x20 address:0x58C];
		isPPC = tmpPPC;
		[self readLongAtAddress:&mapHeader.map_length address:0x5E8];
		[self readLong:&mapHeader.offsetToIndex];
		mapHeader.maptype = 0x01000000;
	}
	else
	{
		[self readLong:&mapHeader.version]; //Check for halo2
		[self readLong:&mapHeader.map_length]; //Check for halo2
		[self readLong:&mapHeader.zeros]; //Not sure
        
        mapLocation = [self currentOffset];
        NSLog(@"INDEX OFFSET LOCATION 0x%lx", mapLocation);
        
		[self readLong:&mapHeader.offsetToIndex];
		[self readLong:&mapHeader.metaSize];
        
        if (mapHeader.version == 8) //Halo 2
        {
            [self skipBytes:396];
            
            isPPC = NO;
            [self readBlockOfData:&mapHeader.name size_of_buffer:0x20];
            [self readBlockOfData:&mapHeader.builddate size_of_buffer:0x20];
            isPPC = tmpPPC;
            [self readLong:&mapHeader.maptype];
            
        }
        else //Halo 1
        {
            [self skipBytes:8];
        
            isPPC = NO;
            [self readBlockOfData:&mapHeader.name size_of_buffer:0x20];
            [self readBlockOfData:&mapHeader.builddate size_of_buffer:0x20];
            isPPC = tmpPPC;
            [self readLong:&mapHeader.maptype];
        }
        
	}
	
	#ifdef __DEBUG__
	NSLog(@"File Header Version: 0x%x", mapHeader.version);
	NSLog(@"File Length: 0x%x", mapHeader.map_length);
	NSLog(@"Offset To Index: 0x%x", mapHeader.offsetToIndex);
	NSLog(@"Total Metadata Size: 0x%x", mapHeader.metaSize);
    NSLog(@"Map type: 0x%x", mapHeader.maptype);
    
	NSLog(@"File Name: %s \n", (char *)mapHeader.name);
	NSLog(@"Build Date: %s \n", (char *)mapHeader.builddate);
	#endif
    
    if (mapHeader.version == 8) //Halo 2
    {
        [self readLongAtAddress:&indexHead.indexMagic address:mapHeader.offsetToIndex];
        [self readLong:&indexHead.tagcount];
        [self readLong:&indexHead.vertex_offset];
        [self skipBytes:0x4]; //scenarioId
        [self readLong:&indexHead.starting_id];
        [self skipBytes:0x4]; //unknown
        [self readLong:&indexHead.vertex_object_count];
        [self skipBytes:0x4]; //tags
    }
    else
    {
        // Index time!
        [self readLongAtAddress:&indexHead.indexMagic address:mapHeader.offsetToIndex];
        [self readLong:&indexHead.starting_id];
        [self readLong:&indexHead.vertexsize];
        
        mapLocation = [self currentOffset];
        NSLog(@"TAG COUNT COUNT 0x%lx", mapLocation);
        
        [self readLong:&indexHead.tagcount];
        NSLog(@"TAG COUNT %ld", indexHead.tagcount);
        
        
        [self readLong:&indexHead.vertex_object_count];
        [self readLong:&indexHead.vertex_offset];
        
        mapLocation = [self currentOffset];
        NSLog(@"INDEX COUNT 0x%lx", mapLocation);
        [self readLong:&indexHead.indices_object_count];
        [self readLong:&indexHead.vertex_size];
        [self readLong:&indexHead.modelsize];
        [self readLong:&indexHead.tagstart];
    }
	
    /*
    NSLog(@"Offset To Index: 0x%x", mapHeader.offsetToIndex);
	NSLog(@"Tag count: %d", indexHead.tagcount);
	NSLog(@"Tag starting id: 0x%x", indexHead.starting_id);
    NSLog(@"Tag starting: %d", indexHead.tagstart);
    */
    
    
	_magic = (indexHead.indexMagic - (mapHeader.offsetToIndex + 40));
	
	#ifdef __DEBUG__
	NSLog(@"Magic: [0x%x]", _magic);
    NSLog(@"Index Offset: [0x%x]", mapHeader.offsetToIndex);
    
    //0x40440000
    
    //indexHead.indexMagic = 0x40440028;
    //_magic = (indexHead.indexMagic - 0x40440000);
	//NSLog(@"New Magic: [0x%x]", _magic);
    NSLog(@"Primary Magic: [0x%x]", indexHead.indexMagic);
    
    
    
	printf("\n");
	#endif
    
    
	//0x1400000
    long offset = 0x40440000;
    if (mapHeader.version == 8) //Halo 2
    {
        offset=0x1400000;
    }
    
    
    //Beat the protection
    long someOffset = offset-mapHeader.offsetToIndex;
    long newOffset = indexHead.indexMagic-someOffset;
    
    if (mapHeader.version == 8) //Halo 2
    {
        newOffset = someOffset;
    }
    

    [self seekToAddress:newOffset];
    
    
    
	// Now lets create and load our tag arrays
    originalTagCount = indexHead.tagcount;
    
    NSLog(@"Capacity3 %ld 0x%lx", indexHead.tagcount);
	tagArray = [[NSMutableArray alloc] initWithCapacity:indexHead.tagcount];
	tagLookupDict = [[NSMutableDictionary alloc] initWithCapacity:indexHead.tagcount];
	NSLog(@"Capacity2");
    
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
		bitm_count = 0,
		nextOffset,
		scenario_offset,
		globals_offset,
		itmc_counter = 0,
		scen_counter = 0,
		mod2_counter = 0,
		bitm_counter = 0,
		mach_counter = 0;
		
	NSMutableArray *mach_offsets = [[NSMutableArray alloc] init];
	plugins = [[NSMutableArray alloc] init];
    tagIdArray = [[NSMutableArray alloc] init];
    
    tagFastArray = malloc(sizeof(long)*indexHead.tagcount);
    tagArraySize = 0;
    
    char *cleaned = malloc(4);
    int scnrTag = 0;
    long tagLocation;
	for (i = 0; i < indexHead.tagcount; i++)
	{
		int r = 1;
        tagLocation=[self currentOffset];
		tempTag = [[MapTag alloc] initWithDataFromFile:self];
		nextOffset = [self currentOffset];
		
		//NSLog(@"Tag name: %@, id: 0x%x, offset in map: 0x%x offset in mapfile: 0x%x  %@", [tempTag tagName], [tempTag idOfTag], [tempTag offsetInMap],[self currentOffset], [NSString stringWithCString:[tempTag tagClassHigh] encoding:NSMacOSRomanStringEncoding]);
	
		if (i != 0)//Surely theres a better methid?
        {
            
            if ([[tagArray objectAtIndex:(i - 1)] offsetInMap] > [tempTag offsetInMap])
            {
                //Stupid 002's protection
                //NSLog(@"Protected");
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
        [tagIdArray addObject:[NSNumber numberWithLong:[tempTag idOfTag]]];
    
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
			//NSLog(@"GLOBALS ARRAY");
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
            if ([[tempTag tagName] rangeOfString:@"warthog"].location != NSNotFound)
            {

            }
            
            NSLog(@"%@ 0x%lx 0x%lx", [tempTag tagName], [tempTag offsetInMap], tagLocation);
			ModelTag *tempModel = [[ModelTag alloc] initWithMapFile:self texManager:_texManager];
            [tagArray addObject:tempModel];
            
            /*NSLog([tempTag tagName]);
            if ([[tempTag tagName] rangeOfString:@"cyborg\\cyborg"].location != NSNotFound)
            {
                
                //NSLog(@"FOUND SKY");

                bipd = tempModel;
                //[tempModel loadAllBitmaps];
                [bipd retain];
            }
            else
            {
               
            }*/
            
            //NSLog(@"Releasing geometry objects");
           
            
			//[tempModel releaseGeometryObjects];
			//[tempModel release];
			
			// Increment our counter
			mod2_count++;
			
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
    qsort(tagFastArray, indexHead.tagcount, sizeof(long), comp);
    tagArraySize = indexHead.tagcount;
    
    NSLog(@"Capacity1");
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

    long tagOffset;
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
			[modTagLookupDict setObject:[NSNumber numberWithLong:[tempTag idOfTag]] forKey:[NSNumber numberWithInt:mod2_counter]];
			[modTagList addObject:[tempTag tagName]];
			mod2_counter++;
		}
		else if (memcmp([tempTag tagClassHigh], (isPPC ? "bitm" : "mtib"), 4) == 0)
		{
			[bitmTagLookupDict setObject:[NSNumber numberWithLong:[tempTag idOfTag]] forKey:[NSNumber numberWithInt:bitm_counter]];
			[bitmTagList addObject:[tempTag tagName]];
			
            if (i < [tagArray count])
            {
                NSLog(@"BITMAP %@ %ld", [[tagArray objectAtIndex:i] tagName], tagOffset);
                [_texManager addTexture:[tagArray objectAtIndex:i]];
                
                bitm_counter++;
            }
		}
		
		if (r)
			[tempTag release];
	}
    

    //Third pass
    long current = [self currentOffset];
    int g;
    for (g = 0; g < [bipdList count]; g++)
	{
		tempTag = [bipdList objectAtIndex:g];
		
        if (memcmp([tempTag tagClassHigh], (isPPC ? "bipd" : "dpib"), 4) == 0)
        {
            
            long modelOffset =  [tempTag offsetInMap] + 0x28;
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
	
	USEDEBUG NSLog(@"Loading map...");
	[self seekToAddress:scenario_offset];
    USEDEBUG NSLog(@"Allocating");
	mapScenario = [[Scenario alloc] initWithMapFile:self];
	//USEDEBUG NSLog([tagArray description]);
    
    USEDEBUG NSLog(@"Tag count: %d", [tagArray count]);
    USEDEBUG NSLog(@"%d", [[tagArray objectAtIndex:scnrTag] tagLength]);
	[mapScenario setTagLength:[[tagArray objectAtIndex:scnrTag] tagLength]];

#ifdef __DEBUG__
	if ([mapScenario loadScenario])
		NSLog(@"Scenario Loaded!");
	#else
	[mapScenario loadScenario];
	#endif
	[mapScenario pairModelsWithSpawn];
	[tagArray replaceObjectAtIndex:0 withObject:mapScenario];
	
	// Then we load the BSP
	bspHandler = [[BSP alloc] initWithMapFile:self texManager:_texManager];
	[bspHandler loadVisibleBspInfo:[mapScenario header].StructBsp version:mapHeader.version];
	[bspHandler setActiveBsp:0];
	

    
	if ([mapScenario mach_ref_count] < mach_counter)
	{
		int response = NSRunAlertPanel(@"Machines detected", @"Swordedit has detected machinery tags which are not referenced in the scenario. Would you like to rebuild references?", @"No", @"OK", nil);
		if (response != NSOKButton)
		{
		
			[mapScenario resetMachineReferences];
			
			NSLog(@"CREATING MACHINE REFERENCES");
			//CREATE THE MACHINE REFERENCES
			NSLog(@"Total machines... %d", [mach_offsets count]);
			for (i=0; i<[mach_offsets count];i++)
			{
				MapTag *tag = [mach_offsets objectAtIndex:i];
                NSLog([tag stringTagClassHigh]);
                
				TAG_REFERENCE machine;
				
				machine.tag[0] = 'h';
				machine.tag[1] = 'c';
				machine.tag[2] = 'a';
				machine.tag[3] = 'm';
				
                machine.unknown = 0;
				machine.NamePtr = [tag stringOffset];
				machine.TagId = [tag idOfTag];
				
				NSLog(@"Creating reference %d", i);
				
				[mapScenario createMachineReference:machine];
			}
			
		}
	}
	
	
	/*NSLog(@"BSPs are loaded!");
	printf("\n");
	
	NSLog(@"Scenery spawn count: %d", [mapScenario scenery_spawn_count]);
	NSLog(@"Vehicle spawn count: %d", [mapScenario vehicle_spawn_count]);
	NSLog(@"Item spawn count: %d", [mapScenario item_spawn_count]);
	NSLog(@"Player spawn count: %d", [mapScenario player_spawn_count]);
	NSLog(@"Machine spawn count: %d", [mapScenario mach_spawn_count]);*/
    
    
	//NSLog([machLookupDict description]);
	// Now lets load all of the bitmaps for shit
    
    if ([self respondsToSelector:@selector(loadAllBitmaps)])
    {
        //NSLog(@"LOADING BITMAPS");
        [self loadAllBitmaps];
    }
	
    
    
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
        long modelIdent = [mapScenario baseModelIdent:[mapScenario scen_references][m].scen_ref.TagId];
        ModelTag *model = [self tagForId:modelIdent];
        
        if ([model respondsToSelector:@selector(generateImage:)])
        [model generateImage:[NSString stringWithFormat:@"/tmp/Archon/scen/%@.tiff", name]];
    }
    
    for (m=0; m < [mapScenario vehi_ref_count]; m++)
    {
        NSString *name = [[self tagForId:[mapScenario vehi_references][m].vehi_ref.TagId] tagName];
        long modelIdent = [mapScenario baseModelIdent:[mapScenario vehi_references][m].vehi_ref.TagId];
        ModelTag *model = [self tagForId:modelIdent];
        
        if ([model respondsToSelector:@selector(generateImage:)])
        [model generateImage:[NSString stringWithFormat:@"/tmp/Archon/vehi/%@.tiff", name]];
    }
    
    for (m=0; m < [mapScenario mach_ref_count]; m++)
    {
        NSString *name = [[self tagForId:[mapScenario mach_references][m].machTag.TagId] tagName];
        long modelIdent = [mapScenario baseModelIdent:[mapScenario mach_references][m].machTag.TagId];
        ModelTag *model = [self tagForId:modelIdent];
        
        if ([model respondsToSelector:@selector(generateImage:)])
        [model generateImage:[NSString stringWithFormat:@"/tmp/Archon/mach/%@.tiff", name]];
    }
    
    [renderV updateObjectTable];
    
	//NSLog(@"LOGGING THE TARG INFO");
	//NSLog([tagArray description]);

	return 0;
}

-(void)rebuildTagArrayToPath:(NSString*)filename withDataAtIndexes:(long*)insertEnd lengths:(long*)dataLength offsets:(int)tagdatacount
{
    NSLog(@"REBUILDING TAG ARRAY");
    NSLog(@"%ld %d", indexHead.tagcount, [tagArray count]);
    
    int i;
    int itemtagLength = 32;
    //int newTags = [tagArray count]-indexHead.tagcount;
    //int dataLength = newTags*itemtagLength;

	// Reload the map header
    /*
	[self readLongAtAddress:&mapHeader.map_id address:0x0];
    [self readLong:&mapHeader.version]; //Check for halo2
    [self readLong:&mapHeader.map_length]; //Check for halo2
    [self readLong:&mapHeader.zeros]; //Not sure
    [self readLong:&mapHeader.offsetToIndex];
    [self readLong:&mapHeader.metaSize];
    [self readBlockOfData:&mapHeader.name size_of_buffer:0x20];
    [self readBlockOfData:&mapHeader.builddate size_of_buffer:0x20];
    [self readLong:&mapHeader.maptype];
    */
    //mapFile = fopen([filename cString],"rwb+");
    
    // Index time!
    //[self writeLongAtAddress:[tagArray count] address:mapHeader.offsetToIndex+12];
    
    
    
    
    //------------------------------------------------------------------------------------------
    // Updates the index offsets if any data is written before them. Also updates the tag totals
    //------------------------------------------------------------------------------------------

    NSLog(@"Writing new tag count");
    long oldTagCount = indexHead.tagcount;
    
    long offsetToIndex;
    [self readLongAtAddress:&offsetToIndex address:0x10];
    
    NSLog(@"Original offset 0x%lx", offsetToIndex);
   
    int g;
    for (g=0; g< tagdatacount; g++)
    {
        if (indexHead.indexMagic + offsetToIndex - 0x40440000 >= insertEnd[g])
        {
            offsetToIndex+=dataLength[g];
            [self writeLongAtAddress:(long*)(&offsetToIndex) address:0x10];
        }
    }
    
    mapHeader.offsetToIndex = offsetToIndex;
    
    long newData = 0;
    for (g=0; g< tagdatacount; g++)
    {
        newData+=dataLength[g];
    }
    
    NSLog(@"Total new data: %ld", newData);
    NSLog(@"New offset 0x%lx", offsetToIndex);
    
    //Update the tag counter
    long newCount = [tagArray count];
    [self writeLongAtAddress:(long*)(&newCount) address:mapHeader.offsetToIndex+12];
    NSLog(@"Tags offset %ld 0x%lx", newCount, mapHeader.offsetToIndex+12);
    
    indexHead.tagcount = newCount;
    
    //Loop through all of the tags and update
    long newOffset = indexHead.indexMagic + mapHeader.offsetToIndex - 0x40440000;
    [self seekToAddress:newOffset];

    long tagEnd = newOffset + indexHead.tagcount*itemtagLength;
    
    //NSMutableArray *alreadyUpdated = [[NSMutableArray alloc] initWithCapacity:3000];
    
    //Update tag offsets
    //NSLog(@"Updating tag offsets %lx %ld %d %d", newOffset, indexHead.tagcount, dataLength, insertEnd);
    
    
    
    //------------------------------------------------------------------------------------------
    // Loops through the tags in the mapfile and updates the offsets to account for any added previous data
    //------------------------------------------------------------------------------------------

    NSLog(@"Updating tag index offsets for tags %d", oldTagCount);
    for (i = 0; i < oldTagCount; i++)
	{
        [self seekToAddress:newOffset+i*itemtagLength];
        long originalOffset, originalOffset2;
        
        //Update the string offset
        [self readLongAtAddress:&originalOffset address:newOffset+i*itemtagLength+16];

        int g;
        for (g=0; g< tagdatacount; g++)
        {
            if (originalOffset-[self magic] >= insertEnd[g])
            {
                originalOffset+=dataLength[g];
                [self writeLongAtAddress:(long*)(&originalOffset) address:newOffset+i*itemtagLength+16];
            }
        }

        //Update the next offset
        [self seekToAddress:newOffset+i*itemtagLength+20];
        [self readLong:&originalOffset2];
        
        long originalOffsetStr = originalOffset2;
        for (g=0; g < tagdatacount; g++)
        {
            if (originalOffset2-[self magic] >= insertEnd[g])
            {
                originalOffset2+=dataLength[g];
                [self writeLongAtAddress:(long*)(&originalOffset2) address:newOffset+i*itemtagLength+20];
            }
        }
        
        NSLog(@"Changed offset 0x%lx 0x%lx 0x%lx 0x%lx", originalOffsetStr-[self magic] , originalOffset2-[self magic], insertEnd[0], newOffset+i*itemtagLength);
    }
    
    
    //------------------------------------------------------------------------------------------
    // Loops through the tag array and updates the offsets for the tags.
    //------------------------------------------------------------------------------------------

    //Update the tag arrays
    NSLog(@"Updating tag array");
    for (i = 0; i < oldTagCount; i++)
	{
        [self seekToAddress:newOffset+i*itemtagLength];
        [[tagArray objectAtIndex:i] updateTag:self];
    }
    
    //------------------------------------------------------------------------------------------
    // Loads the map file into memory
    //------------------------------------------------------------------------------------------
    
    fseek(mapFile, 0L, SEEK_END);
    long size = ftell(mapFile);
    long *mapdata = malloc(size);
    fseek(mapFile, 0L, SEEK_SET);
    fread(mapdata, size, 1, mapFile);
    
    //------------------------------------------------------------------------------------------
    // Loops through the tag array and updates any reflexives. Changes are stored in the map file
    //------------------------------------------------------------------------------------------
    
    long tempValue, prevValue = 0;
    NSLog(@"Fix reflexive offsets");
    for (i = 0; i < [tagArray count]; i++)
	{
        MapTag *mapstag = [tagArray objectAtIndex:i];
        
        long offsetInMap = [mapstag offsetInMap];
        long tagLength = [mapstag tagLength];
       
        NSLog(@"%.4s %@ %ld 0x%lx 0x%lx", [mapstag tagClassHigh], [mapstag tagName], tagLength, offsetInMap, size);
        
        if (tagLength <= 0)
            continue;
        
        int a;
        for (a=0; a < tagLength; a+=4)
        {
            long location = offsetInMap + a;
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
            
            tempValue = mapdata[location / 4];
            if (tempValue != 0 && tempValue != 0xFFFFFFFF && tempValue != 0xCACACACA)
            {
                
                long pos = tempValue - _magic;
                if (pos <= offsetInMap+tagLength && pos >= offsetInMap && pos > location)
                {
                    //NSLog(@"Searching reflexive 0x%lx 0x%lx", location, pos);

                    if (a>=4)
                    {
                        long count, zeroes;
                        count = prevValue;
                        count = mapdata[(location / 4) - 1];
                        
                        if (count > 0)
                        {
                            if (location+4 < offsetInMap+tagLength)
                            {
                                zeroes = mapdata[(location / 4) + 1];
                                if (zeroes == 0)
                                {
                                    
                                    
                                    mapdata[location / 4] = 0;
                                    
                                    /*
                                    NSNumber *location_number = [NSNumber numberWithLong:location];
                                    if ([alreadyUpdated containsObject:location_number])
                                    {
                                        prevValue = tempValue;
                                        continue;
                                    }
                                    
                                    [alreadyUpdated addObject:location_number];
                                    */
                                    //NSLog(@"Updating reflexive 0x%lx 0x%lx", location, pos);

                                    long newOffsetLong=tempValue;
                                    int g;
                                    for (g=0; g< tagdatacount; g++)
                                    {
                                        if (newOffsetLong-[self magic] >= insertEnd[g])
                                        {
                                            newOffsetLong+=dataLength[g];
                                            if (![self writeLongAtAddress:(long*)(&newOffsetLong) address:location])
                                            {
                                                NSLog(@"WRITE ISSUE");
                                            }
                                        }
                                    }
                                    
                                    NSLog(@"Updating reflexive to 0x%lx", newOffsetLong);
                                }
                            }
                        }
                    }
                }
            }
            
            prevValue = tempValue;
        }
    }
    
    //------------------------------------------------------------------------------------------
    // Reloads the map file into memory to include new reflexive offsets
    //------------------------------------------------------------------------------------------

    free(mapdata);
    
    fseek(mapFile, 0L, SEEK_SET);
    fseek(mapFile, 0L, SEEK_END);
    long mapSize = ftell(mapFile);
    long *mapdata_new = malloc(size);
    fseek(mapFile, 0L, SEEK_SET);
    fread(mapdata_new, size, 1, mapFile);
    
    long vertexSize = [self indexHead].vertex_size;
    long vertexOffset = [self indexHead].vertex_offset;
    
    //------------------------------------------------------------------------------------------
    // Loop through the tag array and update the model data.
    // All tag offsets and reflexives should have the correct location.
    //------------------------------------------------------------------------------------------

    for (i = 0; i < [tagArray count]; i++)
	{
        MapTag *mapstag = [tagArray objectAtIndex:i];
        
        long offsetInMap = [mapstag offsetInMap];
        long tagLength = [mapstag tagLength];
        
        if (memcmp([mapstag tagClassHigh], "2dom", 4) == 0)
        {
            NSLog(@"Updating model data %@ 0x%lx 0x%lx", [mapstag tagName], [mapstag offsetInMap], [mapstag offsetInIndex]-32);
            
            //modelData
            long initial = ([mapstag offsetInMap]+48+4+4+140+12);
            long chunk_count = mapdata_new[initial / 4]; initial+=4;
            
            NSLog(@"Offset 0x%lx", initial);
            
            long geometry_offset = mapdata_new[(initial / 4)];
            long geoOffsetResolved = geometry_offset-[self magic];
            
            NSLog(@"Chunk count: %ld 0x%lx", chunk_count, geoOffsetResolved);
            
            int a;
            for (a=0; a < chunk_count; a++)
            {
                long parts_count, parts_offset;
                initial = (geoOffsetResolved + (a * 48)) + 36;
                
                if (initial < 0 || initial >= mapSize)
                {
                    continue;
                }
                
                parts_count = mapdata_new[(initial / 4)]; initial+=4;
                parts_offset = mapdata_new[(initial / 4)];
                initial = parts_offset-[self magic];
                
                NSLog(@"Parts: %ld 0x%lx 0x%lx", parts_count, initial, (geoOffsetResolved + (a * 48)) + 36);
                
                int x;
                for (x=0; x < parts_count; x++)
                {
                    initial+=72;
                    
                    long indexPointer_count, indexPointerRaw1, indexPointerRaw2;
                    long vertPointer_count, vertPointerRaw;

                    if (initial < 0 || initial >= mapSize)
                    {
                        break;
                    }
                    
                    
                    indexPointer_count = mapdata_new[(initial / 4)]; initial+=4;
                    
                    long indexLocation = initial;
                    indexPointerRaw1 = mapdata_new[(initial / 4)]; initial+=4;
                    indexPointerRaw2 = mapdata_new[(initial / 4)]; initial+=4;
                    initial+=4;
                    vertPointer_count = mapdata_new[(initial / 4)]; initial+=4;
                    initial+=8;
                    
                    long vertLocation = initial;
                    vertPointerRaw = mapdata_new[(initial / 4)]; initial+=4;
                    initial+=28;
                    
                    long endOfPart = initial;
                    
                    //Update vertex pointer
                    int g;
                    for (g=0; g< tagdatacount; g++)
                    {
                        if (vertPointerRaw+vertexOffset >= insertEnd[g])
                        {
                            vertPointerRaw+=dataLength[g];
                            [self writeLongAtAddress:(long*)(&vertPointerRaw) address:vertLocation];
                        }
                    }
                    
                    //Update index pointer
                    for (g=0; g< tagdatacount; g++)
                    {
                        if (indexPointerRaw1+vertexOffset+vertexSize >= insertEnd[g])
                        {
                            indexPointerRaw1+=dataLength[g];
                            indexPointerRaw2+=dataLength[g];
                            [self writeLongAtAddress:(long*)(&indexPointerRaw1) address:indexLocation];
                            [self writeLongAtAddress:(long*)(&indexPointerRaw2) address:indexLocation+4];
                        }
                    }
                    
                    initial = endOfPart;
                }
            }
        }
    }
    
    free(mapdata_new);
   
    NSLog(@"Done!");
    
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
	fclose(mapFile);
    
	fclose(bitmapsFile);
}
- (void)setFile:(FILE *)map
{
	mapFile = map;
}
- (FILE *)currentFile
{
	return mapFile;
}
- (BOOL)isPPC
{
	return isPPC;
}
- (void)seekToAddress:(unsigned long)address
{
	fseek(mapFile, address, SEEK_SET);
}
- (void)skipBytes:(long)bytesToSkip
{
	fseek(mapFile, (ftell(mapFile) + bytesToSkip), SEEK_SET);
}
- (void)reverseBytes:(long)bytesToSkip
{
	fseek(mapFile, (ftell(mapFile) - bytesToSkip), SEEK_SET);
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
/* This is directly accessing the buffer, dammit */
- (BOOL)write:(void *)buffer size:(int)size
{
    //NSLog(@"Writing to map");
    
    
	int i;
	if (isPPC)
	{
        NSLog(@"PPC Write");
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
			long *pointLong = buffer;
			long tmpLong;
			for (i = 0; i < (size / 4); i++)
			{	
				tmpLong = EndianSwap32(pointLong[i]);
				fwrite(&tmpLong, 4, 1, mapFile);
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
- (BOOL)writeLong:(long *)myLong
{
	if (fwrite(myLong, sizeof(long),1,mapFile) == 1)
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
- (BOOL)writeByteAtAddress:(void *)byte address:(unsigned long)address
{
	fseek(mapFile, address, SEEK_SET);
	if (fwrite(byte,1,1,mapFile) == 1)
		return YES;
	else
		return NO;
}
- (BOOL)writeFloatAtAddress:(float *)toWrite address:(unsigned long)address
{	
	fseek(mapFile, address, SEEK_SET);
	if (fwrite(toWrite, sizeof(float),1,mapFile) == 1)
		return YES;
	else
		return NO;
}
- (BOOL)writeIntAtAddress:(int *)myInt address:(unsigned long)address
{
	fseek(mapFile, address, SEEK_SET);
	if (fwrite(myInt, sizeof(int),1,mapFile) == 1)
		return YES;
	else
		return NO;
}
- (BOOL)writeLongAtAddress:(long *)myLong address:(unsigned long)address
{
	fseek(mapFile, address, SEEK_SET);
	if (fwrite(myLong, sizeof(long),1,mapFile) == 1)
		return YES;
	else
		return NO;
}

- (BOOL)insertDataInFile:(NSString*)filename withData:(void *)data size:(unsigned int)newsize address:(unsigned long)address
{
    //NSLog(mapName);
    //NSLog(filename);
    
    isPPC = NO;

    NSLog(@"Logging");
    NSLog(@"Open map %d 0x%lx", newsize, address);
    //FILE *oldMap = mapFile;
    
    char *start_data = malloc(address);
    if (![self readBlockOfDataAtAddress:start_data size_of_buffer:address address:0])
        NSLog(@"READ ERROR");
    
    fseek(mapFile, 0, SEEK_END);
    
    long size = ftell(mapFile);
    NSLog(@"Size %ld", size);
    
    long readSize = size-address;
    char *data_buffer = malloc(readSize);
    
    NSLog(@"Reading buffer %ld", readSize);
    if (![self readBlockOfDataAtAddress:data_buffer size_of_buffer:readSize address:address])
        NSLog(@"READ ERROR");
    
    FILE *oldMap;
    if ([filename isEqualToString:mapName])
        oldMap = mapFile;
    else
        oldMap = fopen([filename cStringUsingEncoding:NSASCIIStringEncoding],"wb+");
    
    NSLog(@"Writing to %@", filename);
    
    fseek(oldMap, 0, SEEK_SET);
    fwrite(start_data, address, 1, oldMap);
    fwrite(data, newsize, 1, oldMap);
    fwrite(data_buffer, readSize, 1, oldMap);
    
    if ([filename isEqualToString:mapName])
        mapFile = oldMap;
    else
        fclose(oldMap);
    
    return YES;
}

- (BOOL)writeAnyDataInFile:(NSString*)filename atAddress:(void *)data size:(unsigned int)size address:(unsigned long)address
{
    //NSLog(mapName);
    //NSLog(filename);
    
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

- (BOOL)writeAnyDataAtAddress:(void *)data size:(unsigned int)size address:(unsigned long)address
{
	fseek(mapFile, address, SEEK_SET);
	return [self write:data size:size];
}
- (BOOL)writeAnyArrayDataAtAddress:(void *)data size:(unsigned int)size array_size:(unsigned int)array_size address:(unsigned long)address
{
	fseek(mapFile,address, SEEK_SET);
	if (fwrite(data, size,array_size,mapFile) == array_size)
		return YES;
	else
		return NO;
}
- (BOOL)read:(void *)buffer size:(unsigned int)size
{
	int i;
	if (isPPC)
	{
		/*
			lol, this takes some work, doesn't it?
			
			What I'm doing is going through the buffer and swapping the bytes
			This way we can build once and run on all macs
		*/
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
			long *pointLong = buffer;
			for (i = 0; i < (size / 4); i++)
			{
				fread(&pointLong[i], 4, 1, mapFile);
				pointLong[i] = EndianSwap32(pointLong[i]);
			}
			if ((size % 4) > 0)
			{
				long tempLong;
				pointLong = &tempLong;
				char *bytes;
				int x, byteToTranscribe;
				
				fread(pointLong, 4, 1, mapFile);
				
				bytes = (char *)&pointLong;
				
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
- (BOOL)readLong:(void *)buffer
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
- (BOOL)readByteAtAddress:(void *)buffer address:(unsigned long)address
{
	fseek(mapFile,address,SEEK_SET);
	return [self read:buffer size:1];
}
- (BOOL)readIntAtAddress:(void *)buffer address:(unsigned long)address
{
	fseek(mapFile,address,SEEK_SET);
	return [self read:buffer size:4];
}
- (BOOL)readFloatAtAddress:(void *)buffer address:(unsigned long)address
{
	fseek(mapFile,address,SEEK_SET);
	return [self read:buffer size:4];
}
- (BOOL)readLongAtAddress:(void *)buffer address:(unsigned long)address
{
	fseek(mapFile,address,SEEK_SET);
	return [self read:buffer size:4];
}
- (BOOL)readBlockOfDataAtAddress:(void *)buffer size_of_buffer:(unsigned int)size address:(unsigned long)address
{
	fseek(mapFile,address,SEEK_SET);
	return [self read:buffer size:size];
}
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
	[self readLong:&reflex.chunkcount];
	[self readLong:&reflex.offset];
	[self readLong:&reflex.zero];
	reflex.offset -= _magic;
	return reflex;
}
- (reflexive)readBspReflexive:(long)magic
{
	reflexive reflex;
	reflex.location_in_mapfile = [self currentOffset];
	[self readLong:&reflex.chunkcount];
	[self readLong:&reflex.offset];
	[self readLong:&reflex.zero];
	reflex.offset -= magic;
	return reflex;
}
- (TAG_REFERENCE)readReference
{
	TAG_REFERENCE ref;
	[self readLong:&ref.tag];
	[self readLong:&ref.NamePtr];
	ref.NamePtr -= _magic;
	[self readLong:&ref.unknown];
	[self readLong:&ref.TagId];
    
    //NSLog(@"Reference unknown %ld", ref.unknown);
	return ref;
}

- (void)loadSCEX:(scex*)shader forID:(long)shaderId //FUNCTION WHICH FINDS MULTIPLE BITMAPS
{
    long currentOffset = [self currentOffset];
	
	// ok, so lets lookup the shader tag
	MapTag *tempShaderTag = [[self tagForId:shaderId] retain]; // Now we have the shader! Yay!
	[self seekToAddress:[tempShaderTag offsetInMap]];
    int i;
    [self skipBytes:21*4];
    
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
        [self skipBytes:24*4];
    }
    [self seekToAddress:shader->maps2.offset];
    for (i=0; i < shader->maps2.chunkcount; i++)
    {
        [self skipBytes:11*4];
        [self readShort:&shader->read_maps[shader->maps.chunkcount+shader->maps2.chunkcount-1-i].colorFunction];
        [self readShort:&shader->read_maps[shader->maps.chunkcount+shader->maps2.chunkcount-1-+i].alphaFunction];
        [self skipBytes:9*4];
        [self readFloat:&shader->read_maps[shader->maps.chunkcount+shader->maps2.chunkcount-1-+i].uscale];
        [self readFloat:&shader->read_maps[shader->maps.chunkcount+shader->maps2.chunkcount-1-+i].vscale];
        [self skipBytes:4*4];
        shader->read_maps[shader->maps.chunkcount+shader->maps2.chunkcount-1-+i].bitm = [self readReference];
        [self skipBytes:24*4];
    }
    [self seekToAddress:currentOffset];
}


- (void)loadSCHI:(schi*)shader forID:(long)shaderId //FUNCTION WHICH FINDS MULTIPLE BITMAPS
{
    long currentOffset = [self currentOffset];
	
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
        int a;
        [self skipBytes:11*4];
        [self readShort:&shader->read_maps[i].colorFunction];
        [self readShort:&shader->read_maps[i].alphaFunction];
        [self skipBytes:9*4];
        [self readFloat:&shader->read_maps[i].uscale];
        [self readFloat:&shader->read_maps[i].vscale];
        [self skipBytes:4*4];
        shader->read_maps[i].bitm = [self readReference];
        [self skipBytes:24*4];
    }
    [self seekToAddress:currentOffset];
}

- (void)loadSOSO:(soso*)shader forID:(long)shaderId //FUNCTION WHICH FINDS MULTIPLE BITMAPS
{
    long currentOffset = [self currentOffset];
	
	// ok, so lets lookup the shader tag
	MapTag *tempShaderTag = [[self tagForId:shaderId] retain]; // Now we have the shader! Yay!
	[self seekToAddress:[tempShaderTag offsetInMap]];
    
    int i;
    for (i=0; i<41; i++)
        [self readLong:&shader->junk1[i]];
    
    shader->baseMap = [self readReference];
    for (i=0; i<2; i++)
        [self readLong:&shader->junk3[i]];
    
    shader->multiPurpose = [self readReference];
    
    for (i=0; i<3; i++)
        [self readLong:&shader->junk2[i]];
    
    [self readFloat:&shader->detailScale];
    shader->detailMap = [self readReference];
    
    [self seekToAddress:currentOffset];
}


- (void)loadSWAT:(swat*)shader forID:(long)shaderId //FUNCTION WHICH FINDS MULTIPLE BITMAPS
{
    long currentOffset = [self currentOffset];
	
	// ok, so lets lookup the shader tag
	MapTag *tempShaderTag = [[self tagForId:shaderId] retain]; // Now we have the shader! Yay!
	[self seekToAddress:[tempShaderTag offsetInMap]];
    
    [self skipBytes:0x70];
    
    //Read the material diffuse colour
    [self readFloat:&shader->r];
    [self readFloat:&shader->g];
    [self readFloat:&shader->b];
    
    USEDEBUG NSLog(@"Diffuse colour: %f %f %f", shader->r, shader->g, shader->b);
    
    [self seekToAddress:currentOffset];
}

- (void)loadShader:(senv*)shader forID:(long)shaderId //FUNCTION WHICH FINDS MULTIPLE BITMAPS
{
    
    //NSLog(@"LOADING SHADER");
    long currentOffset = [self currentOffset];
	
	// ok, so lets lookup the shader tag
	MapTag *tempShaderTag = [[self tagForId:shaderId] retain]; // Now we have the shader! Yay!
	[self seekToAddress:[tempShaderTag offsetInMap]];
    
    int i;
    for (i=0; i<34; i++)
        [self readLong:&shader->junk1[i]];
    
    shader->baseMapBitm = [self readReference];
    for (i=0; i<7; i++)
        [self readLong:&shader->junk2[i]];
    
    [self readFloat:&shader->primaryMapScale];
    shader->primaryMapBitm = [self readReference];
    
    [self readFloat:&shader->secondaryMapScale];
    shader->secondaryMapBitm = [self readReference];
    
    [self skipBytes:0x40-16];
    
    //Read the material diffuse colour
    [self readFloat:&shader->r];
    [self readFloat:&shader->g];
    [self readFloat:&shader->b];
    
    //USEDEBUG NSLog(@"Diffuse colour: %f %f %f", shader->r, shader->g, shader->b);
    
    [self seekToAddress:currentOffset];
   // NSLog(@"DONE");
}

- (NSMutableArray*)bitmsTagForShaderId:(long)shaderId //FUNCTION WHICH FINDS MULTIPLE BITMAPS
{
	long currentOffset = [self currentOffset];
	
	// ok, so lets lookup the shader tag
	MapTag *tempShaderTag = [[self tagForId:shaderId] retain]; // Now we have the shader! Yay!
	[self seekToAddress:[tempShaderTag offsetInMap]];
	
	[tempShaderTag release];
	
	NSMutableArray *bitmaps = [[NSMutableArray alloc] init];
	
	long bitm = 'bitm', tempInt;
	int x;
	x = 0;
	
	int cso = currentOffset;
	while (x < 1000)
	{
		[self readLong:&tempInt];
		x++;
		cso+=4;
		
		if (tempInt == bitm)
		{
			[self skipBytes:8];
			
			long identOfBitm;
			[self readLong:&identOfBitm];
			
			
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

- (id)bitmTagForShaderId:(long)shaderId
{
	long currentOffset = [self currentOffset];
	
	// ok, so lets lookup the shader tag
	MapTag *tempShaderTag = [[self tagForId:shaderId] retain]; // Now we have the shader! Yay!
	[self seekToAddress:[tempShaderTag offsetInMap]];
	
	[tempShaderTag release];
	
	long bitm = 'bitm', tempInt;
	int x;
	x = 0;
	do
	{
		[self readLong:&tempInt];
		x++;
	} while (tempInt != bitm && x < 1000);
	if (x != 1000)
	{
		[self skipBytes:8];
		long identOfBitm;
		[self readLong:&identOfBitm];
		[self seekToAddress:currentOffset];
		
		
		return (identOfBitm != 0xFFFFFFFF) ? [self tagForId:identOfBitm] : nil;
	}
	
	[self seekToAddress:currentOffset];
	return nil;
}
- (long)currentOffset
{
	return ftell(mapFile);
	//return [[NSNumber numberWithDouble:ftell(mapFile)] longValue];
}
// I have duplicates here since I'm going to be switcing over from get_magic to _magic
- (long)getMagic
{
	return _magic;
}
- (long)magic
{
	return _magic;
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
- (id)tagForId:(long)identity
{
	
	return [tagArray objectAtIndex:[[tagLookupDict objectForKey:[NSNumber numberWithLong:identity]] intValue]];
	
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
	long tempIdent;
	
    bipd_reference *bipd_ref = [mapScenario bipd_references];
	vehicle_reference *vehi_ref = [mapScenario vehi_references];
	scenery_reference *scen_ref = [mapScenario scen_references];
	mp_equipment *mp_equip = [mapScenario item_spawns];
	//multiplayer_flags *mp_flags = [mapScenario netgame_flags];
	
	//NSLog(@"0x%x", vehi_ref[0].vehi_ref.TagId);
	//0xE3D402BC
	for (x = 0; x < [mapScenario vehi_ref_count]; x++)
	{
        USEDEBUG NSLog(@"Loading vehicles");
		if ([self isTag:vehi_ref[x].vehi_ref.TagId])
        {
            if ([[self tagForId:[mapScenario baseModelIdent:vehi_ref[x].vehi_ref.TagId]] respondsToSelector:@selector(loadAllBitmaps)])
                [(ModelTag *)[self tagForId:[mapScenario baseModelIdent:vehi_ref[x].vehi_ref.TagId]] loadAllBitmaps];
        }
	}
    /*
    for (x = 0; x < [mapScenario bipd_ref_count]; x++)
	{
        NSLog(@"Loading bipds");
		if ([self isTag:bipd_ref[x].bipd_ref.TagId])
        {
			[(ModelTag *)[self tagForId:[mapScenario baseModelIdent:bipd_ref[x].bipd_ref.TagId]] loadAllBitmaps];
        }
	}
     */
    
	for (x = 0; x < [mapScenario scen_ref_count]; x++)
	{
        USEDEBUG NSLog(@"Loading scen");
		if ([self isTag:scen_ref[x].scen_ref.TagId])
		{
			//NSLog(@"Tag id and index: [%d], index:[0x%x], next tag index:[0x%x]", x, scen_ref[x].scen_ref.TagId, scen_ref[x+1].scen_ref.TagId);
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
        USEDEBUG NSLog(@"Loading skybox");
        if ([self isTag:[mapScenario sky][x].modelIdent])
        {
            if ([[self tagForId:[mapScenario sky][x].modelIdent] respondsToSelector:@selector(loadAllBitmaps)])
                [(ModelTag *)[self tagForId:[mapScenario sky][x].modelIdent] loadAllBitmaps];
        }
    }
	for (x = 0; x < [mapScenario item_spawn_count]; x++)
	{
        USEDEBUG NSLog(@"Loading item");
		[self seekToAddress:([[self tagForId:mp_equip[x].itmc.TagId] offsetInMap] + 0x8C)];
		[self readLong:&tempIdent];
		if ([self isTag:tempIdent])
        {
            if ([[self tagForId:[mapScenario baseModelIdent:tempIdent]] respondsToSelector:@selector(loadAllBitmaps)])
                [(ModelTag *)[self tagForId:[mapScenario baseModelIdent:tempIdent]] loadAllBitmaps];
        }
	}
	for (x = 0; x < [mapScenario mach_ref_count]; x++)
	{
       USEDEBUG  NSLog(@"Loading mach");
		if ([self tagForId:[mapScenario mach_references][x].modelIdent] != mapScenario)
        {
            if ([[self tagForId:[mapScenario mach_references][x].modelIdent] respondsToSelector:@selector(loadAllBitmaps)])
                [(ModelTag *)[self tagForId:[mapScenario mach_references][x].modelIdent] loadAllBitmaps];
        }
	}
	// Then we put netgame flags in a bit
}
- (BOOL)isTag:(long)tagId
{
	if (tagId == 0xFFFFFFFF)
		return NO;
	if ([self tagForId:tagId] == mapScenario)
		return NO;
	if ((tagId < (indexHead.tagcount + indexHead.starting_id)) || (unsigned int)tagId < (unsigned int)indexHead.starting_id)
		return NO;
	//NSLog(@"Int val: 0x%x", [[tagLookupDict objectForKey:[NSNumber numberWithLong:tagId]] intValue]);
	
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
- (NSString*)keyForItemid:(long)keyv
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
- (long)itmcIdForKey:(int)key
{
	return [[itmcLookupDict objectForKey:[NSNumber numberWithInt:key]] longValue];
}
- (long)modIdForKey:(int)key
{
	return [[modTagLookupDict objectForKey:[NSNumber numberWithInt:key]] longValue];
}
- (long)bitmIdForKey:(int)key
{
	return [[bitmTagLookupDict objectForKey:[NSNumber numberWithInt:key]] longValue];
}
- (BOOL)saveMapToPath:(NSString*)saveURL
{
    NSString *tempFile = @"/tmp/archon_export.map";
    
    //Copy the map
    if ([[NSFileManager defaultManager] fileExistsAtPath:tempFile])
        [[NSFileManager defaultManager] removeItemAtPath:tempFile error:nil];
    

    FILE *tempFilePath = fopen([tempFile cStringUsingEncoding:NSASCIIStringEncoding],"wb+");

    fseek(mapFile, 0, SEEK_END);
    long end_address = ftell(mapFile);
    void *data = malloc(end_address);
    fseek(mapFile, 0, SEEK_SET);
    fread(data, end_address, 1, mapFile);
    fwrite(data, end_address, 1, tempFilePath);
    fseek(mapFile, 0, SEEK_SET);
    fclose(mapFile);
    free(data);

    //Save changes to a temportary file
    //NSLog(tempFile);
    mapFile = tempFilePath;

    [mapScenario rebuildScenario];
    [mapScenario saveScenario];

    int itemtagLength = 32;
    
    int newTags = [tagArray count]-indexHead.tagcount;
    long dataLength = newTags*itemtagLength;
    
    void *tagSpace = malloc(dataLength);
    memset(tagSpace, 0, dataLength);
    NSLog(@"Set memory");
    
    //Loop through all of the tags and update
    long newOffset = indexHead.indexMagic+mapHeader.offsetToIndex-0x40440000;
    [self seekToAddress:newOffset];
    
    long insertEnd = newOffset + indexHead.tagcount*itemtagLength;
    
    NSLog(saveURL);
    [self rebuildTagArrayToPath:saveURL withDataAtIndexes:&insertEnd lengths:&dataLength offsets:1];
    
    
    //Add new tags to the file
    //Add the new tags
    NSLog(@"Adding new tags %ld %d", indexHead.tagcount, [tagArray count]);
    
   
    
    int i;
    for (i = indexHead.tagcount; i < [tagArray count]; i++)
	{
        MapTag *tag = [tagArray objectAtIndex:i];
        int dataOffset = (i-indexHead.tagcount)*itemtagLength;
        
        char *classA = [tag tagClassHigh];
        char *classB = [tag tagClassB];
        char *classC = [tag tagClassC];
        long identity = [tag idOfTag];
        long stringOffset = [tag stringOffset];
        long offset = [tag rawOffset];
        long someNumber = [tag num1];
        long someNumber2 = [tag num2];
        
        //Update the offsets
        if (stringOffset-_magic >= insertEnd)
            stringOffset+=dataLength;
        
        if (offset-_magic >= insertEnd)
        {
            offset+=dataLength;
            NSLog(@"Updating offset 0x%lx 0x%lx to 0x%lx", newOffset+i*itemtagLength+16, offset-dataLength, offset);
        }
        
        //Write all of the tag data to the file
        memcpy(tagSpace+dataOffset  , classA, 4);
        memcpy(tagSpace+dataOffset+ 4, classB, 4);
        memcpy(tagSpace+dataOffset+ 8, classC, 4);
        memcpy(tagSpace+dataOffset+12, (long*)(&identity), 4);
        memcpy(tagSpace+dataOffset+16, (long*)(&stringOffset), 4);
        memcpy(tagSpace+dataOffset+20, (long*)(&offset), 4);
        memcpy(tagSpace+dataOffset+24, (long*)(&someNumber), 4);
        memcpy(tagSpace+dataOffset+28, (long*)(&someNumber2), 4);
    }
    

    
    NSLog(@"Inserting new tags %d", dataLength);
    [self insertDataInFile:saveURL withData:tagSpace size:dataLength address:insertEnd];
    

    fclose(mapFile);
    mapFile = fopen([mapName cStringUsingEncoding:NSASCIIStringEncoding],"rb+");
    
	return YES;//[mapScenario saveScenarioToFile:saveURL];
}

- (void)saveMap
{
	NSLog(@"hur?");
	[mapScenario rebuildScenario];
	NSLog(@"Or hur!?");
	[mapScenario saveScenario];
	NSLog(@"Asdf.");
	
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
