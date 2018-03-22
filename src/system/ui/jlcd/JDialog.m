#include <assert.h>
#include "UserInterfaceDefs.h"
#include "JDialog.h"


//#define printd(args...) doLog(args)
#define printd(args...)


@implementation  JDialog

/**/
- (void) initComponent
{
 [super initComponent];
 
	myAskingMode = JDialogMode_ASK_OK_CANCEL_MESSAGE;
	myResultAnswer = JDialogResult_NO; 
}


/**/
- free
{
	return [super free];
}

/**/
+ createDialog: (JWINDOW) aParentWindow
{
	return [self createWindow: aParentWindow];
} 

/**
 * Metodos protegidos
 */

/**/
- (int) getScreenDialogHeight
{
	assert(myGraphicContext != NULL);
	
	return [myGraphicContext getHeight];
}		 

		 
/**/
- (void) onCreateWindow
{
		myLabelMsg = [JLabel new];
		[myLabelMsg setAutoSize: FALSE];
		[myLabelMsg setWidth:  [myGraphicContext getWidth]];
		[myLabelMsg setHeight: [self getScreenDialogHeight]];

		[myLabelMsg setWordWrap: TRUE];		
		[myLabelMsg setCaption: "Confirma?"];
		[self addComponent: myLabelMsg];

		[self addDialogControls];
}

/**
 * Abre el formulario configurandolo adecuadamente.
 */
- (JDialogResult) showFormWithAskMode: (JDialogMode) aMode withMessage: (char *) aMessage
{
	if (aMode != JDialogMode_ASK_OK_MESSAGE &&	
			aMode != JDialogMode_ASK_YES_NO_MESSAGE &&
		  aMode != JDialogMode_ASK_YES_NO_CANCEL_MESSAGE &&
		  aMode != JDialogMode_ASK_OK_CANCEL_MESSAGE)
				THROW( UI_BAD_DIALOG_MODE_EX );
						
	myAskingMode = aMode;

	[myLabelMsg setCaption: aMessage];
	[self configDialogControls];

	[self openModalWindow];

	return myResultAnswer;
}

/**/
- (void) addDialogControls
{
	THROW( ABSTRACT_METHOD_EX );
}
 
/**/
- (void) configDialogControls
{
	THROW( ABSTRACT_METHOD_EX );
}

/**/
- (void) doCancelEvent
{
	printd("JMessageDialog:doCancelButtonClick()\n");

	if (myAskingMode != JDialogMode_ASK_YES_NO_CANCEL_MESSAGE)
		return;
		
	myResultAnswer = JDialogResult_CANCEL;
	[self closeWindow];
}

/**/
- (void) doNoEvent
{
	printd("JDialog:doNoEvent()\n");
	
	if (myAskingMode == JDialogMode_ASK_YES_NO_MESSAGE ||
			myAskingMode == JDialogMode_ASK_YES_NO_CANCEL_MESSAGE)					
			myResultAnswer = JDialogResult_NO;
	else
			myResultAnswer = JDialogResult_CANCEL;
	
	[self closeWindow];
}

/**/
- (void) doYesEvent
{
	printd("JMessageDialog:doYesEvent()\n");

	if (myAskingMode == JDialogMode_ASK_YES_NO_MESSAGE ||
			myAskingMode == JDialogMode_ASK_YES_NO_CANCEL_MESSAGE)					
			myResultAnswer = JDialogResult_YES;
	else
			myResultAnswer = JDialogResult_OK;
	
	[self closeWindow];
}

/**/
- (void) doOkEvent
{
	printd("JMessageDialog:doOkEvent()\n");
	[self doYesEvent];
}

/**
 * Metodos publicos
 */
 
/**/ 
- (JDialogResult) askOKMessage: (char *) aMessage
{	
	return [self showFormWithAskMode: JDialogMode_ASK_OK_MESSAGE withMessage: aMessage];
}
/**/ 
- (JDialogResult) askOKMessageFrom: (JWINDOW) aParentWindow withMessage: (char *) aMessage
{	
	[self setParentWindow: aParentWindow];
	return [self showFormWithAskMode: JDialogMode_ASK_OK_MESSAGE withMessage: aMessage];
}

/**/ 
- (JDialogResult) askYesNoMessage: (char *) aMessage
{
	return [self showFormWithAskMode: JDialogMode_ASK_YES_NO_MESSAGE withMessage: aMessage];
}
/**/ 
- (JDialogResult) askYesNoMessageFrom: (JWINDOW) aParentWindow withMessage: (char *) aMessage
{	
	[self setParentWindow: aParentWindow];
	return [self showFormWithAskMode: JDialogMode_ASK_YES_NO_MESSAGE withMessage: aMessage];
}

/**/ 
- (JDialogResult) askYesNoCancelMessage: (char *) aMessage
{
	return [self showFormWithAskMode: JDialogMode_ASK_YES_NO_CANCEL_MESSAGE withMessage: aMessage];
}
/**/ 
- (JDialogResult) askYesNoCancelMessageFrom: (JWINDOW) aParentWindow withMessage: (char *) aMessage
{	
	[self setParentWindow: aParentWindow];
	return [self showFormWithAskMode: JDialogMode_ASK_YES_NO_CANCEL_MESSAGE withMessage: aMessage];
}

/**/ 
- (JDialogResult) askOkCancelMessage: (char *) aMessage
{	
	return [self showFormWithAskMode: JDialogMode_ASK_OK_CANCEL_MESSAGE withMessage: aMessage];
}
/**/ 
- (JDialogResult) askOkCancelMessageFrom: (JWINDOW) aParentWindow withMessage: (char *) aMessage
{	
	[self setParentWindow: aParentWindow];
	return [self showFormWithAskMode: JDialogMode_ASK_OK_CANCEL_MESSAGE withMessage: aMessage];
}


@end

