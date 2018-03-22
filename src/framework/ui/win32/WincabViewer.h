#ifndef Wincab_Viewer_H
#define Wincab_Viewer_H

#define WINCAB_VIEWER id

#include <objpak.h>
#include "ctapp.h"
#include "Viewer.h"

/**
*	LCDViewer. Es la encargada de la visualizacion de los cambios en el LCDVisor.
*/

@interface WincabViewer: Viewer
{
	char myLocation[17];
}

/**
* Metodo update recibe como parametro a quien le hace un update y un 
* cambio de tipo ViewerChangeType.
*/

- (void) update: (id) aSender change : (int) aChange;
 
@end

#endif
