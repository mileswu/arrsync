//
//  sftpBrowse.m
//  arRsync
//
//  Created by Miles Wu on 23/06/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "sftpBrowse.h"


@implementation sftpBrowse

-(sftpBrowse *)initWithSender:(id)sender
{
	
	sftpBrowse *retval = [super init];
	
	_chooseFiles = TRUE;
	_createDirectories = FALSE;
	
	_title = [@"SFTP Browse" retain];
	_connected = [[NSNumber numberWithBool:FALSE] retain];
	
	_sender = [sender retain];
	_addToKeychain = [[NSNumber numberWithBool:FALSE] retain];
	_host = [[NSMutableString string] retain];
	_username = [[NSMutableString string] retain];
	_hostEditable = [[NSNumber numberWithBool:TRUE] retain];
	//_passwordField = [[NSMutableString string] retain];
	_statusInfo = [@"Idle" retain];
	_files = [[NSMutableDictionary dictionary] retain];
	_leftoverData = [[NSData data] retain];
	_sshTask = [[[[PTYTask alloc] init] autorelease] retain];
	_isbusy = [[NSNumber numberWithBool:FALSE] retain];
	_history = [[NSMutableArray array] retain];
	
	//_viewMode = [[NSNumber numberWithInt:1] retain]; COLUMN MODE NEVER TO BE
	
	_directoryList = [[NSArray array] retain];
	_currentDirectoryIndex = nil;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"GiveMeASFTPController" object:self];
		
	return(retval);
}

-(void)dealloc
{
	NSLog(@"DEALLOC");
	[_title release];
	[_connected release];
	[_sender release];
	[_addToKeychain release];
	[_host release];
	[_username release];
	[_hostEditable release];
	//[_passwordField release];
	[_statusInfo release];
	[_files release];
	[_leftoverData release];
	[_sshTask release];
	[_isbusy release];
	[_history release];
	
	[_mainPanel release];
	
	[super release];
}

-(void)awakeFromNib
{
	[_browser setTarget:self];
	[_browser sendActionOn:NSLeftMouseDownMask];
	[_browser setAction:@selector(browserSelected:)];
		
	/*[_outline setTarget:self];
	[_outline setDoubleAction:@selector(outlineViewDoubleClicked:)];*/
	
	
	[self addObserver:self forKeyPath:@"_currentDirectoryIndex" options:NSKeyValueObservingOptionNew context:NULL];
	//[self addObserver:self forKeyPath:@"_viewMode" options:NSKeyValueObservingOptionNew context:NULL]; COLUMN MODE NEVER TO BE

}

-(void)setSFTPController:(sftpController *)aObj
{
	_sftpController = aObj;
}

-(IBAction)endModalWithTag:(id)sender 
{
	/*if([sender tag] >= 200) //This is for the Authentication Dialog Box
	{
		int tag = [sender tag] - 200;
		if(tag == NSOKButton)
		{
			[_sftpController addPassword:[self valueForKey:@"_passwordField"] withHost:[self url] alsoInKeychain:[[self valueForKey:@"_addToKeychain"] boolValue]];
			[self connect:NULL];
		}
		else
			[self setValue:@"Authentication Error" forKey:@"_statusInfo"];
		[NSApp endSheet:_passwordPanel];
		[_passwordPanel orderOut:self];
	}
	else //This is for the whole dialog
	{*/
		[_sender endModalWithTag:sender];
		[_mainPanel orderOut:self];
	//}
}

-(NSString *)url
{
	NSString *url;
	if(![[self valueForKey:@"_username"] isEqualToString:@""])
		url = [NSString stringWithFormat:@"%@@%@", [self valueForKey:@"_username"], [self valueForKey:@"_host"]];
	else
		url = [self valueForKey:@"_host"];
	return(url);
}

