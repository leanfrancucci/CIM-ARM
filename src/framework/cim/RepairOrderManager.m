#include "RepairOrderManager.h"
#include "Persistence.h"
#include "SettingsExcepts.h"
#include "RepairOrderItemDAO.h"
#include "MessageHandler.h"
#include "Audit.h"
#include "util.h"
#include <stdlib.h> 
#include "CtSystem.h"
#include "system/util/all.h"
#include "Event.h"



static id singleInstance = NULL;


@implementation RepairOrderManager


/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
  [singleInstance initialize];
	return singleInstance;
 
}

/**/
+ getInstance
{
	return [self new];	
}


/**/
- initialize
{
	myRepairOrderItemList = [[[Persistence getInstance] getRepairOrderItemDAO] loadAll];
	assert(myRepairOrderItemList);
  
  return self;
}

/*******************************************************************************************
*																			REPAIR ORDER SETTINGS
*
*******************************************************************************************/

/**/
- (void) setRepairOrderDescription: (int) anItemId value: (char*) aValue
{
	REPAIR_ORDER_ITEM obj = [self getRepairOrderItem: anItemId];
	[obj setItemDescription: aValue];
}

/**/
- (char*) getRepairOrderDescription: (int) anItemId
{
	REPAIR_ORDER_ITEM obj = [self getRepairOrderItem: anItemId];
	return [obj getItemDescription];
}

/**/
- (REPAIR_ORDER_ITEM) getRepairOrderItem: (int) anItemId
{
	int i = 0;
	
	for (i=0; i<[myRepairOrderItemList size];++i) 
		if ([ [myRepairOrderItemList at: i] getItemId] == anItemId) return [myRepairOrderItemList at: i];
	
	THROW(REFERENCE_NOT_FOUND_EX);
	return NULL;
}

/**/
- (void) applyRepairOrderChanges: (int) anItemId
{
	REPAIR_ORDER_ITEM obj = [self getRepairOrderItem: anItemId];
  
	[obj applyChanges];
}

/**/
- (int) addRepairOrder:(char*) aDescription
{
  REPAIR_ORDER_ITEM	newRepairOrderItem = [RepairOrderItem new];
	
	[newRepairOrderItem setItemDescription: aDescription];

	[newRepairOrderItem applyChanges];
		
	[self  addRepairOrderToCollection: newRepairOrderItem];

	return [newRepairOrderItem getItemId];
}

- (void) removeRepairOrder: (int) anItemId
{
  REPAIR_ORDER_ITEM aRepairOrderItem = [self getRepairOrderItem: anItemId];

  [self deleteRepairOrder: aRepairOrderItem];
  
}

/**/
- (void) deleteRepairOrder: (REPAIR_ORDER_ITEM) aRepairOrderItem
{
  int aRepairOrderId = 0;
  
  // elimino el repairorderitem
  aRepairOrderId = [aRepairOrderItem getItemId];
	[aRepairOrderItem setDeleted: TRUE];
	[aRepairOrderItem applyChanges];
	[self removeRepairOrderFromCollection: aRepairOrderId];  

}

/**/
- (void) addRepairOrderToCollection: (REPAIR_ORDER_ITEM) aRepairOrderItem
{
	[myRepairOrderItemList add: aRepairOrderItem];
}

/**/
- (void) removeRepairOrderFromCollection: (int) anItemId
{
	int i = 0;
	
	for (i=0; i<[myRepairOrderItemList size]; ++i)
		if ([ [myRepairOrderItemList at: i] getItemId] == anItemId) {
			[myRepairOrderItemList removeAt: i];
			return;
		}
}


/**/
- (void) restoreRepairOrder: (int) anItemId
{
	REPAIR_ORDER_ITEM obj = [self getRepairOrderItem: anItemId];

	[obj restore];
}

/**/
- (COLLECTION) getRepairOrderItems
{
	return myRepairOrderItemList;
}

@end
