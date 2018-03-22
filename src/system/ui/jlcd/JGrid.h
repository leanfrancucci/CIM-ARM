#ifndef  JGRID_H
#define  JGRID_H

#define  JGRID  id

#include "JComponent.h"
#include "Collection.h"

/**
 * Implementa una grilla de items visual.
 * La lista maneja una lista de objetos y mantiene uno seleccionado.
 * Utiliza el metodo str() de todos los Object para imprimir el item
 * actual seleccionado.
 *
 * Por ahora es similar a JGrid excepto por las teclas de navegacion de items y
 * por la visualizacion de los items y del item seleccionado.
 * 
 *
 * (Por ahora no me parece hacer que JGrid, JList y JCombo 
 * pertenezcan a la misma jerarquia de herencia) 
 *
 */
@interface  JGrid: JComponent
{
	id  				myItems;
  COLLECTION  myStringItems;
	int   			myItemIndex;
	BOOL				myOwnObjects;
  BOOL        myPaintObjectString;

	int 				myVisibleOnTopItem;
	int 				myVisibleOnBottomItem;

	char				myText[JComponent_MAX_LEN + 1];
	BOOL				myShowItemNumber;

	unsigned long myLastKeyPressedTime;
	int myIndexPressed;
}
		
/**
 * Configura la lista para que libere los items que mantiene en la coleccion
 * interna al ser liberado.
 * Si @param ownObjects es TRUE entonces la lista libera los items contenidos,
 * en cambio, si @param ownObjects es FALSE no libera los objetos contenidos (solo
 * libera la coleccion que los mantiene).
 */
- (void) setOwnObjects: (BOOL) anOwnObjects;
- (BOOL) getOwnObjects;

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
 * Limpia los items de la coleccion interna de la lista.
 * Libera los objetos segun tenga configurado ownObjects.
 */
- (void) clearItems;

/**
 * Agrega todos los objetos de la coleccion.
 */
- (void) addItemsFromCollection: (COLLECTION) aCollection;

/**
 * Agrega un objeto a la lista
 */
- (void) addItem: (id) anObject;

/**
 * Agrega un string a la lista.
 * Internamente crea un objeto String para agregarlo a la lista de items.
 */
- (void) addString: (char *) aString;
- (void) setString: (char *) aString index: (int) anIndex;

/**
 * Elimina el item de la coleccion y actualiza el pintado del control.
 * @thorws UI_INDEX_OUT_OF_RANGE_EX;
 */
- (void) removeIndex: (int) anIndex;

/**
 * Elimina el item de la coleccion y actualiza el pintado del control.
 * @thorws UI_INDEX_OUT_OF_RANGE_EX; 
 */
- (void) removeItem: (id) anObject;

/**
 * Retorna los items
 */
- (COLLECTION) getItemsCollection; 
 
/**
 *
 */
- (void) setItemIndex: (int) aValue;

/**
 *
 */
- (void) addStringItem: (char*) aStringItem; 

/**
 *
 */
- (void) setPaintObjectString: (BOOL) aValue; 

/**
 *
 */
- (void) removeStringItems; 

/**
 *
 */
- (void) setShowItemNumber: (BOOL) aValue;

@end

#endif

