#include "Box.h"
#include "BoxDAO.h"
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

static id singleInstance = NULL;

@implementation BoxDAO

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
- (void) loadAcceptorsByBoxId: (id) aBox
{
	id obj;
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "acceptor_by_box" filter: "" orderFields: "BOX_ID"];
	
	[myRecordSet open]; 
	[myRecordSet moveBeforeFirst];

	while ( [myRecordSet moveNext] ) {
		if (([myRecordSet getShortValue: "BOX_ID"] == [aBox getBoxId]) && ([myRecordSet getCharValue: "DELETED"] == FALSE)) {
			obj = [[[CimManager getInstance] getCim] getAcceptorSettingsById: [myRecordSet getShortValue: "ACCEPTOR_ID"]];
			if (obj) [aBox addAcceptorSettings: obj];
		}
	}

	[myRecordSet free];
}

/**/
- (void) loadDoorsByBoxId: (id) aBox
{
	id obj;
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "door_by_box" filter: "" orderFields: "BOX_ID"];
	
	[myRecordSet open]; 
	[myRecordSet moveBeforeFirst];

	while ( [myRecordSet moveNext] ) {
		if (([myRecordSet getShortValue: "BOX_ID"] == [aBox getBoxId]) && ([myRecordSet getCharValue: "DELETED"] == FALSE)) {
			obj = [[[CimManager getInstance] getCim] getDoorById: [myRecordSet getShortValue: "DOOR_ID"]];
			if (obj) [aBox addDoor: obj];
		}
	}

	[myRecordSet free];

}

/**/
- (id) newFromRecordSet: (id) aRecordSet
{
	BOX obj;
	char buffer[60];

	obj = [Box new];

	[obj setBoxId: [aRecordSet getShortValue: "BOX_ID"]];
	[obj setName: [aRecordSet getStringValue: "NAME" buffer: buffer]];
	[obj setBoxModel: [aRecordSet getStringValue: "MODEL" buffer: buffer]];

	//printf(" model = %s\n", buffer);
	
	[obj setDeleted: [aRecordSet getCharValue: "DELETED"]];

	// Toma los acceptors de esta caja.
	[self loadAcceptorsByBoxId: obj];

	// Toma las puertas de esta caja.
	[self loadDoorsByBoxId: obj];

	return obj;
}

/**/
- (COLLECTION) loadAll
{
	COLLECTION collection = [Collection new];
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "box" filter: "" orderFields: "BOX_ID"];
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
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "box" filter: "" orderFields: "BOX_ID"];
	
	id obj = NULL;

	[myRecordSet open];

	if ([myRecordSet findById: "BOX_ID" value: anId]) {
		obj = [self newFromRecordSet: myRecordSet];
		if (![obj isDeleted])	return obj;
	} 
  
	[myRecordSet free];
  
	return NULL;
}

/**/
- (char *) loadModelFromBackupById: (unsigned long) anId model: (char*) aModel
{
	ABSTRACT_RECORDSET recordSetBck = [[DBConnection getInstance] createRecordSetWithFilter: "box_bck" filter: "" orderFields: "BOX_ID"];

	[recordSetBck open];

	if ([recordSetBck findById: "BOX_ID" value: anId]) {
		[recordSetBck getStringValue: "MODEL" buffer: aModel];
	}
	[recordSetBck close];
	[recordSetBck free];
  
	return aModel;
}

