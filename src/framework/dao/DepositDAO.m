#include "DepositDAO.h"
#include "Deposit.h"
#include "DepositDetail.h"
#include "CurrencyManager.h"
#include "system/db/all.h"
#include "UserManager.h"
#include "CimManager.h"
#include "CashReferenceManager.h"
#include "SafeBoxHAL.h"
#include "CimBackup.h"
#include "FilteredRecordSet.h"

//#define LOG(args...) doLog(0,args)
#define LOG(args...)

@implementation DepositDAO

static DEPOSIT_DAO singleInstance = NULL;

/**/
- (ABSTRACT_RECORDSET) getNewDepositRecordSet
{
	ABSTRACT_RECORDSET recordSet;

	recordSet = [[DBConnection getInstance] createRecordSet: "deposits"];
	[recordSet setDateField: "CLOSE_TIME"];
	[recordSet setIdField: "NUMBER"];

	return recordSet;
}

/**/
- (ABSTRACT_RECORDSET) getNewDepositDetailRecordSet
{
	ABSTRACT_RECORDSET recordSet;

	recordSet = [[DBConnection getInstance] createRecordSet: "deposit_details"];
	[recordSet setDateField: ""];
	[recordSet setMaxRecordCount: INFINITE_MAX_RECORD_COUNT];
	[recordSet setIdField: "NUMBER"];

	return recordSet;
}

/**/
- initialize
{
	[super initialize];

	myDepositRS = [self getNewDepositRecordSet];
	[myDepositRS open];

  myDepositDetailRS = [self getNewDepositDetailRecordSet];
	[myDepositDetailRS open];

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
	[myDepositRS free];
	[myDepositDetailRS free];
	return [super free];
}

/**/
- (void) saveDepositDetail: (DEPOSIT) aDeposit depositDetail: (DEPOSIT_DETAIL) aDepositDetail
{
	[myDepositDetailRS add];

	[myDepositDetailRS setLongValue: "NUMBER" value: [aDeposit getNumber]];
	[myDepositDetailRS setShortValue: "ACCEPTOR_ID" value: [[aDepositDetail getAcceptorSettings] getAcceptorId]];
	[myDepositDetailRS setCharValue: "DEPOSIT_VALUE_TYPE" value: [aDepositDetail getDepositValueType]];
	[myDepositDetailRS setShortValue: "QTY" value: [aDepositDetail getQty]];
	[myDepositDetailRS setMoneyValue: "AMOUNT" value: [aDepositDetail getAmount]];
	[myDepositDetailRS setShortValue: "CURRENCY_ID" value: [[aDepositDetail getCurrency] getCurrencyId]];
	[myDepositDetailRS setLongValue: "ADDITIONAL_ID" value: 0];

	[myDepositDetailRS save];

	[[CimBackup getInstance] syncRecord: "deposit_details" buffer: [myDepositDetailRS getRecordBuffer]];

}


/**/
- (void) storeDetails: (id) anObject
{
	int i;
	COLLECTION details;
	DEPOSIT_DETAIL detail;

	details = [anObject getDepositDetails];

	for (i = 0; i < [details size]; ++i) {

		detail = [details at: i];

		[self saveDepositDetail: anObject depositDetail: detail];

	}

}

