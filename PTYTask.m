#import "PTYTask.h"

@implementation PTYTask


- (PTYTask *)init
{
	pid = -1;
	
	winSize.ws_row = 1;
	winSize.ws_col = 1;
	winSize.ws_xpixel = 0;
	winSize.ws_ypixel = 0;
	
	return self;
}

-(void)dealloc
{
	[path release];
	[args release];
	[errorHandle release];
	[handle release];
	
	[super dealloc];
}

- (void)setPath:(NSString *)newPath
{	 
	[path release];
	path = [newPath copy];
}

- (void)setArgs:(NSArray *)newArgs
{
	[args release];
	args = [newArgs copy];
}

- (NSData *)excessData
{
	if(excessData)
		return(excessData);
	else
		return([NSData data]);
}

- (void)setExcessData:(NSData *)data
{
	if(excessData)
		[excessData release];
	excessData = [data retain];
}

- (int)pid
{
	return pid;
}

- (NSFileHandle *)handle
{
	return handle;
}

- (NSFileHandle *)errorHandle
{
	return errorHandle;
}


- (void)launchTask
{
	int i2;
	for(i2=0; i2<[args count]; i2++)
		NSLog([args objectAtIndex:i2]);
		
	int errorpipe[2];
	pipe(errorpipe);
		
	pid = forkpty(&fd, NULL, NULL, &winSize);
	
	if (pid > 0) //parent
	{
		close(errorpipe[1]);
		[errorHandle release];
		[handle release];

		errorHandle = [[NSFileHandle alloc] initWithFileDescriptor:errorpipe[0] closeOnDealloc:NO];
		handle = [[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc: NO];
	}
	else if (pid < 0) //failure
		[NSException raise: NSObjectInaccessibleException format: @"Could not fork. Too many processes?!"];
	else { //child
		char **argv = malloc((1 + [args count]) * sizeof(char *));
		int i;
		const char *arg;
		
		for(i=0; i<[args count]; i++)
		{
			arg = [[args objectAtIndex:i] UTF8String];
			argv[i] = malloc(strlen(arg) + 1);
			strcpy(argv[i], arg);
		}
		argv[[args count]] = NULL;

		char **envp = malloc(sizeof(char *));
		envp[0] = NULL;
		
		close(2);
		dup(errorpipe[1]);
		close(errorpipe[0]);
		close(errorpipe[1]);
		
		execve([path fileSystemRepresentation], argv, envp);
	}
}

-(void)kill
{
	if(pid != -1)
		kill((pid_t)pid, SIGINT);
}

@end
