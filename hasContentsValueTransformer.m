//
//  hasContentsValueTransformer.m
//  arRsync
//
//  Created by Miles Wu on 07/10/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "hasContentsValueTransformer.h"


@implementation hasContentsValueTransformer


- (id)transformedValue:(id)value
{
	BOOL retval;

	if([value isKindOfClass:[NSString class]])
		retval = [value length] == 0 ? NO : YES;
	else if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]])
		retval = [value count] == 0 ? NO : YES;
		
	return [NSNumber numberWithBool:retval];
}

@end
