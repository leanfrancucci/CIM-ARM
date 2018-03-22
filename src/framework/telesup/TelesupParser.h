#ifndef TELESUPPARSER_H
#define TELESUPPARSER_H

#define TELESUP_PARSER id

#include <Object.h>
#include "ctapp.h"

#include "Request.h"

/*
 *	Define el tipo de los parsers de mensajes de telesupervision
 */
@interface TelesupParser: Object /* {Abstract} */
{
	int							myTelesupRol;
	char						mySystemId[ TELESUP_SYSTEM_ID_LEN + 1];
}

/*
 *	
 */
+ new;

/*
 *	
 */
- initialize;


/**/
- (void) setTelesupRol: (int) aTelesupRol;
- (int) getTelesupRol;


/**/
- (void) setSystemId: (char *) aSystemId;
- (char *) getSystemId;

/*
 *  Retorna el Request del tipo adecuado en base al mensaje 
 *  recibido. 
 *  El Request se crea y se configuran sus atributos siempre que sea 
 *  posible (en base al tipo de Request creado)
 *
 *	El mensasaje @param (char *) aMessage viene ya previamente decodificado adecuadamente.
 *
 *  @throws TSUP_INVALID_REQUEST_EX
 *  {A}
 */
- (REQUEST) getRequest: (char *) aMessage;

/**
 * Devuelve el valor correspondiente al parametro de tipo String.
 * 
 *  @result (char *) El valor retornado es un puntero a un buffer interno del parser. Por
 *  lo tanto el metodo no es REENTRANTE.
 */
- (char *) getParamAsString: (char *) aMessage paramName: (char *) aParamName;

/**
 * Devuelve el parametro haciendo left trim y right trim del string obtenido.
 */
- (char *) getParamAsTrimString: (char *) aMessage paramName: (char *) aParamName;


/**
 * Devuelve el valor correspondiente al parametro Entero.
 */
- (int) getParamAsInteger: (char *) aMessage paramName: (char *) aParamName;
/**
 * Devuelve el valor correspondiente al parametro Long.
 */
- (int) getParamAsLong: (char *) aMessage paramName: (char *) aParamName;
/**
 * Devuelve el valor correspondiente al parametro Booleano.
 */
- (BOOL) getParamAsBoolean: (char *) aMessage paramName: (char *) aParamName;


/**
 * Devuelve el valor correspondiente al parametro Float.
 */
- (float) getParamAsFloat: (char *) aMessage paramName: (char *) aParamName;

/**
 * Devuelve el valor correspondiente al parametro Moneda.
 */
- (money_t) getParamAsCurrency: (char *) aMessage paramName: (char *) aParamName;

/**
 * Devuelve el valor correspondiente al parametro en formato time_t.
 */
- (datetime_t) getParamAsDateTime: (char *) aMessage paramName: (char *) aParamName;	

@end

#endif
