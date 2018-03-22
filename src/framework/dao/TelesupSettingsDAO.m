#include "TelesupSettingsDAO.h"
#include "TelesupSettings.h"
#include "SettingsExcepts.h"
#include "ordcltn.h"
#include "DataSearcher.h"
#include "util.h"
#include "DAOExcepts.h"
#include "TelesupDefs.h"
#include "Event.h"
#include "Audit.h"
#include "MessageHandler.h"
#include "TelesupervisionManager.h"
#include "Event.h"

static id singleInstance = NULL;

@implementation TelesupSettingsDAO

- (id) newTelFromRecordSet: (id) aRecordSet; 

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
 *	Devuelve las telesupervisiones en base a la informacion del registro actual del recordset.
 */

- (id) newTelFromRecordSet: (id) aRecordSet
{
	TELESUP_SETTINGS obj;
	char buffer[61];

	obj = [TelesupSettings new];
//	doLog(0,"CARGANDO TELESUP = %d\n", [aRecordSet getShortValue: "TELESUP_ID"]);
  [obj setTelesupId: [aRecordSet getShortValue: "TELESUP_ID"]];
  [obj setSystemId: [aRecordSet getStringValue: "SYSTEM_ID" buffer: buffer]];
	[obj setRemoteSystemId: [aRecordSet getStringValue: "REMOTE_SYSTEM_ID" buffer: buffer]];  
  [obj setTelesupDescription: [aRecordSet getStringValue: "DESCRIPTION" buffer: buffer]];  
	[obj setTelesupUserName: [aRecordSet getStringValue: "USER_NAME" buffer: buffer]];
	[obj setTelesupPassword: [aRecordSet getStringValue: "PASSWORD" buffer: buffer]];
	[obj setRemoteUserName: [aRecordSet getStringValue: "REMOTE_USER_NAME" buffer: buffer]];
	[obj setRemotePassword: [aRecordSet getStringValue: "REMOTE_PASSWORD" buffer: buffer]];
	[obj setTelcoType: [aRecordSet getCharValue: "TELCO_TYPE"]];
	[obj setTelesupFrequency: [aRecordSet getCharValue: "FREQUENCY"]];
	[obj setStartMoment: [aRecordSet getCharValue: "START_MOMENT"]];
	[obj setAttemptsQty: [aRecordSet getCharValue: "ATTEMPTS_QTY"]];
	[obj setTimeBetweenAttempts: [aRecordSet getShortValue: "TIME_BETWEEN_ATTEMPTS"]];
	[obj setMaxTimeWithoutTelAllowed: [aRecordSet getShortValue: "MAX_TIME_WOUT_TELESUP_ALLOWED"]];
	[obj setConnectionId1: [aRecordSet getShortValue: "CONNECTION_ID_1"]];
	[obj setConnectionId2: [aRecordSet getShortValue: "CONNECTION_ID_2"]];
	[obj setNextTelesupDateTime: [aRecordSet getDateTimeValue: "NEXT_TEL_DATE"]];
	[obj setLastSuceedTelesupDateTime: [aRecordSet getDateTimeValue: "LAST_SUCEED_TEL_DATE"]];
	[obj setLastTelesupCallId: [aRecordSet getLongValue: "LAST_TELESUP_CALL_ID"]];
	[obj setLastTelesupTicketId: [aRecordSet getLongValue: "LAST_TELESUP_TICKET_ID"]];
	[obj setLastTelesupAuditId: [aRecordSet getLongValue: "LAST_TELESUP_AUDIT_ID"]];
	[obj setLastTelesupMessageId: [aRecordSet getLongValue: "LAST_TELESUP_MESSAGE_ID"]];
  [obj setLastTelesupCollectorId: [aRecordSet getLongValue: "LAST_TEL_COLLECTOR_TOTAL_ID"]];
  [obj setLastTelesupCashRegisterId: [aRecordSet getLongValue: "LAST_TEL_CASH_REGISTER_ID"]];	
	[obj setDeleted: [aRecordSet getCharValue: "DELETED"]];
	[obj setLastAttemptDateTime: [aRecordSet getDateTimeValue: "LAST_ATTEMPT_TEL_DATE"]];
	[obj setFromHour: [aRecordSet getCharValue: "FROM_HOUR"]];
	[obj setToHour: [aRecordSet getCharValue: "TO_HOUR"]];
	[obj setActive: [aRecordSet getCharValue: "ACTIVE"]];
	[obj setAcronym: [aRecordSet getStringValue: "ACRONYM" buffer: buffer]];
	[obj setExtension: [aRecordSet getStringValue: "EXTENSION" buffer: buffer]];
	
	/*IMAS*/
	[obj setSendAudits: [aRecordSet getCharValue: "SEND_AUDITS"]];
	[obj setSendTraffic: [aRecordSet getCharValue: "SEND_TRAFFIC"]];
	
	/**/
	[obj setLastTelesupAdditionalTicketId: [aRecordSet getLongValue: "LAST_TELESUP_ADDITIONAL_ID"]];
  
  /**/ 
  [obj setNextSecondaryTelesupDateTime: [aRecordSet getDateTimeValue: "NEXT_SEC_TEL_DATE"]];
  [obj setTelesupFrame: [aRecordSet getCharValue: "FRAME"]];
  [obj setCabinIdleWaitTime: [aRecordSet getCharValue: "CABIN_IDLE_WAIT_TIME"]];  
	[obj setLastTariffTableHistoryId: [aRecordSet getLongValue: "LAST_TARIFF_TABLE_HISTORY_ID"]];

 	/*CIM*/
	[obj setLastTelesupDepositNumber: [aRecordSet getLongValue: "LAST_TELESUP_DEPOSIT_NUMBER"]];
	[obj setLastTelesupExtractionNumber: [aRecordSet getLongValue: "LAST_TELESUP_EXTRACTION_NUMBER"]];

	[obj setLastTelesupAlarmId: [aRecordSet getLongValue: "LAST_TELESUP_ALARM_ID"]];
	[obj setInformDepositsByTransaction: [aRecordSet getCharValue: "INFORM_DEPOSITS_BY_TRAN"]];
	[obj setInformExtractionsByTransaction: [aRecordSet getCharValue: "INFORM_EXTRACTIONS_BY_TRANS"]];
	[obj setInformAlarmsByTransaction: [aRecordSet getCharValue: "INFORM_ALARMS_BY_TRANS"]];
	[obj setLastTelesupZCloseNumber: [aRecordSet getLongValue: "LAST_TELESUP_ZCLOSE_NUMBER"]];
	[obj setLastTelesupXCloseNumber: [aRecordSet getLongValue: "LAST_TELESUP_XCLOSE_NUMBER"]];
	[obj setInformAlarmsByTransaction: [aRecordSet getCharValue: "INFORM_ALARMS_BY_TRANS"]];
	[obj setInformZCloseByTransaction: [aRecordSet getCharValue: "INFORM_ZCLOSE_BY_TRANS"]];
	return obj;
}

