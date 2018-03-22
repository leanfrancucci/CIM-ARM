#include "JNeedMoreTimeForm.h"
#include "MessageHandler.h"
#include "InputKeyboardManager.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)


@implementation  JNeedMoreTimeForm

static char myYesMessage[] = "SI";
static char myNoMessage[]  = "NO";

/**/
- (void) onCreateForm
{
	[super onCreateForm];

	myCloseTimer = NULL;
	myIsClosingForm = FALSE;
	myIsManualDrop = FALSE;
	myUpdateTimer = [OTimer new];
	[myUpdateTimer initTimer: PERIODIC period: 200 object: self callback: "updateTimerHandler"];

	myLabelMessage = [JLabel new];
	[myLabelMessage setCaption: getResourceStringDef(RESID_NEED_TIME_QUESTION, "Necesita mas tiempo?")];
	[myLabelMessage setWidth: 20];
	[myLabelMessage setHeight: 1];
	[self addFormComponent: myLabelMessage];

	myLabelTimeLeft = [JLabel new];
	[myLabelTimeLeft setCaption: ""];
	[myLabelTimeLeft setWidth: 20];
	[myLabelTimeLeft setHeight: 2];
	[myLabelTimeLeft setWordWrap: TRUE];
	[self addFormComponent: myLabelTimeLeft];

}

/**/
- (void) updateTimerHandler
{
	unsigned long left;
	char label[50];

	if (myIsClosingForm) return;
	if (myCloseTimer == NULL)  return;

	left = [myCloseTimer getTimeLeft];

	//sprintf(label, "La ventana se cerrarra en %ld seg.", left / 1000);
	formatResourceStringDef(label, RESID_WINDOW_CLOSE, "La ventana sera cerrada en %ld seg.", left / 1000);

	[myLabelTimeLeft setCaption: label];

}

/**/
- (void) setCloseTimer: (OTIMER) aTimer
{
	myCloseTimer = aTimer;
	[self updateTimerHandler];
}

/**/
- (void) onMenu1ButtonClick
{
	unsigned long left;

	if (myCloseTimer == NULL)  return;
	left = [myCloseTimer getTimeLeft];
	if ((left / 1000) > 0){
		myModalResult = JFormModalResult_NO;
		myIsClosingForm = TRUE;
		if (myUpdateTimer != NULL) {
			[myUpdateTimer stop];
			[myUpdateTimer free];
			myUpdateTimer = NULL;
		}
		[self closeForm];
	}
}

/**/
- (void) onMenu2ButtonClick
{
	myModalResult = JFormModalResult_YES;
	myIsClosingForm = TRUE;
	if (myUpdateTimer != NULL) {
		[myUpdateTimer stop];
		[myUpdateTimer free];
		myUpdateTimer = NULL;
	}
	[self closeForm];
}

/**/
- (void) cancelForm
{
	myModalResult = JFormModalResult_CANCEL;
	myIsClosingForm = TRUE;
	if (myUpdateTimer != NULL) {
		[myUpdateTimer stop];
		[myUpdateTimer free];
		myUpdateTimer = NULL;
	}
	[self closeForm];
}

/**/
- (char *) getCaption1
{	
	return getResourceStringDef(RESID_NO, myNoMessage);
}

/**/
- (char *) getCaption2
{	
	return getResourceStringDef(RESID_YES, myYesMessage);
}

/**/
- (void) onActivateForm
{

  if (!myIsManualDrop)
    [myLabelMessage setCaption: getResourceStringDef(RESID_NEED_TIME_QUESTION, "Necesita mas tiempo?")];
  else
    [myLabelMessage setCaption: getResourceStringDef(RESID_CANCEL_MANUAL_DROP_QUESTION, "Tiempo ex. Cancelar?")];

  [myUpdateTimer start];
}

/**/
- (void) isManualDrop: (BOOL) aValue
{
  myIsManualDrop = aValue;
}

@end
