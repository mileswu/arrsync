//
//  sftpBrowse.m
//  arRsync
//
//  Created by Miles Wu on 23/06/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "sftpBrowse.h"

static void kbd_callback(const char *name, int name_len,
                         const char *instruction, int instruction_len,
                         int num_prompts,
                         const LIBSSH2_USERAUTH_KBDINT_PROMPT *prompts,
                         LIBSSH2_USERAUTH_KBDINT_RESPONSE *responses,
                         void **abstract)
{
	sftpBrowse * sB = (sftpBrowse *)*abstract;
	NSString *pass = [sB authenticate];
	
	char *password = (char *)[pass UTF8String];
    if (num_prompts == 1) {
        responses[0].text = strdup(password);
        responses[0].length = strlen(password);
    }
} 

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
	[self setValue:[NSNumber numberWithBool:FALSE] forKey:@"_connected"];

	NSString *url = [self url];
	
	[self setValue:[NSNumber numberWithBool:FALSE] forKey:@"_hostEditable"];
	[_sftpController addHost:url];
	
	[_files removeAllObjects];
	
	[_history release];
	_history = [[NSMutableArray array] retain];
	_historyPosition = 0;
	
	int retval;
	retval = libssh2_init(0);
	if(retval) {
		NSLog(@"Error init libssh2");
	}
	
	int sock = socket(AF_INET, SOCK_STREAM, 0);
	
	struct sockaddr_in sin;
	sin.sin_family = AF_INET;
	sin.sin_port = htons(22);
	
	struct hostent *he = gethostbyname("localhost");
	memcpy((char *)&sin.sin_addr.s_addr, (char *)he->h_addr, he->h_length);
	
	[self setValue:[NSNumber numberWithBool:TRUE] forKey:@"_isbusy"];
	connect(sock, (struct sockaddr*) &sin, sizeof(sin));
	
	_sshSession = libssh2_session_init();
	libssh2_session_startup(_sshSession, sock);
	
	char *fingerprint = libssh2_hostkey_hash(_sshSession, LIBSSH2_HOSTKEY_HASH_MD5);
	printf("Fingerprint: ");
	int i;
	for(i=0; i<16; i++)
		printf("%02X ", (unsigned char)fingerprint[i]);
	printf("\n");
	
	void **abs = libssh2_session_abstract(_sshSession);
	*abs = (void *)self;
	retval = libssh2_userauth_keyboard_interactive(_sshSession, "dagijjg", &kbd_callback);
	if(retval) {
		printf("password failed\n");
		[_sftpController failedAuthentication:[self url]];
		
		[self setValue:[NSNumber numberWithBool:FALSE] forKey:@"_isbusy"];
		[self setValue:@"Authentication Error" forKey:@"_statusInfo"];
		[self setValue:[NSNumber numberWithBool:TRUE] forKey:@"_hostEditable"];
		NSAlert *myAlert = [NSAlert alertWithMessageText: @"Failed to Connect"
										   defaultButton:nil
										 alternateButton:nil 
											 otherButton:nil
							   informativeTextWithFormat:@"The connection could not made. SSH returned the following error:\n%@", @"G"];
		[myAlert setAlertStyle:NSCriticalAlertStyle];
		[myAlert beginSheetModalForWindow:_mainPanel modalDelegate:nil didEndSelector:nil contextInfo:nil];
		return(nil);
	}
	printf("in\n");
	

	_sftpSession = libssh2_sftp_init(_sshSession);
	libssh2_session_set_blocking(_sshSession, 1);
		
	
	[self setValue:@"Idle" forKey:@"_statusInfo"];
	[self setValue:[NSNumber numberWithBool:TRUE] forKey:@"_connected"];
	[self setValue:[NSNumber numberWithBool:FALSE] forKey:@"_isbusy"];

	[self setValue:[NSArray arrayWithObject:@"/"] forKey:@"_directoryList"];
	[_browser reloadColumn:0];
}

-(void)ls:(NSString *)path
{
	NSLog(@"Listing %@", path);
	[self setValue:[NSNumber numberWithBool:TRUE] forKey:@"_isbusy"];
	_sftpHandle = libssh2_sftp_opendir(_sftpSession, [path UTF8String]);

	NSMutableArray *files = [NSMutableArray array];
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];


	do {
		char mem[512];
		char longentry[512];
		LIBSSH2_SFTP_ATTRIBUTES attrs;
		
		/* loop until we fail */ 
		int retval = libssh2_sftp_readdir_ex(_sftpHandle, mem, sizeof(mem),longentry, sizeof(longentry), &attrs);
		if(retval > 0) {
			/* retval is the length of the file name in the mem buffer */ 
			
			NSString *name = [NSString stringWithUTF8String:mem];			
			NSMutableDictionary *dict = [NSMutableDictionary dictionary];

			if([name characterAtIndex:0] == '.')
				continue;
			
			if(LIBSSH2_SFTP_S_ISDIR(attrs.permissions)) {
				NSImage *icon = [workspace iconForFile:@"/etc"];
				[icon setSize:NSMakeSize(16,16)];			
				[dict setObject:icon forKey:@"icon"];
				
				[dict setObject:@"dir" forKey:@"type"];
			}
			else {
				NSImage *icon = [workspace iconForFileType:[[name componentsSeparatedByString:@"."] lastObject]];
				[icon setSize:NSMakeSize(16,16)];
				[dict setObject:icon forKey:@"icon"];
				
				[dict setObject:@"file" forKey:@"type"];
			}
			[dict setObject:name forKey:@"name"];
			[files addObject:dict];
			
			printf("%s\n", mem);
		}
		else
			break;
		
	} while (1);
	
	[_files setObject:files forKey:path];
	[self setValue:[NSNumber numberWithBool:FALSE] forKey:@"_isbusy"];
	
	/*
		
	int i;
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

		[dict setObject:absoluteName forKey:@"path"];
		[dict setObject:name forKey:@"name"];
		[files addObject:dict];
	}
	
	NSMutableArray *list = [NSMutableArray array];
	NSArray *reversedList = [[_browser path] pathComponents];
	for(i=([reversedList count]-1); i>=0; i--) //reversing
		[list addObject:[reversedList objectAtIndex:i]];
	[self setValue:list forKey:@"_directoryList"];
	
	*/
}

-(NSString *)authenticate
{
	//NSString *pass = [_sftpController authenticateFromSavedPasswords:[self url]];
	/*if(!pass)
	{
		[NSApp beginSheet:_passwordPanel modalForWindow:_mainPanel modalDelegate:self didEndSelector:NULL contextInfo:NULL];
	}*/
	return(@"temp");
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
