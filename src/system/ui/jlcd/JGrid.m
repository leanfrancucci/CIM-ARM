#include <assert.h>
#include <ctype.h>
#include "util.h"

#include "UserInterfaceExcepts.h"
#include "InputKeyboardManager.h"
#include "JGrid.h"
#include "ordcltn.h"

//#define printd(args...) doLog(args)
#define printd(args...)

#define JGrid_MSECS_TO_PRESS_KEY 		750

@implementation  JGrid

/**/
- (void) initComponent
{
 [super initComponent];
 
	myOwnObjects = TRUE;
	myCanFocus = TRUE;
  myPaintObjectString = TRUE;

	myItems = [OrdCltn new];
  myStringItems = [Collection new];
	assert(myItems != NULL);
	
	myItemIndex = -1;

	myVisibleOnTopItem = -1;
	myVisibleOnBottomItem = -1; 
	myShowItemNumber = FALSE;

  myLastKeyPressedTime = 0;
  myIndexPressed = 0;
}

/**/
- free
{
	if (myOwnObjects)
		[myItems freeContents];

	[myItems free];
  
  [myStringItems free];

	return [super free];
}

/**/
- (void) setOwnObjects: (BOOL) anOwnObjects { myOwnObjects = anOwnObjects; }
- (BOOL) getOwnObjects { return myOwnObjects; }


/**/
- (void) doDraw: (JGRAPHIC_CONTEXT) aGraphicContext
{
	int index;
  //char objCaption[JComponent_MAX_LEN + 1];
	//char caption[JComponent_MAX_LEN + 1];
	// se cambio el largo maximo para que las descripcion no baje de linea.
  char objCaption[JComponent_MAX_WIDTH];
	char caption[JComponent_MAX_WIDTH];	
	

	if (myVisibleOnTopItem == -1 || myVisibleOnBottomItem == -1)
		return;
  
	for (index = myVisibleOnTopItem; index <= myVisibleOnBottomItem; index++) {
		/* Imprime el item */
		if ([myItems at: index] != NULL) {
      
      // Toma el caption de donde corresponde, segun configuracion. Puede tomarlo del mismo objeto o
      // del indice correspondiente de la lista de objectos caption.
      if (( myPaintObjectString ) || (index == 0 ))
        stringcpy(objCaption, [[myItems at: index] str]);
      else {
        assert( [myStringItems at: index - 1] );
        stringcpy(objCaption, [[myStringItems at: index - 1] str]);
      }        

			//
			if (myShowItemNumber) {
				sprintf(caption, "%02d.%-16s", index + 1, objCaption);
			} else {
  			sprintf(caption, "%-19s", objCaption);
			}

			//
/*      [aGraphicContext printString: 
									alignString(auxCaption, caption, myWidth-1, UTIL_AlignLeft) 
																						atPosX: myXPosition + 1
																						atPosY: myYPosition + index - myVisibleOnTopItem];
  
	*/		
			[aGraphicContext printString: caption atPosX: myXPosition + 1
																						atPosY: myYPosition + index - myVisibleOnTopItem];

		}
		/* El seleccionado */
		if (index == myItemIndex) 
			[aGraphicContext printChar: JGrid_SEL_ITEM
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
	
	[aGraphicContext setBlinkCursor: FALSE];
}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) isPressed
{
	int itemCount;
	unsigned long ticks;

	itemCount = [myItems size];
	
	if (myReadOnly || itemCount == 0)
		return FALSE;

	switch (aKey) {

		/* Muetra la opcion anterior */
		case JGrid_KEY_UP:
			
			myLastKeyPressedTime = 0;
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
		case JGrid_KEY_DOWN:
			
			myLastKeyPressedTime = 0;
		 	if (itemCount > 0 && myItemIndex < itemCount - 1) {

				if (myVisibleOnBottomItem == myItemIndex) {
					myVisibleOnTopItem++;
					myVisibleOnBottomItem++;					
				}

				myItemIndex++;
    			[self executeOnSelectAction];
			}

			return TRUE;
		
		case JGrid_KEY_ENTER:

			myLastKeyPressedTime = 0;
			/* Si no tiene definido el evento sale sin procesar la tecla */
			if (myOnClickActionObject == NULL)
				return FALSE;
	
			if (myItemIndex >= 0)
				[self executeOnClickAction];

			return TRUE;		

		default:

			if (!myShowItemNumber) return FALSE;

			if (isdigit(aKey) || aKey == JComponent_KEY_PLUS_10) { 

				ticks = getTicks();
									
				if ( ticks - myLastKeyPressedTime >= JGrid_MSECS_TO_PRESS_KEY) {
					myLastKeyPressedTime = 0;
					myIndexPressed = 0;
				}
		
				if (aKey == JComponent_KEY_PLUS_10) {

					myLastKeyPressedTime = getTicks();
					myIndexPressed = myIndexPressed + 10;
					return TRUE;

				} else {

					myIndexPressed = myIndexPressed + (aKey - '0');
					myLastKeyPressedTime = 0;

				}
																											
				/* Si se va de rango resetea el contador de tiempo */
				if (myIndexPressed < 1 || myIndexPressed > itemCount)
					myLastKeyPressedTime = 0;
				else {
					[self setSelectedIndex: myIndexPressed - 1];
    			[self executeOnSelectAction];
				}

				return TRUE;

			}

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
		/** @todo: comentado por Julian Yerfino el dia 22-06-07 porque no bajaba bien si el height era 2 */
/*		myVisibleOnTopItem = myItemIndex;
		myVisibleOnBottomItem = min([myItems size], myVisibleOnTopItem + myHeight) - 1;	
*/
		myVisibleOnTopItem = myItemIndex;
		myVisibleOnBottomItem = min([myItems size], myVisibleOnTopItem + myHeight) - 1;	
		if (myVisibleOnBottomItem - myVisibleOnTopItem + 1 < myHeight && myVisibleOnTopItem > 0) {
				myVisibleOnTopItem = myVisibleOnBottomItem - myHeight + 1;
		}
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

	myVisibleOnTopItem = -1;
	myVisibleOnBottomItem = -1; 
	
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
- (void) setString: (char *) aString index: (int) anIndex
{
	[[myItems at: anIndex] assignSTR: aString];
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
  
  
  if ( !myPaintObjectString) 
    [myStringItems removeAt: anIndex -1];
    
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

/**/
- (COLLECTION) getItemsCollection
{
  return myItems;
}

/**/ 
- (void) setItemIndex: (int) aValue
{
  myItemIndex = aValue;
}

/**/
- (void) addStringItem: (char*) aStringItem
{
	THROW_NULL( aStringItem );
  [myStringItems add: [String str: aStringItem]];
}

/**/
- (void) setPaintObjectString: (BOOL) aValue
{
  myPaintObjectString = aValue;
}

/**/
- (void) removeStringItems
{
  int i;
  
  for (i = 0; i < [myStringItems size]; i++) 
		[[myStringItems at: i] free];		
}

/**/
- (void) setShowItemNumber: (BOOL) aValue
{
	myShowItemNumber = aValue;
}

/**/
- (void) doFocus
{
	[super doFocus];

	[[InputKeyboardManager getInstance] setNumericMode];
}

@end

