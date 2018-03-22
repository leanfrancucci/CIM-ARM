#ifndef PRINTING_SETTINGS_DAO_H
#define PRINTING_SETTINGS_DAO_H

#define PRINTING_SETTINGS_DAO id

#include <Object.h>
#include "ctapp.h"
#include "DataObject.h"

/**
 *	Implementacion de la persistencia de la configuracion de la impresion.
 *	Provee metodos para recuperar la configuracion de la impresion.
 *
 *	<<singleton>>
 */
@interface PrintingSettingsDAO : DataObject
{
}

+ getInstance;


@end

#endif
