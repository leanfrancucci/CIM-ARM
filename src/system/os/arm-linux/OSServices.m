#include "OSServices.h"

@implementation OSServices

+ (OTHREAD) getNewThread
{
	return [OThread new];
}

+ (OMUTEX) getNewMutex
{
	return [OMutex new];
}

+ (OTIMER) getNewTimer
{
	return [OTimer new];
}

+ (OSEMAPHORE) getNewSemaphore
{
	return [OSemaphore new];
}

/**/
+ (void) OSInit
{
	/* los timers*/
	[OTimer initTimers];
};

/**/
+ (void) OSCleanup
{
	/* timers */
	[OTimer cleanupTimers];
};


@end
