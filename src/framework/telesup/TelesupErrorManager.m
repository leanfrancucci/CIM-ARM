#include "system/util/all.h"
#include "TelesupErrorManager.h"

//#define printd(args...) 	doLog(args)
#define printd(args...) 	


/**/
@implementation TelesupErrorManager

/**/
+ new
{
	return [[super new] initialize];

}

/**/
- free
{
	return self;
}

/**/
- initialize
{
	[super initialize];
	
	return self;
}
	
/**/
- (int) getErrorCode: (int) excode
{
	/*THROW( ABSTRACT_METHOD_EX );
	return 0;
	*/
	// cambie el ABSTRACT_METHOD_EX por el retorno del codigo de excepcion porque en la mayoria
	// de los casos no me interesa
	return excode;
}

@end
