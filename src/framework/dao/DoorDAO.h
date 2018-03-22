#ifndef DOOR_DAO_H
#define DOOR_DAO_H

#define DOOR_DAO id

#include <Object.h>
#include "ctapp.h"
#include "DataObject.h"
#include "Door.h"
#include "TimeLock.h"

/**
 *	Implementacion de la persistencia de la configuracion de puertas.
 *
 *	<<singleton>>
 */
@interface DoorDAO : DataObject
{
}

+ getInstance;
+ (COLLECTION) loadAll;

/**/
- (COLLECTION) loadCompleteList;

/*
 * Se le pasan los minutos de time unlock y devuelve la hora/minutos formateadas (HH:MM)
 */
- (char*) formatMinutesToHourStr: (int) aMinutes buffer: (char*) aBuffer;

@end

#endif