/**/
- (id) loadById: (unsigned long) anId
{
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "telesups" filter: "" orderFields: "TELESUP_ID"];
	id obj = NULL;

	[myRecordSet open];
	[myRecordSet moveFirst];


	if ([myRecordSet findById: "TELESUP_ID" value: anId]) {
		obj = [self newTelFromRecordSet: myRecordSet];
		return obj;
	}

	[myRecordSet free];
	THROW(REFERENCE_NOT_FOUND_EX);
	return NULL;
}

/**/
- (COLLECTION) loadAll
{
	COLLECTION collection = [OrdCltn new];
	ABSTRACT_RECORDSET myRecordSet = [[DBConnection getInstance] createRecordSetWithFilter: "telesups" filter: "" orderFields: "TELESUP_ID"];
	TELESUP_SETTINGS obj;

	[myRecordSet open];
	while ( [myRecordSet moveNext] ) {
		obj = [self newTelFromRecordSet: myRecordSet];
		if ( ![obj isDeleted]) 
			[collection add: obj];
		else 
			[obj free];		
	}

	[myRecordSet free];

	return collection;
}

/**/
- (void) updateTelesupDate: (TELESUP_SETTINGS) aTelesup
{
	DB_CONNECTION dbConnection = [DBConnection getInstance]; 
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSetWithFilter: "telesups" filter: "" orderFields: "TELESUP_ID"];
	ABSTRACT_RECORDSET myRecordSetBck;

	[myRecordSet open];

	if (![myRecordSet findById: "TELESUP_ID" value: [aTelesup getTelesupId]]) {
		//doLog(0,"No se pudo actualizar la fecha/hora de la ultima supervision\n");
		[myRecordSet close];
		[myRecordSet free];
		return;
	}

	[myRecordSet setDateTimeValue: "LAST_SUCEED_TEL_DATE" value: [aTelesup getLastSuceedTelesupDateTime]];
	[myRecordSet setDateTimeValue: "LAST_ATTEMPT_TEL_DATE" value: [aTelesup getLastAttemptDateTime]];
	[myRecordSet save];

	// *********** Analiza si debe hacer backup online ***********
	if ([dbConnection tableHasBackup: "telesups_bck"]) {
		myRecordSetBck = [dbConnection createRecordSetWithFilter: "telesups_bck" filter: "" orderFields: "TELESUP_ID"];

		[self doUpdateBackupById: "TELESUP_ID" value: [aTelesup getTelesupId] backupRecordSet: myRecordSetBck currentRecordSet: myRecordSet tableName: "telesups_bck"];
	}

	[myRecordSet close];
	[myRecordSet free];

}

