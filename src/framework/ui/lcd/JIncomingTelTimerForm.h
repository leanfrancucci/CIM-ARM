#ifndef JINCOMING_TEL_TIMER_FORM_H
#define JINCOMING_TEL_TIMER_FORM_H

#define JINCOMING_TEL_TIMER_FORM id

#include "JSimpleTimerForm.h"
#include "JLabel.h"
#include "system/os/all.h"

/**
 *	
 */
@interface JIncomingTelTimerForm: JSimpleTimerForm
{
	BOOL inTelesup;
}

- (void) startIncomingTelesup;
- (void) finishIncomingTelesup;

@end

#endif

