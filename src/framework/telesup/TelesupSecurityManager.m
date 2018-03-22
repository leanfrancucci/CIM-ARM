#include "TelesupSecurityManager.h"

//#define printd(args...) doLog(args)
#define printd(args...)

@implementation TelesupSecurityManager

static TELESUP_SECURITY_MANAGER myTelesupSecurityManager = nil ;

/**/
+ new
{
	printd("TelesupSecurityManager - new [Singleton]\n" );
	if ( myTelesupSecurityManager ) return myTelesupSecurityManager;
	myTelesupSecurityManager = [[super new] initialize];
	return myTelesupSecurityManager;	
}

/**/
+ getInstance
{
	return [TelesupSecurityManager new];
};

/**/
- initialize
{
	
	return self;
}

 
/**/
- (void) checkAccess: (int) aRol groupOp: (int) aGroupOperation
{
}
;

/**/
- (void) grantAccess: (int) aRol groupOp: (int) aGroupOperation
{
}
;

/**/
- (void) denyAccess: (int) aRol groupOp: (int) aGroupOperation
{
}
;



@end
