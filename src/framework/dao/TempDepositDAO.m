#include "TempDepositDAO.h"
#include "Deposit.h"
#include "DepositDetail.h"
#include "CurrencyManager.h"
#include "system/db/all.h"
#include "UserManager.h"
#include "CimManager.h"
#include "CashReferenceManager.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

/**/
typedef struct {
	BOOL saveDeposit;
	int cashId;
	ABSTRACT_RECORDSET depositRS;
	ABSTRACT_RECORDSET depositDetailRS;
} TempDeposit;

@implementation TempDepositDAO

static TEMP_DEPOSIT_DAO singleInstance = NULL;

/**/
- (void) addDeposit: (TempDeposit*) aTempDeposit deposit: (id) anObject;

/**/
- (ABSTRACT_RECORDSET) getNewDepositRecordSet: (int) aCashId
{
	ABSTRACT_RECORDSET recordSet;
	char name[255];
	TABLE table;

	sprintf(name, "temp_deposits_%d", aCashId);
	table = [[Table new] initWithTableNameAndSchema: name schema: "temp_deposits" type: ROP_TABLE_SINGLE];
	recordSet = [[RecordSet new] initWithTable: table];

	return recordSet;
}

/**/
- (ABSTRACT_RECORDSET) getNewDepositDetailRecordSet: (int) aCashId
{
	ABSTRACT_RECORDSET recordSet;
	char name[255];
	TABLE table;

	//recordSet = [[DBConnection getInstance] createRecordSet: "temp_deposit_details"];
	sprintf(name, "temp_deposit_details_%d", aCashId);
	table = [[Table new] initWithTableNameAndSchema: name schema: "temp_deposit_details" type: ROP_TABLE_SINGLE];
	recordSet = [[RecordSet new] initWithTable: table];

	return recordSet;
}

/**/
- initialize
{
	[super initialize];

	myTempDeposits = [Collection new];
	myMutex = [OMutex new];

	return self;
}

/**/
+ new
{
	if (!singleInstance) singleInstance = [super new];
	return singleInstance;
}

/**/
+ getInstance
{
	return [self new];
}

/**/
- free
{
	return [super free];
}

/**/
- (TempDeposit *) getTempDeposit: (int) aCashId
{
	TempDeposit *tempDeposit;
	int i;

	for (i = 0; i < [myTempDeposits size]; ++i) {
		tempDeposit = (TempDeposit *)[myTempDeposits at: i];
		if (tempDeposit->cashId == aCashId) return tempDeposit;
	}

	tempDeposit = malloc(sizeof(TempDeposit));
	tempDeposit->cashId = aCashId;
	tempDeposit->saveDeposit = FALSE;
	tempDeposit->depositRS = [self getNewDepositRecordSet: aCashId];
	tempDeposit->depositDetailRS = [self getNewDepositDetailRecordSet: aCashId];

	[tempDeposit->depositRS open];
	[tempDeposit->depositDetailRS open];
	[myTempDeposits add: tempDeposit];

	return tempDeposit;
}

