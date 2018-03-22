#include "Get##TEMPLATE##Request.h"
#include "Persistence.h"
#include "##TEMPLATE##Facade.h"
 
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

}

/* La referencia al entidad */
- (void) set##TEMPLATE##Ref: (int) a##TEMPLATE##Ref { my##TEMPLATE##Ref = a##TEMPLATE##Ref; }

/**
 * Los metodos que especifican los parametros consultados
 */
- (void) set##ATTRIBUTE##Query: (BOOL) aQuery { my##ATTRIBUTE##Query = aQuery; }

/**
 * Los metodos de configuracion 
 */

/**/
- (void) executeRequest 
{	
	##TEMPLATE##_FACADE facade = [##TEMPLATE##Facade getInstance];
	
	[myRemoteProxy newResponseMessage];
	
	if (my##ATTRIBUTE##Query)	[myRemoteProxy addParamAs##ATTRIBUTE_TYPE##: "##ATTRIBUTE##" value: [facade getParamAs##ATTRIBUTE_TYPE##: "##ATTRIBUTE##" ##TEMPLATE##Ref: my##TEMPLATE##Ref]];	

	[myRemoteProxy sendMessage]; 	
}


@end
