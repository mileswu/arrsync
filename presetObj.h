//
//  presetObj.h
//  arRsync
//
//  Created by Miles Wu on 05/10/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#define SSHBrowse 20
#define LocalBrowse 10

#import "rsyncController.h"

@interface presetObj : NSObject {
	NSString *_name;
	NSImage *_statusIcon;
	NSMutableArray *_files;
	
	NSMutableDictionary *_options;
	NSMutableDictionary *_lastRun;
	rsyncController *_rsyncController;
	
	NSNumber *_running;
	NSMutableArray *_errors;
	NSNumber *_wantsAttention;
	NSNumber *_totalFileCount;
	NSNumber *_filesDone;
	}

-(presetObj *)init;
-(presetObj *)initFromPlist:(NSDictionary *)dict;
-(presetObj *)initNew;
-(void)addObservers;

-(void)addFiles:(NSArray *)files;

-(void)updateStatusIcon;
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;

@end
