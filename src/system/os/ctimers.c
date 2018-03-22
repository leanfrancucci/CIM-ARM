/*
 *	ctimer.c
 *		Customizable and portable timers
 *		Linux specific
 *
 */
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "excepts.h"
#include "osrt.h"
#include "ctimers.h"
#include "log.h"

/* En ctimers.c en common esta definida MInt. 
   Para evitar problemas con dependencias de archivos lo defino aca y ya esta. */
#define	MInt	int

#ifdef __UCLINUX
#define  MAX_CTIMERS		64
#else
#define  MAX_CTIMERS		96
#endif


/* 999.999.999 nanos = 1.000 msec = 1 sec */
#if CTIMER_MSECS_PERIOD > 999
	#error Definic�on de CTIMER_MSECS_PERIOD err�nea ( 0 <= CTIMER_MSECS_PERIOD < 1000)
#endif

#define CTIMER_ONESECOND		1000
#define CTIMER_PERIOD 			250

/* 1 si est� corriendo; 0 si nop est� corriendo */
static MInt running = 0;


/* La lista de timers */
static CTimer *timers[ MAX_CTIMERS ];

/* Cheque que el modulo este corriendo  */
#define CHECK_FOR_RUNNING() 	if (!running) return -ECTIMER_NOINIT;

/* El trhead que ejecuta handle_timers */
static Thread_t		ctimers_thread;

/* Las zonas cr�ticas de las funciones publicas */
static Mutex_t ctimers_mutex;
/* Devuelven distinto de cero si hubo error */

#define TAKE_MUTEX()			mutexLock( &ctimers_mutex )
#define RELEASE_MUTEX()		mutexUnlock( &ctimers_mutex )

/*#define TAKE_MUTEX()			
#define RELEASE_MUTEX()		
*/

/*
 *	Static functions
 *
 */

/*
 *	handle_ctimers
 *		recorre la lista de timers ejecutando los que hayan expirado
 */
static 
void
handle_ctimers(unsigned long tickcount)
{
	CTimer **t;	
  CTimer *timer;
  int periodic;

	for (t = timers; t < timers + MAX_CTIMERS; t++) {
		TAKE_MUTEX();
    timer = *t; 
        
		if (timer && tickcount >= timer->expires) {
           // printf("tickcount = %ld --- timer->expires = %ld timer period = %ld----- sizeof(tickcount) = %d ----  sizeof(timer-expires) = %d \n", tickcount, timer->expires, timer->period, sizeof(tickcount), sizeof(timer->expires));
      periodic = timer->periodic; 			
			RELEASE_MUTEX();
			timer->function(timer->data);

			if (timer->periodic) {
				timer->expires += timer->period;
			} 

			/** @todo: el siguiente codigo lo comente el 13/06/2007 porque me generaba que se disparara 
					inmediatamente un timer luego de que expirara y en la funcion de callback lo volvia a agregar
					(sobreescribia el valor expires en "0" cuando se volvia a agregar */
		/*else 
				timer->expires = 0;
      }*/

		} else
			RELEASE_MUTEX();
	}
}
 
 
/*
 *	get_slot
 *		Retorna el puntero al slot del timer pasado por paramtero
 */
static
CTimer **
get_slot(CTimer *timer, MInt *status)
{
	CTimer **t;
	
	*status = 0;
	for (t = timers; t < timers + MAX_CTIMERS; t++)
		if (*t == timer) return t;
	*status = -ECTIMER_INVALID;
	return NULL;
}

/*
 *	get_free_slot
 *		Retorna un puntero a un slot libre de la lista de timers
 */
static
CTimer **
get_free_slot(MInt *status)
{
	CTimer **t;
	
	*status = 0;
	for (t = timers; t < timers + MAX_CTIMERS; t++)
		if (*t == NULL) return t;
	*status = -ECTIMER_NOAVAIL;
	return NULL;
}

/*
 *	thread_handle
 *		La funcion que gestiona del hilo del m�dulo.
 *		Llama periodicamente a handle_timers()
 */ 
static
ThreadEntryFunRetVal_t
thread_handle( void *arg )
{
	threadWaitReady(&ctimers_thread);

	threadSetPriority(-10);

	TRY

		while ( 1 ) {
			
            // se va a dormir
			msleep(CTIMER_PERIOD);
					
            // recorre los timers y los ejecuta
			handle_ctimers(getTicks());
					
			if ( !running )
				break;				
		}	

	CATCH

	//	doLog(0,"Ha ocurrido una excepcion en el hilo que maneja los timers\n");
		ex_printfmt();
		
	END_TRY

	RETURN_FROM_THREAD();
}

 
 
/*
 * Public definitions
 *
 */

 
/*
 * init_ctimers
 *
 */
MInt
init_ctimers(void)
{
	running = 1;
	threadCreate( &ctimers_thread, NULL, thread_handle, NULL, 5 );
	if (mutexInit( &ctimers_mutex, NULL )) {
		running = 0;
		return -1;
	}	
	return 1;
}

/*
 * uninit_ctimers
 *
 */
MInt
cleanup_ctimers(void)
{	
	running = 0;	
	mutexDestroy( &ctimers_mutex );
	return 1;
}


/*
 *	init_ctimer
 *	
 */
MInt
init_ctimer(CTimer *timer)
{
	CHECK_FOR_RUNNING();	
	
	timer->expires = 0;
#ifdef USEC_CTIMERS	
	timer->usec_expires = 0;
#endif

	return 1;
}

/*
 *	del_ctimer
 */
MInt
del_ctimer(CTimer *timer)
{
	CTimer **te;
	MInt status;
	
	CHECK_FOR_RUNNING();	
		
	TAKE_MUTEX();
	if ((te = get_slot(timer, &status)) == NULL) {
		RELEASE_MUTEX();
		return status;
	}
	
	*te = NULL;
	RELEASE_MUTEX();
	
	return 1;
}

/*
 *	ctimer_start
 *
 */
MInt
add_ctimer(CTimer *timer)
{
	CTimer **te;
	MInt status;

	CHECK_FOR_RUNNING();
	
	TAKE_MUTEX();	
	if ((te = get_free_slot( &status )) == NULL) {
		RELEASE_MUTEX();
		return status;		
	}	
	*te = timer;
//	(*te)->expires += getTicks();
	RELEASE_MUTEX();
	return 1;
}

/*
 *	mod_timer
 *
 */
MInt
mod_ctimer(CTimer *timer, CTimerExpiresType msec_expires, CTimerExpiresType usec_expires)
{
	CTimer **te;
	MInt status;

#ifndef USEC_CTIMERS
	usec_expires = usec_expires;
#endif	

	CHECK_FOR_RUNNING();

	TAKE_MUTEX();
	if ((te = get_slot(timer, &status)) == NULL)
		return status;	
	
	(*te)->expires = msec_expires + getTicks();	

#ifdef USEC_CTIMERS	
	(*te)->usec_expires = usec_expires;
#endif
	RELEASE_MUTEX();
	
	return 1;
}

