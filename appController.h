//
//  appController.h
//  arRsync
//
//  Created by Adam on 22/06/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//
   
#import <Cocoa/Cocoa.h>
#import "sftpController.h"
#import "documentController.h"
#import "presetObj.h"
#import "hasContentsValueTransformer.h"
#import "isOneValueTransformer.h"

@interface appController : NSObject {
	NSMutableArray *_presets;

}

//Initialisation Routines
-(appController *)init;
-(void)awakeFromNib;
-(IBAction)newDocument:(id)sender;

-(void)dumpPresetsInPlist:(NSNotification *)notification;

@end
