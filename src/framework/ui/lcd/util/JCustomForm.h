#ifndef  JCUSTOM_FORM_H
#define  JCUSTOM_FORM_H

#define  JCUSTOM_FORM  id

#include "JForm.h"
#include "JScrollPanel.h"
#include "JCustomStatusBar.h"
#include "JLabel.h"
#include "JCombo.h"

#define JCustomForm_MAX_MESSAGE_SIZE		JComponent_MAX_LEN - 1

/**
 * Crea un panel scrolleable y delega los mensajes que llegan al formulario a ese panel.
 * El panel establece la zona de control sobre el formulario.
 * Ademas crea tres labels para indicar las operaciones que se pueden hacer con los 
 * botones Menu1, MenuX y Menu2.
 *
 ** @todo ME GUSTARIOA HACER QUE LA APLICACION TENGA EL StatusBar
 */
@interface  JCustomForm: JForm
{
	JSCROLL_PANEL					myScrollPanel;
	
	JCUSTOM_STATUS_BAR		myStatusBar;
	
  char myBufferCustomForm[200 + 1];
	/*
	JLABEL								myLabelMenu1;
	JLABEL								myLabelMenuX;
	JLABEL								myLabelMenu2;
	*/
}



/****
 * Metodos publicos
 */

/**/
- initialize;

/**/
- free; 


/**
 * Metodos publicos
 */

/**
 * Se invoca al presionar el boton del menu correspondiente.
 * Por defecto cierra el formulario.
 */
- (void) doMenu1ButtonClick;
 
/**/
- (void) doMenuXButtonClick;

/**/
- (void) doMenu2ButtonClick;

/**/
- (void) doViewButtonClick;


/**/
- (void) onMenu1ButtonClick;

/**/
- (void) onMenuXButtonClick;

/**/
- (void) onMenu2ButtonClick;

/**/
- (void) onViewButtonClick;

/**
 * Se ejecuta cada vez que se necesita cambiar los caption del status bar 
 * segun el tipo de formulario.
 * debe ser reimplementado por las subclases.
 * En esta clase imprime vacio.
 */
- (void) doChangeStatusBarCaptions;

/**
 * Le pide al formulario el caption que debe imprimir en el caption
 * de la izquierda del StatusBar.
 * Las subclases de CustomForm pueden remiplementarlo. 
 */
- (char *) getCaption1;

/**
 * Le pide al formulario el caption que debe imprimir en el caption
 * del centro del StatusBar.
 * Las subclases de CustomForm pueden remiplementarlo. 
 */
- (char *) getCaptionX;

/**
 * Le pide al formulario el caption que debe imprimir en el caption
 * de la derechadel StatusBar.
 * Las subclases de CustomForm pueden remiplementarlo. 
 */
- (char *) getCaption2;


/**
 *	Crea el label con el texto pasado por parametro y lo agrega al formulario
 */
- (JLABEL) addLabel: (char *) aText;

/**
 *	Crea el label con el texto pasado por parametro y lo agrega al formulario
 */
- (JLABEL) addLabelFromResource: (int) aResource;

/**
 *	Crea el label con el texto pasado por parametro y lo agrega al formulario
 */
- (JLABEL) addLabelFromResource: (int) aResource default: (char *) aDefault;

/**
 *	Crea un combo con las opciones "No", "Si" y lo agrega al formulario.
 */
- (JCOMBO) createNoYesCombo;

@end

#endif

