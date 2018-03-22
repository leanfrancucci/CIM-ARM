#include "GetRequest.h"
#include "log.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

@implementation GetRequest

/**/
- (void) beginRequest
{
	assert(myRemoteProxy);
	
	[super beginRequest];
	[myRemoteProxy newResponseMessage];
}

/**/
- (void) executeRequest
{
	[self sendRequestData];
}

/**/
- (void) endRequest
{
	assert(myRemoteProxy);

	[super endRequest];
	[myRemoteProxy sendMessage];
}

/**/
- (void) sendRequestData
{
//	doLog(0,"El metodo sendRequestData() de GetRequest debe ser implementado!!!");
	THROW( ABSTRACT_METHOD_EX );
}

/**/
- (void) beginEntity
{
	[myRemoteProxy addLine: BEGIN_ENTITY];
}

/**/
- (void) endEntity
{
	[myRemoteProxy addLine: END_ENTITY];
}

@end
