#ifndef REMOTE_CONSOLE_H
#define REMOTE_CONSOLE_H

#define REMOTE_CONSOLE id

#include <objpak.h>
#include "ctapp.h"
#include "OMutex.h"



/**
 *	
 */
@interface RemoteConsole: Object
{
	id myTelesupDaemon;
	int myPort;
	id myClientSocket;
	id myEventsClientSocket;
	BOOL myHasStarted;
	id myParser;
	OMUTEX myMutex;
}


/**/
- (void) setPort: (int) aPort;
- (int) getPort;

/**/
- (void) setTelesupDaemon: (id) aTelesupDaemon;
- (id) getTelesupDaemon;

/**/
- (void) setClientSocket: (id) aClientSocket;
- (void) setEventsClientSocket: (id) aClientSocket;

/**/
- (void) setParser: (id) aParser;
- (id) getParser;

/**/
- (id) getOpRequest;

/**/
- (BOOL) startRemoteConsole;
- (BOOL) hasStarted;

@end

#endif
