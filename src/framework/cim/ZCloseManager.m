#include "ZCloseManager.h"
#include "UserManager.h"
#include "Persistence.h"
#include "CurrencyManager.h"
#include "CashReferenceManager.h"
#include "CimManager.h"
#include "DepositDAO.h"
#include "ReportXMLConstructor.h"
#include "PrinterSpooler.h"
#include "system/util/all.h"
#include "ZCloseDAO.h"
#include "CimAudits.h"
#include "TelesupScheduler.h"
#include "CimManager.h"
#include "Persistence.h"
#include "InstaDropManager.h"
#include "CimGeneralSettings.h"
#include "Audit.h"
#include "MessageHandler.h"
#include "CimDefs.h"
#include "TelesupervisionManager.h"


#define CHECK_END_OF_DAY_TIMER 			10000 // 10 segundos

@implementation ZCloseManager

static ZCLOSE_MANAGER singleInstance = NULL;

/**/
- (int) getLastZCloseMinute;
- (ZCLOSE) loadZClose;
- (void) loadCloses;
- (id) loadCurrentZClose;
-(COLLECTION) loadCurrentCashClosesCollection;
- (void) updateDepositData: (id) aDepositRS closesCollection: (COLLECTION) aCashClosesCollection;
- (ZCLOSE) loadCurrentCashClose: (CIM_CASH) aCimCash;
- (ZCLOSE) loadCashClose: (CIM_CASH) aCimCash 
	fromDepositNumber: (unsigned long) aFromDepositNumber
	toDepositNumber: (unsigned long) aToDepositNumber
	useToDepositNumber: (BOOL) aUseToDepositNumber;
- (void) generateCashClosesForAllCashs: (datetime_t) aCloseTime;
- (void) updateDepositDetailsData: (id) aDepositRS depositDetailRS: (id) aDepositDetailRS closesCollection: (COLLECTION) aCashClosesCollection user: (id) aUser currency: (id) aCurrency;

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}

/**/
+ getInstance
{
  return [self new];
}
 
/**/
- initialize
{
	myLastZCloseTime = 0;
	myLastZCloseNumber = [[[Persistence getInstance] getZCloseDAO] getLastZCloseNumber];

	myLastCashCloseNumber = [[[Persistence getInstance] getZCloseDAO] getLastCashCloseNumber];

	if ([[CimGeneralSettings getInstance] getUseEndDay]) 
		[[ZCloseManager getInstance] loadAllCashes];
	
	return self;
}

/**/
- (void) loadAllCashes
{
	myCurrentCashCloses = [Collection new];

	    //************************* logcoment
//doLog(0, "Carga de ZCloses\n");
	[self loadCloses];

	// Defino un timer que verifica si se llego al End Of Day
	myTimer = [OTimer new];
	[myTimer initTimer: PERIODIC
			period: CHECK_END_OF_DAY_TIMER
			object: self
			callback: "checkEndOfDayHandler"];
	[myTimer start];

}

/**/
- (void) loadCloses
{
	CURRENCY_MANAGER currencyManager;
	CIM_MANAGER cimManager;
	USER_MANAGER userManager;
	CASH_REFERENCE_MANAGER cashReferenceManager;
	unsigned long fDepNumber = 1;
	COLLECTION cashClosesCollection = NULL; 
	ZCLOSE zClose;
	ABSTRACT_RECORDSET depositRS;
	ABSTRACT_RECORDSET depositDetailRS;
	BOOL hasDeposit = TRUE;
	USER user;
	CURRENCY lastCurrency = NULL;
	CURRENCY currency;
	int i;
	unsigned long number;

	// Obtengo los objetos que luego voy a utilizar
	currencyManager = [CurrencyManager getInstance];
	cimManager = [CimManager getInstance];
	userManager = [UserManager getInstance];
	cashReferenceManager = [CashReferenceManager getInstance];

	// carga el zclose
	zClose = [self loadCurrentZClose];

	// carga la coleccion de cash closes
	cashClosesCollection = [self loadCurrentCashClosesCollection];

	[cashClosesCollection add: zClose];

	// analiza a partir de que numero de deposito arranca la busqueda
	for (i=0; i<[cashClosesCollection size]; ++i) {
		if ([[cashClosesCollection at: i] getFromDepositNumber] < fDepNumber) 
			fDepNumber = [[cashClosesCollection at: i] getFromDepositNumber];
	}

	depositRS = [[[Persistence getInstance] getDepositDAO] getNewDepositRecordSet];
	[depositRS open];

	depositDetailRS = [[[Persistence getInstance] getDepositDAO] getNewDepositDetailRecordSet];
	[depositDetailRS open];

	hasDeposit = [depositRS findById: "NUMBER" value: fDepNumber];
    //************************* logcoment
//	doLog(0,"ZCloseManager -> busqueda a partir del dep %ld, hay dep? = %d\n", fDepNumber, hasDeposit);

	if (!hasDeposit) 	[depositRS moveFirst];

	[depositDetailRS moveFirst];

	while (![depositRS eof]) {

		number = [depositRS getLongValue: "NUMBER"];
		user = [userManager getUserFromCompleteList: [depositRS getLongValue: "USER_ID"]];

		[self updateDepositData: depositRS closesCollection: cashClosesCollection];
		
		if ((![depositDetailRS eof] && [depositDetailRS getLongValue: "NUMBER"] == number) ||
				[depositDetailRS findFirstById: "NUMBER" value: number]) {

			while (![depositDetailRS eof] && [depositDetailRS getLongValue: "NUMBER"] == number) {

				if (lastCurrency != NULL && [lastCurrency getCurrencyId] == [depositDetailRS getShortValue: "CURRENCY_ID"]) {
					currency = lastCurrency;
				} else {
					currency = [currencyManager getCurrencyById: [depositDetailRS getShortValue: "CURRENCY_ID"]];
					lastCurrency = currency;
				}

				[self updateDepositDetailsData: depositRS depositDetailRS: depositDetailRS closesCollection: cashClosesCollection user: user currency: currency];


				[depositDetailRS moveNext];
			}

		}

		[depositRS moveNext];
	}

	[depositRS close];
	[depositRS free];
	[depositDetailRS close];
	[depositDetailRS free];

	for (i=0; i<[cashClosesCollection size]; ++i) {

		if ([[cashClosesCollection at: i] getCloseType] == CloseType_END_OF_DAY)
			myCurrentZClose =  [cashClosesCollection at: i];
		else 
			[myCurrentCashCloses add: [cashClosesCollection at: i]];

		[[cashClosesCollection at: i] debug];

	}	

	[cashClosesCollection free];

}


/**/
- (id) loadCurrentZClose
{
	datetime_t lastZCloseCloseTime = 0;
	ZCLOSE lastZClose;

	id zClose = [ZClose new];

	// Levanto el ultimo cierre Z
	lastZCloseCloseTime = [[[Persistence getInstance] getZCloseDAO] getLastZCloseCloseTime];
  myLastZCloseTime = lastZCloseCloseTime;

	// Levanto el ultimo cierre Z que tenga depositos efectuados
	lastZClose = [[[Persistence getInstance] getZCloseDAO] loadLastWithDeposits];

	if ([[CimGeneralSettings getInstance] getNextZNumber] > myLastZCloseNumber) {
		myLastZCloseNumber = [[CimGeneralSettings getInstance] getNextZNumber] - 1;
	}

	[zClose setNumber: myLastZCloseNumber + 1];
	[zClose setOpenTime: lastZCloseCloseTime];

	// Si existe un ultimo cierre Z entonces tengo que localizar
	// el deposito siguiente al ultimo efectuado en ese cierre Z
	// Si no existe un ultimo cierre Z, recorro desde el principio
	if (lastZClose) {
		[zClose setFromCloseNumber: [lastZClose getToCloseNumber] + 1];
	} else {
		[zClose setFromCloseNumber: 1];
	}

	if (lastZClose != NULL && [lastZClose getToDepositNumber] > 0) {
		[zClose setFromDepositNumber: [lastZClose getToDepositNumber] + 1];
	} else {
		[zClose setFromDepositNumber: 1];
	}

	if (lastZClose) [lastZClose free];

	return zClose;
}

