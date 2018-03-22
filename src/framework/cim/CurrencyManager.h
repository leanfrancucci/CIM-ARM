#ifndef CURRENCY_MANAGER_H
#define CURRENCY_MANAGER_H

#define CURRENCY_MANAGER id

#include <Object.h>
#include "system/util/all.h"
#include "Currency.h"

/**
 *	Administra la coleccion de monedas.
 *	<<singleton>>
 */
@interface CurrencyManager : Object
{
	COLLECTION myCurrencies;
	COLLECTION myCurrencyMap;
}

/**
 *  Devuelve la unica instancia posible de esta clase
 */
+ getInstance;

/**
 *	Devuelve la lista de monedas.
 */
- (COLLECTION) getCurrencies;

/**
 *	Devuelve la moneda correspondiente para el Id pasado como parametro.
 */
- (CURRENCY) getCurrencyById: (int) aCurrencyId;

/**
 *	Devuelve la moneda correspondiente para el codigo pasado como parametro.
 */
- (CURRENCY) getCurrencyByCode: (char *) aCurrencyCode;

/**
 * Devuelve la lista de id de currencies.
 */
- (COLLECTION) getCurrenciesIdList;

/**/
- (CURRENCY) getCurrencyByCountryCode: (int) aCountryCode;

@end

#endif
