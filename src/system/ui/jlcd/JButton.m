#include <assert.h>

#include "util.h"
#include "UserInterfaceExcepts.h"
#include "JButton.h"

//#define printd(args...) doLog(args)
#define printd(args...)


@implementation  JButton


/**/
- (void) initComponent
{
 [super initComponent];
 
	stringcpy(myCaption, "JButton...");
	myCanFocus = TRUE; 
}

/**/
- (void) setCaption: (char *) aValue
{
	stringcpy(myCaption, aValue);
	myWidth = strlen(myCaption) + 2;
}
- (char *) getCaption
{
	return myCaption;
}

/**/
- (void) doDraw: (JGRAPHIC_CONTEXT) aGraphicContext
{
	assert(aGraphicContext != NULL);

	[aGraphicContext printString: myCaption atPosX: myXPosition + 1 atPosY: myYPosition];

	[aGraphicContext printChar: ' ' atPosX: myXPosition atPosY: myYPosition];
	[aGraphicContext printChar: ' ' atPosX: myXPosition + myWidth - 1 atPosY: myYPosition];

  /*Alexia Se comento esta parte ya que cuando se aceptaba aparecia un mensaje de confirmacion, 
            si al mismo se le respondia que no, no dibujaba el simbolo correspondiente, ya que no lo ponia en foco
          nuevamnete. */
	
  //if (myIsFocused) {

		[aGraphicContext printChar: JComponent_LEFT_FOCUSED_BUTTON_CHAR
							atPosX: myXPosition atPosY: myYPosition];
		[aGraphicContext printChar: JComponent_RIGTH_FOCUSED_BUTTON_CHAR
							atPosX: myXPosition + myWidth - 1  atPosY: myYPosition];
 // }
}

/**/
- (void) doDrawCursor: (JGRAPHIC_CONTEXT) aGraphicContext
{
	assert(aGraphicContext != NULL);
	
	[aGraphicContext setBlinkCursor: FALSE];
}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) isPressed
{
	printd("JButton.doKeyPressed(%d)\n", aKey);

	
  if (aKey == JButton_KEY_ENTER) {
			
			/* Si no tiene definido el evento sale sin procesar la tecla */
			if (myOnClickActionObject == NULL)
				return FALSE;
				
			[self executeOnClickAction];
			return TRUE;
	}
	
	return FALSE;
}



@end

