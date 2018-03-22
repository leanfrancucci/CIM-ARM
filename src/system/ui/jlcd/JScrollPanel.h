#ifndef  JSCROLL_PANEL_H
#define  JSCROLL_PANEL_H

#define  JSCROLL_PANEL  id

#include "JContainer.h"


typedef enum 
{

	 JScrollPanel_VerticalScrollBarNone
	,JScrollPanel_VerticalScrollBarAlways
	,JScrollPanel_VerticalScrollBarWhenNecesary

} JScrollPanel_VerticalScrollBarMode;

						
/**
 * Implementa un panel contenedor de componentes.
 * Implementa un ScrollBar vertical si es que es necesario.
 **/
@interface  JScrollPanel: JContainer
{
	JScrollPanel_VerticalScrollBarMode	myVerticalScrollBarMode;
}



/****
 * Metodos publicos
 */

/**/
- initialize;

/**/
- free;

/**/
- (void) setVerticalScrollBarMode: (JScrollPanel_VerticalScrollBarMode) aValue;
- (JScrollPanel_VerticalScrollBarMode) getVerticalScrollBarMode;

@end

#endif

