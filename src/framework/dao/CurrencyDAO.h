#ifndef CURRENCY_DAO_H
#define CURRENCY_DAO_H

#define CURRENCY_DAO id

#include <Object.h>
#include "DataObject.h"
#include "system/util/all.h"

/**
 *	Implementacion de la persistencia de la configuracion de monedas.
 *
 *	<<singleton>>
 */
@interface CurrencyDAO : DataObject
{
	ABSTRACT_RECORDSET myCurrencyRS;
}

+ getInstance;
- (COLLECTION) loadAll;
- (COLLECTION) loadCurrencyMap;

@end

#endif
