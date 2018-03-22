#include "Request.h"
#include "log.h"

//#define printd(args...) doLog(0,args)
#define printd(args...) 

/**/
@implementation Request

/**/
+ new
{
	return [[super new] initialize];
}

/**/
+ getInstance
{
	REQUEST request;
		
	/**/
	if ( ![self getSingleVarInstance] ) [self setSingleVarInstance: [[self class] new]];
	
	/**/
	request = [self getSingleVarInstance];
	assert(request);
	
	/**/
	[request clear];
	return request;
};

/**/
+ getSingleVarInstance
{
	 THROW( ABSTRACT_METHOD_EX );
	 return 0;
};
+ (void) setSingleVarInstance: (id) aSingleVarInstance
{
	 THROW( ABSTRACT_METHOD_EX ); 
};

/**/
+ getRestoreInstance
{
	if ( ![self getRestoreVarInstance] ) [self setRestoreVarInstance: [[self class] new]];
	return [self getRestoreVarInstance];
};

/**/
+ getRestoreVarInstance 
{
	 THROW( ABSTRACT_METHOD_EX );
	 return 0;
};
+ (void) setRestoreVarInstance: (id) aRestoreVarInstance
{
	 THROW( ABSTRACT_METHOD_EX ); 
};

/**/
- initialize
{	
	myReqType = INVALID_REQ;
	myFreeAfterExecute = FALSE;
	[self clear];
	return self;
}

/**/
- (void) clear
{
	myTelesupErrorMgr = NULL;	
	myRemoteProxy = NULL;
	myInfoFormatter = NULL;
	
	myReqInitialVigencyDate = time(NULL);
	myReqFinalVigencyDate = 0;
	
	myReqTelesupId = 0;
	myReqId = 0;

	myReqOperation = NO_REQ_OP;

	myReqTelesupRol = 0;
	
	myReqExecuted = FALSE;
	myReqFailed = FALSE;
	myReqErrorCode = 0;
	
	myJobId = 0;
	myMessageId = 0;
	myJobable = FALSE;

	[self clearRequest];
};

/**/
- (void) clearRequest
{
}

/**/
- (void) printRequest
{
	char buf1[32];
	char buf2[32];

/*	doLog(0,"Request:%ld - Type=%d -  Rol=%d - InitialDate=%s - FinalDate=%s\n",
					myReqId,  myReqType, myReqTelesupRol,
					ctime_r(&myReqInitialVigencyDate, buf1), ctime_r(&myReqFinalVigencyDate, buf2));
*/
};

/**/
- (void) setTelesupErrorManager: (TELESUP_ERROR_MANAGER) aTelesupErrorMgr { myTelesupErrorMgr = aTelesupErrorMgr; }	
- (TELESUP_ERROR_MANAGER) getTelesupErrorManager { return myTelesupErrorMgr; }

/**/
- (void) setReqTelesupId: (int) aReqTelesupId { myReqTelesupId = aReqTelesupId; };
- (int) getReqTelesupId { return myReqTelesupId; };

/**/
- (void) setReqId: (unsigned long) anId { myReqId = anId; };
- (unsigned long) getReqId { return myReqId; };

/**/
- (void) setReqType: (int) aRequestType{ myReqType = aRequestType; };
- (int) getReqType{ return myReqType; };

/**/
- (void) setReqOperation: (ENTITY_REQUEST_OPS) aReqOperation { myReqOperation = aReqOperation; } ;
- (ENTITY_REQUEST_OPS) getReqOperation { return myReqOperation; };

/**/
- (void) setReqTelesupRol: (int) aTelesupRol { myReqTelesupRol = aTelesupRol; };
- (int) getReqTelesupRol{ return 	myReqTelesupRol; };

/**/
- (void) setReqExecuted: (BOOL) aValue { myReqExecuted = aValue; }
- (BOOL) isReqExecuted { return myReqExecuted; }

/**/
- (void) setReqFailed: (BOOL) aValue { myReqFailed = aValue; }
- (BOOL) isReqFailed { return myReqFailed; }
	
/**/
- (void) setReqErrorCode: (int) aValue { myReqErrorCode = aValue; }
- (int) getReqErrorCode { return myReqErrorCode; }

/**/
- (void) setUserId: (int) aUserId { myReqUserId = aUserId; };
- (int) getUserId{ return 	myReqUserId;};

