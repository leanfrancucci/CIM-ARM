#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <stdarg.h>
#include "osrt.h"
#include "log.h"

/******************************************************************************************
 * M A C R O S
 ******************************************************************************************/

#ifdef WIN32
#define	SET_THREAD_ID(p,i)	(p)->threadid.threadId = i;
#else
#define	SET_THREAD_ID(p,i)	(p)->threadid = i;
#endif

/******************************************************************************************
 * S T A T I C
 ******************************************************************************************/

static Thread_t main_thread;
static Thread_t *threads[MAX_THREADS] = {&main_thread};
static Exception_handler_t default_exception_handler = NULL;
static void threadRegister(Thread_t *thread);
static void threadUnRegister(Thread_t *thread);

/******************************************************************************************
 * F O R W A R D
 ******************************************************************************************/

void ex_handle_default(Exception_t *ex);

/******************************************************************************************
 * T H R E A D S
 ******************************************************************************************/

extern int threadCreate_OSPDep(ThreadId_t *, const ThreadAttr_t *, ThreadEntryFun_t *, void *, int);
extern void threadExit_OSPDep(ThreadId_t);
extern ThreadId_t threadSelf_OSPDep(void);
extern int threadEqual_OSPDep(ThreadId_t, ThreadId_t);
extern void threadSleep_OSPDep(unsigned int secs);
extern void threadJoin_OSDep(ThreadId_t *);
extern void threads_OSPDep(void);
extern int geterrno_OSPDep(void);
extern int seterrno_OSPDep(int eno);
extern int threadSetPriority_OSDep(int priority);

/******************************************************************************************/

int initializeMainThread(void) {
//	doLog(0,"Initialize main thread\n");
	main_thread.exception.jenv = (void*)0;
	return 1;
}

/**/
int threadCreate(Thread_t *th, const ThreadAttr_t *attr, ThreadEntryFun_t *ef, void *param, int prior)
{	
	int ret;
	th->exception.jenv = (void*)0;
	threadRegister(th);	
	
	SET_THREAD_ID(th,-1);

	ret = threadCreate_OSPDep(&th->threadid, attr, ef, param, prior);
	th->exception.inexception = 0;
	th->exception.infinally = 0;
	th->exception.excode = NO_EXCEPTION;
	assert(ret == 0);
	return ret;
}

/**
 * Invoca a la funcion correspondiente segun la plataforma para terminar la ejecucion
 * del thread.
 **/
void threadExit(Thread_t * th)
{
	threadUnRegister(th);
	threadExit_OSPDep(th->threadid);
}

/*
 *	Espera hasta que el thread tenga un id para continuar.
 *	El problema es que la implementacion de pthread, cuando se crea un thread,
 *	se ejecuta el run, pero no se le asigna un id al thread en ese momento.
 *	Si ocurre una excepcion, no tengo un id de thread al cual comparar para
 *	obtener el jump buffer correspondiente.
 */
void threadWaitReady(Thread_t *th)
{
#ifdef WIN32
//	while ( ( id.threadId = threadSelf_OSPDep().threadId ) == -1 ) msleep(1);
//	SET_THREAD_ID(th, id.threadId);
#else
	ThreadId_t id;
	while ( ( id = threadSelf_OSPDep() ) == (Thread_OSPDep_t)-1 ) msleep(1);
	SET_THREAD_ID(th, id);
#endif


}

/**/
Thread_t *threadSelf(void)
{
	Thread_t **p;
	Thread_t *t;
	ThreadId_t id = threadSelf_OSPDep();

	for (p = threads + 1; p < threads + MAX_THREADS; ++p) {
		t = *p;
		if (t && threadEqual_OSPDep(id, t->threadid)) {
			return t;
		}
	}

	return threads[0];
}

/**/
int threadEqual(Thread_t *thread1, Thread_t *thread2)
{
	return threadEqual_OSPDep(thread1->threadid, thread2->threadid);
}

/**/
void threadSleep(unsigned int secs)
{
	threadSleep_OSPDep(secs);
}

/**/
void threadJoin(Thread_t *th)
{
	threadJoin_OSDep(&(th->threadid));
}

/**/
int geterrno()
{
	return geterrno_OSPDep();
}

/**/
void seterrno(int eno)
{
	seterrno_OSPDep(eno);
}

/**/
static void threadRegister(Thread_t *thread)
{
	int i;
	
	for (i = 1; i < MAX_THREADS; ++i) {
		if (threads[i] == NULL) {
			threads[i] = thread;
			thread->exception.jenv = (void*)0;
			return;
		}
	}
		
	printf("Se supero el limite maximo permitido de threads (%d) especificado por la constante MAX_THREADS\n", MAX_THREADS);
	abort();
	
}

/**/
static void threadUnRegister(Thread_t *thread)
{
	int i;
	

	for (i = 0; i < MAX_THREADS; ++i) {
		if (threads[i] == thread) {
			threads[i]->exception.jenv = (void*)0;
			threads[i]->exception.inexception = 0;
			threads[i]->exception.infinally = 0;
			threads[i]->exception.excode = NO_EXCEPTION;
			threads[i] = NULL;
			return;
		}
	}
	
}

