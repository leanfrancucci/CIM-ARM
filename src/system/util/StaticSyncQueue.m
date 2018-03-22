#include "StaticSyncQueue.h"

@implementation StaticSyncQueue

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	mySem = [[OSemaphore new] initWithCount:0];
	myMutex = [OMutex new];
	queue = NULL;
	return self;
}

/**/
- initWithSize: (int) aDataSize count: (int) aMaxCount
{
	queue = qNew(aDataSize, aMaxCount);
	return self;
}

/**/
- free
{
	if (queue) qFree(&queue);
	[mySem free];
	[myMutex free];
	return [super free];
}

/**
 *	Agrega un elemento a la cola, si hay alguien esperando, lo despierta para que continue
 *	su ejecucion.
 */
- (void*) pushElement: (void*) aBuffer
{
	[myMutex lock];	  // seccion critica
	qAdd(queue, aBuffer);
	[myMutex unLock]; // fin seccion critica
	[mySem post];  // despierto a alguien que esta esperando
	return aBuffer;
}

/**
 *	Quita el elemento al final de la cola y lo devuelve.
 */
- (void*) popBuffer: (void*) aBuffer
{
	[mySem wait];
	[myMutex lock];		//seccion critica
	qRemove(queue, aBuffer);
	[myMutex unLock]; //fin de seccion critica
	return aBuffer;
}

/**/
- (int) getCount
{
	return queue->count;
}


@end
