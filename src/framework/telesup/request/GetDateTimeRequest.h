#ifndef GETDATETIMEREQUEST_H
#define GETDATETIMEREQUEST_H

#define GET_DATETIME_REQUEST id

#include <Object.h>
#include "ctapp.h"

#include "GetRequest.h"


/**
 *	Consulta la fecha y hora y nada mas.
 */
@interface GetDateTimeRequest: GetRequest
{				
}		
	

/**
 * No tiene atributos ni metodos porque se consulta el unico parametro que es posible
  consulta que es "Datetime". 
 */
		
@end

#endif