/**/
- (void) store: (id) anObject
{
	unsigned long indexCount;

	LOG("DepositDAO -> Grabando deposito...\n");

	[myDepositRS add];

	[myDepositRS setShortValue: "DOOR_ID" value: [[anObject getDoor] getDoorId]];
	[myDepositRS setShortValue: "CIM_CASH_ID" value: [[anObject getCimCash] getCimCashId]];
	[myDepositRS setCharValue: "DEPOSIT_TYPE" value: [anObject getDepositType]];
	[myDepositRS setDateTimeValue: "OPEN_TIME" value: [anObject getOpenTime]];
	[myDepositRS setDateTimeValue: "CLOSE_TIME" value: [anObject getCloseTime]];
	[myDepositRS setLongValue: "USER_ID" value: [[anObject getUser] getUserId]];
	[myDepositRS setStringValue: "ENVELOPE_NUMBER" value: [anObject getEnvelopeNumber]];
	[myDepositRS setStringValue: "BANK_ACCOUNT_NUMBER" value: [anObject getBankAccountNumber]];
	[myDepositRS setShortValue: "REJECTED_QTY" value: [anObject getRejectedQty]];
	[myDepositRS setStringValue: "APPLY_TO" value: [anObject getApplyTo]];
	[myDepositRS setLongValue: "NUMBER" value: [anObject getNumber]];
	if ([anObject getCashReference] != NULL)
		[myDepositRS setShortValue: "REFERENCE_ID" value: [[anObject getCashReference] getCashReferenceId]];

	indexCount = [myDepositRS getIndexCount];

	[myDepositRS save];

	[[CimBackup getInstance] syncRecord: "deposits" buffer: [myDepositRS getRecordBuffer]];

	LOG("DepositDAO -> termino de grabar deposito...\n");
	LOG("DepositDAO -> Guardando detalle ...\n");

	// Verifica si se agrego un archivo mas a la lista de indices, con lo cual
	// debo generar los archivos correspondientes para la tabla de detalle de deposito.
	// En caso de que se este en la cantidad maxima de archivos de depositos verifico
	// por el metodo shouldCutFile pues si no [myDepositRS getIndexCount] siempre 
	// va a ser = a indexCount y nunca mas se crearia un nuevo archivo de detalle haciendo 
	// que este cree registros indefinidamente.
	if ( ([myDepositRS getIndexCount] != indexCount) ||
			 ([myDepositRS shouldCutFile]) ) {
		LOG("DepositDAO -> creo un nuevo archivo de detalle\n");
		[myDepositDetailRS cutFile];
	}
	[myDepositRS setShouldCutFile: FALSE];

	[self storeDetails: anObject];

	LOG("DepositDAO -> termino de grabar detalle...\n");

}

/**/
- (id) getDepositFromRecordSet: (ABSTRACT_RECORDSET) aDepositRS depositDetailRS: (ABSTRACT_RECORDSET) aDepositDetailRS
{
	DEPOSIT deposit;
	COLLECTION depositDetails;
	DEPOSIT_DETAIL depositDetail;
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
	[deposit setNumber: [aDepositRS getLongValue: "NUMBER"]];
	[deposit setRejectedQty: [aDepositRS getShortValue: "REJECTED_QTY"]];
	[deposit setApplyTo: [aDepositRS getStringValue: "APPLY_TO" buffer: buf]];
	if ([aDepositRS getShortValue: "REFERENCE_ID"] > 0)
		[deposit setCashReference: [[CashReferenceManager getInstance] getCashReferenceById: [aDepositRS getShortValue: "REFERENCE_ID"]]];

	if (![aDepositDetailRS findFirstById: "NUMBER" value: [deposit getNumber]]) return deposit;

	depositDetails = [deposit getDepositDetails];

	// Creo cada uno de los detalles de deposito
	while (![aDepositDetailRS eof] && [aDepositDetailRS getLongValue: "NUMBER"] == [deposit getNumber]) {

		depositDetail = [DepositDetail new];
		[depositDetail setDepositValueType: [aDepositDetailRS getCharValue: "DEPOSIT_VALUE_TYPE"]];
		[depositDetail setAmount: [aDepositDetailRS getMoneyValue: "AMOUNT"]];
		[depositDetail setQty: [aDepositDetailRS getShortValue: "QTY"]];
		[depositDetail setAdditionalId: [aDepositDetailRS getLongValue: "ADDITIONAL_ID"]];
		[depositDetail setCurrency: [[CurrencyManager getInstance] getCurrencyById: [aDepositDetailRS getShortValue: "CURRENCY_ID"]]];
		[depositDetail setAcceptorSettings: [[CimManager getInstance] getAcceptorSettingsById: [aDepositDetailRS getShortValue: "ACCEPTOR_ID"]]];

		[depositDetails add: depositDetail];

		[aDepositDetailRS moveNext];

	}

	return deposit;	
}

