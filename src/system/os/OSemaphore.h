#ifndef OSEMPAHORE_H
#define OSEMPAHORE_H

#define OSEMAPHORE id

#include <Object.h>
#include "osdef.h"

@interface OSemaphore : Object
{
	Sem_t mySem; /**Id del semaforo*/
	int	  myCount; /** contador inicial del semaforo */
}


/**
 *	Inicializa el semaforo con el valor inicial en aCount.
 */
- initWithCount: (int)aCount;

/**
 * 	Destruye el semaforo
 */

- free;

/**
 *
 */

- (void) wait;

/**
 *
 */

- (void) post;

/**
 *
 */
- (void) tryWait;

@end

#endif
