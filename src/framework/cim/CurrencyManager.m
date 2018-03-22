#include "CurrencyManager.h"
#include "Persistence.h"
#include "CurrencyDAO.h"
#include "CimDefs.h"

@implementation CurrencyManager

static CURRENCY_MANAGER singleInstance = NULL;

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}
 
/**/
- initialize
{
	myCurrencies = [[[Persistence getInstance] getCurrencyDAO] loadAll];
	myCurrencyMap = [[[Persistence getInstance] getCurrencyDAO] loadCurrencyMap];
	return self;
}

/**/
+ getInstance
{
  return [self new];
}

/**/
- (COLLECTION) getCurrencies { return myCurrencies; }

/**/
- (CURRENCY) getCurrencyById: (int) aCurrencyId
{
	int i;

	for (i = 0; i < [myCurrencies size]; ++i) {
		if ([[myCurrencies at: i] getCurrencyId] == aCurrencyId) return [myCurrencies at: i];
	}

	return NULL;
}

/**/
- (CURRENCY) getCurrencyByCode: (char *) aCurrencyCode
{
	int i;

	for (i = 0; i < [myCurrencies size]; ++i) {
		if (strcmp([[myCurrencies at: i] getCurrencyCode], aCurrencyCode) == 0) return [myCurrencies at: i];
	}

	return NULL;
}

/**/
- (COLLECTION) getCurrenciesIdList
{
	COLLECTION list = [Collection new];
	int i;

	for (i = 0; i < [myCurrencies size]; ++i) {
		[list add: [BigInt int: [[myCurrencies at: i] getCurrencyId]]];
	}
	
	return list;
}

/**/
- (CURRENCY) getCurrencyByCountryCode: (int) aCountryCode
{
	int i;
	CurrencyMapping *currencyMapping;

	for (i = 0; i < [myCurrencyMap size]; ++i) {

		currencyMapping = (CurrencyMapping *)[myCurrencyMap at: i];

		if (currencyMapping->jcmCurrencyId == aCountryCode) 
			return [self getCurrencyById: currencyMapping->isoCurrencyId];

	}

	return NULL;
}

@end
