#include "SyncQueue.h"
#include "ordcltn.h"

@implementation SyncQueue

+ new
{
	return [[super new] initialize];
}

- initialize
{
	mySem = [[OSemaphore new] initWithCount:0];
	myCollection = [OrdCltn new];
	myMutex = [OMutex new];
	return self;
}

- free
{
	[myCollection free];
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
	[myCollection add: aBuffer];
	[myMutex unLock]; // fin seccion critica
	[mySem post];  // despierto a alguien que esta esperando
	return aBuffer;
}

/**
 *	Quita el elemento al final de la cola y lo devuelve.
 */
- (void*) popElement
{
	void *aBuffer;
	
	[mySem wait];
	[myMutex lock];		//seccion critica
	aBuffer = [myCollection removeFirst];
	[myMutex unLock]; //fin de seccion critica
	return aBuffer;
}


/**/
- (void*) pushSizedElement: (void *) aBuffer size: (int) aSize
{
	[myMutex lock];	  // seccion critica
	
	[myCollection add: (void *)aSize]; // agrega el tamano de aBuffer
	[myCollection add: aBuffer]; 
	
	[myMutex unLock]; // fin seccion critica
	[mySem post];  // despierto a alguien que esta esperando
	return aBuffer;
}

/**/
- (int) popSizedElement: (void **) aBuffer
{
	int size;
	
	[mySem wait];
	[myMutex lock];		//seccion critica
		
	size = (int)[myCollection removeFirst]; // extrae el tamano del elemento siguiente
	*aBuffer = [myCollection removeFirst];
	
	[myMutex unLock]; //fin de seccion critica
	
	return size;
}

/**/
- (int) getCount
{
	return [myCollection size];
}

/**/
- (void*) getElement
{
	void *aBuffer;
	
	[mySem wait];
	[myMutex lock];		//seccion critica
	aBuffer = [myCollection at:0];
	[myMutex unLock]; //fin de seccion critica
	[mySem post];
	return aBuffer;
}

/**/
- (void*) getElementAt: (int) aPosition
{
	void *aBuffer;
	aBuffer = [myCollection at: aPosition];
	return aBuffer;
}

/**/
- removeAt: (unsigned) anOffset
{
	void *aBuffer = NULL;
	
	[myMutex lock];		//seccion critica
  TRY
    aBuffer = [myCollection removeAt: anOffset];
  FINALLY
    [myMutex unLock]; //fin de seccion critica
  END_TRY

  if (aBuffer != NULL) [mySem wait];
  return aBuffer;
}

@end
