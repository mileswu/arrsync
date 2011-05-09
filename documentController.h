//
//  documentController.h
//  arRsync
//
//  Created by Miles Wu on 23/06/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
  
#import <Cocoa/Cocoa.h>
#import "presetObj.h"
#import "sftpBrowse.h"
#import "rsyncController.h"

@interface documentController : NSObject {	
	IBOutlet NSWindow *_mainWindow;
	IBOutlet NSArrayController *_presetsArrayController;
	
	IBOutlet NSPanel *_fileSheet;
	IBOutlet NSView *_browsePanelAddition;
	
	NSMutableArray *_presets;
	NSMutableArray *_sourceFiles;
	NSMutableString *_destFile;
	
	NSNumber *_allowedSFTP;
	NSNumber *_SFTPforSource;
	NSNumber *_SFTPforDest;
}

-(documentController *)initWithPresetsArray:(NSMutableArray *)presets;
-(IBAction)addFiles:(id)sender;
-(IBAction)browseFile:(id)sender;
-(IBAction)endModalWithTag:(id)sender;
-(IBAction)finishAddingFiles:(id)sender;
-(IBAction)sync:(id)sender;

-(presetObj *)currentPreset;
-(NSArray *)currentPresets;
-(int)numberSelected;

@end
