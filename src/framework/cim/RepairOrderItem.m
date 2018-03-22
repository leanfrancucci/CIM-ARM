#include "RepairOrderItem.h"
#include "Persistence.h"

@implementation RepairOrderItem

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myItemId = 0;
	myItemDescription[0] = '\0';
	myDeleted = FALSE;
	return self;
}

/**/
- (void) setItemId: (int) aValue { myItemId = aValue; }
- (int) getItemId { return myItemId; } 

/**/
- (void) setItemDescription: (char*) aValue { stringcpy(myItemDescription, aValue); }
- (char*) getItemDescription { return myItemDescription; } 

/**/
- (void) setDeleted: (BOOL) aValue { myDeleted = aValue; }
- (BOOL) isDeleted { return myDeleted; }

/**/
- (void) applyChanges
{
	id repairOrderItemDAO;
	repairOrderItemDAO = [[Persistence getInstance] getRepairOrderItemDAO];
  
	[repairOrderItemDAO store: self];
}

/**/
- (void) restore
{
	REPAIR_ORDER_ITEM obj;

	//Recupera el objeto de la persistencia
	obj =	[[[Persistence getInstance] getRepairOrderItemDAO] loadById: [self getItemId]];		

	assert(obj != nil);
	//Setea los valores a la instancia en memoria
	[self setItemDescription: [obj getItemDescription]];

	[obj free];
}

/**/
- (STR) str
{
	return myItemDescription;
}

@end
