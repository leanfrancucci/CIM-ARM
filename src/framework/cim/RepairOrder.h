#ifndef REPAIR_ORDER_H
#define REPAIR_ORDER_H

#define REPAIR_ORDER id

#include <Object.h>
#include "system/util/all.h"
#include "RepairOrderItem.h"

/**
 *	Especifica el tipo de prioridad del pedido de orden.
 */
typedef enum {
	PriorityType_UNDEFINED,
	PriorityType_URGENT,		       /** URGENTE */
	PriorityType_NORMAL,		       /** NORMAL */
	PriorityType_WITHOUT_PRIORITY	 /** SIN PRIORIDAD */
} PriorityType;

typedef enum {
	RepairOrderState_UNDEFINED,
	RepairOrderState_ERROR,		       
	RepairOrderState_OK		       
} RepairOrderState;



/**
 */
@interface RepairOrder : Object
{
	COLLECTION myRepairOrderItemList;
	PriorityType myPriority;
	char myTelephoneNumber[21];
	int myUserId;
	datetime_t myDateTime;
	int myRepairOrderState;
	char myRepairOrderNumber[20];
}

/**/
- (void) addRepairOrderItem: (REPAIR_ORDER_ITEM) aRepairOrderItem;
- (COLLECTION) getRepairOrderItemList;

/**/
- (void) setPriority: (int) aValue;
- (int) getPriority;

/**/
- (void) setTelephoneNumber: (char*) aValue;
- (char*) getTelephoneNumber;

/**/
- (void) setUserId: (int) aValue;
- (int) getUserId;

/**/
- (void) setDateTime: (datetime_t) aValue;
- (datetime_t) getDateTime;

/**/
- (void) setRepairOrderState: (int) aValue;
- (int) getRepairOrderState;

/**/
- (void) setRepairOrderNumber: (char*) aValue;
- (char*) getRepairOrderNumber;

@end

#endif
