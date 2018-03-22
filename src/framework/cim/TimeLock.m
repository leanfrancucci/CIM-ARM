#include "TimeLock.h"

@implementation TimeLock

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
  myDayOfWeek = 0;
  myFromMinute = 0;
  myToMinute = 0;
	return self;
}

/**/
- (void) setDayOfWeek: (int) aValue { myDayOfWeek = aValue; }
- (int) getDayOfWeek { return myDayOfWeek; }

/**/
- (void) setFromMinute: (int) aValue { myFromMinute = aValue; }
- (int) getFromMinute { return myFromMinute; }

/**/
- (void) setToMinute: (int) aValue { myToMinute = aValue; }
- (int) getToMinute { return myToMinute; }

@end
