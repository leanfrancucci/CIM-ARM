#ifndef GET##TEMPLATE##REQUEST_H
#define GET##TEMPLATE##REQUEST_H

#define GET_##TEMPLATE##_REQUEST id

#include <Object.h>
#include "ctapp.h"

#include "GetRequest.h"


/**
 *	Consulta  el protocolo de ##TEMPLATE##
 */
@interface Get##TEMPLATE##Request: GetRequest
{
		BOOL 	my##ATTRIBUTE##Query;	
}		
	

/**
 * Los metodos que especifican los parametros consultados
 */
- (void) set##ATTRIBUTE##Query: (BOOL) aQuery;
		
@end

#endif
