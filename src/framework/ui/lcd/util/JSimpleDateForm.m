#include "JSimpleDateForm.h"
#include "MessageHandler.h"
#include "RegionalSettings.h"

//#define printd(args...) doLog(args)
#define printd(args...)

static char myBackMessage[] = "atras";
static char myEnterMessage[] = "entrar";

@implementation  JSimpleDateForm
/**/
- (void) initComponent
{
	[super initComponent];
	*myTitle = '\0';
	*myDescription = '\0';
	myDateValue = 0;
}

/**/
- (void) doOpenForm
{

	[super doOpenForm];
	
	if (*myTitle != '\0') {
		myLabelTitle = [self addLabel: myTitle];
	}

	if (*myDescription != '\0') {
		myLabelDescription = [self addLabel: myDescription];
	}
	
	myDate = [JDate new];	
	[myDate setReadOnly: FALSE];
	[myDate setSystemTimeMode: FALSE];
	[myDate setJDateFormat: [[RegionalSettings getInstance] getDateFormat]];
	[myDate setDateValue: myDateValue];
	[self addFormComponent: myDate];

	[self focusFormFirstComponent];

	[self doChangeStatusBarCaptions];
}


/**/
- (datetime_t) getDateVal  { return [myDate getDateValue]; }
- (void) setDateVal: (datetime_t) aValue { myDateValue = aValue; }

/**/
- (void) setTitle: (char *) aTitle { stringcpy(myTitle, aTitle); }
- (void) setDescription: (char *) aDescription { stringcpy(myDescription, aDescription); }

/**/
- (void) onMenu1ButtonClick
{	
	myModalResult = JFormModalResult_CANCEL;
	[self closeForm];
}

/**/
- (void) onMenu2ButtonClick
{
	myModalResult = JFormModalResult_OK;
	[self closeForm];
}

/**/
- (char *) getCaption1
{
	return getResourceStringDef(RESID_BACK_KEY, myBackMessage);
}

/**/
- (char *) getCaption2
{
	return getResourceStringDef(RESID_ENTER, myEnterMessage);
}

/**/
- (char *) getCaptionX
{
	return NULL;
}

@end
