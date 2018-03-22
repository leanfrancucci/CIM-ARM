#ifndef STATIC_SYNC_QUEUE_H
#define STATIC_SYNC_QUEUE_H

#define STATIC_SYNC_QUEUE id

#include <Object.h>
#include "system/lang/all.h"
#include "system/os/all.h"
#include "queue.h"

/**
 *	Implementa una cola sincronizada mediante un semaforo.
 *	Cuando se agrega un elemento, si habia alguien esperando, lo despierta.
 *	Cuando quita un elemento, si no hay ninguno disponible, se queda bloqueado.
 *	
 */
@interface StaticSyncQueue : Object
{
	Queue *queue;
	OSEMAPHORE mySem;
	OMUTEX myMutex;
}

/**
 *	Inicializa la cola con el tamaño pasado como parametro
 *	y el la cantidad de elementos indicada.
 */
- initWithSize: (int) aDataSize count: (int) aMaxCount;

/**
 *	Agrega un elemento a la cola.
 *	Si hay alguien esperando, lo despierta para que continue su ejecucion.
 */
- (void*) pushElement: (void*) aBuffer;

/**
 *	Quita el elemento al final de la cola y lo devuelve.
 *	La llamada es bloqueante, es decir, si no existe un elemento disponible, se queda
 *	esperando hasta que haya uno.
 */
- (void*) popBuffer: (void*) aBuffer;

/**/
- (int) getCount;

@end

#endif
