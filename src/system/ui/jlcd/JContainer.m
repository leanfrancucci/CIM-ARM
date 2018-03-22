#include <assert.h>
#include "util.h"
#include "UserInterfaceDefs.h"
#include "UserInterfaceExcepts.h"
#include "JContainer.h"


//#define printd(args...) doLog(args)
#define printd(args...)

@implementation  JContainer


/**/
- (void) initComponent
{	
	[super initComponent];

	myGraphicContext = [JGraphicContext new];
	assert(myGraphicContext != NULL);

	[myGraphicContext setXPosition: myXPosition];
	[myGraphicContext setYPosition: myYPosition];	
	
	myCurrentYPosition = myYPosition;
		
	myCurrentLayoutXPosition = 1;
	myCurrentLayoutYPosition = 1;	
		
	myComponents = [OrdCltn new];
	assert(myComponents != NULL);
	
	myFocusedComponent = NULL;
}


/**/
- free
{
	[myComponents freeContents];
	[myComponents free];
	
	[myGraphicContext free];

	return [super free];
}

/**
 * Metodos publicos
 */

/**/
- (void) setXPosition: (int) anXPosition
{
	assert(myGraphicContext != NULL);
	
	[super setXPosition: anXPosition];
	[myGraphicContext setXPosition: myXPosition];	
}	

/**/
- (void) setYPosition: (int) anYPosition
{
	assert(myGraphicContext != NULL);
	
	[super setYPosition: anYPosition];
	
	myCurrentYPosition = myYPosition;
	[myGraphicContext setYPosition: myCurrentYPosition];	
}	

/**/
- (void) setWidth: (int) aWidth
{
	assert(myGraphicContext != NULL);
	
	[super setWidth: aWidth];
	[myGraphicContext setWidth: myWidth];	
}	

/**/
- (void) setHeight: (int) aHeight
{
	assert(myGraphicContext != NULL);
	
	[super setHeight: aHeight];	
	[myGraphicContext setHeight: myHeight];		
}	
	
/**/
- (int) getComponentCount
{	
	return [myComponents size];
}

/**/
- (JCOMPONENT) getComponentAt: (int) anIndex
{
	return [myComponents at: anIndex];
}

/**
 * Reinmplementado para obtener el canFocus() del componente contenido
 */
- (BOOL) canFocus
{ 
	int i;
				
	/* Busca algun componente que pueda hacer foco */
	for (i = 0; i < [myComponents size]; i++) 
		if ([[myComponents at: i] canFocus]) 
			return TRUE;

	return myCanFocus; 
}

/**/
- (void) doFocusComponent
{	
	[super doFocusComponent];
	[self focusComponent: myFocusedComponent];
}

/**/
- (void) doBlurComponent
{
	[super doBlurComponent];
	if (myFocusedComponent != NULL)
		[myFocusedComponent doBlurComponent];
}


/**/
- (void) focusComponent: (JCOMPONENT) aComponent
{
	if (myFocusedComponent != NULL)
		[myFocusedComponent doBlurComponent];
	
	myFocusedComponent = NULL;
	
	if (aComponent != NULL && [aComponent canFocus])	 {		
		myFocusedComponent = aComponent;
		[myFocusedComponent doFocusComponent];
		[self scrollPageToComponent: myFocusedComponent];	
	}
	
	[self onChangedFocusedComponent];
}
 
	
/**/
- (JCOMPONENT) getFocusedComponent
{
	return myFocusedComponent;
}

/**/
- (void) focusFirstComponent
{
	int i;
	JCOMPONENT component;
	
	[self focusComponent: NULL];
	
	/* Busca el primer component con posibilidad de hacer foco */
	for (i = 0; i < [myComponents size]; i++) {
		component = [myComponents at: i];
		if ([component canFocus]) {
			[self focusComponent: component];
			break;			
		}
	}
}

/**/
- (void) focusNextComponent
{
	int i, j;
	JCOMPONENT component;
	JCOMPONENT newFocusedComponent = NULL;

	/* Busca el component actual */
	for (i = 0; i < [myComponents size]; i++) {
		component = [myComponents at: i];
		if (component == myFocusedComponent)
			break;
	}

	/* Busca el siguiente component con posibilidad de hacer foco */
	for (j = i + 1; j < [myComponents size]; j++) {
		component = [myComponents at: j];

		if (![component canFocus])
			continue;

		newFocusedComponent = component;
		break;
	}

	if (newFocusedComponent != NULL)
		[self focusComponent: newFocusedComponent];
}

