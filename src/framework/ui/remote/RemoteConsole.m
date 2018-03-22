#include "RemoteConsole.h"
#include "cl_genericpkg.h"

#include "TelesupDefs.h"

//#define printd(args...) printf(args)
#define printd(args...)

@implementation RemoteConsole

static REMOTE_CONSOLE singleInstance = NULL ;

// Avoid warning
- (id) getEventsProxy { return NULL; }


/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}
 
 /**/
+ getInstance
{
  return [self new];
}

/**/
- initialize
{
	myClientSocket = NULL;
	myEventsClientSocket = NULL;
	myParser = NULL;	
	myPort = 0;
	myHasStarted = FALSE;
	myMutex = [OMutex new];
	return self;
}

/**/
- free
{

		// Feo esto
	/*	if ([myParser getEventsProxy] != NULL) {
			[[myParser getEventsProxy] free];
		}

		if (myClientSocket) [myClientSocket free];
		if (myEventsClientSocket) [myEventsClientSocket free];
		if (myTelesupDaemon) [myTelesupDaemon free];*/
	return [super free];
}


/**/
- (void) setPort: (int) aPort { myPort = aPort; }
- (int) getPort { return myPort; }

/**/
- (void) setTelesupDaemon: (id) aTelesupDaemon { doLog(0, "e\n"); myTelesupDaemon = aTelesupDaemon; doLog(0, "i\n");}
- (id) getTelesupDaemon { return myTelesupDaemon; }

/**/
- (void) setClientSocket: (id) aClientSocket { myClientSocket = aClientSocket; }
- (void) setEventsClientSocket: (id) aClientSocket { myEventsClientSocket = aClientSocket; }

/**/
- (void) setParser: (id) aParser
{
	myParser = aParser;
}

/**/
- (id) getParser
{
	return myParser;
}

/**/
- (id) getOpRequest
{
	return [myParser getOpRequest];
}

/**/
- (void) stop
{
 // if (myClientSocket) [myClientSocket close];
 // if (myEventsClientSocket) [myEventsClientSocket close];
}

/**/
- (BOOL) startRemoteConsole
{
    int errorCode;

    printf("Comienza el telesupD\n");
    [myTelesupDaemon setFreeOnExit: 0];
    [myTelesupDaemon start];
    printf("antes de waitFor\n");
    [myTelesupDaemon waitFor: myTelesupDaemon];
    printf("Fin telesupD\n");
    
    errorCode = [myTelesupDaemon getErrorCode];
        
    if (errorCode != 0) THROW(TSUP_GENERAL_EX);
    
}

/**/
- (BOOL) hasStarted
{
	return myHasStarted;
}


@end
