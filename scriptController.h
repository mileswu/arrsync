//
//  scriptController.h
//  arRsync
//
//  Created by Miles Wu on 27/04/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <header.h>
#import "rsyncController.h"
#import "presetController.h"

@interface scriptController : NSScriptCommand {

}

-(id)performDefaultImplementation;

-(void)runPreset:(NSString *)presetName;
@end
