#include "system/util/all.h"
#include "TelesupParser.h"

//#define printd(args...) doLog(args)
#define printd(args...)

@implementation TelesupParser

+ new
{
	return [[super new] initialize];
}

- initialize
{	
	/**/
	myTelesupRol = 0;
	mySystemId[0] = '\0';

	return self;
}

/**/
- (void) setTelesupRol: (int) aTelesupRol { myTelesupRol = aTelesupRol; }
- (int) getTelesupRol { return myTelesupRol; }

/**/
- (void) setSystemId: (char *) aSystemId { stringcpy(mySystemId, aSystemId); }
- (char *) getSystemId { return mySystemId; }

/**/
- (REQUEST) getRequest: (char *) aMessage
{
	THROW( ABSTRACT_METHOD_EX );
	return NULL;
}

/**/
- (char *) getParamAsString: (char *) aMessage paramName: (char *) aParamName
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}

/**/
- (char *) getParamAsTrimString: (char *) aMessage paramName: (char *) aParamName
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}



/**/
- (int) getParamAsInteger: (char *) aMessage paramName: (char *) aParamName
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}

/**/
- (int) getParamAsLong: (char *) aMessage paramName: (char *) aParamName
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}

/**/
- (BOOL) getParamAsBoolean: (char *) aMessage paramName: (char *) aParamName
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}


/**/
- (float) getParamAsFloat: (char *) aMessage paramName: (char *) aParamName
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}

/**/
- (money_t) getParamAsCurrency: (char *) aMessage paramName: (char *) aParamName

{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}

/**/
- (datetime_t) getParamAsDateTime: (char *) aMessage paramName: (char *) aParamName
{
	THROW( ABSTRACT_METHOD_EX );
	return 0;
}

@end
