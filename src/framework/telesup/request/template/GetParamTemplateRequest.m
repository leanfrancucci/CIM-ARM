#include "Get##TEMPLATE##Request.h"
#include "Persistence.h"
#include "##TEMPLATE##SettingsFacade.h"
 
/* macro para debugging */
//#define printd(args...) doLog(args)
#define printd(args...)

@implementation Get##TEMPLATE##Request

static GET_##TEMPLATE##_REQUEST mySingleInstance = nil;
static GET_##TEMPLATE##_REQUEST myRestoreSingleInstance = nil;


/**/
+ getSingleVarInstance
{
	 return mySingleInstance; 
}
+ (void) setSingleVarInstance: (id) aSingleVarInstance
{
	 mySingleInstance =  aSingleVarInstance;
}

/**/
+ getRestoreVarInstance 
{
	 return myRestoreSingleInstance; 
}
+ (void) setRestoreVarInstance: (id) aRestoreVarInstance
{
	 myRestoreSingleInstance = aRestoreVarInstance; 
}

/**/
- initialize
{
	[super initialize];
	[self setReqType: GET_##TEMPLATE##_REQ];	
	return self;
}

/**/
- (void) clearRequest
{

};

/**/
- (void) set##ATRIBUTE##Query: (BOOL) aQuery { my##ATRIBUTE##Query = aQuery; }


/**
 * Los metodos de configuracion 
 */

/**/
- (void) executeRequest 
{	
	##TEMPLATE##_SETTINGS_FACADE facade = [##TEMPLATE##SettingsFacade getInstance];
	
	[myRemoteProxy newResponseMessage];

	if (my##ATRIBUTE##Query)			[myRemoteProxy addParamAs##ATRIBUTE_TYPE##: "##ATRIBUTE##" value: [facade getParamAs##ATRIBUTE_TYPE##: "##ATRIBUTE##"]];

	[myRemoteProxy sendMessage]; 	
}


@end
