/*
 *	$Log: JCombo.m,v $
 *	Revision 1.2  2009-02-16 19:06:12  yerfino
 *	*** empty log message ***
 *
 *	Revision 1.1  2007/05/08 15:33:39  yerfino
 *	Primer commit de la carpeta system
 *	
 *	Revision 1.17  2005/12/06 19:34:25  delfino
 *	*** empty log message ***
 *	
 *	Revision 1.16  2005/01/31 14:42:18  yerfino
 *	Se arreglo un error en el clearItems() y clearAllItems().
 *	
 *	Revision 1.15  2005/01/18 17:54:14  delfino
 *	*** empty log message ***
 *	
 *	Revision 1.14  2005/01/11 13:30:25  delfino
 *	*** empty log message ***
 *	
 *	Revision 1.13  2004/12/20 12:55:06  yerfino
 *	*** empty log message ***
 *	
 *	Revision 1.12  2004/11/13 12:20:50  vazquezger
 *	*** empty log message ***
 *	
 *	Revision 1.11  2004/11/12 19:32:35  vazquezger
 *	*** empty log message ***
 *	
 *	Revision 1.10  2004/11/12 19:31:56  vazquezger
 *	*** empty log message ***
 *	
 *	Revision 1.9  2004/11/10 16:06:57  yerfino
 *	Se modifico el componente para que fuera circular.
 *	
 */
 
#include <assert.h>
#include "util.h"

#include "UserInterfaceExcepts.h"
#include "JCombo.h"
#include "ordcltn.h"

//#define printd(args...) doLog(args)
#define printd(args...)


@implementation  JCombo

/**/
- (void) initComponent
{
 [super initComponent];
 
	myOwnObjects = FALSE;
	myCanFocus = TRUE;
	myItemIndex = -1;

	myItems = [OrdCltn new];
	assert(myItems);	 
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
	id obj;
	char *itemString;

  assert(aGraphicContext != NULL);

	obj = [self getSelectedItem];
	if (obj != NULL) {	
		itemString = [obj str];
		if (itemString == NULL)
			myText[0] = '\0';
		else {
			alignString(myText, itemString, myWidth - 1,  UTIL_AlignLeft);
			if (myWidth > 2)
				myText[myWidth - 2] = '\0';
		}
	} else
		myText[0] = '\0';
	
		
    /*Alexia Se comento esta parte ya que cuando se aceptaba aparecia un mensaje de confirmacion, 
             si al mismo se le respondia que no, no dibujaba los corchetes, ya que no lo ponia en foco
            nuevamnete. */
            
  /* Imprime el item */	            
	//if ([self isFocused]) {
		
    [aGraphicContext printString: myText atPosX: myXPosition + 1 atPosY: myYPosition];
  
		/* Encierra entre corchetes si esta en foco y editando */
		[aGraphicContext printChar: '[' atPosX: myXPosition atPosY: myYPosition];
		[aGraphicContext printChar: ']' atPosX: myXPosition + myWidth - 2 atPosY: myYPosition];
				
		[aGraphicContext printChar: JComponent_DOWN_ARROW_CHAR
													atPosX: myXPosition + myWidth -1 atPosY: myYPosition];		
	//} else 		{

		//[aGraphicContext printString: myText atPosX: myXPosition + 1 atPosY: myYPosition];
	//}
}

/**/
- (void) doDrawCursor: (JGRAPHIC_CONTEXT) aGraphicContext
{
	assert(aGraphicContext != NULL);

	if (myReadOnly) 
		return;
    
	[aGraphicContext blinkCursorAtPosX: myXPosition + myWidth - 1 atPosY: myYPosition];
  
}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) isPressed
{
	int itemCount;

	itemCount = [myItems size];

	if (myReadOnly) return FALSE;

	switch (aKey) {

		/* Muetra la opcion siguiente */
		case JCombo_KEY_RIGHT:

			if (itemCount == 0) return TRUE;
			
			myItemIndex = (myItemIndex+1) % itemCount;
			[self executeOnSelectAction];
			return TRUE;

		/* Muetra la opcion anterior */
		case JCombo_KEY_LEFT:

			if (itemCount == 0) return TRUE;
			
			if (myItemIndex == 0) myItemIndex = itemCount;
			myItemIndex = (myItemIndex-1) % itemCount;
			[self executeOnSelectAction];
			return TRUE;


		case JCombo_KEY_ENTER:

			/* Si no tiene definido el evento sale sin procesar la tecla */
			if (myOnClickActionObject == NULL)
				return FALSE;
				
			if (myItemIndex > 0)
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
- (void) clearAllItems
{
	int i;
	id obj;
	int count = [myItems size];
	  
	for (i = 0; i < count; i++) {
		obj = [myItems at: 0];
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
	
	if (myItemIndex == -1)
		[self setSelectedIndex: 0];
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

	// @@todo Revisar el removeItem del JCombo
	printd("@@todo Revisar el removeItem del JCombo\n");
	
	if (anIndex < 0 || anIndex >= [myItems size])
		THROW( UI_INDEX_OUT_OF_RANGE_EX );
	
	obj = [myItems at: anIndex];		
	
	if (myOwnObjects)
		[obj free];
		
	[myItems removeAt: anIndex];
	
	if (myItemIndex >= [myItems size])	
		myItemIndex = [myItems size] - 1;

	if ([myItems size] == 0)
		myItemIndex = -1;	
	
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
- (COLLECTION) getItems
{
  return myItems;
} 

@end

