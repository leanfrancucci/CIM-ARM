#include "AcceptorDAO.h"
#include "AcceptorSettings.h"
#include "system/db/all.h"
#include "DataSearcher.h"
#include "util.h"
#include "CimManager.h"
#include "Cim.h"
#include "AcceptedCurrency.h"
#include "Denomination.h"
#include "CurrencyManager.h"
#include "Audit.h"
#include "ResourceStringDefs.h"

static id singleInstance = NULL;

@implementation AcceptorDAO

- (id) newFromRecordSet: (id) aRecordSet doorCollection: (COLLECTION) aDoorCollection;
- (void) validateFields: (id) anObject;

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
	myAcceptorsRS = [[DBConnection getInstance] createRecordSet: "acceptors"];
	[myAcceptorsRS open];

	myAcceptedDepositValuesRS = [[DBConnection getInstance] createRecordSet: "accepted_dep_value"];
	[myAcceptedDepositValuesRS open];

	myCurrencyByDepValueRS = [[DBConnection getInstance] createRecordSet: "currency_dep_value"];
	[myCurrencyByDepValueRS open];

	denominationsRS = [[DBConnection getInstance] createRecordSet: "denominations"];
	[denominationsRS open];

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
- (void) loadDenominations: (id) acceptedCurrency acceptorId: (int) anAcceptorId depositValueType: (int) aDepositValueType
{
	DENOMINATION denom;

	[denominationsRS moveBeforeFirst];

	while ( [denominationsRS moveNext] ) {

		if ( ([denominationsRS getShortValue: "ACCEPTOR_ID"] == anAcceptorId) && 
				 ([denominationsRS getCharValue: "DEPOSIT_VALUE_TYPE"] == aDepositValueType) && 
				 ([denominationsRS getShortValue: "CURRENCY_ID"] == [[acceptedCurrency getCurrency] getCurrencyId]) ) {

			denom = [Denomination new];
			[denom setAmount: [denominationsRS getMoneyValue: "DENOMINATION"]];
			[denom setDenominationState: [denominationsRS getCharValue: "STATE"]];
			[denom setDenominationSecurity: [denominationsRS getCharValue: "SECURITY"]];

			[acceptedCurrency addDenomination: denom];
		}
	}
}


/**/
-(void) loadAcceptedCurrencies: (id) anAcceptedDepValue acceptorId: (int) anAcceptorId
{
	ACCEPTED_CURRENCY acceptedCurrency;

	[myCurrencyByDepValueRS moveBeforeFirst];

	while ( [myCurrencyByDepValueRS moveNext] ) {

		if ( ([myCurrencyByDepValueRS getShortValue: "ACCEPTOR_ID"] == anAcceptorId) && ([myCurrencyByDepValueRS getCharValue: "DEPOSIT_VALUE_TYPE"] == [anAcceptedDepValue getDepositValueType]) && (![myCurrencyByDepValueRS getCharValue: "DELETED"]) ) {

			acceptedCurrency = [AcceptedCurrency new];
			[acceptedCurrency	setCurrency: [[CurrencyManager getInstance] getCurrencyById: [myCurrencyByDepValueRS getShortValue: "CURRENCY_ID"]]];

			[self loadDenominations: acceptedCurrency acceptorId: anAcceptorId depositValueType: [anAcceptedDepValue getDepositValueType]];

			// agrega el deposito aceptado al acceptedCurrency
			[anAcceptedDepValue addAcceptedCurrency: acceptedCurrency];
		}

	}
}

/**/
- (void) loadAcceptedDepositValues: (id) anObject
{
	ACCEPTED_DEPOSIT_VALUE acceptedDepositValue;

	[myAcceptedDepositValuesRS moveBeforeFirst];

	while ( [myAcceptedDepositValuesRS moveNext] ) {

		if (([myAcceptedDepositValuesRS getShortValue: "ACCEPTOR_ID"] == [anObject getAcceptorId]) && (![myAcceptedDepositValuesRS getCharValue: "DELETED"])) {

			acceptedDepositValue = [AcceptedDepositValue new];
			[acceptedDepositValue setDepositValueType: [myAcceptedDepositValuesRS getCharValue: "DEPOSIT_VALUE_TYPE"]];

			// carga los currencies (divisas) de este valor aceptado
			[self loadAcceptedCurrencies: acceptedDepositValue acceptorId: [anObject getAcceptorId]];

			// agrega el deposito aceptado al acceptor
			[anObject addAcceptedDepositValue: acceptedDepositValue];

		}
	}
}

