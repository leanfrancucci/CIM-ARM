#include <assert.h>
#include <ctype.h>
#include <time.h>
#include "UserInterfaceExcepts.h"
#include "util.h"
#include "JSubMenu.h"

//#define printd(args...) doLog(args)
#define printd(args...)


@implementation  JSubMenu

/**/
- (void) initComponent
{
 [super initComponent];

	myMenuItems = [OrdCltn new];
	assert(myMenuItems != NULL);

	myVisibleOnTopItem = NULL;
	myVisibleOnBottomItem  = NULL;

	mySelectedItem = NULL;
	mySelectedSubMenu = NULL;
	
	memset(myBlankString, ' ', sizeof(myBlankString) - 2);
	myBlankString[sizeof(myBlankString) - 1] = '\0';

	myLastKeyPressedTime = 0;
	myIndexMenuPressed = 0;
}

/**/
- free
{
	[myMenuItems freeContents];
	[myMenuItems free];

	return [super free];
}

/**/
- (BOOL) hasMenuItems { return [myMenuItems size] > 0; }

/**
 * Le configura el Widht a cada submenu
 */
- (void) setWidth: (int) aWidth
          
{
	int i;

	myWidth = aWidth;
	for (i = 0; i < [myMenuItems size]; i++)
		[[myMenuItems at: i] setWidth: myWidth];	
		
	[self reconfigureVisibleItems];
}

/**
 * Le configura el Height a cada submenu
 */
- (void) setHeight: (int) aHeight
{
	int i;

	myHeight = aHeight;
	for (i = 0; i < [myMenuItems size]; i++)
		[[myMenuItems at: i] setHeight: myHeight];	
		
	[self reconfigureVisibleItems];
}

/**/
- (void) addMenuItem: (JMENU_ITEM) aMenuItem
{
	assert(myMenuItems != NULL);
	assert(aMenuItem != NULL);

	[myMenuItems add: aMenuItem];

	[aMenuItem setWidth: myWidth];
 	[aMenuItem setHeight: myHeight];
	[aMenuItem setMenuIndex: [myMenuItems size] - 1];
	[aMenuItem setNumeratedMenuMode: myNumeratedMenuMode];
	[aMenuItem setCircularMenuMode: myCircularMenuMode];
		
	/*  ver si se puede hacer de manera mejor */
	if ([aMenuItem isKindOf: (id) [self class]])
		[aMenuItem setMenuLevel: myMenuLevel + 1];	
	else
		[aMenuItem setMenuLevel: myMenuLevel];
	
	if (mySelectedItem == NULL && [aMenuItem isVisible]) 
		[self setSelectedMenuItem: aMenuItem];

	[self reconfigureVisibleItems];
}

/**/
- (void) setSelectedMenuItem: (JMENU_ITEM) aMenu
{
	if (mySelectedItem != NULL)
		[mySelectedItem setSelected: FALSE];
		
	mySelectedSubMenu = NULL;
	mySelectedItem = aMenu;
	if (mySelectedItem != NULL) {
		[mySelectedItem setSelected: TRUE];	
		[self reconfigureVisibleItems];		
	} else {
		myVisibleOnTopItem = NULL;
		myVisibleOnBottomItem = NULL;
	}
}					
	
	
/**/
- (void) reconfigureVisibleItems
{
	int h;
	
	if ([myMenuItems size] == 0)
		return;
	
	assert(mySelectedItem != NULL);
	
	h = min([myMenuItems size], myHeight) - 1;
	
	if (myVisibleOnTopItem == NULL) myVisibleOnTopItem = mySelectedItem;		
	if (myVisibleOnBottomItem == NULL) myVisibleOnBottomItem = myVisibleOnTopItem;

	if ([mySelectedItem getMenuIndex] < [myVisibleOnTopItem getMenuIndex])
		myVisibleOnTopItem = mySelectedItem;
	
	if ([mySelectedItem getMenuIndex] > [myVisibleOnBottomItem getMenuIndex])		
		myVisibleOnTopItem = [self getPreviousVisibleMenuItemFrom: mySelectedItem step: h];
	
	myVisibleOnBottomItem = [self getNextVisibleMenuItemFrom: myVisibleOnTopItem step: h];
}

