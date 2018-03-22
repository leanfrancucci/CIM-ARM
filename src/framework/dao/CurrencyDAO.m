#include "CurrencyDAO.h"
#include "Currency.h"
#include "system/db/all.h"
#include "DataSearcher.h"
#include "util.h"
#include "CimDefs.h"

static id singleInstance = NULL;

@implementation CurrencyDAO

- (id) newCurrencyFromRecordSet: (id) aRecordSet;

/**/
+ new
{
	if (!singleInstance) singleInstance = [super new];
	return singleInstance;
}

/**/
- initialize
{
	[super initialize];
	myCurrencyRS = [[DBConnection getInstance] createRecordSet: "currencies"];
	[myCurrencyRS open];
	return self;
}

/**/
- free
{
	return [super free];
}

/**/
+ getInstance
{
	return [self new];
}


/*
 *	Devuelve la configuracion de los perfiles en base a la informacion del registro actual del recordset.
 */

- (id) newCurrencyFromRecordSet: (id) aRecordSet
{
	CURRENCY obj;
	char buffer[100];

	obj = [Currency new];

	[obj setCurrencyId: [aRecordSet getShortValue: "CURRENCY_ID"]];
	[obj setName: [aRecordSet getStringValue: "CURRENCY_NAME" buffer: buffer]];
	[obj setCurrencyCode: [aRecordSet getStringValue: "CURRENCY_CODE" buffer: buffer]];

	return obj;
}

/**/
- (COLLECTION) loadAll
{
	COLLECTION collection = [Collection new];
	CURRENCY obj;

	[myCurrencyRS moveBeforeFirst];

	while ( [myCurrencyRS moveNext] ) {
		obj = [self newCurrencyFromRecordSet: myCurrencyRS];
		[collection add: obj];
	}

	return collection;
}

/**/

- (id) loadById: (unsigned long) anId
{
	CURRENCY obj;

	if (![myCurrencyRS findById: "CURRENCY_ID" value: anId]) return NULL;

	obj = [self newCurrencyFromRecordSet: myCurrencyRS];

	return obj;
}

/**/
- (void) store: (id) anObject
{
	[myCurrencyRS add];
	[myCurrencyRS setShortValue: "CURRENCY_ID" value: [anObject getCurrencyId]];
	[myCurrencyRS setStringValue: "CURRENCY_NAME" value: [anObject getName]];
	[myCurrencyRS setStringValue: "CURRENCY_CODE" value: [anObject getCurrencyCode]];
	[myCurrencyRS save];
}

/**/
- (COLLECTION) loadCurrencyMap
{
	COLLECTION collection = [Collection new];
	ABSTRACT_RECORDSET recordset = [[DBConnection getInstance] createRecordSet: "currency_map"];
	CurrencyMapping *currencyMapping;

	[recordset open];

	[recordset moveBeforeFirst];

	while ( [recordset moveNext] ) {

		currencyMapping = malloc(sizeof(CurrencyMapping));
		currencyMapping->jcmCurrencyId = [recordset getShortValue: "JCM_CURRENCY_ID"];
		currencyMapping->isoCurrencyId = [recordset getShortValue: "CURRENCY_ID"];

		[collection add: currencyMapping];
	}

	[recordset close];
	[recordset free];

	return collection;
}

@end
