#ifndef ACCEPTED_DEPOSIT_VALUE_H
#define ACCEPTED_DEPOSIT_VALUE_H

#define ACCEPTED_DEPOSIT_VALUE id

#include <Object.h>
#include "CimDefs.h"
#include "AcceptedCurrency.h"
#include "system/util/all.h"

/**
 *	Tipos de valores aceptados para un validador.
 *	Contiene el tipo de valor aceptado (efectivo, chequest) y una collecion con los tipos de divisas aceptadas para ese valor.
 */
@interface AcceptedDepositValue : Object
{
	DepositValueType myDepositValueType;
	COLLECTION myAcceptedCurrencies;
}

/**/
- (void) setDepositValueType: (DepositValueType) aValue;
- (DepositValueType) getDepositValueType;

/**/
- (void) addAcceptedCurrency: (ACCEPTED_CURRENCY) aValue;
- (COLLECTION) getAcceptedCurrencies;
- (ACCEPTED_CURRENCY) getAcceptedCurrencyByCurrencyId: (int) aCurrencyId;
- (void) addDepositValueTypeCurrency: (int) anAcceptorId currencyId: (int) aCurrencyId;
- (void) removeDepositValueTypeCurrency: (int) anAcceptorId currencyId: (int) aCurrencyId;

- (void) removeAcceptedDepositValueCurrency: (int) aCurrencyId;

#ifdef __DEBUG_CIM
/**/
- (void) debug;
#endif

@end

#endif
