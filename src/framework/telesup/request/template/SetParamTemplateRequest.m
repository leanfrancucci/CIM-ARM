#include "Set##TEMPLATE##Request.h"
#include "Persistence.h"
#include "##TEMPLATE##SettingsFacade.h"
 
/* macro para debugging */
//#define printd(args...) doLog(args)
#define printd(args...)

@implementation Set##TEMPLATE##Request

static SET_##TEMPLATE##_REQUEST mySingleInstance = nil;
static SET_##TEMPLATE##_REQUEST myRestoreSingleInstance = nil;


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
	[self setReqType: SET_##TEMPLATE##_REQ];	
	return self;
}

/**/
- (void) clearRequest
{

}

/**/
- (DATA_OBJECT) getRequestDAO
{
	return [[Persistence getInstance] getSet##TEMPLATE##RequestDAO];
}

/**
 * Los metodos de acceso al objeto
 */

- (void) set##ATTRIBUTE##: (##ATTRIBUTE_TYPE##) a##ATTRIBUTE## { my##ATTRIBUTE## = a##ATTRIBUTE##; }
- (##ATTRIBUTE_TYPE##)  get##ATTRIBUTE## { return my##ATTRIBUTE##; }



/**/
- (void ) assignStateRequestTo: (id) anObject
{
	/*
	[anObject setXXX: myXXX];
	*/
	[anObject set##ATTRIBUTE##: 		my##ATTRIBUTE##];			
}

/**/
- (void) assignRestoreRequestInfo
{	
	##TEMPLATE##_SETTINGS_FACADE facade = [##TEMPLATE##SettingsFacade getInstance];
	/*
	myXXX  = [[ZZZFacade getInstance] getXXX];
	*/	
	my##ATTRIBUTE## 			= [facade getParamAs##ATTRIBUTE_TYPE##:  "##ATTRIBUTE##"];
}

/**
 * Los metodos de configuracion 
 */
 
/**/
- (void) executeRequest
{
	##TEMPLATE##_SETTINGS_FACADE facade = [##TEMPLATE##SettingsFacade getInstance];

	[facade setParamAs##ATTRIBUTE_TYPE##:  "##ATTRIBUTE##" 			value: my##ATTRIBUTE##];
	
	[facade applyChanges];
}

@end
