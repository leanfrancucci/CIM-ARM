#include "RollbackJobRequest.h"
 
//#define printd(args...) doLog(args)
#define printd(args...)


@implementation RollbackJobRequest

static ROLLBACK_JOB_REQUEST mySingleInstance = nil;
static ROLLBACK_JOB_REQUEST myRestoreSingleInstance = nil;

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
	[self setReqType: ROLLBACK_JOB_REQ];
	return self;	
}

/**/
- (void) clearRequest
{

};

/**/
- (void) executeRequest 
{	
}

@end