/**/
- (void) addAcceptorByBox: (int) aBoxId acceptorId: (int) anAcceptorId
{
	AUDIT audit;
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSetWithFilter: "acceptor_by_box" filter: "" orderFields: "BOX_ID"];
	ABSTRACT_RECORDSET myRecordSetBck;

	// Busca si el acceptor existe 
	[myDataSearcher setRecordSet: myRecordSet];
	[myDataSearcher addShortFilter: "ACCEPTOR_ID" operator: "=" value: anAcceptorId];
	[myDataSearcher addCharFilter: "DELETED" operator: "=" value: FALSE];

	TRY

		[myRecordSet open];

    if ([myDataSearcher find]) THROW(DAO_DUPLICATED_ACCEPTOR_BY_BOX_EX);

		audit = [[Audit new] initAuditWithCurrentUser: 	EVENT_ADD_ACCEPTOR_BY_BOX additional: "" station: 0 logRemoteSystem: TRUE];
	
    [audit logChangeAsString: FALSE
													resourceId: RESID_AcceptorByBox_BOX_ID 
													oldValue: "" 
													newValue: [[[[CimManager getInstance] getCim] getBoxById: aBoxId] getName] 
													oldReference: 0 
													newReference: aBoxId];

    [audit logChangeAsString: FALSE
													resourceId: RESID_AcceptorByBox_ACCEPTOR_ID 
													oldValue: "" 
													newValue: [[[[CimManager getInstance] getCim] getAcceptorSettingsById: anAcceptorId] getAcceptorName]  
													oldReference: 0 
													newReference: anAcceptorId];


		[myRecordSet add];

		[myRecordSet setShortValue: "BOX_ID" value: aBoxId];
		[myRecordSet setShortValue: "ACCEPTOR_ID" value: anAcceptorId];
		[myRecordSet setCharValue: "DELETED" value: FALSE];
		
		[myRecordSet save];

    [audit saveAudit];
    [audit free];

		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "acceptor_by_box_bck"]) {
			myRecordSetBck = [dbConnection createRecordSet: "acceptor_by_box_bck"];

			[self doAddBackup: myRecordSetBck currentRecordSet: myRecordSet tableName: "acceptor_by_box_bck"];
		}

	FINALLY

		[myRecordSet free];

	END_TRY
}

/**/
- (void) removeAcceptorByBox: (int) aBoxId acceptorId: (int) anAcceptorId
{
	AUDIT audit;
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	DATA_SEARCHER myDataSearcherBck = [DataSearcher new];
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSetWithFilter: "acceptor_by_box" filter: "" orderFields: "BOX_ID"];
	ABSTRACT_RECORDSET myRecordSetBck;

	[myDataSearcher setRecordSet: myRecordSet];
	[myDataSearcher addShortFilter: "BOX_ID" operator: "=" value: aBoxId];
	[myDataSearcher addShortFilter: "ACCEPTOR_ID" operator: "=" value: anAcceptorId];
	[myDataSearcher addCharFilter: "DELETED" operator: "=" value: FALSE];

	TRY

		[myRecordSet open];

    if (![myDataSearcher find]) THROW(DAO_ACCEPTOR_BY_BOX_NOT_FOUND_EX);

		audit = [[Audit new] initAuditWithCurrentUser: 	EVENT_REMOVE_ACCEPTOR_BY_BOX additional: "" station: 0 logRemoteSystem: TRUE];
	
    [audit logChangeAsString: FALSE
													resourceId: RESID_AcceptorByBox_BOX_ID 
													oldValue: [[[[CimManager getInstance] getCim] getBoxById: aBoxId] getName] 
													newValue: ""
													oldReference: aBoxId 
													newReference: 0];

    [audit logChangeAsString: FALSE
													resourceId: RESID_AcceptorByBox_ACCEPTOR_ID 
													oldValue: [[[[CimManager getInstance] getCim] getAcceptorSettingsById: anAcceptorId] getAcceptorName] 
													newValue: ""  
													oldReference: anAcceptorId 
													newReference: 0];

		[myRecordSet setCharValue: "DELETED" value: TRUE];
		[myRecordSet save];

		[audit saveAudit];
		[audit free];

		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "acceptor_by_box_bck"]) {
			myRecordSetBck = [dbConnection createRecordSet: "acceptor_by_box_bck"];

			[myDataSearcherBck setRecordSet: myRecordSetBck];
			[myDataSearcherBck addShortFilter: "BOX_ID" operator: "=" value: aBoxId];
			[myDataSearcherBck addShortFilter: "ACCEPTOR_ID" operator: "=" value: anAcceptorId];
			[myDataSearcherBck addCharFilter: "DELETED" operator: "=" value: FALSE];

			[self doUpdateBackup: myRecordSetBck currentRecordSet: myRecordSet dataSearcher: myDataSearcherBck tableName: "acceptor_by_box_bck"];
		}

	FINALLY

		[myRecordSet free];

	END_TRY
}

