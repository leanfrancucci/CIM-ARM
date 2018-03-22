#include "JcmThread.h"
#include "safeBoxMgr.h"


@implementation JcmThread

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myObjectPtr = NULL;
	return self;
}

/**/
- (void) run
{
	threadSetPriority(-20);

	(*threadExecFun)(myObjectPtr);

}

- ( void ) setExecFun: (ExecFunction) execfun
{
	threadExecFun = execfun;	
}

- ( void ) setObjectPtr: (void*) objPtr
{
	myObjectPtr = objPtr;
}

@end
