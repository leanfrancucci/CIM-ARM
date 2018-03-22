#ifndef COMMERCIAL_STATE_DAO_H
#define COMMERCIAL_STATE_DAO_H

#define COMMERCIAL_STATE_DAO id

#include <Object.h>
#include "ctapp.h"
#include "DataObject.h"

/**
 *	Implementacion de la persistencia del estado comercial del sistema.
 *	Provee metodos para recuperar el estado comercial del sistema.
 *
 *	<<singleton>>
 */
@interface CommercialStateDAO : DataObject
{
}

+ getInstance;
- (void) storeCommercialStateElapsedTime: (id) anObject;


@end

#endif
