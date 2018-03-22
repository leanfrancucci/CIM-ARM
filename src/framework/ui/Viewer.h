#ifndef Viewer_H
#define Viewer_H

#define VIEWER id

#include <objpak.h>
#include "ctapp.h"
#include "LcdVisor.h"

/**
*	Viewer. Es la encargada de la visualizacion de los cambios.
*/

@interface Viewer: Object
{
	LCD_VISOR lcdVisor;
}

/**
* Metodo update recibe como parametro a quien le hace un update y un 
* cambio de tipo ViewerChangeType.
*/

- (void) update: (id) aSender change : (int) aChange;


@end

#endif
