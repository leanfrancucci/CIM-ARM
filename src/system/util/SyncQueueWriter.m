#include <assert.h>
#include "SyncQueueWriter.h"

@implementation SyncQueueWriter

/**/
+ new
{
	return [[super new] initialize];	
}

/**/
- initialize
{	
	return self;
}

/**/
- free
{	
	return [super free];
}

/**/
- initWithSyncQueue: (SYNC_QUEUE) aQueue
{
	myQueue = aQueue;
	return self;
}

/**/
- (void) setSyncQueue: (SYNC_QUEUE) aQueue
{
	myQueue = aQueue;
}

/**/
- (int) write: (char *) aBuf qty: (int) aQty
{	
	assert(myQueue);
	
	/* previo al dato agrega en la cola la cantidad de datos del elemento siguiente */	
	[myQueue pushSizedElement: (void *)aBuf size: (int)aQty];
	
	return aQty;
}


@end