/**/
- (void) store: (id) anObject
{	
 	int telesupId;
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSetWithFilter: "telesups" filter: "" orderFields: "TELESUP_ID"];
	ABSTRACT_RECORDSET myRecordSetBck;
	volatile AUDIT audit;
  char buffer[512];
  char buffer2[512];
  volatile BOOL alwaysLog = FALSE;
	volatile BOOL updateRecord = FALSE;
  
  TRY

		[myRecordSet open];

		//Valida los campos correspondientes a las telesupervisiones. En el caso que internamente se encuentre un error,
		//arroja una excepcion de otro modo, pasa.
		[self validateFields: anObject];

		if ([anObject getTelesupId] != 0) {

			[myRecordSet findById: "TELESUP_ID" value: [anObject getTelesupId]];
			updateRecord = TRUE;

      if ([anObject isDeleted]) audit = [[Audit new] initAuditWithCurrentUser: TELESUPERVISION_DELETED additional: [anObject getTelesupDescription] station: 0 logRemoteSystem: TRUE];
      else audit = [[Audit new] initAuditWithCurrentUser: TELESUPERVISION_UPDATED additional: [anObject getTelesupDescription] station: 0 logRemoteSystem: TRUE];

		}	else {
			[myRecordSet add];
      alwaysLog = TRUE;
      audit = [[Audit new] initAuditWithCurrentUser: TELESUPERVISION_INSERTED additional: [anObject getTelesupDescription] station: 0 logRemoteSystem: TRUE];
		}
  
    // Log de cambios
    if (![anObject isDeleted]) {

      [audit logChangeAsString: alwaysLog resourceId: RESID_TelesupSettings_DESCRIPTION oldValue: [myRecordSet getStringValue: "DESCRIPTION" buffer: buffer] newValue: [anObject getTelesupDescription]];

      if (strlen(trim([anObject getSystemId])) > 0)
        [audit logChangeAsString: alwaysLog resourceId: RESID_TelesupSettings_SYSTEM_ID oldValue: [myRecordSet getStringValue: "SYSTEM_ID" buffer: buffer] newValue: [anObject getSystemId]];

      if (strlen(trim([anObject getRemoteSystemId])) > 0)
        [audit logChangeAsString: alwaysLog resourceId: RESID_TelesupSettings_REMOTE_SYSTEM_ID oldValue: [myRecordSet getStringValue: "REMOTE_SYSTEM_ID" buffer: buffer] newValue: [anObject getRemoteSystemId]];

      if (strlen(trim([anObject getTelesupUserName])) > 0)
        [audit logChangeAsString: alwaysLog resourceId: RESID_TelesupSettings_USER_NAME oldValue: [myRecordSet getStringValue: "USER_NAME" buffer: buffer] newValue: [anObject getTelesupUserName]];

      if (strlen(trim([anObject getTelesupPassword])) > 0)
        [audit logChangeAsPassword: alwaysLog resourceId: RESID_TelesupSettings_PASSWORD oldValue: [myRecordSet getStringValue: "PASSWORD" buffer: buffer] newValue: [anObject getTelesupPassword]];

      if (strlen(trim([anObject getRemoteUserName])) > 0)
        [audit logChangeAsString: alwaysLog resourceId: RESID_TelesupSettings_REMOTE_USER_NAME oldValue: [myRecordSet getStringValue: "REMOTE_USER_NAME" buffer: buffer] newValue: [anObject getRemoteUserName]];

      if (strlen(trim([anObject getRemotePassword])) > 0)
        [audit logChangeAsPassword: alwaysLog resourceId: RESID_TelesupSettings_REMOTE_PASSWORD oldValue: [myRecordSet getStringValue: "REMOTE_PASSWORD" buffer: buffer] newValue: [anObject getRemotePassword]];

      [audit logChangeAsResourceString: 
						alwaysLog 
						resourceId: RESID_TelesupSettings_TELCO_TYPE 
						resourceStringBase: RESID_TelesupSettings_TELCO_TYPE_Desc 
						oldValue: [myRecordSet getCharValue: "TELCO_TYPE"] 
						newValue: [anObject getTelcoType]];

      [audit logChangeAsInteger: alwaysLog resourceId: RESID_TelesupSettings_FREQUENCY oldValue: [myRecordSet getCharValue: "FREQUENCY"] newValue: [anObject getTelesupFrequency]];
      [audit logChangeAsInteger: alwaysLog resourceId: RESID_TelesupSettings_ATTEMPTS_QTY oldValue: [myRecordSet getCharValue: "ATTEMPTS_QTY"] newValue: [anObject getAttemptsQty]];
      [audit logChangeAsInteger: alwaysLog resourceId: RESID_TelesupSettings_TIME_BETWEEN_ATTEMPTS oldValue: [myRecordSet getShortValue: "TIME_BETWEEN_ATTEMPTS"] newValue: [anObject getTimeBetweenAttempts]];

      stringcpy(buffer, "");
			TRY
				if ([myRecordSet getShortValue: "CONNECTION_ID_1"] > 0)
					stringcpy(buffer, [[TelesupervisionManager getInstance] getConDescription: [myRecordSet getShortValue: "CONNECTION_ID_1"]]);
			CATCH
			END_TRY

			TRY
				if ([anObject getConnection1] != NULL)
					stringcpy(buffer2, [[anObject getConnection1] getConnectionDescription]);
			CATCH
			END_TRY
            
      [audit logChangeAsString: alwaysLog resourceId: RESID_TelesupSettings_CONNECTION_1 
          oldValue: buffer 
          newValue: buffer2];

			[audit logChangeAsDateTime: alwaysLog resourceId: RESID_TelesupSettings_NEXT_TEL_DATE oldValue: [myRecordSet getDateTimeValue: "NEXT_TEL_DATE"] newValue: [anObject getNextTelesupDateTime]];
      [audit logChangeAsInteger: alwaysLog resourceId: RESID_TelesupSettings_FROM_HOUR oldValue: [myRecordSet getCharValue: "FROM_HOUR"] newValue: [anObject getFromHour]];
      [audit logChangeAsInteger: alwaysLog resourceId: RESID_TelesupSettings_TO_HOUR oldValue: [myRecordSet getCharValue: "TO_HOUR"] newValue: [anObject getToHour]];
      [audit logChangeAsBoolean: alwaysLog resourceId: RESID_TelesupSettings_ACTIVE oldValue: [myRecordSet getCharValue: "ACTIVE"] newValue: [anObject isActive]];
      [audit logChangeAsInteger: alwaysLog resourceId: RESID_TelesupSettings_FRAME oldValue: [myRecordSet getCharValue: "FRAME"] newValue: [anObject getTelesupFrame]];
      [audit logChangeAsBoolean: FALSE resourceId: RESID_INFORM_DEPOSITS oldValue: [myRecordSet getCharValue: "INFORM_DEPOSITS_BY_TRAN"] newValue: [anObject getInformDepositsByTransaction]];
      [audit logChangeAsBoolean: FALSE resourceId: RESID_INFORM_EXTRACTIONS oldValue: [myRecordSet getCharValue: "INFORM_EXTRACTIONS_BY_TRANS"] newValue: [anObject getInformExtractionsByTransaction]];
      [audit logChangeAsBoolean: FALSE resourceId: RESID_INFORM_ALARMS oldValue: [myRecordSet getCharValue: "INFORM_ALARMS_BY_TRANS"] newValue: [anObject getInformAlarmsByTransaction]];

    }

    [myRecordSet setStringValue: "SYSTEM_ID" value: [anObject getSystemId]];
		[myRecordSet setStringValue: "REMOTE_SYSTEM_ID" value: [anObject getRemoteSystemId]];        
    [myRecordSet setStringValue: "DESCRIPTION" value: [anObject getTelesupDescription]];    
		[myRecordSet setStringValue: "USER_NAME" value: [anObject getTelesupUserName]];
		[myRecordSet setStringValue: "PASSWORD" value: [anObject getTelesupPassword]];
		[myRecordSet setStringValue: "REMOTE_USER_NAME" value: [anObject getRemoteUserName]];
		[myRecordSet setStringValue: "REMOTE_PASSWORD" value: [anObject getRemotePassword]];		
		[myRecordSet setCharValue: "TELCO_TYPE" value: [anObject getTelcoType]];
		[myRecordSet setCharValue: "FREQUENCY" value: [anObject getTelesupFrequency]];
		[myRecordSet setCharValue: "START_MOMENT" value: [anObject getStartMoment]];
		[myRecordSet setCharValue: "ATTEMPTS_QTY" value: [anObject getAttemptsQty]];
		[myRecordSet setShortValue: "TIME_BETWEEN_ATTEMPTS" value: [anObject getTimeBetweenAttempts]];
		[myRecordSet setShortValue: "MAX_TIME_WOUT_TELESUP_ALLOWED" value: [anObject getMaxTimeWithoutTelAllowed]];

    if ([anObject getConnectionId1] != 0)
      [myRecordSet setShortValue: "CONNECTION_ID_1" value: [anObject getConnectionId1]];

    if ([anObject getConnectionId2] != 0)
		  [myRecordSet setShortValue: "CONNECTION_ID_2" value: [anObject getConnectionId2]];

		[myRecordSet setDateTimeValue: "NEXT_TEL_DATE" value: [anObject getNextTelesupDateTime]];
		[myRecordSet setDateTimeValue: "LAST_SUCEED_TEL_DATE" value: [anObject getLastSuceedTelesupDateTime]];
		[myRecordSet setLongValue:	"LAST_TELESUP_CALL_ID" value: [anObject getLastTelesupCallId]];
		[myRecordSet setLongValue:	"LAST_TELESUP_TICKET_ID" value: [anObject getLastTelesupTicketId]];
		[myRecordSet setLongValue:	"LAST_TELESUP_AUDIT_ID" value: [anObject getLastTelesupAuditId]];
		[myRecordSet setLongValue:	"LAST_TELESUP_MESSAGE_ID" value: [anObject getLastTelesupMessageId]];
		[myRecordSet setLongValue:	"LAST_TEL_COLLECTOR_TOTAL_ID" value: [anObject getLastTelesupCollectorId]];
		[myRecordSet setLongValue:	"LAST_TEL_CASH_REGISTER_ID" value: [anObject getLastTelesupCashRegisterId]];
    [myRecordSet setCharValue: "DELETED" value: [anObject isDeleted]];
		[myRecordSet setDateTimeValue: "LAST_ATTEMPT_TEL_DATE" value: [anObject getLastAttemptDateTime]];
		[myRecordSet setCharValue: "FROM_HOUR" value: [anObject getFromHour]];
		[myRecordSet setCharValue: "TO_HOUR" value: [anObject getToHour]];
		[myRecordSet setCharValue: "ACTIVE" value: [anObject isActive]];
		[myRecordSet setStringValue: "ACRONYM" value: [anObject getAcronym]];
		[myRecordSet setStringValue: "EXTENSION" value: [anObject getExtension]];
		[myRecordSet setCharValue: "SEND_AUDITS" value: [anObject getSendAudits]];
		[myRecordSet setCharValue: "SEND_TRAFFIC" value: [anObject getSendTraffic]];
		[myRecordSet setLongValue:	"LAST_TELESUP_ADDITIONAL_ID" value: [anObject getLastTelesupAdditionalTicketId]];
		[myRecordSet setDateTimeValue: "NEXT_SEC_TEL_DATE" value : [anObject getNextSecondaryTelesupDateTime]];
		[myRecordSet setCharValue: "FRAME" value: [anObject getTelesupFrame]];
		[myRecordSet setCharValue: "CABIN_IDLE_WAIT_TIME" value: [anObject getCabinIdleWaitTime]];
		[myRecordSet setLongValue: "LAST_TARIFF_TABLE_HISTORY_ID" value: [anObject getLastTariffTableHistoryId]];
		[myRecordSet setLongValue: "LAST_TELESUP_DEPOSIT_NUMBER" value: [anObject getLastTelesupDepositNumber]];
		[myRecordSet setLongValue: "LAST_TELESUP_EXTRACTION_NUMBER" value: [anObject getLastTelesupExtractionNumber]];
		[myRecordSet setLongValue: "LAST_TELESUP_ALARM_ID" value: [anObject getLastTelesupAlarmId]];
		[myRecordSet setCharValue: "INFORM_DEPOSITS_BY_TRAN" value: [anObject getInformDepositsByTransaction]];
		[myRecordSet setCharValue: "INFORM_EXTRACTIONS_BY_TRANS" value: [anObject getInformExtractionsByTransaction]];
		[myRecordSet setCharValue: "INFORM_ALARMS_BY_TRANS" value: [anObject getInformAlarmsByTransaction]];
		[myRecordSet setLongValue: "LAST_TELESUP_ZCLOSE_NUMBER" value: [anObject getLastTelesupZCloseNumber]];
		[myRecordSet setLongValue: "LAST_TELESUP_XCLOSE_NUMBER" value: [anObject getLastTelesupXCloseNumber]];
		[myRecordSet setCharValue: "INFORM_ZCLOSE_BY_TRANS" value: [anObject getInformZCloseByTransaction]];

		telesupId = [myRecordSet save];
		[anObject setTelesupId: telesupId];

		[audit setStation: telesupId];
    [audit saveAudit];
    [audit free];

		// *********** Analiza si debe hacer backup online ***********
		if ([dbConnection tableHasBackup: "telesups_bck"]) {

			if (!updateRecord) { // doy de alta
				// verifico que la supervision no existe en placa. (este control se hace por si
				// se limpio el equipo para luego hacer un restore, en cuyo caso no debo crearla 
				// porque ya existe en placa)
				if (![self existTelesupInBackup: [anObject getTelesupId]]) {
					myRecordSetBck = [dbConnection createRecordSetWithFilter: "telesups_bck" filter: "" orderFields: "TELESUP_ID"];
					[self doAddBackup: myRecordSetBck currentRecordSet: myRecordSet tableName: "telesups_bck"];					
				}
			} else {
				myRecordSetBck = [dbConnection createRecordSetWithFilter: "telesups_bck" filter: "" orderFields: "TELESUP_ID"];
				[self doUpdateBackupById: "TELESUP_ID" value: [anObject getTelesupId] backupRecordSet: myRecordSetBck currentRecordSet: myRecordSet tableName: "telesups_bck"];
			}

		}

	FINALLY

		[myRecordSet free];
		
	END_TRY
}

