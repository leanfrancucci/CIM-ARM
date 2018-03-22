#include <assert.h>
#include "SyncQueueReader.h"


@implementation SyncQueueReader

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
- (int) read: (char *)aBuf qty: (int) aQty
{
	void *p;
	int  size;

	/**
	 * tengo que controlar de no de devolver mas de aQty bytes.
	 */	 
	assert(myQueue);	
	size =  (int)[myQueue popSizedElement: (void **)&p];	
	memcpy(aBuf, p, size);
	
	return size;
}


@end