/**/
int threadSetPriority(int priority)
{
	return threadSetPriority_OSDep(priority);
}

/******************************************************************************************
 * M U T E X
 ******************************************************************************************/
 
extern int mutexInit_OSPDep(MutexId_t *mutex, const MutexAttr_t *attr);
extern int mutexDestroy_OSPDep(MutexId_t *mutex); 
extern int mutexLock_OSPDep(MutexId_t *mutex); 
extern int mutexTrylock_OSPDep(MutexId_t *mutex);
extern int mutexUnlock_OSPDep(MutexId_t *mutex);

/**********************************************************************************/


/**/
int mutexInit(Mutex_t *mutex, const MutexAttr_t *attr)
{
	return mutexInit_OSPDep(&mutex->mutexid, NULL);
}

/**/
int mutexDestroy(Mutex_t *mutex)
{
	return mutexDestroy_OSPDep(&mutex->mutexid);
}

/**/
int mutexLock(Mutex_t *mutex)
{
	return mutexLock_OSPDep(&mutex->mutexid);
}

/**/
int mutexTrylock(Mutex_t *mutex)
{
	return mutexTrylock_OSPDep(&mutex->mutexid);
}

/**/
int mutexUnlock(Mutex_t *mutex)
{
	return mutexUnlock_OSPDep(&mutex->mutexid);
}


/*************************************************************************************
 *	E X C E P T I O N     M A N A G M E N T
 *************************************************************************************/

/**/
jmp_buf *ex_save_env(void)
{

	Thread_t *thread;

	thread = threadSelf();

	if (!thread->exception.jenv) {
    
		thread->exception.jenv = &thread->exception.jmpenvs[0];

	} else {

		if (thread->exception.jenv - thread->exception.jmpenvs >= MAX_NESTED_TRIES-1) {
            printf("NESTED = %ld\n", thread->exception.jenv - thread->exception.jmpenvs);
			printf("Can not define more than %d Try blocks!!!!\n", MAX_NESTED_TRIES);
			abort();
		}

		thread->exception.jenv++;
	}
  
	return thread->exception.jenv;
}

	
/**/
void ex_remove_env(void)
{
	Thread_t *thread = threadSelf();
	if (thread->exception.jenv > &thread->exception.jmpenvs[0]) 
		thread->exception.jenv--;	else thread->exception.jenv = NULL;
}

/**/
void ex_set_except_block(void)
{
	Thread_t *thread = threadSelf();	   	
	thread->exception.infinally = 0;
	thread->exception.inexception = 0;
}

/**/
void ex_set_finally_block(void)
{
	Thread_t *thread = threadSelf();	   	
	thread->exception.infinally = 1;
}

/**/
int ex_curr_code(int excode)
{
	Thread_t *thread = threadSelf();	   	
	return (thread->exception.excode == excode);
}

/**/
void ex_throw(int excode, int fatal, int adcode, char *file, int line, char *name)
{
	ex_throw_msg(excode, fatal, adcode, file, line, name, "");
}

/**/
void ex_throw_fmt(int excode, int fatal, int adcode, char *file, int line, char *name, char *format, ...)
{
	Thread_t *thread;
	jmp_buf *buf;
	va_list ap;

	thread = threadSelf();

	va_start(ap, format);
	vsnprintf(thread->exception.msg, EX_MSG_SIZE-1, format, ap);
	va_end(ap);

	strncpy(thread->exception.file, file, EX_FILE_SIZE-1);
	strncpy(thread->exception.name, name, EX_NAME_SIZE-1);	
	thread->exception.excode = excode;
	thread->exception.adcode = adcode;
	thread->exception.line = line;
	thread->exception.inexception = 1;
	
	if (!thread->exception.jenv) {
	//	doLog(0,"Ha ocurrido una excepcion y no hay un bloque TRY/CATCH definido\n");
		ex_handle_default(&(thread->exception));
	}	
	buf = thread->exception.jenv;

	if (thread->exception.jenv == &thread->exception.jmpenvs[0]) {
		thread->exception.jenv = NULL;
	} else {
		thread->exception.jenv--;
	}

	longjmp(*buf, thread->exception.excode);

}

/**/
void ex_throw_msg(int excode, int fatal, int adcode, char *file, int line, char *name, char *msg)
{
	Thread_t *thread;
	jmp_buf *buf;

	thread = threadSelf();

	strncpy(thread->exception.msg, msg, EX_MSG_SIZE-1);	
	strncpy(thread->exception.file, file, EX_FILE_SIZE-1);
	strncpy(thread->exception.name, name, EX_NAME_SIZE-1);	
	thread->exception.excode = excode;
	thread->exception.adcode = adcode;
	thread->exception.line = line;
	thread->exception.inexception = 1;
	
	if (!thread->exception.jenv) {
	    printf("Ha ocurrido una excepcion y no hay un bloque TRY/CATCH definido\n");
		abort();
		ex_handle_default(&(thread->exception));
	}	
	buf = thread->exception.jenv;

	if (thread->exception.jenv == &thread->exception.jmpenvs[0]) {
		thread->exception.jenv = NULL;
	} else {
		thread->exception.jenv--;
	}

	longjmp(*buf, thread->exception.excode);

}

