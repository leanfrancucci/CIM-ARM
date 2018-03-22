#ifndef BUZZER_H
#define BUZZER_H

#define BUZZER id

#include <Object.h>
#include "OTimer.h"

typedef enum {
	BuzzerState_ON
 ,BuzzerState_OFF
} BuzzerState;

/**
 *	doc template
 */
@interface Buzzer : Object
{
	OTIMER myTimer;
	BuzzerState myBuzzerState;
	int myHandle;
	int myCurrentLevel;
	BOOL myIsEnabled;
}

/**/
+ getInstance;

/**/
- (void) buzzerBeep: (unsigned long) aTime;

/**/
- (void) buzzerStart;

/**/
- (void) buzzerStop;

/**/
- (void) disableBuzzer;
- (void) enableBuzzer;

/**/
- (int) getCurrentLavel;

/**/
- (void) stopAndDisableBuzzer;

@end

#endif
