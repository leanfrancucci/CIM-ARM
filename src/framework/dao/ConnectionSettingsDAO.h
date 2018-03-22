#ifndef CONNECTION_SETTINGS_DAO_H
#define CONNECTION_SETTINGS_DAO_H

#define CONNECTION_SETTINGS_DAO id

#include <Object.h>
#include "ctapp.h"
#include "DataObject.h"
#include "system/db/all.h"

/**
 *	Implementacion ROP de la persistencia de las conexiones.
 *	Provee metodos para recuperar las conexiones.
 *
 *	<<singleton>>
 */
@interface ConnectionSettingsDAO : DataObject
{
}

+ getInstance;

@end

#endif
