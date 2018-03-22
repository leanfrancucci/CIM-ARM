#include "system/util/all.h"
#include "ROPPersistence.h"

#include "TelesupErrorManager.h"
#include "TelesupJobManager.h"
#include "TelesupJobDAO.h"
#include "Request.h"

//#define printd(args...) 	doLog(args)
#define printd(args...) 	

/**/
@implementation TelesupJobManager

static TELESUP_JOB_MANAGER myTelesupJobManager = nil ;

/**/
+ new
{	
	if ( !myTelesupJobManager ) 
		return myTelesupJobManager = [[super new] initialize];	 
	
	return myTelesupJobManager;
}

/**/
+ getInstance
{
	return [TelesupJobManager new];
}; 

/**/
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
}	

/**/
- (void) executePendingJobs
{
	TELESUP_JOB job;
	
	while (1) {
			
		/* Obtiene el siguiente job pendiente */
		job = [self getNextPendingJobUntilNow];
		
		if (job == NULL)
			return;
	
		[job executeTelesupJob];
	}	
}

/**/
- (TELESUP_JOB) getNextPendingJobUntilNow
{
	return [self getNextPendingJobUntil:  getDateTime()];
}
	
/**/
- (TELESUP_JOB) getNextPendingJobUntil: (datetime_t) aDate
{
	TELESUP_JOB job;
	TELESUP_JOB_DAO jdao;
	
	/* Obtiene el DAO de persistencia de Jobs */
	jdao = [[Persistence getInstance] getTelesupJobDAO];
	assert(jdao);
	
	/* obtiene el job */
	job = [jdao getNextPendingJobUntil: aDate];				
	
	return job;
}

	
@end
