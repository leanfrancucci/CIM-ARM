#ifndef SETPARAMREQUEST_H
#define SETPARAMREQUEST_H

#define SET_PARAM_REQUEST id

#include <Object.h>
#include "ctapp.h"

#include "Request.h"

/*
 *	Define el tipo de los Request utilizados para configurar
 *  remotamente el nuevo estado del sistema.
 */
@interface SetParamRequest: Request /* {Abstract} */
{

}

/**
 * Debe ser reimplementado por cada subclase para configurar adecuadamente los 
 * parametros dados.
 * {A}
 */
- (void) setParamSettings;

@end

#endif