/**/
void ex_rethrow(void)
{
	Thread_t *thread = threadSelf();
	jmp_buf *buf;

	thread->exception.inexception = 1;

	if (!thread->exception.jenv) {
		printf("Ha ocurrido una excepcion y no hay un bloque TRY/CATCH definido\n");
		ex_handle_default(&(thread->exception));
	}	
	buf = thread->exception.jenv;
	if (thread->exception.jenv == &thread->exception.jmpenvs[0]) 
		thread->exception.jenv = NULL; else thread->exception.jenv--;
	longjmp(*buf, thread->exception.excode);
	
}

/**/
void ex_do_rethrow(void)
{
	char name[EX_NAME_SIZE];
	char file[EX_FILE_SIZE];
	char msg[EX_MSG_SIZE];

	Thread_t *thread = threadSelf();
	
    
	if ( thread->exception.inexception &&
			 thread->exception.infinally) {
		
		strncpy(name, thread->exception.name, EX_NAME_SIZE-1);	
		strncpy(msg, thread->exception.msg, EX_MSG_SIZE-1);	
		strncpy(file, thread->exception.file, EX_FILE_SIZE-1);
		
		ex_throw_msg(thread->exception.excode, 0, thread->exception.adcode, file, thread->exception.line, name, msg);

	}
		
}

/**/
int ex_get_line(void)
{
	Thread_t *thread = threadSelf();
	return thread->exception.line;
}

/**/
char *ex_get_file(void)
{
	Thread_t *thread = threadSelf();
	return thread->exception.file;
}

/**/
char *ex_get_name(void)
{
	Thread_t *thread = threadSelf();
	return thread->exception.name;
}

/**/
int ex_get_code(void)
{
	Thread_t *thread = threadSelf();
	return thread->exception.excode;
}

/**/
int ex_get_additional_code(void)
{
	Thread_t *thread = threadSelf();
	return thread->exception.adcode;
}

/**/
char *ex_get_msg(void)
{
	Thread_t *thread = threadSelf();
	return thread->exception.msg;
}

/**/
void ex_set_default_handler( Exception_handler_t handler)
{
	default_exception_handler = handler;
}

/**/
void ex_handle_default(Exception_t *ex)
{
	if (!default_exception_handler) {
		ex_printfmt_exception(ex);
		//doLog(0,"La aplicaci�n sera cerrada abruptamente debido a la excepcion no capturada!!!!!!!!!!!!");
		exit(1);
	} else {
		default_exception_handler(ex->name, ex->file, ex->line, ex->excode, ex->adcode, ex->adcode > 0 ? strerror(ex->adcode): "", ex->msg );
	}
}

/**/
void ex_printfmt_exception( Exception_t *ex )
{
	printf("Exception \'%s\', at %s, line %d, code %d [internal code: %d - %s], msg: %s\n",
			 ex->name, 
			 ex->file, 
			 ex->line,
			 ex->excode, 
			 ex->adcode, 
			 ex->adcode > 0 ? strerror(ex->adcode): "",
	 		 ex->msg );
}

/**/
void ex_call_default_handler(void)
{
	Thread_t *thread = threadSelf();  
	ex_handle_default(&(thread->exception));
}

/**/
void ex_printfmt(void)
{
	Thread_t *thread = threadSelf();  
	ex_printfmt_exception(&(thread->exception));
	fflush(stdout);
}



/**********************************************************************************
 * S E M A P H O R E S
 **********************************************************************************/

extern int semInit_OSPDep(SemId_t *sem, unsigned int value);
extern int semDestroy_OSPDep(SemId_t *sem);
extern int semPost_OSPDep(SemId_t *sem);
extern int semWait_OSPDep(SemId_t *sem);
extern int semTimedwait_OSPDep(SemId_t *sem, unsigned long msecs);
extern int semTrywait_OSPDep(SemId_t *sem);
extern char *getKernelVersion_OSDep(void);
extern int makeDir_OSDep(char *path);

/**********************************************************************************/

/**/
int semInit(Sem_t *sem, unsigned int value)
{
	return semInit_OSPDep(&sem->semid, value);
}

/**/
int semDestroy(Sem_t *sem)
{
	return semDestroy_OSPDep(&sem->semid);
}

/**/
int semPost(Sem_t *sem)
{
	return semPost_OSPDep(&sem->semid);
}

/**/
int semWait(Sem_t *sem)
{
	return semWait_OSPDep(&sem->semid);
}

/**/
int semTimedwait(Sem_t *sem, unsigned long msecs)
{
	return semTimedwait_OSPDep(&sem->semid, msecs);
}

/**/
int semTrywait(Sem_t *sem)
{
	return semTrywait_OSPDep(&sem->semid);
}

/**/
char *getKernelVersion(void)
{
	return getKernelVersion_OSDep();
}

/**/
int makeDir(char *path)
{
	return makeDir_OSDep(path);	
}