/**/
-(COLLECTION) loadCurrentCashClosesCollection
{
	COLLECTION col = [Collection new];
	COLLECTION cimCashs = [[[CimManager getInstance] getCim] getCimCashs];
	int i;
	id cashClose;
	ZCLOSE lastCashClose;
	unsigned long fromDepositNumber = 1;

	for (i = 0; i < [cimCashs size]; ++i) {

		cashClose = [ZClose new];

		lastCashClose = [[[Persistence getInstance] getZCloseDAO] loadLastCashClose: [[cimCashs at: i] getCimCashId]];

		if (lastCashClose) {
			if ([lastCashClose getToDepositNumber] != 0)
				fromDepositNumber = [lastCashClose getToDepositNumber] + 1;
			else
				fromDepositNumber = [lastCashClose getFromDepositNumber];
		}
	
    //************************* logcoment
//		doLog(0, "Levantando cash close desde deposito %ld\n", fromDepositNumber);
	
		if (lastCashClose) {
			[cashClose setOpenTime: [lastCashClose getCloseTime]];
		} else {
			[cashClose setOpenTime: [SystemTime getLocalTime]];
		}

		[cashClose setFromDepositNumber: fromDepositNumber];
		[cashClose setCimCash: [cimCashs at: i]];
		[cashClose setCloseType: CloseType_CASH_CLOSE];
		
		[col add: cashClose];

	}
	
	return col;

}

/**/
- (void) updateDepositData: (id) aDepositRS closesCollection: (COLLECTION) aCashClosesCollection
{
	int i;
	id cashClose;

	for (i=0; i<[aCashClosesCollection size]; ++i) {

		cashClose = [aCashClosesCollection at: i];
		[cashClose updateDepData: aDepositRS];

	}

}

/**/
- (void) updateDepositDetailsData: (id) aDepositRS depositDetailRS: (id) aDepositDetailRS closesCollection: (COLLECTION) aCashClosesCollection user: (id) aUser currency: (id) aCurrency
{
	int i;
	id cashClose;

	for (i=0; i<[aCashClosesCollection size]; ++i) {

		cashClose = [aCashClosesCollection at: i];
		[cashClose updateDepDetData: aDepositRS depositDetailRS: aDepositDetailRS user: aUser currency: aCurrency];

	}

}


/*******************************************************************************************/


/*********************************************
 *
 * Carga el zclose actual (fin de dia)
 *
 *********************************************/

/*
	Algoritmo general:
	
		1) Buscar la ultima extraccion efectuada de la puerta pasada como parametro.
		2) Obtener el numero del ultimo deposito (tengo que buscar a partir de ese mas 1).
		3) Comenzar la busqueda de depositos a partir de este ID.
		4) Solo incluir aquellos depositos cuya DOOR_ID coincide con la puerta pasada como parametro.
	
		Notas: - el FromId debe quedar como el primer deposito hecho en esa puerta.
 					 - el ToId debe quedar como el ultimo deposito hecho en esa puerta.

*/
- (ZCLOSE) loadZClose
{
	ZCLOSE zClose;
	unsigned long fromDepositNumber = 0;
	unsigned long toDepositNumber = 0;
	unsigned long number;
	ABSTRACT_RECORDSET depositRS;
	ABSTRACT_RECORDSET depositDetailRS;
	ACCEPTOR_SETTINGS acceptorSettings;
	CURRENCY currency;
	CURRENCY_MANAGER currencyManager;
	CIM_MANAGER cimManager;
	CURRENCY lastCurrency = NULL;
	ZCLOSE lastZClose;
	BOOL hasDeposit = TRUE;
	USER user;
	USER_MANAGER userManager;
	DOOR door;
	CIM_CASH cimCash;
	datetime_t lastZCloseCloseTime = 0;
	CASH_REFERENCE_MANAGER cashReferenceManager;
	CASH_REFERENCE cashReference;

	// Obtengo los objetos que luego voy a utilizar
	currencyManager = [CurrencyManager getInstance];
	cimManager = [CimManager getInstance];
	userManager = [UserManager getInstance];
	cashReferenceManager = [CashReferenceManager getInstance];

	zClose = [ZClose new];

	depositRS = [[[Persistence getInstance] getDepositDAO] getNewDepositRecordSet];
	[depositRS open];

	depositDetailRS = [[[Persistence getInstance] getDepositDAO] getNewDepositDetailRecordSet];
	[depositDetailRS open];

	// Levanto el ultimo cierre Z
	lastZCloseCloseTime = [[[Persistence getInstance] getZCloseDAO] getLastZCloseCloseTime];
  myLastZCloseTime = lastZCloseCloseTime;
  
	// Levanto el ultimo cierre Z que tenga depositos efectuados
	lastZClose = [[[Persistence getInstance] getZCloseDAO] loadLastWithDeposits];

	if ([[CimGeneralSettings getInstance] getNextZNumber] > myLastZCloseNumber) {
		myLastZCloseNumber = [[CimGeneralSettings getInstance] getNextZNumber] - 1;
	}
	[zClose setNumber: myLastZCloseNumber + 1];
	[zClose setOpenTime: lastZCloseCloseTime];

	// Si existe un ultimo cierre Z entonces tengo que localizar
	// el deposito siguiente al ultimo efectuado en ese cierre Z
	// Si no existe un ultimo cierre Z, recorro desde el principio
	if (lastZClose) {
		[zClose setFromCloseNumber: [lastZClose getToCloseNumber] + 1];
	} else {
		[zClose setFromCloseNumber: 1];
	}

	if (lastZClose != NULL && [lastZClose getToDepositNumber] > 0) {
		fromDepositNumber = [lastZClose getToDepositNumber] + 1;
		hasDeposit = [depositRS findById: "NUMBER" value: fromDepositNumber];
    //************************* logcoment
//		doLog(0,"ZCloseManager -> buscando depositos a partir del %ld, hay depositos? = %d\n", fromDepositNumber, hasDeposit);
	} else {
		[depositRS moveFirst];
    //************************* logcoment
//		doLog(0, "ZCloseManager -> buscando a partir del primer deposito\n");
	}

	[depositDetailRS moveFirst];

	// Recorro hasta el fin del recordset de depositos

	while (hasDeposit && ![depositRS eof]) {

		// Si no tiene fecha de apertura, le pongo la fecha del primer deposito
		if ([zClose getOpenTime] == 0) [zClose setOpenTime: [depositRS getDateTimeValue: "OPEN_TIME"]];

		// Asigno el numero de deposito inicial (si corresponde) y final
		number = [depositRS getLongValue: "NUMBER"];
		if (fromDepositNumber == 0) fromDepositNumber = number;
		toDepositNumber = number;

		user = [userManager getUserFromCompleteList: [depositRS getLongValue: "USER_ID"]];
		cimCash = [cimManager getCimCashById: [depositRS getShortValue: "CIM_CASH_ID"]];
		door = [cimManager getDoorById: [depositRS getShortValue: "DOOR_ID"]];
		cashReference = NULL;
		if ([depositRS getShortValue: "REFERENCE_ID"] != 0) 
			cashReference = [cashReferenceManager getCashReferenceById: [depositRS getShortValue: "REFERENCE_ID"]];

		// Verifico si tiene detalles, en primer lugar me dijo si ya estoy parado
		// en el detalle correspondiente (muy probablemente) y sino lo busco
		// Luego recorro cada uno de los detalles mientras el numero de deposito coincida.

		if ((![depositDetailRS eof] && [depositDetailRS getLongValue: "NUMBER"] == number) ||
				[depositDetailRS findFirstById: "NUMBER" value: number]) {

			while (![depositDetailRS eof] && [depositDetailRS getLongValue: "NUMBER"] == number) {

				// Esto es una especide de "cache" de moneda, para no tener que ir a buscarla todo
				// el tiempo ya que es muy probable que sea la misma que la anterior
				if (lastCurrency != NULL && [lastCurrency getCurrencyId] == [depositDetailRS getShortValue: "CURRENCY_ID"]) {
					currency = lastCurrency;
				} else {
					currency = [currencyManager getCurrencyById: [depositDetailRS getShortValue: "CURRENCY_ID"]];
					lastCurrency = currency;
				}

				acceptorSettings = [cimManager getAcceptorSettingsById: [depositDetailRS getShortValue: "ACCEPTOR_ID"]];

				// Agrego el detalle
				[zClose addZCloseDetail: user
					door: door
					cimCash: cimCash
					cashReference: cashReference
					acceptorSettings: acceptorSettings
					depositValueType: [depositDetailRS getCharValue: "DEPOSIT_VALUE_TYPE"]
					currency: currency
					qty: [depositDetailRS getShortValue: "QTY"]
					amount: [depositDetailRS getMoneyValue: "AMOUNT"]];

				[depositDetailRS moveNext];

			}

		}

		[depositRS moveNext];

	}

	[zClose setFromDepositNumber: fromDepositNumber];
	[zClose setToDepositNumber: toDepositNumber];

	// Si el OpenTime es = 0 a pesar de todo, le pongo la hora actual
	if ([zClose getOpenTime] == 0) {
		[zClose setOpenTime: [SystemTime getLocalTime]];
	}

	[depositRS close];
	[depositRS free];
	[depositDetailRS close];
	[depositDetailRS free];
	if (lastZClose) [lastZClose free];

	[zClose debug];

	return zClose;

}

