#ifndef  JMESSAGE_DIALOG_H
#define  JMESSAGE_DIALOG_H

#define  JMESSAGE_DIALOG  id

#include "UserInterfaceExcepts.h"
#include "UserInterfaceDefs.h"
#include "JDialog.h"
#include "JLabel.h"

/**
 * Reimplementa un dialogo igual a JDialog pero las acciones las
 * maneja con los botones especificos del CT.
 *
 * <<singleton>>
 */
@interface  JMessageDialog: JDialog
{		
	JLABEL			myLabelMenu1;
	JLABEL			myLabelMenuX;
	JLABEL			myLabelMenu2;
}

/**/
- (void) doMenu1ButtonClick;

/**/
- (void) doMenuXButtonClick;


/**/
- (void) doMenu2ButtonClick;

/**
 * @param (JWINDOW) aParentWindow es la ventana padre del dialogo 
 * (en general el formulario que dispara el dialogo) se utiliza para que el dialogo le avise a 
 * su padre que no se repinte mas.
 * @param  (char *) aMessage el mensaje que mostrara eldialogo.
 */  
+ (JDialogResult) askOKMessageFrom: (JWINDOW) aParentWindow withMessage: (char *) aMessage;

/**
 * @param (JWINDOW) aParentWindow es la ventana padre del dialogo 
 * (en general el formulario que dispara el dialogo) se utiliza para que el dialogo le avise a 
 * su padre que no se repinte mas.
 * @param  (char *) aMessage el mensaje que mostrara eldialogo.
 */  
+ (JDialogResult) askYesNoMessageFrom: (JWINDOW) aParentWindow withMessage: (char *) aMessage;

/**
 * @param (JWINDOW) aParentWindow es la ventana padre del dialogo 
 * (en general el formulario que dispara el dialogo) se utiliza para que el dialogo le avise a 
 * su padre que no se repinte mas.
 * @param  (char *) aMessage el mensaje que mostrara eldialogo.
 */ 
+ (JDialogResult) askYesNoCancelMessageFrom: (JWINDOW) aParentWindow withMessage: (char *) aMessage;

/**
 * @param (JWINDOW) aParentWindow es la ventana padre del dialogo 
 * (en general el formulario que dispara el dialogo) se utiliza para que el dialogo le avise a 
 * su padre que no se repinte mas.
 * @param  (char *) aMessage el mensaje que mostrara eldialogo.
 */ 
+ (JDialogResult) askOkCancelMessageFrom: (JWINDOW) aParentWindow withMessage: (char *) aMessage;

/**
 *
 */
+ (void) showExceptionDialogFrom: (JWINDOW) aParentWindow 
				 exceptionCode: (int) anExceptionCode
				 exceptionName: (char*) anExceptionName;

@end

#endif