-(IBAction)connect:(id)sender
{	
	//sleep(1); //ugly hack
	[_sshTask kill];
	[_sshTask release];
	[self setValue:[NSNumber numberWithBool:FALSE] forKey:@"_connected"];

	_sshTask = [[PTYTask alloc] init];
	NSString *url = [self url];
	
	[self setValue:[NSNumber numberWithBool:FALSE] forKey:@"_hostEditable"];
	[_sftpController addHost:url];
	
	[_leftoverData release];
	_leftoverData = [[NSData data] retain];
	
	[_files removeAllObjects];
	
	[_history release];
	_history = [[NSMutableArray array] retain];
	_historyPosition = 0;

	NSArray *args = [NSArray arrayWithObjects:@"/usr/bin/sftp", url, nil];
	[_sshTask setArgs:args];
	[_sshTask setPath:[args objectAtIndex:0]];
	[_sshTask launchTask];
	[self setValue:@"Connecting..." forKey:@"_statusInfo"];
	NSLog(@"125");

	[NSThread detachNewThreadSelector:@selector(waitForConnection:) toTarget:self withObject:nil];
}

-(void)waitForConnection:(id)goive
{
	NSLog(@"126");
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSLog(@"127");
	
	[self setValue:[NSNumber numberWithBool:TRUE] forKey:@"_isbusy"];

	if(![self waitForPrompt])
	{
		[self setValue:[NSNumber numberWithBool:FALSE] forKey:@"_isbusy"];
		return;
	}
	
	[self setValue:@"Idle" forKey:@"_statusInfo"];
	[self setValue:[NSNumber numberWithBool:TRUE] forKey:@"_connected"];
	
	[self setValue:[NSArray arrayWithObject:@"/"] forKey:@"_directoryList"];
	[_browser reloadColumn:0];
	//[_history addObject:@"/"];
	//[_outline reloadData];
	
	[self setValue:[NSNumber numberWithBool:FALSE] forKey:@"_isbusy"];
	[pool release];
}

-(NSMutableData *)waitForPrompt
{
	NSString *str;
	NSMutableData *data = [NSMutableData data];
	NSFileHandle *taskHandle = [_sshTask handle];
	BOOL authenticatedBefore = FALSE;
	[data appendData:_leftoverData];
		
	while(1)
	{
		NSData *tempdata = [taskHandle availableData];
		if([tempdata length] == 0 && [_connected boolValue] == FALSE) //data is empty
		{
			[self setValue:@"Error" forKey:@"_statusInfo"];
			NSString * sshError = [[[NSString alloc] initWithData:[[_sshTask errorHandle] availableData] encoding:NSUTF8StringEncoding] autorelease];
			NSLog(sshError);

			NSAlert *myAlert = [NSAlert alertWithMessageText: @"Failed to Connect"
											   defaultButton:nil
											 alternateButton:nil 
												 otherButton:nil
								   informativeTextWithFormat:@"The connection could not made. SSH returned the following error:\n%@", sshError];
			[myAlert setAlertStyle:NSCriticalAlertStyle];
			[myAlert beginSheetModalForWindow:_mainPanel modalDelegate:nil didEndSelector:nil contextInfo:nil];
			
			[self setValue:[NSNumber numberWithBool:FALSE] forKey:@"_isbusy"];
			[self setValue:[NSNumber numberWithBool:TRUE] forKey:@"_hostEditable"];
			return(nil);
		}
		else if([tempdata length] == 0) //data is empty
		{
			[self setValue:@"Error" forKey:@"_statusInfo"];
			NSString * sshError = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
			
			NSAlert *myAlert = [NSAlert alertWithMessageText: @"Problem"
											   defaultButton:nil
											 alternateButton:nil 
												 otherButton:nil
								   informativeTextWithFormat:@"The connection died unexpectedly. SSH returned the following error:\n%@", sshError];
			[myAlert setAlertStyle:NSCriticalAlertStyle];
			[myAlert beginSheetModalForWindow:_mainPanel modalDelegate:nil didEndSelector:nil contextInfo:nil];
			[self setValue:[NSNumber numberWithBool:FALSE] forKey:@"_connected"];
			[_browser reloadColumn:0];
			
			[self setValue:[NSNumber numberWithBool:FALSE] forKey:@"_isbusy"];
			[self setValue:[NSNumber numberWithBool:TRUE] forKey:@"_hostEditable"];
			return(nil);
		}
		
		[data appendData:tempdata];
		str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

		if([str hasSuffix:@"Are you sure you want to continue connecting (yes/no)? "])
			[taskHandle writeData: [[[_sftpController addkeyForHost:[self url]] stringByAppendingString:@"\r"] dataUsingEncoding:NSUTF8StringEncoding]];
		
		if([str rangeOfString:@"Too many authentication failures"].location != NSNotFound)
		{
			[self setValue:[NSNumber numberWithBool:FALSE] forKey:@"_isbusy"];
			[self setValue:@"Authentication Error" forKey:@"_statusInfo"];
			[self setValue:[NSNumber numberWithBool:TRUE] forKey:@"_hostEditable"];
			return(nil);
		}
			
		if([str hasSuffix:@"assword:"] || [str hasSuffix:@"assword: "])
		{
			if(authenticatedBefore == TRUE)
				[_sftpController failedAuthentication:[self url]];
			NSString *pass = [self authenticate];
			if(!pass)
				return(nil);
			[taskHandle writeData: [[pass stringByAppendingString:@"\r"] dataUsingEncoding:NSUTF8StringEncoding]];
			authenticatedBefore = TRUE;
		}
		
		NSRange promptLoc = [str rangeOfString:@"sftp> "];
		if(promptLoc.location != NSNotFound)
		{
			NSRange leftoverRange;
			leftoverRange.location = promptLoc.location + 6;
			leftoverRange.length = [data length] - (leftoverRange.location);
			
			[_leftoverData release];
			_leftoverData = [[data subdataWithRange:leftoverRange] retain];
			break;
		}
		[str release];
	}
	[str release];

	return(data);
}                     

