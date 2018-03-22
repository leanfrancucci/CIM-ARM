#ifndef  JWINDOW_H
#define  JWINDOW_H

#define  JWINDOW id

#include <objpak.h>
 
#include "JPrintDebug.h"
#include "JContainer.h"
#include "JVirtualScreen.h"

/**
 * Define la funcionalidad basica de las ventanas.
 * Gestiona los eventos de entrada del usuario.
 */

/**
 *  
 */
@interface  JWindow: JContainer
{	
	JWINDOW							myParentWindow;
	
	BOOL								myModalMode;
	BOOL 								myCanClose;
	
	BOOL								myIamClosing;

	id 									myOnCloseWindowHandler;
}

/**/
- (void) setOnCloseWindowHandler: (id) anObject;
- (id) getOnCloseWindowHandler;

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
 * Este es el metodo a utilizar al crear ventanas.
 * @param (JWINDOW) aParentWindow configura el padre de la ventana. Si el padre es
 * valido entonces cuando se abre la ventana desactiva  al padre, y si la ventana 
 * es modal  cuando se cierra vuelve a activar al padre.
 * El padre puede ser NULL en cuyo caso no se activa ni desactiva.
 */
+ createWindow: (JWINDOW) aParentWindow;

/**
 *
 */
- (void) setParentWindow: (JWINDOW) aParentWindow;
- (JWINDOW) getParentWindow;


/**
 * Si canClose se configura en TRUE es posible cerrar la ventana.
 * Si se configura en FALSE la ventana no puede ser cerrada por mas que se
 * llame a closeWindow().
 */
- (void) setCanClose: (BOOL) aValue;
- (BOOL) canClose;


/** 
 * @visibility public
 */
- (void) openWindow;

/**
 * @visibility public
 */
- (void) openModalWindow;

/**
 * @visibility public
 */
- (void) openWindowWithModalMode: (BOOL) aModal;

/**
 * Cierra la ventana.
 * @visibility public
 */
- (void) closeWindow;


/**
 * Procesa el mensaje. 
 * Es llamado por  doProcessMessages() y por processApplicationMessages()
 * Devuelve FALSE si recibe un mensaje CLOSE y TRUE en caso contrario.
 */
- (BOOL) doProcessMessage: (JEvent *) anEvent;
 
/* Procesa los eventos  recibidos por la ventana.
 * Extrae cada evento de la cola de eventos de la ventana y los
 * procesa de manera adecuada.
 * Se queda clavado esperando mensajes hasta recibir un mensaje CLOSE.
 * @visibility private
 */
- (void) doProcessMessages;

/**
 * El formulario recibe una tecla presionada mediante este mensaje.
 * Es ejecutado por processWindowMessages().
 * @param aKey (int) la tecla presionada y recibida por el form
 * @param isPressed (int) TRUE si la tecla se presiono (OnPressed) y FALSE si
 * la tecla se solto (OnReleased).
 * Devuelve TRUE si es que la tecla fue procesada y FALSE si la tecla no
 * fue usada.
 * La tecla se recibe en la sub sub clase de Window y esta la va enviando hacia
 * arriba a las superclases si es que no la necesita procesar. Cuando llega, si
 * es que llega a JWindow, se la envia al control con el foco actual, y si el control
 * no la necesita procesar la procesa la ventana en JWindow.
 * @visibility private
 */
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) anIsPressed;

/**
 * Se ejecuta al abrir la ventana.
 * @visibility private
 */
- (void) doOpenWindow;


 /**
 * Se ejecuta al cerrar la ventana.
 * @visibility private
 */
- (void) doCloseWindow;

/**
 * Se ejecuta al crear la ventana.
 * @visibility private
 */
- (void) doCreateWindow;

/**
 * Se ejecuta al destruir la ventana.
 * @visibility private
 */
- (void) doDestroyWindow;


/***
 * Metodos Protegidos
 */

/**
 * Se ejecuta una sola vez al crear la ventana.
 * Se crean los controles visuales dla ventana.
 * Debe ser reimplementado por las subclases de Window.
 * en este metodo se deben crear los controles dla ventana.
 * @visibility protected
 */
- (void) onCreateWindow;

/**
 * Se ejecuta cuando se destruye la ventana
 * Los controles no deben ser liberados: la ventana los destruye automaticamente.
 * Debe ser reimplementado por las subclases de Window.
 * @visibility protected
 */
- (void) onDestroyWindow;


/**
 * Se ejecuta al abrir la ventana.
 * Debe ser reimplementado por las subclases de Window.
 * En este metodo se deben configurar los controles delformulario de manera adecuada.
 * No se tiene acceso al pintado de la pantalla en este metodo, el acceso se obtiene
 * recien en el onActivateWindow().
 * @visibility protected
 */
- (void) onOpenWindow;

/**
 *
 * Se ejecuta al cerrar la ventana.
 * Debe ser reimplementado por las subclases de Window.
 * @visibility protected
 */
- (void) onCloseWindow;

/**
 * Metodo abstracto que debe ser reimplementado por JDialog y por JForm para
 * mostrar una excepcion de manera adecuada.
 */
- (void) showDefaultExceptionDialogWithExCode: (int) anExceptionCode;

/**
 * Invoca al metodo showDefaultExceptionDialogWithExCode() con el codigo de
 * excepcion que actualmente se disparo.
 * Puede ser directamente utilizado y no debe ser reimplementado.
 */
- (void) showDefaultExceptionDialog;

/**
 * Debe ser invocado cuando se necesita que se repinte la ventana.
 * Por ejemplo cuando se esta n un proceso batch y se quiere actualizar un
 * JProgressBar l metodo debe ser invocada dentro del proceso periodicamente.
 * Se queda clavado hasta que no hayan mas mensjaes en la cola.
 */
- (void) processApplicationMessages;

/**
 * Bloquea la actualizacon de la pantalla.
 * Se utiliza cuando se estan realizando operaciones intensivas sobre los 
 * componentes  dentro de una ventana.
 * Agregarlo dentro de un bloque try/finally.
 */
- (void) lockWindowsUpdate;

/**
 * Desbloquea la actualizacon de la pantalla y envia un mensaje para pintar todo.
 */
- (void) unlockWindowsUpdate;

/**
 * Hace que la ventana se pinte.
 * No repinta la ventana.
 */
- (void) activateWindow;

/**
 * La ventana deja de pintarse
 */
- (void) deactivateWindow;


/**
 * Se ejecuta al activar una ventana.
 * Ejecuta el onFocus() de la ventana
 * Envia un evento paint para que se repinte la ventana. 
 */
- (void) onActivateWindow;

/**
 * Se ejecuta al desactivar una ventana
 * Ejecuta el onBlur() de la ventana
 */
- (void) onDeactivateWindow;

/**
 * Devuelve TRUE si la ventana esta activada, y FALSE en caso contrario.
 */
- (BOOL) isActiveWindow;


/**/
+ (JWINDOW) getActiveWindow;

@end

#endif

