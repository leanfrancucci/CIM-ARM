#include <assert.h>
#include "util.h"

#include "UserInterfaceExcepts.h"
#include "JList.h"
#include "ordcltn.h"

//#define printd(args...) doLog(args)
#define printd(args...)


@implementation  JList

/**/
- (void) initComponent
{
 [super initComponent];
 
	myOwnObjects = FALSE;
	myCanFocus = TRUE;

	myItems = [OrdCltn new];
	assert(myItems != NULL);
	
	myItemIndex = -1;

	myVisibleOnTopItem = -1;
	myVisibleOnBottomItem = -1; 
}

/**/
- free
{
	if (myOwnObjects)
		[myItems freeContents];

	[myItems free];

	return [super free];
}

/**/
- (void) setOwnObjects: (BOOL) anOwnObjects { myOwnObjects = anOwnObjects; }
- (BOOL) getOwnObjects { return myOwnObjects; }


/**/
- (void) doDraw: (JGRAPHIC_CONTEXT) aGraphicContext
{	
	int index;
	char auxCaption[JComponent_MAX_LEN + 1];

	if (myVisibleOnTopItem == -1 || myVisibleOnBottomItem == -1)
		return;
		
	for (index = myVisibleOnTopItem; index <= myVisibleOnBottomItem; index++) {

		/* Imprime el item */		
		if ([myItems at: index] != NULL)
			[aGraphicContext printString: 
								alignString(auxCaption, [[myItems at: index] str], myWidth - 1, UTIL_AlignLeft) 
																						atPosX: myXPosition + 1
																						atPosY: myYPosition + index - myVisibleOnTopItem];
		
		[aGraphicContext printChar: '['
										atPosX: myXPosition + 1 atPosY: myYPosition + index - myVisibleOnTopItem];
		[aGraphicContext printChar: ']'
										atPosX: myXPosition + myWidth - 1 atPosY: myYPosition + index - myVisibleOnTopItem];
												
		/* El seleccionado */
		if (index == myItemIndex) 
			[aGraphicContext printChar: '\xD8'
										atPosX: myXPosition atPosY: myYPosition + index - myVisibleOnTopItem];
		else
			[aGraphicContext printChar: ' '
										atPosX: myXPosition atPosY: myYPosition + index - myVisibleOnTopItem];		
	}
	
}

/**/
- (void) doDrawCursor: (JGRAPHIC_CONTEXT) aGraphicContext
{
	assert(aGraphicContext != NULL);

	if (myReadOnly) 
		return;

	[aGraphicContext setBlinkCursor: FALSE];
}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) isPressed
{
	int itemCount;

	itemCount = [myItems size];
	
	if (myReadOnly || itemCount == 0)
		return FALSE;

	switch (aKey) {

		/* Muetra la opcion anterior */
		case JList_KEY_LEFT:

			if (myItemIndex > 0) {

				if (myVisibleOnTopItem == myItemIndex) {					
					myVisibleOnTopItem--;
					myVisibleOnBottomItem--;
				}

				myItemIndex--;
				[self executeOnSelectAction];
			}

			return TRUE;

		/* Muetra la opcion siguiente */
		case JList_KEY_RIGHT:

		 	if (itemCount > 0 && myItemIndex < itemCount - 1) {

				if (myVisibleOnBottomItem == myItemIndex) {
					myVisibleOnTopItem++;
					myVisibleOnBottomItem++;					
				}

				myItemIndex++;
    			[self executeOnSelectAction];
			}

			return TRUE;
		
		case JList_KEY_ENTER:

			/* Si no tiene definido el evento sale sin procesar la tecla */
			if (myOnClickActionObject == NULL)
				return FALSE;
	
			if (myItemIndex >= 0)
				[self executeOnClickAction];

			return TRUE;		

		default:

			break;
	}

	return FALSE;
}

/**/
- (void) doValidate
{
}