-(void)ls:(NSString *)path
{
	NSFileHandle *taskHandle = [_sshTask handle];
	[self setValue:[NSNumber numberWithBool:TRUE] forKey:@"_isbusy"];
	NSLog(@"Listing %@", path);
	[taskHandle writeData: [[NSString stringWithFormat:@"ls -l \"%@\"\r", path] dataUsingEncoding:NSUTF8StringEncoding]];
	NSMutableData *data = [self waitForPrompt];
	
	if(!data)
		return;
	
	NSArray *listFiles = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] componentsSeparatedByString:@"\r\n"];
	
	NSMutableArray *files = [NSMutableArray array];
		
	int i;
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	for(i=1;i<[listFiles count] - 1;i++)
	{
		NSString *name = [[[listFiles objectAtIndex:i] substringFromIndex:56] lastPathComponent];
		NSString *absoluteName = [[listFiles objectAtIndex:i] substringFromIndex:56];
		if(name == nil)
			NSLog(@"problem 212");
		if(absoluteName == nil)
			NSLog(@"problem 232");
		
		
		if([name characterAtIndex:0] == '.')
			continue;
		NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		if([[listFiles objectAtIndex:i] characterAtIndex:0] != 'd')
		{
			NSImage *icon = [workspace iconForFileType:[[name componentsSeparatedByString:@"."] lastObject]];
			[icon setSize:NSMakeSize(16,16)];			
			[dict setObject:icon forKey:@"icon"];
			
			[dict setObject:@"file" forKey:@"type"];
		}
		else
		{
			NSImage *icon = [workspace iconForFile:@"/etc"];
			[icon setSize:NSMakeSize(16,16)];
			[dict setObject:icon forKey:@"icon"];
			
			[dict setObject:@"dir" forKey:@"type"];
		}
		[dict setObject:absoluteName forKey:@"path"];
		[dict setObject:name forKey:@"name"];
		[files addObject:dict];
	}
	
	NSMutableArray *list = [NSMutableArray array];
	NSArray *reversedList = [[_browser path] pathComponents];
	for(i=([reversedList count]-1); i>=0; i--) //reversing
		[list addObject:[reversedList objectAtIndex:i]];
	[self setValue:list forKey:@"_directoryList"];
	
	[_files setObject:files forKey:path];
	[self setValue:[NSNumber numberWithBool:FALSE] forKey:@"_isbusy"];
}

