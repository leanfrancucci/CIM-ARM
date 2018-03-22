#ifndef  JACTION_MENU_H
#define  JACTION_MENU_H

#define  JACTION_MENU id

#include "JMenuItem.h"


/**
 * Implementa un item de menu que dispara una accion determinada en contraste con el JSUbmenu
 * que es un conteenedor de items de menu.
 */
@interface  JActionMenu: JMenuItem
{
}

/**
 * Inicializa el menu para ejecutar una accion determinada.
 */
- initActionMenu: (char *) aCaption
					object: (id) anObject action: (char *)  anAction;


@end

#endif