/**/
- (id) newFromRecordSet: (id) aRecordSet doorCollection: (COLLECTION) aDoorCollection
{
	ACCEPTOR_SETTINGS obj;
	char buffer[100];
	int i;

	obj = [AcceptorSettings new];

	[obj setAcceptorId: [aRecordSet getShortValue: "ACCEPTOR_ID"]];
	[obj setAcceptorType: [aRecordSet getCharValue: "ACCEPTOR_TYPE"]];
	[obj setAcceptorName: [aRecordSet getStringValue: "NAME" buffer: buffer]];
	[obj setAcceptorBrand: [aRecordSet getCharValue: "BRAND"]];
	[obj setAcceptorModel: [aRecordSet getStringValue: "MODEL" buffer: buffer]];
	[obj setAcceptorProtocol: [aRecordSet getCharValue: "PROTOCOL"]];
	[obj setAcceptorSerialNumber: [aRecordSet getStringValue: "SERIAL_NUMBER" buffer: buffer]];
	[obj setAcceptorHardwareId: [aRecordSet getShortValue: "HARDWARE_ID"]];
	[obj setStackerSize: [aRecordSet getShortValue: "STACKER_SIZE"]];
	[obj setStackerWarningSize: [aRecordSet getShortValue: "STACKER_WARNING_SIZE"]];

	for (i = 0; i < [aDoorCollection size]; ++i) {
		if ([[aDoorCollection at: i] getDoorId] == [aRecordSet getShortValue: "DOOR_ID"]) {
			[[aDoorCollection at: i] addAcceptorSettings: obj];
		}
	}

	[obj setAcceptorBaudRate: [aRecordSet getCharValue: "BAUD_RATE"]];
	[obj setAcceptorDataBits: [aRecordSet getCharValue: "DATA_BITS"]];
	[obj setAcceptorParity: [aRecordSet getCharValue: "PARITY"]];
	[obj setAcceptorStopBits: [aRecordSet getCharValue: "STOP_BITS"]];
	[obj setDisabled: [aRecordSet getCharValue: "DISABLED"]];
	[obj setDeleted: [aRecordSet getCharValue: "DELETED"]];
//	[obj setStartTimeOut: [aRecordSet getCharValue: "START_TIMEOUT"]];
//	[obj setEchoDisable: [aRecordSet getCharValue: "ECHO_DISABLE"]];

	// carga los tipos de valores aceptados
	[self loadAcceptedDepositValues: obj];

	return obj;
}

/**/
- (COLLECTION) loadAll: (COLLECTION) aDoorCollection
{
	COLLECTION collection = [Collection new];
	ACCEPTOR_SETTINGS obj;
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSetBck;

	[myAcceptorsRS moveBeforeFirst];

	while ( [myAcceptorsRS moveNext] ) {
		obj = [self newFromRecordSet: myAcceptorsRS doorCollection: aDoorCollection];

		// controlo que el protocolo NO este con valor menor a 1
		if ([obj getAcceptorProtocol] < 1) {
			// actualizo en memoria
			[obj setAcceptorProtocol: 1];
			// actualizo en el data
			[myAcceptorsRS setCharValue: "PROTOCOL" value: 1];
			[myAcceptorsRS save];

			// *********** Analiza si debe hacer backup online ***********
			if ([dbConnection tableHasBackup: "acceptors_bck"]) {
				myRecordSetBck = [dbConnection createRecordSetWithFilter: "acceptors_bck" filter: "" orderFields: "ACCEPTOR_ID"];
		
				[self doUpdateBackupById: "ACCEPTOR_ID" value: [obj getAcceptorId] backupRecordSet: myRecordSetBck currentRecordSet: myAcceptorsRS tableName: "acceptors_bck"];
			}

		//	doLog(0,"Acceptor %d: Se actualizo el protocolo porque era erroneo. Nuevo valor: 1 **************\n",[obj getAcceptorId]);
		}

		[collection add: obj];
	}

	return collection;
}

