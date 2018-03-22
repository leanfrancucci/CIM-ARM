#ifndef  JCUSTOM_STATUS_BAR_H
#define  JCUSTOM_STATUS_BAR_H

#define  JCUSTOM_STATUS_BAR id

#include "JContainer.h"
#include "JLabel.h"

/**
 * Implementa una barra especial de estado con tres captions que indican
 * las operaciones ejecutables sobre el control actual seleccionado.
 **/
@interface  JCustomStatusBar: JContainer
{
	JLABEL								myLabelMenu1;
	JLABEL								myLabelMenuX;
	JLABEL								myLabelMenu2;

	/*
	char									myCaption1[ JComponent_LINE_SIZE + 1 ];
	char									myCaptionX[ JComponent_LINE_SIZE + 1 ];
	char									myCaption2[ JComponent_LINE_SIZE + 1 ];	
	*/
}

/**
 * Configura el titulo de la izquierda.
 * Si aCaption es null entonces configura la cadena vacia.
 */
- (void) setCaption1: (char *) aCaption; 
- (char *) getCaption1; 

/**
 * Configura el titulo del medio.
 */
- (void) setCaptionX: (char *) aCaption; 
- (char *) getCaptionX; 

/**
 * Configura el titulo de la derecha.
 */
- (void) setCaption2: (char *) aCaption; 
- (char *) getCaption2; 

@end

#endif

