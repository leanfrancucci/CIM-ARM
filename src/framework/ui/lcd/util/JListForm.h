#ifndef  JLIST_FORM_H
#define  JLIST_FORM_H

#define  JLIST_FORM  id

#include "JCustomForm.h"
#include "JLabel.h"
#include "JText.h"
#include "JGrid.h"


/**
 * Implementa un formulario con una lista y operaciones para dar de alta, baja, modificar y 
 * visualizar instancias.
 *
 * Debe redefinirse el metodo hook onConfigureForm() en  las subclases para configurar 
 * el formulario adecuadamente y tambien en ese metodo deben agregarse los items a la 
 * lista de instancias.
 * Los items pueden agregarse de a uno o puede agregar toda un acoleccion de items.  
 * El formulario solo mantiene una referenci a los items recibidos.
 * no los destruye, solo destruye elprimer item si es que el formulario
 * pemite agregar nuevas instancias.
 * 
 **/
@interface  JListForm: JCustomForm
{
	JGRID			myObjectsList;
	JLABEL		myLabelTitle;
	BOOL			myAllowNewInstances;

	BOOL			myAllowDeleteInstances;
	BOOL			myConfirmDeleteInstances;

	id 				myNewInstancesItemCaption;
	BOOL 			myReturnToFirstItem;

	char			myDeleteMessage[JCustomForm_MAX_MESSAGE_SIZE + 1];	
	char 			myTitle[21];
}



/****
 * Metodos publicos
 */

/**/
- initialize;

/**/
- free;

/**/
- (void) doSelectInstance;

/**/
- (void) doDeleteInstance;

/**/
- (void) setTitle: (char *) aTitle;

/**
 * Metodos protegidos
 */

/**
 * Metodo hook invocado en el open() del form y que permite configurarlo d manera
 * adecuada. Aqui debe indicarse si permite agregar o eliminar instancias, el mensaje
 * del primer item, etc.
 */
- (void) onConfigureForm;
 
/**
 * Configura el formulario para que pueda agregar o no nuevas instancias.
 * Si permite nuevas instancias entonces agrega un primer item ficticio en la lista
 * que se presiona para agregar una nueva instancia invocandose el metodo onNewInstance().
 */
- (void) setAllowNewInstances: (BOOL) aValue;
- (BOOL) getAllowNewInstances;

/**
 * Configura el mensaje del primer item de la lista que sirve para agregar nuevas instancias. 
 */
- (void) setNewInstancesItemCaption: (char *) aString;

/**
 * Configura el formulario para que, antes de eliminar una inatancia, le pregunte al usuario
 * si quiere o no eliminarla.
 */
- (void) setConfirmDeleteInstances: (BOOL) aValue;
- (BOOL) getConfirmDeleteInstances;


/**
 * Configura el formulario para que pueda eliminar o no instancias.
 */
- (void) setAllowDeleteInstances: (BOOL) aValue;
- (BOOL) getAllowDeleteInstances;

/**
 * Devuelve TRUE si es que puede agregar una entidad en base al item actulmente
 * seleccionado en el listado.
 * Devuelve FALSE en caso contrario.
 */
- (BOOL) canInsertNewInstanceOnSelection;

/**
 * Devuelve TRUE si es que puede eliminar la entidad seleccionada actualmente en el listado.
 * Devuelve FALSE en caso contrario.
 */
- (BOOL) canDeleteInstanceOnSelection;

/**
 * Le pide a la subclase de JListForm el mensaje adecuado para mostrar en el dialogo 
 * de confirmacion de eliminacion de instancias.
 * El metodo se llama justo antes de dispara el dialogo y permite que el formulario pueda
 * armar el mensaje en base a la instancia que se quiere eliminar.
 */
- (char *) getDeleteInstanceMessage: (char *) aMessage toSave: (id) anInstance; 

/**
 * Configura y obtienel indice actualmente seleccionado en la lista.
 * Los items comienzan en cero y van hasta la cantidad de elementos de
 * la lista - 1.
 * Si la lista esta vacia getSelectedItemIndex() devuelve -1.
 * Si el indice en  setSelectedItemIndex() esta fuera de rango lnza la
 * excepcion UI_INDEX_OUT_OF_RANGE_EX
 */
- (void) setSelectedIndex: (int) anIndex;
- (int) getSelectedIndex;

/**
 * Configura y obtiene l instancia actualmente seleccionada en la lista.
 * Si la instancia en setSelectedItem() no se encuentra lanza la
 * excepcion UI_INDEX_OUT_OF_RANGE_EX
 */
- (void) setSelectedItem: (id) anObject;
- (id) getSelectedItem;

/**
 * Agrega un item a la lista del formulario
 */
- (void) addItem: (id) anItem;

/**
 * Agrega todos los items de la coleccion @param aCollection a la lista del formulario.
 */
- (void) addItemsFromCollection: (id) aCollection;

/**
 * Elimina el item de la coleccion y actualiza el pintado del control.
 * @thorws UI_INDEX_OUT_OF_RANGE_EX; 
 */
- (void) removeItem: (id) anItem;

/**
 * Elimina el item de la coleccion y actualiza el pintado del control.
 * @thorws UI_INDEX_OUT_OF_RANGE_EX;
 */
- (void) removeIndex: (int) anIndex;

/**
 * Limpia los items de la coleccion interna de la lista.
 * Libera los objetos segun tenga configurado ownObjects.
 */
- (void) clearItems;

/**
 * Metodo hook invocado al presionar el boton correspondiente para agregar una entidad 
 * Es el mismo que para visualizar una entidad pero seleccionando el primer item (hoy es menu2Button).
 * Debe reimplementarse el metodo para disparar el formulario para agregar instancias y luego de aceptada
 * debe ser agregada a la lista del form mediante el metodo addItem().
 * @result (id) retorna la nueva instancia agregada por las subclases de JListForm.
 */
- (id) onNewInstance;

/**
 * Metodo hook invocado al presionar el boton correspondiente a editar la entidad 
 * seleccionada en el listado o o dar de alta una nueva (hoy es menu2Button).
 * @param (id) anObject es la instancia que se selecciono para visualizar y editar.
 */
- (void) onSelectInstance: (id) anInstance;

/**
 * Metodo hook invocado al presionar el boton correspondiente al delete de la entidad seleccionada.
 * (hoy es el boton menuXButton).
 * @param (id) anObject es la instancia que se selecciono para eliminar.
 */
- (void) onDeleteInstance: (id) anInstance;

/**
 * Metodo que retorna TRUE si la lista de items contiene algun item, de lo contrario retorna FALSE. 
 */
- (BOOL) listHasItems;

/**
 *
 */
- (COLLECTION) getItemsCollection; 

/**
 *
 */
- (int) getItemsQty;

/**
 *
 */
- (void) addStringItem: (char*) aStringItem; 
- (void) setPaintObjectString: (BOOL) aValue; 
- (void) clearStringItems;

/**
 *	Configura que debe retornar al primer item cuando vuelve de una pantalla.
 */
- (void) setReturnToFirstItem: (BOOL) aValue;

/**
 *
 */
- (void) addNewItem;

/**
 *
 */
- (void) editItem;

@end

#endif

