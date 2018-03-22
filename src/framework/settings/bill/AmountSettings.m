#include "AmountSettings.h"
#include "Persistence.h"
#include "SettingsExcepts.h"
#include "UserManager.h"
#include "Audit.h"
#include "MessageHandler.h"

static id singleInstance = NULL;

@implementation AmountSettings

static char myAmountSettingsMessageString[] 		= "Configuracion";

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}

/**/
+ getInstance
{
	return [self new];		
}

/**/
- initialize
{
	return[[[Persistence getInstance] getAmountSettingsDAO] loadById: 1];
}

/**/
- (void) setAmountSettingsId: (int) aValue {	myAmountSettingsId= aValue; }
- (void) setRoundType: (RoundType) aValue {	myRoundType= aValue; }
- (void) setDecimalQty: (int) aValue { myDecimalQty= aValue;  }
- (void) setItemsRoundDecimalQty: (int) aValue { myItemsRoundDecimalQty= aValue; }
- (void) setSubtotalRoundDecimalQty: (int) aValue {	mySubtotalRoundDecimalQty= aValue; }
- (void) setTotalRoundDecimalQty: (int) aValue {	myTotalRoundDecimalQty= aValue; }
- (void) setTaxRoundDecimalQty: (int) aValue {	myTaxRoundDecimalQty= aValue; }
- (void) setRoundValue: (money_t) aValue {	myRoundValue= aValue; }
					
/**/	
- (int) getAmountSettingsId { return myAmountSettingsId; }
- (RoundType) getRoundType { return myRoundType; }
- (int) getDecimalQty { return myDecimalQty; }
- (int) getItemsRoundDecimalQty { return myItemsRoundDecimalQty; }
- (int) getSubtotalRoundDecimalQty { return mySubtotalRoundDecimalQty; }
- (int) getTotalRoundDecimalQty { return myTotalRoundDecimalQty; }
- (int) getTaxRoundDecimalQty { return myTaxRoundDecimalQty; }
- (money_t) getRoundValue { return myRoundValue; }

/**/
- (void) applyChanges
{
	id amountSettingsDAO;
	amountSettingsDAO = [[Persistence getInstance] getAmountSettingsDAO];		

	[amountSettingsDAO store: self];
}

/**/
- (void) restore
{
	[self initialize];
}

/**/
- (STR) str
{
  return getResourceStringDef(RESID_SAVE_CONFIGURATION_QUESTION, myAmountSettingsMessageString);
}

@end

