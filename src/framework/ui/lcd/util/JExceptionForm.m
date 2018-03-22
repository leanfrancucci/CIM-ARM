#include "JExceptionForm.h"
#include "CtSystem.h"
#include "util.h"
#include "InputKeyboardManager.h"
#include "include/keypadlib.h"
#include "MessageHandler.h"
#include "PrinterSpooler.h"

//#define printd(args...) doLog(0,args)
#define printd(args...)

@implementation  JExceptionForm

/**/
- (void) onCreateForm
{
	[super onCreateForm];
	keyPressed = 0;
	myOldForm = NULL;
	[self setWidth: 20];
	[self setHeight: 4];
	
	labelMessage = [JLabel new];
	[labelMessage setWidth: 20];
	[labelMessage setHeight: 3];
	[labelMessage setWordWrap: TRUE];
	[labelMessage setAutoSize: FALSE];
	[labelMessage setCaption: ""];
	[self addFormComponent: labelMessage];
//	[labelMessage setVisible: TRUE];
	
	myLabelMenu1 = [JLabel new];	
	[myLabelMenu1 setAutoSize: FALSE];
	[myLabelMenu1 setWidth: myWidth / 3];		
	[myLabelMenu1 setTextAlign: UTIL_AlignLeft];
	[myLabelMenu1 setCaption: getResourceStringDef(RESID_MENU_1, "Menu 1")];
	[self addComponent: myLabelMenu1];

	[self  addBlanks: 1];
	
	myLabelMenuX = [JLabel new];
	[myLabelMenuX setAutoSize: FALSE];	
	[myLabelMenuX setWidth: myWidth / 3];		
	[myLabelMenuX setTextAlign: UTIL_AlignCenter];
	[myLabelMenuX setCaption: getResourceStringDef(RESID_MENU_X, "Menu X")];
	[self  addComponent: myLabelMenuX];
	
	[self  addBlanks: 1];
	
	myLabelMenu2 = [JLabel new];	
	[myLabelMenu2 setAutoSize: FALSE];
	[myLabelMenu2 setWidth: myWidth / 3];		
	[myLabelMenu2 setTextAlign: UTIL_AlignRight];
	[myLabelMenu2 setCaption: getResourceStringDef(RESID_MENU_2, "Menu 2")];	
	[self  addComponent: myLabelMenu2];
		
//	[myGraphicContext clearScreen];
//	doLog(0,"JExceptionForm -> onCreateForm() \n");
}

/**/
- (void) setMessage: (char*) aMessage
{
	char buf[100];

	sprintf(buf, "%-80c", ' ');
	[labelMessage setCaption: buf];

	sprintf(buf, "%-60s", aMessage);
	[labelMessage setCaption: buf];

	//[self doChangeStatusBarCaptions];
	[myLabelMenu1 paintComponent];
	[myLabelMenu2 paintComponent];
	[myLabelMenuX paintComponent];
}

/**/
- (void) processKeys
{
	while (keyPressed == 0) msleep(100);
}

/**/
- (void) keyboardHandler: (void*) aKey
{
	int key = *(int*)aKey;

	if (key == 'c') keyPressed = key;
	if (key == 'e' && myMode == 1) keyPressed = key;;
	
}

/**/
- (void) onCloseWindow: (JWINDOW) aWindow
{
	int key;

	if (myOldForm)
		[myOldForm setOnCloseWindowHandler: NULL];

	myOldForm = NULL;
	//[self paintComponent];
	key = 'c';
	[self keyboardHandler: &key];
}

- (JDialogResult) showExceptionForm: (int) aMode message: (char*) aMessage
{
	BOOL ignoreKeyEvents;

	myMode = aMode;

	// Espero hasta que la ventana sea NULL o no sea JExceptionForm
	while ([JWindow getActiveWindow] != NULL && 
				 [[JWindow getActiveWindow] isKindOf: [JExceptionForm class]]) msleep(1000);

	ignoreKeyEvents	= [[InputKeyboardManager getInstance] getIgnoreKeyEvents];

	[[InputKeyboardManager getInstance] setIgnoreKeyEvents: FALSE];
	[[InputKeyboardManager getInstance] setKeyboardHandler: self method: "keyboardHandler:"];

	myOldForm = [JWindow getActiveWindow];
	if (myOldForm) {
		//doLog(0,"Old form class Name = %s\n", [myOldForm name]);
	
		[myOldForm setOnCloseWindowHandler: self];
		[myOldForm deactivateWindow];
	}
		
	[self showForm];
		
	[myLabelMenuX setCaption: ""];
	if (aMode == 1) {
		[myLabelMenu1 setCaption: getResourceStringDef(RESID_NO_UPPER, "NO")];
		[myLabelMenu2 setCaption: getResourceStringDef(RESID_YES_UPPER, "SI")];
	} else {
		[myLabelMenu1 setCaption: ""];
		[myLabelMenu2 setCaption: getResourceStringDef(RESID_OK_UPPER, "OK")];
	}
	
	[self setMessage: aMessage];
	
	[self processKeys];

	[[InputKeyboardManager getInstance] setKeyboardHandler: NULL method: ""];
	[[InputKeyboardManager getInstance] setIgnoreKeyEvents: ignoreKeyEvents];

	if (myOldForm) {
		[myOldForm setOnCloseWindowHandler: NULL];
		[myOldForm activateWindow];
	}
	
	if (keyPressed == 'c') return JDialogResult_YES;
	else return JDialogResult_NO;
	
}
	