/**/
- (void) store: (id) anObject
{
  AUDIT audit;
  char buffer[61];
	int acceptorId;
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSet = [dbConnection createRecordSetWithFilter: "acceptors" filter: "" orderFields: "ACCEPTOR_ID"];
	ABSTRACT_RECORDSET myRecordSetBck;
	volatile BOOL updateRecord = FALSE;

 	[myDataSearcher setRecordSet: myRecordSet];
	[myDataSearcher addShortFilter: "ACCEPTOR_ID" operator: "!=" value: [anObject getAcceptorId]];  
	[myDataSearcher addStringFilter: "NAME" operator: "=" value: [anObject getAcceptorName]];
	[myDataSearcher addCharFilter: "DELETED" operator: "=" value: FALSE];

	[myRecordSet open];

	if ([anObject getAcceptorId] == 0) 
  	if ([myDataSearcher find]) THROW(DAO_DUPLICATED_ACCEPTOR_EX);    

	[self validateFields: anObject];

  if ([anObject isDeleted]) {

		updateRecord = TRUE;
    audit = [[Audit new] initAuditWithCurrentUser: Event_DELETE_ACCEPTOR additional: [anObject getAcceptorName] station: [anObject getAcceptorId] logRemoteSystem: TRUE];
		[myRecordSet findById: "ACCEPTOR_ID" value: [anObject getAcceptorId]];
  } else if ([anObject getAcceptorId] != 0) {

			updateRecord = TRUE;
    	[myRecordSet findById: "ACCEPTOR_ID" value: [anObject getAcceptorId]];
			audit = [[Audit new] initAuditWithCurrentUser: Event_EDIT_ACCEPTOR additional: [anObject getAcceptorName] station: [anObject getAcceptorId] logRemoteSystem: TRUE];
	} else {

		[myRecordSet add];
		audit = [[Audit new] initAuditWithCurrentUser: Event_NEW_ACCEPTOR additional: "" station: 0 logRemoteSystem: TRUE];
		[audit setAlwaysLog: TRUE];
	}

  // LOG DE CAMBIOS 
  //if (![anObject isDeleted]) {


		[audit logChangeAsResourceString: FALSE
				resourceId: RESID_Acceptor_TYPE 
				resourceStringBase: RESID_Acceptor_TYPE
				oldValue: [myRecordSet getCharValue: "ACCEPTOR_TYPE"]
				newValue: [anObject getAcceptorType]
				oldReference: [myRecordSet getCharValue: "ACCEPTOR_TYPE"]
				newReference: [anObject getAcceptorType]];

		[audit logChangeAsString: RESID_Acceptor_NAME oldValue: [myRecordSet getStringValue: "NAME" buffer: buffer] newValue: [anObject getAcceptorName]];

		[audit logChangeAsResourceString: FALSE
				resourceId: RESID_Acceptor_BRAND 
				resourceStringBase: RESID_Acceptor_BRAND
				oldValue: [myRecordSet getCharValue: "BRAND"]
				newValue: [anObject getAcceptorBrand]
				oldReference: [myRecordSet getCharValue: "BRAND"]
				newReference: [anObject getAcceptorBrand]];

    [audit logChangeAsString: RESID_Acceptor_MODEL oldValue: [myRecordSet getStringValue: "MODEL" buffer: buffer] newValue: [anObject getAcceptorModel]];
    [audit logChangeAsInteger: RESID_Acceptor_PROTOCOL oldValue: [myRecordSet getCharValue: "PROTOCOL"] newValue: [anObject getAcceptorProtocol]];
    [audit logChangeAsInteger: RESID_Acceptor_HARDWARE_ID oldValue: [myRecordSet getShortValue: "HARDWARE_ID"] newValue: [anObject getAcceptorHardwareId]];
    [audit logChangeAsInteger: RESID_Acceptor_STACKER_SIZE oldValue: [myRecordSet getShortValue: "STACKER_SIZE"] newValue: [anObject getStackerSize]];
    [audit logChangeAsInteger: RESID_Acceptor_STACKER_WARNING_SIZE oldValue: [myRecordSet getShortValue: "STACKER_WARNING_SIZE"] newValue: [anObject getStackerWarningSize]];

    [audit logChangeAsString: FALSE 
				resourceId: RESID_Acceptor_DOOR_ID 
				oldValue: [[[[CimManager getInstance] getCim] getDoorById: [myRecordSet getShortValue: "DOOR_ID"]] getDoorName] 						newValue: [[[[CimManager getInstance] getCim] getDoorById: [[anObject getDoor] getDoorId]] getDoorName] 					
				oldReference: [myRecordSet getShortValue: "DOOR_ID"] 
				newReference: [[anObject getDoor] getDoorId]];

    //[audit logChangeAsInteger: RESID_Acceptor_START_TIMEOUT oldValue: [myRecordSet getCharValue: "START_TIMEOUT"] newValue: [anObject getStartTimeOut]];

    //[audit logChangeAsBoolean: RESID_Acceptor_ECHO_DISABLE oldValue: [myRecordSet getCharValue: "ECHO_DISABLE"] newValue: [anObject getEchoDisable]];
/*				  
    [audit logChangeAsInteger: RESID_Acceptor_BAUD_RATE oldValue: [myAcceptorsRS getCharValue: "BAUD_RATE"] newValue: [anObject getAcceptorBaudRate]];

    [audit logChangeAsInteger: RESID_Acceptor_DATA_BITS oldValue: [myAcceptorsRS getCharValue: "DATA_BITS"] newValue: [anObject getAcceptorDataBits]];

    [audit logChangeAsInteger: RESID_Acceptor_PARITY oldValue: [myAcceptorsRS getCharValue: "PARITY"] newValue: [anObject getAcceptorParity]];

    [audit logChangeAsInteger: RESID_Acceptor_STOP_BITS oldValue: [myAcceptorsRS getCharValue: "STOP_BITS"] newValue: [anObject getAcceptorStopBits]];

    [audit logChangeAsInteger: RESID_Acceptor_FLOW_CONTROL oldValue: [myAcceptorsRS getCharValue: "FLOW_CONTROL"] newValue: [anObject getAcceptorFlowControl]];
*/

    //doLog(0,"loguea el cambio en el campo deleted anterior = %d   nuevo = %d\n", [myAcceptorsRS getCharValue: "DELETED"], [anObject isDeleted]);

    [audit logChangeAsBoolean: RESID_Acceptor_DELETED oldValue: [myRecordSet getCharValue: "DELETED"] newValue: [anObject isDeleted]];
		[audit logChangeAsBoolean: RESID_Acceptor_DISABLED oldValue: [myRecordSet getCharValue: "DISABLED"] newValue: [anObject isDisabled]];

 //}

	[myRecordSet setCharValue: "ACCEPTOR_TYPE" value: [anObject getAcceptorType]];
	[myRecordSet setStringValue: "NAME" value: [anObject getAcceptorName]];
	[myRecordSet setCharValue: "BRAND" value: [anObject getAcceptorBrand]];
	[myRecordSet setStringValue: "MODEL" value: [anObject getAcceptorModel]];
	[myRecordSet setCharValue: "PROTOCOL" value: [anObject getAcceptorProtocol]];
	[myRecordSet setStringValue: "SERIAL_NUMBER" value: [anObject getAcceptorSerialNumber]];
	[myRecordSet setShortValue: "HARDWARE_ID" value: [anObject getAcceptorHardwareId]];
	[myRecordSet setShortValue: "STACKER_SIZE" value: [anObject getStackerSize]];
	[myRecordSet setShortValue: "STACKER_WARNING_SIZE" value: [anObject getStackerWarningSize]];
	[myRecordSet setShortValue: "DOOR_ID" value: [[anObject getDoor] getDoorId]];
	[myRecordSet setCharValue: "BAUD_RATE" value: [anObject getAcceptorBaudRate]];
	[myRecordSet setCharValue: "DATA_BITS" value: [anObject getAcceptorDataBits]];
	[myRecordSet setCharValue: "PARITY" value: [anObject getAcceptorParity]];
	[myRecordSet setCharValue: "STOP_BITS" value: [anObject getAcceptorStopBits]];
	[myRecordSet setCharValue: "DISABLED" value: [anObject isDisabled]];
	[myRecordSet setCharValue: "DELETED" value: [anObject isDeleted]];
//[myRecordSet setCharValue: "START_TIMEOUT" value: [anObject geTStartTimeOut]];
//	[myRecordSet setCharValue: "ECHO_DISABLE" value: [anObject getEchoDisable]];

	acceptorId = [myRecordSet save];
	[anObject setAcceptorId: acceptorId];
	[audit setStation: acceptorId];

  [audit saveAudit];
  [audit free];

	// *********** Analiza si debe hacer backup online ***********
	if ([dbConnection tableHasBackup: "acceptors_bck"]) {
		myRecordSetBck = [dbConnection createRecordSetWithFilter: "acceptors_bck" filter: "" orderFields: "ACCEPTOR_ID"];

		if (updateRecord) [self doUpdateBackupById: "ACCEPTOR_ID" value: [anObject getAcceptorId] backupRecordSet: myRecordSetBck currentRecordSet: myRecordSet tableName: "acceptors_bck"];
		else [self doAddBackup: myRecordSetBck currentRecordSet: myRecordSet tableName: "acceptors_bck"];
	}

}

