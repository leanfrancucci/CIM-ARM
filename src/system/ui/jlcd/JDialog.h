#ifndef  J_DIALOG_H
#define  J_DIALOG_H

#define  JDIALOG  id

#include "UserInterfaceExcepts.h"
#include "UserInterfaceDefs.h"
#include "JWindow.h"
#include "JScrollPanel.h"
#include "JLabel.h"


typedef enum {

		 JDialogResult_NO
		,JDialogResult_YES		
		,JDialogResult_OK
		,JDialogResult_CANCEL

} JDialogResult;


typedef enum {

	 JDialogMode_ASK_OK_MESSAGE
	,JDialogMode_ASK_YES_NO_MESSAGE
	,JDialogMode_ASK_YES_NO_CANCEL_MESSAGE
	,JDialogMode_ASK_OK_CANCEL_MESSAGE
	
} JDialogMode;



/**
 * Implementa una ventana de dialogo que espera una respuesta del usuario.
 * La ventana tiene varios modos de uso en base a la configuracion de botones que
 * se presenta al usuario. 
 */
@interface  JDialog: JWindow
{
		JLABEL					myLabelMsg;

		int							myAskingMode;
		JDialogResult		myResultAnswer;
}

/**
 *
 */
+ createDialog: (JWINDOW) aParentWindow; 

/**
 * Metodos protegidos
 */

/**
 * Devuelve el tamanio de la ventana del dialogo.
 * Permite que las subclases de JDialo definan una ventana mas pequenia para
 * poder agregarrle controles por debajo del dialogo (algo es algo).
 */
- (int) getScreenDialogHeight;

/**
 * Agrega los controles adecuados.
 * Alguna subclase de JDialog agregara botones, otro agregara labels, etc.
 * En base a la configuracion del lcd y el teclado del sistema.
 */
- (void) addDialogControls;
 
/**
 * Configura los controles con el caption correspondiente en base al modo.
 */
- (void) configDialogControls;

/**
 *
 */
- (JDialogResult) showFormWithAskMode: (JDialogMode) aMode withMessage: (char *) aMessage;

/**
 * Se llama al recibir el evento correspondiente al CANCEL de los dialogos 
 * en el sistema. Cada sistema debera reimplementar el metodo en una subclase de JDialog
 * para llamar a este metodo en base al evento del usuario adecuado.
 */ 
- (void) doCancelEvent;

/**
 * Se llama al recibir el evento correspondiente al YES de los dialogos 
 * en el sistema. Cada sistema debera reimplementar el metodo en una subclase de JDialog
 * para llamar a este metodo en base al evento del usuario adecuado.
 */
- (void) doYesEvent;

/**
 * Se llama al recibir el evento correspondiente al NO de los dialogos 
 * en el sistema. Cada sistema debera reimplementar el metodo en una subclase de JDialog
 * para llamar a este metodo en base al evento del usuario adecuado.
 */
- (void) doNoEvent;

/**
 * Se llama al recibir el evento correspondiente al OK de los dialogos 
 * en el sistema. Cada sistema debera reimplementar el metodo en una subclase de JDialog
 * para llamar a este metodo en base al evento del usuario adecuado.
 */
- (void) doOkEvent;

/**
 * Metodos publicos
 */

/**
 * El dialogo muestra el mensaje @param aMessage, y se queda esperando que el 
 * usuario presione OK.  
 * @return JDialogResult_OK
 *  ---------------------------------  <br>
 *  |             message            | <br>
 *  |             message            | <br>
 *  |             message            | <br>
 *  |     					          OK     | <br>
 *  ---------------------------------  <br>
 */ 
- (JDialogResult) askOKMessage: (char *) aMessage;
- (JDialogResult) askOKMessageFrom: (JWINDOW) aParentWindow withMessage: (char *) aMessage;

/**
 * El dialogo muestra el mensaje @param aMessage, y se queda esperando una respueta 
 * afirmativa (JDialogResult_YES) o negativa (JDialogResult_NO) del usuario.
 * @return JDialogResult_YES o JDialogResult_NO
 *  ---------------------------------  <br>
 *  |             message            | <br>
 *  |             message            | <br>
 *  |             message            | <br>
 *  |    YES                     NO  | <br>
 *  ---------------------------------  <br>
 */ 
- (JDialogResult) askYesNoMessage: (char *) aMessage;
- (JDialogResult) askYesNoMessageFrom: (JWINDOW) aParentWindow withMessage: (char *) aMessage;

/**
 * El dialogo muestra el mensaje @param aMessage, y se queda esperando una respueta 
 * afirmativa (JDialogResult_YES), negativa (JDialogResult_NO) o la cancelacion de 
 * la operacion (JDialogResult_NO) por parte del usuario .
 * @return JDialogResult_YES , JDialogResult_NO o JDialogResult_CANCEL
 *  ---------------------------------  <br>
 *  |             message            | <br>
 *  |             message            | <br>
 *  |             message            | <br>
 *  |    YES        NO			  CANCEL | <br>
 *  ---------------------------------  <br>
 */ 
- (JDialogResult) askYesNoCancelMessage: (char *) aMessage;
- (JDialogResult) askYesNoCancelMessageFrom: (JWINDOW) aParentWindow withMessage: (char *) aMessage;

/**
 * El dialogo muestra el mensaje @param aMessage, y se queda esperando una respueta 
 * de aceptacion (JDialogResult_OK) o una respuesta de cancelacion (JDialogResult_CANCEL)  de 
 * por parte del usuario .
 * @return JDialogResult_OK o JDialogResult_CANCEL
 * Muestra el siguiente display:
 *  ---------------------------------  <br>
 *  |             message            | <br>
 *  |             message            | <br>
 *  |             message            | <br>
 *  |    OK                 CANCEL   | <br>
 *  ---------------------------------  <br>
 */ 
- (JDialogResult) askOkCancelMessage: (char *) aMessage;
- (JDialogResult) askOkCancelMessageFrom: (JWINDOW) aParentWindow withMessage: (char *) aMessage;

@end

#endif

