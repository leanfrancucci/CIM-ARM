#ifndef  JEDIT_FORM_H
#define  JEDIT_FORM_H

#define  JEDIT_FORM  id

#include "JCustomForm.h"
#include "JLabel.h"
#include "JCombo.h"

typedef enum
{
	 JEditFormMode_VIEW
	,JEditFormMode_EDIT

} JEditFormMode;


/**
 * Formulario base para visualizar y editar entidades individuales.
 * El formulario inicialmente se dispara con shorForm() y se muestra en
 * modo visualizacion.
 * En el modo VIEW si se presiona la tecla aceptar antonces se pasa el
 * modo a EDIT; si se presiona cancelar se cierra el formulario.
 * En el modo EDIT si se presiona aceptar se llama al metodo onAccept() y
 * se cierra el formulario; si se presiona cancelar se cierra el formulario
 * llamando al metodo onCancel().
 *
 * El formulario se puede abrir directamente en modo edicion para dar de
 * alta entiddes. Si se cancela habiendolo abierto directamente en modo EDIT entonces
 * el formulario se cierra.
 **/
@interface  JEditForm: JCustomForm
{
	JEditFormMode  		myFormMode;			// El estado actual del form
	BOOL							myEditFocusInFirstControlMode;

	BOOL							myCloseOnCancel;
	BOOL							myCloseOnAccept;
	
	BOOL							myIsEditable;
	
	BOOL							myConfirmAcceptOperation;
	char							myConfirmAcceptMessage[JCustomForm_MAX_MESSAGE_SIZE + 1];

	/* La instancia que se esta visualizando/editando */
	id								myInstance;	
}



/****
 * Metodos publicos
 */

/**/
- initialize;

/**/
- free;


/**
 * 	Indica si debe cerrar o no el form al aceptar 
 */
- (void) setCloseOnAccept: (BOOL) aValue;
- (BOOL) getCloseOnAccept;

/**
 *	Indica si debe cerrar o no el form al cancelar en estado edicion original 
 * en el que fue abierto el form
 */
- (void) setCloseOnCancel: (BOOL) aValue;
- (BOOL) getCloseOnCancel;


/**
 * Configura el formulario para que sea de solo visualizacion o
 * edicion y visualizacion.
 */
- (void) setEditable: (BOOL) aValue;
- (BOOL) isEditable;

/**
 * Si se configura en TRUE el formulario cuando se pone en edicion pone el foco en
 * el primer control de la pagina actual.
 * Si se pone en FALSE va al primer control de la primer pagina del formulario.
 * Por defecto esta en TRUE.
 */
- (void) setEditFocusInFirstControlMode: (BOOL) aValue;
- (BOOL) isEditFocusInFirstControlMode;

/**
 * devuelve el modo actual del formulario
 */
- (JEditFormMode) getFormMode;

/**
 * Abre y muestra el formulario en modo visualizacion directamente.
 * El formulario se abre modal.
 * @param (id) anInstance la instancia que se quiere visualizar.
 * @visibility public
 */
- (JFormModalResult) showFormToView: (id) anInstance;

/**
 * Abre y muestra el formulario en modo edicion directamente.
 * El formulario se abre modal.
 * @param (id) anInstance la instancia que se quiere editar.
 * @visibility public
 */
- (JFormModalResult) showFormToEdit: (id) anInstance;

/**
 * Configura la instancia que se esta visualizano/editando
 */
- (void) setFormInstance: (id) anInstance;

/**
 * Devuelve la instancia pasada en showFormToView() o showFormToEdit() y que
 * se esta visualizando/editando.
 * Lo deben utilizar las subclases para conocer la instancia que estan gestionando. 
 */
- (id) getFormInstance; 
 
/****
 * Metodos privados
 */

/**/
- (void) validateFormControls;

/**
 * Se ejecuta cuando el formulario cambia de modo visualizacion / edicion
 * @visibility private
 */
- (void) doChangeFormMode: (JEditFormMode) aNewMode;


/******
 * Metodos protegidos
 */

/**
 * Se ejecuta al aceptar el formulario.
 * @visibility private
 */
- (BOOL) doAcceptForm;

/**
 * Se ejecuta al cancelar el formulario.
 * @visibility private
 */
- (void) doCancelForm;

/**
 * Se ejecuta al abrir el formulario
 * @visibility private
 */
- (void) doModelToView;

/**
 * Se ejecuta al aceptar el formulario
 * @visibility private
 */
- (void) doViewToModel;


/**
 * Los eventos
 **/

/**
 * Metodo hook que puede ser reimplementado por las subclases.
 * @visibility protected
 */
- (void) onChangeFormMode: (JEditFormMode) aNewMode;

/**
 * Configura el formulario para que, antes de aceptar, le pregunte al usuario
 * si quiere o no hacerlo.
 */
- (void) setConfirmAcceptOperation: (BOOL) aValue;
- (BOOL) getConfirmAcceptOperation;

/**
 * Le pide a la subclase de JEditForm el mensaje adecuado para mostrar en el dialogo 
 * de confirmacion de aceptacion del formulario.
 */
- (char *) getConfirmAcceptMessage: (char *) aMessage toSave: (id) anInstance;

/**
 * Se ejecuta al aceptar el formulario.
 * Aqui deberian grabarse los datos del formulario.
 * Tambien se deben validar los datos antes de guardarlos lanzando
 * excepciones en caso de validaciones negativas.
 * Las excepciones muetran el mensaje de error correspondiente
 * con un formulario de mensajes especial.
 * Si no se quiere lanzar una excepcion para que no muestre el cartel de error
 * pero no se quiere cerrar el formulario, entonces no se debe lanzar una excepcion
 * pero si debe llamarse al metodo setCanCloseForm(value) con value = FALSE  para
 * instruir al formulario para que no se cierre y permita reingresar los valores en
 * los controles sin que muestre el cartel de error tipico de las excepciones.
 * @param (id) anInstance es la instancia que se quiere almacenar.
 * @visibility protected
 */
- (void) onAcceptForm: (id) anInstance;

/**
 * Se ejecuta al cancelar el formulario.
 * Metodo hook que puede ser reimplementado por las subclases. 
 * @visibility protected
 */
- (void) onCancelForm: (id) anInstance;

/**
 * Debe ser reimplementado por las subclases para asignar el estado de la entidad
 * que se esta visualizando o editando a los controles del formulario.
 * @visibility protected
 */
- (void) onModelToView: (id) anInstance;

/**
 * Debe ser reimplementao por las subclases para asignar el estado de los controles
 * al estado de la entidad que se esta visualizando o modificando.
 * @visibility protected
 */
- (void) onViewToModel: (id) anInstance;

/**
 * Acepta el formulario para que se graben los datos ingreados.
 * Llama a onModelToView() antes de aceptar los datos
 * Cierra el formulario
 * @visibility public
 */
- (void) acceptForm;

/**
 * Cancela el formulario llamando a doAccept()
 * Cierra el formulario
 * @visibility public
 */
- (void) cancelForm;

/**
 * Posiciona el foco en el primer componente en base a EditFocusInFirstControlMode
 */
- (void) focusInFirstEditComponent;

@end

#endif