/*********************************************
 *
 * Carga los cierres por cash (cierres x)
 *
 *********************************************/

/**/
- (void) loadCurrentCashCloses
{
	int i;
	COLLECTION cimCashs;
	ZCLOSE currentCashClose;

    //************************* logcoment
//	doLog(0, "CARGANDO CIERRES X ACTUALES...\n");

	cimCashs = [[[CimManager getInstance] getCim] getCimCashs];

	for (i = 0; i < [cimCashs size]; ++i) {

		currentCashClose = [self loadCurrentCashClose: [cimCashs at: i]];
		[myCurrentCashCloses add: currentCashClose];

		[currentCashClose debug];

	}

}

/**/
- (ZCLOSE) loadCurrentCashClose: (CIM_CASH) aCimCash
{
	ZCLOSE lastCashClose;
	unsigned long fromDepositNumber = 0;
	ZCLOSE cashClose;
	
	lastCashClose = [[[Persistence getInstance] getZCloseDAO] loadLastCashClose: [aCimCash getCimCashId]];
	if (lastCashClose) {
		if ([lastCashClose getToDepositNumber] != 0)
			fromDepositNumber = [lastCashClose getToDepositNumber] + 1;
		else
			fromDepositNumber = [lastCashClose getFromDepositNumber];
	}

    //************************* logcoment
//	doLog(0, "Levantando cash close desde deposito %ld\n", fromDepositNumber);

	cashClose = [self loadCashClose: aCimCash fromDepositNumber: fromDepositNumber toDepositNumber: 0 useToDepositNumber: FALSE];
	if (lastCashClose) {
		[cashClose setOpenTime: [lastCashClose getCloseTime]];
	} else {
		[cashClose setOpenTime: [SystemTime getLocalTime]];
	}

	return cashClose;
}

/**/
- (ZCLOSE) loadCashClose: (CIM_CASH) aCimCash 
	fromDepositNumber: (unsigned long) aFromDepositNumber
	toDepositNumber: (unsigned long) aToDepositNumber
	useToDepositNumber: (BOOL) aUseToDepositNumber
{
	ABSTRACT_RECORDSET depositRS;
	ABSTRACT_RECORDSET depositDetailRS;
	CURRENCY currency;
	CURRENCY_MANAGER currencyManager;
	CIM_MANAGER cimManager;
	CURRENCY lastCurrency = NULL;
	money_t amount;
	ZCLOSE cashClose;
	unsigned long number;
	ACCEPTOR_SETTINGS acceptorSettings;

	cashClose = [ZClose new];
	[cashClose setFromDepositNumber: aFromDepositNumber];
	[cashClose setToDepositNumber: aToDepositNumber];
	[cashClose setCimCash: aCimCash];
	[cashClose setCloseType: CloseType_CASH_CLOSE];

	// No hay datos
	if (aUseToDepositNumber && aToDepositNumber == 0) 
		return cashClose;

	// Obtengo los objetos que luego voy a utilizar

	currencyManager = [CurrencyManager getInstance];
	cimManager = [CimManager getInstance];

	depositRS = [[[Persistence getInstance] getDepositDAO] getNewDepositRecordSet];
	[depositRS open];

	depositDetailRS = [[[Persistence getInstance] getDepositDAO] getNewDepositDetailRecordSet];
	[depositDetailRS open];

	if (aFromDepositNumber > 0) {

		if (![depositRS findFirstFromId: "NUMBER" value: aFromDepositNumber]) {
			[depositRS close];
			[depositDetailRS close];
			[depositRS free];
			[depositDetailRS free];
			return cashClose;
		}

	} else {
		[depositRS moveFirst];
	}

	[depositDetailRS moveFirst];

	// Recorro hasta el fin del recordset de depositos

	while (![depositRS eof]) {
		
		if (aToDepositNumber != 0 && [depositRS getLongValue: "NUMBER"] > aToDepositNumber) break;
		number = [depositRS getLongValue: "NUMBER"];
		if (aFromDepositNumber == 0) {
			aFromDepositNumber = number;
			[cashClose setFromDepositNumber: aFromDepositNumber];
		}

		// Solo me interesan los depositos de la puerta seleccionada
		if ([depositRS getShortValue: "CIM_CASH_ID"] == [aCimCash getCimCashId]) {

			[cashClose setToDepositNumber: number];

			// Verifico si tiene detalles, en primer lugar me dijo si ya estoy parado
			// en el detalle correspondiente (muy probablemente) y sino lo busco
			// Luego recorro cada uno de los detalles mientras el numero de deposito coincida.
			if ((![depositDetailRS eof] && [depositDetailRS getLongValue: "NUMBER"] == number) ||
					[depositDetailRS findFirstById: "NUMBER" value: number]) {

				while (![depositDetailRS eof] && [depositDetailRS getLongValue: "NUMBER"] == number) {

					// Esto es una especide de "cache" de moneda, para no tener que ir a buscarla todo
					// el tiempo ya que es muy probable que sea la misma que la anterior
					if (lastCurrency != NULL && [lastCurrency getCurrencyId] == [depositDetailRS getShortValue: "CURRENCY_ID"]) {
						currency = lastCurrency;
					} else {
						currency = [currencyManager getCurrencyById: [depositDetailRS getShortValue: "CURRENCY_ID"]];
						lastCurrency = currency;
					}

					// Agrego el detalle al cierre de cash (cierre parcial)
					if ([depositDetailRS getCharValue: "DEPOSIT_VALUE_TYPE"] == DepositValueType_VALIDATED_CASH)
						amount = [depositDetailRS getMoneyValue: "AMOUNT"] * [depositDetailRS getShortValue: "QTY"];
					else
						amount = [depositDetailRS getMoneyValue: "AMOUNT"];

          acceptorSettings = [cimManager getAcceptorSettingsById: [depositDetailRS getShortValue: "ACCEPTOR_ID"]];

					[cashClose addCashCloseDetail: aCimCash
						acceptorSettings: acceptorSettings
						depositValueType: DepositValueType_MANUAL_CASH
						currency: currency
						qty: [depositDetailRS getShortValue: "QTY"]
						amount: amount];

					[depositDetailRS moveNext];

				}

			}

		}

		[depositRS moveNext];

	}

	[depositRS close];
	[depositRS free];
	[depositDetailRS close];
	[depositDetailRS free];

	return cashClose;
}

