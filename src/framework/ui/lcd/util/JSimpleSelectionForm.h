#ifndef  JSIMPLE_SELECTION_FORM_H
#define  JSIMPLE_SELECTION_FORM_H

#define  JSIMPLE_SELECTION_FORM id

#include "JListForm.h"


/**
 *
 */
@interface  JSimpleSelectionForm: JCustomForm
{
	JGRID	myObjectsList;
	COLLECTION myCollection;
	char myTitle[41];
	JLABEL myLabelTitle;
	int myAutoRefreshTime;
	OTIMER myUpdateTimer;
	BOOL myIsClosingForm;
	BOOL myShowItemNumber;
	id mySelectedItem;
}

/**/
- (void) setShowItemNumber: (BOOL) aValue;

/**/
- (void) setTitle: (char *) aTitle;

/**/
- (void) setCollection: (COLLECTION) aCollection;

/**/
- (void) setInitialSelectedItem: (id) anItem;

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

/**/
- (void) setAutoRefreshTime: (unsigned long) aValue;


@end

#endif

