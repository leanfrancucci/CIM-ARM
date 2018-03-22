#include "JSimpleTextForm.h"
#include "MessageHandler.h"
#include "BarcodeScanner.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

static char myBackMessage[] = "atras";
static char myEnterMessage[] = "entrar";

@implementation  JSimpleTextForm
/**/
- (void) initComponent
{
	[super initComponent];
	*myTitle = '\0';
	*myDescription = '\0';
	*myTextValue = '\0';
	myNumericMode = FALSE;
	myLongValue = 0;
	myTextWidth = 9;
	myPasswordMode = FALSE;
	myScannigModeEnable = FALSE;
	myCaption1[0] = '\0';
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
	
	myText = [JText new];
	[myText setWidth: myTextWidth];
	[myText setNumericMode: myNumericMode];
	[myText setPasswordMode: myPasswordMode];
	if (myNumericMode && !myPasswordMode) [myText setLongValue: myLongValue];
	else ([myText setText: myTextValue]);

	[self addFormComponent: myText];

	[self focusFormFirstComponent];

	[self doChangeStatusBarCaptions];

	if (myScannigModeEnable) {
		[[BarcodeScanner getInstance] setObserver: self];
		[[BarcodeScanner getInstance] enable];
	}
}

/**/
- (void) setWidth: (int) aWidth
{
	myTextWidth = aWidth;
}

/**/
- (void) setNumericMode: (BOOL) aValue { myNumericMode = aValue; }
- (void) setPasswordMode: (BOOL) aPasswordMode { myPasswordMode = aPasswordMode; }

/**/
- (void) setLongValue: (long) aValue { myLongValue = aValue; }
- (long) getLongValue { return [myText getLongValue]; }

/**/
- (char *) getTextValue  { return [myText getText]; }
- (void) setTextValue: (char *) aValue { stringcpy(myTextValue, aValue); }

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
	if (strlen(myCaption1) == 0)
		return getResourceStringDef(RESID_BACK_KEY, myBackMessage);
		else
			return myCaption1;
	return NULL;
}

/**/
- (char *) getCaption2
{
	return getResourceStringDef(RESID_ENTER, myEnterMessage);
}

/**/
- (void) onBarcodeScanned: (char *) aBarcode
{
	char data[50];

	stringcpy(data, aBarcode);

	// el codigo de barras nunca puede ser mayor al definido en el edit
	if (strlen(data) > myTextWidth)
		data[myTextWidth] = '\0';

	[myText setText: data];

	[self paintComponent];
}

/**/
- (void) setScanningModeEnable: (BOOL) aValue
{
	myScannigModeEnable = aValue;
}	

/**/
- (void) closeForm
{
	if (myScannigModeEnable) {
		[[BarcodeScanner getInstance] disable];
		[[BarcodeScanner getInstance] removeObserver];
	}

	[super closeForm];
}

/**/
- (void) setCaption1: (char*) aCaption
{
	stringcpy(myCaption1, aCaption);
}

@end
