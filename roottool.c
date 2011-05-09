/*
 *  roottool.c
 *  arRsync
 *
 *  Created by Miles Wu on 03/10/2006.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#include "roottool.h"

int main(int argc, char **argv)
{
	OSStatus status;
	AuthorizationRef authref;
	
	//path to self
	
	if(argc==2 && !strcmp(argv[1], "--self-repair"))
	{
		struct stat st;
		int fd_tool;
		
		status = AuthorizationCopyPrivilegedReference(&authref, kAuthorizationFlagDefaults) //GET AEWP ref
		if(status != 0)
			exit(-1);
		
		fd_tool = open(path_to_self, O_NONBLOCK|O_RDONLY|O_EXLOCK, 0); //OPEN EXCLUSIVELY
		if(fd_tool == -1)
			exit(-1);
		
		if(fstat(fd_tool, &st)) //GET Stat
			exit(-1);
			
		if (st.st_uid != 0) //OWN AS ROOT
			fchown(fd_tool, 0, st.st_gid);
		
		fchmod(fd_tool, (st.st_mode & (~(S_IWGRP|S_IWOTH))) | S_ISUID); //chmod w-w g-w +s
		close(fd_tool);
	}
	else //NOT SELF REPAIR mode
	{
		AuthorizationExternalForm extAuth;
		
		if(read(0, &extAuth, sizeof(extAuth)) != sizeof(extAuth)) //Reading auth in
			exit(-1);
		if(AuthorizationCreateFromExternalForm(&extAuth, &auth)) //making it normal
			exit(-1);
		
		if(geteuid()!=0) //Are we root?
		{////self repair
			FILE *commPipe = NULL;
			char *arguments[] = { "--self-repair", NULL };

			if (AuthorizationExecuteWithPrivileges(auth, path_to_self, kAuthorizationFlagDefaults, arguments, &commPipe))
				exit(kMyAuthorizedCommandInternalError);
			
			//REAL ARSE
			////Communication with sub-child which is running command
			
			fflush(commPipe);
			fclose(commPipe);
			
			exit(0);
		}
		
		
	}//Lets go
	if(path_to_self)
		free(path_to_self);
		
	////read command
	////check size
		
	AuthorizationItem right = { kAuthorizationRightExecute, 0, NULL, 0 } ;
	AuthorizationRights rights = { 1, &right };
	AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights;
		
	//Checking auth is ok
	if (status = AuthorizationCopyRights(auth, &rights, kAuthorizationEmptyEnvironment, flags, NULL))
	exit(-1);
		
		////go
		
	exit(0); //should never get here...
}
	
	
}