  #include <assert.h>
#include "UserInterfaceExcepts.h"
#include "InputKeyboardManager.h"
#include "util.h"
#include "JMainMenu.h"

//#define printd(args...) doLog(args)
#define printd(args...)

@implementation  JMainMenu


/**/
- (void) initComponent
{
 [super initComponent];
 
	myCanFocus = TRUE;
	
	myNumeratedMenuMode = TRUE;
	myCircularMenuMode = TRUE;

	[self hastaNuncaMalditosItems];
}



/**/
- free
{
	[mySubMenu free];

	return [super free];
}

/**/
- (void) setNumeratedMenuMode: (BOOL) aValue 
{ 
	myNumeratedMenuMode = aValue;
 	[mySubMenu setNumeratedMenuMode: myNumeratedMenuMode];
}

/**/
- (BOOL) getNumeratedMenuMode { return myNumeratedMenuMode; }


/**/
- (void) setCircularMenuMode: (BOOL) aValue
{ 
	myCircularMenuMode = aValue;
 	[mySubMenu setCircularMenuMode: myCircularMenuMode];
}

/**/
- (BOOL) getCircularMenuMode { return myCircularMenuMode; }


/**/
- (void) setWidth: (int) aWidth
{
	assert(mySubMenu != NULL);

	[super setWidth: aWidth];
	[mySubMenu setWidth: aWidth];
}

/**/
- (void) setHeight: (int) aHeight
{
	assert(mySubMenu != NULL);

	myHeight = aHeight;
	[mySubMenu setHeight: myHeight];
}


/**/
- (void) addMenuItem: (JMENU_ITEM) aMenuItem
{
	assert(mySubMenu != NULL);
	assert(aMenuItem != NULL);

	[aMenuItem setWidth: myWidth];
	[aMenuItem setHeight: myHeight];
		
	[mySubMenu addMenuItem: aMenuItem];
}

/**/
- (void) doDraw: (JGRAPHIC_CONTEXT) aGraphicContext
{
	assert(mySubMenu != NULL);
	[mySubMenu doDraw: aGraphicContext];	
}

/**/
- (void) doDrawCursor: (JGRAPHIC_CONTEXT) aGraphicContext
{
	assert(aGraphicContext != NULL);

	[aGraphicContext setBlinkCursor: FALSE];
}


/**/
- (void) doFocus
{
	assert(mySubMenu != NULL);
	
	[[InputKeyboardManager getInstance] setNumericMode];			
	[mySubMenu doFocus];	
}

/**/
- (void) doBlur
{	
	assert(mySubMenu != NULL);
	[mySubMenu doBlur];	
}


/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) isPressed
{
	assert(mySubMenu != NULL);
	return [mySubMenu doKeyPressed: aKey isKeyPressed: isPressed];
}

/**/
- (int) getCurrentMenuLevel
{
	assert(mySubMenu != NULL);
	return [mySubMenu getCurrentMenuLevel];
}

/**/
- (void) hastaNuncaMalditosItems
{
	if (mySubMenu != NULL)	
		[mySubMenu free];	
	
	mySubMenu = [JSubMenu new];
	[mySubMenu setMenuLevel: 1];
	[mySubMenu setNumeratedMenuMode: myNumeratedMenuMode];
	[mySubMenu setCircularMenuMode: myCircularMenuMode];
	[mySubMenu setWidth: myWidth];
	[mySubMenu setHeight: myHeight];	
}

/**
 * Devuelve el submenu
 */
- (JSUB_MENU) getSubMenu
{
  return mySubMenu;
}

@end

