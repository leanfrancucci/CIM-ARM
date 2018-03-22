#include "RepairOrder.h"	

@implementation RepairOrder

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myRepairOrderItemList = [Collection new];
	myPriority = 0;
	myRepairOrderState = RepairOrderState_UNDEFINED;
	myDateTime = 0;
	myRepairOrderNumber[0] = '\0';
	return self;
}

/**/
- (void) addRepairOrderItem: (REPAIR_ORDER_ITEM) aRepairOrderItem
{
  [myRepairOrderItemList add: aRepairOrderItem];
}

/**/
- (COLLECTION) getRepairOrderItemList
{
  return myRepairOrderItemList;
}

/**/
- (void) setPriority: (int) aValue { myPriority = aValue; }
- (int) getPriority { return myPriority; }

/**/
- (void) setTelephoneNumber: (char*) aValue { stringcpy(myTelephoneNumber, aValue); }
- (char*) getTelephoneNumber { return myTelephoneNumber; }

/**/
- (void) setUserId: (int) aValue { myUserId = aValue; }
- (int) getUserId { return myUserId; }

/**/
- (void) setDateTime: (datetime_t) aValue { myDateTime = aValue; }
- (datetime_t) getDateTime { return myDateTime; }

/**/
- (void) setRepairOrderState: (int) aValue { myRepairOrderState = aValue; }
- (int) getRepairOrderState { return myRepairOrderState; }

/**/
- (void) setRepairOrderNumber: (char*) aValue { stringcpy(myRepairOrderNumber, aValue); }
- (char*) getRepairOrderNumber { return myRepairOrderNumber; }

@end