/**/
- (void) focusPreviousComponent
{
	int i, j;
	JCOMPONENT component;
	JCOMPONENT newFocusedComponent = NULL;

	/* Busca el component actual */
	for (i = 0; i < [myComponents size]; i++) {
		component = [myComponents at: i];
		if (component == myFocusedComponent)
			break;
	}

	/* Busca el siguiente component con posibilidad de hacer foco */
	for (j = i - 1; j >= 0; j--) {
		component = [myComponents at: j];

		if (![component canFocus])
			continue;

		newFocusedComponent = component;
		break;
	}

	if (newFocusedComponent != NULL) 
		[self focusComponent: newFocusedComponent];
}

/**/
- (void) focusFirstComponentInCurrentPage
{
	int i;
	JCOMPONENT component;
	
	/* Busca el primer componente */
	for (i = 0; i < [myComponents size]; i++) {
		component = [myComponents at: i];
		if ([component getYPosition] >= myCurrentYPosition &&
		    [component getYPosition] <= myCurrentYPosition + myHeight - 1) {
					[self scrollPageToComponent: component];
					break;
		}
	}
}


/**/
- (void) addEol
{
	myCurrentLayoutYPosition++;
	myCurrentLayoutXPosition = 1;
}

/**/
- (void) addBlanks: (int) aQty
{
	myCurrentLayoutXPosition += aQty;
	if (myCurrentLayoutXPosition > [myGraphicContext getWidth]) 
		[self addEol];
}

/**/
- (void) addNewPage
{
	int currentPage;
	
	/* page como si comenzara de cero */
	if (myCurrentLayoutXPosition == 1 && myCurrentLayoutYPosition % myHeight == 1)
		return;
		
	currentPage = 1 + (myCurrentLayoutYPosition - 1) / 3;	
	myCurrentLayoutYPosition = currentPage * myHeight + 1;
	myCurrentLayoutXPosition = 1;
}


/**/
- (void) addComponent: (JCOMPONENT) aComponent
{	
	THROW_NULL(aComponent);
	
	[myComponents add: aComponent];
	
	/* configura el padre del componente */
	[aComponent setOwner: self];
	[aComponent setGraphicContext: myGraphicContext];
	[aComponent setLockedComponent: myIsLockedComponent];
	
	/* Comienzo del layout */
		
	if (myCurrentLayoutXPosition + [aComponent getWidth] > myWidth + 1)
		[self addEol];

	[aComponent setXPosition: myCurrentLayoutXPosition];
	[aComponent setYPosition: myCurrentLayoutYPosition];
 
	myCurrentLayoutXPosition += [aComponent getWidth];
			
	myCurrentLayoutYPosition += [aComponent getHeight] - 1;

	/* Fin Layout */ 	
		
	/* Hace foco en el componente si corresponde */	
	if (myFocusedComponent == NULL && [aComponent canFocus])
			[self focusComponent: aComponent]; 					
}

/**
 *
 */
- (void) setGraphicContext: (JGRAPHIC_CONTEXT) aGraphicContext
{
	aGraphicContext = aGraphicContext;
}

/**/
- (void) doDraw: (JGRAPHIC_CONTEXT) aGraphicContext
{
	int i;
	JCOMPONENT	component;
	
 	/* Imprime con su propio contexto */
	
	assert(aGraphicContext != NULL);
	assert(myComponents != NULL);
	[self clearContainerScreen];
		
	/* Apaga el blink del cursor */
	[aGraphicContext setBlinkCursor: FALSE];

	for (i = 0; i < [myComponents size]; i++) {	
		component = [myComponents at: i];
	
		if ([component isVisible] && 
				[aGraphicContext intersecsAreaAtXPos: 
															[component getXPosition] atYPos: [component getYPosition]]) 			
			[component paintComponent];
	}
	
	/* Le indica al control en foco que posicione, prenda o apague el cursor*/		
	[self drawCursor];
}

/**
 * Reinmplementado para hacer el doDrawCursor() del componente 
 * en foco del contenedor.
 */		
- (void) doDrawCursor: (JGRAPHIC_CONTEXT) aGraphicContext
{
	/** @todo copiar los datos basicos de aGraphicContext en myGraphicContext 
	          excepto l posicion en (x, y)*/
	if (myIsLockedComponent) 
		return;
								
	/* Busca el componente con foco */
	if (myFocusedComponent != NULL)
		[myFocusedComponent drawCursor];
}

