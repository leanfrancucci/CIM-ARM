#ifndef EVENT_MANAGER_H
#define EVENT_MANAGER_H

#define EVENT_MANAGER id

#include "Object.h"
#include "ctapp.h"
#include "EventCategory.h"
#include "Event.h"

/**
 * Clase  
 */

@interface EventManager:  Object
{
	COLLECTION myEventsCategory;
	COLLECTION myEvents;
}

/**
 * 
 */

+ new;
+ getInstance;
- initialize;

/*******************************************************************************************
*																			EVENTS CATEGORIES SETTINGS
*
*******************************************************************************************/

/**
 * Devuelve la categoria con el id pasado como parametro
 */

- (EVENT_CATEGORY) getEventCategory: (int) aEventCategoryId;

/**
 * Setea si se permite loguear la categoria de eventos
 */

- (void) setEventCategoryLog: (int) aEventCategoryId value: (BOOL) aValue;

/**
 * Devuelve los valores correspondientes a la categoria de eventos
 */

- (char*) getEventCategoryDescription: (int) aEventCategoryId;
- (BOOL) getEventCategoryLog: (int) aEventCategoryId;
- (char*) getEventCategoryResource: (int) aEventCategoryId;

/**
 * Aplica los cambios en la persistencia realizados a la categoria de eventos pasada como parametro
 */

- (void) applyEventCategoryChanges: (int) aEventCategoryId;



/*******************************************************************************************
*																			EVENTS SETTINGS
*
*******************************************************************************************/

/**
 * Devuelve el evento con el id pasado como parametro
 */

- (EVENT) getEvent: (int) anEventId;


/**
 * Devuelve los valores correspondientes a los eventos
 */

- (int) getEventCategoryId: (int) anEventId;
- (char *) getEventName: (int) anEventId;
- (int) getEventHasAdditional: (int) anEventId;
- (BOOL) getEventIsCritical: (int) anEventId;
- (char *) getEventResource: (int) anEventId;

/**
 * Aplica los cambios en la persistencia realizados a la categoria de eventos pasada como parametro
 */

- (void) applyEventChanges: (int) anEventId;

/**
 * Devuelve la lista de eventos
 */
- (COLLECTION) getEvents;

/**
 * Devuelve la lista de categorias de evento
 */
- (COLLECTION) getEventsCategory;

@end

#endif

