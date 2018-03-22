#ifndef GET_APPLIED_MESSAGES_REQUEST_H
#define GET_APPLIED_MESSAGES_REQUEST_H

#define GET_APPLIED_MESSAGES_REQUEST id

#include <Object.h>
#include "ctapp.h"
#include "GetRequest.h"

/**
 *	Obtiene los mensajes ejecutados y recibidos dentro de un Job
 */
@interface GetAppliedMessagesRequest: GetRequest
{	
	int						myFilterType;

	unsigned long 			myFromId;
	unsigned long 			myToId;		
}		

/**
 * Los metodos que especifican los parametros consultados
 */

/**
 * Indica si el filtro seleccionado es por fecha, por id o sin filtro.
 * @param int filterType:	0: (NONE_INFO_FILTER) 	ningun filtro
 *							1: (ID_INFO_FILTER)		filtro por identificador de entidad
 */
- (void) setFilterInfoType: (int) aFilterInfoType;

- (void) setFromId: (int) aFromId;
- (void) setToId: (int) aToId;

@end



#endif