/**/
- (JMENU_ITEM) gotoMenuItemFromIndex: (unsigned int) anIndex
{
	JMENU_ITEM menu;
	
	if (anIndex < 0 || anIndex >= [self visibleMenuItemsCount])
		return NULL;
	
	menu = [myMenuItems at: anIndex];
	[self setSelectedMenuItem: menu];	
	return menu;	
}

				
/**/
- (JMENU_ITEM) getPreviousVisibleMenuItemFrom: (JMENU_ITEM) aMenuItem
{
	JMENU_ITEM menu;
	int index;

	menu = aMenuItem;
	
	/* Busca para atras */
	for (index = [aMenuItem getMenuIndex] - 1; index >= 0; index--) {
		menu = [myMenuItems at: index];
		if ([menu isVisible])
			return menu;
	}
	
	/* Sigue buscando del final si es que esta configurado circular */
	if (myCircularMenuMode)
		for (index = [myMenuItems size] - 1; index >= 0; index--) {
			menu = [myMenuItems at: index];
			if ([menu isVisible] || menu == aMenuItem)
				break;
		}
		
	return menu;
}

/**/
- (JMENU_ITEM) getPreviousVisibleMenuItemFrom: (JMENU_ITEM) aMenuItem step: (int) aStep
{
	JMENU_ITEM menu;

	menu = aMenuItem;
	while (aStep--)
		menu = [self getPreviousVisibleMenuItemFrom: menu];

	return menu;
}

/**/
- (JMENU_ITEM) getNextVisibleMenuItemFrom: (JMENU_ITEM) aMenuItem
{
	JMENU_ITEM menu;
	int index;

	menu = aMenuItem;
	
	/* Busca para adelante */
	for (index = [aMenuItem getMenuIndex] + 1; index < [myMenuItems size]; index++) {
		menu = [myMenuItems at: index];
		if ([menu isVisible])
			return menu;
	}
	
	/* Sigue buscando del final si es que esta configurado circular */
	if (myCircularMenuMode)
		for (index = 0; index < [myMenuItems size]; index++) {
			menu = [myMenuItems at: index];
			if ([menu isVisible] || menu == aMenuItem)
				break;
		}
	
	return menu;
}

/**/
- (JMENU_ITEM) getNextVisibleMenuItemFrom: (JMENU_ITEM) aMenuItem step: (int) aStep
{
	JMENU_ITEM menu;

	menu = aMenuItem;
	while (aStep--)
		menu = [self getNextVisibleMenuItemFrom: menu];

	return menu;
}


/**/
- (void) doDraw: (JGRAPHIC_CONTEXT) aGraphicContext
{
	JMENU_ITEM menu;
	int index;
	
	assert(aGraphicContext != NULL);

	if (mySelectedSubMenu != NULL) {

		[mySelectedSubMenu setXPosition: myXPosition];
		[mySelectedSubMenu setYPosition: myYPosition];
		[mySelectedSubMenu doDraw: aGraphicContext];		


	} else {

		if (myVisibleOnTopItem == NULL || myVisibleOnBottomItem == NULL)
			return;

		for (index = 0, menu = myVisibleOnTopItem; index < myHeight; index++) {

			[menu setXPosition: myXPosition];
			[menu setYPosition: myYPosition + index];
			[menu doDrawMenuItem: aGraphicContext];

			/* Imprime el caracter de seleccionado */
			if ([menu isSelected])
				[aGraphicContext printChar: JMenuItem_SEL_ITEM atPosX: myXPosition atPosY: myYPosition + index];
			else
				[aGraphicContext printChar: ' ' atPosX: myXPosition atPosY: myYPosition + index];				

			if (menu == myVisibleOnBottomItem)
				break;

			menu = [self getNextVisibleMenuItemFrom: menu];
		}
		
		/* Imprime en blanco las siguientes lineas si no llego al myHeight */
		for (index++; index < myHeight; index++) 
			[aGraphicContext printString: myBlankString atPosX: myXPosition atPosY: myYPosition + index];		
	}
}


