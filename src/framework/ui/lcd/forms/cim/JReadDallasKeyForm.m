#include "JReadDallasKeyForm.h"
#include "MessageHandler.h"
#include "CimGeneralSettings.h"

//#define printd(args...) doLog(args)
#define printd(args...)

@implementation JReadDallasKeyForm


/**/
- (void) onCreateForm
{
	[super onCreateForm];
	if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_DALLAS_KEY)
		myLabelTitle = [self addLabelFromResource: RESID_ENTER_DALLAS_KEY default: "Enter Dallas Key..."];
	else
		if ([[CimGeneralSettings getInstance] getLoginDevType] == LoginDevType_SWIPE_CARD_READER)
			myLabelTitle = [self addLabelFromResource: RESID_ENTER_SWIPE_CARD_KEY default: "Enter Swipe Card Key..."];
}

/**/
- (char *) getCaption1
{	
	return getResourceStringDef(RESID_CANCEL_KEY, "cancel");
}

/**/
- (char *) getCaption2
{	
	return NULL;
}

/**/
- (void) onMenu1ButtonClick
{
	[self closeForm];
}

@end
