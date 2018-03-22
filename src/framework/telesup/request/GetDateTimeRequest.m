#include "system/util/all.h"
#include "GetDateTimeRequest.h"
#include "Persistence.h"
#include "RegionalSettingsFacade.h"


//#define printd(args...) doLog(args)

#define printd(args...)

/**/
@implementation GetDateTimeRequest

static GET_DATETIME_REQUEST mySingleInstance = nil;
static GET_DATETIME_REQUEST myRestoreSingleInstance = nil;

/**/
+ getSingleVarInstance
{
	 return mySingleInstance; 
};
+ (void) setSingleVarInstance: (id) aSingleVarInstance
{
	 mySingleInstance =  aSingleVarInstance;
};

/**/
+ getRestoreVarInstance 
{
 	return myRestoreSingleInstance; 
};

+ (void) setRestoreVarInstance: (id) aRestoreVarInstance
{
	 myRestoreSingleInstance = aRestoreVarInstance; 
};

/**/
- initialize
{
	[super initialize];
	[self setReqType: GET_DATETIME_REQ];	
	return self;
}


/**/
- (void) clearRequest
{

}

/**
 * Los metodos de configuracion 
 */

/**/
- (void) sendRequestData
{	
//	REGIONAL_SETTINGS_FACADE facade = [RegionalSettingsFacade getInstance];	

	//[myRemoteProxy addParamAsDateTime: "DateTime" value: [facade getParamAsDateTime:  "DateTime"]];
}

@end

