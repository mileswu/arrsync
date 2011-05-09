//
//  documentController.m
//  arRsync
//
//  Created by Miles Wu on 23/06/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "documentController.h"

@implementation documentController

-(documentController *)initWithPresetsArray:(NSMutableArray *)presets;
{
	documentController *currDocument = [super init];
	
	_presets = presets;
	_sourceFiles = [[NSMutableArray array] retain];
	_destFile = [[NSMutableString string] retain];
	_allowedSFTP = [[NSNumber numberWithBool:TRUE] retain];
	_SFTPforSource = [[NSNumber numberWithBool:FALSE] retain];
	_SFTPforDest = [[NSNumber numberWithBool:FALSE] retain];
	
	return(currDocument);
}

-(presetObj *)currentPreset
{
	int i;	
	if((i = [_presetsArrayController selectionIndex]) != NSNotFound)
		return([_presets objectAtIndex:i]);
	else
		return(nil);
}

-(IBAction)addFiles:(id)sender
{
	if([self currentPreset])
	{
		[self setValue:[NSMutableArray array] forKey:@"_sourceFiles"];
		[self setValue:[NSMutableString string] forKey:@"_destFile"];
		
		[self setValue:[NSNumber numberWithBool:FALSE] forKey:@"_SFTPforSource"];
		[self setValue:[NSNumber numberWithBool:FALSE] forKey:@"_SFTPforDest"];
		
		[NSApp beginSheet:_fileSheet
		   modalForWindow: _mainWindow
			modalDelegate: self
		   didEndSelector:NULL
			  contextInfo:nil
			];
	}

}

-(IBAction)browseFile:(id)sender
{
	int localbrowse = 100;//, remotebrowse = 101;
	int result = localbrowse;
	id openPanel;
	BOOL usedSFTP;
	
	if([sender tag] == 1 && [_SFTPforDest boolValue] == TRUE) //source
		[self setValue:[NSNumber numberWithBool:FALSE] forKey:@"_allowedSFTP"];
	else if([sender tag] == 2 && [_SFTPforSource boolValue] == TRUE) //dest
		[self setValue:[NSNumber numberWithBool:FALSE] forKey:@"_allowedSFTP"];
	else
		[self setValue:[NSNumber numberWithBool:TRUE] forKey:@"_allowedSFTP"];

	
	while(result != NSOKButton && result != NSCancelButton)
	{
		//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		if(result == localbrowse)
		{
			usedSFTP = FALSE;
			openPanel = [NSOpenPanel openPanel];
			[openPanel setAccessoryView:_browsePanelAddition];
		}
		else //remote browse
		{
			usedSFTP = TRUE;
			openPanel = [[[sftpBrowse alloc] initWithSender:self] autorelease];
			[NSBundle loadNibNamed:@"sftpBrowse" owner:openPanel];
		}
		
		if([sender tag] == 1)
		{
			[openPanel setTitle:@"Add Sources"];
			[openPanel setCanChooseDirectories:TRUE];
			[openPanel setAllowsMultipleSelection:TRUE];
		}
		else //dest
		{
			[openPanel setTitle:@"Set Destination"];
			[openPanel setCanCreateDirectories:TRUE];
			[openPanel setCanChooseDirectories:TRUE];
			[openPanel setCanChooseFiles: FALSE];
		}
		result = [openPanel runModal];
		//[pool release];
	}

	if([sender tag] == 1 && result == NSOKButton) //sources
	{
		[self setValue:[NSNumber numberWithBool:usedSFTP] forKey:@"_SFTPforSource"];
		[self setValue:[openPanel filenames] forKey:@"_sourceFiles"];
	}
	else if([sender tag] == 2 && result == NSOKButton) //dest
	{
		[self setValue:[NSNumber numberWithBool:usedSFTP] forKey:@"_SFTPforDest"];
		[self setValue:[openPanel filename] forKey:@"_destFile"];
	}
}

-(IBAction)endModalWithTag:(id)sender{ //called by sftpBrowse on "Cancel", "OK" and the segmented control of both NS and SFTP		
	[NSApp stopModalWithCode:[sender tag]];
}

-(IBAction)finishAddingFiles:(id)sender
{
	[NSApp endSheet:_fileSheet];
	int i;
	
	NSMutableArray *arr = [NSMutableArray array];
	
	if([sender tag] == 1)
		for(i=0; i<[_sourceFiles count]; i++)
			[arr addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:TRUE], @"enabled",
				[_sourceFiles objectAtIndex:i], @"source",
				_destFile, @"destination", NULL]];

	[[self currentPreset] addFiles:arr];
	[_fileSheet orderOut:self];
}

-(NSArray *)currentPresets
{
	return([_presetsArrayController selectedObjects]);
}

-(int)numberSelected
{
	return([[_presetsArrayController selectedObjects] count]);
}


-(IBAction)sync:(id)sender
{
	if([self numberSelected] == 0)
	{
		NSLog(@"Nothing to run");
	}
	else if([self numberSelected] == 1)
		[[[self currentPreset] valueForKey:@"_rsyncController"] sync];
	else
	{
		NSArray *objs = [self currentPresets];
		int i;
		for(i=0; i<[objs count]; i++)
			[[[objs objectAtIndex:i] valueForKey:@"_rsyncController"] sync];
	}
}

@end
