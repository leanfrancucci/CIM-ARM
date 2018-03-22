#include <assert.h>
#include "util.h"

#include "UserInterfaceExcepts.h"
#include "JCheckBoxList.h"
#include "ordcltn.h"
#include "JCheckBox.h"

//#define printd(args...) doLog(args)
#define printd(args...)


@implementation  JCheckBoxList

/**/
- (void) initComponent
{
 [super initComponent];
 
//	myOwnObjects = TRUE;
	myCanFocus = TRUE;

	myCheckBoxCollection = [OrdCltn new];
	assert(myCheckBoxCollection != NULL);
	
	myItemIndex = -1;

	myVisibleOnTopItem = -1;
	myVisibleOnBottomItem = -1; 
  myCheckBoxListMode = JCheckBoxList_VIEW; 
}

/**/
- free
{
	if (myOwnObjects)
		[myCheckBoxCollection freeContents];

	[myCheckBoxCollection free];

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
    
    [[myCheckBoxCollection at: index] setYPosition: myYPosition + index - myVisibleOnTopItem];
    [[myCheckBoxCollection at: index] setXPosition: myXPosition + 2];
    [[myCheckBoxCollection at: index] doDraw: aGraphicContext];
  
		/* Imprime el item */
    if ([myCheckBoxCollection at: index] != NULL)
			[aGraphicContext printString: 
									alignString(auxCaption, [[myCheckBoxCollection at: index] getCaption], myWidth - 1, UTIL_AlignLeft) 
																						atPosX: myXPosition + 4
																						atPosY: myYPosition + index - myVisibleOnTopItem];
		
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

	itemCount = [myCheckBoxCollection size];
  	
	if (itemCount == 0) return FALSE;

	switch (aKey) {

		/* Muetra la opcion anterior */
		case JCheckBoxList_KEY_UP:
			if (myItemIndex > 0) {

				if (myVisibleOnTopItem == myItemIndex) {					
					myVisibleOnTopItem--;
					myVisibleOnBottomItem--;
				}

				myItemIndex--;
				[self executeOnSelectAction];
        return TRUE;
			} else return FALSE;

			

		/* Muetra la opcion siguiente */
		case JCheckBoxList_KEY_DOWN:
    
		 	if (itemCount > 0 && myItemIndex < itemCount - 1) {

				if (myVisibleOnBottomItem == myItemIndex) {
					myVisibleOnTopItem++;
					myVisibleOnBottomItem++;					
				}

				myItemIndex++;
    			[self executeOnSelectAction];
          return TRUE;
			} else return FALSE;
      

		case JCheckBoxList_KEY_ENTER:
      
      if (myItemIndex < 0)
        return FALSE;
      
      if (!myReadOnly) {
        [[myCheckBoxCollection at: myItemIndex] setYPosition: myYPosition + myItemIndex - myVisibleOnTopItem];
        [[myCheckBoxCollection at: myItemIndex] setXPosition: myXPosition + 2];
        [[myCheckBoxCollection at: myItemIndex] doKeyPressed: JCheckBoxList_KEY_ENTER isKeyPressed: TRUE];
        return TRUE;        
      }

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
- (void) setSelectedCheckBoxIndex: (int) anIndex
{
 	/* throws an exceptions if the value is invalid */
	if (anIndex < 0 || anIndex > [myCheckBoxCollection size] - 1)
		THROW( UI_INDEX_OUT_OF_RANGE_EX );

	myItemIndex = anIndex;

	/* Ubica el cursor adecuadamente */
	if (myItemIndex >= myVisibleOnTopItem && myItemIndex <= myVisibleOnBottomItem)
		return;

	/* si es el ultimo elemento el seleccionado se ubica abajo de la lista,
	   si no se ubica arriba de la lista */
	if (myItemIndex == [myCheckBoxCollection size] - 1)	{					
		myVisibleOnBottomItem = myItemIndex;
		myVisibleOnTopItem = max(0, myVisibleOnBottomItem - myHeight + 1) ;		
	} else {
		myVisibleOnTopItem = myItemIndex;
		myVisibleOnBottomItem = min([myCheckBoxCollection size], myVisibleOnTopItem + myHeight) - 1;	
	}
}

/**/
- (int) getSelectedCheckBoxIndex
{
	return myItemIndex;
}

/**/
- (void) setSelectedCheckBoxItem: (id) anObject
{
	int i;

	for (i = 0; i < [myCheckBoxCollection size]; i++)
		if ([myCheckBoxCollection at: i] == anObject) {
			[self setSelectedCheckBoxIndex: i];
			return;
		}
	THROW( UI_INDEX_OUT_OF_RANGE_EX );
}

/**/
- (id) getSelectedCheckBoxItem
{
	if (myItemIndex < 0)
		return NULL;

	return [myCheckBoxCollection at: myItemIndex];
}

/**/
- (void) clearItems
{
	int i;
	id obj;

	for (i = 0; i < [myCheckBoxCollection size]; i++) {
		obj = [myCheckBoxCollection at: i];		
		if (myOwnObjects)
			[obj free];		
		[myCheckBoxCollection remove: i];
	}
	myItemIndex = -1;
}

/**/
- (void) addCheckBoxFromCollection: (COLLECTION) aCollection
{
	/* buscar el metodo para agregarlos de una sola vez */
	int i;

	THROW_NULL( aCollection );

	for (i = 0; i < [aCollection size]; i++)
		[self addCheckBoxItem: [aCollection at: i]];
}


/**/
- (void) addCheckBoxItem: (id) anObject
{
	THROW_NULL( anObject );

	[myCheckBoxCollection add: anObject];

	if (myItemIndex == -1) {
		[self setSelectedCheckBoxIndex: 0];
		myVisibleOnTopItem =  myItemIndex;
	}

	myVisibleOnBottomItem = min([myCheckBoxCollection  size], myItemIndex + myHeight) - 1;	
}


/**/
- (void) removeCheckBoxIndex: (int) anIndex
{
	id obj;

	if (anIndex < 0 || anIndex >= [myCheckBoxCollection size])
		THROW( UI_INDEX_OUT_OF_RANGE_EX );
	
		
	obj = [myCheckBoxCollection at: anIndex];		
	
	if (myOwnObjects)
		[obj free];
		
	[myCheckBoxCollection removeAt: anIndex];	
			
	if (myItemIndex >= [myCheckBoxCollection size])	
		myItemIndex = [myCheckBoxCollection size] - 1;
	
	if ([myCheckBoxCollection size] == 0) {
		myItemIndex = -1;
		myVisibleOnTopItem = -1;	
		myVisibleOnBottomItem = -1;		
	}	 else {
	
		if (myVisibleOnBottomItem == [myCheckBoxCollection size])
			myVisibleOnBottomItem--;		
			
		if (myVisibleOnBottomItem - myVisibleOnTopItem < myHeight - 1 && myVisibleOnTopItem > 0)
			myVisibleOnTopItem--;	
	
	}
		
	[self paintComponent];
}


/**/
- (void) removeCheckBoxItem: (id) anObject
{
	int index;
	
	for (index = 0; index < [myCheckBoxCollection size]; index++)
		if ([myCheckBoxCollection at: index] == anObject) 
			break;
	
	if (index == [myCheckBoxCollection size])
		THROW( UI_INDEX_OUT_OF_RANGE_EX );
	
	[self removeCheckBoxIndex: index];
}

/**/
- (COLLECTION) getCheckBoxItemsCollection 
{
  return myCheckBoxCollection;
}

/**/
- (BOOL) hasAnyElementChecked
{
  int i;
  
  for (i=0; i<[myCheckBoxCollection size]; ++i)
    if ( [[myCheckBoxCollection at: i] isChecked] ) return TRUE;
  
  return FALSE;
}

@end

