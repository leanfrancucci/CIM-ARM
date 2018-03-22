#include "CashReferenceSummary.h"

@implementation CashReferenceSummary

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myCashReference = NULL;
	myCurrency = NULL;
	myAmount = 0;
	myDepositValueType = DepositValueType_UNDEFINED;
	myDepositType = DepositType_UNDEFINED;
	myValAmount = 0;
	myManualAmount = 0;
	myManualQty = 0;
	return self;
}

/**/
+ (CASH_REFERENCE_SUMMARY) newCashReferenceSummary: (CASH_REFERENCE) aCashReference
	currency: (CURRENCY) aCurrency
	amount: (money_t) anAmount
{
	CASH_REFERENCE_SUMMARY summary;
	summary = [CashReferenceSummary new];
	[summary setCashReference: aCashReference];
	[summary setCurrency: aCurrency];
	[summary addAmount: anAmount];
	return summary;
}

/**/
+ (CASH_REFERENCE_SUMMARY) newCashReferenceSummary: (CASH_REFERENCE) aCashReference
	currency: (CURRENCY) aCurrency
	amount: (money_t) anAmount
	depositValueType: (DepositValueType) aDepositValueType
	depositType: (DepositType) aDepositType
{
	CASH_REFERENCE_SUMMARY summary;
	summary = [CashReferenceSummary new];
	[summary setCashReference: aCashReference];
	[summary setCurrency: aCurrency];
	[summary addAmount: anAmount];
	[summary setDepositValueType: aDepositValueType];
	[summary setDepositType: aDepositType];
	return summary;
}

+ (CASH_REFERENCE_SUMMARY) newCashReferenceSummary: (CASH_REFERENCE) aCashReference
	currency: (CURRENCY) aCurrency
	amount: (money_t) anAmount
	valAmount: (money_t) aValAmount
	manualAmount: (money_t) aManualAmount
	manualQty: (int) aManualQty
{
	CASH_REFERENCE_SUMMARY summary;
	summary = [CashReferenceSummary new];
	[summary setCashReference: aCashReference];
	[summary setCurrency: aCurrency];
	[summary addAmount: anAmount];
	[summary addValAmount: aValAmount];	
	[summary addManualAmount: aManualAmount];
	[summary addManualQty: aManualQty];
	return summary;

}


/**/
- (CASH_REFERENCE) getCashReference;

/**/
- (void) setCashReference: (CASH_REFERENCE) aCashReference { myCashReference = aCashReference; }
- (CASH_REFERENCE) getCashReference { return myCashReference; }

/**/
- (money_t) getAmount { return myAmount; }
- (void) addAmount: (money_t) anAmount { myAmount += anAmount; }

/**/
- (money_t) getValAmount { return myValAmount; }
- (void) addValAmount: (money_t) anAmount { myValAmount += anAmount; }

/**/
- (money_t) getManualAmount { return myManualAmount; }
- (void) addManualAmount: (money_t) anAmount { myManualAmount += anAmount; };

/**/
- (int) getManualQty { return myManualQty; }
- (void) addManualQty: (int) aManualQty { myManualQty += aManualQty; }

/**/
- (void) setCurrency: (CURRENCY) aCurrency { myCurrency = aCurrency; }
- (CURRENCY) getCurrency { return myCurrency; }

/**/
- (void) setDepositValueType: (DepositValueType) aDepositValueType { myDepositValueType = aDepositValueType; }
- (DepositValueType) getDepositValueType { return myDepositValueType; }

/**/
- (void) setDepositType: (DepositType) aDepositType { myDepositType = aDepositType; }
- (DepositType) getDepositType { return myDepositType; }

@end
