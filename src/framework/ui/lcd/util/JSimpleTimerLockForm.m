#include "JSimpleTimerLockForm.h"
#include "MessageHandler.h"

//#define printd(args...) doLog(args)
#define printd(args...)


@implementation  JSimpleTimerLockForm


/**/
- (void) setTitle: (char *) aTitle
{
	stringcpy(myTitle, aTitle);
}

/**/
- (void) setTimeout: (int) aSeconds
{
	myTimeout = aSeconds;
}

/**/
- (void) setShowTimer: (BOOL) aValue
{
	myShowTimer = aValue;
}

/**/
- (void) setCanCancel: (BOOL) aValue
{
	myCanCancel = aValue;
}

/**/
- (void) onCreateForm
{
	[super onCreateForm];
	*myTitle = '\0';
	myTimeout = 60;
	myIsClosingForm = FALSE;
	myShowTimer = TRUE;
	myCanCancel = FALSE;
	myMutex = [OMutex new];
}

/**/
- free
{
	myIsClosingForm = TRUE;
	[myMutex free];
	return [super free];
}

/**/
- (char *) formatTimeLeft: (unsigned long) aLeftTime buffer: (char *) aBuffer
{
	int left = aLeftTime / 1000;
	sprintf(aBuffer, "%d:%02d", left / 60, left % 60);
	return aBuffer;
}

/**/
- (void) updateTimerHandler
{
	char timeStr[50];
	char format[20];
	char buffer[21];

  if (myIsClosingForm) return;

	[myMutex lock];

	if (myIsClosingForm) {
		[myMutex unLock];
		return;
	}

	myTimeout--;

	if (myTimeout <= 0) {
		myModalResult = JFormModalResult_CANCEL;
		myIsClosingForm = TRUE;

		[myUpdateTimer stop];
		[myUpdateTimer free];
		[myMutex unLock];
		[self closeForm];
		return;
	}

	if (myShowTimer) {
		[self formatTimeLeft: myTimeout * 1000 buffer: timeStr];
		sprintf(format, "%%%ds", (20 - strlen(timeStr)) / 2);
		sprintf(buffer, format, " ");
		strcat(buffer, timeStr);
	
		[myLabelTimeLeft setCaption: buffer];
	}

	[myMutex unLock];
}

/**/
- (void) onMenu2ButtonClick
{

}

/**/
- (void) onMenuXButtonClick
{

}

/**/
- (void) onMenu1ButtonClick
{

}

/**/
- (char *) getCaption1
{	
	return NULL;
}

/**/
- (char *) getCaption2
{	
	return NULL;
}

/**/
- (char *) getCaptionX
{
	return NULL;
}

/**/
- (void) doOpenForm
{
	[super doOpenForm];

	[myMutex lock];
	
	myLabelMessage = [self addLabel: myTitle];

	if (myShowTimer) {
		myLabelTimeLeft = [JLabel new];
		[myLabelTimeLeft setCaption: ""];
		[myLabelTimeLeft setWidth: 20];
		[myLabelTimeLeft setHeight: 1];
		[myLabelTimeLeft setWordWrap: TRUE];
		[self addFormComponent: myLabelTimeLeft];
	}

	myUpdateTimer = [OTimer new];
	[myUpdateTimer initTimer: PERIODIC period: 1000 object: self callback: "updateTimerHandler"];
	[myUpdateTimer start];

	[myMutex unLock];

	[self updateTimerHandler];

}

@end