- (void) deleteDenomination: (int) aDepositValueType acceptorId: (int) anAcceptorId currencyId: (int) aCurrencyId denomination: (DENOMINATION) aDenomination
{
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSetBck;
	AUDIT audit;
	BOOL found = FALSE;

	[denominationsRS moveFirst];

	while (![denominationsRS eof]) {

		if ( ([denominationsRS getCharValue: "DEPOSIT_VALUE_TYPE"] == aDepositValueType) && 
				 ([denominationsRS getShortValue: "ACCEPTOR_ID"] == anAcceptorId) && 
				 ([denominationsRS getShortValue: "CURRENCY_ID"] == aCurrencyId) && 
				 ([denominationsRS getMoneyValue: "DENOMINATION"] == [aDenomination getAmount]) ) {
			found = TRUE;
			break;
		}

		[denominationsRS moveNext];
	}

	if (!found) return;
		
	audit = [[Audit new] initAuditWithCurrentUser: EVENT_REMOVE_DENOMINATION additional: "" station: 0 logRemoteSystem: TRUE];

	[audit logChangeAsResourceString: FALSE
				resourceId: RESID_DEPOSIT_VALUE_TYPE 
				resourceStringBase: RESID_DEPOSIT_VALUE_TYPE
				oldValue: 0 
				newValue: aDepositValueType 
				oldReference: 0 
				newReference: aDepositValueType];

	[audit logChangeAsString: FALSE
				resourceId: RESID_ACCEPTOR_ID
				oldValue: "" 
				newValue: [[[[CimManager getInstance] getCim] getAcceptorSettingsById: anAcceptorId] getAcceptorName] 
				oldReference: 0 
				newReference: anAcceptorId];

	[audit logChangeAsString: FALSE
				resourceId: RESID_CURRENCY_ID
				oldValue: "" 
				newValue: [[[CurrencyManager getInstance] getCurrencyById: aCurrencyId] getName] 
				oldReference: 0 
				newReference: aCurrencyId];

  	[audit logChangeAsMoney: RESID_Denomination_DENOMINATION 
		oldValue: 0
 		newValue: [aDenomination getAmount]];

	// Le configuro esto para que quede con moneda y validador en 0 y no la trate de levantar nunca mas
	[denominationsRS setShortValue: "ACCEPTOR_ID" value: 0];
	[denominationsRS setShortValue: "CURRENCY_ID" value: 0];

	[denominationsRS save];

	[audit saveAudit];
	[audit free];

	// *********** Analiza si debe hacer backup online ***********
	if ([dbConnection tableHasBackup: "denominations_bck"]) {
		myRecordSetBck = [dbConnection createRecordSet: "denominations_bck"];

		[self doUpdateDenominationBck: myRecordSetBck currentRecordSet: denominationsRS depositValueType: aDepositValueType acceptorId: anAcceptorId currencyId: aCurrencyId denomination: aDenomination tableName: "denominations_bck"];
	}

}

