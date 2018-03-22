#ifndef GET##TEMPLATE##REQUEST_H
#define GET##TEMPLATE##REQUEST_H

#define GET_##TEMPLATE##_REQUEST id

#include <Object.h>
#include "ctapp.h"

#include "GetRequest.h"


/**
 *	Consulta   ##TEMPLATE##
 */
@interface Get##TEMPLATE##Request: GetRequest
{
	int			my##TEMPLATE##Ref;
	
	BOOL 		my##ATRIBUTE##Query;
}		
	

- (void) set##TEMPLATE##Ref: (int) a##TEMPLATE##Ref;

/**
 * Los metodos que especifican los parametros consultados
 */
- (void) set##ATRIBUTE##Query: (BOOL) aQuery;
		
@end

#endif
