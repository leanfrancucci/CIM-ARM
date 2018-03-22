#ifndef SWIPE_READER_THREAD_H
#define SWIPE_READER_THREAD_H

#define SWIPE_READER_THREAD id

#include <Object.h>
#include "system/os/all.h"
#include "system/util/all.h"

/**
 *	doc template
 */
@interface SwipeReaderThread : OThread
{
  id myObserver;
  BOOL myIsEnable;
	id myComPort;
	int myTimeout;
	int myComPortNumber;
	BaudRateType myBaudRate;
	int myReadTimeout;
}

/**/
+ getInstance;


/**/
- (void) setObserver: (id) anObserver;

/**/
- (void) enable;
- (void) disable;

@end

#endif
