#ifndef ASYNC_MSG_THREAD_H
#define ASYNC_MSG_THREAD_H

#define ASYNC_MSG_THREAD id

#include <Object.h>
#include "system/os/all.h"
#include "JExceptionForm.h"
#include "system/util/all.h"
#include "ctapp.h"

typedef struct {
    char description[200];
    
} AsyncMsg;

/**
 *	doc template
 */
@interface AsyncMsgThread : OThread
{
	SYNC_QUEUE mySyncQueue;
	BOOL myWait;
    id mySystemOpRequest;
}

+ getInstance;

/**/
- (void) addAsynMsg: (char *) aDescription;
- (void) setSystemOpRequest: (id) anObject;

@end

#endif
