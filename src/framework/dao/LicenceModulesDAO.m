#include "LicenceModulesDAO.h"
#include "SettingsExcepts.h"
#include "system/db/all.h"
#include "Audit.h"
#include "MessageHandler.h"
#include "Event.h"
#include "util.h"
#include "Module.h"

static id singleInstance = NULL;

@implementation LicenceModulesDAO

- (id) newFromRecordSet: (id) aRecordSet; 

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

/**/
- (id) newFromRecordSet: (id) aRecordSet
{
	MODULE obj;
	char buffer[60];
	
	obj = [Module new];

	[obj setModuleId: [aRecordSet getShortValue: "LICENCE_MODULE_ID"]];
	[obj setModuleCode: [aRecordSet getShortValue: "CODE"]];
  [obj setBaseDateTime: [aRecordSet getDateTimeValue: "BASE_DATE"]];
  [obj setExpireDateTime: [aRecordSet getDateTimeValue: "EXPIRE_DATE"]];
	[obj setHoursQty: [aRecordSet getShortValue: "HOURS_QTY"]];
	[obj setOnline: [aRecordSet getCharValue: "ONLINE"]];
  [obj setRemoteSignatureLen: [aRecordSet getCharValue: "REMOTE_SIGNATURE_LEN"]];
	[obj setRemoteSignature: [aRecordSet getCharArrayValue: "REMOTE_SIGNATURE" buffer: buffer] remoteSignatureLen: [aRecordSet getCharValue: "REMOTE_SIGNATURE_LEN"]];
  [obj setAuthorizationId: [aRecordSet getLongValue: "AUTHORIZATION_ID"]];
  [obj setElapsedTime: [aRecordSet getLongValue: "TIME_ELAPSED"]];
  [obj setEnable: [aRecordSet getCharValue: "ENABLE"]];

//	[obj printInfo];

	return obj;
}

/**/
- (id) loadById: (unsigned long) anId
{

	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSet: "licence_modules"];
	id obj = NULL;

	[myRecordSet open];

	if ([myRecordSet findById: "LICENCE_MODULE_ID" value: anId]) {
		obj = [self newFromRecordSet: myRecordSet];
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
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSet: "licence_modules"];
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
- (void) store: (id) anObject
{
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSet: "licence_modules"];
	ABSTRACT_RECORDSET myRecordSetBck;
  AUDIT audit;

	TRY

	[myRecordSet open];

	if ([anObject getModuleId] != 0) {
    if (![myRecordSet findById: "LICENCE_MODULE_ID" value: [anObject getModuleId]]) THROW(REFERENCE_NOT_FOUND_EX);
	} 

  // Audito
  	audit = [[Audit new] initAuditWithCurrentUser: Event_EDIT_LICENCE_MODULE additional: [anObject getModuleName] station: [anObject getModuleCode] logRemoteSystem: FALSE];

  // LOG DE CAMBIOS 
    [audit logChangeAsDateTime: RESID_Module_BASE_DATE_TIME oldValue: [myRecordSet getDateTimeValue: "BASE_DATE"] newValue: [anObject getBaseDateTime]];
    [audit logChangeAsDateTime: RESID_Module_EXPIRE_DATE_TIME oldValue: [myRecordSet getDateTimeValue: "EXPIRE_DATE"] newValue: [anObject getExpireDateTime]];
    [audit logChangeAsInteger: RESID_Module_HOURS_QTY oldValue: [myRecordSet getShortValue: "HOURS_QTY"] newValue: [anObject getHoursQty]];
		[audit logChangeAsBoolean: FALSE resourceId: RESID_Module_ONLINE oldValue: [myRecordSet getCharValue: "ONLINE"] newValue: [anObject getOnline]];
    [audit logChangeAsInteger: RESID_Module_AUTHORIZATION_ID oldValue: [myRecordSet getLongValue: "AUTHORIZATION_ID"] newValue: [anObject getAuthorizationId]];
    [audit logChangeAsInteger: RESID_Module_TIME_ELAPSED oldValue: [myRecordSet getLongValue: "TIME_ELAPSED"] newValue: [anObject getElapsedTime]];
		[audit logChangeAsBoolean: FALSE resourceId: RESID_Module_ENABLE oldValue: [myRecordSet getCharValue: "ENABLE"] newValue: [anObject isEnable]];

		[myRecordSet setShortValue: "CODE" value: [anObject getModuleCode]];
		[myRecordSet setDateTimeValue: "BASE_DATE" value: [anObject getBaseDateTime]];
		[myRecordSet setDateTimeValue: "EXPIRE_DATE" value: [anObject getExpireDateTime]];
		[myRecordSet setShortValue: "HOURS_QTY" value: [anObject getHoursQty]];
		[myRecordSet setCharValue: "ONLINE" value: [anObject getOnline]];
		[myRecordSet setCharValue: "REMOTE_SIGNATURE_LEN" value: [anObject getRemoteSignatureLen]];
		[myRecordSet setCharArrayValue: "REMOTE_SIGNATURE" value: [anObject getRemoteSignature]];
 		[myRecordSet setLongValue: "AUTHORIZATION_ID" value: [anObject getAuthorizationId]];
		[myRecordSet setLongValue: "TIME_ELAPSED" value: [anObject getElapsedTime]];
            printf("10\n");

        
 		[myRecordSet setCharValue: "ENABLE" value: [anObject isEnable]];

		[myRecordSet save];

    [audit saveAudit];  
    [audit free];

		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "licence_modules_bck"]) {
			myRecordSetBck = [dbConnection createRecordSet: "licence_modules_bck"];
	
			[self doUpdateBackupById: "LICENCE_MODULE_ID" value: [anObject getModuleId] backupRecordSet: myRecordSetBck currentRecordSet: myRecordSet tableName: "licence_modules_bck"];
		}

	FINALLY

		[myRecordSet free];

	END_TRY
}


/**/
- (void) storeModuleElapsedTime: (id) anObject
{
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSet: "licence_modules"];
	ABSTRACT_RECORDSET myRecordSetBck;

	TRY

		[myRecordSet open];
	
		if ([anObject getModuleId] != 0) {
			if (![myRecordSet findById: "LICENCE_MODULE_ID" value: [anObject getModuleId]]) THROW(REFERENCE_NOT_FOUND_EX);
		} 

		[myRecordSet setLongValue: "TIME_ELAPSED" value: [anObject getElapsedTime]];

		[myRecordSet save];

		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "licence_modules_bck"]) {
			myRecordSetBck = [dbConnection createRecordSet: "licence_modules_bck"];
	
			[self doUpdateBackupById: "LICENCE_MODULE_ID" value: [anObject getModuleId] backupRecordSet: myRecordSetBck currentRecordSet: myRecordSet tableName: "licence_modules_bck"];
		}

	FINALLY

		[myRecordSet free];

	END_TRY


}

@end