/**/
- (void) clearContainerScreen
{
	if (myIsLockedComponent)
		return;
		
//	[myGraphicContext clearArea];
}

/**
 * Reimplementa el metodo */
- (void) setLockedComponent: (BOOL) aValue
{
	int i;

	[super setLockedComponent: aValue];
	
	/* Busca el componente y le configura el valor */
	for (i = 0; i < [myComponents size]; i++)	
			[[myComponents at: i] setLockedComponent: aValue];
}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) anIsPressed
{	
  id currentComponent = NULL;
  
	if (!anIsPressed)
			return FALSE;
	
	if (myFocusedComponent != NULL) {

		/* Le da la tecla al control para ver si la quiere o no */
		if ([myFocusedComponent processKey: aKey isKeyPressed: anIsPressed]) {
			printd("JContainer -> Soy el componente, manejo yo la tecla\n");
			[myFocusedComponent paintComponent];
				
			return TRUE;
		
		} else {
		
			switch (aKey) {

				/* TAB */
				case JComponent_TAB:
					printd("JContainer -> JComponent_TAB\n");
					[myFocusedComponent validateComponent];					
					[myFocusedComponent paintComponent];
          currentComponent = myFocusedComponent;
					[self focusNextComponent];
          
          if (currentComponent != myFocusedComponent) 
					 [myFocusedComponent paintComponent];
									
					return TRUE;


				/* SHIFT TAB */
				case JComponent_SHIFT_TAB:
					printd("JContainer -> JComponent_SHIFT_TAB\n");
					[myFocusedComponent validateComponent];
					[myFocusedComponent paintComponent];
          currentComponent = myFocusedComponent;
					[self focusPreviousComponent];
          
          if (currentComponent != myFocusedComponent) 
					 [myFocusedComponent paintComponent];
           
					return TRUE;
					
				default:				
				
					return FALSE;
			}
		
		}
		
	} else {

		if (aKey == UserInterfaceDefs_KEY_UP) {
			
			if ([self getCurrentPage] > 1)	
				[self scrollToPreviousPage];
				
			return TRUE;
		}		

		if (aKey == UserInterfaceDefs_KEY_DOWN) {			
			/*	myCurrentLayoutYPosition mantiene la siguiente posicion Y al ultimo conmponente agregado */
			if ([self getCurrentPage] < [self getNumberOfPages]) 
				[self scrollToNextPage];
			
      return TRUE;
		}

	}
	
	return FALSE;
}


/**/
- (int) getCurrentPage
{
	return (myCurrentYPosition - 1) / myHeight + 1;
}

/**/
- (int) getNumberOfPages
{
	return (myCurrentLayoutYPosition - 1) / myHeight + 1;
}

/**/
- (void) scrollToPage: (int) aPage
{
	if (aPage <= 0 || aPage > [self getNumberOfPages])
		THROW( UI_INDEX_OUT_OF_RANGE_EX );
	
	myCurrentYPosition = ((aPage - 1) * myHeight) + 1;
	
	[myGraphicContext setCurrentYPosition: myCurrentYPosition];
	
	if (!myIsLockedComponent)
		[self sendPaintMessage];
		
}


/**/
- (void) scrollPageAtYPosition: (int) anYPos
{
	[self scrollToPage: (anYPos - 1) / myHeight + 1];
}

- (void) scrollToNextPage
{	
	[self scrollToPage: [self getCurrentPage] + 1];
}

- (void) scrollToPreviousPage
{	
	[self scrollToPage: [self getCurrentPage] - 1];
}

/**/
- (void) scrollPageToComponent: (JCOMPONENT) aComponent
{
	assert(aComponent != NULL);

	printd("[aComponent getYPosition] = %d\n", [aComponent getYPosition]);
	printd("myCurrentYPosition = %d\n", myCurrentYPosition);
	printd("myHeight = %d\n", myHeight);
	
	if ( [aComponent getYPosition] >= myCurrentYPosition &&
			 [aComponent getYPosition] < myCurrentYPosition + myHeight) return;
			 
 	[self scrollPageAtYPosition: [aComponent getYPosition]];
}

/**/
- (void) onChangedFocusedComponent
{
}
 
@end