/**/
- (void) setReqRemoteProxy: (REMOTE_PROXY) aRemoteProxy { 	myRemoteProxy = aRemoteProxy; }
- (REMOTE_PROXY) getReqRemoteProxy { return myRemoteProxy; }

/**/
- (void) setReqInfoFormatter: (INFO_FORMATTER) anInfoFormatter {	 myInfoFormatter = anInfoFormatter; }
- (INFO_FORMATTER) getReqInfoFormatter { return myInfoFormatter; }

/**/
- (void) setReqInitialVigencyDate: (DATETIME) anInitialVigencyDate { myReqInitialVigencyDate = anInitialVigencyDate; };
- (DATETIME) getReqInitialVigencyDate { return myReqInitialVigencyDate; };

/**/
- (void) setReqFinalVigencyDate: (DATETIME) aFinalVigencyDate { myReqFinalVigencyDate = aFinalVigencyDate; };
- (DATETIME) getReqFinalVigencyDate { return myReqFinalVigencyDate; };


/**/
- (void) setReqJobId: (unsigned long) aJobId { myJobId = aJobId; }
- (unsigned long) getReqJobId { return myJobId; }

/**/
- (void) setReqMessageId: (unsigned long) aMessageId { myMessageId = aMessageId; }
- (unsigned long) getReqMessageId { return myMessageId; }

/**/
- (void) setJobable: (BOOL) aValue { myJobable = aValue; }
- (BOOL) isJobable { return myJobable; }

/**/
- (void) saveRequest
{
	[[self getRequestDAO] store: self];
}

/**/
- (DATA_OBJECT) getRequestDAO
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}


/**/
- (void) assignStateRequestTo: (id) anObject
{
	THROW( ABSTRACT_METHOD_EX );
}


/**/
- (void) assignRequestTo: (id) anObject
{
	[anObject setReqId: myReqId];
	[anObject setReqType: myReqType];
	[anObject setReqOperation:  myReqOperation];

	[anObject setReqRemoteProxy: myRemoteProxy];	
	[anObject setReqInfoFormatter: myInfoFormatter];
		
	[anObject setReqTelesupId: myReqTelesupId];
	[anObject setReqTelesupRol: myReqTelesupRol];

	[anObject setReqInitialVigencyDate: myReqInitialVigencyDate];
	[anObject setReqFinalVigencyDate: myReqFinalVigencyDate];

	[anObject setReqExecuted: myReqExecuted];
	[anObject setReqFailed: myReqFailed];
	[anObject setReqErrorCode: myReqErrorCode];

	[self assignStateRequestTo: anObject];
}

/**/
- (REQUEST) getRestoreRequest
{
	REQUEST req;

	printd("Request.getRestoreRequest()\n");

	req = [self getRestoreInstance];
	[self assignRequestTo: req];
	[req assignRestoreRequestInfo];
	
	/* La fecha inicial del request se pasa como fecha final del request original */
	[req setReqInitialVigencyDate: myReqFinalVigencyDate];
	[req setReqFinalVigencyDate: 0];
	
	return req;
}
;

/**/
- (void) assignRestoreInfo
{
	if (myReqOperation == ACTIVATE_REQ_OP || myReqOperation == ADD_REQ_OP) return;
		
	[self assignRestoreRequestInfo];
}
;

/**/
- (void) assignRestoreRequestInfo
{	
}


/**/
- (void) processRequest
{	
	[self beginRequest];
	[self executeRequest];
	[self endRequest];
}



/**/
- (void) beginRequest
{
}


/**/
- (void) executeRequest
{
	THROW( ABSTRACT_METHOD_EX );
}



/**/
- (void) endRequest
{
}

/**/
- (void) requestExecuted
{
	[self setReqExecuted: TRUE];
	[self setReqFailed: FALSE];
	[self setReqErrorCode: 0];
}
 
/**/
- (void) requestFailedWithErrorCode: (int) anErrorCode
{
	[self setReqExecuted: TRUE];
	[self setReqFailed: TRUE];
	[self setReqErrorCode: anErrorCode];
}

/**/
- (void) setFreeAfterExecute: (BOOL) aValue { myFreeAfterExecute = aValue; }
- (BOOL) getFreeAfterExecute { return myFreeAfterExecute; }

@end
