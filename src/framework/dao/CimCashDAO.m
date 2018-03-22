#include "CimCash.h"
#include "CimCashDAO.h"
#include "ordcltn.h"
#include "system/db/all.h"
#include "DataSearcher.h"
#include "util.h"
#include "Audit.h"
#include "MessageHandler.h"
#include "system/util/all.h"
#include "CimManager.h"
#include "Cim.h"
#include "DAOExcepts.h"
#include "ZCloseManager.h"

static id singleInstance = NULL;

@implementation CimCashDAO

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
- (void) loadAcceptorsByCashId: (id) aCash
{
	id obj;
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "acceptor_by_cash" filter: "" orderFields: "CASH_ID"];
	
	[myRecordSet open]; 
	[myRecordSet moveBeforeFirst];

	while ( [myRecordSet moveNext] ) {
		if (([myRecordSet getShortValue: "CASH_ID"] == [aCash getCimCashId]) && ([myRecordSet getCharValue: "DELETED"] == FALSE)) {
			obj = [[[CimManager getInstance] getCim] getAcceptorSettingsById: [myRecordSet getShortValue: "ACCEPTOR_ID"]];
			assert(obj);
			[aCash addAcceptorSettings: obj];
		}
	}

	[myRecordSet free];
}

/**/
- (id) newFromRecordSet: (id) aRecordSet
{
	CIM_CASH obj;
	char buffer[30];
	DOOR door;

	obj = [CimCash new];

	[obj setCimCashId: [aRecordSet getShortValue: "CASH_ID"]];

	door = [[CimManager getInstance] getDoorById: [aRecordSet getShortValue: "DOOR_ID"]];
	[obj setDoor: door];

	[obj setName: [aRecordSet getStringValue: "NAME" buffer: buffer]];
	[obj setDepositType: [aRecordSet getCharValue: "DEPOSIT_TYPE"]];
	[obj setDeleted: [aRecordSet getCharValue: "DELETED"]];

	// Toma los acceptors de este cash
	[self loadAcceptorsByCashId: obj];

	return obj;
}

/**/
- (COLLECTION) loadAll
{
	COLLECTION collection = [Collection new];
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "cim_cash" filter: "" orderFields: "CASH_ID"];
	id obj;
	
	[myRecordSet open]; 
	
	while ( [myRecordSet moveNext] ) {
		// agrego el cash a la coleccion
		obj = [self newFromRecordSet: myRecordSet];
		[collection add: obj];
	}

	[myRecordSet free];
  
	return collection;
}

/**/
- (id) loadById: (unsigned long) anId
{
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "cim_cash" filter: "" orderFields: "CASH_ID"];
	
	id obj = NULL;

	[myRecordSet open];

	if ([myRecordSet findById: "CASH_ID" value: anId]) {
		obj = [self newFromRecordSet: myRecordSet];
		if (![obj isDeleted])	return obj;
	}
  
	[myRecordSet free];
  
	return NULL;
}

- (void) addAcceptorByCash: (int) aCashId acceptorId: (int) anAcceptorId
{
	AUDIT audit;
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSetWithFilter: "acceptor_by_cash" filter: "" orderFields: "CASH_ID"];
	ABSTRACT_RECORDSET myRecordSetBck;

//	doLog(0,"acashId = %d\n", aCashId);

	[myDataSearcher setRecordSet: myRecordSet];
	[myDataSearcher addShortFilter: "CASH_ID" operator: "=" value: aCashId];
	[myDataSearcher addShortFilter: "ACCEPTOR_ID" operator: "=" value: anAcceptorId];
	[myDataSearcher addCharFilter: "DELETED" operator: "=" value: FALSE];

	TRY

		[myRecordSet open];

    if ([myDataSearcher find]) THROW(DAO_DUPLICATED_ACCEPTOR_BY_CASH_EX);    

		audit = [[Audit new] initAuditWithCurrentUser: 	EVENT_NEW_ACCEPTOR_BY_CASH additional: "" station: 0 logRemoteSystem: TRUE];

    [audit logChangeAsString: FALSE
													resourceId: RESID_Cash_CASH_ID 
													oldValue: "" 
													newValue: [[[[CimManager getInstance] getCim] getCimCashById: aCashId] getName] 
													oldReference: 0 
													newReference: aCashId];

    [audit logChangeAsString: FALSE
													resourceId: RESID_ACCEPTOR_ID 
													oldValue: "" 
													newValue: [[[[CimManager getInstance] getCim] getAcceptorSettingsById: anAcceptorId] getAcceptorName]  
													oldReference: 0 
													newReference: anAcceptorId];

		[myRecordSet add];

		[myRecordSet setShortValue: "CASH_ID" value: aCashId];
		[myRecordSet setShortValue: "ACCEPTOR_ID" value: anAcceptorId];
		[myRecordSet setCharValue: "DELETED" value: FALSE];
		
		[myRecordSet save];

		[audit saveAudit];
		[audit free];

		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "acceptor_by_cash_bck"]) {
			myRecordSetBck = [dbConnection createRecordSet: "acceptor_by_cash_bck"];

			[self doAddBackup: myRecordSetBck currentRecordSet: myRecordSet tableName: "acceptor_by_cash_bck"];
		}

	FINALLY

		[myRecordSet free];

	END_TRY
}

