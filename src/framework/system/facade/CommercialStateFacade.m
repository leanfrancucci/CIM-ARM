#include <strings.h>
#include "CommercialStateFacade.h"
#include "SettingsExcepts.h"
#include "CommercialStateMgr.h"

static id singleInstance = NULL;

@implementation CommercialStateFacade

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
- (void) setParamAsInteger: (char*) aParam value: (int) aValue
{

	if (strcasecmp(aParam, "State") == 0 ) {
		[[[CommercialStateMgr getInstance] getCurrentCommercialState] setCommState: aValue];
		return;
	}

//	[[[CommercialStateMgr getInstance] getCurrentCommercialState] restore];
	THROW(INVALID_PARAM_EX);
}


/**
* GET
*/

/**/
- (int) getParamAsInteger: (char*) aParam
{
	if (strcasecmp(aParam, "State") == 0 )	return [[[CommercialStateMgr getInstance] getCurrentCommercialState] getCommState];
	
//	[[[CommercialStateMgr getInstance] getCurrentCommercialState] restore];
	THROW(INVALID_PARAM_EX);
	return 0;
}

/**/
- (void) applyChanges
{
	TRY 

		[[[CommercialStateMgr getInstance] getCurrentCommercialState] applyChanges];
	
	CATCH
	
//		[[[CommercialStateMgr getInstance] getCurrentCommercialState] restore];
		RETHROW();

	END_TRY
}

@end
