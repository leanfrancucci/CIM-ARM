#ifndef  JCONTAINER_H
#define  JCONTAINER_H

#define  JCONTAINER  id

#include "JComponent.h"
#include "JGraphicContext.h"

/**
 * Implementa un contenedor de JComponent.
 * Cada container tiene su propio JGraphicContext
 *
 * Implementa scroll entre los componentes que pueden hacer foco.
 * Implementa una politica de paginas para hacer scroll entre componentes. Una 
 * pagina tiene el tamanio del 'height' contenedor. Si se esta en el ultimo componente de
 * una pagina y se presiona TAB entonces debe irse al siguiente componente que puede 
 * hacer foco. Si este componente esta en la pagina siguiente entonces se scrollea
 * a la siguiente pagina.
 * La pagina origen es la 1 y no hay limite de paginas.
 *
 * Es un <<Composite>>.
 *
 * Recibe mensajes como un JComponent normal pero los procesa para enviarselos
 * al JComponent que tenga el foco actual.
 *
 */
 
/** @todo Falta manejar el tema del scroll por x agregando myCurrentXPosition 
 *(pero no es necesario por ahora) 
 */
 
/** @todo  Hay que hacer que los metodos focusFirstComponent(), focusNextcomponent(),
 * focusComponent() etc. sean recursivos para poder hacer agregaciones de paneles.
 * Por ahora no se usa y lo voy a dejar asi, entonces.
 */ 
 
 
 
@interface  JContainer: JComponent
{
		id										myComponents;			
		JCOMPONENT						myFocusedComponent;	
		
		/* Mantiene la posicion en Y de la pagina actual que se esta mostrando en el contexto grafico */
		int 									myCurrentYPosition;
				
		/* Maneja la posicion del ultimo componente agregado */
		int 									myCurrentLayoutXPosition;
		int 									myCurrentLayoutYPosition;
};


/****
 * Metodos publicos
 */

/**/
- initialize;

/**/
- free;


/**
 * Metodos protegidos
 */

/**
 * Limpia la zona de pintado del contenedor.
 *
 * @visibility protected
 */
/**/
- (void) clearContainerScreen;

/**
* Metodos publicos
*/

/**
 * Devuelve la cantidad de componentes del contenedor.
 */
- (int) getComponentCount;

/**
 * Devuelve el componente en la posiciojn anIndex del contenedor
 */
- (JCOMPONENT) getComponentAt: (int) anIndex;

/**
 * Agrega un componente al contenedor
 */
- (void) addComponent: (JCOMPONENT) aComponent;

	
/**
 * Agrega espacios en blanco al contenedor
 */
- (void) addBlanks: (int) aQty;

/**
 * Agrega espacio en blanco hasta el final de la linea actual del componente.
 * El proximo componente agregado se ubica en la siguiente linea.
 */
- (void) addEol;

/**
 * Agrega las lineas necesarias como para que el proximo componente agregado sea
 * ubicado en la siguiente pagina.
 * Si esta ubicado en la posicion origen de una pagina no hace nada.
 */
- (void) addNewPage;

/**
 * Establece el foco en el componente.
 */
- (void) focusComponent: (JCOMPONENT) aComponent;
- (JCOMPONENT) getFocusedComponent;

/**
 * Posiciona el foco del formulario en el primer control agregado.
 * @visibility protected
 */
- (void) focusFirstComponent;

/**
 * Establece el foco del formulario en el siguiente control.
 * @visibility protected
 */
- (void) focusNextComponent;

/**
 * Establece el foco del formulario en el control anterior.
 * @visibility protected
 */
- (void) focusPreviousComponent;

/**
 * Hace foco en el primer control editable de la pagina actual.
 */
- (void) focusFirstComponentInCurrentPage;

/**
 *
 */
- (void) scrollPageToComponent: (JCOMPONENT) aComponent;

/**
 *
 */
- (void) scrollToNextPage;

/**
 *
 */
- (void) scrollToPreviousPage;

/**
 * Scrollea el contexto a la pagina dada.
 * @throws UI_INDEX_OUT_OF_RANGE_EX
 */
- (void) scrollToPage: (int) aPage;


/***
 * Se ejecuta al cambiar el foco del componente en el contenedor.
 */
- (void) onChangedFocusedComponent;

/**
 *
 */
- (int) getCurrentPage;

/**
 *
 */
- (int) getNumberOfPages;

/**
 *
 */
- (void) scrollToPage: (int) aPage;


/**
 *
 */
- (void) scrollToNextPage;

/**
 *
 */
- (void) scrollToPreviousPage;

/**
 * Scrollea a la pagina corrspondiente a la posicion Y.
 * @param (int) anYPos es la posicion Y que se mapea a la pagina correspondiente.
 */
- (void) scrollPageAtYPosition: (int) anYPos;

/**
 *
 */
- (void) scrollPageToComponent: (JCOMPONENT) aComponent;


@end

#endif

