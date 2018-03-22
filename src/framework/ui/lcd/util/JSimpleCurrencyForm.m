#include "JSimpleCurrencyForm.h"
#include "AmountSettings.h"
#include "MessageHandler.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

static char myBackMessage[] = "atras";
static char myEnterMessage[] = "entrar";

@implementation  JSimpleCurrencyForm
/**/
- (void) initComponent
{
	[super initComponent];
	*myTitle = '\0';
	*myDescription = '\0';
	*myCurrencyCode = '\0';
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
	
	if (*myCurrencyCode != '\0') {
		myLabelCurrencyCode = [JLabel new];
		[myLabelCurrencyCode setAutoSize: FALSE];
		[myLabelCurrencyCode setWidth: 8];
		[myLabelCurrencyCode setCaption: myCurrencyCode];
		[self addFormComponent: myLabelCurrencyCode];
	}

	myNumericText = [JNumericText new];
	[myNumericText setWidth: 10];
	[myNumericText setDecimalDigits: [[AmountSettings getInstance] getItemsRoundDecimalQty]];
	[myNumericText setMoneyValue: myValue];
	[self addFormComponent: myNumericText];

	[self focusFormFirstComponent];

	[self doChangeStatusBarCaptions];
}


/**/
- (void) setTitle: (char *) aTitle { stringcpy(myTitle, aTitle); }
- (void) setDescription: (char *) aDescription { stringcpy(myDescription, aDescription); }
- (void) setCurrencyCode: (char *) aCurrencyCode { stringcpy(myCurrencyCode, aCurrencyCode); }
/**/
- (void) setMoneyValue: (money_t) aValue { myValue = aValue; }
- (money_t) getMoneyValue { return [myNumericText getMoneyValue]; }

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

@end

