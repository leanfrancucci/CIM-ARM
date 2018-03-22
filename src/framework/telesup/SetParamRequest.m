#include "SetParamRequest.h"
#include "log.h"

/* macro para debugging */
//#define printd(args...) doLog(0,args)
//#define printd(args...)


@implementation SetParamRequest

/**/
- (void) executeRequest
{
	[self setParamSettings];
}

/**/
- (void) endRequest
{
	assert(myRemoteProxy);

	[super endRequest];
	[myRemoteProxy sendAckWithTimestampMessage];
}

/**/
- (void) setParamSettings
{
//	doLog(0,"El metodo setParamSettings() de SetParamRequest debe ser implementado!!!");
	THROW( ABSTRACT_METHOD_EX );
}

@end
