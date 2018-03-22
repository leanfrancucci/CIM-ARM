#ifndef  JPROGRESS_BAR_H
#define  JPROGRESS_BAR_H

#define  JPROGRESS_BAR id

#include "JComponent.h"

/**
 *
 */
@interface  JProgressBar: JComponent
{
	char    myCaption[ JComponent_MAX_LEN + 1 ];
 	int			myProgressPosition;
	BOOL		myFilled;
	BOOL    myShowPercent;

}


/**
 * Avanza el progress bar a un valor absoluto de 0 a 99.
 */
- (void) advanceProgressTo: (int) aValue;

/**
 * Devuelve la posicion de 0 a 99 en donde se encuentra
 * ubicada la progress bar.
 */
- (int) getProgressPosition;

/**
 *	Indica si rellena la barra de progreso, sino la rellena, solo dibuja el
 *	cuadradito del porcentaje actual.
 */
- (void) setFilled: (BOOL) aValue;

/**
 *	Indica si muestra o no el porcentaje de progreso.
 */
- (void) showPercent: (BOOL) aValue;


@end

#endif