/*********************************************
 *
 * Carga el ultimo z close
 *
 *********************************************/

/**/
- (ZCLOSE) loadLastZClose
{
	int number;

	number = [[[Persistence getInstance] getZCloseDAO] getLastZCloseNumber];
	if (number == 0) return NULL;

	return [self loadZCloseById: number];

}

/**/
- (ZCLOSE) loadZCloseById: (unsigned long) anId
{
	unsigned long fromDepositNumber = 0;
	unsigned long toDepositNumber = 0;
	unsigned long number;
	ABSTRACT_RECORDSET depositRS;
	ABSTRACT_RECORDSET depositDetailRS;
	ACCEPTOR_SETTINGS acceptorSettings;
	CURRENCY currency;
	CURRENCY_MANAGER currencyManager;
	CIM_MANAGER cimManager;
	CURRENCY lastCurrency = NULL;
	ZCLOSE lastZClose;
	BOOL hasDeposit = TRUE;
	USER user;
	USER_MANAGER userManager;
	DOOR door;
	CIM_CASH cimCash;
	CASH_REFERENCE_MANAGER cashReferenceManager;
	CASH_REFERENCE cashReference;

	// Obtengo los objetos que luego voy a utilizar
	currencyManager = [CurrencyManager getInstance];
	cimManager = [CimManager getInstance];
	userManager = [UserManager getInstance];
	cashReferenceManager = [CashReferenceManager getInstance];
  
	// Levanto el cierre Z de con el id
	lastZClose = [[[Persistence getInstance] getZCloseDAO] loadById: anId];
	if (lastZClose == NULL) return NULL;

	depositRS = [[[Persistence getInstance] getDepositDAO] getNewDepositRecordSet];
	[depositRS open];

	depositDetailRS = [[[Persistence getInstance] getDepositDAO] getNewDepositDetailRecordSet];
	[depositDetailRS open];

	fromDepositNumber = [lastZClose getFromDepositNumber];
	toDepositNumber   = [lastZClose getToDepositNumber];

	hasDeposit = (fromDepositNumber != 0);

	if (hasDeposit) {
		hasDeposit = [depositRS findById: "NUMBER" value: fromDepositNumber];
	}

	[depositDetailRS moveFirst];

	// Recorro hasta el fin del recordset de depositos

	while (hasDeposit && ![depositRS eof]) {


		// Asigno el numero de deposito inicial (si corresponde) y final
		number = [depositRS getLongValue: "NUMBER"];
		if (number > toDepositNumber) break;

		user = [userManager getUserFromCompleteList: [depositRS getLongValue: "USER_ID"]];
		cimCash = [cimManager getCimCashById: [depositRS getShortValue: "CIM_CASH_ID"]];
		door = [cimManager getDoorById: [depositRS getShortValue: "DOOR_ID"]];
		cashReference = NULL;
		if ([depositRS getShortValue: "REFERENCE_ID"] != 0) 
			cashReference = [cashReferenceManager getCashReferenceById: [depositRS getShortValue: "REFERENCE_ID"]];

		// Verifico si tiene detalles, en primer lugar me dijo si ya estoy parado
		// en el detalle correspondiente (muy probablemente) y sino lo busco
		// Luego recorro cada uno de los detalles mientras el numero de deposito coincida.

		if ((![depositDetailRS eof] && [depositDetailRS getLongValue: "NUMBER"] == number) ||
				[depositDetailRS findFirstById: "NUMBER" value: number]) {

			while (![depositDetailRS eof] && [depositDetailRS getLongValue: "NUMBER"] == number) {

				// Esto es una especide de "cache" de moneda, para no tener que ir a buscarla todo
				// el tiempo ya que es muy probable que sea la misma que la anterior
				if (lastCurrency != NULL && [lastCurrency getCurrencyId] == [depositDetailRS getShortValue: "CURRENCY_ID"]) {
					currency = lastCurrency;
				} else {
					currency = [currencyManager getCurrencyById: [depositDetailRS getShortValue: "CURRENCY_ID"]];
					lastCurrency = currency;
				}

				acceptorSettings = [cimManager getAcceptorSettingsById: [depositDetailRS getShortValue: "ACCEPTOR_ID"]];

				// Agrego el detalle
				[lastZClose addZCloseDetail: user
					door: door
					cimCash: cimCash
					cashReference: cashReference
					acceptorSettings: acceptorSettings
					depositValueType: [depositDetailRS getCharValue: "DEPOSIT_VALUE_TYPE"]
					currency: currency
					qty: [depositDetailRS getShortValue: "QTY"]
					amount: [depositDetailRS getMoneyValue: "AMOUNT"]];

				[depositDetailRS moveNext];

			}

		}

		[depositRS moveNext];

	}

	[depositRS close];
	[depositRS free];
	[depositDetailRS close];
	[depositDetailRS free];

	return lastZClose;

}

/*********************************************
 *
 * Carga el cash close
 *
 *********************************************/

/**/
- (ZCLOSE) loadLastCashClose
{
	int number;

	number = [[[Persistence getInstance] getZCloseDAO] getLastCashCloseNumber];
	if (number == 0) return NULL;

	return [self loadCashCloseById: number];

}

