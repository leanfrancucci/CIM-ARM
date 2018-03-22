#ifndef TIME_LOCK_H
#define TIME_LOCK_H

#define TIME_LOCK id

#include <Object.h>

/**
 *	doc template
 */
@interface TimeLock : Object
{
  int myDayOfWeek;
  int myFromMinute;
  int myToMinute;
}

/**/
- (void) setDayOfWeek: (int) aValue;
- (int) getDayOfWeek;

/**/
- (void) setFromMinute: (int) aValue;
- (int) getFromMinute;

/**/
- (void) setToMinute: (int) aValue;
- (int) getToMinute;

@end

#endif
