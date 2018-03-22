#ifndef JSIMPLE_TIMER_LOCK_FORM_H
#define JSIMPLE_TIMER_LOCK_FORM_H

#define JSIMPLE_TIMER_LOCK_FORM id

#include "JCustomForm.h"
#include "JLabel.h"
#include "system/os/all.h"

/**
 *	
 */
@interface JSimpleTimerLockForm: JCustomForm
{
	JLABEL myLabelMessage;
	JLABEL myLabelTimeLeft;
	OTIMER myUpdateTimer;
	int myTimeout;
	char myTitle[61];
	BOOL myIsClosingForm;
	BOOL myShowTimer;
	BOOL myCanCancel;
	OMUTEX myMutex;
}

/**/
- (void) setTitle: (char *) aTitle;

/**/
- (void) setTimeout: (int) aSeconds;

/**/
- (void) setShowTimer: (BOOL) aValue;

/**/
- (void) setCanCancel: (BOOL) aValue;

@end

#endif

