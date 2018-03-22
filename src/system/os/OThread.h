#ifndef OTHREAD_H
#define OTHREAD_H

#define OTHREAD id

#include <Object.h>
#include "osrt.h"
  
typedef enum {
	THR_NEW,
	THR_READY,
	THR_RUNNING,
	THR_BLOCKED,
	THR_ZOMBIE
} ThreadState;

@interface OThread : Object
{
	Thread_t thrd; /**Id del thread*/
	int priority; /**Prioridad a setear en la creacion del thread*/
	ThreadState state;
	int freeOnExit;
}


- (Thread_t*) getThreadHandle;

/**/
- (int) getFreeOnExit;
- (void) setFreeOnExit: (int) aValue;

/**
Metodo que llama la funcion de callback.
*/

- (void) run;

/**
Metodo que hace comenzar al thread.
*/

- (void) start;

/**
Termina la ejecucion de un thread. 
*/

- (void) stop;

/**
Duerme el thread la cantidad de segundos enviada como parametro.
*/

- (void) sleep: (int) aSeconds;

/**
Setea la prioridad del thread.
*/

- (void) setPriority: (int) aPriority;

/**
Retorna la prioridad del thread.
*/

- (int) getPriority;

/**
Realiza un join.
*/

- (void) join;

/**
 *	Espera a que finalize el thread.
 */
- (void) waitFor: (OTHREAD) aThread;

@end

#endif
