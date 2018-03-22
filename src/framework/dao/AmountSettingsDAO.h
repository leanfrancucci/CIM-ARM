#ifndef AMOUNT_SETTINGS_DAO_H
#define AMOUNT_SETTINGS_DAO_H

#define AMOUNT_SETTINGS_DAO id

#include <Object.h>
#include "ctapp.h"
#include "DataObject.h"

/**
 *	Implementacion de la persistencia de la configuracion de los montos.
 *	Provee metodos para recuperar la configuracion de los montos .
 *
 *	<<singleton>>
 */
@interface AmountSettingsDAO : DataObject
{
}

+ getInstance;


@end

#endif
