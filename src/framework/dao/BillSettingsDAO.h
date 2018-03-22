#ifndef BILL_SETTINGS_DAO_H
#define BILL_SETTINGS_DAO_H

#define BILL_SETTINGS_DAO id

#include <Object.h>
#include "ctapp.h"
#include "DataObject.h"

/**
 *	Implementacion de la persistencia de la configuracion de la facturacion.
 *	Provee metodos para recuperar la configuracion de la facturacion.
 *
 *	<<singleton>>
 */
@interface BillSettingsDAO : DataObject
{
}

+ getInstance;


@end

#endif
