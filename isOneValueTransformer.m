//
//  isOneValueTransformer.m
//  arRsync
//
//  Created by Miles Wu on 11/10/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "isOneValueTransformer.h"


@implementation isOneValueTransformer
- (id)transformedValue:(id)value
{
	BOOL retval;
	
	if([value intValue] == 1)
		retval = NO;
	else
		retval = YES;
	
	return [NSNumber numberWithBool:retval];
}
@end
