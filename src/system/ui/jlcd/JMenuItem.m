#include <assert.h>
#include "UserInterfaceExcepts.h"
#include "util.h"
#include "JMenuItem.h"

//#define printd(args...) doLog(args)
#define printd(args...)


@implementation  JMenuItem

/**/
- (void) initComponent
{
 [super initComponent];
 
	myCanFocus = TRUE;
	strcpy(myCaption, "Main Menu");
	mySelected = FALSE;
	myMenuIndex = -1;
	
	myNumeratedMenuMode = FALSE;
	myCircularMenuMode = TRUE;
}


/**/
- free
{
	return [super free];
}

/**/
- (void) setNumeratedMenuMode: (BOOL) aValue { myNumeratedMenuMode = aValue;  }
- (BOOL) getNumeratedMenuMode { return myNumeratedMenuMode; }

/**/
- (void) setCircularMenuMode: (BOOL) aValue { myCircularMenuMode = aValue; }
- (BOOL) getCircularMenuMode { return myCircularMenuMode; }

/**/
- (void) setCaption: (char *) aValue
{
	assert(aValue != NULL);

	stringcpy(myCaption, aValue);
}
- (char *) getCaption { return myCaption; }

/**/
- (void) setMenuIndex: (int) aMenuIndex { myMenuIndex = aMenuIndex; }
- (int)  getMenuIndex { return myMenuIndex; }

/**/
- (BOOL) hasMenuItems { return FALSE; }


/**/
- (void) setSelected: (BOOL) aValue { mySelected = aValue; }
- (BOOL) isSelected { return mySelected; }


/**/
- (void) doDraw: (JGRAPHIC_CONTEXT) aGraphicContext
{
	THROW( ABSTRACT_METHOD_EX );
}

/**/
- (void) doDrawMenuItem: (JVIRTUAL_SCREEN) aGraphicContext
{	
	char			auxCaption[JComponent_MAX_LEN + 1];
	char 			format[15];	
	int len;
	
	assert(aGraphicContext != NULL);

	len = min(sizeof(auxCaption) - 1, myWidth - 1);
	
	/* El numero de menu si es que tiene que hacerlo */
	if (myNumeratedMenuMode) {
	
		snprintf(format, sizeof(format) - 1, "%s" "%s" "-%d" "%s", "%02d.", "%", len - 3, "s");
		snprintf(auxCaption, len + 1, format, myMenuIndex + 1, myCaption);

	} else {
			
		snprintf(format, sizeof(format) - 1, "%s" "%d" "%s", "%-", len, "s");
		snprintf(auxCaption, len + 1, format, myCaption);
	
	}
	
	[aGraphicContext printString: auxCaption atPosX: myXPosition + 1 atPosY: myYPosition];			
}

/**/
- (void) doDrawCursor: (JGRAPHIC_CONTEXT) aGraphicContext
{
	assert(aGraphicContext != NULL);
	
	/* no es necesario hacer el blink FALSE porque lo hace el MainMenu*/
	//[aGraphicContext setBlinkCursor: FALSE];
}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) isPressed
{
	THROW( ABSTRACT_METHOD_EX );
	return FALSE;
}

/**/
- (void) setMenuLevel: (int) aValue { myMenuLevel = aValue; }
- (int) getMenuLevel { 	return myMenuLevel; }

@end