/**/
- (void) storeDenomination: (int) aDepositValueType acceptorId: (int) anAcceptorId currencyId: (int) aCurrencyId denomination: (DENOMINATION) aDenomination
{
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSetBck;
	AUDIT audit = NULL;
	BOOL found = FALSE;
	char additional[21];
	char buf[50];

    //printf("AcceptorDao storeDenomination acceptor %d  currencyId %d Amount %lld\n", anAcceptorId, aCurrencyId, [aDenomination getAmount]);
    
	[denominationsRS moveFirst];

	while (![denominationsRS eof]) {

		if ( ([denominationsRS getCharValue: "DEPOSIT_VALUE_TYPE"] == aDepositValueType) && 
				 ([denominationsRS getShortValue: "ACCEPTOR_ID"] == anAcceptorId) && 
				 ([denominationsRS getShortValue: "CURRENCY_ID"] == aCurrencyId) && 
				 ([denominationsRS getMoneyValue: "DENOMINATION"] == [aDenomination getAmount]) ) {
			found = TRUE;
			break;
		}

		[denominationsRS moveNext];
	}

	if (!found) {
		audit = [[Audit new] initAuditWithCurrentUser: 	EVENT_NEW_DENOMINATION additional: "" station: 0 logRemoteSystem: TRUE];
		[audit setAlwaysLog: TRUE];

		[audit logChangeAsResourceString: FALSE
			resourceId: RESID_DEPOSIT_VALUE_TYPE 
			resourceStringBase: RESID_DEPOSIT_VALUE_TYPE
			oldValue: 0
			newValue: aDepositValueType
			oldReference: 0
			newReference: aDepositValueType];

		[audit logChangeAsString: FALSE
			resourceId: RESID_ACCEPTOR_ID 
			oldValue: ""
			newValue: [[[[CimManager getInstance] getCim] getAcceptorSettingsById: anAcceptorId] getAcceptorName]
         		oldReference: 0
			newReference: anAcceptorId];

		[audit logChangeAsString: FALSE
			resourceId: RESID_CURRENCY_ID 
			oldValue: "" 
			newValue: [[[CurrencyManager getInstance] getCurrencyById: aCurrencyId] getName]
         		oldReference: 0
			newReference: aCurrencyId];

  		[audit logChangeAsMoney: RESID_Denomination_DENOMINATION 
			oldValue: 0 
			newValue: [aDenomination getAmount]];


		[audit logChangeAsResourceString: FALSE
			resourceId: RESID_Denomination_STATE 
			resourceStringBase: RESID_Denomination_STATE
			oldValue: 0
			newValue: [aDenomination getDenominationState]
			oldReference: 0
			newReference: [aDenomination getDenominationState]];

	} else {

		// solo audito cuando cambia el estado de la denominacion
		if ([denominationsRS getCharValue: "STATE"] != [aDenomination getDenominationState]){

			formatMoney(buf, "", [denominationsRS getMoneyValue: "DENOMINATION"], 0, 20);
			sprintf(additional,"%s %s - %s",[[[CurrencyManager getInstance] getCurrencyById: [denominationsRS getShortValue: "CURRENCY_ID"]] getCurrencyCode], buf,[[[[CimManager getInstance] getCim] getAcceptorSettingsById: anAcceptorId] getAcceptorName]);

			audit = [[Audit new] initAuditWithCurrentUser: 	EVENT_EDIT_DENOMINATION additional: additional station: 0 logRemoteSystem: TRUE];
		
			[audit logChangeAsResourceString: FALSE
				resourceId: RESID_DEPOSIT_VALUE_TYPE 
				resourceStringBase: RESID_DEPOSIT_VALUE_TYPE
				oldValue: [denominationsRS getCharValue: "DEPOSIT_VALUE_TYPE"]
				newValue: aDepositValueType
				oldReference: [denominationsRS getCharValue: "DEPOSIT_VALUE_TYPE"]
				newReference: aDepositValueType];


			[audit logChangeAsString: FALSE
				resourceId: RESID_ACCEPTOR_ID 
				oldValue: [[[[CimManager getInstance] getCim] getAcceptorSettingsById: [denominationsRS getShortValue: "ACCEPTOR_ID"]] getAcceptorName]
				newValue: [[[[CimManager getInstance] getCim] getAcceptorSettingsById: anAcceptorId] getAcceptorName]
        oldReference: [denominationsRS getShortValue: "ACCEPTOR_ID"]
				newReference: anAcceptorId];       


			[audit logChangeAsString: FALSE
				resourceId: RESID_CURRENCY_ID 																	
				oldValue: [[[CurrencyManager getInstance] getCurrencyById: [denominationsRS getShortValue: "CURRENCY_ID"]] getName]
				newValue: [[[CurrencyManager getInstance] getCurrencyById: aCurrencyId] getName]
        oldReference: [denominationsRS getShortValue: "CURRENCY_ID"]
				newReference: aCurrencyId];

			[audit logChangeAsMoney: RESID_Denomination_DENOMINATION oldValue: [denominationsRS getMoneyValue: "DENOMINATION"] newValue: [aDenomination getAmount]];


			[audit logChangeAsResourceString: FALSE
				resourceId: RESID_Denomination_STATE 
				resourceStringBase: RESID_Denomination_STATE
				oldValue: [denominationsRS getCharValue: "STATE"]
				newValue: [aDenomination getDenominationState]
				oldReference: [denominationsRS getCharValue: "STATE"]
				newReference: [aDenomination getDenominationState]];
		}
	}

	if (!found) {
		[denominationsRS add];
		[denominationsRS setCharValue: "DEPOSIT_VALUE_TYPE" value: aDepositValueType];
		[denominationsRS setShortValue: "ACCEPTOR_ID" value: anAcceptorId];
		[denominationsRS setShortValue: "CURRENCY_ID" value: aCurrencyId];
		[denominationsRS setMoneyValue: "DENOMINATION" value: [aDenomination getAmount]];
	}

	[denominationsRS setCharValue: "STATE" value: [aDenomination getDenominationState]];
	[denominationsRS setCharValue: "SECURITY" value: [aDenomination getDenominationSecurity]];

	[denominationsRS save];

	if (audit != NULL){
		[audit saveAudit];
		[audit free];
	}

	// *********** Analiza si debe hacer backup online ***********
	if ([dbConnection tableHasBackup: "denominations_bck"]) {
		myRecordSetBck = [dbConnection createRecordSet: "denominations_bck"];

		if (found) [self doUpdateDenominationBck: myRecordSetBck currentRecordSet: denominationsRS depositValueType: aDepositValueType acceptorId: anAcceptorId currencyId: aCurrencyId denomination: aDenomination tableName: "denominations_bck"];
		else [self doAddBackup: myRecordSetBck currentRecordSet: denominationsRS tableName: "denominations_bck"];
	}

}

