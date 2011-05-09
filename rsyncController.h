

#import <Cocoa/Cocoa.h>
#import <unistd.h>
#import "sftpController.h"
#import "PTYTask.h"

@class presetObj;

@interface rsyncController : NSObject {

	sftpController *_sftpController;

	//int _termination;
	
	PTYTask *_cmd;
	NSFileHandle *_cmdOutput;
	NSFileHandle *_cmdError;
	NSFileHandle *_cmdInput;
	
	presetObj *_presetObj;
}

-(rsyncController *)initWithPreset:(presetObj *)preset;
-(void)setSFTPController:(sftpController *)aObj;

/*//cmd manip
- (BOOL)isRunning;
- (void)suspendCmd;
- (void)resumeCmd;
- (void)stopCmd;*/


-(void)sync;
- (void)startCmdThread:(id)nothing;
-(NSArray *)getRsyncArguments;
-(NSArray *)getEnabledFiles;
-(BOOL)isBidirectional;
-(PTYTask *)runSyncWithArgs:(NSArray *)rsyncArguments withFile:(NSDictionary *)file reversed:(BOOL)reversed;
-(int)countDryRun:(PTYTask*)dryrun;
-(int)dryRunCountForAll;

-(void)updateErrors:(PTYTask *)task;
-(int)updateProgress:(PTYTask *)task;


/*/progress
- (void)updateErrors:(id)anObject;
- (void)updateProgress:(id)anObject;*/

//Stuff
- (int)numberOfCharactersInString:(NSString *)str character:(char)chr;
-(BOOL)isRemote:(NSString *)file;
-(NSString *)escapeString:(NSString *)str;

@end
