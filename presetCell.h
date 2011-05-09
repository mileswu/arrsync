//
//  presetCell.h
//  arRsync
//
//  Created by Adam on 07/10/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface presetCell : NSTextFieldCell {
}

- (id)init;
-(void)setObjectValue:(id)value;
-(id)objectValue;

-(void)drawWithFrame:(NSRect)frame inView:(NSView*)view;
-(void)drawInteriorWithFrame:(NSRect)frame inView:(NSView*)view;

@end