- (void) removeAcceptorByCash: (int) aCashId acceptorId: (int) anAcceptorId
{
	AUDIT audit;
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	DATA_SEARCHER myDataSearcherBck = [DataSearcher new];
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSetWithFilter: "acceptor_by_cash" filter: "" orderFields: "CASH_ID"];
	ABSTRACT_RECORDSET myRecordSetBck;

	[myDataSearcher setRecordSet: myRecordSet];
	[myDataSearcher addShortFilter: "CASH_ID" operator: "=" value: aCashId];
	[myDataSearcher addShortFilter: "ACCEPTOR_ID" operator: "=" value: anAcceptorId];
	[myDataSearcher addCharFilter: "DELETED" operator: "=" value: FALSE];

	TRY

		[myRecordSet open];

    if (![myDataSearcher find]) THROW(DAO_ACCEPTOR_BY_CASH_REFERENCE_NOT_FOUND_EX);    

		audit = [[Audit new] initAuditWithCurrentUser: 	EVENT_REMOVE_ACCEPTOR_BY_CASH additional: "" station: 0 logRemoteSystem: TRUE];
	
    [audit logChangeAsString: FALSE
													resourceId: RESID_Cash_CASH_ID 
													oldValue: "" 
													newValue: [[[[CimManager getInstance] getCim] getCimCashById: aCashId] getName] 
													oldReference: 0 
													newReference: aCashId];

    [audit logChangeAsString: FALSE
													resourceId: RESID_ACCEPTOR_ID 
													oldValue: "" 
													newValue: [[[[CimManager getInstance] getCim] getAcceptorSettingsById: anAcceptorId] getAcceptorName] 
													oldReference: 0 
													newReference: anAcceptorId];

		[myRecordSet setCharValue: "DELETED" value: TRUE];
		
		[myRecordSet save];

		[audit saveAudit];
		[audit free];

		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "acceptor_by_cash_bck"]) {
			myRecordSetBck = [dbConnection createRecordSet: "acceptor_by_cash_bck"];

			[myDataSearcherBck setRecordSet: myRecordSetBck];
			[myDataSearcherBck addShortFilter: "CASH_ID" operator: "=" value: aCashId];
			[myDataSearcherBck addShortFilter: "ACCEPTOR_ID" operator: "=" value: anAcceptorId];
			[myDataSearcherBck addCharFilter: "DELETED" operator: "=" value: FALSE];

			[self doUpdateBackup: myRecordSetBck currentRecordSet: myRecordSet dataSearcher: myDataSearcherBck tableName: "acceptor_by_cash_bck"];
		}

	FINALLY

		[myRecordSet free];

	END_TRY
}

/**/
- (void) validateFields: (id) anObject
{

	if (strlen([anObject getName]) == 0)
		THROW(DAO_CASH_NAME_NULLED_EX);

	if ([anObject getDoor] == NULL)
		THROW(DAO_CASH_DOOR_NULLED_EX);

}

