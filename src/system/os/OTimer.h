#ifndef OTIMER_H
#define OTIMER_H

#define OTIMER id

#include <objpak.h>
#include "ctimers.h"

#define ONE_SHOT 1
#define PERIODIC -1

/**
 * Timer. Clase que representa a los timers. Tiene funcionalidad
 * para decir la función de callback al momento de ocurrencia de un
 * evento programado. Basicamente consta de un Thread que se "duerme"
 * por periodos de tiempo dados como parametro y que al despertarse
 * llaman a la función dada.
 */
@interface OTimer:Object
{
	CTimer		myTimer;
	int			myIsActive;
	id 			myObject;
	char		*myCallback;
	long 		myPeriod;	/** en milisegundos */	 	
	long		myOriginalPeriod;
	int 		myCycle;	/** 	ONE_SHOT o PERIODIC */
	id 			myArg;
	long		myInitialTicks;
	int			myExecutedTimes;
	SEL 		mySel;
}


/**
 *	initTimers
 *		Inicializa el modulo ctimers.c
 *		Debe ser invocado siempre entes de utilizar los timers
 */
+ (void) initTimers;

/**
 *	cleanupCtTimers
 *		limpia el modulo ctimers.c
 *
 */
+ (void) cleanupTimers;
 
/**
 * Constructor de la clase.
 */
+ new ;

/**
 * Método usado para definir la parametrización del timer.
 * @param cycle Número de veces que se pretende que el timer envie señales (puede ser una, varias o continuamente).
 * @param period Periodo de tiempo entre llamada y llamada (en mseg).
 * @param object Objeto del cual se llamará el metodo de callback.
 * @param callback Cadena que identifica el nombre del método de callback.
 */
- (void) initTimer:(int) aCycle period:(long) aPeriod 
						object:(id) anObject callback:(char*) aCallback ;

/**
 * Método usado para definir la parametrización del timer (para funciones de callback con un parametro).
 * @param cycle Número de veces que se pretende que el timer envie señales (puede ser una, varias o continuamente).
 * @param period Periodo de tiempo entre llamada y llamada (en mseg).
 * @param object Objeto del cual se llamará el metodo de callback.
 * @param callback Cadena que identifica el nombre del método de callback.
 * @param arg Objeto que representa al parámetro de la función de callback.
 */	    
- (void) initTimerWithArg:(int) aCycle period:(long) aPeriod 
						object:(id) anObject callback:(char *) aCallback arg: (id) anArg ;

						
/**
 *	init
 *	(all init deprectaed)
 *
 */
- (void) init:(int) aCycle period:(long) aPeriod object:(id) anObject 
					callback:(char*) aCallback ;
- (void) init:(int) aCycle period:(long) aPeriod object:(id) anObject 
					callback:(char*) aCallback arg1: (id) anObject1 ;
- (void) init:(int) aCycle period:(long) aPeriod object:(id) anObject 
					callback:(char*) aCallback arg1: (id) anObject1 arg2: anObject2 ;

/**
 *	setCycle
 *		Setea el ciclo del timer.
 *		El ciclo puede ser
 *	 		ONE_SHOT: se ejecuta solo una vez
 *			PERIODIC: se ejecuta periodicamente hasta llamar al stop
 */
- (void) setCycle:(int) aCycle;
						
/**
 *	setPeriod
 *		Setea el período del timer en milisegundos
 */
- (void) setPeriod:(long) aPeriod;
- (long) getPeriod;

/**
 *	setObject
 *		Setea el objeto y el método que se invoca cuando el timer expira 
 *
 */
- (void) setObject: (id) anObject callback: (char *) aCallback arg: (id) anArg;

	
/**
	Comienza a ejecutar el timer 
*/
- (void) start;


/**
	Detiene la ejecucion del timer
*/

- (void) stop;

- initalize;
- (void) expireTimer;
- (unsigned long) getTimeLeft;
- (unsigned long) getTimePassed;

@end

#endif 
