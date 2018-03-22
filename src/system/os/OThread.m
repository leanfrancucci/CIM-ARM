#include "osrt.h"
#include "OThread.h"
#include "log.h"

ThreadEntryFunRetVal_t methodCall(void * obj)
{
    
	threadWaitReady([obj getThreadHandle]);
    printf("Thread1\n");
	[obj run];
	printf("Saliendo del thread\n");fflush(stdout);
	threadExit([obj getThreadHandle]);
    printf("Thread2\n");
	if ([obj getFreeOnExit]) [obj free];
    printf("Thread3\n");
	RETURN_FROM_THREAD();

}

@implementation OThread

/**/
- (Thread_t*) getThreadHandle
{
	return &thrd;	
}

/**/
- initialize
{
	freeOnExit = 1;
	return self;
}

/**/
- (void) run
{
}

/**/
- (int) getFreeOnExit
{
	return freeOnExit;
}

/**/
- (void) setFreeOnExit: (int) aValue
{
	freeOnExit = aValue;
}

/**/
- (void) start
{
	threadCreate(&thrd, NULL, methodCall, (void *)self, priority);
}

/**/
- (void) stop
{
	threadExit(&thrd);
}

/**/
- (void) sleep: (int) aSeconds
{
	threadSleep(aSeconds);
}

/**/
- (void) setPriority: (int) aPriority
{
	priority = aPriority;
}

/**/
- (int) getPriority
{
	return priority;
}

- (void) join
{
	threadJoin(&thrd);
}

- (void) waitFor: (OTHREAD) aThread
{
	threadJoin([aThread getThreadHandle]);
}

/*- (void) testCancel
{
	pthread_testcancel();
}
*/
@end
