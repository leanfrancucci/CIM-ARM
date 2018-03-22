#ifndef __TELESUPFACTORY_H
#define __TELESUPFACTORY_H

#define TELESUP_FACTORY id

#include <Object.h>
#include "ctapp.h"
#include "system/io/all.h"

#include "TelesupD.h"
#include "TelesupErrorManager.h"
#include "TelesupViewer.h"

/*
 *	Devuelve una instancia de un hilo de telesupervision adecuado.
 */
@interface TelesupFactory: Object
{

}

/**/
+ getInstance;

/**
 * Devuelve un demonio de telesupervision de tipo adecuado en base al identificador 
 * del esquema de telesupervision particular.
 * @param (int) aTelesupId especifica el esquema de telesupervision particular (G2, Telefonica, Telecom, etc)
 * @param (int) aTelesupRol especifica el rol de telesupervision particular
 * @param (TELESUP_VIEWER) aTelesupViewer el observer del proceso telesupervision, si es NULL se 
 * crea un DummyTelesupViewer.
 * @result (TelesupD) devuelve un demonio de telesupervision particular.
 */
- getNewTelesupDaemon: (int) aTelesupId rol: (int) aRol viewer: (TELESUP_VIEWER) aTelesupViewer
						reader: (READER) aReader  writer: (WRITER) aWriter;

/**
 * Devuelve un manejador de errores de telesupervision adecuado en base al identificador 
 * del esquema de telesupervision particular.
 */
- (TELESUP_ERROR_MANAGER) getTelesupErrorManager: (int) aTelesupId;

@end

#endif
