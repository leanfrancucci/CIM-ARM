#include <assert.h>
#include "UserInterfaceDefs.h"
#include "JScrollPanel.h"

#define printd(args...)// doLog(0,args)
//#define printd(args...)

@implementation  JScrollPanel

/**/
- (void) initComponent
{
 [super initComponent];
 
	myReadOnly = FALSE; 
	myVerticalScrollBarMode = JScrollPanel_VerticalScrollBarWhenNecesary;
}


/**/
- free
{
	return [super free];
}

/**/
- (void) setVerticalScrollBarMode: (JScrollPanel_VerticalScrollBarMode) aValue 
{ myVerticalScrollBarMode = aValue; }
- (JScrollPanel_VerticalScrollBarMode) getVerticalScrollBarMode { return myVerticalScrollBarMode; }

/**/
- (void) doDraw: (JGRAPHIC_CONTEXT) aGraphicContext
{
	//char image;
	[super doDraw: aGraphicContext];
	
	/* Escribe la barra de scroll vertical si corresponde */
	if (myVerticalScrollBarMode == JScrollPanel_VerticalScrollBarNone)
		return;

	/* Si no es necesario que la dibuje */
	if (myVerticalScrollBarMode == JScrollPanel_VerticalScrollBarWhenNecesary &&
			[self getNumberOfPages] <= 1)
		return;				

	/* Dibuja el scroll bar */
	
/*	
	if ([self getNumberOfPages] <= 1)
		image = JScrollBar_ONLY_ONE_PAGE_IMAGE;
	else if ([self getCurrentPage] == 1)
			image = JScrollBar_TOP_PAGE_IMAGE;
	else if ([self getCurrentPage] == [self getNumberOfPages])
				image = JScrollBar_BOOTOM_PAGE_IMAGE;
	else
				image = JScrollBar_MIDDLE_PAGE_IMAGE;
	*/
	/* Imprime el caracter de abajo del ScrollBar */				
	//[aGraphicContext printChar: image atPosX: myXPosition + myWidth - 1 atPosY: myCurrentYPosition];
}

@end

