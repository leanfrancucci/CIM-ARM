#include <assert.h>
#include "UserInterfaceExcepts.h"
#include "util.h"
#include "JProgressBar.h"

#ifdef CT_NCURSES_SUPPORT
#define JProgressBar_FILL_CHAR		'='
#define JProgressBar_EMPTY_CHAR		'_'
#else
#define JProgressBar_FILL_CHAR		'\x2'
#define JProgressBar_EMPTY_CHAR		'\x3'
#endif

//#define printd(args...) doLog(args)
#define printd(args...)


@implementation  JProgressBar


static char pfill1[] =
{
	0x1f,
	0x1f,
	0x1f,
	0x1f,
	0x1f,
	0x1f,
	0x1f,
	0x00
};

static char pempty2[] =
{
	0x1f,
	0x11,
	0x11,
	0x11,
	0x11,
	0x11,
	0xff,
	0x00
};


/**/
- (void) initComponent
{
	extern int lcd_programchar(int, char *);

  [super initComponent];

	myProgressPosition = 0;
	myCaption[0] = '\0';
	myShowPercent = TRUE;
	myFilled = TRUE;
	lcd_programchar(2, pfill1);
	lcd_programchar(3, pempty2);
}

/**/
- (void) advanceProgressTo: (int) aValue
{
	int absPos;

	if (aValue < 0 || aValue > 100)
		THROW( UI_INDEX_OUT_OF_RANGE_EX );

	/* myCurrebtPos va de 0 a 99 */
	myProgressPosition = aValue;

	absPos = min(((myWidth - 4 ) * myProgressPosition / 100), myWidth - 4);

	memset(myCaption, ' ', myWidth);

	if (myFilled) {
		memset(myCaption, JProgressBar_FILL_CHAR, absPos);
		memset(myCaption + absPos, JProgressBar_EMPTY_CHAR, myWidth - absPos - 4);
	} else {
		memset(myCaption, JProgressBar_EMPTY_CHAR, myWidth - 4);
		myCaption[absPos] = JProgressBar_FILL_CHAR;
	}
	
	if (myShowPercent)
		sprintf(myCaption + myWidth - 4, "%3d%s", myProgressPosition, "%");
		
	myCaption[myWidth] = '\0';

	[self paintComponent];
}

/**/
- (int) getProgressPosition
{
	return myProgressPosition;
}

/**/
- (void) doDraw: (JGRAPHIC_CONTEXT) aGraphicContext
{
	assert(aGraphicContext != NULL);

	printd("JProgressBar:doDraw()\n");

	[aGraphicContext printString: myCaption atPosX: myXPosition atPosY: myYPosition];
}

/**/
- (void) setFilled: (BOOL) aValue
{
	myFilled = aValue;
}

/**/
- (void) showPercent: (BOOL) aValue
{
	myShowPercent = aValue;
}


@end

