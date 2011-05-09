//
//  presetArrayController.h
//  arRsync
//
//  Created by Miles Wu on 07/10/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "presetObj.h"

@interface presetArrayController : NSArrayController {

}

-(presetArrayController *)init;
-(void)awakeFromNib;
//-(void)refresh:(NSNotification *)notification;

-(void)add:(id)sender;
-(void)remove:(id)sender;
-(void)confirmedRemove:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(id)sender;

/*-(void)addObject:(id)sender;
-(void)removeObject:(id)sender;*/

@end
