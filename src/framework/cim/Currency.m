#include "Currency.h"
#include "system/util/all.h"

@implementation Currency

/**/
- (void) setCurrencyId: (int) aCurrencyId
{
	myCurrencyId = aCurrencyId;
}

/**/
- (int) getCurrencyId
{
	return myCurrencyId;
}
	
/**/
- (void) setName: (char *) aName
{
	stringcpy(myName, aName);
};

/**/
- (char *) getName
{
	return myName;
}

/**/
- (STR) str
{
	return myCurrencyCode;
}

/**/
- (void) setCurrencyCode: (char *) aValue { stringcpy(myCurrencyCode, aValue); }
- (char *) getCurrencyCode { return myCurrencyCode; }


@end

