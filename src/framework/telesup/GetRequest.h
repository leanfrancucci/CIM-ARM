#ifndef GETREQUEST_H
#define GETREQUEST_H

#define GETREQUEST id

#include <Object.h>
#include "ctapp.h"

#include "Request.h"

/*
 *	Define el tipo de todos los Request que son utilizados
 *  para que el sistema remoto consulte informacion sobre
 *  el estado del sistema.
 */
@interface GetRequest: Request /* {Abstract} */
{
}

/**
 * Debe ser reimplementado por cada clase para enviar los datos del request a traves del RemoteProxy.
 * {A}
 */
- (void) sendRequestData;
- (void) beginEntity;
- (void) endEntity;

@end

#endif
