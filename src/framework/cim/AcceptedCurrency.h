#ifndef ACCEPTED_CURRENCY_H
#define ACCEPTED_CURRENCY_H

#define ACCEPTED_CURRENCY id

#include <Object.h>
#include "CimDefs.h"
#include "Currency.h"
#include "Denomination.h"
#include "system/util/all.h"

/**
 *	Tipo de moneda aceptado.
 *	Por cada tipo de moneda aceptado, contiene las denominaciones configuradas
 */
@interface AcceptedCurrency : Object
{
	CURRENCY myCurrency;
	COLLECTION myDenominations;
}

/**/
- (void) setCurrency: (CURRENCY) aValue;
- (CURRENCY) getCurrency;

/**/
- (void) addDenomination: (DENOMINATION) aDenomination;
- (COLLECTION) getDenominations;

/**/
- (DENOMINATION) getDenominationByAmount: (money_t) aDenomination;


#ifdef __DEBUG_CIM
/**/
- (void) debug;
#endif

@end

#endif