/**/
- (void) addDepositValueType: (int) anAcceptorId depositValueType: (int) aDepositValueType
{
	AUDIT audit;
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSetBck;

	[myDataSearcher setRecordSet: myAcceptedDepositValuesRS];

  [myDataSearcher addShortFilter: "ACCEPTOR_ID" operator: "=" value: anAcceptorId];  
	[myDataSearcher addCharFilter: "DEPOSIT_VALUE_TYPE" operator: "=" value: aDepositValueType];
	[myDataSearcher addCharFilter: "DELETED" operator: "=" value: FALSE];

  if ([myDataSearcher find]) THROW(DAO_DUPLICATED_DEPOSIT_VALUE_TYPE_EX);    

	audit = [[Audit new] initAuditWithCurrentUser: 	EVENT_NEW_DEPOSIT_TYPE additional: "" station: 0 logRemoteSystem: TRUE];
	[audit setAlwaysLog: TRUE];

	[audit logChangeAsResourceString: FALSE
				resourceId: RESID_DEPOSIT_VALUE_TYPE 
				resourceStringBase: RESID_DEPOSIT_VALUE_TYPE
				oldValue: 0
				newValue: aDepositValueType
				oldReference: 0
				newReference: aDepositValueType];

    	[audit logChangeAsString: FALSE
				resourceId: RESID_ACCEPTOR_ID
				oldValue: "" 
				newValue: [[[[CimManager getInstance] getCim] getAcceptorSettingsById: anAcceptorId] getAcceptorName]  
				oldReference: 0 
				newReference: anAcceptorId];

	[myAcceptedDepositValuesRS add];

	[myAcceptedDepositValuesRS setShortValue: "ACCEPTOR_ID" value: anAcceptorId];
	[myAcceptedDepositValuesRS setCharValue: "DEPOSIT_VALUE_TYPE" value: aDepositValueType];
	[myAcceptedDepositValuesRS setCharValue: "DELETED" value: FALSE];

	[myAcceptedDepositValuesRS save];

	[audit saveAudit];
	[audit free];

	// *********** Analiza si debe hacer backup online ***********
	if ([dbConnection tableHasBackup: "accepted_dep_value_bck"]) {
		myRecordSetBck = [dbConnection createRecordSet: "accepted_dep_value_bck"];

		[self doAddBackup: myRecordSetBck currentRecordSet: myAcceptedDepositValuesRS tableName: "accepted_dep_value_bck"];
	}

}

