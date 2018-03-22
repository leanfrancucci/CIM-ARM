#include "CommercialStateDAO.h"
#include "CommercialState.h"
#include "SettingsExcepts.h"
#include "system/db/all.h"
#include "Audit.h"
#include "MessageHandler.h"
#include "Event.h"
#include "util.h"

static id singleInstance = NULL;

@implementation CommercialStateDAO

- (id) newCommercialStateFromRecordSet: (id) aRecordSet; 

/**/
+ new
{
	if (!singleInstance) singleInstance = [super new];
	return singleInstance;
}

/**/
- initialize
{
	[super initialize];
	return self;
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

/*
 *	Devuelve el estado comercial del sistema en base a la informacion del registro actual del recordset.
 */
- (id) newCommercialStateFromRecordSet: (id) aRecordSet
{
	COMMERCIAL_STATE obj;
	char buffer[60];
	
	obj = [CommercialState new];

	[obj setCommercialStateId: [aRecordSet getShortValue: "COMMERCIAL_STATE_ID"]];
	
	//doLog(0,"%s", "/********************************************************/\n");
	//doLog(0,"Estado de la caja = %d\n", [aRecordSet getShortValue: "STATE"]);
	//doLog(0,"%s", "/********************************************************/\n");
	
	[obj setCommState: [aRecordSet getShortValue: "STATE"]];
	[obj setOldState: [aRecordSet getShortValue: "OLD_STATE"]];
	[obj setCommercialMode: [aRecordSet getCharValue: "COMMERCIAL_MODE"]];
	[obj setRemoteUnitsQty: [aRecordSet getShortValue: "REMOTE_UNITS_QTY"]];
	[obj setHoursQty: [aRecordSet getShortValue: "HOURS_QTY"]];
  [obj setExpireDateTime: [aRecordSet getDateTimeValue: "EXPIRE_DATE"]];
  [obj setAuthorizationId: [aRecordSet getLongValue: "AUTHORIZATION_ID"]];
  [obj setRequestDateTime: [aRecordSet getDateTimeValue: "REQUEST_DATE_TIME"]];
  [obj setRemoteSignatureLen: [aRecordSet getCharValue: "REMOTE_SIGNATURE_LEN"]];
	[obj setRemoteSignature: [aRecordSet getCharArrayValue: "REMOTE_SIGNATURE" buffer: buffer] remoteSignatureLen: [aRecordSet getCharValue: "REMOTE_SIGNATURE_LEN"]];
  [obj setActive: [aRecordSet getCharValue: "ACTIVE"]];
  [obj setElapsedTime: [aRecordSet getLongValue: "TIME_ELAPSED"]];
	[obj setStartDateTime: [aRecordSet getDateTimeValue: "START_DATE_TIME"]];

	return obj;
}

/**/
- (id) loadById: (unsigned long) anId
{

	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSet: "commercial_state"];
	id obj = NULL;

	[myRecordSet open];

	if ([myRecordSet findById: "COMMERCIAL_STATE_ID" value: anId]) {
		obj = [self newCommercialStateFromRecordSet: myRecordSet];
		[myRecordSet free];
		return obj;
	}

	[myRecordSet free];
	THROW(REFERENCE_NOT_FOUND_EX);
	return NULL;
}

/**/
- (COLLECTION) loadAll
{
	COLLECTION collection = [Collection new];
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSet: "commercial_state"];
	id obj;

	[myRecordSet open]; 
	
	while ( [myRecordSet moveNext] ) {
		
		obj = [self newCommercialStateFromRecordSet: myRecordSet];
		[collection add: obj];

	}

	[myRecordSet free];
	return collection;
}