/**/
+ (JDialogResult) showYesNoForm: (char *) aMessage
{
	JEXCEPTION_FORM form;
	JDialogResult result;

	//doLog(0,"JExceptionForm -> showYesNoForm 1\n");		
	form = [JExceptionForm createForm: NULL];
	result = [form showExceptionForm: 1 message: aMessage];		
	[form free];
	//doLog(0,"JExceptionForm -> showYesNoForm 2\n");
	
	return result;
}

- (void) showProcess: (char*) aMessage
{

	[[InputKeyboardManager getInstance] setKeyboardHandler: self method: "keyboardHandler:"];

	myOldForm = [JWindow getActiveWindow];
	if (myOldForm) {
		//doLog(0,"Old form class Name = %s\n", [myOldForm name]);
		[myOldForm setOnCloseWindowHandler: self];
		[myOldForm deactivateWindow];
	}
		
	[self showForm];
		
	[myLabelMenuX setCaption: ""];
	[myLabelMenu1 setCaption: ""];
	[myLabelMenu2 setCaption: ""];
	
	[self setMessage: aMessage];

}

/**/
- (void) printerStateNotification: (int) aPrinterState
{
	
	//doLog(0,"Llego un printerStateNotification() cuando estoy en un JExceptionForm, lo descarto\n");
  [[PrinterSpooler getInstance] cancelLastJob];
 		
}

/**/
- (void) acceptorSerialNumberChangeNotification
{
PASO_POR_ACA();
}

/**/
- (void) closeProcessForm
{
	[[InputKeyboardManager getInstance] setKeyboardHandler: NULL method: ""];

	if (myOldForm) {
		[myOldForm setOnCloseWindowHandler: NULL];
		[myOldForm activateWindow];
	}

	[self closeForm];
}

/**/
+ (JFORM) showProcessForm: (char *) aMessage
{
	JEXCEPTION_FORM form;

	//doLog(0,"JExceptionForm -> showProcessForm\n");		
	form = [JExceptionForm createForm: NULL];
	[form showProcess: aMessage];
		
	return form;
}

/**/
+ (JFORM) showProcessForm2: (JCOMPONENT) aComponent msg: (char *) aMessage 
{
	JEXCEPTION_FORM form;

	//doLog(0,"JExceptionForm -> showProcessForm\n");		
	form = [JExceptionForm createForm: NULL];
	[form showProcess: aMessage];
		
	return form;
}

/**/
+ (JDialogResult) showOkForm: (char *) aMessage
{
	JEXCEPTION_FORM form;
	JDialogResult result;

	//doLog(0,"JExceptionForm -> showOkForm 1\n");		
	form = [JExceptionForm createForm: NULL];
	result = [form showExceptionForm: 2 message: aMessage];		
	[form free];
	//doLog(0,"JExceptionForm -> showYesNoForm 2\n");
	
	return result;
}


/**/
+ (JDialogResult) showException: (int) anExceptionCode exceptionName: (char*) anExceptionName
{
	char myExceptionMessage[ JComponent_MAX_LEN + 1 ];
	char myExceptionDescription[ JComponent_MAX_LEN + 1 ];
	char myExceptionName[100];
	JDialogResult result;
	JEXCEPTION_FORM form;

	stringcpy(myExceptionName, anExceptionName);
	TRY

		ex_printfmt();
		[[MessageHandler getInstance] processMessage: myExceptionDescription
									 								 messageNumber: anExceptionCode];
																	 
		snprintf(myExceptionMessage, JComponent_MAX_LEN, myExceptionDescription);
	CATCH
		snprintf(myExceptionMessage, JComponent_MAX_LEN, "Exception: %d! %s", anExceptionCode, myExceptionName);
		//doLog(0,"Mensaje no encontrado  = !%s!\n", myExceptionMessage);

	END_TRY
	
	form = [JExceptionForm createForm: NULL];
	result = [form showExceptionForm: 0 message: myExceptionMessage];
	[form free];
	
	return result;
	
}

@end


