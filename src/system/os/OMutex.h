#ifndef OMUTEX_H
#define OMUTEX_H

#define OMUTEX id

#include <Object.h>
#include "osdef.h"

@interface OMutex : Object
{
	Mutex_t mtx; /**Id del mutex*/
}

/**
Realiza el new del mutex e invoca al init del mismo.
*/

+ new;

/**
Metodo que inicializa el mutex.
*/

- init;

/**
Destruye el mutex. 
*/

- free;

/**
*
*/

- (void) lock;

/**
*
*/

- (void) unLock;

/**
*
*/

- (void) tryLock;

@end

#endif
