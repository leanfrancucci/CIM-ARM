#ifndef  JAPPLICATION_H__
#define  JAPPLICATION_H__

#define  JAPPLICATION  id

#include "JWindow.h"
#include "JForm.h"
#include "JDialog.h"

#include "InputKeyboardManager.h"

/**
 * gestiona la aplicacion manteniendo una lista de ventanas con una de ellas activa.
 * Cuando se libera la aplicacion se liberan todas las ventanas agregadas.
 */
 

/**
 *  
 */
@interface  JApplication: JWindow
{	
	id												myFormsList;
	
	JFORM											myPreviousActiveForm;
	JFORM											myActiveForm;	
	JFORM											myMainApplicationForm;
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
 *
 */
- (void) startApplication;

/**
 *
 */
- (void) stopApplication;


/**
 * Agrega un nuevo formulario a la lista de formularios hojas de la aplicacion. 
 */
- (void) addApplicationForm: (JFORM) aForm;

/**
 * Devuelve el formulario activo.
 */
- (JFORM) getActiveApplicationForm;


/**
 * configura el formulario proincipal de la aplicacion
 */
- (void) setMainApplicationForm: (JFORM) aForm;
- (JFORM) getMainApplicationForm;

/**
 * Activa el formulario principal de la aplicacion.
 */
- (void) activateMainApplicationForm;

/**
 * Hace que aForm sea el formulario activa de la aplicacion que reciba los mensajes.
 * Cuando una formulario se abre le dice a su Owner (si tiene) que se abrio invocando 
 * este metodo.
 * Esto se hace para que los eventos rcibidos por esta formulario sean despachados a la formulario activa.
 */
- (void) activateApplicationForm: (JFORM) aForm;

/**
 *
 */
- (void) deactivateApplicationForm: (JFORM) aForm;

/**
 * Activa el siguiente formulario en la lista de formularios de la aplicacion.
 */
- (void) activateNextApplicationForm;

/**
 * se ejecuta al comenzar la aplicacion antes de disparar el primer formulario.
 */
- (void) onStartApplication;

/**
 * Se ejecuta al salir y detener la aplicacion
 */
- (void) onStopApplication;

/**
 * Cuando activa la siguiente ventana
 */
- (void) onActivateApplicationForm: (JFORM) anActiveForm previousActiveForm: (JFORM) aPreviousForm;

/**
 * se ejecuta al activar la ventan principal de la aplicacion.
 */
- (void) onActivateMainApplicationForm: aMainForm previousActiveForm: aPreviousForm;

/**
 * Activa la vista actual.
 */
- (void) activateCurrentView;

/** 
 * Desactiva la vista actual.
 */
- (void) deactivateCurrentView; 


@end

#endif

