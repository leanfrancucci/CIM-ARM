#ifndef OS_SERVICES_H
#define OS_SERVICES_H

#define OS_SERVICES id

#include <Object.h>
#include "OThread.h"
#include "OTimer.h"
#include "OMutex.h"
#include "OSemaphore.h"

/**
 *	Permite crear objetos que dependen del sistem operativo (semaphoros, puerto com, timers).
 *	Existe una implementacion distinta para cada sistema operativo y todos los objetos que dependan
 *	del mismo deben ser creados a traves de esta clase.
 *
 */
@interface OSServices : Object
{
}


/**
 *	Metodo de clase. Devuelve un nuevo objeto OThread.
 */
+ (OTHREAD) getNewThread;

/**
 *	Metodo de clase. Devuelve un nuevo objeto CtTimer.
 */
+ (OTIMER) getNewTimer;

/**
 *	Metodo de clase. Devuelve un nuevo objeto OMutex.
 */
+ (OMUTEX) getNewMutex;

/**
 *	Metodo de clase. Devuelve un nuevo objeto OSemaphore
 */
+ (OSEMAPHORE) getNewSemaphore;

/**
 * Inicializa los timers, los sockets y demás.
 */
 + (void) OSInit;

/**
 * Libera los recursos tomados
 */
 + (void) OSCleanup;

@end

#endif
