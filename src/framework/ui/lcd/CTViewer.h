#ifndef CT_VIEWER_H
#define CT_VIEWER_H

#define CT_VIEWER id

#include <objpak.h>
#include "system/os/all.h"
#include "ctapp.h"

/**
 *	Una clase Viewer para un display de caracteres 2 lineas.
 *	Utiliza las librerias de LCD para mostrar la informacion.
 */
@interface CTViewer: Object
{
	char myNumber[30];
	char myLocation[17];	
	OTIMER myTimer;
}

/**
 * Metodo update recibe como parametro a quien le hace un update y un 
 * cambio de tipo ViewerChangeType.
 */
- (void) update: (id) aSender change : (int) aChange;


@end

#endif
