#ifndef  JMENU_ITEM_H
#define  JMENU_ITEM_H

#define  JMENU_ITEM  id

#include "JComponent.h"


/**
 *
 */
@interface  JMenuItem: JComponent
{
	char						myCaption[JComponent_MAX_LEN + 1];
	
	int							myMenuIndex; /* el indice del menu en el submenu actual comienza de cero */
	int							myMenuLevel; /* el nivel de profundidad del menu comienza de 1 */
	BOOL						mySelected;
	
	BOOL						myNumeratedMenuMode;
	BOOL						myCircularMenuMode;
}

/**
 * El titulo del menu.
 * @throws UI_INDEX_OUT_OF_RANGE_EX
 */
- (void) setCaption: (char *) aValue;

/**
 *
 */
- (char *) getCaption;

/**
 * El orden en el que se encuentra el item en la lista nterna.
 * El orden es ascendente comenzando desde 0 (no le afecta el valor vidible del control)
 */
- (void) setMenuIndex: (int) aMenuIndex;
- (int)  getMenuIndex;

/**
 * Dibuja el item de tipo ActionMenu o de tipo SubMenuItem.
 * Metodo reimplementado por cada una de estas dos clases.
 * el metodo doDraw() llama e este metodo al pintar.
 */
- (void) doDrawMenuItem: (JVIRTUAL_SCREEN) aVirtualScreen;

/**
 * Devuelve TRUE si el menuItem tiene items hijos y
 * devuelve FALSE en caso contrario.
 */
- (BOOL) hasMenuItems;

/**/
- (void) setSelected: (BOOL) aValue;
- (BOOL) isSelected;

/**
 * Configura el nivel en el que se encuentra actualkmente el menu.
 * El primer nivel comienza en 1.
 */
- (void) setMenuLevel: (int) aValue;
- (int) getMenuLevel;

/**
 * Configura el menu para que imprima los items numerados a izquierda 
 * en orden ascendente.
 */
- (void) setNumeratedMenuMode: (BOOL) aValue;
- (BOOL) getNumeratedMenuMode;

/**
 * Configura el menu para que navegue los items de manera circular o no.
 */
- (void) setCircularMenuMode: (BOOL) aValue;
- (BOOL) getCircularMenuMode;

@end

#endif

