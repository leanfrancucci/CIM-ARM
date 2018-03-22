#include "system/util/all.h"

#include "TelesupJob.h"
#include "Request.h"

//#define printd(args...) 	doLog(args)
#define printd(args...) 	


@implementation TelesupJob

/**/
+ new
{
	return [[super new] initialize];
}	

- free
{
	return self;
}
	
/**/
- initialize
{	
	[super initialize];
	
	[self clear];
	return self;
}	

/**/
- (void) clear
{
	myTelesupId = 0;
	myJobId = 0;
	myTelesupRol = 0;
	myInitialVigencyDate = time(NULL);
	myIsCommited = FALSE;
	myIsExecuted = FALSE;
	myIsNulled = TRUE;
}	

/**/ 
- (void) setTelesupId: (int) aTelesupId { myTelesupId = aTelesupId; }
- (int) getTelesupId { return myTelesupId; }

/**/
- (void) setJobId: (unsigned long) aJobId { myJobId = aJobId; }
- (unsigned long) getJobId { return myJobId; }

- (void) setTelesupRol: (int) aTelesupRol { myTelesupRol = aTelesupRol; }
- (int) getTelesupRol { return myTelesupRol; }

/**/
- (void) setCommited: (BOOL) aValue { myIsCommited = aValue; }
- (BOOL) isCommited { return myIsCommited; }

/**/
- (void) setExecuted: (BOOL) aValue { myIsExecuted = aValue; }
- (BOOL) isExecuted { return myIsExecuted; }

/**/
- (void) setNulled: (BOOL) aValue { myIsNulled = aValue; }
- (BOOL) isNulled { return myIsNulled; }
	
/**/
- (void) setInitialVigencyDate: (DATETIME) anInitialVigencyDate { myInitialVigencyDate = anInitialVigencyDate; }	
- (DATETIME) getInitialVigencyDate { return myInitialVigencyDate; }

/**/
- (void) startTelesupJob
{
	[self startTelesupJobAt: time(NULL)];
}

/**/
- (void) startTelesupJobAt: (DATETIME) anInitialVigencyDate
{
}	
	
/**/
- (void) commitTelesupJob
{
}	
	
/**/
- (void) rollbackTelesupJob
{
}	

/**/
- (BOOL) hasToExecute
{
}

				
/**/
- (void) executeTelesupJob
{

}
	
/**/
- (void) addRequest: (REQUEST) aRequest
{

}


@end
