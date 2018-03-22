#ifndef  JFORM_H
#define  JFORM_H

#define  JFORM  id

#include <objpak.h>

#include "JPrintDebug.h"
#include "JEventQueue.h"
#include "JVirtualScreen.h"
#include "JWindow.h"


/**
 * Define la funcionalidad basica de los formularios
 * Los formularios se disparan invocando a showForm() y se queda el control
 * del programa dentro de este metodo hasrta que se cierre el formulario.
 */
 
typedef enum 
{
	 JFormModalResult_NONE
	,JFormModalResult_OK
	,JFormModalResult_CANCEL
	,JFormModalResult_YES
	,JFormModalResult_NO
	
} JFormModalResult;
 

/**
 *  
 */
@interface  JForm: JWindow
{	
	JFormModalResult			myModalResult;
	BOOL									myCanCloseForm;
}


/***
 * Metodos Publicos
 */  


/**/
+ new;

/**/
- initialize;

/**/
- free;

/**
 * El metodo  utilizado para crear formularios.
 */
+ createForm: (JWINDOW) aParentWindow;
 
/**
 * Metodos hook que pueden ser usados por las subclases de JForm.
 **/
 
/**/
- (void) doCreateForm;

/**/
- (void) doDestroyForm;


/**/
- (void) doOpenForm;

/**/
- (void) doCloseForm;


/**
 *
 */
- (void) showFormWithModalMode: (BOOL) aModal;

/**
 * Abre y muestra el formulario.
 * El metodo showForm() llama al metodo onOpen() del formulario. 
 * Cuando cierra el formulario ejecuta onFormClose.
 * El formulario se abre no modal.
 * @visibility public
 */
- (void) showForm;

/**
 * @result (FormModalResult) devuelve el modal result del formulario
 * en base a las operaciones realizadas por el usuario.
 */
- (JFormModalResult) showModalForm;

/**
 * Cierra el formulario.
 * @visibility public
 */
- (void) closeForm;

/**
 * Cierra el formulario y configura el ModalResult.
 * @visibility public
 */
- (void) closeFormWithModalResult: (JFormModalResult) aModalResult;

/**
 * Configura el ModalResult del formulario
 * @visibility public
 */
- (void) setModalResult : (JFormModalResult) aModalResult;
- (JFormModalResult) getModalResult;


/***
 * Metodos Protegidos
 */


/**
 * Setear en TRUE para que al recibir el mensaje closeForm() el
 * formulario decida si cerrarse o no en base al valor pasado en canCloseform().
 * @visibility protected
 */
- (void) setCanCloseForm: (BOOL) aValue;
- (BOOL) canCloseForm;




/**
 * Los eventos de los que se pueden colgar las subclases de JForm.
 **/ 
 
 
/**
 * Se ejecuta una sola vez al crear el formulario.
 * Se crean los controles visuales del formulario.
 * Debe ser reimplementado por las subclases de Form.
 * en este metodo se deben crear los controles del formulario.
 * @visibility protected
 */
- (void) onCreateForm;

/**
 * Se ejecuta cuando se destruye el formulario
 * Los controles no deben ser liberados: el formulario los destruye automaticamente.
 * Debe ser reimplementado por las subclases de Form.
 * @visibility protected
 */
- (void) onDestroyForm;


/**
 * Se ejecuta al abrir el formulario.
 * Debe ser reimplementado por las subclases de Form.
 * En este metodo se deben configurar los controles delformulario de manera adecuada.
 * @visibility protected
 */
- (void) onOpenForm;

/**
 * Se ejecuta al ctivar una ventana.
 * @visibility protected 
 */
- (void) onActivateForm;

/**
 * Se ejecuta al desactivar una ventana
 * @visibility protected 
 */
- (void) onDeActivateForm;

/**
 *
 * Se ejecuta al cerrar el formulario.
 * Debe ser reimplementado por las subclases de Form.
 * @visibility protected
 */
- (void) onCloseForm;

/**/
- (int) getFormComponentCount;

/**/
- (JCOMPONENT) getFormComponentAt: (int) anIndex;
 
/**/
- (void) addFormComponent: (JCOMPONENT) aComponent;

/**/
- (void) addFormBlanks: (int) aQty;

/**/
- (void) addFormEol;

/**/
- (void) addFormNewPage;

/**/
- (void) focusFormComponent: (JCOMPONENT) aComponent;

/**/
- (JCOMPONENT) getFormFocusedComponent;

/**/
- (void) focusFormFirstComponent;

/**/
- (void) focusFormNextComponent;

/**/
- (void) focusFormPreviousComponent;

/**/
- (int) getFormCurrentPage;

/**/
- (void) focusFormFirstComponentInCurrentPage;



@end

#endif

