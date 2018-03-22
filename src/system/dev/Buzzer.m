#include "Buzzer.h"
#include "system/lang/all.h"
#include <linux/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <assert.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include "log.h"
#include "util.h"

#define BUZZER_DEV BASE_PATH "/dev/buzzer"
#define PERIODIC_BUZZER_TIME 700

#define CHECK_BUZZER_DRIVER() do { if (myHandle == -1) return; } while (0)

/* ioctl defs */
#define BUZZER_IOC_MAGIC 'y'

/*
 * 
 */
#define BUZZER_ON			_IO(BUZZER_IOC_MAGIC, 1)
/*
 * 
 */
#define BUZZER_OFF			_IO(BUZZER_IOC_MAGIC, 2)

#define GRAP_IOC_MAXNR		 	2

@implementation Buzzer

static BUZZER singleInstance = NULL; 

/**/
+ new
{
	if (singleInstance) return singleInstance;
	singleInstance = [super new];
	[singleInstance initialize];
	return singleInstance;
}
 
/**/
- initialize
{
	myTimer = [OTimer new];
	myHandle = open(BUZZER_DEV, O_WRONLY);
	myCurrentLevel = 0;
	myIsEnabled = TRUE;
	if (myHandle == -1) {
	//	doLog(0,"Error: cannot open buzzer driver\n");
	}
	return self;
}

/**/
+ getInstance
{
  return [self new];
}

/**/
- (void) buzzerOn
{
	CHECK_BUZZER_DRIVER();
	if (!myIsEnabled) return;
	myBuzzerState = BuzzerState_ON;
	ioctl(myHandle, BUZZER_ON, 0);
	//doLog(0,"ON  BUZZER ON\n"); fflush(stdout);
}

/**/
- (void) buzzerOff
{
	CHECK_BUZZER_DRIVER();
	myBuzzerState = BuzzerState_OFF;
	ioctl(myHandle, BUZZER_OFF, 0);
	//doLog(0,"OFF BUZZER OFF\n"); fflush(stdout);
}

/**/
- (void) buzzerChangeState
{
	CHECK_BUZZER_DRIVER();
	if (myBuzzerState == BuzzerState_ON) [self buzzerOff];
	else [self buzzerOn];
}

/**/
- (void) beepFinish
{
	[self buzzerOff];

	if (myCurrentLevel > 0) {
		[myTimer initTimer: PERIODIC period: PERIODIC_BUZZER_TIME object: self callback: "buzzerChangeState"];
		[myTimer start];
	}

}

/**/
- (void) buzzerBeep: (unsigned long) aTime
{
	CHECK_BUZZER_DRIVER();
	[self buzzerOn];
	[myTimer initTimer: ONE_SHOT period: aTime object: self callback: "beepFinish"];
	[myTimer start];
}

/**/
- (void) buzzerStart
{
	CHECK_BUZZER_DRIVER();
	myCurrentLevel++;
	// Solo la primera vez tiene que comenzar el timer, si luego se van acumulando
	// mas niveles el timer ya esta comenzado
	if (myCurrentLevel == 1) {
		[self buzzerOn];
		[myTimer initTimer: PERIODIC period: PERIODIC_BUZZER_TIME object: self callback: "buzzerChangeState"];
		[myTimer start];
	}
}

/**/
- (void) buzzerStop
{
	CHECK_BUZZER_DRIVER();

	if (myCurrentLevel == 0) return;

	myCurrentLevel--;
	if (myCurrentLevel == 0) {
		[myTimer stop];
		[self buzzerOff];
	}
}

/**/
- (void) disableBuzzer
{
	myIsEnabled = FALSE;
}

/**/
- (void) enableBuzzer
{
	myIsEnabled = TRUE;
}

/**/
- (int) getCurrentLavel
{
	return myCurrentLevel;
}

/**/
- (void) stopAndDisableBuzzer
{
	int i = 1;
	int lavelQty;

	lavelQty = [self getCurrentLavel];

	while (i<=lavelQty){
		[self buzzerStop];
		i++;
	}

	[self disableBuzzer];
}

@end
