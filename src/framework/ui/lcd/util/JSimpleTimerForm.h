#ifndef JSIMPLE_TIMER_FORM2_H
#define JSIMPLE_TIMER_FORM2_H

#define JSIMPLE_TIMER_FORM id

#include "JCustomForm.h"
#include "JLabel.h"
#include "system/os/all.h"

/**
 *	
 */
@interface JSimpleTimerForm: JCustomForm
{
	JLABEL myLabelMessage;
	JLABEL myLabelTimeLeft;
	OTIMER myUpdateTimer;
	int myTimeout;
	int myAuxTimeout;
	char myTitle[61];
	BOOL myIsClosingForm;
	BOOL myShowTimer;
	BOOL myCanCancel;
	OMUTEX myMutex;
	BOOL myCenterTitle;
	BOOL myShowButton1;
	BOOL myShowButton2;
	BOOL myIsAdvanceTimer;
	char myCaption1[10];
	char myCaption2[10];
	BOOL myIgnoreActiveWindow;
}

/**/
- (void) setIgnoreActiveWindow: (BOOL) aValue;

/**/
- (void) setTitle: (char *) aTitle;

/**/
- (void) setTimeout: (int) aSeconds;

/**/
- (void) setShowTimer: (BOOL) aValue;

/**/
- (void) setCanCancel: (BOOL) aValue;

/**/
- (void) setCenterTitle: (BOOL) aValue;

/**/
- (void) setShowButton1: (BOOL) aValue;

/**/
- (void) setShowButton2: (BOOL) aValue;

/**/
- (void) setIsAdvanceTimer: (BOOL) aValue;

/**/
- (void) setCaption1: (char *) aCaption;

/**/
- (void) setCaption2: (char *) aCaption;

@end

#endif