/**/
- (void) setSelectedIndex: (int) anIndex
{
 	/* throws an exceptions if the value is invalid */
	if (anIndex < 0 || anIndex > [myItems size] - 1)
		THROW( UI_INDEX_OUT_OF_RANGE_EX );

	myItemIndex = anIndex;

	/* Ubica el cursor adecuadamente */
	if (myItemIndex >= myVisibleOnTopItem && myItemIndex <= myVisibleOnBottomItem)
		return;

	/* si es el ultimo elemento el seleccionado se ubica abajo de la lista,
	   si no se ubica arriba de la lista */
	if (myItemIndex == [myItems size] - 1)	{					
		myVisibleOnBottomItem = myItemIndex;
		myVisibleOnTopItem = max(0, myVisibleOnBottomItem - myHeight + 1) ;		
	} else {
		myVisibleOnTopItem = myItemIndex;
		myVisibleOnBottomItem = min([myItems size], myVisibleOnTopItem + myHeight) - 1;	
	}
}

/**/
- (int) getSelectedIndex
{
	return myItemIndex;
}

/**/
- (void) setSelectedItem: (id) anObject
{
	int i;

	for (i = 0; i < [myItems size]; i++)
		if ([myItems at: i] == anObject) {
			[self setSelectedIndex: i];
			return;
		}
	THROW( UI_INDEX_OUT_OF_RANGE_EX );
}

/**/
- (id) getSelectedItem
{
	if (myItemIndex < 0)
		return NULL;

	return [myItems at: myItemIndex];
}

/**/
- (void) clearItems
{
	int i;
	id obj;
	int count = [myItems size];
	
	for (i = 0; i < count; i++) {
		obj = [myItems at: 0];
		if (myOwnObjects)
			[obj free];
		[myItems removeAt: 0];		
	}
  
	myItemIndex = -1;
}

/**/
- (void) addItemsFromCollection: (COLLECTION) aCollection
{
	/* buscar el metodo para agregarlos de una sola vez */
	int i;

	THROW_NULL( aCollection );

	for (i = 0; i < [aCollection size]; i++)
		[self addItem: [aCollection at: i]];
}


/**/
- (void) addItem: (id) anObject
{
	THROW_NULL( anObject );

	[myItems add: anObject];

	if (myItemIndex == -1) {
		[self setSelectedIndex: 0];
		myVisibleOnTopItem =  myItemIndex;
	}

	myVisibleOnBottomItem = min([myItems  size], myItemIndex + myHeight) - 1;		
}


/**/
- (void) addString: (char *) aString
{
	THROW_NULL( aString );

	[self addItem: [String str: aString]];
}

/**/
- (void) removeIndex: (int) anIndex
{
	id obj;

	if (anIndex < 0 || anIndex >= [myItems size])
		THROW( UI_INDEX_OUT_OF_RANGE_EX );
	
		
	obj = [myItems at: anIndex];		
	
	if (myOwnObjects)
		[obj free];
		
	[myItems removeAt: anIndex];	
			
	if (myItemIndex >= [myItems size])	
		myItemIndex = [myItems size] - 1;
	
	if ([myItems size] == 0) {
		myItemIndex = -1;
		myVisibleOnTopItem = -1;	
		myVisibleOnBottomItem = -1;		
	}	 else {
	
		if (myVisibleOnBottomItem == [myItems size])
			myVisibleOnBottomItem--;		
			
		if (myVisibleOnBottomItem - myVisibleOnTopItem < myHeight - 1 && myVisibleOnTopItem > 0)
			myVisibleOnTopItem--;	
	
	}
		
	[self paintComponent];
}


/**/
- (void) removeItem: (id) anObject
{
	int index;
	
	for (index = 0; index < [myItems size]; index++)
		if ([myItems at: index] == anObject) 
			break;
	
	if (index == [myItems size])
		THROW( UI_INDEX_OUT_OF_RANGE_EX );
	
	[self removeIndex: index];
}


@end