/**/
- (void) removeDepositValueType: (int) anAcceptorId depositValueType: (int) aDepositValueType
{
	AUDIT audit;
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	DATA_SEARCHER myDataSearcherBck = [DataSearcher new];
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSetBck;

	[myDataSearcher setRecordSet: myAcceptedDepositValuesRS];

  [myDataSearcher addShortFilter: "ACCEPTOR_ID" operator: "=" value: anAcceptorId];  
	[myDataSearcher addCharFilter: "DEPOSIT_VALUE_TYPE" operator: "=" value: aDepositValueType];
	[myDataSearcher addCharFilter: "DELETED" operator: "=" value: FALSE];

  if (![myDataSearcher find]) THROW(DAO_INEXISTENT_DEPOSIT_VALUE_TYPE_EX);    

	audit = [[Audit new] initAuditWithCurrentUser: 	EVENT_REMOVE_DEPOSIT_TYPE additional: "" station: 0 logRemoteSystem: TRUE];

	[audit logChangeAsResourceString: FALSE
				resourceId: RESID_DEPOSIT_VALUE_TYPE 
				resourceStringBase: RESID_DEPOSIT_VALUE_TYPE
				oldValue: 0
				newValue: aDepositValueType
				oldReference: 0
				newReference: aDepositValueType];

	[audit logChangeAsString: FALSE
				resourceId: RESID_ACCEPTOR_ID
				oldValue: "" 
				newValue: [[[[CimManager getInstance] getCim] getAcceptorSettingsById: anAcceptorId] getAcceptorName]  												oldReference: 0 
				newReference: anAcceptorId];

	[myAcceptedDepositValuesRS setCharValue: "DELETED" value: TRUE];

	[myAcceptedDepositValuesRS save];

	[audit saveAudit];
	[audit free];

	// *********** Analiza si debe hacer backup online ***********
	if ([dbConnection tableHasBackup: "accepted_dep_value_bck"]) {
		myRecordSetBck = [dbConnection createRecordSet: "accepted_dep_value_bck"];

		[myDataSearcherBck setRecordSet: myRecordSetBck];
		[myDataSearcherBck addShortFilter: "ACCEPTOR_ID" operator: "=" value: anAcceptorId];  
		[myDataSearcherBck addCharFilter: "DEPOSIT_VALUE_TYPE" operator: "=" value: aDepositValueType];
		[myDataSearcherBck addCharFilter: "DELETED" operator: "=" value: FALSE];

		[self doUpdateBackup: myRecordSetBck currentRecordSet: myAcceptedDepositValuesRS dataSearcher: myDataSearcherBck tableName: "accepted_dep_value_bck"];
	}

}

/**/
- (void) addDepositValueTypeCurrency: (int) anAcceptorId depositValueType: (int) aDepositValueType currencyId: (int) aCurrencyId
{
	AUDIT audit;
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSetBck;

	[myDataSearcher setRecordSet: myCurrencyByDepValueRS];
  [myDataSearcher addShortFilter: "ACCEPTOR_ID" operator: "=" value: anAcceptorId];  
	[myDataSearcher addCharFilter: "DEPOSIT_VALUE_TYPE" operator: "=" value: aDepositValueType];
	[myDataSearcher addShortFilter: "CURRENCY_ID" operator: "=" value: aCurrencyId];
	[myDataSearcher addCharFilter: "DELETED" operator: "=" value: FALSE];

  if ([myDataSearcher find]) THROW(DAO_DUPLICATED_DEPOSIT_VALUE_TYPE_CURRENCY_EX);

	audit = [[Audit new] initAuditWithCurrentUser: 	EVENT_NEW_CURRENCY additional: "" station: 0 logRemoteSystem: TRUE];
	[audit setAlwaysLog: TRUE];

	[audit logChangeAsResourceString: FALSE
			resourceId: RESID_DEPOSIT_VALUE_TYPE 
			resourceStringBase: RESID_DEPOSIT_VALUE_TYPE
			oldValue: 0
			newValue: aDepositValueType
			oldReference: 0
			newReference: aDepositValueType];		

	[audit logChangeAsString: FALSE
			resourceId: RESID_ACCEPTOR_ID
			oldValue: "" 
			newValue: [[[[CimManager getInstance] getCim] getAcceptorSettingsById: anAcceptorId] getAcceptorName]  												oldReference: 0 
			newReference: anAcceptorId];

	[audit logChangeAsString: FALSE
			resourceId: RESID_CURRENCY_ID
			oldValue: "" 
			newValue: [[[CurrencyManager getInstance] getCurrencyById: aCurrencyId] getName]  
			oldReference: 0 
			newReference: aCurrencyId];

	[myCurrencyByDepValueRS add];

	[myCurrencyByDepValueRS setShortValue: "ACCEPTOR_ID" value: anAcceptorId];
	[myCurrencyByDepValueRS setCharValue: "DEPOSIT_VALUE_TYPE" value: aDepositValueType];
	[myCurrencyByDepValueRS setShortValue: "CURRENCY_ID" value: aCurrencyId];
	[myCurrencyByDepValueRS setCharValue: "DELETED" value: FALSE];

	[myCurrencyByDepValueRS save];
	[audit saveAudit];
	[audit free];

	// *********** Analiza si debe hacer backup online ***********
	if ([dbConnection tableHasBackup: "currency_dep_value_bck"]) {
		myRecordSetBck = [dbConnection createRecordSet: "currency_dep_value_bck"];

		[self doAddBackup: myRecordSetBck currentRecordSet: myCurrencyByDepValueRS tableName: "currency_dep_value_bck"];
	}

}