/**/
- (void) saveDepositDetail: (DEPOSIT) aDeposit detail: (DEPOSIT_DETAIL) aDepositDetail
{
	BOOL found = FALSE;
	TempDeposit *tempDeposit;
	ABSTRACT_RECORDSET depositDetailRS;

	[myMutex lock];

	TRY

		tempDeposit = [self getTempDeposit: [[aDeposit getCimCash] getCimCashId]];
		depositDetailRS = tempDeposit->depositDetailRS;
	
		// Si no guardo el deposito aun, lo guardo ahora
		if (!tempDeposit->saveDeposit) {
			[self addDeposit: tempDeposit deposit: aDeposit];
		}
	
		// Recorro el recordSet de detalle para ver si ya existe el detalle y 
		// actualizo la cantidad unicamente, sino agrego un nuevo registro
	
		if ([aDeposit getDepositType] == DepositType_AUTO) {
	
			[depositDetailRS moveBeforeFirst];
	
			while ([depositDetailRS moveNext]) {
				if ([depositDetailRS getShortValue: "ACCEPTOR_ID"] == [[aDepositDetail getAcceptorSettings] getAcceptorId] &&
						[depositDetailRS getCharValue: "DEPOSIT_VALUE_TYPE"] == [aDepositDetail getDepositValueType] &&
						[depositDetailRS getShortValue: "CURRENCY_ID"] == [[aDepositDetail getCurrency] getCurrencyId] && 
						[depositDetailRS getMoneyValue: "AMOUNT"] == [aDepositDetail getAmount]) {
					found = TRUE;
					break;
				}
			}
	
		}
	
		// Si encontro el registro, modifico la cantidad existente		
		if (found) {
			[depositDetailRS setShortValue: "QTY" value: [aDepositDetail getQty]];
	
		// Sino lo agrego a la lista
		} else {
			[depositDetailRS add];
			[depositDetailRS setShortValue: "ACCEPTOR_ID" value: [[aDepositDetail getAcceptorSettings] getAcceptorId]];
			[depositDetailRS setCharValue: "DEPOSIT_VALUE_TYPE" value: [aDepositDetail getDepositValueType]];
			[depositDetailRS setShortValue: "QTY" value: [aDepositDetail getQty]];
			[depositDetailRS setMoneyValue: "AMOUNT" value: [aDepositDetail getAmount]];
			[depositDetailRS setShortValue: "CURRENCY_ID" value: [[aDepositDetail getCurrency] getCurrencyId]];
			[depositDetailRS setLongValue: "ADDITIONAL_ID" value: 0];
		}
	
		[depositDetailRS save];

	FINALLY

		[myMutex unLock];

	END_TRY

}

/**/
- (void) setDepositValues: (ABSTRACT_RECORDSET) aRecordSet deposit: (id) anObject
{
	[aRecordSet setShortValue: "DOOR_ID" value: [[anObject getDoor] getDoorId]];
	[aRecordSet setShortValue: "CIM_CASH_ID" value: [[anObject getCimCash] getCimCashId]];
	[aRecordSet setCharValue: "DEPOSIT_TYPE" value: [anObject getDepositType]];
	[aRecordSet setDateTimeValue: "OPEN_TIME" value: [anObject getOpenTime]];
	[aRecordSet setDateTimeValue: "CLOSE_TIME" value: [anObject getCloseTime]];
	[aRecordSet setLongValue: "USER_ID" value: [[anObject getUser] getUserId]];
	[aRecordSet setStringValue: "ENVELOPE_NUMBER" value: [anObject getEnvelopeNumber]];
	[aRecordSet setStringValue: "BANK_ACCOUNT_NUMBER" value: [anObject getBankAccountNumber]];
	if ([anObject getCashReference] != NULL)
		[aRecordSet setShortValue: "REFERENCE_ID" value: [[anObject getCashReference] getCashReferenceId]];
	[aRecordSet setShortValue: "REJECTED_QTY" value: [anObject getRejectedQty]];
	[aRecordSet setStringValue: "APPLY_TO" value: [anObject getApplyTo]];
}

/**/
- (void) addDeposit: (TempDeposit*) aTempDeposit deposit: (id) anObject
{
	ABSTRACT_RECORDSET depositRS;
//	doLog(0,"TempDepositDAO -> Agregando deposito... ");
	depositRS = aTempDeposit->depositRS;

	[depositRS add];
	[self setDepositValues: depositRS deposit: anObject];
	[depositRS save];

	aTempDeposit->saveDeposit = TRUE;
	
//	doLog(0,"OK\n");
}