-(NSString *)authenticate
{
	NSString *pass = [_sftpController authenticateFromSavedPasswords:[self url]];
	/*if(!pass)
	{
		[NSApp beginSheet:_passwordPanel modalForWindow:_mainPanel modalDelegate:self didEndSelector:NULL contextInfo:NULL];
	}*/
	return(pass);
}

-(int)browser:(NSBrowser *)aBrowser numberOfRowsInColumn:(int)column
{
	if([_connected boolValue] == FALSE)
		return(0);
	else
	{
		NSArray *files;
		if([[aBrowser path] length] == 0)
		{
			[self ls:@"/"];
			files = [_files objectForKey:@"/"];
		}
		else
		{
			[self ls:[aBrowser path]];
			files = [_files objectForKey:[aBrowser path]];
		}

		return([files count]);
	}
}

-(void)browser:(NSBrowser *)aBrowser willDisplayCell:(NSBrowserCell *)aCell atRow:(int)row column:(int)column
{
	if([_connected boolValue] == TRUE)
	{		
		NSArray *files;
		NSString *path;
		if(column == 0)
			path = @"/";
		else
			path = [_browser pathToColumn:column];
		
		files = [_files objectForKey:path];
		
		
		if(row >= [files count])
		{
			NSLog(@"problem 674");
			int i;
			NSLog(@"Begin dump for %@", [_browser path]);
			NSLog(@"no %d", [files count]);
			for(i=0;i<[files count];i++)
				NSLog([[files objectAtIndex:i] valueForKey:@"path"]);
			NSLog(@"finished dump");
		}
		
		
		[aCell setStringValue:[[files objectAtIndex:row] objectForKey:@"name"]];
		[aCell setImage:[[files objectAtIndex:row] objectForKey:@"icon"]];
		if([[[files objectAtIndex:row] objectForKey:@"type"] isEqualToString:@"file"])
		{
			[aCell setLeaf:YES];
			if(_chooseFiles == TRUE)
				[aCell setEnabled:YES];
			else
				[aCell setEnabled:NO];
		}
	}
}

-(void)browserSelected:(NSBrowserCell *)cell
{
	NSArray *selectedCells = [_browser selectedCells];
	int i;

	if(![[_browser selectedCell] isLeaf] && [selectedCells count] == 1) //Changing to new directory. This is for history purposes.
	{
		//NSLog(@"%@ %d", [_browser path], [_history count]);
		
		if(_historyPosition == 0)
			[_history insertObject:[_browser path] atIndex:0];
		else
		{
			NSMutableArray *newhistory = [[NSMutableArray array] retain];
			for(i=_historyPosition; i<[_history count]; i++)
				[newhistory addObject:[_history objectAtIndex:i]];
			_historyPosition = 0;
			[_history release];
			_history = newhistory;
		}
		[self updateHistoryEnabled];
	}
	
	else if([[_browser selectedCell] isLeaf] || [selectedCells count] != 1 ) //selected either multiple files or a file. This is for updating top bar
	{
		NSMutableArray *list = [NSMutableArray array];
		NSArray *reversedList = [[_browser path] pathComponents];
		
		for(i=([reversedList count]-2); i>=0; i--) //reversing but ignoring last one cos it's a file not a dir
			[list addObject:[reversedList objectAtIndex:i]];
		[self setValue:list forKey:@"_directoryList"];

	}
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	int index = [[change objectForKey:NSKeyValueChangeNewKey] intValue];
	if([keyPath isEqualToString:@"_currentDirectoryIndex"] && index != 0)
	{
		NSMutableArray *newPathComponents = [NSMutableArray array];
		NSArray *list = [self valueForKey:@"_directoryList"];
		int i;
		
		for(i=([list count]-1); i>=index; i--)
			[newPathComponents addObject:[list objectAtIndex:i]];
		
		NSString *newPath = [NSString pathWithComponents:newPathComponents];
		NSLog(newPath);
		[_browser setPath:newPath];
		
		NSMutableArray *reversed = [NSMutableArray array];
		for(i=([newPathComponents count]-1); i>=0; i--)
			[reversed addObject:[newPathComponents objectAtIndex:i]];
		
		[self setValue:[NSNumber numberWithInt:0] forKey:@"_currentDirectoryIndex"];
		[self setValue:reversed forKey:@"_directoryList"];

		//[_outline reloadData];
	}
	/*else if([keyPath isEqualToString:@"_viewMode"] && [[change objectForKey:NSKeyValueChangeNewKey] intValue] == 0)
	{
		[_outline reloadData];
	}*/
}



