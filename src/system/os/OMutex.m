#include "osrt.h"
#include "OMutex.h"


@implementation OMutex

+ new
{
	return [[super new] init];
}

- init
{
	mutexInit(&mtx, NULL);
	return self;
}

- free
{
	mutexDestroy(&mtx);
	return [super free];
}

- (void) lock
{
	mutexLock(&mtx);
}

- (void) unLock
{
	mutexUnlock(&mtx);
}

- (void) tryLock
{
	mutexTrylock(&mtx);
}

@end
