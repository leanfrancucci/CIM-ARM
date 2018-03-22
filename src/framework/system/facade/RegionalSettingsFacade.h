#ifndef REGIONAL_SETTINGS_FACADE_H
#define REGIONAL_SETTINGS_FACADE_H

#define REGIONAL_SETTINGS_FACADE id

#include <Object.h>
#include "ctapp.h"
#include "RegionalSettings.h"

/**
 *	<<singleton>>
 * Clase que maneja la configuracion regional del sistema.
 */

@interface RegionalSettingsFacade : Object
{
}

/**
 *
 */

+ new;
+ getInstance;
- initialize;

/**
* SET
*/

/*
 * DateTime
 */

- (void) setParamAsDateTime: (char*) aParam value: (datetime_t) aValue;

/*
 * MoneySymbol 
 */

- (void) setParamAsString: (char*) aParam value: (char*) aValue;

/*
 * Language (1- Spanish/2- English/3- French)
 * TimeZone
 * InitialMonth
 * InitialWeek
 * InitialDay
 * InitialHour
 * FinalMonth
 * FinalWeek
 * FinalDay
 * FinalHour
 */

- (void) setParamAsInteger: (char*) aParam value: (int) aValue;

/*
 * DSTEnable
 * BlockDateTimeChange 
 */

- (void) setParamAsBoolean: (char*) aParam value: (BOOL) aValue;


/**
* GET
*/

/*
 * DateTime
 */

- (datetime_t) getParamAsDateTime: (char*) aParam;

/*
 * MoneySymbol 
 */

- (char*) getParamAsString: (char*) aParam;

/*
 * Language
 * TimeZone
 * InitialMonth
 * InitialWeek
 * InitialDay
 * InitialHour
 * FinalMonth
 * FinalWeek
 * FinalDay
 * FinalHour
 */

- (int) getParamAsInteger: (char*) aParam;

/*
 * DSTEnable
 * BlockDateTimeChange 
 */

- (BOOL) getParamAsBoolean: (char*) aParam;

/*
 * Aplica los cambios realizados en la persistencia
 */
 
- (void) applyChanges;

@end

#endif