-(IBAction)backforward:(id)sender
{
	int tag = [sender selectedSegment];
	/*[sender setSelected:NO forSegment:0];
	[sender setSelected:NO forSegment:1];*/ //doesn't work

	if(tag == 1 && _historyPosition !=0) //forward
		_historyPosition--;
	else if(tag == 0 && _historyPosition != ([_history count]-1))//backwards
		_historyPosition++;
	else
		return;
	
	NSString *newpath = [_history objectAtIndex:_historyPosition];
	[_browser setPath:newpath];
	
	int i;
	NSMutableArray *list = [NSMutableArray array];
	NSArray *reversedList = [[_browser path] pathComponents];
	
	for(i=([reversedList count]-1); i>=0; i--) //reversing
		[list addObject:[reversedList objectAtIndex:i]];
	[self setValue:list forKey:@"_directoryList"];
	
	[self updateHistoryEnabled];
}

-(void)updateHistoryEnabled
{
	if(_historyPosition == 0) //no forward
		[_historySegmentedControl setEnabled:FALSE forSegment:1];
	else
		[_historySegmentedControl setEnabled:TRUE forSegment:1];
		
	if(_historyPosition == ([_history count]-1)) //no backwards
		[_historySegmentedControl setEnabled:FALSE forSegment:0];
	else
		[_historySegmentedControl setEnabled:TRUE forSegment:0];
}

-(IBAction)useHistory:(id)sender
{
	if([_connected boolValue] == TRUE || [sender indexOfSelectedItem] == 0 || [_hostEditable boolValue] == FALSE)
		return;
	
	NSArray *arr, *urlarr;
	
	if([sender tag] == 0)
		arr = [_sftpController valueForKey:@"_saneBonjourHosts"];
	else if([sender tag] == 1)
		arr = [[NSUserDefaults standardUserDefaults] arrayForKey:@"lastHosts"];
	else if([sender tag] == 2)
		arr = [_sftpController valueForKey:@"_hostFileHosts"];
		
	urlarr = [[arr objectAtIndex:[sender indexOfSelectedItem]] componentsSeparatedByString:@"@"];
	
	if([urlarr count] == 1)
	{
		[self setValue:[urlarr objectAtIndex:0] forKey:@"_host"];
		[self setValue:@"" forKey:@"_username"];
	}
	else
	{
		[self setValue:[urlarr objectAtIndex:0] forKey:@"_username"];
		[self setValue:[urlarr objectAtIndex:1] forKey:@"_host"];
	}
}

-(IBAction)disconnect:(id)sender
{
	[self setValue:[NSNumber numberWithBool:FALSE] forKey:@"_connected"];
	[self setValue:[NSNumber numberWithBool:TRUE] forKey:@"_hostEditable"];
}

