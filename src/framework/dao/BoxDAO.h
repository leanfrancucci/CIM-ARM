#ifndef BOX_DAO_H
#define BOX_DAO_H

#define BOX_DAO id

#include <Object.h>
#include "ctapp.h"
#include "DataObject.h"

/**
 *
 *	<<singleton>>
 */
@interface BoxDAO : DataObject
{
}

+ getInstance;
+ (COLLECTION) loadAll;

/** 
 * Manejador de aceptadores por caja.
 */
- (void) addAcceptorByBox: (int) aBoxId acceptorId: (int) anAcceptorId;
- (void) removeAcceptorByBox: (int) aBoxId acceptorId: (int) anAcceptorId;

/** 
 * Manejador de puertas por caja.
 */
- (void) addDoorByBox: (int) aBoxId doorId: (int) aDoorId;
- (void) removeDoorByBox: (int) aBoxId doorId: (int) aDoorId;

@end

#endif
