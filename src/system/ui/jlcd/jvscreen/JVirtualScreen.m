#include <assert.h>
#include <stdlib.h>

#include "util.h"
#include "UserInterfaceExcepts.h"
#include "JVirtualScreen.h"
#include "lcdlib.h"

//#define printd(args...) doLog(args)
#define printd(args...)


@implementation  JVirtualScreen

static id singleInstance = NULL;
static BOOL isOpen = FALSE;

/*****
 * Funciones de acceso al lcd
 */

/**/
static int lcdOpen(void)
{
	return lcd_open();
}

/**/
static void lcdClose(void)
{
	lcd_close();
}

/**/
static void lcdClear(void)
{
	if (!isOpen) return;
	lcd_clear();
}

/**/
static void lcdGotoXY(int x, int y)
{
	if (!isOpen) return;
	lcd_set_cursorxy(x, y);
}

/**/
static void lcdPut(char *text)
{
	if (!isOpen) return;
    //printf("lcdPut = %s \n", text);
	lcd_write((const char *)text, strlen(text));
}

/**/
static void lcdBlinkCursor(int value)
{
	if (!isOpen) return;
	lcd_set_cursor_blink(value);
}

/**/
static void lcdCursorState(int value)
{
	if (!isOpen) return;
	lcd_set_cursor_state(value);
}

/**/
static void lcdProgramChar(int ram, char *pvalue)
{
	if (!isOpen) return;
	lcd_programchar(ram, pvalue);
}


/**
 *
 */

/**/
+ new
{
	if (!singleInstance) singleInstance = [[super new] initialize];
	return singleInstance;
}


/**/
+ getInstance
{
	return [self new];
}

/**/
- initialize
{
	[super initialize];
	
	myGlobalX = 1;
	myGlobalY = 1;
		
	myPhysicalSize.width = PHYSICAL_WIDTH;
	myPhysicalSize.height = PHYSICAL_HEIGHT;
	myVirtualSize.width = PHYSICAL_WIDTH;
	myVirtualSize.height = PHYSICAL_HEIGHT;
	
	return self;
}

/**/
- (void) close
{
	isOpen  = FALSE;

	lcdClose();
}

/**/
- free
{
	lcdClose();
	
	return [super self];
}

/**/
- (void) initScreen
{	
	if (lcdOpen() < 0)
		THROW( UI_COULD_NOT_OPEN_SCREEN_DRIVER_EX );

	isOpen  = TRUE;

	[self clearScreen];
}

/**/
- (void) initScreenWithHeight: (int) aVirtualHeight
{
	myVirtualSize.height = aVirtualHeight;
	[self initScreen];
}

/**/
- (void) clearScreen
{
 	printd("JVirtualScreen -> clearScreen() \n");
	lcdClear();
}


/**/
- (void) setBlinkCursor: (BOOL) aValue
{
	if (aValue)
		[self setCursorState: TRUE];

	lcdBlinkCursor(aValue);
}

/**/
- (void) setCursorState: (BOOL) aValue
{
	lcdCursorState(aValue);
}


/**/
- (void) gotoPosX: (int) aPosX  posY: (int) aPosY
{
	if (aPosX < 1 || aPosY < 1 || aPosX > myVirtualSize.width || aPosY > myVirtualSize.height) {
		printd("JVirtualScreen: ERROR - Fuera de Rango: gotoPosX: %d posY: %d !\n", aPosX, aPosY);
		return;
	}

	if (aPosX < 1 || aPosY < 1 || aPosX > myPhysicalSize.width || aPosY > myPhysicalSize.height) {
		printd("JVirtualScreen: ERROR2 - Fuera de Rango: gotoPosX: %d posY: %d !\n", aPosX, aPosY);
		return;
	}
	
	lcdGotoXY(aPosX, aPosY);

	myGlobalX = aPosX;
	myGlobalY = aPosY;
}

/**/
- (int) getXPos
{
	return myGlobalX;
}

/**/
- (int) getYPos
{
	return myGlobalY;
}


/**/
- (void) printChar: (char) aChar atPosX: (int) aPosX atPosY: (int) aPosY
{
	char auxStr[2];
	auxStr[0] = aChar;
	auxStr[1] = '\0';
	[self printString: auxStr atPosX: aPosX atPosY: aPosY];
}

/**/
- (void) printString: (char *) aText atPosX: (int) aPosX atPosY: (int) aPosY
{
	if (aPosX < 1 || aPosY < 1 || aPosX > myVirtualSize.width || aPosY > myVirtualSize.height) {
		printd("JVirtualScreen: ERROR - Fuera de Rango: printString: \"%s\" atPosX: %d atPosY: %d !\n", 				
																																			aText, aPosX, aPosY);
		return;
	}		
	
	if (aPosX < 1 || aPosY < 1 || aPosX > myPhysicalSize.width || aPosY > myPhysicalSize.height) {
		printd("JVirtualScreen: ERROR2 - Fuera de Rango: printString: \"%s\" atPosX: %d atPosY: %d !\n", 				
																																			aText, aPosX, aPosY);
		return;
	}

	[self gotoPosX: aPosX  posY: aPosY];
	lcdPut(aText);

	//printd("JVirtualScreen: printString(\"%s\" (%d, %d))\n", aText, aPosX, aPosY);
}

/**/
- (int) getPhysicalWidth
{
	return myPhysicalSize.width;
}

/**/
- (int) getPhysicalHeight
{
	return myPhysicalSize.height;
}


/**/
- (int) getVirtualWidth
{
	return myVirtualSize.width;
}

/**/
- (int) getVirtualHeight
{
	return myVirtualSize.height;
}

/**/
- (void) programChar: (int) aRamPosition chars: (char *) aValue
{
	lcdProgramChar(aRamPosition, aValue);
}



@end

