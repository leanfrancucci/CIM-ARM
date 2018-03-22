#include "JIncomingTelTimerForm.h"
#include "MessageHandler.h"
#include "Audit.h"

//#define printd(args...) doLog(args)
#define printd(args...)


@implementation  JIncomingTelTimerForm

static char myCancelMessage[] = "cancel";

- (void) onOpenForm
{
	[super onOpenForm];
	inTelesup = FALSE;
}

/**/
- (void) onMenu1ButtonClick
{
	if (!inTelesup)
		[super onMenuXButtonClick];
}

/**/
- (void) onMenuXButtonClick
{

}

/**/
- (void) onMenu2ButtonClick
{

}


/**/
- (char *) getCaption1
{	
	if ((myCanCancel) && !(inTelesup)) return getResourceStringDef(RESID_CANCEL_KEY, myCancelMessage);
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
- (void) startIncomingTelesup
{
	char buffer[41];

	[myMutex lock];

	[myUpdateTimer stop];
	[myUpdateTimer free];

	[myMutex unLock];

  sprintf(buffer,"%s                         ", trim(getResourceStringDef(RESID_SUPERVISING, "Supervisando...")));
  
	[myLabelMessage setCaption: buffer];

	[myLabelTimeLeft setCaption: "                    "];

	inTelesup = TRUE;
	[self doChangeStatusBarCaptions];
}

/**/
- (void) finishIncomingTelesup
{
	[self closeForm];
}

/**/
- (void) onCloseForm
{
	if (myTimeout <= 0) 
		[Audit auditEventCurrentUser: Event_CMP_TIMEOUT_CONNECT additional: "" station: 0 logRemoteSystem: FALSE];

	[super onCloseForm];
}


@end
