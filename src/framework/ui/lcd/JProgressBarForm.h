#ifndef  JPROGRESS_BAR_FORM_H
#define  JPROGRESS_BAR_FORM_H

#define  JPROGRESS_BAR_FORM  id

#include "JCustomForm.h"

#include "JLabel.h"
#include "JButton.h"
#include "JProgressBar.h"

/**
 *
 */
@interface  JProgressBarForm: JCustomForm
{
	JPROGRESS_BAR	progressBar;
	JLABEL			myLabelTitle;
	JLABEL			labelMessage;
	JLABEL			labelMessage2;
	int currentProgress;
	id object;
	char *callBack;
	BOOL myAdvanceOnTimer;
}

/**
 *	Setea la funcion de callback que debe llamar cuando se muestra el formulario.
 * 	@param object el objeto al cual se debe llamar.
 *	@param callBack el nombre de la funcion de callback (no debe tener parametros).
 */
- (void) setCallBack: (id) anObject callBack: (char*) aCallBack;

/**
 *	Avanza el progreso de la operacion.
 */
- (void) advance;

/**
 *	Avanza el progreso de la operacion a un determinado valor.
 */
- (void) advanceTo: (int) aProgress;

/**
 *	Setea el caption del formulario.
 */
- (void) setCaption: (char*) aCaption;

/**
 *	Setea el caption 2 del formulario.
 */
- (void) setCaption2: (char*) aCaption;

/**/
- (void) setTitle: (char *) aTitle;

/**
 *
 */
- (void) setAdvanceOnTimer: (BOOL) aValue;

@end

#endif