/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) isPressed
{
	JMENU_ITEM menu;
	
	/* si esta dentro de un SubMenu del SubMenu ... */
	if (mySelectedSubMenu != NULL) {

		/* Escape */
		if (aKey == JMenuItem_KEY_ESCAPE) {
      
			if (![mySelectedItem doKeyPressed: aKey isKeyPressed: isPressed]) 
				mySelectedSubMenu = NULL;				
				
			return TRUE;			
		}

		return [mySelectedSubMenu doKeyPressed: aKey isKeyPressed: isPressed];

	} else {

		switch (aKey) {

			/**/
			case JMenuItem_KEY_UP:

					myLastKeyPressedTime = 0;
					
					if ([myMenuItems size] == 0 || mySelectedItem == NULL || myVisibleOnTopItem == NULL) 
						  return TRUE;

					/* busca el anterior visible */
					menu = [self getPreviousVisibleMenuItemFrom: mySelectedItem];
					
					if (menu == mySelectedItem || ![menu isVisible]) 
						return TRUE;

					[self setSelectedMenuItem: 	menu];

					return TRUE;

			/**/
			case JMenuItem_KEY_DOWN:

					myLastKeyPressedTime = 0;
					
					if ([myMenuItems size] == 0) 
						return TRUE;

					/* busca el siguiente visible */
					menu = [self getNextVisibleMenuItemFrom: mySelectedItem];

					if (menu == mySelectedItem) 
						return  TRUE;

					[self setSelectedMenuItem: 	menu];

					return  TRUE;

			/* Enter */
			case JMenuItem_KEY_ENTER:
					
          myLastKeyPressedTime = 0;
			
					if ([myMenuItems size] == 0) 
						return TRUE;

					THROW_NULL(mySelectedItem);

					if ([mySelectedItem hasMenuItems])  {
						mySelectedSubMenu = mySelectedItem;
						return TRUE;
					}
          	
					return [mySelectedItem doKeyPressed: aKey isKeyPressed: isPressed];

			/* Escape */
			case JMenuItem_KEY_ESCAPE:	
						
					myLastKeyPressedTime = 0;
					
					/* Sale y deja el primer item del submenu seleccionado */	
/*					[self setSelectedMenuItem: NULL];
					if ([myMenuItems size] > 0)
						[self setSelectedMenuItem: [myMenuItems at: 0]];
	*/

					/* Sale con FALSE asi el menu de arriba sabe que es el ultimo submenu */
					return FALSE;

			/**/
			default:

			 	if (myNumeratedMenuMode && (isdigit(aKey) || aKey == JComponent_KEY_PLUS_10)) {
				
					if (getTicks() - myLastKeyPressedTime >= JMenuItem_MSECS_TO_PRESS_KEY) {
						myLastKeyPressedTime = 0;
						myIndexMenuPressed = 0;
					}
				
					if (aKey == JComponent_KEY_PLUS_10) {
						
						myLastKeyPressedTime = getTicks();
						myIndexMenuPressed = myIndexMenuPressed + 10;
						return TRUE;
					
					} else	{
					
						myIndexMenuPressed = myIndexMenuPressed + (aKey - '0');
						myLastKeyPressedTime = 0;
						
					}
											
					/* Si se va de rango resetea el contador de tiempo */
					if (myIndexMenuPressed < 1 || myIndexMenuPressed > [self visibleMenuItemsCount]) {
						myLastKeyPressedTime = 0;
						return TRUE;
					}
					
					[self gotoMenuItemFromIndex: myIndexMenuPressed - 1];
					
					return TRUE;
						
				} else				
				
					return FALSE;

			}
	}
		
	return FALSE;
}


/**/
- (int) getCurrentMenuLevel
{
	if (mySelectedSubMenu == NULL) 
		return myMenuLevel;
	else
		return [mySelectedSubMenu getCurrentMenuLevel];
}

/**/
- (void) setNumeratedMenuMode: (BOOL) aValue 
{ 
	int i;
	
	[super setNumeratedMenuMode: aValue];
	
	for (i = 0; i < [myMenuItems size]; i++)
 		[[myMenuItems at: i] setNumeratedMenuMode: aValue];
}

/**/
- (void) setCircularMenuMode: (BOOL) aValue 
{ 
	int i;
	
	[super setCircularMenuMode: aValue];
	
	for (i = 0; i < [myMenuItems size]; i++)
 		[[myMenuItems at: i] setCircularMenuMode: aValue];
}

/**/
- (unsigned int) visibleMenuItemsCount
{
	int i;
	int count = 0;
	
	count = 0;	
	for (i = 0; i < [myMenuItems size]; i++)
 		if ([[myMenuItems at: i] isVisible])
			count++;

	return count;
}


@end


