#ifndef __OSRT_H
#define __OSRT_H

#include "osdef.h"
//#include <stdarg.h>

/**********************************************************************
 *	THREADS
 *********************************************************************/
int initializeMainThread(void);
int threadCreate(Thread_t *, const ThreadAttr_t *, ThreadEntryFun_t *, void *, int);
void threadExit(Thread_t *);
Thread_t *threadSelf();
int threadEqual(Thread_t *, Thread_t *);
void threadSleep(unsigned int secs);
void threadJoin(Thread_t *);
int geterrno(void); 
void seterrno(int eno);
void threadWaitReady(Thread_t *th);
int threadSetPriority(int priority);

/**********************************************************************
 *	MUTEX
 *********************************************************************/

int mutexInit(Mutex_t *mutex, const MutexAttr_t *attr);
int mutexDestroy(Mutex_t *mutex); 
int mutexLock(Mutex_t *mutex); 
int mutexTrylock(Mutex_t *mutex);
int mutexUnlock(Mutex_t *mutex);


/**********************************************************************
 *	SEMAPHORES
 *********************************************************************/
 
int semInit(Sem_t *sem, unsigned int value);
int semDestroy(Sem_t *sem);
int semPost(Sem_t *sem);
int semWait(Sem_t *sem);
int semTimedwait(Sem_t *sem, unsigned long msecs);
int semTrywait(Sem_t *sem);


/**********************************************************************
 *	EXCEPTION MANAGMENT
 *********************************************************************/
 
/** 
 *	Devuelve el jump buffer correspondiente al nivel de anidamiento de TRY
 *	y el thread actual.
 */
jmp_buf *ex_save_env(void);

/** 
 *	Remueve el jump buffer en el tope de la pila.
 */
void ex_remove_env(void);

/** 
 *	Setea un flag para indicar que se esta en un bloque except.
 */	
void ex_set_except_block(void);

/** 
 *	Setea un flag para indicar que se esta en un bloque finally.
 */	
void ex_set_finally_block(void);

/** 
 *	Devuelve TRUE si el codigo de la excepcion actual es igual al numero
 *	de excepcion pasada como parametro.
 */	
int ex_curr_code(int excode);


/**
 *	Arroja la excepcion pasada como parametro.
 *
 *	excode : codigo de la excepcion
 *	fatal : true si es una excepcion fatal, false en caso contrario.
 *  adcode : codigo adicional de la excepcion
 *
 */	
void ex_throw(int excode, int fatal, int adcode, char *file, int line, char *name);

/**
 *	Item anterior pero proporciona un parametro adicional para un mensaje
 */
void ex_throw_msg(int excode, int fatal, int adcode, char *file, int line, char *name, char *msg);
void ex_throw_fmt(int excode, int fatal, int adcode, char *file, int line, char *name, char *format, ...);

/**
 *	Arroja nuevamente la excepcion actual.
 */
void ex_rethrow(void);

/** 
 *	Realiza un rethrow pero unicamente si esta en un bloque finally
 */
void ex_do_rethrow(void);

/**
 *	Devuelve el numero de linea de la excepcion actual.
 */
int ex_get_line(void);

/**
 *	Devuelve el nombre del archivo de la excepcion actual.
 */
char *ex_get_file(void);

/**
 *	Devuelve el nombre de la excepcion actual.
 */
char *ex_get_name(void);

/**
 *	Devuelve el codigo de la excepcion actual.
 */
int ex_get_code(void);

/**
 *	Devuelve el codigo adicional de la excepcion.
 */
int ex_get_additional_code(void);

/**
 *	Devuelve el mensaje adicional de la excepcion.
 */
char *ex_get_msg(void);

/**
 * Imprime la excepcion por salida estandar.
 * Se imprimen todos los datos de la excepcion.
 */
void ex_printfmt(void);

void ex_printfmt_exception( Exception_t *ex );

/**
 *	Setea el manejador de excepciones por defecto, es decir la funcion de callback a llamar
 *	si ocurre una excepcion no capturada.
 *	Si no se setea esta funcion, por defecto imprime por salida standard el error y aborta la 
 *	aplicacion.
 */
void ex_set_default_handler( Exception_handler_t handler);

/**
 *	Llama al manejador de excepcion por defecto con la excepcion del hilo actual.
 */
void ex_call_default_handler(void);

/**********************************************************************
 *	VARIOS
 *********************************************************************/

/**
 *	Devuelve la cantidad de ticks del sistema
 */
unsigned long  getTicks(void);

/**
 *	Duerme la cantidad de segundos especificada en value.
 */
void	msleep(unsigned long value);

/**
 *	Devuelve la version del kernel del sistema operativo.
 */
char *getKernelVersion(void);

/**
 *	Crea el directorio pasado por parametro.
 */
int makeDir(char *path);

/**
 *  Escribe los datos al archivo pasado por parametro de forma segura,
 *  es decir, haciendo el correspondiente flush del archivo.
 */
int secureWriteDataToFile(char *aFileName, char *data, int size);

#endif
