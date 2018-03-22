#ifndef  JSUB_MENU_H
#define  JSUB_MENU_H

#define  JSUB_MENU id

#include "JMenuItem.h"

/**
 *
 */
@interface  JSubMenu: JMenuItem
{
	char						myBlankString[JComponent_MAX_LEN + 1];
	
	id							myMenuItems;

	JMENU_ITEM			mySelectedItem;
	JMENU_ITEM			myVisibleOnTopItem;
	JMENU_ITEM			myVisibleOnBottomItem;

	JMENU_ITEM			mySelectedSubMenu;

	int 						myIndexMenuPressed;
	unsigned long   myLastKeyPressedTime;
}

/**
 *  Busca el siguiente item visible
 */
- (JMENU_ITEM) getNextVisibleMenuItemFrom: (JMENU_ITEM) aMenuItem;

/**
 * Busca el step-esimo item de menu visible anterior a menuItem.
 */
- (JMENU_ITEM) getNextVisibleMenuItemFrom: (JMENU_ITEM) aMenuItem step: (int) aStep;


/**
 *  Busca el anterior item visible
 */
- (JMENU_ITEM) getPreviousVisibleMenuItemFrom: (JMENU_ITEM) aMenuItem;

/**
 * Busca el step-esimo item de menu visible posyerior a menuItem.
 */
- (JMENU_ITEM) getPreviousVisibleMenuItemFrom: (JMENU_ITEM) aMenuItem step: (int) aStep;

/**
 * Reconfigura los items que debe tener visibles en la pantalla.
 */
- (void) reconfigureVisibleItems;

/**
 * Devuelve el nivel en el que se encuentra actualmente el menu.
 * El primer nivel comienza en 1.
 */
- (int) getCurrentMenuLevel;

/**
 * Posiciona el menu en el indice anIndex.
 * @return el menu en el que se posiciona o NULL si no existe un menu en anOffset@throws
 */
- (JMENU_ITEM) gotoMenuItemFromIndex: (unsigned int) anIndex;

/**
 * Estavlece aMenu como el menu selecconado actualmente en el submenu.
 */
- (void) setSelectedMenuItem: (JMENU_ITEM) aMenu;

/**
 * Devuelve la cantidad de items visibles del menu
 */
- (unsigned int) visibleMenuItemsCount;

@end

#endif

