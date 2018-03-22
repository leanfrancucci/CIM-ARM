#ifndef SYNC_QUEUE_H
#define SYNC_QUEUE_H

#define SYNC_QUEUE id

#include <Object.h>
#include "system/lang/all.h"
#include "system/os/all.h"

/**
 *	Implementa una cola sincronizada mediante un semaforo.
 *	Cuando se agrega un elemento, si habia alguien esperando, lo despierta.
 *	Cuando quita un elemento, si no hay ninguno disponible, se queda bloqueado.
 *	
 */
@interface SyncQueue : Object
{
	COLLECTION myCollection;
	OSEMAPHORE mySem;
	OMUTEX myMutex;
}

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
- (void*) popElement;

/**
 *	Agrega un elemento dimensionado a la cola.
 *  Ofrece la posibilidad de agregar un puntero a caracteres a la cola y sacarlo
 *  conociendo la cantidad de caracteres de la cadena.
 */
- (void*) pushSizedElement: (void *) aBuffer size: (int) aSize;

/**
 *	Quita el elemento al final de la cola y lo devuelve obteniendo
 *  previamente el tamano del elemento.
 *  @aBuffer (char **) devuelve el elemento extraido en *aBuffer. 
 *  @result retorna el tamano del elemento extraido.
 */
- (int) popSizedElement: (void **) aBuffer;

/**
 *	Devuelve el elemento al final de la cola, pero no lo quita.
 *	La llamada es bloqueante, es decir, si no existe un elemento disponible, se queda
 *	esperando hasta que haya uno.
 */
- (void*) getElement;

/**
 *	Devuelve la cantidad de elementos actualmente en la cola.
 */
- (int) getCount;

/**
 *	Devuelve el elemento en la posicion aPosition.
 *	No deberia utilizarse normalmente ya que debe respetarse la semantica de una cola,
 *	pero en algunos casos puede ser util.
 */
- (void*) getElementAt: (int) aPosition;

/**
 *  Remueve el objeto pasado como parametro.
 */
- removeAt: (unsigned) anOffset;

@end

#endif