/*- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if([_connected boolValue] == FALSE)
		return(0);
	else if(item == nil)
	{
		int i;
		NSArray *reversedPath = [self valueForKey:@"_directoryList"];
		NSMutableArray *pathA = [NSMutableArray array];
		for(i=([reversedPath count]-1); i>=0; i--)
			[pathA addObject:[reversedPath objectAtIndex:i]];
		NSString *path = [NSString pathWithComponents:pathA];
		
		//[self ls:path];
		return([[_files valueForKey:path] count]);
	}
	else
	{
		//[self ls:[item valueForKey:@"path"]];
		return([[_files valueForKey:[item valueForKey:@"path"]] count]);
	}
}
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return([[item valueForKey:@"type"] isEqualToString:@"file"] ? NO : YES );
}
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
	if(item == nil)
	{
		int i;
		NSArray *reversedPath = [self valueForKey:@"_directoryList"];
		NSMutableArray *pathA = [NSMutableArray array];

		for(i=([reversedPath count]-1); i>=0; i--)
			[pathA addObject:[reversedPath objectAtIndex:i]];
		NSString *path = [NSString pathWithComponents:pathA];

		return([[_files valueForKey:path] objectAtIndex:index]);
	}
	else
		return([[_files valueForKey:[item valueForKey:@"path"]] objectAtIndex:index]);
}
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return([item valueForKey:@"name"]);
}
- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	//[cell setImage:[item valueForKey:@"icon"]];
}

- (void)outlineViewDoubleClicked:(id)sender
{
	NSDictionary *item = [_outline itemAtRow:[_outline selectedRow]];
	if(![[item valueForKey:@"type"] isEqualToString:@"dir"])
		return;
	
	NSArray *reversedPath = [[item valueForKey:@"path"] pathComponents];
	
	NSMutableArray *path = [NSMutableArray array];
	int i;
	for(i=([reversedPath count]-1); i>=0; i--)
		[path addObject:[reversedPath objectAtIndex:i]];
	
	[self setValue:path forKey:@"_directoryList"];
	
	[_outline reloadData];
}*/

-(NSArray *)filenames
{
	//if([[self valueForKey:@"_viewMode"] intValue] == 1) //NSBrowser
	//{
		NSArray *cells = [_browser selectedCells];
		NSMutableArray *filenames = [NSMutableArray array];
		int i;
		for(i=0; i<[cells count]; i++)
		{
			NSArray *pathA = [[_browser path] pathComponents];
			NSString *path = [[pathA subarrayWithRange:NSMakeRange(1,[pathA count]-2)] componentsJoinedByString:@"/"];
			NSLog(path);
			if([[self valueForKey:@"_username"] isEqualToString:@""])
			   [filenames addObject:[NSString stringWithFormat:@"%@:\"/%@/%@\"",
				   [self valueForKey:@"_host"],
				   path,
				   [[cells objectAtIndex:i] stringValue]]];
			else
			   [filenames addObject:[NSString stringWithFormat:@"%@@%@:\"/%@/%@\"",
				   [self valueForKey:@"_username"],
				   [self valueForKey:@"_host"],
				   path,
				   [[cells objectAtIndex:i] stringValue]]];
		}
		return([filenames retain]);
	/*}	
	else //Outline View
	{
		NSIndexSet *selected = [_outline selectedRowIndexes];
		int *indexArray = malloc(sizeof(int)*[selected count]);
		[selected getIndexes:indexArray maxCount:[selected count] inIndexRange:nil];
		
		NSMutableArray *filenames = [NSMutableArray array];
		
		int i;
		for(i=0; i<[selected count]; i++)
			[filenames addObject:[NSString stringWithFormat:@"sftp://%@:%@",
				[self valueForKey:@"_host"],
				[[_outline itemAtRow:indexArray[i]] valueForKey:@"path"]]];
		return([filenames retain]);
	}*/
}

-(NSString *)filename
{
	//if([[self valueForKey:@"_viewMode"] intValue] == 1)
		return([[NSString stringWithFormat:@"sftp://%@:\"%@\"",
			[self valueForKey:@"_host"],
			[_browser path]] retain]);
	/*else
	{
		return([[NSString stringWithFormat:@"sftp://%@:%@",
			[self valueForKey:@"_host"],
			[[_outline itemAtRow:[_outline selectedRow]] valueForKey:@"path"]] retain]);
	}*/
}

-(int)runModal
{
	return([NSApp runModalForWindow:_mainPanel]);
}
-(void)setAccessoryView:(NSView *)aView
{
	
}
-(void)setCanChooseDirectories:(BOOL)flag
{
	[_browser setAllowsBranchSelection:flag];
}

-(void)setAllowsMultipleSelection:(BOOL)flag
{
	[_browser setAllowsMultipleSelection:flag];
	//[_outline setAllowsMultipleSelection:flag];
}
-(void)setCanChooseFiles:(BOOL)flag
{
	_chooseFiles = flag;
}
-(void)setCanCreateDirectories:(BOOL)flag
{      
	
}
-(void)setTitle:(NSString *)aTitle
{
	[self setValue:aTitle forKey:@"_title"];
}
@end
