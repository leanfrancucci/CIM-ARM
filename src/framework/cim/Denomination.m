#include "Denomination.h"
#include "system/util/all.h"

@implementation Denomination

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myAmount = 0;
	myDenominationState = DenominationState_UNDEFINED;
	myDenominationSecurity = DenominationSecurity_UNDEFINED;
	return self;
}


/**/
- (void) setAmount: (money_t) aValue { myAmount = aValue; }
- (money_t) getAmount { return myAmount; }

/**/
- (void) setDenominationState: (DenominationState) aValue { myDenominationState = aValue; }
- (DenominationState) getDenominationState { return myDenominationState; }

/**/
- (void) setDenominationSecurity: (DenominationSecurity) aValue { myDenominationSecurity = aValue; }
- (DenominationSecurity) getDenominationSecurity { return myDenominationSecurity; }

#ifdef __DEBUG_CIM
/**/
- (void) debug
{
	char *denominationStateStr[] = {"NO DEFINIDO", "Aceptado", "Rechazado"};
	char *denominationSecurityStr[] = {"NO DEFINIDO", "Standard", "Alta"};
	char moneyStr[50];

	doLog(0,"					Monto = %s, Estado = %s, Seguridad = %s\n",
		formatMoney(moneyStr, "", myAmount, 2, 40),
		denominationStateStr[myDenominationState],
		denominationSecurityStr[myDenominationSecurity]);
}
#endif

@end
