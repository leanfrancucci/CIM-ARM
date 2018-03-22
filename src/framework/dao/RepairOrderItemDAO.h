#ifndef REPAIR_ORDER_ITEM_DAO_H
#define REPAIR_ORDER_ITEM_DAO_H

#define REPAIR_ORDER_ITEM_DAO id

#include <Object.h>
#include "ctapp.h"
#include "DataObject.h"

/**
 *
 *	<<singleton>>
 */
@interface RepairOrderItemDAO : DataObject
{
	COLLECTION myCompleteList;
	COLLECTION myActiveList;
	ABSTRACT_RECORDSET myRepairOrderItemRS;
}

+ getInstance;
+ (COLLECTION) loadAll;

- (void) loadCompleteList;
- (COLLECTION) getCompleteList;
- (COLLECTION) getActiveList;

@end

#endif
