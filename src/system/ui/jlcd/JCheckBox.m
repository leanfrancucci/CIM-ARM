#include <assert.h>
#include <ctype.h>
#include <limits.h>

#include "util.h"
#include "UserInterfaceExcepts.h"
#include "JCheckBox.h"
#include "lcdlib.h"

#define _BX(x) (unsigned char)((x&0x10000000 ) << 7 | (x&0x01000000 ) << 6 | (x&0x00100000 ) << 5 |    (x&0x00010000 ) << 4 | (x&0x00001000 ) << 3 | (x&0x00000100 ) << 2 | (x&0x00000010 ) << 1 | ( x&0x00000001 ))
				 
#define _B(x) ((x/10000000) << 7 | ((x/1000000 )%10) << 6 | ((x/100000  )%10) << 5 | ((x/10000   )%10) << 4 | ((x/1000    )%10) << 3 | ((x/100     )%10) << 2 | ((x/10      )%10) << 1 | (x % 10))

/**/
static char puncheck[] =
{
	_B(00000),
	_B(10101),
	_B(00000),
	_B(10001),
	_B(00000),
	_B(10101),
	_B(00000),
	0x00
};

static char pcheck[] =
{
	_B(    0),
	_B(    1),
	_B(   11),
	_B(10110),
	_B(11100),
	_B( 1000),
	_B( 0000),
	0x00
};

#ifdef CT_NCURSES_SUPPORT
#define JCheckBox_CHAR_CHECKED			 		'X'
#define JCheckBox_CHAR_UNCHECKED		 		'_'
#else
#define JCheckBox_CHAR_CHECKED			 		'\x3'
#define JCheckBox_CHAR_UNCHECKED		 		'\x2'
#endif

//#define printd(args...) doLog(args)
#define printd(args...)

@implementation  JCheckBox

/**/
- (void) initComponent
{
 [super initComponent];
 
	myCaption[0] = '\0';
	myCheckedState = FALSE;
	myCanFocus = TRUE;

	lcd_programchar(2, puncheck);
  lcd_programchar(3, pcheck);
	
}


/**/
- (void) setCaption: (char *) aValue
{
	if (myWidth == 0)
		myWidth = strlen(aValue);

	strncpy2(myCaption, aValue, myWidth);

	[self paintComponent];
}

/**/
- (char *) getCaption
{
	return myCaption;
}

/**/
- (void) setChecked: (BOOL) aValue
{
	myCheckedState = aValue;
	[self paintComponent];
}

/**/
- (BOOL) isChecked
{
	return myCheckedState;
}


/**/
- (void) doDraw: (JGRAPHIC_CONTEXT) aGraphicContext
{
  assert(aGraphicContext != NULL);
  
	/* Imprime el caracter especial */
	[aGraphicContext printChar: myCheckedState ? JCheckBox_CHAR_CHECKED : JCheckBox_CHAR_UNCHECKED
														atPosX: myXPosition atPosY: myYPosition];

	/* Imprime el caption */
 	//[aGraphicContext printString: myCaption atPosX: myXPosition + 1 atPosY: myYPosition];	
}

/**/
- (void) doDrawCursor: (JGRAPHIC_CONTEXT) aGraphicContext
{
	assert(aGraphicContext != NULL);
	
	if (myReadOnly) 
		return;

	[aGraphicContext blinkCursorAtPosX: myXPosition atPosY: myYPosition];		
}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) isPressed
{

	printd("JCheckBox.doKeyPressed(%d)\n", aKey); 

	if (myReadOnly)
		return FALSE;

	/* Cambia el estado del checkbox */
	if (aKey == JCheckBox_KEY_CLICK) {
	
		myCheckedState = !myCheckedState;
		
		/* Si no tiene definido el evento sale sin procesar la tecla */
		if (myOnClickActionObject != NULL)
			[self executeOnClickAction];
			
		return TRUE;
	}

	return FALSE;
}

/**/
- (void) setCheckItem: (id) anItem
{
  myCheckItem = anItem;
}

/**/
- (id) getCheckItem
{
  return myCheckItem;
} 



@end

