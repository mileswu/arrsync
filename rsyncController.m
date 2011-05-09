

#import "rsyncController.h"

@implementation rsyncController : NSObject

-(rsyncController *)initWithPreset:(presetObj *)preset
{
	//termination = 0;
	rsyncController *r = [super init];
	
	_presetObj = preset;
	_cmd = [[[[PTYTask alloc] init] autorelease] retain];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"GiveMeASFTPController" object:self];

	return r;
}

-(void)setSFTPController:(sftpController *)aObj
{
	_sftpController = aObj;
}

-(void)sync
{
	NSLog(@"Started sync");
	[_presetObj setValue:[NSNumber numberWithBool:TRUE] forKey:@"_running"];
	[_presetObj setValue:[NSNumber numberWithBool:FALSE] forKey:@"_totalFileCount"];
	[_presetObj setValue:[NSNumber numberWithInt:0] forKey:@"_filesDone"];
	
	[_presetObj setValue:[NSMutableArray array] forKey:@"_errors"];
	
	NSMutableDictionary *lastRun = [NSMutableDictionary dictionary];
	[lastRun setValue:[NSDate date] forKey:@"time"];
	[lastRun setValue:[NSNumber numberWithBool:FALSE] forKey:@"duration"];
	[lastRun setValue:[NSNumber numberWithInt:0] forKey:@"sourceChanges"];
	[lastRun setValue:[NSNumber numberWithInt:0] forKey:@"destChanges"];
	[_presetObj setValue:lastRun forKey:@"_lastRun"];

	[NSThread detachNewThreadSelector:@selector(startCmdThread:) toTarget:self withObject:nil];
}

-(BOOL)isBidirectional
{
	if([[[_presetObj valueForKey:@"_options"] valueForKey:@"mode"] intValue] == 0)
		return(TRUE);
	else
		return(FALSE);
}

-(NSArray *)getRsyncArguments
{
	NSDictionary *options = [_presetObj valueForKey:@"_options"];
	
	NSMutableArray *rsyncArguments = [NSMutableArray array];
	[rsyncArguments addObject:@"/usr/bin/env"];
	[rsyncArguments addObject:@"rsync"];
	[rsyncArguments addObject:@"-vrt"]; //verbose, recursive, save times
	
	int mode = [[options valueForKey:@"mode"] intValue];
	if(mode==1) //BACKUP
		[rsyncArguments addObject:@"--delete"];
	//mode 2 == MERGE
	if(mode == 0 || mode == 2) //need only to update
		[rsyncArguments addObject:@"-u"];
	
	int checkMode = [[options valueForKey:@"checkMode"] intValue];
	if(checkMode==1) //always checksum
		[rsyncArguments addObject:@"-c"];
	//mode 2 == normal
	else if(checkMode==3)
		[rsyncArguments addObject:@"--size-only"];
	
	int copyMode = [[options valueForKey:@"copyMode"] intValue];
	if(copyMode==0) //whole files
		[rsyncArguments addObject:@"-W"];
	//mode 1 == normal
	
	if([[options valueForKey:@"extendedAttr"] intValue] == 1)
		[rsyncArguments addObject:@"-E"];
	if([[options valueForKey:@"preservePermissions"] intValue] == 1)
		[rsyncArguments addObject:@"-p"];
	if([[options valueForKey:@"symlinks"] intValue] == 1)
		[rsyncArguments addObject:@"-l"];
	
	NSLog(@"Done all argument crap");
	return(rsyncArguments);
}

-(NSArray *)getEnabledFiles
{
	NSArray *files = [_presetObj valueForKey:@"_files"];
	NSMutableArray *enabledFiles = [NSMutableArray array];
	int i;
	for(i=0; i<[files count]; i++) //getting enabled files
		if([[[files objectAtIndex:i] valueForKey:@"enabled"] boolValue] == TRUE)
			[enabledFiles addObject:[files objectAtIndex:i]];
	return(enabledFiles);
}

