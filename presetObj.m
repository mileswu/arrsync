//
//  presetObj.m
//  arRsync
//
//  Created by Miles Wu on 05/10/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "presetObj.h"


@implementation presetObj

-(presetObj *)init;
{
	presetObj *o = [super init];
	
	_name = [[NSMutableString stringWithString:@""] retain]; //Needs to be generated based on exisiting 'Untitled #' presets
	_statusIcon = [[NSImage imageNamed:@"idle0"] retain];
	_files = [[NSMutableArray array] retain];
	//[_files setNotification:@"presetsChanged"];
	_options = [[NSMutableDictionary dictionary] retain];
	//[_options setNotification:@"presetsChanged"];
	_errors = [[NSMutableArray array] retain];
	_lastRun = [[NSMutableDictionary dictionary] retain];
	
	_rsyncController = [[rsyncController alloc] initWithPreset:self];
	_running = [[NSNumber numberWithBool:FALSE] retain];
	_totalFileCount = [[NSNumber numberWithBool:FALSE] retain];
	_filesDone = [[NSNumber numberWithInt:0] retain];
	
	[_options setValue:[NSNumber numberWithInt:1] forKey:@"mode"];
	[_options setValue:[NSNumber numberWithInt:1] forKey:@"copyMode"];
	[_options setValue:[NSNumber numberWithInt:2] forKey:@"checkMode"];
	[_options setValue:[NSNumber numberWithBool:FALSE] forKey:@"inplace"];
	[_options setValue:[NSNumber numberWithBool:FALSE] forKey:@"symlinks"];
	[_options setValue:[NSNumber numberWithBool:FALSE] forKey:@"extendedAttr"];
	[_options setValue:[NSNumber numberWithBool:FALSE] forKey:@"preservePermissions"];
	
	[_lastRun setValue:[NSNumber numberWithBool:FALSE] forKey:@"time"];
	[_lastRun setValue:[NSNumber numberWithBool:FALSE] forKey:@"duration"];
	[_lastRun setValue:[NSNumber numberWithBool:FALSE] forKey:@"sourceChanges"];
	[_lastRun setValue:[NSNumber numberWithBool:FALSE] forKey:@"destChanges"];
	
	return(o);
}

-(void)addObservers
{
	[self addObserver:self forKeyPath:@"_running" options:NSKeyValueObservingOptionNew context:NULL];
	[self addObserver:self forKeyPath:@"_files" options:NSKeyValueObservingOptionNew context:NULL];
	[self addObserver:self forKeyPath:@"_name" options:NSKeyValueObservingOptionNew context:NULL];
	[self addObserver:self forKeyPath:@"_errors" options:NSKeyValueObservingOptionNew context:NULL];
	[self addObserver:self forKeyPath:@"_lastRun" options:NSKeyValueObservingOptionNew context:NULL];

	[self addObserver:self forKeyPath:@"_options.mode" options:NSKeyValueObservingOptionNew context:NULL];
	[self addObserver:self forKeyPath:@"_options.copyMode" options:NSKeyValueObservingOptionNew context:NULL];
	[self addObserver:self forKeyPath:@"_options.checkMode" options:NSKeyValueObservingOptionNew context:NULL];
	[self addObserver:self forKeyPath:@"_options.inplace" options:NSKeyValueObservingOptionNew context:NULL];
	[self addObserver:self forKeyPath:@"_options.symlinks" options:NSKeyValueObservingOptionNew context:NULL];
	[self addObserver:self forKeyPath:@"_options.extendedAttr" options:NSKeyValueObservingOptionNew context:NULL];
	[self addObserver:self forKeyPath:@"_options.preservePermissions" options:NSKeyValueObservingOptionNew context:NULL];
	
	[self addObserver:self forKeyPath:@"_lastRun.time" options:NSKeyValueObservingOptionNew context:NULL];
	[self addObserver:self forKeyPath:@"_lastRun.duration" options:NSKeyValueObservingOptionNew context:NULL];
	[self addObserver:self forKeyPath:@"_lastRun.sourceChanges" options:NSKeyValueObservingOptionNew context:NULL];
	[self addObserver:self forKeyPath:@"_lastRun.destChanges" options:NSKeyValueObservingOptionNew context:NULL];

}

-(presetObj *)initNew
{
	[self addObservers];
	return(self);
}

-(presetObj *)initFromPlist:(NSDictionary *)dict
{
	//presetObj *p = [presetObj init];
	[self setValue:[NSMutableDictionary dictionaryWithDictionary:[dict valueForKey:@"options"]] forKey:@"_options"];
	
	NSMutableArray *files = [NSMutableArray array];
	int i;
	for(i=0; i<[[dict valueForKey:@"files"] count]; i++)
		[files addObject:[NSDictionary dictionaryWithDictionary:[[dict valueForKey:@"files"] objectAtIndex:i]]];
	
	[self setValue:files forKey:@"_files"];
	[self setValue:[NSMutableString stringWithString:[dict valueForKey:@"name"]] forKey:@"_name"];

	[self setValue:[NSMutableArray arrayWithArray:[dict objectForKey:@"errors"]] forKey:@"_errors"]; 
	[self setValue:[NSMutableDictionary dictionaryWithDictionary:[dict objectForKey:@"lastRun"]] forKey:@"_lastRun"]; 

	[self addObservers];
	[self updateStatusIcon];
	return(self);
}

-(void)addFiles:(NSArray *)files
{
	[_files addObjectsFromArray:files];
	[self setValue:_files forKey:@"_files"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if([keyPath isEqualToString:@"_running"] || [keyPath isEqualToString:@"_files"])
		[self updateStatusIcon];
	if(![keyPath isEqualToString:@"_running"])
		[[NSNotificationCenter defaultCenter] postNotificationName:@"presetsPLISTdump" object:self];
}

-(void)updateStatusIcon{
	if([_running boolValue] == TRUE)
		 [self setValue:[NSImage imageNamed:@"syncing"] forKey:@"_statusIcon"] ;
	else
	{
		if([_wantsAttention boolValue] == TRUE)
		{
			if([_errors count] > 0)
				[self setValue:[NSImage imageNamed:@"errors"] forKey:@"_statusIcon"] ;
			else
				[self setValue:[NSImage imageNamed:@"success"] forKey:@"_statusIcon"] ;
			
		}
		else
		{
			if([_files count] <= 6)
				[self setValue:[NSImage imageNamed:[NSString stringWithFormat:@"idle%d", [_files count]]] forKey:@"_statusIcon"];
			else
				[self setValue:[NSImage imageNamed:@"idleMany"] forKey:@"_statusIcon"];
		}
	}
}


@end