/**/
- (void) validateFields: (id) anObject
{
	id telesup;

	/* 
	 * Validacion de campo nulo
	 */
	if ([anObject isDeleted]) return;

	/*
	  Validacion de rangos
	  TelcoType = 1..3
	  StartMoment = 1..3
	  AttemptsQty = 0..255
	  TimeBetweenAttempts = 0..3600
	  ConnectionId = 1..16
		FromHour = 0..24
		ToHour = 0..24
		FromHour < ToHour

		Para Telecom:
		
		Acronym != ""
		SystemId != ""
		Extension != ""
		Password != ""
		ModemPhoneNumber != ""
		
	*/
	
	/*Tipo supervision*/
  if ([anObject getTelcoType] == 0) THROW(DAO_TELCO_NULLED_EX);
  
  /*Descripcion*/
	if ( strlen([anObject getTelesupDescription]) == 0 )
		THROW(DAO_TELESUP_DESCRIPTION_INCORRECT_EX);
   
	if ([anObject getTelcoType] == IMAS_TSUP_ID) {
  
		if ( strcmp([anObject getTelesupUserName], "") == 0 )
			THROW(DAO_TELESUP_USER_NAME_EMPTY_EX);

		if ( strcmp([anObject getTelesupPassword], "") == 0 )
			THROW(DAO_TELESUP_PASSWORD_EMPTY_EX);
			
		if ( strcmp([anObject getSystemId], "") == 0 )
			THROW(DAO_TELESUP_SYSTEM_ID_EMPTY_EX);

  }

	// Validaciones propias de TELECOM
	if ([anObject getTelcoType] == TELECOM_TSUP_ID) {
		if ( strcmp([anObject getExtension], "") == 0 )
			THROW(DAO_TELESUP_EXTENSION_EMPTY_EX);

		if ( strcmp([anObject getAcronym], "") == 0 )
			THROW(DAO_TELESUP_ACRONYM_EMPTY_EX);

		if ( strcmp([anObject getTelesupUserName], "") == 0 )
			THROW(DAO_TELESUP_TECO_USER_NAME_EMPTY_EX);

		if ( strcmp([anObject getTelesupPassword], "") == 0 )
			THROW(DAO_TELESUP_TECO_PASSWORD_EMPTY_EX);

		if ( strcmp([anObject getSystemId], "") == 0 )
			THROW(DAO_TELESUP_TECO_SYSTEM_ID_EMPTY_EX);

	}

	// Validaciones propias de TELEFONICA
	if ([anObject getTelcoType] == TELEFONICA_TSUP_ID) {
		if ( strcmp([anObject getSystemId], "") == 0 )
			THROW(DAO_TELESUP_TASA_SYSTEM_ID_EMPTY_EX);

		if ( strcmp([anObject getTelesupPassword], "") == 0 )
			THROW(DAO_TELESUP_TECO_PASSWORD_EMPTY_EX);
	}

	// Validaciones propias de SAR II
	if ([anObject getTelcoType] == SARII_TSUP_ID) {
		if ( strlen([anObject getSystemId]) == 0 )
			THROW(DAO_TELESUP_SYSTEM_ID_EMPTY_EX);

		if ( strlen([anObject getTelesupUserName]) == 0 )
			THROW(DAO_TELESUP_USER_NAME_EMPTY_EX);

		if ( strlen([anObject getTelesupPassword]) == 0 )
			THROW(DAO_TELESUP_PASSWORD_EMPTY_EX);
	}

	if ([anObject getConnectionId1] == 0) THROW(DAO_CONNECTION1_NULLED_EX);
	
  if ( ( [anObject getTelesupFrequency] < 1 ) || ( [anObject getTelesupFrequency] > 90 ))
    THROW(DAO_TELESUP_FREQUENCY_INCORRECT_EX);      
  
	if (([anObject getAttemptsQty] < 1) || ([anObject getAttemptsQty] > 10))
	 THROW(DAO_ATTEMPTS_QTY_INCORRECT_EX);
  

	// verificacion de supervision automatica de datos
	if ( ([anObject getTelcoType] == PIMS_TSUP_ID) && [anObject getInformDepositsByTransaction]) {

		telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: FTP_SERVER_TSUP_ID];

		if ( telesup && [telesup getInformDepositsByTransaction] ) 
			THROW(DAO_CANNOT_SET_INFORM_DEPOSIT_BY_TRANSACTION_EX);
	}

	// verificacion de supervision automatica de datos
	if ( ([anObject getTelcoType] == FTP_SERVER_TSUP_ID) && [anObject getInformDepositsByTransaction]) {

		telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];

		if ( telesup && [telesup getInformDepositsByTransaction] ) 
			THROW(DAO_CANNOT_SET_INFORM_DEPOSIT_BY_TRANSACTION_EX);
	}
		
}

/**/
- (BOOL) existTelesupInBackup: (int) anId
{
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET recordSetBck;
	BOOL exist = FALSE;

	if ([dbConnection tableHasBackup: "telesups_bck"]) {
		recordSetBck = [dbConnection createRecordSetWithFilter: "telesups_bck" filter: "" orderFields: "TELESUP_ID"];

		[recordSetBck open];
		if ([recordSetBck findById: "TELESUP_ID" value: anId]) {
			exist = TRUE;
		}

		[recordSetBck close];
		[recordSetBck free];
	}

	return exist;

}

@end