/**/
- (void) addDoorByBox: (int) aBoxId doorId: (int) aDoorId
{
	AUDIT audit;
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSetWithFilter: "door_by_box" filter: "" orderFields: "BOX_ID"];
	ABSTRACT_RECORDSET myRecordSetBck;

	// Busca si el acceptor existe 
	[myDataSearcher setRecordSet: myRecordSet];
	[myDataSearcher addShortFilter: "DOOR_ID" operator: "=" value: aDoorId];
	[myDataSearcher addCharFilter: "DELETED" operator: "=" value: FALSE];

	TRY

		[myRecordSet open];

    if ([myDataSearcher find]) THROW(DAO_DUPLICATED_DOOR_BY_BOX_EX);    

		[myRecordSet add];

		audit = [[Audit new] initAuditWithCurrentUser: 	EVENT_ADD_DOOR_BY_BOX additional: "" station: 0 logRemoteSystem: TRUE];
	
    [audit logChangeAsString: FALSE
													resourceId: RESID_DoorByBox_BOX_ID 
													oldValue: "" 
													newValue: [[[[CimManager getInstance] getCim] getBoxById: aBoxId] getName] 
													oldReference: 0 
													newReference: aBoxId];

    [audit logChangeAsString: FALSE
													resourceId: RESID_DoorByBox_DOOR_ID 
													oldValue: "" 
													newValue: [[[[CimManager getInstance] getCim] getDoorById: aDoorId] getDoorName]  
													oldReference: 0 
													newReference: aDoorId];


		[myRecordSet setShortValue: "BOX_ID" value: aBoxId];
		[myRecordSet setShortValue: "DOOR_ID" value: aDoorId];
		[myRecordSet setCharValue: "DELETED" value: FALSE];
		
		[myRecordSet save];

		[audit saveAudit];	
		[audit free];

		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "door_by_box_bck"]) {
			myRecordSetBck = [dbConnection createRecordSet: "door_by_box_bck"];
			[self doAddBackup: myRecordSetBck currentRecordSet: myRecordSet tableName: "door_by_box_bck"];
		}

	FINALLY

		[myRecordSet free];

	END_TRY
}

/**/
- (void) removeDoorByBox: (int) aBoxId doorId: (int) aDoorId
{
	AUDIT audit;
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	DATA_SEARCHER myDataSearcherBck = [DataSearcher new];
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSetWithFilter: "door_by_box" filter: "" orderFields: "BOX_ID"];
	ABSTRACT_RECORDSET myRecordSetBck;

	[myDataSearcher setRecordSet: myRecordSet];
	[myDataSearcher addShortFilter: "BOX_ID" operator: "=" value: aBoxId];
	[myDataSearcher addShortFilter: "DOOR_ID" operator: "=" value: aDoorId];
	[myDataSearcher addCharFilter: "DELETED" operator: "=" value: FALSE];

	TRY

		[myRecordSet open];

    if (![myDataSearcher find]) THROW(DAO_DOOR_BY_BOX_NOT_FOUND_EX);    

		audit = [[Audit new] initAuditWithCurrentUser: 	EVENT_REMOVE_DOOR_BY_BOX additional: "" station: 0 logRemoteSystem: TRUE];
	
    [audit logChangeAsString: FALSE
													resourceId: RESID_AcceptorByBox_BOX_ID 
													oldValue: [[[[CimManager getInstance] getCim] getBoxById: aBoxId] getName] 
													newValue: ""
													oldReference: aBoxId 
													newReference: 0];

    [audit logChangeAsString: FALSE
													resourceId: RESID_AcceptorByBox_ACCEPTOR_ID 
													oldValue: [[[[CimManager getInstance] getCim] getDoorById: aDoorId] getDoorName] 
													newValue: ""  
													oldReference: aDoorId 
													newReference: 0];

		[myRecordSet setCharValue: "DELETED" value: TRUE];
		[myRecordSet save];

		[audit saveAudit];
		[audit free];

		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "door_by_box_bck"]) {
			myRecordSetBck = [dbConnection createRecordSet: "door_by_box_bck"];

			[myDataSearcherBck setRecordSet: myRecordSetBck];
			[myDataSearcherBck addShortFilter: "BOX_ID" operator: "=" value: aBoxId];
			[myDataSearcherBck addShortFilter: "DOOR_ID" operator: "=" value: aDoorId];
			[myDataSearcherBck addCharFilter: "DELETED" operator: "=" value: FALSE];

			[self doUpdateBackup: myRecordSetBck currentRecordSet: myRecordSet dataSearcher: myDataSearcherBck tableName: "door_by_box_bck"];

		}

	FINALLY

		[myRecordSet free];

	END_TRY
}


