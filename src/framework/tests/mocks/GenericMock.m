#include "GenericMock.h"

@implementation GenericMock

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	[self resetMock];
	return self;
}

/**/
- (void) setMockName: (char *) aName
{
	strcpy(myMockName, aName);
}

/**/
- (void) resetMock
{
	*myLastMethod = '\0';
}

/**/
- (char *) getLastMethod
{
	return myLastMethod;
}

/**/
- doesNotRecognize:(SEL)aSelector
{
	char buf[255];
	strcpy(buf, aSelector);
  //doLog(0,"Mock method : %s.%s()\n", myMockName, buf);
	strcpy(myLastMethod, aSelector);
}
- doesNotUnderstand:aMessage
{
  return [self doesNotRecognize:[aMessage selector]];
}

@end
