#include "RestartSystemRequest.h"
#include "ctversion.h"
#include "system/util/all.h"
#include "system/os/all.h"
#include "CtSystem.h"

//#define printd(args...) doLog(args)
#define printd(args...)


@implementation RestartSystemRequest

static RESTART_SYSTEM_REQUEST mySingleInstance = nil;
static RESTART_SYSTEM_REQUEST myRestoreSingleInstance = nil;

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
	[self setReqType: RESTART_SYSTEM_REQ];
	myForceReboot = FALSE;
	return self;
}

/**/
- (void) setForceReboot: (BOOL) aValue { myForceReboot = aValue; }

/**/
- (void) executeRequest
{

	[myRemoteProxy sendAckMessage];
	
	TRY
		[[CtSystem getInstance] shutdownSystem];
	CATCH
	END_TRY

	/** @todo: el comando "reboot" deberia pasar a algun otro lado para que no quede tan acoplado */
	system("reboot");
	
}

/**/
- (void) endRequest
{
	[super endRequest];
	
	[myRemoteProxy sendAckMessage];
}

@end
