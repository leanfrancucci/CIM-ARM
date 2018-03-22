#include <strings.h>
#include "RegionalSettingsFacade.h"
#include "SettingsExcepts.h"

static id singleInstance = NULL;

@implementation RegionalSettingsFacade

/**/
+ new
{
	if (!singleInstance) singleInstance = [[super new] initialize];
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
	[super initialize];
	return self;
}

/**
* SET
*/

/**/
- (void) setParamAsDateTime: (char*) aParam value: (datetime_t) aValue
{
	if (strcasecmp(aParam, "DateTime") == 0 ) {
		[[RegionalSettings getInstance] setDateTime: aValue];
		return;
	}
	
	[[RegionalSettings getInstance] restore];		
	THROW_MSG(INVALID_PARAM_EX, aParam);
}

/**/
- (void) setParamAsString: (char*) aParam value: (char*) aValue
{
	if (strcasecmp(aParam, "MoneySymbol") == 0 ) {
		[[RegionalSettings getInstance] setMoneySymbol: aValue];
		return;
	}
	
	if (strcasecmp(aParam, "TimeZone") == 0 ) {
		[[RegionalSettings getInstance] setTimeZoneAsString: aValue];
		return;
	}

	[[RegionalSettings getInstance] restore];		
	THROW_MSG(INVALID_PARAM_EX, aParam);
}

/**/
- (void) setParamAsInteger: (char*) aParam value: (int) aValue
{
	if (strcasecmp(aParam, "Language") == 0 ) {
		[[RegionalSettings getInstance] setLanguage: aValue];
		return;
	}

	if (strcasecmp(aParam, "InitialMonth") == 0 ) {
		[[RegionalSettings getInstance] setInitialMonth: aValue];
		return;
	}

	if (strcasecmp(aParam, "InitialWeek") == 0 ) {
		[[RegionalSettings getInstance] setInitialWeek: aValue];
		return;
	}

	if (strcasecmp(aParam, "InitialDay") == 0 ) {
		[[RegionalSettings getInstance] setInitialDay: aValue];
		return;
	}

	if (strcasecmp(aParam, "InitialHour") == 0 ) {
		[[RegionalSettings getInstance] setInitialHour: aValue];
		return;
	}

	if (strcasecmp(aParam, "FinalMonth") == 0 ) {
		[[RegionalSettings getInstance] setFinalMonth: aValue];
		return;
	}

	if (strcasecmp(aParam, "FinalWeek") == 0 ) {
		[[RegionalSettings getInstance] setFinalWeek: aValue];
		return;
	}

	if (strcasecmp(aParam, "FinalDay") == 0 ) {
		[[RegionalSettings getInstance] setFinalDay: aValue];
		return;
	}

	if (strcasecmp(aParam, "FinalHour") == 0 ) {
		[[RegionalSettings getInstance] setFinalHour: aValue];
		return;
	}

	if (strcasecmp(aParam, "DateFormat") == 0 ) {
		[[RegionalSettings getInstance] setDateFormat: aValue];
		return;
	}


	[[RegionalSettings getInstance] restore];		
	THROW_MSG(INVALID_PARAM_EX, aParam);
}


/**/
- (void) setParamAsBoolean: (char*) aParam value: (BOOL) aValue
{
	if (strcasecmp(aParam, "DSTEnable") == 0 ) {
		[[RegionalSettings getInstance] setDSTEnable: aValue];
		return;
	}

	if (strcasecmp(aParam, "BlockDateTimeChange") == 0 ) {
		[[RegionalSettings getInstance] setBlockDateTimeChange: aValue];
		return;
	}

	[[RegionalSettings getInstance] restore];		
	THROW_MSG(INVALID_PARAM_EX, aParam);
}

/**
* GET
*/

/**/
- (datetime_t) getParamAsDateTime: (char*) aParam
{
	if (strcasecmp(aParam, "DateTime") == 0 ) return [[RegionalSettings getInstance] getDateTime];

	[[RegionalSettings getInstance] restore];		
	THROW_MSG(INVALID_PARAM_EX, aParam);
	return 0;
}

/**/
- (char*) getParamAsString: (char*) aParam
{

	if (strcasecmp(aParam, "MoneySymbol") == 0 ) return [[RegionalSettings getInstance] getMoneySymbol];
	if (strcasecmp(aParam, "TimeZone") == 0 ) return [[RegionalSettings getInstance] getTimeZoneAsString];

	[[RegionalSettings getInstance] restore];		
	THROW_MSG(INVALID_PARAM_EX, aParam);
	return NULL;
}

/**/
- (int) getParamAsInteger: (char*) aParam
{
	if (strcasecmp(aParam, "Language") == 0 )	return [[RegionalSettings getInstance] getLanguage];
	if (strcasecmp(aParam, "InitialMonth") == 0 ) return [[RegionalSettings getInstance] getInitialMonth];
	if (strcasecmp(aParam, "InitialWeek") == 0 ) return [[RegionalSettings getInstance] getInitialWeek];
	if (strcasecmp(aParam, "InitialDay") == 0 ) return [[RegionalSettings getInstance] getInitialDay];
	if (strcasecmp(aParam, "InitialHour") == 0 ) return [[RegionalSettings getInstance] getInitialHour];
	if (strcasecmp(aParam, "FinalMonth") == 0 ) return [[RegionalSettings getInstance] getFinalMonth];
	if (strcasecmp(aParam, "FinalWeek") == 0 ) return [[RegionalSettings getInstance] getFinalWeek];
	if (strcasecmp(aParam, "FinalDay") == 0 ) return [[RegionalSettings getInstance] getFinalDay];
	if (strcasecmp(aParam, "FinalHour") == 0 ) return [[RegionalSettings getInstance] getFinalHour];
	if (strcasecmp(aParam, "DateFormat") == 0 ) return [[RegionalSettings getInstance] getDateFormat];

	[[RegionalSettings getInstance] restore];
	THROW_MSG(INVALID_PARAM_EX, aParam);
	return 0;
}

/**/
- (BOOL) getParamAsBoolean: (char*) aParam
{
	if (strcasecmp(aParam, "DSTEnable") == 0 ) return [[RegionalSettings getInstance] getDSTEnable];
	if (strcasecmp(aParam, "BlockDateTimeChange") == 0 ) return [[RegionalSettings getInstance] getBlockDateTimeChange];

	[[RegionalSettings getInstance] restore];		
	THROW(INVALID_PARAM_EX);
	return 0;
}

/**/
- (void) applyChanges
{
	TRY 
	
		[[RegionalSettings getInstance] applyChanges];
	
	CATCH
		
		[[RegionalSettings getInstance] restore];
		RETHROW();

	END_TRY
}

@end