/**/
- (id) loadCashCloseById: (unsigned long) anId
{
	ABSTRACT_RECORDSET depositRS;
	ABSTRACT_RECORDSET depositDetailRS;
	CURRENCY currency;
	CURRENCY_MANAGER currencyManager;
	CIM_MANAGER cimManager;
	CURRENCY lastCurrency = NULL;
	money_t amount;
	ZCLOSE cashClose;
	unsigned long number;
	ACCEPTOR_SETTINGS acceptorSettings;

	cashClose = [[[Persistence getInstance] getZCloseDAO] loadCashCloseById: anId];
	if (cashClose == NULL) return NULL;

	[cashClose setCloseType: CloseType_CASH_CLOSE];

	// No hay datos
	if ([cashClose getToDepositNumber] == 0)
		return cashClose;


	// Obtengo los objetos que luego voy a utilizar

	currencyManager = [CurrencyManager getInstance];
	cimManager = [CimManager getInstance];

	depositRS = [[[Persistence getInstance] getDepositDAO] getNewDepositRecordSet];
	[depositRS open];

	depositDetailRS = [[[Persistence getInstance] getDepositDAO] getNewDepositDetailRecordSet];
	[depositDetailRS open];

	if (![depositRS findFirstFromId: "NUMBER" value: [cashClose getFromDepositNumber]]) {
		[depositRS close];
		[depositDetailRS close];
		[depositRS free];
		[depositDetailRS free];
		return cashClose;
	}


	[depositDetailRS moveFirst];

	// Recorro hasta el fin del recordset de depositos

	while (![depositRS eof]) {
		
		if ([depositRS getLongValue: "NUMBER"] > [cashClose getToDepositNumber]) break;
		number = [depositRS getLongValue: "NUMBER"];

		// Solo me interesan los depositos de la puerta seleccionada
		if ([depositRS getShortValue: "CIM_CASH_ID"] == [[cashClose getCimCash] getCimCashId]) {

			// Verifico si tiene detalles, en primer lugar me dijo si ya estoy parado
			// en el detalle correspondiente (muy probablemente) y sino lo busco
			// Luego recorro cada uno de los detalles mientras el numero de deposito coincida.
			if ((![depositDetailRS eof] && [depositDetailRS getLongValue: "NUMBER"] == number) ||
					[depositDetailRS findFirstById: "NUMBER" value: number]) {

				while (![depositDetailRS eof] && [depositDetailRS getLongValue: "NUMBER"] == number) {

					// Esto es una especide de "cache" de moneda, para no tener que ir a buscarla todo
					// el tiempo ya que es muy probable que sea la misma que la anterior
					if (lastCurrency != NULL && [lastCurrency getCurrencyId] == [depositDetailRS getShortValue: "CURRENCY_ID"]) {
						currency = lastCurrency;
					} else {
						currency = [currencyManager getCurrencyById: [depositDetailRS getShortValue: "CURRENCY_ID"]];
						lastCurrency = currency;
					}

					// Agrego el detalle al cierre de cash (cierre parcial)
					if ([depositDetailRS getCharValue: "DEPOSIT_VALUE_TYPE"] == DepositValueType_VALIDATED_CASH)
						amount = [depositDetailRS getMoneyValue: "AMOUNT"] * [depositDetailRS getShortValue: "QTY"];
					else
						amount = [depositDetailRS getMoneyValue: "AMOUNT"];

					acceptorSettings = [cimManager getAcceptorSettingsById: [depositDetailRS getShortValue: "ACCEPTOR_ID"]];

					[cashClose addCashCloseDetail: [cashClose getCimCash]
						acceptorSettings: acceptorSettings
						depositValueType: [depositDetailRS getCharValue: "DEPOSIT_VALUE_TYPE"]
						currency: currency
						qty: [depositDetailRS getShortValue: "QTY"]
						amount: amount];

					[depositDetailRS moveNext];

				}

			}

		}

		[depositRS moveNext];

	}

	[depositRS close];
	[depositRS free];
	[depositDetailRS close];
	[depositDetailRS free];

	return cashClose;
	
}

/**/
- (ZCLOSE) getCurrentZClose
{
	return myCurrentZClose;
}

/**/
- (ZCLOSE) getCurrentCashCloseForCimCash: (CIM_CASH) aCimCash
{
	int i;

	for (i = 0; i < [myCurrentCashCloses size]; ++i) {

		if ([[myCurrentCashCloses at: i] getCimCash] == aCimCash) 
			return [myCurrentCashCloses at: i];

	}

	return NULL;
}

/*********************************************
 *
 * Procesa el deposito para sumarizar los totales
 *
 *********************************************/

/**/
- (void) processDeposit: (DEPOSIT) aDeposit
{
	COLLECTION depositDetails;
	DEPOSIT_DETAIL depositDetail;
	ZCLOSE currentCashClose;
	int i;

	THROW_NULL(aDeposit);

	depositDetails = [aDeposit getDepositDetails];
	[myCurrentZClose addRejectedQty: [aDeposit getRejectedQty]];


	// Configuro el numero de deposito desde (si es que no existe)
	// y el numero de deposito hasta
	if ([myCurrentZClose getFromDepositNumber] == 0) {
		[myCurrentZClose setFromDepositNumber: [aDeposit getNumber]];
	}
	[myCurrentZClose setToDepositNumber: [aDeposit getNumber]];

	// El numero deberia ir avanzando para todos los cierres, por las dudas
	for (i = 0; i < [myCurrentCashCloses size]; ++i) {
		
		currentCashClose = [myCurrentCashCloses at: i];
		// Configuro el numero de deposito desde (si es que no existe)
		// y el numero de deposito hasta
		if ([currentCashClose getFromDepositNumber] == 0) {
			[currentCashClose setFromDepositNumber: [aDeposit getNumber]];
		}
		[currentCashClose setToDepositNumber: [aDeposit getNumber]];

	}

	currentCashClose = [self getCurrentCashCloseForCimCash: [aDeposit getCimCash]];

	// Proceso cada uno de los detalles y los agrego a los detalles de
	// la extraccion
	for (i = 0; i < [depositDetails size]; ++i) {

		depositDetail = [depositDetails at: i];

		// Agrego el detalle a la extraccion
		[myCurrentZClose addZCloseDetail: [aDeposit getUser]			
			door: [aDeposit getDoor]
			cimCash: [aDeposit getCimCash]
			cashReference: [aDeposit getCashReference]
			acceptorSettings: [depositDetail getAcceptorSettings]
			depositValueType: [depositDetail getDepositValueType]
			currency: [depositDetail getCurrency]
			qty: [depositDetail getQty]
			amount: [depositDetail getAmount]];

		// Agrego el detalle al cierre actual
		[currentCashClose addCashCloseDetail: [aDeposit getCimCash]
			acceptorSettings: [depositDetail getAcceptorSettings]
			depositValueType: DepositValueType_MANUAL_CASH
			currency: [depositDetail getCurrency]
			qty: [depositDetail getQty]
			amount: [depositDetail getTotalAmount]];
	}

}

/**/
- (void) processTempDepositDetail: (DEPOSIT) aDeposit depositDetail: (DEPOSIT_DETAIL) aDepositDetail
{
	ZCLOSE currentCashClose;

	currentCashClose = [self getCurrentCashCloseForCimCash: [aDeposit getCimCash]];

	// Agrego el detalle a la extraccion
	[myCurrentZClose addZCloseDetail: [aDeposit getUser]			
		door: [aDeposit getDoor]
		cimCash: [aDeposit getCimCash]
		cashReference: [aDeposit getCashReference]
		acceptorSettings: [aDepositDetail getAcceptorSettings]
		depositValueType: [aDepositDetail getDepositValueType]
		currency: [aDepositDetail getCurrency]
		qty: [aDepositDetail getQty]
		amount: [aDepositDetail getAmount]];

	// Agrego el detalle al cierre actual
	[currentCashClose addCashCloseDetail: [aDeposit getCimCash]
		acceptorSettings: [aDepositDetail getAcceptorSettings]
		depositValueType: DepositValueType_MANUAL_CASH
		currency: [aDepositDetail getCurrency]
		qty: [aDepositDetail getQty]
		amount: [aDepositDetail getTotalAmount]];

}

/*********************************************
 *
 * Genera el reporte de reference en base al zclose actual
 *
 *********************************************/

/**/
- (void) generateCashReferenceSummary: (BOOL) detailReport reference: (CASH_REFERENCE) reference
{
	scew_tree *tree;
	unsigned long auditNumber;
  datetime_t auditDateTime;
	CashReferenceReportParam param;

	// Audito el evento
	auditDateTime = [SystemTime getLocalTime];
  auditNumber = [Audit auditEventCurrentUserWithDate: EVENT_CASH_REFERENCE_REPORT additional: "" station: 0 datetime: auditDateTime logRemoteSystem: FALSE];	
	
  // Parametros del reporte
	param.includeDetails = detailReport;
	param.auditNumber = auditNumber;
  param.auditDateTime = auditDateTime;    
  param.cashReference = reference;

	tree = [[ReportXMLConstructor getInstance] buildXML: myCurrentZClose entityType: CASH_REFERENCE_PRT 
		isReprint: FALSE varEntity: &param];
	[[PrinterSpooler getInstance] addPrintingJob: CASH_REFERENCE_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];

}

/*********************************************
 *
 * Genera el reporte de reference en base al zclose actual
 *
 *********************************************/
