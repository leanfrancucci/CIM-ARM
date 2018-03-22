#include "Set##TEMPLATE##Request.h"
#include "Persistence.h"
#include "##TEMPLATE##Facade.h"
 
/* macro para debugging */
//efine printd(args...) doLog(args)
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

/**/
- (void) set##ATTRIBUTE##: (##ATTRIBUTE_TYPE##) a##ATTRIBUTE## { my##ATTRIBUTE## = a##ATTRIBUTE##; };
- (int)  get##ATTRIBUTE## { return my##ATTRIBUTE##; };

/**/
- (void ) assignStateRequestTo: (id) anObject
{
	/*
	[anObject setXXX: myXXX];
	*/
	[anObject set##TEMPLATE##Ref: 			my##TEMPLATE##Ref];	

	[anObject set##ATTRIBUTE##: my##ATTRIBUTE##];		
};

/**/
- (void) assignRestoreRequestInfo
{
	##TEMPLATE##_FACADE facade = [##TEMPLATE##Facade getInstance];
	/*
		myXXX = [facade getParamAsXXX: "XXX" 	XXXId: myXXXId];
	*/
	my##ATTRIBUTE## 		= [facade getParamAs##ATTRIBUTE_TYPE##: "##ATTRIBUTE##" 	refId: myRefId];
}


/**
 * Los metodos de gestion de la entidad 
 */
 
/**/
- (void) activateEntity
{
	[[##TEMPLATE##Facade getInstance] activate##TEMPLATE##: my##ATRIBUTE_KEY##];
}
- (void) addEntity
{
	my##ATRIBUTE_KEY## = [[##TEMPLATE##Facade getInstance] add##TEMPLATE##];
}

/**/
- (void) deactivateEntity
{
	[[##TEMPLATE##Facade getInstance] deactivate##TEMPLATE##: my##ATRIBUTE_KEY##];
}
- (void) removeEntity
{
	[[##TEMPLATE##Facade getInstance] remove##TEMPLATE##: my##ATRIBUTE_KEY##];
}

/**/
- (void) sendKeyValueResponse
{
	/* Agrega el conjunto de parametros clave de la entidad */
	[myRemoteProxy addParamAsInteger: "XXXX" value: myXXXXId];
}

/**/
- (void) setEntitySettings
{
	##TEMPLATE##_FACADE facade = [##TEMPLATE##Facade getInstance];
	
	[facade setSettingsParamAs##ATTRIBUTE_TYPE##:   "##ATTRIBUTE##" value: my##ATTRIBUTE## refId: myRefId];
	
	[facade applyChanges: my##ATTRIBUTE_KEY##];
}
	

@end
