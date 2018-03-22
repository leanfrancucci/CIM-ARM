#ifndef ASKREQUEST_H
#define ASKREQUEST_H

#define ASKREQUEST id

#include <Object.h>
#include "ctapp.h"

#include "TelesupParser.h"
#include "Request.h"

/*
 * Define el tipo de los request que deben consultar 
 * informacion� al sistema remoto para invocar 
 * al TelesupSystemFacade
 */
@interface AskRequest: Request /* {Abstract} */
{
	TELESUP_PARSER		myTelesupParser;

	char				myResponseBuffer[ 512 ];
}

/**
 * Configura el parser de telesupervision especifico.
 * El parser solo es utilizado por los AskRequest.
 *
 */
- (void) setReqTelesupParser: (TELESUP_PARSER) aTelesupParser;
- (TELESUP_PARSER) getReqTelesupParser;


/**
 * Metodo hook invocado por executeRequest() para que cada subclase especifica 
 * agregue los parametros necesarios al mensaje creado por AskRequest antes de que sean enviados.
 * Por ejemplo el metodo podria implementrse asi:
 *		- (void) addQueryParameters
 *		{
 *			[myRemoteProxy addLine: "SETPHONE"]; 	
 *		}
 */
- (void) addQueryParameters;

@end

#endif
