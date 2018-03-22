#include "Option.h"
#include "system/util/all.h"

@implementation Option

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myKey = 0;
	*myValue = '\0';
	return self;
}

/**/
- (void) setKey: (int) aKey { myKey = aKey; }
- (void) setValue: (char *) aValue { stringcpy(myValue, aValue); }

/**/
+ newOption: (int) aKey value: (char *) aValue
{
	OPTION option = [Option new];

	[option setKey: aKey];
	[option setValue: aValue];

	return option;
}

/**/
- (int) getKeyOption { return myKey; }

/**/
- (char *) getValue { return myValue; }

/**/
- (STR) str
{
	return myValue;
}

@end
