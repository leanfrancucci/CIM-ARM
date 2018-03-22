#ifndef DALLAS_DEV_THREAD_H
#define DALLAS_DEV_THREAD_H

#define DALLAS_DEV_THREAD id

#include <Object.h>
#include "system/os/all.h"
#include "system/util/all.h"

/**
 *	doc template
 */
@interface DallasDevThread : OThread
{
  id myObserver;
  BOOL myIsEnable;
}

/**/
+ getInstance;


/**/
- (void) setObserver: (id) anObserver;

/**/
- (void) enable;

/**/
- (void) disable;

@end

#endif
