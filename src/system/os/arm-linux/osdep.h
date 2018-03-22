#ifndef __OSPDEPS_H
#define __OSPDEPS_H

#include <pthread.h>
#include <semaphore.h>

/**
 *	HANDLE
 */
typedef int OS_HANDLE;

/***
 * Threads
 **/

typedef pthread_t 		Thread_OSPDep_t;
typedef void 					*ThreadEntryFunRetVal_OSPDep_t;
typedef void  				*ThreadExitData_OSPDep;

#define RETURN_FROM_THREAD() return NULL

#define THREAD_ENTRYFUNPARAM_NULLVAL_OSDEP				NULL
#define THREAD_EXITDATA_NULLVAL_OSDEP					NULL
#define	HANDLE				int

/***
 * M U T E X
 **/

 
typedef		pthread_mutex_t	Mutex_OSPDep_t;


/***
 * S E M A P H O R E S
 **/
 
#define MAX_SEMAPHORE_COUNT_OSDEP	0xFFF
#define	WAIT_FOREVER			0

typedef		sem_t			Sem_OSPDep_t;


#endif

