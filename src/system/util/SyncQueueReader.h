#ifndef SYNCQUEUEREADER_H
#define SYNCQUEUEREADER_H

#define SYNC_QUEUE_READER id

#include <Object.h>
#include "system/io/all.h"
#include "SyncQueue.h"

/**
 * Un Reader para leer datos de una cola sincronizada.
 * El read()  queda bloqueado hasta que se agregue un dato a la cola.
 * Se utiliza como consumidor de un QueueWriter productor.
 */
@interface SyncQueueReader : Reader
{
	SYNC_QUEUE		myQueue;
}

/**
 * Inicializa el reader con la cola sincronicada
 */
- initWithSyncQueue: (SYNC_QUEUE) aQueue;
 
/**
 * Configura la cola que usara el reader
 */
- (void) setSyncQueue: (SYNC_QUEUE) aQueue;

/**
 */
- (int) read: (char *)aBuf qty:(int) aQty;


@end

#endif