/**/
- (void) store: (id) anObject
{
	int cashId;
  AUDIT audit;
  char buffer[61];  
  int i;	
	char oldDoorStr[40];
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSetWithFilter: "cim_cash" filter: "" orderFields: "CASH_ID"];
	ABSTRACT_RECORDSET myRecordSetBck;
	volatile BOOL updateRecord = FALSE;

	[myDataSearcher setRecordSet: myRecordSet];
	[myDataSearcher addShortFilter: "CASH_ID" operator: "!=" value: [anObject getCimCashId]];  
	[myDataSearcher addStringFilter: "NAME" operator: "=" value: [anObject getName]];
	[myDataSearcher addCharFilter: "DELETED" operator: "=" value: FALSE];

	[myRecordSet open];

  if ([myDataSearcher find]) THROW(DAO_DUPLICATED_CIM_CASH_EX);    

	[self validateFields: anObject];

	TRY

  // Audito
  if ([anObject isDeleted]) {
		updateRecord = TRUE;
    audit = [[Audit new] initAuditWithCurrentUser: EVENT_DELETE_CASH additional: [anObject getName] station: [anObject getCimCashId]  logRemoteSystem: TRUE];
		[myRecordSet findById: "CASH_ID" value: [anObject getCimCashId]];
  } else if ([anObject getCimCashId] != 0) {
		updateRecord = TRUE;
    [myRecordSet findById: "CASH_ID" value: [anObject getCimCashId]];
    audit = [[Audit new] initAuditWithCurrentUser: EVENT_EDIT_CASH additional: "" station: [anObject getCimCashId] logRemoteSystem: TRUE];
	} else {
		[myRecordSet add];
		audit = [[Audit new] initAuditWithCurrentUser: EVENT_NEW_CASH additional: "" station: 0 logRemoteSystem: TRUE];
	}

    /// LOG DE CAMBIOS 
    if (![anObject isDeleted]) {
      [audit logChangeAsString: RESID_Cash_NAME oldValue: [myRecordSet getStringValue: "NAME" buffer: buffer] newValue: [anObject getName]];

			oldDoorStr[0] = '\0';
			
			if ([anObject getCimCashId] != 0) 
				strcpy(oldDoorStr, [[[[CimManager getInstance] getCim] getDoorById: [myRecordSet getShortValue: "DOOR_ID"]] getDoorName]);

      [audit logChangeAsString: FALSE
														resourceId: RESID_Cash_DOOR_ID 
														oldValue: oldDoorStr
														newValue: [[[[CimManager getInstance] getCim] getDoorById: [[anObject getDoor] getDoorId]] getDoorName] 
														oldReference: [myRecordSet getShortValue: "DOOR_ID"] 
														newReference: [[anObject getDoor] getDoorId]];                            

			[audit logChangeAsResourceString: FALSE
																				resourceId: RESID_Cash_DEPOSIT_TYPE 
																				resourceStringBase: RESID_Cash_DEPOSIT_TYPE
																				oldValue: [myRecordSet getCharValue: "DEPOSIT_TYPE"]
																				newValue: [anObject getDepositType]
																			  oldReference: [myRecordSet getCharValue: "DEPOSIT_TYPE"]
																				newReference: [anObject getDepositType]];		
    }

		[myRecordSet setStringValue: "NAME" value: [anObject getName]];
		[myRecordSet setShortValue: "DOOR_ID" value: [[anObject getDoor] getDoorId]];
		[myRecordSet setCharValue: "DEPOSIT_TYPE" value: [anObject getDepositType]];
		[myRecordSet setCharValue: "DELETED" value: [anObject isDeleted]];
		
		cashId = [myRecordSet save];

		[audit setStation: cashId];
    [audit saveAudit];  
    [audit free];

		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "cim_cash_bck"]) {
			myRecordSetBck = [dbConnection createRecordSetWithFilter: "cim_cash_bck" filter: "" orderFields: "CASH_ID"];
	
			if (updateRecord) [self doUpdateBackupById: "CASH_ID" value: cashId backupRecordSet: myRecordSetBck currentRecordSet: myRecordSet tableName: "cim_cash_bck"];
			else [self doAddBackup: myRecordSetBck currentRecordSet: myRecordSet tableName: "cim_cash_bck"];
		}

		// Si esta agregando un cash debe almacenar los aceptadores
		if ([anObject getCimCashId] == 0) {
		
			[[[CimManager getInstance] getCim] addCimCash: anObject];	

			for (i=0; i<[[anObject getAcceptorSettingsList] size]; ++i) 
				[self addAcceptorByCash: cashId acceptorId: [[[anObject getAcceptorSettingsList] at: i] getAcceptorId]];
			
			[[ZCloseManager getInstance] addNewCashClose: anObject];

		} else {
			
			if ([anObject isDeleted]) {

				for (i=0; i<[[anObject getAcceptorSettingsList] size]; ++i) 
					[self removeAcceptorByCash: cashId acceptorId: [[[anObject getAcceptorSettingsList] at: i] getAcceptorId]];

			}

		}

		[anObject setCimCashId: cashId];
		
	FINALLY

		[myRecordSet free];
	
	END_TRY
}

@end
