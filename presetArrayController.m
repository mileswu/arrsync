//
//  presetArrayController.m
//  arRsync
//
//  Created by Miles Wu on 07/10/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "presetArrayController.h"


@implementation presetArrayController

-(presetArrayController *)init
{
	presetArrayController *i = [super init];

	return(i);
}

-(void)awakeFromNib
{
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh:) name:@"presetsChanged" object:nil];
}

-(void)add:(id)sender
{
	presetObj *newPreset = [[[[presetObj alloc] init] initNew] autorelease];
	
	NSArray *content = [self content];
	int i, *occupied = malloc(sizeof(int)*[content count]), no = 0, probe = 1, j, flag = 0;
	for(i=0; i<[content count]; i++)
	{
		NSString *s = [[content objectAtIndex:i] valueForKey:@"_name"];
		if([s hasPrefix:@"Untitled"])
		{
			if([s length] == 8)
				occupied[no] = 1;
			else
				occupied[no] = [[s substringFromIndex:9] intValue];
			no++;
		}
	}
	
	i=0;
	while(1)
	{
		for(j=0; j<no; j++)
			if(occupied[j] == probe)
			{
				flag = 1;
				break;
			}
		
		if(flag == 1)
		{
			probe++;
			flag = 0;
		}
		else
			break;
	}
	
	[self addObject:newPreset];
	if(probe != 1)
		[newPreset setValue:[NSString stringWithFormat:@"Untitled %d", probe] forKey:@"_name"];
	else
		[newPreset setValue:@"Untitled" forKey:@"_name"];
}

-(void)remove:(id)sender
{	//Needs to learn how to deal with multiple
	
	NSString* messageText = [NSString string];
	
	if([[self selectedObjects] count] == 1){
		messageText = [NSString stringWithFormat:@"Are you sure you want to \ndelete \"%@\"?", [[self selection] valueForKey:@"name"]];
	}else{
		messageText = [NSString stringWithFormat:@"Are you sure you want to \ndelete these %d presets?", [[self selectedObjects] count]];
	}
		
	NSAlert *a = [NSAlert alertWithMessageText:messageText
							defaultButton:@"Cancel"
							alternateButton:@"Delete"
							   otherButton:NULL
				 informativeTextWithFormat:@"This action is not undoable."];
			
	NSImage *finalIcon = [[NSImage alloc] initWithSize:NSMakeSize(64,64)];//[NSImage imageNamed:@"warning"];
	[finalIcon lockFocus];
	NSImage *warningIcon = [NSImage imageNamed:@"warning"];
	[warningIcon setScalesWhenResized:TRUE];
	[warningIcon setSize:NSMakeSize(64,64)];
	[warningIcon dissolveToPoint:NSMakePoint(0,0) fraction:1.0];

	if([[self selectedObjects] count] == 1)
		[[[self selection] valueForKey:@"_statusIcon"] dissolveToPoint:NSMakePoint(32,0) fraction:1.0];
	else {
		[[[[self selectedObjects] objectAtIndex:[[self selectedObjects] count]-1] valueForKey:@"_statusIcon"] dissolveToPoint:NSMakePoint(28,4) fraction:0.8];
		[[[[self selectedObjects] lastObject] valueForKey:@"_statusIcon"] dissolveToPoint:NSMakePoint(32,0) fraction:1.0];
	}


	[finalIcon unlockFocus];
	
	[a setIcon:finalIcon];
	
	[a beginSheetModalForWindow:[sender window] modalDelegate:self didEndSelector:@selector(confirmedRemove:returnCode:contextInfo:) contextInfo:sender];
}

-(void)confirmedRemove:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(id)sender
{
	if(returnCode != NSOKButton)
	{
		[super remove:sender];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"presetsPLISTdump" object:self];
	}
	[[alert window] orderOut:self];
}

/*-(void)addObject:(id)sender
{	
	NSLog(@"G");
	[super addObject:sender];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"presetsChanged" object:self];

}

-(void)removeObject:(id)sender;
{
	[super removeObject:sender];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"presetsChanged" object:self];

}*/


@end
