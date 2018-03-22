#ifndef DENOMINATION_H
#define DENOMINATION_H

#define DENOMINATION id

#include <Object.h>
#include "CimDefs.h"
#include "system/lang/all.h"

/**
 *	Denominacion de un billete / moneda.
 *	Incluye basicamente el valor de la denominacion, si se encuentra rechazada / aceptada y
 * 	el nivel de seguridad que posee.
 */
@interface Denomination : Object
{
	money_t myAmount;
	DenominationState myDenominationState;
	DenominationSecurity myDenominationSecurity;
}

/**/
- (void) setAmount: (money_t) aValue;
- (money_t) getAmount;

/**/
- (void) setDenominationState: (DenominationState) aValue;
- (DenominationState) getDenominationState;

/**/
- (void) setDenominationSecurity: (DenominationSecurity) aValue;
- (DenominationSecurity) getDenominationSecurity;

#ifdef __DEBUG_CIM
/**/
- (void) debug;
#endif

@end

#endif
