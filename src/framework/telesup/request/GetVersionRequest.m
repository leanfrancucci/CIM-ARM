#include "GetVersionRequest.h"
#include "ctversion.h"

//#define printd(args...) doLog(args)
#define printd(args...)


@implementation GetVersionRequest

static GET_VERSION_REQUEST mySingleInstance = nil;
static GET_VERSION_REQUEST myRestoreSingleInstance = nil;

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
	[self setReqType: GET_VERSION_REQ];
	return self;
}

/**/
- (void) clearRequest
{

};


/**/
- (void) sendRequestData
{	
	[myRemoteProxy addParamAsString: "AppVersion" value: APP_VERSION_STR];
	[myRemoteProxy addParamAsString: "AppRelease" value: APP_RELEASE_DATE];
}

@end
