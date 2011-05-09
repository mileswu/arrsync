//
//  appController.m
//  arRsync
//
//  Created by Adam on 22/06/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "appController.h"


@implementation appController

-(appController *)init
{
	appController *r = [super init];
	
	hasContentsValueTransformer *hcTransformer = [[[hasContentsValueTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:hcTransformer forName:@"hasContentsValueTransformer"];
	
	isOneValueTransformer *is1 = [[[isOneValueTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:is1 forName:@"isOneValueTransformer"];

	_presets = [[NSMutableArray array] retain];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dumpPresetsInPlist:) name:@"presetsPLISTdump" object:nil];
	
	sftpController *s = [[sftpController alloc] init];
	[NSBundle loadNibNamed:@"sftpAuthentication" owner:s];
	
	[self loadPresets];
	return(r);
}

-(void)awakeFromNib
{
	documentController *newDocument = [[documentController alloc] initWithPresetsArray:_presets];
	[NSBundle loadNibNamed:@"syncDocument" owner:newDocument];
	

}

-(IBAction)newDocument:(id)sender
{

}

-(void)dumpPresetsInPlist:(NSNotification *)notification;
{
	int i;
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	NSMutableArray *arr = [NSMutableArray array];
	
	for(i=0; i<[_presets count]; i++)
		[arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[[_presets objectAtIndex:i] valueForKey:@"_options"], @"options",
			[[_presets objectAtIndex:i] valueForKey:@"_files"], @"files",
			[[_presets objectAtIndex:i] valueForKey:@"_name"], @"name",
			[[_presets objectAtIndex:i] valueForKey:@"_errors"], @"errors",
			[[_presets objectAtIndex:i] valueForKey:@"_lastRun"], @"lastRun", nil]];
	
	[ud setValue:arr forKey:@"presets"];
}

-(void)loadPresets
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	int flag=0;
		
	if([ud valueForKey:@"lastAppVersion"])
	{
		if([[ud valueForKey:@"lastAppVersion"] isEqualToString:@"0.4"])
		{
			NSArray *arr = [ud valueForKey:@"presets"];
			int i, j;
			
			for(i=0; i<[arr count]; i++)
			{
				NSDictionary *preset = [arr objectAtIndex:i];
				NSMutableDictionary *newPreset = [NSMutableDictionary dictionary];
				
				[newPreset setValue:[preset valueForKey:@"name"] forKey:@"name"];
				
				NSMutableDictionary *newOptions = [NSMutableDictionary dictionary];
				NSDictionary *options = [preset valueForKey:@"arguments"];
				
				[newOptions setValue:[options valueForKey:@"attributes"] forKey:@"extendedAttr"];
				if([[options valueForKey:@"checks"] intValue] == 3) //option no longer exists
					[newOptions setValue:[NSNumber numberWithInt:2] forKey:@"checkMode"];
				else
					[newOptions setValue:[options valueForKey:@"checks"] forKey:@"checkMode"];
				[newOptions setValue:[options valueForKey:@"mode"] forKey:@"mode"];
				[newOptions setValue:[options valueForKey:@"permissions"] forKey:@"preservePermissions"];
				[newOptions setValue:[options valueForKey:@"symlinks"] forKey:@"symlink"];
				[newOptions setValue:[options valueForKey:@"wholeFile"] forKey:@"copyMode"];
				[newOptions setValue:[NSNumber numberWithInt:0] forKey:@"inplace"];
				
				[newPreset setValue:newOptions forKey:@"options"];
				
				NSArray *files = [preset valueForKey:@"files"];
				NSMutableArray *newFiles = [NSMutableArray array];
				for(j=0; j<[files count]; j++)
				{
					NSArray *file = [files objectAtIndex:j];
					NSMutableDictionary *newFile = [NSMutableDictionary dictionary];
					
					[newFile setValue:[file objectAtIndex:0] forKey:@"enabled"];
					[newFile setValue:[NSMutableString stringWithString:[file objectAtIndex:3]] forKey:@"destination"];
					[newFile setValue:[NSMutableString stringWithFormat:@"%@/%@", [file objectAtIndex:2], [file objectAtIndex:1]] forKey:@"source"];
					
					[newFiles addObject:newFile];
				}
				[newPreset setValue:newFiles forKey:@"files"];
				
				[newPreset setValue:[NSMutableArray array] forKey:@"errors"];
				
				NSMutableDictionary *lastRun = [NSMutableDictionary dictionary];
				[lastRun setValue:[NSNumber numberWithBool:FALSE] forKey:@"time"];
				[lastRun setValue:[NSNumber numberWithBool:FALSE] forKey:@"duration"];
				[lastRun setValue:[NSNumber numberWithBool:FALSE] forKey:@"sourceChanges"];
				[lastRun setValue:[NSNumber numberWithBool:FALSE] forKey:@"destChanges"];
				[newPreset setValue:lastRun forKey:@"lastRun"];
				
				[_presets addObject:[[[[presetObj alloc] init] initFromPlist:newPreset] autorelease]];
			}
			[ud setValue:@"0.6" forKey:@"lastAppVersion"];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"presetsPLISTdump" object:self];
		}
		else if([[ud valueForKey:@"lastAppVersion"] isEqualToString:@"0.6"])
		{
			NSArray *arr = [ud valueForKey:@"presets"];
			int i;
				
			for(i=0; i<[arr count]; i++)
				[_presets addObject:[[[[presetObj alloc] init] initFromPlist:[arr objectAtIndex:i]] autorelease]];
			[ud setValue:@"0.6" forKey:@"lastAppVersion"];
		}
		else
			flag = 1;
	}
	else
		flag = 1;
	
	if(flag == 1)
	{
		NSLog(@"We don't support your backwards version");
		[ud setValue:@"0.6" forKey:@"lastAppVersion"];
		[ud setValue:[NSArray array] forKey:@"presets"];
	}
}

@end
