#ifndef EXTRACTION_H
#define EXTRACTION_H

#define EXTRACTION id

#include <Object.h>
#include "CimDefs.h"
#include "User.h"
#include "AcceptorSettings.h"
#include "Currency.h"
#include "ExtractionDetail.h"
#include "Door.h"
#include "CimCash.h"
#include "ZClose.h"

#define MAX_BANK_ACCOUNT_INFO		50

/**
 *	Representa una extraccion de la caja de seguridad.
 */
@interface Extraction : Object
{
	unsigned long myNumber;   /** Numero de extraccion */
	USER myOperator;          /** Usuario operador que realizo la extraccion (puede ser nulo = desconocido) */
	USER myCollector;         /** Usuario recaudador que realizo la extraccion (puede ser nulo = desconocido) */
	datetime_t myDateTime;    /** Fecha/hora en la cual se realizo la extraccion */
	DOOR myDoor;              /** Puerta por la cual se efectuo la extraccion */
	unsigned long myFromDepositNumber;	/** Desde que numero de deposito abarca la extraccion */
	unsigned long myToDepositNumber;		/** Hasta que numero de deposito abarca la extraccion */
	int myRejectedQty;								/** Cantidad de billetes rechazados en el deposito */
	char myBankAccountInfo[MAX_BANK_ACCOUNT_INFO + 1];
	COLLECTION myExtractionDetails;
	COLLECTION myCashCloses;
	unsigned long myFromCloseNumber;
	unsigned long myToCloseNumber;
	int myCurrentManualDepositCount;
	BOOL myHasEmitStackerFull;
	BOOL myHasEmitStackerWarning;
	COLLECTION myCashReferenceSummaries;
	char myBagNumber[50];
	COLLECTION myBagTrackingCollection;
	COLLECTION myEnvelopeTrackingCollection;
	BOOL myHasBagTracking;
	int myBagTrackingMode;
}

/**/
- (void) clear;

/**/
- (void) setOperator: (USER) aValue;
- (USER) getOperator;

/**/
- (void) setCollector: (USER) aValue;
- (USER) getCollector;

/**/
- (void) setNumber: (unsigned long) aNumber;
- (unsigned long) getNumber;
					
/**/
- (void) setDateTime: (datetime_t) aDateTime;
- (datetime_t) getDateTime;

/**/
- (void) setFromDepositNumber: (unsigned long) aValue;
- (unsigned long) getFromDepositNumber;

/**/
- (void) setToDepositNumber: (unsigned long) aValue;
- (unsigned long) getToDepositNumber;

/**/
- (void) setRejectedQty: (int) aRejectedQty;
- (void) addRejectedQty: (int) aRejectedQty;
- (int) getRejectedQty;

/**/
- (void) setDoor: (DOOR) aDoor;
- (DOOR) getDoor;

/**/
- (void) setBankAccountInfo: (char *) aBankAccountInfo;
- (char *) getBankAccountInfo;

/**/
- (COLLECTION) getExtractionDetails;

/**/
- (int) getDetailCount: (COLLECTION) aSourceCollection;

/**/
- (COLLECTION) getCimCashs: (COLLECTION) aSourceCollection;

/**/
- (COLLECTION) getDetailsByCimCash: (COLLECTION) aSourceCollection cimCash: (CIM_CASH) aCimCash;

/**/
- (COLLECTION) getAcceptorSettingsList: (COLLECTION) aSourceCollection;

/**/
- (COLLECTION) getDetailsByAcceptorSettings: (COLLECTION) aSourceCollection 
	acceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings;

/**/
- (COLLECTION) getCurrencies: (COLLECTION) aSourceCollection;

/**/
- (COLLECTION) getDetailsByCurrency: (COLLECTION) aSourceCollection currency: (CURRENCY) aCurrency;

/*
* devuelve la cantidad de billetes total de la source collection, pero si esta es NULL lo asocia a los detalles
* de la extraccion actual.
*/
- (int) getQty: (COLLECTION) aSourceCollection;