/**/
- (void) validateFields: (id) anObject
{

	if (strlen([anObject getName]) == 0)
		THROW(DAO_BOX_NAME_NULLED_EX);

}

/**/
- (void) store: (id) anObject
{
	int boxId;
  AUDIT audit;
  char buffer[61];  
  int i;
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSetWithFilter: "box" filter: "" orderFields: "BOX_ID"];
	ABSTRACT_RECORDSET myRecordSetBck;
	volatile BOOL updateRecord = FALSE;

	[myDataSearcher setRecordSet: myRecordSet];
	[myDataSearcher addShortFilter: "BOX_ID" operator: "!=" value: [anObject getBoxId]];  
	[myDataSearcher addStringFilter: "NAME" operator: "=" value: [anObject getName]];
	[myDataSearcher addCharFilter: "DELETED" operator: "=" value: FALSE];

	[myRecordSet open];

  if ([myDataSearcher find]) THROW(DAO_DUPLICATED_BOX_EX);    
	[self validateFields: anObject];

	TRY

		// Audito
		if ([anObject isDeleted]) {
			updateRecord = TRUE;
			audit = [[Audit new] initAuditWithCurrentUser: EVENT_DELETE_BOX additional: "" station: [anObject getBoxId]  logRemoteSystem: TRUE];
			[myRecordSet findById: "BOX_ID" value: [anObject getBoxId]];
		} else if ([anObject getBoxId] != 0) {
			updateRecord = TRUE;
			[myRecordSet findById: "BOX_ID" value: [anObject getBoxId]];
			audit = [[Audit new] initAuditWithCurrentUser: EVENT_EDIT_BOX additional: "" station: [anObject getBoxId] logRemoteSystem: TRUE];
		} else {
			[myRecordSet add];
			audit = [[Audit new] initAuditWithCurrentUser: EVENT_NEW_BOX additional: "" station: 0 logRemoteSystem: TRUE];
		}

    /// LOG DE CAMBIOS 
    if (![anObject isDeleted]) {
      [audit logChangeAsString: RESID_Box_NAME oldValue: [myRecordSet getStringValue: "NAME" buffer: buffer] newValue: [anObject getName]];
      [audit logChangeAsString: RESID_Box_MODEL oldValue: [myRecordSet getStringValue: "MODEL" buffer: buffer] newValue: [anObject getBoxModel]];
    }

		[myRecordSet setStringValue: "NAME" value: [anObject getName]];
		[myRecordSet setStringValue: "MODEL" value: [anObject getBoxModel]];
		[myRecordSet setCharValue: "DELETED" value: [anObject isDeleted]];
		
		boxId = [myRecordSet save];

		[audit setStation: boxId];
    [audit saveAudit];  
    [audit free];	

		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "box_bck"]) {
			myRecordSetBck = [dbConnection createRecordSetWithFilter: "box_bck" filter: "" orderFields: "BOX_ID"];
	
			if (updateRecord) [self doUpdateBackupById: "BOX_ID" value: boxId backupRecordSet: myRecordSetBck currentRecordSet: myRecordSet tableName: "box_bck"];
			else [self doAddBackup: myRecordSetBck currentRecordSet: myRecordSet tableName: "box_bck"];
		}

		// Si esta agregando una caja debe almacenar los aceptadores y puertas
		if ([anObject getBoxId] == 0) {
			
			for (i=0; i<[[anObject getAcceptorSettingsList] size]; ++i) 
				[self addAcceptorByBox: boxId acceptorId: [[[anObject getAcceptorSettingsList] at: i] getAcceptorId]];

			for (i=0; i<[[anObject getDoorsList] size]; ++i) 
				[self addDoorByBox: boxId doorId: [[[anObject getDoorsList] at: i] getDoorId]];

			
		} else {
			
			if ([anObject isDeleted]) {

				for (i=0; i<[[anObject getAcceptorSettingsList] size]; ++i) 
					[self removeAcceptorByBox: boxId acceptorId: [[[anObject getAcceptorSettingsList] at: i] getAcceptorId]];

				for (i=0; i<[[anObject getDoorsList] size]; ++i) 
					[self removeDoorByBox: boxId doorId: [[[anObject getDoorsList] at: i] getDoorId]];

			}
		}
    
		[anObject setBoxId: boxId];

	FINALLY

		[myRecordSet free];
	
	END_TRY
}

@end
