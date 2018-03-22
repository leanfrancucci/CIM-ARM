#ifndef __OSPDEPS_H
#define __OSPDEPS_H


#include <pthread.h>

typedef struct {
	void *handle;
	long  threadId;
} Thread_OSPDep_t;

/**
 *	HANDLE
 */
typedef void* OS_HANDLE;

//typedef pthread_t 		Thread_OSPDep_t;
typedef unsigned long ThreadEntryFunRetVal_OSPDep_t;
typedef void  				*ThreadExitData_OSPDep;

#define RETURN_FROM_THREAD() return 0
#define THREAD_ENTRYFUNPARAM_NULLVAL_OSDEP				NULL
#define THREAD_EXITDATA_NULLVAL_OSDEP					NULL

/***
 * M U T E X
 **/
 
typedef		pthread_mutex_t	Mutex_OSPDep_t;


/***
 * S E M A P H O R E S
 **/
#define MAX_SEMAPHORE_COUNT_OSDEP	0xFFF 
#define	WAIT_FOREVER		INFINITE
typedef	void*					Sem_OSPDep_t;


#endif