-(PTYTask *)runSyncWithArgs:(NSArray *)rsyncArguments withFile:(NSDictionary *)file reversed:(BOOL)reversed
{
	PTYTask *run = [[[PTYTask alloc] init] autorelease];
	[run setPath:@"/usr/bin/env"];
		
	NSArray *files, *temp;
	
	NSString *dest, *src;

	if(reversed == FALSE)
	{
		src = [NSString stringWithFormat:@"%@", [file valueForKey:@"source"]];
		dest = [NSString stringWithFormat:@"%@/", [file valueForKey:@"destination"]];
	}
		
	else //going backwards
	{
		NSArray *sourceComp = [[file valueForKey:@"source"] pathComponents];
		
		src = [NSString stringWithFormat:@"%@", [[file valueForKey:@"destination"] stringByAppendingFormat:@"/%@", [sourceComp objectAtIndex:([sourceComp count]-1)]]];
		dest = [NSString stringWithFormat:@"%@", [[NSString pathWithComponents:[sourceComp subarrayWithRange:NSMakeRange(0, [sourceComp count]-1)]] stringByAppendingString:@"/"]];
	}
	
	if([self isRemote:src])
		src = [self escapeString:src];
	if([self isRemote:dest])
		dest = [self escapeString:dest];
	
	temp = [NSArray arrayWithObjects:src, dest, nil];

	files = [rsyncArguments arrayByAddingObjectsFromArray:temp];
	[run setArgs:files];
	[run launchTask];
	
	//if SSH needs password
	if([self isRemote:[file valueForKey:@"source"]] || [self isRemote:[file valueForKey:@"destination"]])
	{
		NSLog(@"SSH rsync");
		
		NSFileHandle *handle = [run handle];
		NSMutableData *data = [NSMutableData data];
		NSString *host;
		
		if([self isRemote:[file valueForKey:@"source"]])
			host = [[[file valueForKey:@"source"] componentsSeparatedByString:@":"] objectAtIndex:0];
		else
			host = [[[file valueForKey:@"destination"] componentsSeparatedByString:@":"] objectAtIndex:0];

		BOOL authenicatedBefore = FALSE;
		while(1)
		{
			NSLog(@"1");
			NSData *tempData = [handle availableData];
			NSLog(@"2");

			if([tempData length] == 0) //died
			{
				NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

				NSLog(str);
				NSLog(@"Connection meats");
			}
			[data appendData:tempData];
			
			NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			
			if([str hasSuffix:@"Are you sure you want to continue connecting (yes/no)? "])
				[handle writeData: [[[_sftpController addkeyForHost:host] stringByAppendingString:@"\r"] dataUsingEncoding:NSASCIIStringEncoding]];
			if([str rangeOfString:@"Too many authentication failures"].location != NSNotFound)
			{
				NSLog(@"Password crap");
			}
			if([str hasSuffix:@"assword:"] || [str hasSuffix:@"assword: "])
			{
				if(authenicatedBefore == TRUE)
					[_sftpController failedAuthentication:host];
				
				NSLog(@"Prompt");
				[handle writeData:[[[_sftpController authenticateFromSavedPasswords:host] stringByAppendingString:@"\r"] dataUsingEncoding:NSASCIIStringEncoding]];
				authenicatedBefore = TRUE;
			}
			
			if([str rangeOfString:@"file list"].location != NSNotFound)
			{
				NSLog([[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]);
				[run setExcessData:data];
				NSLog(@"GO");
				break;
			}
			
		}
		
	}
	
	
	return(run);
}

-(int)countDryRun:(PTYTask*)dryrun
{
	int count = [self numberOfCharactersInString:[[NSString alloc] initWithData:[dryrun excessData] encoding:NSASCIIStringEncoding] character:'\n'];
	NSLog(@"count from excess");
	NSFileHandle *o = [dryrun handle];
	while(1)
	{
		NSAutoreleasePool *dryrunpool = [[NSAutoreleasePool alloc] init];
		NSLog(@"F1");
		NSData *dryrundata = [o availableData];
		NSLog(@"F2");

		if([dryrundata length]==0)
			break;
		
		NSString *str = [[NSString alloc] initWithData:dryrundata encoding:NSASCIIStringEncoding];
		NSLog(@"F3 %@", str
			  );
		count += [self numberOfCharactersInString:str character:'\n'];
		NSLog(@"F4");
		[dryrunpool release];
	}
	NSLog(@"F@");

	return(count);
}

-(int)dryRunCountForAll
{
	int count=0, i;
	NSArray *enabledFiles = [self getEnabledFiles];
	NSArray *rsyncArguments = [[self getRsyncArguments] arrayByAddingObject:@"-n"];
	BOOL bi=[self isBidirectional];
	
	for(i=0; i<[enabledFiles count]; i++)
	{
		count += [self countDryRun:[self runSyncWithArgs:rsyncArguments withFile:[enabledFiles objectAtIndex:i] reversed:FALSE]];
		if(bi)
			count += [self countDryRun:[self runSyncWithArgs:rsyncArguments withFile:[enabledFiles objectAtIndex:i] reversed:TRUE]];
	}
	
	NSLog(@"Counted %d for dry run", count);
	return(count);
}

- (void)startCmdThread:(id)nothing
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	int count = [self dryRunCountForAll];
	int i;
	
	[_presetObj setValue:[NSNumber numberWithInt:count] forKey:@"_totalFileCount"];
	
	NSArray *enabledFiles = [self getEnabledFiles];
	NSArray *rsyncArguments = [self getRsyncArguments];
	BOOL bi=[self isBidirectional];
	
	int scount=0;
	int dcount = 0;
	for(i=0; i<[enabledFiles count]; i++)
	{
		PTYTask *t;
		t = [self runSyncWithArgs:rsyncArguments withFile:[enabledFiles objectAtIndex:i] reversed:FALSE];
		[NSThread detachNewThreadSelector:@selector(updateErrors:) toTarget:self withObject:t];
		dcount += [self updateProgress:t];
		if(bi)
		{
			t = [self runSyncWithArgs:rsyncArguments withFile:[enabledFiles objectAtIndex:i] reversed:TRUE];
			[NSThread detachNewThreadSelector:@selector(updateErrors:) toTarget:self withObject:t];
			scount += [self updateProgress:t];
		}
	}
	
	[_presetObj setValue:[NSNumber numberWithBool:FALSE] forKey:@"_running"];
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	
	[d setValue:[[_presetObj valueForKey:@"_lastRun"] valueForKey:@"time"] forKey:@"time"];
	[d setValue:[NSNumber numberWithInt:(int)[[NSDate date] timeIntervalSinceDate:[d valueForKey:@"time"]]] forKey:@"duration"];
	[d setValue:[NSNumber numberWithInt:scount] forKey:@"sourceChanges"];
	[d setValue:[NSNumber numberWithInt:dcount] forKey:@"destChanges"];
	[_presetObj setValue:d forKey:@"_lastRun"];
	
	
	NSLog(@"Finished");
	[pool release];
}