/**/
- (void) store: (id) anObject
{
	
  AUDIT audit;
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSet: "commercial_state"];
	ABSTRACT_RECORDSET myRecordSetBck;

	[self validateFields: anObject];	

	TRY

	[myRecordSet open];

	if ([anObject getCommercialStateId] != 0) {
    if (![myRecordSet findById: "COMMERCIAL_STATE_ID" value: [anObject getCommercialStateId]]) THROW(REFERENCE_NOT_FOUND_EX);
	} 


  // Audito
  	audit = [[Audit new] initAuditWithCurrentUser: Event_EDIT_COMMERCIAL_STATE additional: "" station: [anObject getCommercialStateId] logRemoteSystem: FALSE];

  /// LOG DE CAMBIOS 
		[audit logChangeAsResourceString: FALSE
																			resourceId: RESID_CommercialState_STATE 
																			resourceStringBase: RESID_CommercialState_STATE
																			oldValue: [myRecordSet getShortValue: "STATE"]
																			newValue: [anObject getCommState]
																			oldReference: [myRecordSet getShortValue: "STATE"]
																			newReference: [anObject getCommState]];		

		[audit logChangeAsResourceString: FALSE
																			resourceId: RESID_CommercialState_OLD_STATE 
																			resourceStringBase: RESID_CommercialState_STATE 
																			oldValue: [myRecordSet getShortValue: "OLD_STATE"]
																			newValue: [anObject getOldState]
																			oldReference: [myRecordSet getShortValue: "OLD_STATE"]
																			newReference: [anObject getOldState]];		

		[audit logChangeAsResourceString: FALSE
																			resourceId: RESID_CommercialState_COMMERCIAL_MODE 
																			resourceStringBase: RESID_CommercialState_COMMERCIAL_MODE 
																			oldValue: [myRecordSet getCharValue: "COMMERCIAL_MODE"]
																			newValue: [anObject getCommercialMode]
																			oldReference: [myRecordSet getShortValue: "COMMERCIAL_MODE"]
																			newReference: [anObject getCommercialMode]];		

    [audit logChangeAsInteger: RESID_CommercialState_REMOTE_UNITS_QTY oldValue: [myRecordSet getShortValue: "REMOTE_UNITS_QTY"] newValue: [anObject getRemoteUnitsQty]];
    [audit logChangeAsInteger: RESID_CommercialState_HOURS_QTY oldValue: [myRecordSet getShortValue: "HOURS_QTY"] newValue: [anObject getHoursQty]];
    [audit logChangeAsDateTime: RESID_CommercialState_EXPIRE_DATE oldValue: [myRecordSet getDateTimeValue: "EXPIRE_DATE"] newValue: [anObject getExpireDateTime]];
    [audit logChangeAsInteger: RESID_CommercialState_AUTHORIZATION_ID oldValue: [myRecordSet getLongValue: "AUTHORIZATION_ID"] newValue: [anObject getAuthorizationId]];
    [audit logChangeAsDateTime: RESID_CommercialState_REQUEST_DATE oldValue: [myRecordSet getDateTimeValue: "REQUEST_DATE_TIME"] newValue: [anObject getRequestDateTime]];
    [audit logChangeAsInteger: RESID_CommercialState_ACTIVE oldValue: [myRecordSet getCharValue: "ACTIVE"] newValue: [anObject isActive]];
    [audit logChangeAsDateTime: RESID_CommercialState_START_DATE_TIME oldValue: [myRecordSet getDateTimeValue: "START_DATE_TIME"] newValue: [anObject getStartDateTime]];

		[myRecordSet setShortValue: "STATE" value: [anObject getCommState]];
		[myRecordSet setShortValue: "OLD_STATE" value: [anObject getOldState]];
		[myRecordSet setCharValue: "COMMERCIAL_MODE" value: [anObject getCommercialMode]];
		[myRecordSet setShortValue: "REMOTE_UNITS_QTY" value: [anObject getRemoteUnitsQty]];
		[myRecordSet setShortValue: "HOURS_QTY" value: [anObject getHoursQty]];
		[myRecordSet setDateTimeValue: "EXPIRE_DATE" value: [anObject getExpireDateTime]];
 		[myRecordSet setLongValue: "AUTHORIZATION_ID" value: [anObject getAuthorizationId]];
		[myRecordSet setDateTimeValue: "REQUEST_DATE_TIME" value: [anObject getRequestDateTime]];
		[myRecordSet setCharValue: "REMOTE_SIGNATURE_LEN" value: [anObject getRemoteSignatureLen]];
		[myRecordSet setCharArrayValue: "REMOTE_SIGNATURE" value: [anObject getRemoteSignature]];
 		[myRecordSet setCharValue: "ACTIVE" value: [anObject isActive]];
		[myRecordSet setLongValue: "TIME_ELAPSED" value: [anObject getElapsedTime]];
		[myRecordSet setDateTimeValue: "START_DATE_TIME" value: [anObject getStartDateTime]];

	//	doLog(0,"comienza a guardar el cambio de estado\n");

		[myRecordSet save];

	//doLog(0,"%s", "/********************************************************/\n");
	//doLog(0,"Estado de la caja luego de guardar = %d\n", [myRecordSet getShortValue: "STATE"]);
	//doLog(0,"%s", "/********************************************************/\n");

    [audit saveAudit];  
    [audit free];

		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "commercial_state_bck"]) {
			myRecordSetBck = [dbConnection createRecordSet: "commercial_state_bck"];
	
			[self doUpdateBackupById: "COMMERCIAL_STATE_ID" value: [anObject getCommercialStateId] backupRecordSet: myRecordSetBck currentRecordSet: myRecordSet tableName: "commercial_state_bck"];
		}

	FINALLY

		//doLog(0,"Ha surgido una excepcion al guardar el cambio de estado\n");
		//ex_printfmt();
		[myRecordSet free];

	END_TRY
}


/**/
- (void) storeCommercialStateElapsedTime: (id) anObject
{
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSet: "commercial_state"];
	ABSTRACT_RECORDSET myRecordSetBck;

	TRY

		[myRecordSet open];
	
		if ([anObject getCommercialStateId] != 0) {
			if (![myRecordSet findById: "COMMERCIAL_STATE_ID" value: [anObject getCommercialStateId]]) THROW(REFERENCE_NOT_FOUND_EX);
		} 

		[myRecordSet setLongValue: "TIME_ELAPSED" value: [anObject getElapsedTime]];

		[myRecordSet save];

		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "commercial_state_bck"]) {
			myRecordSetBck = [dbConnection createRecordSet: "commercial_state_bck"];
	
			[self doUpdateBackupById: "COMMERCIAL_STATE_ID" value: [anObject getCommercialStateId] backupRecordSet: myRecordSetBck currentRecordSet: myRecordSet tableName: "commercial_state_bck"];
		}

	FINALLY

//		doLog(0,"Ha surgido una excepcion al guardar el cambio de estado\n");
//		ex_printfmt();
		[myRecordSet free];

	END_TRY


}

/**/
- (void) validateFields: (id) anObject
{
	/*
		Validacion de rangos en cuanto a los valores que presentan restricciones
		state = 1..4
	*/

/*
	if ( ( ([anObject getCommState] < 1) || ([anObject getCommState] > 4) ) )
		THROW(DAO_OUT_OF_RANGE_VALUE_EX);
*/
}

@end
