#ifndef  JNEED_MORE_TIME_FORM_H
#define  JNEED_MORE_TIME_FORM_H

#define  JNEED_MORE_TIME_FORM  id

#include "JCustomForm.h"

#include "JLabel.h"
#include "JDate.h"
#include "JTime.h"
#include "system/db/all.h"

/**
 *	
 */
@interface  JNeedMoreTimeForm: JCustomForm
{
	JLABEL myLabelMessage;
	JLABEL myLabelTimeLeft;
	OTIMER myCloseTimer;
	OTIMER myUpdateTimer;
	BOOL myIsClosingForm;
	BOOL myIsManualDrop;
}

/**/
- (void) setCloseTimer: (OTIMER) aTimer;

/**/
- (void) cancelForm;

/**/
- (void) isManualDrop: (BOOL) aValue;

@end

#endif

