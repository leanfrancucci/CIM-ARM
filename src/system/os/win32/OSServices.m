#include "OSServices.h"
#include "system/net/all.h"

@implementation OSServices

+ (OTHREAD) getNewThread
{
	return [OThread new];
}

+ (OSEMAPHORE) getNewSemaphore
{
	return [OSemaphore new];
}

+ (OMUTEX) getNewMutex
{
	return [OMutex new];
}

+ (OTIMER) getNewTimer
{
	return [OTimer new];
}

/**/
 + (void) OSInit
 {
	extern int initSockets_OSPDep(void);

	/* los timers*/
	[OTimer initTimers];

	/* sockets */
 	if (initSockets_OSPDep() == -1)
		THROW( SOCKET_INIT_EX );
 }

/**/
 + (void) OSCleanup
 {
	extern int cleanupSockets_OSPDep(void);

	/* timers */
	[OTimer cleanupTimers];

	/* sockets */
 	if (cleanupSockets_OSPDep() == -1)
		THROW( SOCKET_INIT_EX );
 }

@end
