#ifndef ZCLOSE_H
#define ZCLOSE_H

#define ZCLOSE id

#include <Object.h>
#include "system/util/all.h"
#include "User.h"
#include "ZCloseDetail.h"
#include "Door.h"
#include "Currency.h"
#include "AcceptorSettings.h"
#include "CimCash.h"
#include "CashReferenceSummary.h"

typedef enum {
	CloseType_END_OF_DAY
	CloseType_CASH_CLOSE
} CloseType;

/**
 *	Cierre Z (final del dia).
 */
@interface ZClose : Object
{
	unsigned long myNumber;
	USER myUser;
	unsigned long myFromDepositNumber;
	unsigned long myToDepositNumber;
	datetime_t myOpenTime;
	datetime_t myCloseTime;
	COLLECTION myZCloseDetails;
	COLLECTION myCashReferenceSummaries;
	int myRejectedQty;
	CloseType myCloseType;
	CIM_CASH myCimCash;
	BOOL myIsOpen;
	unsigned long myFromCloseNumber;
	unsigned long myToCloseNumber;
	unsigned long myParentNumber;
	datetime_t myParentCloseTime;

}

/**/
- (void) clear;

/**/
- (void) setNumber: (unsigned long) aValue;
- (unsigned long) getNumber;

/**/
- (void) setUser: (USER) aValue;
- (USER) getUser;
	
/**/
- (void) setFromDepositNumber: (unsigned long) aValue;
- (unsigned long) getFromDepositNumber;

/**/
- (void) setToDepositNumber: (unsigned long) aValue;
- (unsigned long) getToDepositNumber;

/**/
- (void) setOpenTime: (datetime_t) aValue;
- (datetime_t) getOpenTime;

/**/
- (void) setCloseTime: (datetime_t) aValue;
- (datetime_t) getCloseTime;

/**/
- (void) setRejectedQty: (int) aRejectedQty;
- (void) addRejectedQty: (int) aRejectedQty;
- (int) getRejectedQty;

/**/
- (BOOL) hasDetails;

/**/
- (COLLECTION) getZCloseDetails;

/**/
- (ZCLOSE_DETAIL) addZCloseDetail: 
		(USER) aUser
		door: (DOOR) aDoor
		cimCash: (CIM_CASH) aCimCash
		cashReference: (CASH_REFERENCE) aCashReference
		acceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings
		depositValueType: (DepositValueType) aDepositValueType
		currency: (CURRENCY) aCurrency
		qty: (int) aQty
		amount: (money_t) anAmount;

/**
 *	Devuelve la lista de detalles de deposito por usuario.
 *	La lista debe ser liberada por quien llama a este metodo (pero no el contenido).
 */
- (COLLECTION) getZCloseDetailsByUser: (USER) aUser;
- (COLLECTION) getZCloseDetailsSummary;

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

/**/
- (COLLECTION) getValidatedDetails: (COLLECTION) aSourceCollection;

/**/
- (COLLECTION) getManualDetails: (COLLECTION) aSourceCollection;

/**/
- (int) getQty: (COLLECTION) aSourceCollection;

/**/
- (money_t) getTotalAmount: (COLLECTION) aSourceCollection;

/**/
- (money_t) getTotalAmountByCurreny: (COLLECTION) aSourceCollection currency: (CURRENCY) aCurrency;

/**/
- (money_t) getCashCloseTotalAmount: (COLLECTION) aSourceCollection;

/**/
- (money_t) getCashCloseTotalAmountByCurreny: (COLLECTION) aSourceCollection currency: (CURRENCY) aCurrency;

/**
 *	Devuelven los CASH_REFERENCE que se incluyen en este Z.
 *	La lista debe ser liberada por quien invoca a este metodo (pero no el contenido)
 */
- (COLLECTION) getCashReferences;

/**
 *	Devuelven 
 *	La lista debe ser liberada por quien invoca a este metodo (pero no el contenido)
 */
- (COLLECTION) getCashReferenceSummaries: (CASH_REFERENCE) aCashReference;


/*
 * Devuelve el total de las currency de todas las cash reference
 */

- (money_t) getCashReferenceTotalAmountByCurreny: (COLLECTION) aSourceCollection currency: (CURRENCY) aCurrency reference: (CASH_REFERENCE) aReference totalManual: (money_t*) aTotalManual totalVal: (money_t*) aTotalVal manualQty: (int*) aManualQty;

/**/
- (COLLECTION) getUsersList;

/**/
- (void) setCloseType: (CloseType) aValue;
- (CloseType) getCloseType;

/**/
- (void) setCimCash: (CIM_CASH) aValue;
- (CIM_CASH) getCimCash;

/**/
- (ZCLOSE_DETAIL) addCashCloseDetail: (CIM_CASH) aCimCash
	acceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings
	depositValueType: (DepositValueType) aDepositValueType
	currency: (CURRENCY) aCurrency
	qty: (int) aQty
	amount: (money_t) anAmount;

/**/
- (BOOL) includesDeposit: (unsigned long) aDepositNumber;

- (BOOL) isOpen;

/**/
- (void) setFromCloseNumber: (unsigned long) aValue;
- (unsigned long) getFromCloseNumber;

/**/
- (void) setToCloseNumber: (unsigned long) aValue;
- (unsigned long) getToCloseNumber;

/**/
- (void) setParentNumber: (unsigned long) aValue;
- (unsigned long) getParentNumber;

/**/
- (void) setParentCloseTime: (datetime_t) aValue;
- (datetime_t) getParentCloseTime;

/**/
- (void) updateDepData: (id) aDepositRS;
- (void) updateDepDetData: (id) aDepositRS depositDetailRS: (id) aDepositDetailRS user: (id) aUser currency: (id) aCurrency;


#ifdef __DEBUG_CIM
/**/
- (void) debug;
#endif

@end

#endif