/*
* devuelve la cantidad de billetes depositados en el validador/buzon pasado por parametro
*/ 
- (int) getQtyByAcceptor: (ACCEPTOR_SETTINGS) anAcceptorSettings;

/**/
- (money_t) getTotalAmount: (COLLECTION) aSourceCollection;

/**/
- (void) setFromCloseNumber: (unsigned long) aFromCloseNumber;
- (void) setToCloseNumber: (unsigned long) aToCloseNumber;

/**/
- (unsigned long) getFromCloseNumber;
- (unsigned long) getToCloseNumber;

/**/
- (EXTRACTION_DETAIL) addExtractionDetail: (CIM_CASH) aCimCash
		acceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings
		depositValueType: (DepositValueType) aDepositValueType
		currency: (CURRENCY) aCurrency
		qty: (int) aQty
		amount: (money_t) anAmount
		cashReference: (CASH_REFERENCE) aCashReference;

/**/
- (money_t) getTotalAmountByCurreny: (COLLECTION) aSourceCollection currency: (CURRENCY) aCurrency;

/**/
- (void) addCashClose: (ZCLOSE) aCashClose;
- (ZCLOSE) getCashClose: (CIM_CASH) aCimCash depositNumber: (unsigned long) aDepositNumber;
- (COLLECTION) getCashCloses;

/**/
- (COLLECTION) getEndOfDayNumbers;
- (COLLECTION) getCashClosesForEndOfDay: (unsigned long) aCloseNumber;
- (datetime_t) getEndDayCloseTime: (unsigned long) aCloseNumber;

/**
 * Incrementa en 1 la cantidad de depositos manuales que hay en el buzon.
 */
- (void) incCurrentManualDepositCount;

/**
 * Metodos para el manejo de buzon lleno
 */
- (BOOL) hasEmitStackerWarning;
- (void) setHasEmitStackerWarning: (BOOL) aValue;
- (BOOL) hasEmitStackerFull;
- (void) setHasEmitStackerFull: (BOOL) aValue;
- (int) getCurrentManualDepositCount;

/**/
- (void) addCashReferenceSummary: (CASH_REFERENCE) aCashReference 
	currency: (CURRENCY) aCurrency 
	amount: (money_t) anAmount
	depositValueType: (DepositValueType) aDepositValueType
	depositType: (DepositType) aDepositType;

/**/
- (money_t) getCashReferenceTotalAmountByCurrenyByDepType: (COLLECTION) aSourceCollection 
	currency: (CURRENCY) aCurrency 
	reference: (CASH_REFERENCE) aReference 
	depositType: (DepositType) aDepositType;

/**/
- (money_t) getCashReferenceTotalAmountByCurrenyByDepTypeByValType: (COLLECTION) aSourceCollection 
	currency: (CURRENCY) aCurrency 
	reference: (CASH_REFERENCE) aReference 
	depositType: (DepositType) aDepositType 
	depositValueType: (DepositValueType) aDepositValueType;

/**/
- (COLLECTION) getCashReferences: (DepositType) aDepositType;

/**/
- (COLLECTION) getCashReferencesByCurr: (DepositType) aDepositType currency: (id) aCurrency;

/**/
- (COLLECTION) getCashReferenceSummaries: (CASH_REFERENCE) aCashReference;

/**/
- (COLLECTION) getDepositValueTypes: (CASH_REFERENCE) aCashReference depositType: (DepositType) aDepositType;

/**/
- (COLLECTION) getCurrenciesByDepType: (DepositType) aDepositType;

/**/
- (COLLECTION) getAllCashReferences;

/**/
- (void) setBagNumber: (char*) aBagNumber;
- (char*) getBagNumber;

/**/
- (void) setBagTrackingCollection: (COLLECTION) aCollection;
- (COLLECTION) getBagTrackingCollection;

/**/
- (void) setEnvelopeTrackingCollection: (COLLECTION) aCollection;
- (COLLECTION) getEnvelopeTrackingCollection;

/**/
- (void) setHasBagTracking: (BOOL) aValue;
- (BOOL) hasBagTracking;

/**/
- (void) setBagTrackingMode: (int) aValue;
- (int) getBagTrackingMode;

@end

#endif
