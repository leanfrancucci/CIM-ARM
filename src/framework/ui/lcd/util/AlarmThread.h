#ifndef ALARM_THREAD_H
#define ALARM_THREAD_H

#define ALARM_THREAD id

#include <Object.h>
#include "system/os/all.h"
#include "JExceptionForm.h"
#include "system/util/all.h"

typedef struct {
	JDialogMode dialogMode;
	char *text;
	void *data;
	id object;
	char callback[200];
	JDialogResult modalResult;
} Alarm;

/**
 *	doc template
 */
@interface AlarmThread : OThread
{
	SYNC_QUEUE mySyncQueue;
	BOOL myWait;
}

+ getInstance;

/**/
- (void) addAlarm: (char *) anAlarm;

/**/
- (void) askYesNoQuestion: (char *) anAlarm 
	data: (void*) aData 
	object: (id) anObject
	callback: (char *) aCallback;

/**/
- (void) setAlarmWait: (BOOL) aValue;

@end

#endif
