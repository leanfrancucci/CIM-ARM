#include "RegionalSettings.h"
#include "Persistence.h"
#include "SystemTime.h"
#include "util.h"
#include <time.h>
#include "UserManager.h"
#include "MessageHandler.h"
#include "Audit.h"

static id singleInstance = NULL;

static void convertTime(datetime_t *dt, struct tm *bt)
{
#ifdef __UCLINUX
	localtime_r(dt, bt);
#else
	gmtime_r(dt, bt);
#endif
}

@implementation RegionalSettings

static char myRegionalSettingsMessageString[] 		= "Configuracion";

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
	return [[[Persistence getInstance] getRegionalSettingsDAO] loadById: 1];
}

/**/
- (void) setRegionalSettingsId: (int) aRegionalSettingsId {	myRegionalSettingsId = aRegionalSettingsId; }

/**/
- (void) setDateTime: (datetime_t) aDateTime
{
  char buff[50];
  struct tm brokenTime;
//  doLog(0,"RegionalSettings -> setDateTime()\n");

  TRY	
    // lo audito antes del cambio de hora
    convertTime(&aDateTime, &brokenTime);
    strftime(buff, 50, [self getDateTimeFormatString], &brokenTime);
    [Audit auditEventCurrentUser: TELESUP_SET_DATE_TIME additional: buff station: 0 logRemoteSystem: TRUE];
  
    myDateTime = aDateTime;
	  [SystemTime setLocalTime: aDateTime];
  CATCH
  //  doLog(0,"\n********** ERROR AL CAMBIAR FECHA/HORA ***********\n");
  END_TRY
}

/**/
- (void) setMoneySymbol: (char *) aMoneySymbol { strncpy2(myMoneySymbol, aMoneySymbol, sizeof(myMoneySymbol)-1); }
- (void) setLanguage: (LanguageType) aLanguage { myLanguage = aLanguage; }
- (void) setTimeZone: (int) aTimeZone { myTimeZone = aTimeZone; }

/**/
- (void) setTimeZoneAsString: (char*) aValue 
{
	
	// es negativo
/*
	if (strcmp(&aValue[0], "-") == 0) {
		doLog(0,"es negativo\n");
		memcpy(value, &aValue[1], strlen(aValue)-1);
		myTimeZone = atoi(value) * (0-3600);
	} else */
	myTimeZone = atoi(aValue) * 3600;

//	doLog(0,"timezone = %d\n", myTimeZone);

}

/**/
- (void) setInitialMonth: (int) aInitialMonth { myInitialMonth = aInitialMonth; }
- (void) setInitialWeek: (int) aInitialWeek {	myInitialWeek = aInitialWeek; }
- (void) setInitialDay: (int) aInitialDay { myInitialDay = aInitialDay; }
- (void) setInitialHour: (int) aInitialHour { myInitialHour = aInitialHour; }
- (void) setFinalMonth: (int) aFinalMonth { myFinalMonth = aFinalMonth; }
- (void) setFinalWeek: (int) aFinalWeek { myFinalWeek = aFinalWeek; }
- (void) setFinalDay: (int) aFinalDay { myFinalDay = aFinalDay; }
- (void) setFinalHour: (int) aFinalHour { myFinalHour = aFinalHour; }
- (void) setDSTEnable: (BOOL) aValue { myDSTEnable = aValue; }
- (void) setBlockDateTimeChange: (BOOL) aValue { myBlockDateTimeChange = aValue; }
- (void) setDateFormat: (DateFormat) aDateFormat { myDateFormat = aDateFormat; }

/**/
- (char *) getDateFormatString
{
	static char *formatString[] = {"%d/%m/%y", "%d/%m/%y", "%m/%d/%y"};
	return formatString[myDateFormat];
}

/**/
- (char *) getDateTimeFormatString
{
	static char *formatString[] = {"%d/%m/%y %H:%M:%S", "%d/%m/%y %H:%M:%S", "%m/%d/%y %H:%M:%S"};
	return formatString[myDateFormat];
}


/**/
- (int) getRegionalSettingsId { return myRegionalSettingsId; }
- (datetime_t) getDateTime { return [SystemTime getGMTTime]; }
- (char *) getMoneySymbol { return myMoneySymbol; }
- (LanguageType) getLanguage { return myLanguage; }
- (int) getTimeZone { return myTimeZone; }
- (DateFormat) getDateFormat { return myDateFormat; }

/**/
- (char*) getTimeZoneAsString
{
	char aux[10];

	strcpy(sTimeZone, "");
	sprintf(aux, "%d", myTimeZone/3600);
	strcat(sTimeZone, aux);

	return sTimeZone;
}

/**/
- (int) getInitialMonth { return myInitialMonth; }
- (int) getInitialWeek { return myInitialWeek; }
- (int) getInitialDay { return myInitialDay; }
- (int) getInitialHour { return myInitialHour; }
- (int) getFinalMonth { return myFinalMonth; }
- (int) getFinalWeek { return myFinalWeek; }
- (int) getFinalDay { return myFinalDay; }
- (int) getFinalHour { return myFinalHour; }
- (BOOL) getDSTEnable { return myDSTEnable; }
- (BOOL) getBlockDateTimeChange { return myBlockDateTimeChange; }


/**/
- (void) applyChanges
{
	id regionalSettingsDAO;
	regionalSettingsDAO = [[Persistence getInstance] getRegionalSettingsDAO];		

	[regionalSettingsDAO store: self];
}

/**/
- (void) restore
{
	[self initialize];
}

/**/
- (STR) str
{
  return getResourceStringDef(RESID_SAVE_CONFIGURATION_QUESTION, myRegionalSettingsMessageString);
}

@end