/**/
- (void) generateCurrentZClose
{
	scew_tree *tree;
	ZCloseReportParam param;
	unsigned long auditNumber;
  datetime_t auditDateTime;
  char additional[20];
	
	// Audito el evento
	sprintf(additional, "%ld", [myCurrentZClose getNumber]);
	auditDateTime = [SystemTime getLocalTime];
  auditNumber = [Audit auditEventCurrentUserWithDate: AUDIT_CIM_ZCLOSE additional: additional station: 0 datetime: auditDateTime logRemoteSystem: FALSE];	
	
  // Parametros del reporte
	param.user = NULL;
  param.includeDetails = FALSE;
	param.auditNumber = auditNumber;
  param.auditDateTime = auditDateTime;    
  	
	tree = [[ReportXMLConstructor getInstance] buildXML: myCurrentZClose entityType: CIM_XCLOSE_PRT isReprint: FALSE varEntity: &param];
	[[PrinterSpooler getInstance] addPrintingJob: CIM_ZCLOSE_PRT 
		copiesQty: [[CimGeneralSettings getInstance] getXCopiesQty]
		ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];
}

/*********************************************
 * REPORTE
 * Genera el reporte de usuarios en base al z actual
 *
 *********************************************/

/**/
- (BOOL) generateUserReports: (ZCLOSE) aZClose includeDetail: (BOOL) aIncludeDetail
{
	COLLECTION users;
	int i;
	BOOL found;
	BOOL vHeader = TRUE;
	BOOL vFooter = TRUE;

	users = [aZClose getUsersList];
	found = [users size] > 0;

	if ([users size] > 1){
			vHeader = TRUE;
			vFooter = FALSE;
	}

	for (i = 0; i < [users size]; ++i) {

		if (i == 1)
			vHeader = FALSE;

		if (i == ([users size] - 1))
			vFooter = TRUE;

		[self generateUserReport: aZClose user: [users at: i] includeDetail: aIncludeDetail resumeReport: TRUE viewHeader: vHeader viewFooter: vFooter];
	}

	[users free];
	return found;
}


/**/
- (BOOL) generateUserReports: (BOOL) aIncludeDetail resumeReport: (BOOL) aResumeReport
{
	COLLECTION users;
	int i;
	BOOL found;
	BOOL vHeader = TRUE;
	BOOL vFooter = TRUE;

	users = [myCurrentZClose getUsersList];
	found = [users size] > 0;

	if (aResumeReport != FALSE){
	  if ([users size] > 1){
			vHeader = TRUE;
			vFooter = FALSE;
		}
	}

	for (i = 0; i < [users size]; ++i) {
		
		if (aResumeReport != FALSE){
			if (i == 1)
				vHeader = FALSE;

			if (i == ([users size] - 1))
				vFooter = TRUE;
		}

		[self generateUserReport: [users at: i] includeDetail: aIncludeDetail resumeReport: aResumeReport viewHeader: vHeader viewFooter: vFooter];
	}

	[users free];
	return found;
}

/**/
- (BOOL) generateUserReports: (BOOL) aIncludeDetail
{
	return [self generateUserReports: aIncludeDetail resumeReport: FALSE];
}

/**/
- (void) generateUserReport: (USER) aUser includeDetail: (BOOL) aIncludeDetail
{
	[self generateUserReport: (USER) aUser includeDetail: (BOOL) aIncludeDetail resumeReport: FALSE viewHeader: FALSE viewFooter: FALSE];
}

/**/
- (void) generateUserReport: (USER) aUser includeDetail: (BOOL) aIncludeDetail resumeReport: (BOOL) aResumeReport viewHeader: (BOOL) aViewHeader viewFooter: (BOOL) aViewFooter
{
	scew_tree *tree;
	ZCloseReportParam param;
	unsigned long auditNumber;
  datetime_t auditDateTime;
  char additional[20];
	BOOL viewLogo;

  // Limpia todas las Insta Drop para el usuario
	[[InstaDropManager getInstance] clearInstaDropByUser: aUser];

	// Limpia todos los Extended Drop para el usuario
	[[CimManager getInstance] endAllExtendedDropsForUser: aUser];

	// Configuro el usuario
	[myCurrentZClose setUser: aUser];

	// Audito el evento
	sprintf(additional, "%s %ld", getResourceStringDef(RESID_ACTUAL_Z_DESC, "Z Actual"), [myCurrentZClose getNumber]);
	auditDateTime = [SystemTime getLocalTime];
  auditNumber = [Audit auditEventCurrentUserWithDate: Event_OPERATOR_REPORT additional: additional station: 0 datetime: auditDateTime logRemoteSystem: FALSE];

  // Parametros para generar el reporte
  param.user = aUser;
  param.includeDetails = aIncludeDetail;
	param.auditNumber = auditNumber;
  param.auditDateTime = auditDateTime;
	param.resumeReport = aResumeReport;
	param.viewHeader = aViewHeader;
	param.viewFooter = aViewFooter;

	// Imprimo el reporte de Operador
	tree = [[ReportXMLConstructor getInstance] buildXML: myCurrentZClose entityType: CIM_OPERATOR_PRT isReprint: FALSE varEntity: &param];

	viewLogo = [[CimGeneralSettings getInstance] getPrintLogo];
	if (aResumeReport == TRUE)
		if (!aViewHeader)
			viewLogo = FALSE;

	[[PrinterSpooler getInstance] addPrintingJob: CIM_OPERATOR_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: viewLogo];
}

/**/
- (void) generateUserReport: (ZCLOSE) aZClose user: (USER) aUser includeDetail: (BOOL) aIncludeDetail resumeReport: (BOOL) aResumeReport viewHeader: (BOOL) aViewHeader viewFooter: (BOOL) aViewFooter
{
	scew_tree *tree;
	ZCloseReportParam param;
	unsigned long auditNumber;
  datetime_t auditDateTime;
  char additional[20];
	BOOL viewLogo;

	// Configuro el usuario
	[aZClose setUser: aUser];

	// Audito el evento
	sprintf(additional, "%s %ld", getResourceStringDef(RESID_ACTUAL_Z_DESC, "Z Actual"), [aZClose getNumber]);
	auditDateTime = [SystemTime getLocalTime];
  auditNumber = [Audit auditEventCurrentUserWithDate: Event_OPERATOR_REPORT additional: additional station: 0 datetime: auditDateTime logRemoteSystem: FALSE];

  // Parametros para generar el reporte
  param.user = aUser;
  param.includeDetails = aIncludeDetail;
	param.auditNumber = auditNumber;
  param.auditDateTime = auditDateTime;
	param.resumeReport = aResumeReport;
	param.viewHeader = aViewHeader;
	param.viewFooter = aViewFooter;
  
	// Imprimo el reporte de Operador
	tree = [[ReportXMLConstructor getInstance] buildXML: aZClose entityType: CIM_OPERATOR_PRT isReprint: TRUE varEntity: &param];

	viewLogo = [[CimGeneralSettings getInstance] getPrintLogo];
	if (aResumeReport == TRUE)
		if (!aViewHeader)
			viewLogo = FALSE;

	[[PrinterSpooler getInstance] addPrintingJob: CIM_OPERATOR_PRT copiesQty: 1 ignorePaperOut: FALSE tree: tree additional: viewLogo];
}


/*********************************************
 * REPORTE
 * Genera el reporte de fin de dia y junto con eso emite todos los cierres 
 * de todos los cash
 *
 *********************************************/

