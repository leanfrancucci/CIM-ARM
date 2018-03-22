#ifndef TELESUP_SETTINGS_DAO_H
#define TELESUP_SETTINGS_DAO_H

#define TELESUP_SETTINGS_DAO id

#include <Object.h>
#include "ctapp.h"
#include "DataObject.h"
#include "system/db/all.h"
#include "TelesupSettings.h"

/**
 *	Implementacion ROP de la persistencia de las telesupervisiones.
 *	Provee metodos para recuperar las telesupervisiones.
 *
 *	<<singleton>>
 */
@interface TelesupSettingsDAO : DataObject
{
}

+ getInstance;

/**
 *	Actualiza la fecha/hora de ultima supervision exitosa y ultimo intento con
 *	la informacion contenida en el objeto pasado por parametro.
 */
- (void) updateTelesupDate: (TELESUP_SETTINGS) aTelesup;


@end

#endif
