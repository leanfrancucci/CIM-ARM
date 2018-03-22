#include "CommitJobRequest.h"
 
//#define printd(args...) doLog(args)
#define printd(args...)


/**/
@implementation CommitJobRequest

static COMMIT_JOB_REQUEST mySingleInstance = nil;
static COMMIT_JOB_REQUEST myRestoreSingleInstance = nil;

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
	[self setReqType: COMMIT_JOB_REQ];
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