/**/
- (void) generateZClose: (BOOL) aPrintOperatorReports
{
	scew_tree *tree;
	char additional[20];
	datetime_t closeTime;
	ZCloseReportParam param;
	unsigned long auditNumber;
  datetime_t auditDateTime;	
	int i;
	unsigned long toCloseNumber;
	id telesup = NULL;

	// Limpia todas las Insta Drop
	[[InstaDropManager getInstance] clearAll];

	// Termino todos los extended Drops pendientes
	[[CimManager getInstance] endAllExtendedDrops];

	// Imprime los reportes de operador
	if (aPrintOperatorReports) [self generateUserReports: FALSE resumeReport: TRUE];

	// Asigno al usuario que esta activo en este momento
	[myCurrentZClose setUser: [[UserManager getInstance] getUserLoggedIn]];

	// Configuro la fecha/hora de la extraccion
	closeTime = [SystemTime getLocalTime];
	[myCurrentZClose setCloseTime: closeTime];
  myLastZCloseTime = closeTime;

	// Genera todos los cierres X correspondientes, deberia tomar el numero de cierre desde
	// y numero de cierre hasta
	[self generateCashClosesForAllCashs: closeTime];
	  
	[myCurrentZClose setToCloseNumber: myLastCashCloseNumber];
	toCloseNumber = [myCurrentZClose getToCloseNumber];

	// Guardo la extraccion
	[[[Persistence getInstance] getZCloseDAO] store: myCurrentZClose];

	// Audito el evento
	sprintf(additional, "%s %ld", getResourceStringDef(RESID_REPRINT_Z_DESC, "Z"), [myCurrentZClose getNumber]);
	auditDateTime = [SystemTime getLocalTime];
  auditNumber = [Audit auditEventCurrentUserWithDate: Event_GRAND_Z additional: additional station: 0 datetime: auditDateTime logRemoteSystem: FALSE];  

	// Imprimo el reporte X
	param.user = NULL;
  param.includeDetails = FALSE;
	param.auditNumber = auditNumber;
  param.auditDateTime = auditDateTime;

	// Genero el reporte  
	tree = [[ReportXMLConstructor getInstance] buildXML: myCurrentZClose 
		entityType: CIM_ZCLOSE_PRT isReprint: FALSE varEntity: &param];
	[[PrinterSpooler getInstance] addPrintingJob: CIM_ZCLOSE_PRT 
		copiesQty: [[CimGeneralSettings getInstance] getZCopiesQty]
		ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];

#ifdef __CIM_DEBUG
	//[myCurrentZClose debug];
#endif

	// Limpio la extraccion (resetea los valores en 0) y configura
	// el nuevo numero de Z
	myLastZCloseNumber = [myCurrentZClose getNumber];

	if ([[CimGeneralSettings getInstance] getNextZNumber] > myLastZCloseNumber) {
		myLastZCloseNumber = [[CimGeneralSettings getInstance] getNextZNumber] - 1;
	}

	[myCurrentZClose clear];
	[myCurrentZClose setNumber: myLastZCloseNumber + 1];
	[myCurrentZClose setOpenTime: closeTime];
	[myCurrentZClose setFromCloseNumber: toCloseNumber + 1];

	// Como se generaron nuevos cierres debo agregarlos a la extraccion actual
	for (i = 0; i < [myCurrentCashCloses size]; ++i) {
		[[ExtractionManager getInstance] addCurrentCashClose: [myCurrentCashCloses at: i]];
	}


		/* supervisa si:
		1.existe la supervision
		2.esta configurada online el envio de zclose en la telesup
		*/
	
		telesup = [[TelesupervisionManager getInstance] getTelesupByTelcoType: PIMS_TSUP_ID];
	
		if ( telesup && [telesup getInformZCloseByTransaction] ) {
	
			[[TelesupScheduler getInstance] setCommunicationIntention: CommunicationIntention_INFORM_Z_CLOSE];
			[[TelesupScheduler getInstance] startTelesupInBackground];
		}

}

/*********************************************
 * 
 * Carga los cierres de cash para asignarselos a la extraccion correspondiente
 *
 *********************************************/

/**/
- (BOOL) inStartDay
{
	int startDay;
	int endDay;
	int current;
	struct tm currentBrokenTime;

	// Si tengo configurado el AutoPrint en FALSE   
	if (![[CimGeneralSettings getInstance] getAutoPrint]) return FALSE;

	startDay = [[CimGeneralSettings getInstance] getStartDay];
	endDay   = [[CimGeneralSettings getInstance] getEndDay];

	// Si ya imprimio el cierre de hoy
	if ([self hasAlreadyPrintZClose]) {

		// Lo imprimio despues del startDay, entonces no lo genero nuevamente
		if ([self getLastZCloseMinute] >= startDay) return FALSE;
		// No tiene nuevos detalles, no lo imprimo
		else if (![myCurrentZClose hasDetails]) return FALSE;

	}

  [SystemTime decodeTime: [SystemTime getLocalTime] brokenTime: &currentBrokenTime];

	current = currentBrokenTime.tm_hour * 60 + currentBrokenTime.tm_min;

	if (current >= startDay && current <= endDay) return TRUE;
	
	return FALSE;
}

/**/
- (int) getLastZCloseMinute
{
 	struct tm lastZCloseBrokenTime;

  [SystemTime decodeTime: myLastZCloseTime brokenTime: &lastZCloseBrokenTime];

	return lastZCloseBrokenTime.tm_hour * 60 + lastZCloseBrokenTime.tm_min;
}

/**/
- (BOOL) hasAlreadyPrintZClose
{
  struct tm lastZCloseBrokenTime;
  struct tm currentBrokenTime;

  if (myLastZCloseTime == 0) return FALSE;

  [SystemTime decodeTime: myLastZCloseTime brokenTime: &lastZCloseBrokenTime];
  [SystemTime decodeTime: [SystemTime getLocalTime] brokenTime: &currentBrokenTime];
  
  if (lastZCloseBrokenTime.tm_year == currentBrokenTime.tm_year &&
      lastZCloseBrokenTime.tm_mon == currentBrokenTime.tm_mon &&
      lastZCloseBrokenTime.tm_mday == currentBrokenTime.tm_mday)
    return TRUE;
    
  return FALSE;
}

/**/
- (void) checkEndOfDayHandler
{
	int startDay;
	int endDay;
	int current;
	struct tm currentBrokenTime;

	// Si tengo configurado el AutoPrint en FALSE
	if (![[CimGeneralSettings getInstance] getAutoPrint]) return;

	// Si estoy haciendo depositos manuales o validados o extracciones, no se imprime el z
	if (![[CimManager getInstance] isSystemIdleForAutoZClose]) return;

	startDay = [[CimGeneralSettings getInstance] getStartDay];
	endDay   = [[CimGeneralSettings getInstance] getEndDay];

	// Si no se imprimio el cierre de hoy sigo analizando
	if ([self hasAlreadyPrintZClose]) return;

	// Verifica si llego al End Of Day (el minuto debe coincidir exactamente)
  [SystemTime decodeTime: [SystemTime getLocalTime] brokenTime: &currentBrokenTime];
	current = currentBrokenTime.tm_hour * 60 + currentBrokenTime.tm_min;
  if (current < endDay) return;

	// Genero el cierre Z
	[self generateZClose: [[CimGeneralSettings getInstance] getPrintOperatorReport] == PrintOperatorReport_ALWAYS];

}

/**/
- (unsigned long) getLastZNumber
{
	return myLastZCloseNumber;
}


