  #include <assert.h>

#include "util.h"
#include "UserInterfaceExcepts.h"
#include "JComponent.h"

//#define printd(args...) doLog(args)
#define printd(args...)


/**/

@implementation  JComponent

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	[super initialize];

	[self initComponent];
	
	return self;
}

/**/
- free
{
	return [super free];
 }

/**/
- (void) initComponent
{
	myEventQueue = [JEventQueue getInstance];
	assert(myEventQueue != NULL);			

	myOwner = NULL;
		
	myGraphicContext = NULL;
	
	myXPosition = 1;
	myYPosition = 1;

	myMaxWidth = JComponent_MAX_WIDTH;
	myMaxHeight = JComponent_MAX_HEIHT;
	
	myWidth = myMaxWidth;
	myHeight = 1;
		
	myIsVisible = TRUE;
	myCanFocus = FALSE;
	myReadOnly = FALSE;
  myEnabled = TRUE;
	myIsFocused = FALSE;

	myOnFocusActionObject = NULL;
	myOnFocusActionMethod = NULL;
	
	myOnBlurActionObject = NULL;
	myOnBlurActionMethod = NULL;
			
	myOnClickActionObject = NULL;
	myOnClickActionMethod = NULL;
	
	myOnSelectActionObject = NULL;
	myOnSelectActionMethod = NULL;	
	
	myIsLockedComponent = TRUE;
}


/**/
- initWithOwner: (JCOMPONENT) aComponent
{
	[self setOwner: aComponent];
	
	return self;
}

/**/
- (void) setOwner: (JCOMPONENT) aValue { myOwner = aValue; }
- (JCOMPONENT) getOwner { return myOwner; }


/**/
- (void) setXPosition: (int) aPosition { myXPosition = aPosition; }
- (int) getXPosition { return myXPosition; }

/**/
- (void) setYPosition: (int) aPosition { myYPosition = aPosition; }
- (int) getYPosition { return myYPosition; }


/**/
- (void) setWidth: (int) aWidth 
{ 
		if (aWidth > myMaxWidth)
			THROW( UI_SCREEN_OUT_OF_RANGE_EX );
			
		myWidth = aWidth; 
}
- (int) getWidth { return myWidth; }

/**/
- (void) setHeight: (int) aHeight 
{ 
		if (aHeight > myMaxHeight)
			THROW( UI_SCREEN_OUT_OF_RANGE_EX );
			
		myHeight = aHeight; 
}
- (int) getHeight { return myHeight;}

/**/
- (int) getComponentArea
{
	return myWidth * myHeight;
}

/**/
- (void) setVisible: (int) aValue 
{ 
	myIsVisible = aValue; 
	[self paintComponent];
}
- (BOOL) isVisible { return myIsVisible; }

- (BOOL) isFocused { return myIsFocused; }

/**/
- (void) setCanFocus: (BOOL) aValue { myCanFocus = aValue; }
- (BOOL) canFocus { return myIsVisible && myCanFocus; }

/**/
- (void) doReadOnlyMode: (BOOL) aValue
{
	// HOOK METHOD
}

/**/
- (void) setReadOnly: (BOOL) aValue
{
	myReadOnly = aValue;

	[self doReadOnlyMode: aValue];

}

- (BOOL) isReadOnly { return myReadOnly; }

/**/
- (void) setEnabled: (BOOL) aValue
{
  myEnabled = aValue;
}

- (BOOL) isEnabled
{
  return myEnabled;
}



/**/
- (BOOL) processKey: (int) aKey isKeyPressed: (BOOL) isPressed
{
	return [self doKeyPressed: aKey isKeyPressed: isPressed];
}

/**/
- (BOOL) doProcessMessage: (JEvent *) anEvent
{
	THROW(ABSTRACT_METHOD_EX);
	return FALSE;
}

/**/
- (void) showComponent
{
	[self doShow];
}

/**/
- (void) hideComponent
{
	[self doHide];
}

/**/
- (void) doFocusComponent
{
  if (![self canFocus]) {
		//	doLog(0,"%s: doFocusComponent(): UI_CAN_NOT_FOCUS_COMPONENT_EX\n", [self str]);
			THROW( UI_CAN_NOT_FOCUS_COMPONENT_EX );
	}
			
	myIsFocused = TRUE;

	[self doFocus];
	[self executeOnFocusAction];
}

/**/
- (void) doBlurComponent
{
	myIsFocused = FALSE;	
	
	[self doBlur];
	[self executeOnBlurAction];
}

/**/
- (void) validateComponent
{
	[self doValidate];
}

/**/
- (void) doShow
{
	myIsVisible = TRUE;
}

/**/
- (void) doHide
{
	myIsVisible = FALSE;
}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) isPressed
{
	aKey = aKey;
	isPressed = isPressed;

	return FALSE;
}

