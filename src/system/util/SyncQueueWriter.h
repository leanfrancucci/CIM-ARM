#ifndef SYNCQUEUEWRITER_H
#define SYNCQUEUEWRITER_H

#define SYNC_QUEUE_WRITER id

#include <Object.h>
#include "system/io/all.h"
#include "SyncQueue.h"

/**
 * Un Writer para escribir datos en una cola sincronizada.
 * El write()  queda bloqueado hasta quehaya espacio para escribir.
 * Se utiliza como productor  de un QueueReader consumidor.
 */
@interface SyncQueueWriter : Writer
{
	SYNC_QUEUE		myQueue;
}

/**
 * Inicializa el writer con la cola sincronicada
 */
- initWithSyncQueue: (SYNC_QUEUE) aQueue;


/**
 * Configura la cola que usara el reader
 */
- (void) setSyncQueue: (SYNC_QUEUE) aQueue;


/**
 */
- (int) write: (char *) aBuf qty:(int) aQty;


@end

#endif
