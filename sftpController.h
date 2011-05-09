//
//  sftpController.h
//  arRsync
//
//  Created by Miles Wu on 24/06/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Security/Security.h>

@interface sftpController : NSObject {

	NSMutableDictionary *_passwords;
	
	NSNetServiceBrowser *_serviceBrowser;
	
	NSMutableArray *_bonjourHosts;
	NSMutableArray *_saneBonjourHosts;

	NSMutableArray *_hostFileHosts;
	
	IBOutlet NSPanel *_passwordPanel;
	IBOutlet NSSecureTextField *_passwordField;
	NSMutableString *_currentHost;
	NSNumber *_rememberPassword;
}

-(sftpController *)init;
-(void)dealloc;

-(void)giveMeSFTP:(NSNotification *)notification;

-(NSString *)authenticateFromSavedPasswords:(NSString *)host;
-(void)addPassword:(NSString *)password withHost:(NSString *)host alsoInKeychain:(BOOL)flag;
-(void)failedAuthentication:(NSString *)host;
-(NSString *)addkeyForHost:(NSString *)host;


-(IBAction)endPanelButtons:(id)sender;

-(void)netServiceBrowser:(NSNetServiceBrowser *)sender didFindService:(NSNetService *)netService moreComing:(BOOL)moreComing;
-(void)netServiceBrowser:(NSNetServiceBrowser *)sender didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreComing;

-(void)parseHostFile;
-(void)addHost:(NSString *)host;
@end