/**/
- (void) setGraphicContext: (JGRAPHIC_CONTEXT) aGraphicContext
{
	myGraphicContext = aGraphicContext;
}

/**/
- (void) setLockedComponent: (BOOL) aValue
{
	myIsLockedComponent = aValue; 
	
	[self onChangeLockComponent: myIsLockedComponent];		
}

/**/
- (void) lockComponent
{ 
	[self setLockedComponent: TRUE];
	
}

/**/
- (void) unlockComponent
{ 
	[self setLockedComponent: FALSE];
}

/**/
- (void) onChangeLockComponent: (BOOL) isLocked
{
	isLocked = isLocked;
}


/**/
- (BOOL) isLockedComponent { return myIsLockedComponent; }


/**/
- (void) paintComponent
{
	if (myGraphicContext == NULL || myIsLockedComponent)	
		return;
		
	[self doDraw: myGraphicContext];
	[self drawCursor];
}


/**/
- (void) doDraw: (JGRAPHIC_CONTEXT) aGraphicContext
{
	aGraphicContext = aGraphicContext;
	THROW( ABSTRACT_METHOD_EX );
}

/**/
- (void) drawCursor
{
	[self doDrawCursor: myGraphicContext];
}

/**/
- (void) doDrawCursor: (JGRAPHIC_CONTEXT) aGraphicContext
{
	assert(aGraphicContext != NULL);
	aGraphicContext = aGraphicContext;
}

/**/
- (void) doFocus
{

}

/**/
- (void) doBlur
{	
}

/**/
- (void) doValidate
{
}


/**/
- (void) sendPaintMessage
{
	JEvent		evt;
		
	//printd("\n%s: sendPaintMessage()\n", [self str]);
	/* Repinta la pantalla */
	evt.evtid = JEventQueueMessage_PAINT;
	[myEventQueue putJEvent: &evt];
}

/**
 * Los eventos disparados
 **/

/**/
- (void) executeOnActionMethod: (id) anObject action: (char *) anAction
{
	SEL mySelector;

	if (anObject == NULL)
		return;

	mySelector = [anObject findSel: anAction];
	if (mySelector)
		[anObject perform: mySelector];
	else
		THROW( UI_BAD_ACTION_METHOD_EX );
}

/** OnFocus */
/**/ 
- (void) setOnFocusAction: (id) anObject action: (char *) anAction
{
	myOnFocusActionObject = anObject;
	myOnFocusActionMethod = anAction;
}

/**/
- (BOOL) hasOnFocusAction
{
	return myOnFocusActionObject != NULL && myOnFocusActionMethod != NULL;
}

/**/
- (void) executeOnFocusAction
{
	[self executeOnActionMethod: myOnFocusActionObject action: myOnFocusActionMethod];
}

/** OnBlur */
/**/
- (void) setOnBlurAction: (id) anObject action: (char *) anAction
{
	myOnBlurActionObject = anObject;
	myOnBlurActionMethod = anAction;
}

/**/
- (BOOL) hasOnBlurAction
{
	return myOnBlurActionObject != NULL && myOnBlurActionMethod != NULL;
}

/**/
- (void) executeOnBlurAction
{
	[self executeOnActionMethod: myOnBlurActionObject action: myOnBlurActionMethod];
}

/** OnClick */ 
/**/
- (void) setOnClickAction: (id) anObject action: (char *) anAction
{
	myOnClickActionObject = anObject;
	myOnClickActionMethod = anAction;
}

/**/
- (BOOL) hasOnClickAction
{
	return myOnClickActionObject != NULL && myOnClickActionMethod != NULL;
}

/**/
- (void) executeOnClickAction
{
	[self executeOnActionMethod: myOnClickActionObject action: myOnClickActionMethod];
}

/** OnChange */
/**/
- (void) setOnChangeAction: (id) anObject action: (char *) anAction
{
	myOnChangeActionObject = anObject;
	myOnChangeActionMethod = anAction;
}

/**/
- (BOOL) hasOnChangeAction
{
	return myOnChangeActionObject != NULL && myOnChangeActionMethod != NULL;
}

/**/
- (void) executeOnChangeAction
{
	[self executeOnActionMethod: myOnChangeActionObject action: myOnChangeActionMethod];
}


/** OnSelect */
/**/
- (void) setOnSelectAction: (id) anObject action: (char *) anAction
{
	myOnSelectActionObject = anObject;
	myOnSelectActionMethod = anAction;
}

/**/
- (BOOL) hasOnSelectAction
{
	return myOnSelectActionObject != NULL && myOnSelectActionMethod != NULL;
}

/**/
- (void) executeOnSelectAction
{
	[self executeOnActionMethod: myOnSelectActionObject action: myOnSelectActionMethod];
}

@end

