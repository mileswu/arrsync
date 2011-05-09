//
//  sftpController.m
//  arRsync
//
//  Created by Miles Wu on 24/06/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "sftpController.h"

@implementation sftpController

-(sftpController *)init
{
	self = [super init];
	
	_passwords = [[NSMutableDictionary dictionary] retain];
	_bonjourHosts = [[NSMutableArray array] retain];
	_saneBonjourHosts = [[NSMutableArray array] retain];
	_hostFileHosts = [[NSMutableArray array] retain];
	_currentHost = [[NSMutableString string] retain];
	_rememberPassword = [[NSNumber numberWithBool:FALSE] retain];
	
	[_bonjourHosts addObject:@"B"]; //for top value of list
	[_saneBonjourHosts addObject:@"B"]; //for top value of list
	[_hostFileHosts addObject:@"SH"]; //for top value of list
	
	NSUserDefaults *udc = [NSUserDefaults standardUserDefaults];
	
	if([udc arrayForKey:@"lastHosts"] == nil)
		[udc setObject:[NSArray arrayWithObject:@"H"] forKey:@"lastHosts"];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(giveMeSFTP:) name:@"GiveMeASFTPController" object:nil];
	
	_serviceBrowser = [[[[NSNetServiceBrowser alloc] init] autorelease] retain];
	[_serviceBrowser setDelegate:self];
	[_serviceBrowser searchForServicesOfType:@"_ssh._tcp." inDomain:@""];
	
	[self parseHostFile];
	
	return(self);
}

-(void)dealloc
{
	[_passwords release];
	[_bonjourHosts release];
	[_saneBonjourHosts release];
	[_hostFileHosts release];	
	[_serviceBrowser release];
	[_currentHost release];
	[_rememberPassword release];
	[super release];
}

-(void)giveMeSFTP:(NSNotification *)notification
{
	id obj = [notification object];
	[obj setSFTPController:self];
}

-(void)addPassword:(NSString *)password withHost:(NSString *)host alsoInKeychain:(BOOL)flag
{
	[_passwords setValue:password forKey:host];
	if(flag == TRUE)
	{
		NSString *account = [NSString stringWithFormat:@"arRsync SFTP - %@", host];
		NSLog(@"ACC - %@", account);
		NSLog(@"HST - %@", host);
		NSLog(@"PSS - %@", password);
		
		const char *Caccount, *Chost, *Cpassword;
		Caccount = [account UTF8String];
		Chost = [host UTF8String];
		Cpassword = [password UTF8String];

		SecKeychainAddGenericPassword(NULL, strlen(Caccount), Caccount, strlen(Chost), Chost, strlen(Cpassword), (const void *)Cpassword, nil);
		NSLog(@"added");
	}
}

-(NSString *)addkeyForHost:(NSString *)host;
{
	//Place some Dialog in here at some point in the future
	return("yes");
}     


-(NSString *)authenticateFromSavedPasswords:(NSString *)host
{
	NSLog(@"Auth from save");
	NSString *pass;

	pass = [_passwords objectForKey:host];
	if(pass)
	{
		NSLog(pass);
		return(pass);
	}
		
	void *cStringpass = nil;
	UInt32 length = nil;
	OSStatus status;
	
	NSString *account = [NSString stringWithFormat:@"arRsync SFTP - %@", host];
	const char *Caccount, *Chost;
	Caccount = [account UTF8String];
	Chost = [host UTF8String];
	NSLog(@"Auth from save2");

	status = SecKeychainFindGenericPassword(nil, strlen(Caccount), Caccount, strlen(Chost), Chost, &length, &cStringpass, nil);
	NSLog(@"Auth from save3");
	
	if(status==noErr)
	{
		pass = [NSString stringWithCString:cStringpass length:length];
		SecKeychainItemFreeContent(NULL, cStringpass);

		[_passwords setValue:pass forKey:host];
		NSLog(pass);
		return(pass);
	}
	SecKeychainItemFreeContent(NULL, cStringpass);
	
	[self setValue:host forKey:@"_currentHost"];
	[self setValue:[NSNumber numberWithBool:FALSE] forKey:@"_rememberPassword"];
	
	[_passwordField setStringValue:@""];
	int retval = [NSApp runModalForWindow:_passwordPanel];
	if(retval != NSOKButton)
	{
		return(NULL);
	}
	
	[self addPassword:[_passwordField stringValue] withHost:host alsoInKeychain:[[self valueForKey:@"_rememberPassword"] boolValue]];
	return([_passwordField stringValue]);
}

