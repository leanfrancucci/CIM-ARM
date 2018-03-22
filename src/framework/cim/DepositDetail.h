#ifndef DEPOSIT_DETAIL_H
#define DEPOSIT_DETAIL_H

#define DEPOSIT_DETAIL id

#include "Object.h"
#include "CimDefs.h"
#include "Currency.h"
#include "AcceptorSettings.h"

/**
 *	Detalle del deposito efectuado.
 *	
 */
@interface DepositDetail :  Object
{
	DepositValueType myDepositValueType;		/** Tipo de valor depositado */
	money_t myAmount;												/** Monto unitario depositado (denominacion o valor) */
	int myQty;															/** Cantidad depositada */
	CURRENCY myCurrency;										/** Moneda utilizada para el deposito */
	ACCEPTOR_SETTINGS myAcceptorSettings;		/** Validador / Buzon utilizado en el deposito */
	unsigned long myAdditionalId;						/** Identificador adicional (reservado) */
	char myBuf[50];													/** Un buffer para devolver el string */
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
- (BOOL) isUnknownBill;
				
/**/
- (void) setCurrency: (CURRENCY) aCurrency;
- (CURRENCY) getCurrency;
					
/**/
- (void) setAcceptorSettings: (ACCEPTOR_SETTINGS) anAcceptorSettings;
- (ACCEPTOR_SETTINGS) getAcceptorSettings;
					
/**/
- (void) setAdditionalId: (unsigned long) anAdditionalId;
- (unsigned long) getAdditionalId;
	
/**
 *	Devuelve el monto total (es decir la cantidad * el monto unitario).
 */
- (money_t) getTotalAmount;

/**/
- (char *) getDepositValueName;

#ifdef __DEBUG_CIM
/**/
- (void) debug;
#endif

@end

#endif

