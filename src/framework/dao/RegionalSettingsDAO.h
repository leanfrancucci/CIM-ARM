#ifndef REGIONAL_SETTINGS_DAO_H
#define REGIONAL_SETTINGS_DAO_H

#define REGIONAL_SETTINGS_DAO_ id

#include <Object.h>
#include "ctapp.h"
#include "DataObject.h"

/**
 *	Implementacion de la persistencia de configuracion regional.
 *	Provee metodos para recuperar la configuracion regional.
 *
 *	<<singleton>>
 */
@interface RegionalSettingsDAO : DataObject
{
}

+ getInstance;


@end

#endif
