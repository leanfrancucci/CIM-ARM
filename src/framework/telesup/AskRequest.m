#include "AskRequest.h"

//#define printd(args...) doLog(args)
#define printd(args...)

@implementation AskRequest

/**/
- (void) clearRequest
{
	[super clearRequest];
	
	myTelesupParser = NULL;
}	

/**/
- (void) setReqTelesupParser: (TELESUP_PARSER) aTelesupParser { 	myTelesupParser = aTelesupParser; }
- (TELESUP_PARSER) getReqTelesupParser { return myTelesupParser; }

/**/
- (void) executeRequest
{
	REQUEST request;
	
	assert(myRemoteProxy);
	assert(myTelesupParser);
	
	// Debo enviar el mensaje al proxy para averiguar algo
	[myRemoteProxy newResponseMessage];
	[self addQueryParameters];
	[myRemoteProxy sendMessage];

	/* Lee el mensaje */
	[myRemoteProxy readTelesupMessage: myResponseBuffer qty: sizeof(myResponseBuffer) - 1];
     
	/* Los Requests son singletons */             
	request = [myTelesupParser getRequest: myResponseBuffer];
	
       
	[request executeRequest];
	[request clear];
}

/**/
- (void) addQueryParameters
{
	THROW( ABSTRACT_METHOD_EX );
}

@end
