#include "StartJobRequest.h"
 
#define printd(args...) doLog(0,args)
//#define printd(args...)


@implementation StartJobRequest

static START_JOB_REQUEST mySingleInstance = nil;
static START_JOB_REQUEST myRestoreSingleInstance = nil;

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
	[self setReqType: START_JOB_REQ];
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

