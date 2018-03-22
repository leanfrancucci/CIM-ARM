#ifndef  JVIRTUAL_SCREEN_H__
#define  JVIRTUAL_SCREEN_H__

#define  JVIRTUAL_SCREEN  id

#include <objpak.h>


/*******************************************************************************
*
* LCD HIPL driver.
*
* There is a virtual display area bigger than the physical display to implement
* the vertical scrolling capabilities.
* All output to the LCD is also save in an internal buffer, to provide scrolling,
* saving and restoring functions.
*
*
*		------------------ x ------------------>				   
*		|				
*		|		   
*		y
*		|
*		|
*		V
*
*   
*                 |---------------------|   }              }
*   FirstLine --> | text1               |   } PHYSICAL     }         
*                 | text2               |   } SCREEN       }
*                 | text3               |   }   4x20       }
*   LastLine  --> | text4               |   }              }
*                 |----------------------                  }
*                 |.text5...............|                  } VIRTUAL
*                 |.text6...............|                  } SCREEN
*                 |.....................|                  }   9x20
*                 |.....................|                  }
*                 |.....................|                  }
*                 |---------------------|                  }
*
* The virtual screen is bigger than the physical screen to provide scrolling
* capabilities. All the output is also written to an internal buffer for
* scrolling and saving/restoring the contents of the screen.
* The FirstLine and LastLine indicates the area of the buffer that it is currently
* showing on the screen. When you scroll down or up you move these variables change
* their values and the buffer is dumped to the screen.                                 
* Saving and restoring is useful when you want to display a popup window, and when  
* the user presses Enter, restores the original screen.                               
* The limitation is that you can only save/restore one screen at a time.             
*
********************************************************************************/

#define PHYSICAL_WIDTH   20
#define PHYSICAL_HEIGHT  4


typedef struct
{
	int height;
	int width;

} JVirtualSize;
	
/**
 *
 */
@interface  JVirtualScreen: Object
{
	JVirtualSize		myPhysicalSize;
	JVirtualSize		myVirtualSize;

	int myGlobalX;
	int myGlobalY;
		
	/*	
	int myScrollFromLine;
	int myScrollToLine;
	
	char *myScrBuf;
	int myFirstLine;
	int myLastLine;
	int myLineCount;
	
	int myOldFirstLine;
	int myOldLastLine;
	int myOldLineCount;
	char *myOldScreen;
	
	int myOldCursorX;
	int myOldCursorY;
	*/
}

/**/
+ new;

/**/
+ getInstance;

/**/
+ initialize;

/**/
- free;

/**
 * Initializes the display, creates the buffer and clear the 
 * screen.
 */
- (void) initScreen;

/**
 *
 */
- (void) initScreenWithHeight: (int) aVirtualHeight;


/**
 *
 */
//- (void) printFormat: (char *) aFormat, ...;

/**
 *
 */
- (void) clearScreen;

/**
 *
 */
- (void) setCursorState: (BOOL) aValue;

/**
 *
 */
- (void) setBlinkCursor: (BOOL) aValue;

/**
 *
 */
- (void) gotoPosX: (int) aPosX  posY: (int) aPosY;

/**
 *
 */
- (int) getXPos;

/**
 *
 */
- (int) getYPos;

/**
 *
 */
- (void) printChar: (char) aChar atPosX: (int) aPosX atPosY: (int) aPosY;

/**
 *
 */
- (void) printString: (char *) aText atPosX: (int) aPosX atPosY: (int) aPosY;


/**
 *
 */
- (int) getPhysicalWidth;

/**
 *
 */
- (int) getPhysicalHeight;


/**
 *
 */
- (int) getVirtualWidth;


/**
 *
 */
- (int) getVirtualHeight;

/**
 *
 */
- (void) programChar: (int) aRamPosition chars: (char *) aValue;


@end

#endif

