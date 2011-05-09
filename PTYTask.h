#import <Cocoa/Cocoa.h>
#import <unistd.h>
#import <util.h>
#import <termios.h>

@interface PTYTask : NSObject {
    NSString * path; 
    NSArray * args;      
    NSFileHandle * handle;   
    NSFileHandle * errorHandle;
	
	struct winsize winSize;        
	
	int fd;
    int pid;
	NSData *excessData;
}

- (PTYTask *)init;
-(void)dealloc;

- (int)pid;
- (NSFileHandle *)handle;
- (NSFileHandle *)errorHandle;
-(void)kill;
- (void)setPath:(NSString *)newPath;
- (void)setArgs:(NSArray *)newArgs;
- (NSData *)excessData;
- (void)setExcessData:(NSData *)data;
- (void)launchTask;

@end