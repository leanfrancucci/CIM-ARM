#ifndef  JEXCEPTION_FORM_H
#define  JEXCEPTION_FORM_H

#define  JEXCEPTION_FORM id

#include "JCustomForm.h"

#include "JLabel.h"
#include "JButton.h"
#include "JProgressBar.h"
#include "JDialog.h"

/**
 *
 */
@interface  JExceptionForm: JForm
{
	JLABEL			myLabelMenu1;
	JLABEL			myLabelMenu2;
	JLABEL			myLabelMenuX;
	JLABEL			labelMessage;
	char				keyPressed;
	int					myMode;
	JWINDOW			myOldForm;
}

/**
 *
 */
+ (JDialogResult) showException: (int) anExceptionCode 
									exceptionName: (char *) anExceptionName;

/**
 *
 */									
+ (JDialogResult) showYesNoForm: (char *) aMessage;

/**
 *
 */
+ (JDialogResult) showOkForm: (char *) aMessage; 


+ (JFORM) showProcessForm: (char *) aMessage;
- (void) closeProcessForm;

@end

#endif

