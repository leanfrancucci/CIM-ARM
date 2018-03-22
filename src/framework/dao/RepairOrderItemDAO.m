#include "RepairOrderItem.h"
#include "RepairOrderItemDAO.h"
#include "ordcltn.h"
#include "system/db/all.h"
#include "DataSearcher.h"
#include "util.h"
#include "Audit.h"
#include "MessageHandler.h"
#include "system/util/all.h"
#include "DAOExcepts.h"
#include "SettingsExcepts.h"

static id singleInstance = NULL;

@implementation RepairOrderItemDAO


/**/
+ new
{
	if (!singleInstance) singleInstance = [super new];
	return singleInstance;
}

/**/
- free
{
	return [super free];
}

/**/
+ getInstance
{
	return [self new];
}

/**/
- initialize
{
	[super initialize];

	myCompleteList = [Collection new];
	myActiveList = [Collection new];
	
	return self;
}

/*
 *	Devuelve la configuracion de las ordenes de reparacion en base a la informacion del registro actual del recordset.
 */

- (id) newRepairOrderItemFromRecordSet: (id) aRecordSet
{
	REPAIR_ORDER_ITEM obj;
	char buffer[50];

	obj = [RepairOrderItem new];

	[obj setItemId: [aRecordSet getShortValue: "ITEM_ID"]];
	[obj setItemDescription: [aRecordSet getStringValue: "DESCRIPTION" buffer: buffer]];
	[obj setDeleted: [aRecordSet getCharValue: "DELETED"]];
	
	return obj;
}

/**/
- (COLLECTION) loadAll
{
	COLLECTION collection = [Collection new];
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "repair_order_item" filter: "" orderFields: "ITEM_ID"];
	REPAIR_ORDER_ITEM obj;
	
	[myRecordSet open];
  
	while ( [myRecordSet moveNext] ) {
		// agrego la orden a la coleccion solo si no se encuentra borrado
		obj = [self newRepairOrderItemFromRecordSet: myRecordSet];
		if (!( [obj isDeleted])) [collection add: obj];
		else [obj free];
	}

	[myRecordSet free];

	return collection;
}

/**/
- (void) loadCompleteList
{

	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "repair_order_item" filter: "" orderFields: "ITEM_ID"];
	REPAIR_ORDER_ITEM obj;

	[myRecordSet open];

	while ( [myRecordSet moveNext] ) {

		obj = [self newRepairOrderItemFromRecordSet: myRecordSet];

		[myCompleteList add: obj];

		if (!( [obj isDeleted])) [myActiveList add: obj];
	}

	[myRecordSet free];

}

/**/
- (COLLECTION) getCompleteList
{
	assert(myCompleteList);

	return myCompleteList;
}

/**/
- (COLLECTION) getActiveList
{
	assert(myActiveList);

	return myActiveList;
}

/**/
- (void) store: (id) anObject
{
	int repairOrderItemId;
  AUDIT audit;
	char buffer[61];

	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "repair_order_item" filter: "" orderFields: "ITEM_ID"];
		
	[myDataSearcher setRecordSet: myRecordSet];
  [myDataSearcher addShortFilter: "ITEM_ID" operator: "!=" value: [anObject getItemId]];  
	[myDataSearcher addStringFilter: "DESCRIPTION" operator: "=" value: [anObject getItemDescription]];
	[myDataSearcher addCharFilter: "DELETED" operator: "=" value: 0];
	
	TRY

		[myRecordSet open];

    [self validateFields: anObject];

    if ([myDataSearcher find]) THROW(DAO_DUPLICATED_REPAIR_ORDER_ITEM_EX);

    if ([anObject isDeleted]) {
      [myRecordSet findById: "ITEM_ID" value: [anObject getItemId]];
      audit = [[Audit new] initAuditWithCurrentUser: Event_DELETE_REPAIR_ORDER_ITEM additional: [anObject getItemDescription] station: 0 logRemoteSystem: FALSE];
    } else if ([anObject getItemId] != 0) {
      [myRecordSet findById: "ITEM_ID" value: [anObject getItemId]];
      audit = [[Audit new] initAuditWithCurrentUser: Event_EDIT_REPAIR_ORDER_ITEM additional: [anObject getItemDescription] station: 0 logRemoteSystem: FALSE];     
    } else {      
      [myRecordSet add];
      audit = [[Audit new] initAuditWithCurrentUser: Event_NEW_REPAIR_ORDER_ITEM additional: [anObject getItemDescription] station: 0 logRemoteSystem: FALSE];
    }

    // LOG DE CAMBIOS 
    if (![anObject isDeleted]) {
      [audit logChangeAsString: RESID_Repair_Order_Item_DESCRIPTION oldValue: [myRecordSet getStringValue: "DESCRIPTION" buffer: buffer] newValue: [anObject getItemDescription]];
    }

		[myRecordSet setStringValue: "DESCRIPTION" value: [anObject getItemDescription]];
		[myRecordSet setCharValue: "DELETED" value: [anObject isDeleted]];
    
		repairOrderItemId = [myRecordSet save];
		[anObject setItemId: repairOrderItemId];
		
    [audit saveAudit];  
    [audit free];

	FINALLY

		[myRecordSet free];
	
	END_TRY
}

/**/
- (void) validateFields: (id) anObject
{

  if (strlen([anObject getItemDescription]) == 0) 
    THROW(DAO_REPAIR_ORDER_DESCRIPTION_NULLED_EX);
}

/**/
- (id) loadById: (unsigned long) anId
{
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "repair_order_item" filter: "" orderFields: "ITEM_ID"];
	
	id obj = NULL;

	[myRecordSet open];

	if ([myRecordSet findById: "ITEM_ID" value: anId]) {
		obj = [self newRepairOrderItemFromRecordSet: myRecordSet];
		//Verifica que la el usuario no este borrado
		if (![obj isDeleted])	return obj;
	} 
  
	[myRecordSet free];
  
	THROW(REFERENCE_NOT_FOUND_EX);
	return NULL;
}

@end