-(void)updateErrors:(PTYTask *)task
{
	NSFileHandle *o = [task errorHandle];
	NSMutableArray *errors = [_presetObj valueForKey:@"_errors"];
	while(1)
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		NSData *dryrundata = [o availableData];
		NSLog(@"HI123");
		
		if([dryrundata length]==0)
			break;
		NSString *error = [[NSString alloc] initWithData:dryrundata encoding:NSASCIIStringEncoding];
		
		NSArray *newErrors = [error componentsSeparatedByString:@"\n"];
		int i;
		for(i=0; i<[newErrors count]; i++)
			if(![[newErrors objectAtIndex:i] isEqualToString:@""])
				[errors addObject:[newErrors objectAtIndex:i]];
		
		[_presetObj setValue:errors forKey:@"_errors"];
		
		[error release];
		
		[pool release];
	}
	
}
-(int)updateProgress:(PTYTask *)task
{
	NSFileHandle *o = [task handle];
	int ccount=0, inc;
	inc = [self numberOfCharactersInString:[[NSString alloc] initWithData:[task excessData] encoding:NSASCIIStringEncoding] character:'\n'];
	
	while(1)
	{
		NSAutoreleasePool *pool1 = [[NSAutoreleasePool alloc] init];
		
		int count = [[_presetObj valueForKey:@"_filesDone"] intValue];
		NSData *dryrundata = [o availableData];
		if([dryrundata length]==0)
			break;
		
		inc = [self numberOfCharactersInString:[[NSString alloc] initWithData:dryrundata encoding:NSASCIIStringEncoding] character:'\n'];
		count += inc;
		ccount += inc;
		
		if(count > [[_presetObj valueForKey:@"_totalFileCount"] intValue])
			[_presetObj setValue:[NSNumber numberWithInt:count] forKey:@"_totalFileCount"];
		
		[_presetObj setValue:[NSNumber numberWithInt:count] forKey:@"_filesDone"];
		[pool1 release];
	}
	return(ccount);
}

//Random manipulations
- (int)numberOfCharactersInString:(NSString *)str character:(char)chr
{
	int i, count;
	count = 0;
	for(i=0; i<[str length]; i++)
		if([str characterAtIndex:i] == chr)
			count += 1;
	return count;
}

-(BOOL)isRemote:(NSString *)file
{
	if([file rangeOfString:@":"].location == NSNotFound)
		return(NO);
	else
		return(YES);
}

-(NSString *)escapeString:(NSString *)str
{
	NSMutableString *strm = [NSMutableString stringWithString:str];
	[strm replaceOccurrencesOfString:@" " withString:@"\\ " options:NSLiteralSearch range:NSMakeRange(0,[strm length])];
	return(strm);
}



@end
