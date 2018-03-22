#ifndef TELESUP_ERROR_MANAGER_H
#define TELESUP_ERROR_MANAGER_H

#define TELESUP_ERROR_MANAGER id

#include <Object.h>
#include "ctapp.h"
#include "TelesupDefs.h"

/**
 *	Mapea excepciones del sistema a errores especificaos de cada esquema de telesupervision particular.
 */
@interface TelesupErrorManager: Object
{
}

/**
 *	
 */
+ new;

/**
 *
 */
- free;
 
/**
 *	
 */
- initialize;

/**
 * Mapea el codigo de excepcion interno del sistema @param (int) excode con un codigo
 * de error adecuado en base al protocolo de telesupervision dado.
 * {A} (Debe ser reimplementado por cada esquema de telesupervision)
 */
- (int) getErrorCode: (int) excode;

	
@end

#endif