/**/
- (void) removeDepositValueTypeCurrency: (int) anAcceptorId depositValueType: (int) aDepositValueType currencyId: (int) aCurrencyId
{
	AUDIT audit;
	DATA_SEARCHER myDataSearcher = [DataSearcher new];
	DATA_SEARCHER myDataSearcherBck = [DataSearcher new];
	DB_CONNECTION dbConnection = [DBConnection getInstance];
	ABSTRACT_RECORDSET myRecordSetBck;

	[myDataSearcher setRecordSet: myCurrencyByDepValueRS];

  [myDataSearcher addShortFilter: "ACCEPTOR_ID" operator: "=" value: anAcceptorId];  
	[myDataSearcher addCharFilter: "DEPOSIT_VALUE_TYPE" operator: "=" value: aDepositValueType];
	[myDataSearcher addShortFilter: "CURRENCY_ID" operator: "=" value: aCurrencyId];
	[myDataSearcher addCharFilter: "DELETED" operator: "=" value: FALSE];

  if (![myDataSearcher find]) THROW(DAO_INEXISTENT_DEPOSIT_VALUE_TYPE_CURRENCY_EX);    

	audit = [[Audit new] initAuditWithCurrentUser: 	EVENT_REMOVE_CURRENCY additional: "" station: 0 logRemoteSystem: TRUE];
	[audit logChangeAsResourceString: FALSE
				resourceId: RESID_DEPOSIT_VALUE_TYPE 
				resourceStringBase: RESID_DEPOSIT_VALUE_TYPE
				oldValue: 0 
				newValue: aDepositValueType 
				oldReference: 0 
				newReference: aDepositValueType];

	[audit logChangeAsString: FALSE
				resourceId: RESID_ACCEPTOR_ID
				oldValue: "" 
				newValue: [[[[CimManager getInstance] getCim] getAcceptorSettingsById: anAcceptorId] getAcceptorName] 
				oldReference: 0 
				newReference: anAcceptorId];

	[audit logChangeAsString: FALSE
				resourceId: RESID_CURRENCY_ID
				oldValue: "" 
				newValue: [[[CurrencyManager getInstance] getCurrencyById: aCurrencyId] getName] 
				oldReference: 0 
				newReference: aCurrencyId];

	[myCurrencyByDepValueRS setCharValue: "DELETED" value: TRUE];

	[myCurrencyByDepValueRS save];
	[audit saveAudit];
	[audit free];

	// *********** Analiza si debe hacer backup online ***********
	if ([dbConnection tableHasBackup: "currency_dep_value_bck"]) {
		myRecordSetBck = [dbConnection createRecordSet: "currency_dep_value_bck"];

		[myDataSearcherBck setRecordSet: myRecordSetBck];
		[myDataSearcherBck addShortFilter: "ACCEPTOR_ID" operator: "=" value: anAcceptorId];  
		[myDataSearcherBck addCharFilter: "DEPOSIT_VALUE_TYPE" operator: "=" value: aDepositValueType];
		[myDataSearcherBck addShortFilter: "CURRENCY_ID" operator: "=" value: aCurrencyId];
		[myDataSearcherBck addCharFilter: "DELETED" operator: "=" value: FALSE];

		[self doUpdateBackup: myRecordSetBck currentRecordSet: myCurrencyByDepValueRS dataSearcher: myDataSearcherBck tableName: "currency_dep_value_bck"];
	}

}

/**/
- (void) validateFields: (id) anObject
{
	if (strlen([anObject getAcceptorName]) == 0)
    THROW(DAO_ACCEPTOR_NAME_INCORRECT_EX);

	if ([anObject getStackerWarningSize] > [anObject getStackerSize])
    THROW(DAO_STACKER_WARNING_SIZE_INCORRECT_EX);

	if ([[anObject getDoor] isDeleted])
		if (![anObject isDisabled]) {
			[anObject setDisabled: TRUE];
			THROW(DAO_CANOT_ENABLE_DEVICE_EX);
		}

}

@end
