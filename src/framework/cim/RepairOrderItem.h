#ifndef REPAIR_ORDER_ITEM_H
#define REPAIR_ORDER_ITEM_H

#define REPAIR_ORDER_ITEM id

#include <Object.h>
#include "system/util/all.h"

/**
 */
@interface RepairOrderItem : Object
{
	int myItemId;
	char myItemDescription[22];
	BOOL myDeleted;
}

/**/
- (void) setItemId: (int) aValue;
- (int) getItemId;

/**/
- (void) setItemDescription: (char*) aValue;
- (char*) getItemDescription;

/**/
- (void) setDeleted: (BOOL) aValue;
- (BOOL) isDeleted;

/*
 * Aplica los cambios
 */
- (void) applyChanges;

/*
 * Restaura los valores de la persistencia
 */
- (void) restore;


@end

#endif