-(IBAction)endPanelButtons:(id)sender
{
	[NSApp stopModalWithCode:[sender tag]];
	[_passwordPanel orderOut:self];
}

-(void)failedAuthentication:(NSString *)host
{
	[_passwords removeObjectForKey:host];
	
	SecKeychainItemRef kcitem;
	OSStatus status;
	
	NSString *account = [NSString stringWithFormat:@"arRsync SFTP - %@", host];
	
	status = SecKeychainFindGenericPassword(NULL, [account length], [account cStringUsingEncoding:NSASCIIStringEncoding], [host length], [host cStringUsingEncoding:NSASCIIStringEncoding], NULL, NULL, &kcitem);

	if(status==noErr)
		SecKeychainItemDelete(kcitem);
} 

-(void)netServiceBrowser:(NSNetServiceBrowser *)sender didFindService:(NSNetService *)netService moreComing:(BOOL)moreComing
{
	NSString *sanitized = [NSString stringWithFormat:@"%@.local", [netService name]];
	
	////replace spaces with - and any non-normal character removed
	
	[_bonjourHosts addObject:[netService name]];
	[_saneBonjourHosts addObject:sanitized];
	[self setValue:_saneBonjourHosts forKey:@"_saneBonjourHosts"];
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)sender didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreComing
{
	int i;
	for(i=0;i<[_bonjourHosts count];i++)
		if([[_bonjourHosts objectAtIndex:i] isEqualToString:[netService name]])
		{
			[_bonjourHosts removeObjectAtIndex:i];
			[_saneBonjourHosts removeObjectAtIndex:i];
			[self setValue:_saneBonjourHosts forKey:@"_saneBonjourHosts"];
			break;
		}
}

-(void)parseHostFile
{
	[_hostFileHosts removeAllObjects];
	[_hostFileHosts addObject:@"SH"]; //for top value of list

	NSString *file = [NSString stringWithContentsOfFile:[@"~/.ssh/known_hosts" stringByExpandingTildeInPath]];
	if(file == nil)
		return;
	
	NSArray *lines = [file componentsSeparatedByString:@"\n"];
	
	int i;
	for(i=0; i<[lines count]; i++)
	{	
		NSString *h = [[[[[lines objectAtIndex:i] componentsSeparatedByString:@" "] objectAtIndex:0] componentsSeparatedByString:@","] objectAtIndex:0];
		if(![h isEqualToString:@""])
			[_hostFileHosts addObject:h];
	}
	
	[self setValue:_hostFileHosts forKey:@"_hostFileHosts"];
}

-(void)addHost:(NSString *)host //stored in plist
{
	NSUserDefaults *udc = [NSUserDefaults standardUserDefaults];
	NSArray *storedHosts;
	
	storedHosts = [udc arrayForKey:@"lastHosts"];
	
	int i, max = 10;
	NSMutableArray *newArray = [NSMutableArray array];
	
	for(i=0; i<[storedHosts count]; i++)
		if(![[storedHosts objectAtIndex:i] isEqualToString:host])
			[newArray addObject:[storedHosts objectAtIndex:i]];
		
	if([newArray count] == max+1) //don't forget first is dummy
		[newArray removeObjectAtIndex:max];

	[newArray insertObject:host atIndex:1];
	
	[udc setObject:[NSArray arrayWithArray:newArray] forKey:@"lastHosts"];
}




@end
