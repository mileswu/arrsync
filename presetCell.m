//
//  presetCell.m
//  arRsync
//
//  Created by Adam on 07/10/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "presetCell.h"


@implementation presetCell



- (id)init
{	
	[super init];
	
	presetCell *o = [presetCell alloc];

	return o;
}

-(void)setObjectValue:(id)value //This appears to be called
{
	[super setObjectValue:value];
}	

-(id)objectValue
{
	return [super objectValue];
}

-(void)drawWithFrame:(NSRect)frame inView:(NSView*)view
{
	
	NSAttributedString *myOverlayString = [[NSAttributedString alloc] 
													initWithString:[self title]
														attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																		(([self isHighlighted]) ? [NSColor whiteColor] : [NSColor blackColor] ),NSForegroundColorAttributeName,
																		[NSFont systemFontOfSize:[NSFont systemFontSize]],NSFontAttributeName,nil]];
	
	[myOverlayString drawAtPoint:NSMakePoint(frame.origin.x,frame.origin.y)];
	
	NSImage* sshImage = [NSImage imageNamed:@"sshSmall"];
	[sshImage dissolveToPoint:NSMakePoint(frame.origin.x, frame.origin.y+frame.size.height-2)  fraction:1.0];

}

-(void)drawInteriorWithFrame:(NSRect)frame inView:(NSView*)view
{
}


@end
