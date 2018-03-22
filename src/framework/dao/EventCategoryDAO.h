#ifndef EVENT_CATEGORY_DAO_H
#define EVENT_CATEGORY_DAO_H

#define EVENT_CATEGORY_DAO id

#include <Object.h>
#include "ctapp.h"
#include "DataObject.h"
#include "system/db/all.h"

/**
 *	Implementacion ROP de la persistencia de la categoria de eventos.
 *	Provee metodos para recuperar las categoria de eventos.
 *
 *	<<singleton>>
 */
@interface EventCategoryDAO : DataObject
{
}

+ getInstance;

- (COLLECTION) loadAllEvents;

@end

#endif