/**/
- (id) getDepositFromRecordSetForTelesup: (ABSTRACT_RECORDSET) aDepositRS depositDetailRS: (ABSTRACT_RECORDSET) aDepositDetailRS
{
	DEPOSIT deposit;
	COLLECTION depositDetails;
	DEPOSIT_DETAIL depositDetail;
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
	[deposit setNumber: [aDepositRS getLongValue: "NUMBER"]];
	[deposit setRejectedQty: [aDepositRS getShortValue: "REJECTED_QTY"]];
	[deposit setApplyTo: [aDepositRS getStringValue: "APPLY_TO" buffer: buf]];
	if ([aDepositRS getShortValue: "REFERENCE_ID"] > 0)
		[deposit setCashReference: [[CashReferenceManager getInstance] getCashReferenceById: [aDepositRS getShortValue: "REFERENCE_ID"]]];

	if ([aDepositDetailRS eof] || [aDepositDetailRS getLongValue: "NUMBER"] != [aDepositRS getLongValue: "NUMBER"])
		if (![aDepositDetailRS findFirstById: "NUMBER" value: [deposit getNumber]]) return deposit;

	depositDetails = [deposit getDepositDetails];

	// Creo cada uno de los detalles de deposito
	while (![aDepositDetailRS eof] && [aDepositDetailRS getLongValue: "NUMBER"] == [deposit getNumber]) {

		depositDetail = [DepositDetail new];
		[depositDetail setDepositValueType: [aDepositDetailRS getCharValue: "DEPOSIT_VALUE_TYPE"]];
		[depositDetail setAmount: [aDepositDetailRS getMoneyValue: "AMOUNT"]];
		[depositDetail setQty: [aDepositDetailRS getShortValue: "QTY"]];
		[depositDetail setAdditionalId: [aDepositDetailRS getLongValue: "ADDITIONAL_ID"]];
		[depositDetail setCurrency: [[CurrencyManager getInstance] getCurrencyById: [aDepositDetailRS getShortValue: "CURRENCY_ID"]]];
		[depositDetail setAcceptorSettings: [[CimManager getInstance] getAcceptorSettingsById: [aDepositDetailRS getShortValue: "ACCEPTOR_ID"]]];

		[depositDetails add: depositDetail];

		[aDepositDetailRS moveNext];

	}

	return deposit;	
}

/**/
- (id) loadById: (unsigned long) anId
{
	if (![myDepositRS findById: "NUMBER" value: anId]) return NULL;

	return [self getDepositFromRecordSet: myDepositRS depositDetailRS: myDepositDetailRS];
}

/**/
- (id) loadLast
{

	if (![myDepositRS moveLast]) return NULL;

	return [self getDepositFromRecordSet: myDepositRS depositDetailRS: myDepositDetailRS];

}

/**/
- (unsigned long) getLastDepositNumber
{
	if (![myDepositRS moveLast]) 
		return [[CimBackup getInstance] getLastRowValue: "deposits" field: "NUMBER"];

	return [myDepositRS getLongValue: "NUMBER"];
}


/**/
- (ABSTRACT_RECORDSET) getDepositRecordSetByDate: (datetime_t) aFromDate to: (datetime_t) aToDate
{
	FILTERED_RECORDSET recordSet; 
	
	recordSet = [[FilteredRecordSet new] initWithRecordset: [self getNewDepositRecordSet]];
	
	if (aFromDate > 0)
		[recordSet addLongFilter: "CLOSE_TIME" operator: ">=" value: aFromDate];
		
	if (aToDate > 0)
		[recordSet addLongFilter: "CLOSE_TIME" operator: "<=" value: aToDate];
								
	return recordSet;		

}

/**/
- (void) deleteAll
{
	[myDepositRS deleteAll];
	[myDepositDetailRS deleteAll];
}

@end
