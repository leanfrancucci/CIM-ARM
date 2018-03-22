#ifndef REGIONAL_SETTINGS_H
#define REGIONAL_SETTINGS_H

#define REGIONAL_SETTINGS id

#include "Object.h"
#include "ctapp.h"

/**/
typedef enum {
	DateFormat_UNDEFINED
 ,DateFormat_DDMMYY
 ,DateFormat_MMDDYY
} DateFormat;

/**
 * 
 */

@interface RegionalSettings:  Object
{
	int myRegionalSettingsId;
	datetime_t myDateTime;
	char myMoneySymbol[10];
	LanguageType myLanguage;
	int myTimeZone;
	char sTimeZone[10];
	BOOL myDSTEnable; //Habilita el Day light saving time
	int myInitialMonth;
	int myInitialWeek;
	int myInitialDay;
	int myInitialHour;
	int myFinalMonth;
	int myFinalWeek;
	int myFinalDay;
	int myFinalHour;
	DateFormat myDateFormat;
	BOOL myBlockDateTimeChange;
}

/*
 * 
 */

+ new;
+ getInstance;
- initialize;
		
/**
 * Setea los paramatros de la configuracion regional 
 */

- (void) setRegionalSettingsId: (int) aRegionalSettingsId;
- (void) setDateTime: (datetime_t) aDateTime;
- (void) setMoneySymbol: (char *) aMoneySymbol;
- (void) setLanguage: (LanguageType) aLanguage;
- (void) setTimeZone: (int) aTimeZone;
- (void) setTimeZoneAsString: (char*) aValue;
- (void) setInitialMonth: (int) aInitialMonth;
- (void) setInitialWeek: (int) aInitialWeek;
- (void) setInitialDay: (int) aInitialDay;
- (void) setInitialHour: (int) aInitialHour;
- (void) setFinalMonth: (int) aFinalMonth;
- (void) setFinalWeek: (int) aFinalWeek;
- (void) setFinalDay: (int) aFinalDay;
- (void) setFinalHour: (int) aFinalHour;
- (void) setDSTEnable: (BOOL) aValue;
- (void) setBlockDateTimeChange: (BOOL) aValue;
- (void) setDateFormat: (DateFormat) aDateFormat;

- (char *) getDateFormatString;
- (char *) getDateTimeFormatString;


/**
 * Devuelve los parametros de la configuracion regional
 */

- (int) getRegionalSettingsId;	
- (datetime_t) getDateTime;	
- (char *) getMoneySymbol;	
- (LanguageType) getLanguage;	
- (int) getTimeZone;
- (char*) getTimeZoneAsString;
- (int) getInitialMonth;	
- (int) getInitialWeek;	
- (int) getInitialDay;	
- (int) getInitialHour;	
- (int) getFinalMonth;	
- (int) getFinalWeek;	
- (int) getFinalDay;	
- (int) getFinalHour;	
- (BOOL) getDSTEnable;
- (BOOL) getBlockDateTimeChange;
- (DateFormat) getDateFormat;

/*
 * Aplica los cambios realizados a la instancia de la configuracion regional
 */

- (void) applyChanges;

/*
 * Aplica los cambios realizados a la instancia de la configuracion regional
 */

- (void) restore;

@end

#endif

