#ifndef DUMMY_TELESUP_VIEWER_H
#define DUMMY_TELESUP_VIEWER_H

#define DUMMY_TELESUP_VIEWER id

#include <Object.h>
#include "ctapp.h"

#include "TelesupViewer.h"

/**
 *	Es una clase que se encarga de actualizar el progreso de la Telesupervision.
 *	Implementa solo doLog() a la salida estandar
 */
@interface DummyTelesupViewer: TelesupViewer
{
}


@end

#endif
