#ifndef EVENT_CATEGORY_H
#define EVENT_CATEGORY_H

#define EVENT_CATEGORY id

#include "Object.h"
#include "ctapp.h"

/**
 *	Representa una categoria de eventos.
 * 	
 */
@interface EventCategory :  Object
{
	int myEventCategoryId;
	char myDescription[30];
	BOOL myLogCategory;
	BOOL myDeleted;
}

/**
 * Setea los valores correspondientes a la categoria de eventos
 */

- (void) setEventCategoryId: (int) aValue;
- (void) setCatEventDescription: (char*) aValue;
- (void) setLogEventCategory: (BOOL) aValue; 
- (void) setDeleted: (BOOL) aValue;

/**
 * Devuelve los valores correspondientes a la categoria de eventos
 */

- (int) getEventCategoryId;
- (char*) getCatEventDescription;
- (BOOL) logEventCategory;
- (BOOL) isDeleted;
	
/**
 * Aplica los cambios realizados a la categoria de eventos en la persistencia.
 */

- (void) applyChanges;

/**
 * Restaura los valores de la persistencia
 */

- (void) restore;

@end

#endif


