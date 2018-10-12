#include "AcceptedCurrency.h"

@implementation AcceptedCurrency

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myDenominations = [Collection new];
	myCurrency = NULL;
	return self;
}

/**/
- (void) setCurrency: (CURRENCY) aValue { myCurrency = aValue; }
- (CURRENCY) getCurrency { return myCurrency; }

/**/
- (void) addDenomination: (DENOMINATION) aDenomination
{
	int i;
	BOOL exist = FALSE;

    printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>AcceptedCurrency addDenominatioN!!! %d\n", [aDenomination getAmount]);
    
	for (i = 0; i < [myDenominations size]; ++i) {
		if ([[myDenominations at: i] getAmount] == [aDenomination getAmount])
			exist = TRUE;
	}

	if (!exist){
		[myDenominations add: aDenomination];
        printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>AcceptedCurrency addEDDDDDenominatioN!!! %ld\n", [aDenomination getAmount]);
    }
    printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>AcceptedCurrency myDenominations Size!!! %d\n", [myDenominations size]);

}

/**/
- (COLLECTION) getDenominations { return myDenominations; }

/**/
- (STR) str
{
	return [myCurrency str];
}

/**/
- (DENOMINATION) getDenominationByAmount: (money_t) aDenomination
{
	int i;

	for (i=0; i<[myDenominations size]; ++i)
		if ([[myDenominations at:i] getAmount] == aDenomination) return [myDenominations at: i];

	return NULL;

}

#ifdef __DEBUG_CIM
/**/
- (void) debug
{
	int i;

	doLog(0,"		Divisa: %s\n", [myCurrency getName]);
	doLog(0,"		Denominaciones aceptadas ----------------------------------\n");
	for (i = 0; i < [myDenominations size]; ++i)
		[[myDenominations at: i] debug];
}

#endif

@end
