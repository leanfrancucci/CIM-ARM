#include <string.h>
#include "util.h"


#include "RequestDAO.h"
#include "Request.h"
#include "TelesupJobDAO.h"
//#include "TelesupFactory.h"


#define TELESUP_JOBS_TABLE_NAME			"telesup_jobs"

/**
 * Gestiona la lista de Request directamente a traves de un Recordset.
 * No los puede gestionar con una coleccion porque los Request son singleton
 * y dentro de un job es posible que haya requests del mismo tipo.
 *
 */
@implementation TelesupJobDAO

/**/ 
static id  singleInstance = NULL;


/**/
+ new
{
	if (!singleInstance) singleInstance = [super new];
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

	myCurrentJob = NULL;
	
	myRecordSet  = [[DBConnection getInstance] createRecordSet: TELESUP_JOBS_TABLE_NAME];	
	[myRecordSet open];
	
	myNextPendingJobRecordSet  = [[DBConnection getInstance] createRecordSet: TELESUP_JOBS_TABLE_NAME];		
	myNextPendingJobDataSearcher = [DataSearcher new];
	
	myRequestRecordSet = [RequestDAO createRequestRecordSet];		
	myRequestDataSearcher = [DataSearcher new];
	
	return self;
}

/**/
- free
{
	[myRecordSet close];
	[myRecordSet free];

	[myNextPendingJobRecordSet free];	
	[myNextPendingJobDataSearcher free];         
	
	[myRequestRecordSet free];	
	[myRequestDataSearcher free];
			
	return self;
}	


/**/
- (void) store: (id) anObject
{
	assert(myRecordSet);
	assert(anObject);
	
	/* Agrega el registro en la tabla si es un nuevo registro */
	if ([anObject getJobId] > 0)
		[myRecordSet findById: "JOB_ID" value: [anObject getJobId]];
	else
		[myRecordSet add];	
		
	[myRecordSet setCharValue: 		"TELESUP_ID" 	value: [anObject getTelesupId]];
	[myRecordSet setCharValue: 		"ROL" 			value: [anObject getTelesupRol]];
	[myRecordSet setDateTimeValue: 	"INIT_DATE" 	value: [anObject getInitialVigencyDate]];
	[myRecordSet setBoolValue: 		"EXECUTED" 		value: [anObject isExecuted]];
	[myRecordSet setBoolValue: 		"COMMITED" 		value: [anObject isCommited]];
	[myRecordSet setBoolValue: 		"NULLED" 		value: [anObject isNulled]];

	/* Graba el registro */
	[myRecordSet save];
	[anObject setJobId: [myRecordSet getLongValue:  "JOB_ID"]];	
}

/**/
- (id) loadById: (unsigned long) anObjectId
{
	TELESUP_JOB job;
	
	/* Busca el registro correspondiente en la tabla de jobs */
	if ( ![myRecordSet findById: "JOB_ID" value: anObjectId] )
		THROW( NO_CURRENT_RECORD_EX );

	job = [TelesupJob new];
	
	/* Datos del job */
	[job setJobId: anObjectId];	
	[job setTelesupId: 			[myRecordSet getCharValue: "TELESUP_ID"]];
	[job setTelesupRol: 		[myRecordSet getCharValue: "ROL"]];
	[job setInitialVigencyDate: [myRecordSet getDateTimeValue: "INIT_DATE"]];	
	[job setCommited: 			[myRecordSet getBoolValue: "COMMITED"]];
	[job setExecuted: 			[myRecordSet getBoolValue: "EXECUTED"]];
	[job setNulled: 			[myRecordSet getBoolValue: "NULLED"]];
	
	/* Asigna el manejador de errores especifico del esquema de telesupervision */
	//[job setTelesupErrorManager:  [[TelesupFactory getInstance] getTelesupErrorManager: [job getTelesupId]]];
	
	return job;
};



/**/
- (void) removeJob: (TELESUP_JOB) aJob
{
	assert(aJob);
	
	/* Busca el registro correspondiente en la tabla de jobs */
	if ( ![myRecordSet findById: "JOB_ID" value: [aJob getJobId]] ) 
		return;
		
	[myRecordSet delete];	
}

/**/
- (void) beginJobExecution: (TELESUP_JOB) aJob
{
	assert(aJob);	
	assert(myRequestRecordSet);
	assert(myRequestDataSearcher);
		
	myCurrentJob = aJob;
	
	if ([myCurrentJob isExecuted])
		THROW( TS_JOB_EXECUTED );
		
	[myRequestRecordSet open];
	[myRequestRecordSet moveBeforeFirst];
	
	/**/
	[myRequestDataSearcher clear];
	
	[myRequestDataSearcher setRecordSet: myRequestRecordSet];
	/* Falta alguna manera de pedirle el DataSearcher al RequestDAO */
	[myRequestDataSearcher addLongFilter: "JOB_ID" operator: "=" value: [aJob getJobId]];
}

/**/
- (void) jobExecuted
{
	assert(myCurrentJob);
	assert(myRequestRecordSet);
	
	/**/
	[myCurrentJob setExecuted: TRUE];
	[self store: myCurrentJob];
	
	/**/
	[myRequestRecordSet close];
}

/**/
- (REQUEST) getNextPendingRequest
{
	REQUEST request;
	
	assert(myCurrentJob);
	assert(myRequestDataSearcher);

	/* Gestiona la lista de Request directamente a traves de un Recordset.
	 * No los puede gestionar con una coleccion porque los Request son singleton
	 * y dentro de un job es posible que haya requests del mismo tipo.
 	 */ 
		
	request = NULL;
	if ([myRequestDataSearcher findNext])
		request = [RequestDAO getRequestFromRecordSet: myRequestRecordSet];
		
	return request;
}
 
/**/
- (TELESUP_JOB) getNextPendingJobUntil: (datetime_t) aDate
{
	TELESUP_JOB aJob;
	
	assert(myNextPendingJobRecordSet);
	assert(myNextPendingJobDataSearcher);
	
	[myNextPendingJobRecordSet open];
	
	/* Falta alguna manera de pedirle el DataSearcher al RequestDAO */
	[myNextPendingJobDataSearcher clear];
	[myNextPendingJobDataSearcher setRecordSet: myNextPendingJobRecordSet];
	[myNextPendingJobDataSearcher addDateTimeFilter: 	"INIT_DATE" operator: "<=" 	value: aDate];	
	[myNextPendingJobDataSearcher addCharFilter: 		"EXECUTED" 	operator: "=" 	value: FALSE];	
	[myNextPendingJobDataSearcher addCharFilter: 		"NULLED" 	operator: "=" 	value: FALSE];		
	
	aJob = NULL;
	if ([myNextPendingJobDataSearcher findNext]) 	
		aJob = [self loadById: [myNextPendingJobRecordSet getLongValue: "JOB_ID"]];			
	
	[myNextPendingJobRecordSet close];
	
	return aJob;
}
	
@end
