//
//  scriptController.m
//  arRsync
//
//  Created by Miles Wu on 27/04/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "scriptController.h"


@implementation scriptController

-(id)performDefaultImplementation
{
	
	NSString* commandName = [[self commandDescription] commandName];
		
	
	if([commandName isEqualToString:@"runPreset"])
		[self runPreset:[[[[self evaluatedArguments] allValues] objectAtIndex:0] stringValue]];

	return @"We don't know nothin'";
}


-(void)runPreset:(NSString *)presetName
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadPresetByName" object:presetName];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"startCmd" object:presetName];
	
}

@end
