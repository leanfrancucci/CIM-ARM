#include <assert.h>
#include "JPrintDebug.h"
#include "util.h"
#include "UserInterfaceDefs.h"
#include "UserInterfaceExcepts.h"
#include "JGraphicContext.h"

//#define printd(args...) doLog(args)
#define printd(args...)

@implementation  JGraphicContext

static char myClearingString[PHYSICAL_WIDTH + 1];


/**/
+ new
{
	return [[super new] initialize];
}


/**/
- initialize
{	
	[super initialize];

	myIsClear = FALSE;
	myVirtualScreen = [JVirtualScreen getInstance];
	assert(myVirtualScreen != NULL);

	myHeight = [myVirtualScreen getPhysicalHeight];
	myWidth = [myVirtualScreen getPhysicalWidth];
			
	myXPosition = 1;
	myCurrentXPosition = 1;
	
	myYPosition = 1;
	myCurrentYPosition = 1;
	
	myCursorXPosition = 1;
	myCursorYPosition = 1;

	return self;
}


/**/
- free
{
	return [super free];
}

/**/
- (void) setWidth: (int) aWidth 
{ 
		if (aWidth > [myVirtualScreen getPhysicalWidth])
			THROW( UI_SCREEN_OUT_OF_RANGE_EX );
			
		myWidth = aWidth; 
}
- (int) getWidth { return myWidth; }

/**/
- (void) setHeight: (int) aHeight 
{ 
		if (aHeight > [myVirtualScreen getPhysicalHeight])
			THROW( UI_SCREEN_OUT_OF_RANGE_EX );
			
		myHeight = aHeight; 	
}
- (int) getHeight { return myHeight;}


/**/
- (void) setXPosition: (int) aPosition { myXPosition = aPosition; }
- (int) getXPosition { return myXPosition; }

/**/
- (void) setYPosition: (int) aPosition { myYPosition = aPosition; }
- (int) getYPosition { return myYPosition; }

/**/
- (void) setCurrentXPosition: (int) aPosition { myCurrentXPosition = aPosition; }
- (int) getCurrentXPosition { return myCurrentXPosition; }

/**/
- (void) setCurrentYPosition: (int) aPosition { myCurrentYPosition = aPosition; }
- (int) getCurrentYPosition { return myCurrentYPosition; }

/**/
- (void) setCursorState: (BOOL) aValue
{
	[myVirtualScreen setCursorState: aValue];
}

/**/
- (void) setBlinkCursor: (BOOL) aValue
{
	[myVirtualScreen setBlinkCursor: aValue];
}

/**/
- (void) blinkCursorAtPosX: (int) aPosX atPosY: (int) aPosY
{
	[myVirtualScreen gotoPosX: [self mapXPosition: aPosX] posY: [self mapYPosition: aPosY]];	
	[myVirtualScreen setBlinkCursor: TRUE];
}

/**/
- (void) gotoPosX: (int) aPosX  posY: (int) aPosY
{
	myCursorXPosition = [self mapXPosition: aPosX];
	myCursorYPosition = [self mapYPosition: aPosY];
	
	[myVirtualScreen gotoPosX: myCursorXPosition posY: myCursorYPosition];			
}

/**/
- (void) clearScreen
{
	printd("JGraphicContext -> clearScreen()\n");
	[myVirtualScreen clearScreen];
	myIsClear = TRUE;
}

/**/
- (void) clearArea
{
	int i;
	if (myIsClear) return;
	printd("JGraphicContext -> clearArea()\n");
	memset(myClearingString, ' ', sizeof(myClearingString) - 1);
	myClearingString[min(myWidth, sizeof(myClearingString) - 1)] = '\0';
	
	for (i = myYPosition; i <= myHeight; i++)
		[myVirtualScreen printString: myClearingString atPosX: myXPosition atPosY: i];	
}

/**/
- (void) printChar: (char) aChar atPosX: (int) aPosX atPosY: (int) aPosY
{
	myIsClear = FALSE;
	[myVirtualScreen printChar: aChar 
					atPosX: [self mapXPosition: aPosX] atPosY: [self mapYPosition: aPosY]];	
}

/**/
- (void) printString: (char *) aText atPosX: (int) aPosX atPosY: (int) aPosY
{
	int xx, yy;
	int len;
	char *p = aText;

	myIsClear = FALSE;
	
	//char *string;
	
	/*
	for (	string = &aText[0], xx = [self mapXPosition: aPosX], yy = [self mapYPosition: aPosY]; 
				*string != '\0' && xx <= myWidth; 
				string++, xx++)
			[myVirtualScreen printChar: *string atPosX: xx atPosY: yy];			
	*/
	len = strlen(p);

	while (1) {

		xx = [self mapXPosition: aPosX];
		yy = [self mapYPosition: aPosY]; 
				
		[myVirtualScreen printString: p atPosX: xx atPosY: yy];
		printd("(%02d,%02d) = |%s|\n", xx, yy, p);

		len = strlen(p);
		if (len <= myWidth) break;
		
		p += myWidth;
		aPosX = 1;
		aPosY++;
	}


}

/**/
- (void) scrollDown: (int) aLinesQty
{
	myCurrentYPosition += aLinesQty;	
}

/**/
- (void) scrollUp: (int) aLinesQty
{
	myCurrentYPosition -= aLinesQty;
	if (myCurrentYPosition < 1)
		myCurrentYPosition = 1;	
}

/**/
- (BOOL) intersecsAreaAtXPos: (int) anXPos atYPos: (int) anYPos
{
	return anYPos >= myCurrentYPosition && anYPos < myCurrentYPosition + myHeight;
}

/**/
- (int) mapXPosition: (int) aPosX
{
	//return aPosX - myXPosition + 1;
	return myXPosition  - myCurrentXPosition + aPosX; 
}

/**/
- (int) mapYPosition: (int) aPosY
{	
	return myYPosition  - myCurrentYPosition + aPosY; 
}

 
@end

