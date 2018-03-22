#ifndef CIM_GENERAL_SETTINGS_DAO_H
#define CIM_GENERAL_SETTINGS_DAO_H

#define CIM_GENERAL_SETTINGS_DAO id

#include <Object.h>
#include "ctapp.h"
#include "DataObject.h"

/**
 *	Implementacion de la persistencia de la configuracion del CIM.
 *
 *	<<singleton>>
 */
@interface CimGeneralSettingsDAO : DataObject
{
}

+ getInstance;


@end

#endif
