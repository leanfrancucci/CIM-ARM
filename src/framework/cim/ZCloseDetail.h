#ifndef ZCLOSE_DETAIL_H
#define ZCLOSE_DETAIL_H

#define ZCLOSE_DETAIL id

#include "Object.h"
#include "CimDefs.h"
#include "Currency.h"
#include "AcceptorSettings.h"
#include "User.h"
#include "Door.h"
#include "CimCash.h"

/**
 *	Detalle del deposito efectuado.
 *	
 */
@interface ZCloseDetail :  Object
{
	USER myUser;
	DOOR myDoor;
	CIM_CASH myCimCash;
	ACCEPTOR_SETTINGS myAcceptorSettings;		/** Validador / Buzon utilizado en el deposito */
	DepositValueType myDepositValueType;		/** Tipo de valor depositado */
	money_t myAmount;												/** Monto unitario depositado (denominacion o valor) */
	int myQty;															/** Cantidad depositada */
	CURRENCY myCurrency;										/** Moneda utilizada para el deposito */
}

/**/
- (void) setDepositValueType: (DepositValueType) aDepositValueType;
- (DepositValueType) getDepositValueType;
					
/**/
- (void) setAmount: (money_t) anAmount;
- (money_t) getAmount;
					
/**/
- (void) setQty: (int) aQty;
- (void) addQty: (int) aQty;
- (int) getQty;
					
/**/
- (void) setCurrency: (CURRENCY) aCurrency;
- (CURRENCY) getCurrency;
					
/**/
- (void) setAcceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings;
- (ACCEPTOR_SETTINGS) getAcceptorSettings;

/**
 *	Devuelve el monto total (es decir la cantidad * el monto unitario).
 */
- (money_t) getTotalAmount;

/**/
- (void) setUser: (USER) aValue;
- (USER) getUser;

/**/
- (void) setDoor: (DOOR) aValue;
- (DOOR) getDoor;

/**/
- (void) setCimCash: (CIM_CASH) aValue;
- (CIM_CASH) getCimCash;

/**/	
- (BOOL) isUnknownBill;

#ifdef __DEBUG_CIM
/**/
- (void) debug;
#endif

@end

#endif

