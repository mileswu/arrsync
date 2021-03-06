//
//  sftpBrowse.h
//  arRsync
//
//  Created by Miles Wu on 23/06/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <libssh2.h>
#import <libssh2_sftp.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <unistd.h>
#import <sys/types.h>
#import <netdb.h>

#import "PTYTask.h"
#import "sftpController.h"


@interface sftpBrowse : NSObject {
	NSString *_title;
	
	id _sender; 
	
	sftpController *_sftpController;
	
	LIBSSH2_SESSION *_sshSession;
	LIBSSH2_SFTP *_sftpSession;
	LIBSSH2_SFTP_HANDLE *_sftpHandle;
	
	BOOL _chooseFiles;
	BOOL _createDirectories;
	BOOL _passwordPanelUp;
	
	IBOutlet NSPanel *_mainPanel;
	IBOutlet NSPanel *_passwordPanel;
	IBOutlet NSBrowser *_browser;
	IBOutlet NSSegmentedControl *_historySegmentedControl;
	//IBOutlet NSOutlineView *_outline;
	
	//NSString *_passwordField;
	NSString *_host;
	NSString *_username;
	NSNumber *_hostEditable;
	NSString *_statusInfo;
	NSNumber *_addToKeychain;
	NSMutableDictionary *_files;
	//NSNumber *_viewMode;
	NSNumber *_isbusy;
	NSMutableArray *_history;
	int _historyPosition;
	
	NSArray *_directoryList;
	NSNumber *_currentDirectoryIndex;
	
	NSNumber *_connected;
}
-(sftpBrowse *)initWithSender:(id)sender;
-(void)dealloc;

-(void)setSFTPController:(sftpController *)aObj;
-(void)awakeFromNib;
-(IBAction)connect:(id)sender;
-(IBAction)backforward:(id)sender;
-(IBAction)useHistory:(id)sender;
-(IBAction)disconnect:(id)sender;
-(NSString *)url;

-(void)browser:(NSBrowser *)aBrowser willDisplayCell:(NSBrowserCell *)aCell atRow:(int)row column:(int)column;
-(int)browser:(NSBrowser *)aBrowser numberOfRowsInColumn:(int)column;
-(void)browserSelected:(NSBrowserCell *)cell;

-(void)updateDirectoryListIsDir:(BOOL)isDir;

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;

-(void)updateHistoryEnabled;

/*- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;
- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item;
- (void)outlineViewDoubleClicked:(id)sender;*/


-(void)setTitle:(NSString *)aTitle;
-(NSArray *)filenames;
-(NSString *)filename;
-(void)setAccessoryView:(NSView *)aView;
-(int)runModal;

-(void)setCanChooseDirectories:(BOOL)flag;
-(void)setAllowsMultipleSelection:(BOOL)flag;
-(void)setCanChooseFiles:(BOOL)flag;
-(void)setCanCreateDirectories:(BOOL)flag;

-(IBAction)endModalWithTag:(id)sender;

-(NSString *)authenticate;
-(void)ls:(NSString *)path;


@end