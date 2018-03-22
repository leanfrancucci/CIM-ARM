#include "SetEntityRequest.h"
#include "log.h"

/* macro para debugging */
//#define printd(args...) doLog(0,args)
#define printd(args...)


@implementation SetEntityRequest


/**
 * Define el metodo que decide la operacion que debe realizar el REquest.
 */
- (void) executeRequest
{
	switch (myReqOperation) {

		case ACTIVATE_REQ_OP:
			[self activateEntity];
			[self setEntitySettings];
			break;

		case DEACTIVATE_REQ_OP:
			[self deactivateEntity];
			break;

		case ADD_REQ_OP:
			[self addEntity];
			[self setEntitySettings];
			break;

		case REMOVE_REQ_OP:
			[self removeEntity];
			break;

		case SETTINGS_REQ_OP:
			[self setEntitySettings];
			break;

		default:
			THROW( TSUP_INVALID_OPERATION_EX );
			break;
	}

}


/**/
- (void) endRequest
{
	assert(myRemoteProxy);

	[super endRequest];

	switch (myReqOperation) {

		case ADD_REQ_OP:
			[self sendAddEntityResponse];
			break;

		case REMOVE_REQ_OP:
			[self sendRemoveEntityResponse];
			break;

		case ACTIVATE_REQ_OP:
			[self sendActivateEntityResponse];
			break;

		case DEACTIVATE_REQ_OP:
			[self sendDeactivateEntityResponse];
			break;

		default:
			[myRemoteProxy sendAckWithTimestampMessage];
			break;
	}
}


/**/

-(void) sendAddEntityResponse
{
	[myRemoteProxy newResponseMessage];
	[self sendKeyValueResponse];
	[myRemoteProxy appendTimestamp];
	[myRemoteProxy sendMessage];
}

/**/
- (void) sendRemoveEntityResponse
{
	[myRemoteProxy sendAckWithTimestampMessage];
}

/**/
- (void) sendActivateEntityResponse
{
	[myRemoteProxy newResponseMessage];
	[self sendKeyValueResponse];
	[myRemoteProxy appendTimestamp];	
	[myRemoteProxy sendMessage];
}

/**/
- (void) sendDeactivateEntityResponse
{
	[myRemoteProxy sendAckWithTimestampMessage];
}

/**/
- (void) sendKeyValueResponse
{
}


/**/
- (void) addEntity
{
	//doLog(0,"El metodo addEntity() de SetEntityRequest debe ser implementado!!!");
	THROW( ABSTRACT_METHOD_EX );
};

/**/
- (void) removeEntity
{
	//doLog(0,"El metodo removeEntity() de SetEntityRequest debe ser implementado!!!");
	THROW( ABSTRACT_METHOD_EX );
};

/**/
- (void) activateEntity
{
	//mdoLog(0,"El metodo activateEntity() de SetEntityRequest debe ser implementado!!!");
	THROW( ABSTRACT_METHOD_EX );
};

/**/
- (void) deactivateEntity
{
	//doLog(0,"El metodo deactivateEntity() de SetEntityRequest debe ser implementado!!!");
	THROW( ABSTRACT_METHOD_EX );
};

/**/
- (void) setEntitySettings
{
	//doLog(0,"El metodo setEntitySettings() de SetEntityRequest debe ser implementado!!!");
	THROW( ABSTRACT_METHOD_EX );
};

@end
