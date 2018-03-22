#include "CashReferenceDAO.h"
#include "CashReference.h"
#include "system/util/all.h"
#include "CashReferenceManager.h"
#include "ResourceStringDefs.h"
#include "Audit.h"

#include "DataSearcher.h"


static id singleInstance = NULL;

@implementation CashReferenceDAO

- (id) newFromRecordSet: (id) aRecordSet; 

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
- (id) newFromRecordSet: (id) aRecordSet
{
	CASH_REFERENCE obj;
	char buffer[31];

	obj = [CashReference new];

	[obj setCashReferenceId: [aRecordSet getShortValue: "REFERENCE_ID"]];
	[obj setName: [aRecordSet getStringValue: "NAME" buffer: buffer]];
	[obj setParentId: [aRecordSet getShortValue: "PARENT_ID"]];
	[obj setDeleted: [aRecordSet getCharValue: "DELETED"]];

	return obj;
}

/**/
- (COLLECTION) loadAll
{
	COLLECTION collection = [Collection new];
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "cash_reference" filter: "" orderFields: "REFERENCE_ID"];
	id obj;
	
	[myRecordSet open]; 
	
	while ( [myRecordSet moveNext] ) {
		obj = [self newFromRecordSet: myRecordSet];
		[collection add: obj];
	}

	[myRecordSet free];
  
	return collection;
}

/**/
- (id) loadById: (unsigned long) anId
{
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "cash_reference" filter: "" orderFields: "REFERENCE_ID"];
	
	id obj = NULL;

	[myRecordSet open];

	if ([myRecordSet findById: "REFERENCE_ID" value: anId]) {
		obj = [self newFromRecordSet: myRecordSet];
	} 
  
	[myRecordSet free];
  
	return obj;
}

/**/
- (void) validateFields: (id) anObject
{

	if (strlen([anObject getName]) == 0)
		THROW(DAO_CASH_REFERENCE_NAME_NULLED_EX);

}

/**/
- (void) store: (id) anObject
{
	int referenceId;
	char buffer[60];
  AUDIT audit;
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet;
	ABSTRACT_RECORDSET myRecordSetBck;
	volatile BOOL updateRecord = FALSE;

	int parentId = 0;
	char auxOldParentStr[40];
	char auxNewParentStr[40];
	int auxNewParent = 0;

	[self validateFields: anObject];

	myRecordSet = [dbConnection createRecordSetWithFilter: "cash_reference" filter: "" orderFields: "REFERENCE_ID"];

	[myDataSearcher setRecordSet: myRecordSet];
	[myDataSearcher addShortFilter: "REFERENCE_ID" operator: "!=" value: [anObject getCashReferenceId]];  
	[myDataSearcher addStringFilter: "NAME" operator: "=" value: [anObject getName]];
	if ([anObject getParent]) parentId = [[anObject getParent] getCashReferenceId];
	[myDataSearcher addShortFilter: "PARENT_ID" operator: "=" value: parentId];
	[myDataSearcher addCharFilter: "DELETED" operator: "=" value: FALSE];

	[myRecordSet open];

  if ([myDataSearcher find]) {
		[myRecordSet free];
		[myDataSearcher free];
		THROW(DAO_DUPLICATED_CASH_REFERENCE_EX);    
	}

	TRY
	
		[myRecordSet open];

		if ([anObject isDeleted]) {
			updateRecord = TRUE;
			audit = [[Audit new] initAuditWithCurrentUser: Event_DELETE_CASH_REFERENCE additional: [anObject getName] station: [anObject getCashReferenceId] logRemoteSystem: TRUE];
			[myRecordSet findById: "REFERENCE_ID" value: [anObject getCashReferenceId]];
		} else if ([anObject getCashReferenceId] != 0) {
			updateRecord = TRUE;
			[myRecordSet findById: "REFERENCE_ID" value: [anObject getCashReferenceId]];
			audit = [[Audit new] initAuditWithCurrentUser: Event_EDIT_CASH_REFERENCE additional: "" station: [anObject getCashReferenceId] logRemoteSystem: TRUE];
		} else {
			[myRecordSet add];
			audit = [[Audit new] initAuditWithCurrentUser: Event_NEW_CASH_REFERENCE additional: "" station: 0 logRemoteSystem: TRUE];
		}
	
		// LOG DE CAMBIOS 
		if (![anObject isDeleted]) {
	
			[audit logChangeAsString: RESID_CashReference_NAME oldValue: [myRecordSet getStringValue: "NAME" buffer: buffer] newValue: [anObject getName]];
	
			auxOldParentStr[0] = '\0';
			auxNewParentStr[0] = '\0';
	
			if ([myRecordSet getShortValue: "PARENT_ID"] != 0) 
				strcpy(auxOldParentStr, [[[CashReferenceManager getInstance] getCashReferenceById: [myRecordSet getShortValue: "PARENT_ID"]] getName]);
	
			if ([anObject getParent]) {
				strcpy(auxNewParentStr, [[anObject getParent] getName]);
				auxNewParent = [[anObject getParent] getCashReferenceId];
			}
			
			[audit logChangeAsString: FALSE 
						resourceId: RESID_CashReference_PARENT_ID 
						oldValue: auxOldParentStr
						newValue: auxNewParentStr
						oldReference: [myRecordSet getShortValue: "PARENT_ID"] 
						newReference: auxNewParent];
		}

  	[myRecordSet setStringValue: "NAME" value: [anObject getName]];
		[myRecordSet setCharValue: "DELETED" value: [anObject isDeleted]];
		if ([anObject getParent])
			[myRecordSet setShortValue: "PARENT_ID" value: [[anObject getParent] getCashReferenceId]];

		referenceId = [myRecordSet save];
		[anObject setCashReferenceId: referenceId];

		[audit setStation: referenceId];
  	[audit saveAudit];
  	[audit free];

		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "cash_reference_bck"]) {
			myRecordSetBck = [dbConnection createRecordSetWithFilter: "cash_reference_bck" filter: "" orderFields: "REFERENCE_ID"];
	
			if (updateRecord) [self doUpdateBackupById: "REFERENCE_ID" value: [anObject getCashReferenceId] backupRecordSet: myRecordSetBck currentRecordSet: myRecordSet tableName: "cash_reference_bck"];
			else [self doAddBackup: myRecordSetBck currentRecordSet: myRecordSet tableName: "cash_reference_bck"];
		}

	FINALLY

		[myRecordSet free];
		[myDataSearcher free];
	
	END_TRY
}

@end