/**/
- (void) updateDeposit: (DEPOSIT) aDeposit
{
	TempDeposit *tempDeposit;
	ABSTRACT_RECORDSET depositRS;


	[myMutex lock];

	TRY

		tempDeposit = [self getTempDeposit: [[aDeposit getCimCash] getCimCashId]];
		
		// Si no existe, no hago nada
		if (!tempDeposit->saveDeposit) {

			printd(0,"TempDepositDAO -> no actualizo el deposito porque todavia no se guardo por primera vez\n");

		} else {
	
			depositRS = tempDeposit->depositRS;
		
		//	doLog(0,"TempDepositDAO -> Modificando deposito...\n");
			[depositRS moveFirst];
			[self setDepositValues: depositRS deposit: aDeposit];
			[depositRS save];

		}

	FINALLY

		[myMutex unLock];

	END_TRY

}

/**/
- (id) getDepositFromRecordSet: (ABSTRACT_RECORDSET) aDepositRS depositDetailRS: (ABSTRACT_RECORDSET) aDepositDetailRS
{
	DEPOSIT deposit;
	char buf[50];

	// Creo el deposito con los datos
	deposit = [Deposit new];
	[deposit setDoor: [[CimManager getInstance] getDoorById: [aDepositRS getShortValue: "DOOR_ID"]]];
	[deposit setCimCash: [[CimManager getInstance] getCimCashById: [aDepositRS getShortValue: "CIM_CASH_ID"]]];
	[deposit setDepositType: [aDepositRS getCharValue: "DEPOSIT_TYPE"]];
	[deposit setOpenTime: [aDepositRS getDateTimeValue: "OPEN_TIME"]];
	[deposit setCloseTime: [aDepositRS getDateTimeValue: "CLOSE_TIME"]];
	[deposit setUser: [[UserManager getInstance] getUserFromCompleteList: [aDepositRS getLongValue: "USER_ID"]]];
	[deposit setEnvelopeNumber: [aDepositRS getStringValue: "ENVELOPE_NUMBER" buffer: buf]];
	[deposit setBankAccountNumber: [aDepositRS getStringValue: "BANK_ACCOUNT_NUMBER" buffer: buf]];
	if ([aDepositRS getShortValue: "REFERENCE_ID"] > 0)
		[deposit setCashReference: [[CashReferenceManager getInstance] getCashReferenceById: [aDepositRS getShortValue: "REFERENCE_ID"]]];
	[deposit setRejectedQty: [aDepositRS getShortValue: "REJECTED_QTY"]];
	[deposit setApplyTo: [aDepositRS getStringValue: "APPLY_TO" buffer: buf]];

	[aDepositDetailRS moveFirst];

	// Creo cada uno de los detalles de deposito
	while (![aDepositDetailRS eof]) {

		[deposit addDepositDetail: [[CimManager getInstance] getAcceptorSettingsById: [aDepositDetailRS getShortValue: "ACCEPTOR_ID"]]
		depositValueType: [aDepositDetailRS getCharValue: "DEPOSIT_VALUE_TYPE"]
		currency: [[CurrencyManager getInstance] getCurrencyById: [aDepositDetailRS getShortValue: "CURRENCY_ID"]]
		qty: [aDepositDetailRS getShortValue: "QTY"]
		amount: [aDepositDetailRS getMoneyValue: "AMOUNT"]];

		[aDepositDetailRS moveNext];

	}

	return deposit;	
}

/**/
- (id) loadLastByCimCash: (CIM_CASH) aCimCash
{
	TempDeposit *tempDeposit;

	tempDeposit = [self getTempDeposit: [aCimCash getCimCashId]];
	if (![tempDeposit->depositRS moveLast]) return NULL;

	return [self getDepositFromRecordSet: tempDeposit->depositRS depositDetailRS: tempDeposit->depositDetailRS];
}

/**/
- (void) clearDeposit: (DEPOSIT) aDeposit
{
	TempDeposit *tempDeposit;

	[myMutex lock];

	TRY
	
		tempDeposit = [self getTempDeposit: [[aDeposit getCimCash] getCimCashId]]; 
		tempDeposit->saveDeposit = FALSE;
	
		// Elimino los archivos temporales
		[tempDeposit->depositRS deleteAll];
		[tempDeposit->depositDetailRS deleteAll];

	FINALLY

		[myMutex unLock];

	END_TRY
}

@end
