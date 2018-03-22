  #ifndef  JCOMBO_H
#define  JCOMBO_H

#define  JCOMBO  id

#include "JComponent.h"


/**
 * Implementa un combo visual de items.
 * El combo maneja una lista de objetos y mantiene uno seleccionado.
 * Utiliza el metodo str() de todos los Object para imprimir el item
 * actual seleccionado.
 *
 * (Por ahora no me parece hacer que JGrid, JList y JCombo 
 * pertenezcan a la misma jerarquia de herencia) 
 *
 */
@interface  JCombo: JComponent
{
	 id  				myItems;
	 int   			myItemIndex;
	 BOOL				myOwnObjects;

	 char				myText[JComponent_MAX_LEN + 1];
}


/**
 * Configura el combo para que libere los items que mantiene en la coleccion
 * interna al ser liberado.
 * Si @param ownObjects es TRUE entonces el combo libera los items contenidos,
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
 * Limpia los items de la coleccion interna del combo.
 * Libera los objetos segun tenga configurado ownObjects.
 */ 
- (void) clearItems;

/**
 * Libera la totalidad de los items de la coleccion.
 */
- (void) clearAllItems; 

/**
 * Agrega todos los objetos de la coleccion.
 */ 
- (void) addItemsFromCollection: (COLLECTION) aCollection;
 
/**
 * Agrega un objeto al combo
 */ 
- (void) addItem: (id) anObject; 

/**
 * Agrega un string al combo.
 * Internamente crea un objeto String para agregarlo a la lista de items.
 */ 
- (void) addString: (char *) aString;

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
 * Devuelve la coleccion de items del combo.
 */
- (COLLECTION) getItems; 
 
  


@end

#endif

