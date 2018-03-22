#ifndef  JCHECK_BOX_LIST_H
#define  JCHECK_BOX_LIST_H

#define  JCHECK_BOX_LIST  id

#include "JComponent.h"
#include "JCheckBox.h"

/**
 *
 */
 
typedef enum 
{
	JCheckBoxList_VIEW,
  JCheckBoxList_EDIT,
} JCheckBoxListMode;
 
 
 
@interface  JCheckBoxList: JComponent
{
	id  				myCheckBoxCollection;
	int   			myItemIndex;
	BOOL				myOwnObjects;  

	int 				myVisibleOnTopItem;
	int 				myVisibleOnBottomItem;

	char				myText[JComponent_MAX_LEN + 1];
  JCheckBoxListMode         myCheckBoxListMode;
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
 * Configura y obtiene el indice actualmente seleccionado en la lista.
 * Los items comienzan en cero y van hasta la cantidad de elementos de
 * la lista - 1.
 * Si la lista esta vacia getSelectedCheckBoxIndex() devuelve -1.
 * Si el indice en  setSelectedCheckBoxIndex() esta fuera de rango lnza la
 * excepcion UI_INDEX_OUT_OF_RANGE_EX
 */
- (void) setSelectedCheckBoxIndex: (int) anIndex;
- (int) getSelectedCheckBoxIndex;

/**
 * Configura y obtiene la instancia de check box actualmente seleccionada en la lista.
 * Si la instancia en setSelectedCheckBoxItem() no se encuentra lanza la
 * excepcion UI_INDEX_OUT_OF_RANGE_EX
 */
- (void) setSelectedCheckBoxItem: (id) anObject;
- (id) getSelectedCheckBoxItem;

/**
 * Limpia los items de la coleccion interna de la lista.
 * Libera los objetos segun tenga configurado ownObjects.
 */
- (void) clearItems;

/**
 * Agrega todos los objetos de la coleccion.
 */
- (void) addCheckBoxFromCollection: (COLLECTION) aCollection;

/**
 * Agrega un objeto a la lista
 */
- (void) addCheckBoxItem: (id) anObject;

/**
 * Elimina el check box de la coleccion y actualiza el pintado del control.
 * @thorws UI_INDEX_OUT_OF_RANGE_EX;
 */
- (void) removeCheckBoxIndex: (int) anIndex;

/**
 * Elimina el check box de la coleccion y actualiza el pintado del control.
 * @thorws UI_INDEX_OUT_OF_RANGE_EX; 
 */
- (void) removeCheckBoxItem: (id) anObject;

/**
 * Retorna los items
 */
- (COLLECTION) getCheckBoxItemsCollection; 

/**
 *
 */
- (BOOL) hasAnyElementChecked; 
 
 
@end

#endif

