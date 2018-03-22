#ifndef CASH_REFERENCE_SUMMARY_H
#define CASH_REFERENCE_SUMMARY_H

#define CASH_REFERENCE_SUMMARY id

#include <Object.h>
#include "CashReference.h"
#include "Currency.h"
#include "system/lang/all.h"
#include "CimDefs.h"

/**
 *	doc template
 */
@interface CashReferenceSummary : Object
{
	CASH_REFERENCE myCashReference;
	CURRENCY myCurrency;
	money_t myAmount;
	DepositValueType myDepositValueType;
	DepositType myDepositType;
	money_t myValAmount;
	money_t myManualAmount;
	int myManualQty;
}

+ (CASH_REFERENCE_SUMMARY) newCashReferenceSummary: (CASH_REFERENCE) aCashReference
	currency: (CURRENCY) aCurrency
	amount: (money_t) anAmount;

+ (CASH_REFERENCE_SUMMARY) newCashReferenceSummary: (CASH_REFERENCE) aCashReference
	currency: (CURRENCY) aCurrency
	amount: (money_t) anAmount
	depositValueType: (DepositValueType) aDepositValueType
	depositType: (DepositType) aDepositType;

+ (CASH_REFERENCE_SUMMARY) newCashReferenceSummary: (CASH_REFERENCE) aCashReference
	currency: (CURRENCY) aCurrency
	amount: (money_t) anAmount
	valAmount: (money_t) aValAmount
	manualAmount: (money_t) aManualAmount
	manualQty: (int) aManualQty;

/**/
- (void) setCashReference: (CASH_REFERENCE) aCashReference;
- (CASH_REFERENCE) getCashReference;

/**/
- (money_t) getAmount;
- (void) addAmount: (money_t) anAmount;

/**/
- (money_t) getValAmount;
- (void) addValAmount: (money_t) anAmount;

/**/
- (money_t) getManualAmount;
- (void) addManualAmount: (money_t) anAmount;

/**/
- (int) getManualQty;
- (void) addManualQty;

/**/
- (void) setCurrency: (CURRENCY) aCurrency;
- (CURRENCY) getCurrency;


/**/
- (void) setDepositValueType: (DepositValueType) aDepositValueType;
- (DepositValueType) getDepositValueType;

/**/
- (void) setDepositType: (DepositType) aDepositType;
- (DepositType) getDepositType;

@end

#endif