/**/
- (COLLECTION) loadCashCloses: (COLLECTION) aCimCashes
	fromCloseNumber: (unsigned long) aFromCloseNumber
	toCloseNumber: (unsigned long) aToCloseNumber
{
	COLLECTION cashCloses = [Collection new];
	ABSTRACT_RECORDSET cashCloseRS;
	ZCLOSE cashClose;
	unsigned long zCloseNumber = 0;
	datetime_t zCloseTime = 0;
	int i;
	CIM_CASH cimCash;

	cashCloseRS = [[[Persistence getInstance] getZCloseDAO] getNewZCloseRecordSet];
	[cashCloseRS open];

	//doLog(0, "Cargando desde el Close %d al %d\n", aFromCloseNumber, aToCloseNumber);

	if ([cashCloseRS moveLast]) {

		do {
			// Si es un Z, tomo los datos para despues asignarselos al X
			if ([cashCloseRS getCharValue: "CLOSE_TYPE"] == CloseType_END_OF_DAY) {
				zCloseNumber = [cashCloseRS getLongValue: "NUMBER"];
				zCloseTime = [cashCloseRS getDateTimeValue: "CLOSE_TIME"];
			}

			if ([cashCloseRS getCharValue: "CLOSE_TYPE"] == CloseType_CASH_CLOSE &&
					[cashCloseRS getLongValue: "NUMBER"] >= aFromCloseNumber &&
					(aToCloseNumber == 0 || [cashCloseRS getLongValue: "NUMBER"] <= aToCloseNumber)) {

				cimCash = NULL;

				// Verifico si el cash que se esta analizando corresponde con alguno pasado como parametro
				for (i = 0; i < [aCimCashes size]; ++i) {
					if ([cashCloseRS getShortValue: "CIM_CASH_ID"] == [[aCimCashes at: i] getCimCashId]) {
						cimCash = [aCimCashes at: i];
						break;
					}
				}

				if (cimCash != NULL) {
					cashClose = [self loadCashClose: cimCash
						fromDepositNumber: [cashCloseRS getLongValue: "FROM_DEPOSIT_NUMBER"] 
						toDepositNumber: [cashCloseRS getLongValue: "TO_DEPOSIT_NUMBER"] 
						useToDepositNumber: TRUE];

					[cashClose setNumber: [cashCloseRS getLongValue: "NUMBER"]];
					[cashClose setOpenTime: [cashCloseRS getDateTimeValue: "OPEN_TIME"]];
					[cashClose setCloseTime: [cashCloseRS getDateTimeValue: "CLOSE_TIME"]];
					[cashClose setParentNumber: zCloseNumber];
					[cashClose setParentCloseTime: zCloseTime];

					[cashCloses at: 0 insert: cashClose];
				}
			}
		} while ([cashCloseRS movePrev]);

	}

	[cashCloseRS close];
	[cashCloseRS free];

	return cashCloses;

}

/*********************************************
 * 
 * Genera el cierre de cash
 *
 *********************************************/

/**/
- (void) generateCashClose: (ZCLOSE) aCashClose 
	user: (USER) aUser 
	closeTime: (datetime_t) aCloseTime
{
	int index;
	ZCLOSE newCashClose;

	myLastCashCloseNumber++;

	[aCashClose setCloseTime: aCloseTime];
	[aCashClose setNumber: myLastCashCloseNumber];
	[aCashClose setUser: aUser];

	if ([myCurrentZClose getCloseTime] > 0)
		[aCashClose setParentNumber: [myCurrentZClose getNumber]];

	[aCashClose setParentCloseTime: [myCurrentZClose getCloseTime]];

	[[[Persistence getInstance] getZCloseDAO] store: aCashClose];

	/* Mando a imprimir el cierre parcial */
	[self printCashClose: aCashClose];

	index = [myCurrentCashCloses offsetOf: aCashClose];
	
	// Creo el nuevo Cash Close (siempre hay uno abierto)
	newCashClose = [ZClose new];

	if ([aCashClose getToDepositNumber] == 0)
		[newCashClose setFromDepositNumber: [aCashClose getFromDepositNumber]];
	else
		[newCashClose setFromDepositNumber: [aCashClose getToDepositNumber] + 1];

	[newCashClose setToDepositNumber: 0];
	[newCashClose setCimCash: [aCashClose getCimCash]];
	[newCashClose setCloseType: CloseType_CASH_CLOSE];
	[newCashClose setOpenTime: [aCashClose getCloseTime]];
	if ([newCashClose getOpenTime] == 0)
		[newCashClose setOpenTime: [SystemTime getLocalTime]];

	// Remuevo el anterior e inserto el nuevo
	[myCurrentCashCloses removeAt: index];
	[myCurrentCashCloses at: index insert: newCashClose];

}

/*********************************************
 * 
 * Genera el cierre para todos los cash
 *
 *********************************************/

/**/
- (void) generateCashClosesForAllCashs: (datetime_t) aCloseTime
{
	int i;

	for (i = 0; i < [myCurrentCashCloses size]; ++i) {
		[self generateCashClose: [myCurrentCashCloses at: i] 
			user: [myCurrentZClose getUser]
			closeTime: aCloseTime];
	}

	//return myCurrentCashCloses;
}

/*********************************************
 * 
 * Genera el cierre para una puerta
 *
 *********************************************/

/**/
- (void) generateCashCloseForDoor: (DOOR) aDoor user: (USER) aUser closeTime: (datetime_t) aCloseTime
{
	int i;
	ZCLOSE cashClose;

	for (i = 0; i < [myCurrentCashCloses size]; ++i) {
		cashClose = [myCurrentCashCloses at: i];
		if ([[cashClose getCimCash] getDoor] != aDoor) continue;
		[self generateCashClose: cashClose user: aUser closeTime: aCloseTime];
	}

}


/*********************************************
 * 
 * Imprime el cierre de cash
 *
 *********************************************/

/**/
- (void) printCashClose: (ZCLOSE) aCashClose
{
	scew_tree *tree;
  unsigned long auditNumber = 0;
  datetime_t auditDateTime = 0;	
  ZCloseReportParam xParam;
  char additional[100];
  
	// Audito el evento
	auditDateTime = [SystemTime getLocalTime];
  sprintf(additional, "%s %ld", getResourceStringDef(RESID_PARTIAL_DAY_DESC, "Parcial"), [aCashClose getNumber]);
  auditNumber = [Audit auditEvent: [aCashClose getUser] eventId: AUDIT_CIM_PARTIAL_DAY additional: additional station: [[aCashClose getCimCash] getCimCashId] logRemoteSystem: FALSE];
  
  xParam.user = NULL; //no se usa para el Cash Close
  xParam.includeDetails = FALSE; //no se usa para el Cash Close
  xParam.auditNumber = auditNumber;
	xParam.auditDateTime = auditDateTime;
  
	// Imprimo el X o cash close
	tree = [[ReportXMLConstructor getInstance] buildXML: aCashClose entityType: CIM_X_CASH_CLOSE_PRT isReprint: FALSE varEntity: &xParam];		
  [[PrinterSpooler getInstance] addPrintingJob: CIM_X_CASH_CLOSE_PRT 
		copiesQty: [[CimGeneralSettings getInstance] getXCopiesQty]
		ignorePaperOut: FALSE tree: tree additional: [[CimGeneralSettings getInstance] getPrintLogo]];

}

/**/
- (BOOL) hasUserMovements: (USER) aUser
{
	COLLECTION users;
	int i;
	BOOL found;

	users = [myCurrentZClose getUsersList];
	found = FALSE;

	for (i = 0; i < [users size]; ++i) {
		if ([users at: i] == aUser)
      found = TRUE;
	}

	[users free];
	return found;
}

/**/
- (void) addNewCashClose: (CIM_CASH) aCimCash
{
	ZCLOSE cashClose;

	if (![[CimGeneralSettings getInstance] getUseEndDay]) return;

    //************************* logcoment
//	doLog(0, "ZCloseManager -> Agrego el cash close a los cierres actuales\n");
	cashClose = [ZClose new];
	[cashClose setFromDepositNumber: 0];
	[cashClose setToDepositNumber: 0];
	[cashClose setCimCash: aCimCash];
	[cashClose setCloseType: CloseType_CASH_CLOSE];

	[myCurrentCashCloses add: cashClose];

	[[ExtractionManager getInstance] addCurrentCashClose: cashClose];

}

@end
