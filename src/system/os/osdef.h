#ifndef __OSDEF_H
#define __OSDEF_H

/** Platform dependent includes */
#ifdef __LINUX
	#include "linux/osdep.h"
	#include "errno.h"
#endif

#ifdef __ARM_LINUX
	//#include "linux/osdep.h"
	#include "arm-linux/osdep.h"  //estaba funcionando sin esto.ver sole con alexiaa
	#include "errno.h"
#endif

#ifdef __UCLINUX
	#include "uclinux/osdep.h"
	#include "errno.h"	
#endif

#ifdef __WIN32
	#include "win32\osdep.h"
	#include "errno.h"
#endif

#include <setjmp.h>


/**
 *	THREADS
 */

#define	MAX_THREADS						55
#define	MIN_STACK_SIZE				512

/**
 *	EXCEPTIONS
 */
#define MAX_NESTED_TRIES			 20
#define NO_EXCEPTION				    0
#define EX_NAME_SIZE					100
#define EX_FILE_SIZE					100

#ifdef __UCLINUX
#define EX_MSG_SIZE						100
#endif
#ifdef __ARM_LINUX
#define EX_MSG_SIZE						100
#else
#define EX_MSG_SIZE						1000
#endif

typedef	Thread_OSPDep_t					ThreadId_t;
typedef ThreadEntryFunRetVal_OSPDep_t 	ThreadEntryFunRetVal_t;
typedef ThreadEntryFunRetVal_t(ThreadEntryFun_t)(void *);
typedef ThreadExitData_OSPDep			ThreadExitData_t;

#define THREAD_ENTRYFUNPARAM_NULLVAL 	THREAD_ENTRYFUNPARAM_NULLVAL_OSDEP
#define THREAD_EXITDATA_NULLVAL 		THREAD_EXITDATA_NULLVAL_OSDEP

typedef struct {
	jmp_buf		  jmpenvs[MAX_NESTED_TRIES];
	jmp_buf		 *jenv;
	int					excode;
	int					adcode;
	int					line;
	int 				inexception;
	char				file[EX_FILE_SIZE];
	char				name[EX_NAME_SIZE];
	char				msg[EX_MSG_SIZE];
	int					infinally;
} Exception_t;


typedef struct {
	ThreadId_t	threadid;
	int 				priority;
	Exception_t exception;
} Thread_t;

typedef struct {	
	void 			*stackaddr;
	unsigned long 	stacksize;
	int 			autostart;
} ThreadAttr_t;

/**
 *	Funcion de callback para llamar cuando ocurre una excepcion.
 */
typedef void(*Exception_handler_t)(char *name, char*file, int line, int excode, int adcode, char* admsg, char*msg);


/***
 * M U T E X
 **/			

typedef	Mutex_OSPDep_t					MutexId_t;

typedef struct {
	MutexId_t		mutexid;
} Mutex_t;


typedef struct {
	int		id;
} MutexAttr_t;


/***
 * S E M A P H O R E S
 **/			

#define 	MAX_SEMAPHORE_COUNT			MAX_SEMAPHORE_COUNT_OSDEP

typedef	Sem_OSPDep_t					SemId_t;

typedef struct {
	SemId_t		semid;
} Sem_t;


#endif

