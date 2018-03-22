#ifndef SYSTEM_TIME_H
#define SYSTEM_TIME_H

#define SYSTEM_TIME id

#include <Object.h>
#include <time.h>
#include "system/lang/all.h"

/**
 *	System time.
 *	Encapsula el manejo de fecha/hora del sistema.
 *	Todos metodos de clase.
 */
@interface SystemTime : Object
{

}


/**
 *	Devuelve la fecha/hora actual local.
 */
+ (datetime_t) getLocalTime;

/**
 *	Setea la fecha/hora del sistema de acuerdo con la fecha/hora local pasada por parametro.
 */
+ (void) setLocalTime: (datetime_t) aLocalTime;

/**
 *	Setea la fecha/hora del sistema de acuerdo con la fecha/hora GMT pasada como parametro.
 */
+ (void) setGMTTime: (datetime_t) aGMTTime;

/**
 *	Devuelve la fecha/hora actual en GMT.
 */
+ (datetime_t) getGMTTime;

/**
 *	Codifica la fecha/hora a partir de los valores pasados por parametro.
 *
 *	@param year anio desde 1970 en adelante.
 *	@param mon  mes [1-12].
 *	@param day  dia [1-31].
 *	@param hour hora [0-23].
 *	@param min  minutos [0-59].
 *	@param sec  segundos [0-59].
 */
+ (datetime_t) encodeTime: (int) aYear mon: (int) aMon day: (int) aDay
							 hour: (int) anHour min: (int) aMin sec: (int) aSec;

/**
 *	Decodifica la fecha/hora pasada como parametro en la estructura brokenTime.
 *
 *	@param datetime la fecha/hora a convertir en segundos desde 1970.
 *	@param brokenTime la estructura convertida.
 */							 
+ (struct tm*) decodeTime: (datetime_t) aDateTime brokenTime: (struct tm*) aBrokenTime;
							 
/**
 *	Convierte la hora GMT pasada como parametro a hora local.
 */
+ (datetime_t) convertToLocalTime: (datetime_t) aGMTTime;

/**
 *	Convierte la hora Local pasada como parametro a hora GMT.
 */
+ (datetime_t) convertToGMTTime: (datetime_t) aLocalTime;

/**
 *	Devuelve la zona horaria, en segundos de diferencia.
 */
+ (int) getTimeZone;

/**
 *	Configura la zona horaria, en segundos de diferencia con GMT.
 */
+ (void) setTimeZone: (int) aTimeZone;

/**
 *	Chequea que la fecha actual sea correcta dentro de los limites establecidos (2005-2050).
 *	En caso que haya un error arroja una excepcion INVALID_CURRENT_TIME_EX.
 *	@throws INVALID_CURRENT_TIME_EX si la fecha es invalida.
 */
+ (void) checkCurrentTime;

@end

#endif
