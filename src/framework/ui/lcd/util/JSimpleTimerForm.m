#include "JSimpleTimerForm.h"
#include "MessageHandler.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)


@implementation  JSimpleTimerForm

static char myDoneMessage[] = "listo";
static char myCancelMessage[] = "cancel";

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
- (void) setCenterTitle: (BOOL) aValue
{
	myCenterTitle = aValue;
}

/**/
- (void) setShowButton1: (BOOL) aValue
{
	myShowButton1 = aValue;
}

/**/
- (void) setShowButton2: (BOOL) aValue
{
	myShowButton2 = aValue;
}

/**/
- (void) setIsAdvanceTimer: (BOOL) aValue
{
	myIsAdvanceTimer = aValue;
}

/**/
- (void) setCaption1: (char *) aCaption
{
	stringcpy(myCaption1, aCaption);
}

/**/
- (void) setCaption2: (char *) aCaption
{
	stringcpy(myCaption2, aCaption);
}

/**/
- (void) onCreateForm
{
	[super onCreateForm];
	*myTitle = '\0';
	myTimeout = 60;
	myAuxTimeout = 0;
	myIsClosingForm = FALSE;
	myShowTimer = TRUE;
	myCanCancel = FALSE;
	myMutex = [OMutex new];
	myCenterTitle = FALSE;
	myShowButton1 = FALSE;
	myShowButton2 = TRUE;
	myIsAdvanceTimer = FALSE;
	myIgnoreActiveWindow = TRUE;
	*myCaption1 = '\0';
	*myCaption2 = '\0';
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

	if (!myIsAdvanceTimer){ // tiempo en retroceso

		// Solo se decrementa el timer cuando el form esta activo
		if (myIgnoreActiveWindow)
			myTimeout--;
		else if ([self isActiveWindow]) myTimeout--;

		if (myTimeout <= 0) {
			myModalResult = JFormModalResult_CANCEL;
			myIsClosingForm = TRUE;
			[myUpdateTimer stop];
			[myUpdateTimer free];
			[myMutex unLock];
			[self closeForm];
			return;
		}
		myAuxTimeout = myTimeout;

	}else{  // tiempo en avance

		// Solo se incrementa el timer cuando el form esta activo
		if (myIgnoreActiveWindow)
			myAuxTimeout++;
		else if ([self isActiveWindow]) myAuxTimeout++;

		if (myTimeout <= myAuxTimeout) {
			myModalResult = JFormModalResult_CANCEL;
			myIsClosingForm = TRUE;
			[myUpdateTimer stop];
			[myUpdateTimer free];
			[myMutex unLock];
			[self closeForm];
			return;
		}

	}
	


	if (myShowTimer) {
		[self formatTimeLeft: myAuxTimeout * 1000 buffer: timeStr];
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
	[myMutex lock];

  if (myShowButton2){
		myModalResult = JFormModalResult_YES;

		if (myIsClosingForm) {
			[myMutex unLock];
			return;
		}

		myIsClosingForm = TRUE;
		[myUpdateTimer stop];
		[myUpdateTimer free];

		[myMutex unLock];

		[self closeForm];

	} else {
		[myMutex unLock];
	}

}

/**/
- (void) onMenu1ButtonClick
{
	[myMutex lock];

  if (myShowButton1){
		myModalResult = JFormModalResult_NO;

		if (myIsClosingForm) {
			[myMutex unLock];
			return;
		}

		myIsClosingForm = TRUE;
		[myUpdateTimer stop];
		[myUpdateTimer free];

		[myMutex unLock];

		[self closeForm];

	} else {
		[myMutex unLock];
	}

}

/**/
- (void) onMenuXButtonClick
{
	[myMutex lock];

	if (myCanCancel) {
		myModalResult = JFormModalResult_NO;
		myIsClosingForm = TRUE;
		[myUpdateTimer stop];
		[myUpdateTimer free];
		[myMutex unLock];
		[self closeForm];
	} else {
		[myMutex unLock];
	}



}


/**/
- (char *) getCaption1
{	
	if (myShowButton1){
		if (strlen(myCaption1) != 0)
			return myCaption1;
	}
	return NULL;
}

/**/
- (char *) getCaption2
{	
	if (myShowButton2){
		if (strlen(myCaption2) == 0)
			return getResourceStringDef(RESID_DONE, myDoneMessage);
		else
			return myCaption2;
	}
	return NULL;
}

/**/
- (char *) getCaptionX
{	
	if (myCanCancel) return getResourceStringDef(RESID_CANCEL_KEY, myCancelMessage);
	return NULL;
}

/**/
- (void) doOpenForm
{
	char titleStr[30];
	char format[10];
	char buffer[50];

	[super doOpenForm];

	[myMutex lock];
	
	// Titulo centrado
	if (myCenterTitle){
		strcpy(titleStr, myTitle);
		sprintf(format, "%%%ds", (20 - strlen(titleStr)) / 2);
		sprintf(buffer, format, " ");
		strcat(buffer, titleStr);
	}else{
		// Titulo sin centrar
		strcpy(buffer, myTitle);
	}

	myLabelMessage = [self addLabel: buffer];

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

/**/
- (void) setIgnoreActiveWindow: (BOOL) aValue
{
	myIgnoreActiveWindow = aValue;
}

@end
