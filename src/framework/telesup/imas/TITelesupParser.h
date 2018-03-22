#ifndef TI_TELESUP_PARSER_H
#define TI_TELESUP_PARSER_H

#define TI_TELESUP_PARSER id

#include <Object.h>
#include "ctapp.h"
#include "TelesupParser.h"


/**
 *	Implementa el parsing de los mensajes provenientes
 *  de la telesupervision con el sistema de Telecom
 */
@interface TITelesupParser: TelesupParser
{
	char systemId[20];
}


/**
 *	Setea el identificador del equipo. Esto se establece porque algunos archivos
 *	que se deben enviar deben tener concatenado el numero de equipo.
 */
- (void) setSystemId: (char *) aSystemId;

- (REQUEST) getRequest: (char *) aMessage activateFilter:(int)filtered fromDate:(datetime_t)fDate toDate:(datetime_t)tDate;

@end

#endif
