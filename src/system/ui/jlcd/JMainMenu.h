#ifndef  JMAIN_MENU_H
#define  JMAIN_MENU_H

#define  JMAIN_MENU id

#include "JComponent.h"
#include "JSubMenu.h"

/**
 * Maneja un conjunto de menues de tipo JSubMenu o JActionMenu. 
 *
 * El menu puede configurarse para que imprima numeros secuenciales 
 * al lado de cada item y para que estos puedan ser accedidos a traves de 
 * shortcuts: si se ingresa un numero entonces el menu se posiciona n el item
 * que se encuentre en el orden del numero ingresado. 
 *
 * es posible configurar el menu para que navegue los items de manera circular.
 *
 **/
@interface  JMainMenu: JComponent
{
		BOOL						myNumeratedMenuMode;
		BOOL						myCircularMenuMode;
		
		JSUB_MENU				mySubMenu;
};


/**
 * Agrega un nuevo item de menu al menu principal.
 */
- (void) addMenuItem: (JMENU_ITEM) aMenuItem;

/**
 * Devuelve el nivel en el que se encuentra actualmente el menu.
 * El primer nivel comienza en 1.
 */
- (int) getCurrentMenuLevel;

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

/**
 * Elimina todo slos menu items del main menu
 */
- (void) hastaNuncaMalditosItems;

/**
 * Devuelve el submenu
 */
- (JSUB_MENU) getSubMenu;

@end

#endif

