#include <stdio.h>
#include <assert.h>
#include <ctype.h>
#include <limits.h>

#include "util.h"
#include "InputKeyboardManager.h"
#include "UserInterfaceExcepts.h"
#include "JText.h"

//#define printd(args...) doLog(args)
#define printd(args...)


/** @todo en setNumericMode() configurar el teclado para que soloreciba 
						numeros o para que reciba alfanumericos 
*/ 

@implementation  JText

/**/
- (void) initComponent
{
 [super initComponent];

	myText[0] = '\0';
	myFirstVisibleChar = 0;
	myCurrentPosition = 0;

	myMaxLen = sizeof(myText) - 1;
	
	myMinValue = LONG_MIN;
 	myMaxValue = LONG_MAX;

	myIsPasswordMode = FALSE;
	myIsMandatoryMode = FALSE;
	myIsNumericMode = FALSE;
	myIsAlphaNumericLoginMode = FALSE;
	myNumericType = JTextNumericType_NORMAL;

	myCanFocus = TRUE;
	
	myIsNewPosition = TRUE;
}

/**/
- (void) setMaxLen: (int) aValue 
{ 
		if (myMaxLen > sizeof(myText) - 1)
			THROW( UI_INDEX_OUT_OF_RANGE_EX );
			
		myMaxLen = aValue; 
}
- (int) getMaxLen { return myMaxLen; }

/**/
- (void) setMinNumericValue: (long) aValue { myMinValue = aValue; }
- (long) getMinNumericValue { return myMinValue; }

/**/
- (void) setMaxNumericValue: (long) aValue { myMaxValue = aValue; }
- (long) getMaxNumericValue { return myMaxValue; }

/**/
- (void) setPasswordMode: (BOOL) aValue { myIsPasswordMode = aValue; }
- (BOOL) isPasswordMode { return myIsPasswordMode; }

/**/
- (void) setMandatoryMode: (BOOL) aValue { myIsMandatoryMode = aValue; }
- (BOOL) isMandatoryMode { return myIsMandatoryMode; }


/**/
- (void) setFullMandatoryMode: (BOOL) aValue { myIsFullMandatoryMode = aValue; }
- (BOOL) isFullMandatoryMode { return myIsFullMandatoryMode; }


/**/
- (void) setNumericMode: (BOOL) aValue { myIsNumericMode = aValue; }
- (BOOL) isNumericMode { return myIsNumericMode; }

/**/
- (void) setAlphaNumericLoginMode: (BOOL) aValue { myIsAlphaNumericLoginMode = aValue; }

/**/
- (void) setNumericType: (JTextNumericType) aValue
{
	myNumericType = aValue;
	[self setNumericMode: TRUE];
}

/**/
- (JTextNumericType) getNumericType
{
	return myNumericType;
}

/**/
- (void) setText: (char *) aText
{
	
  stringcpy(myText, aText);

	myText[myMaxLen] = '\0';
	myCurrentPosition = strlen(myText);
	if (myCurrentPosition == myMaxLen) 
    myCurrentPosition--;

  if ( myCurrentPosition == myWidth )
    myCurrentPosition--;
    
	[self executeOnChangeAction];
	
	[self paintComponent];
}

/**/
- (char *) getText
{
	return myText;
}

/**/
- (void) setIntegerValue: (int) aValue
{
	snprintf(myText, sizeof(myText) - 1, "%d", aValue);
	[self executeOnChangeAction];
}

/**/
- (int) getIntegerValue
{
	return atoi(myText);
}

/**/
- (void) setLongValue: (long) aValue
{
  snprintf(myText, sizeof(myText) - 1, "%ld", aValue);
	[self executeOnChangeAction];
}

/**/
- (long) getLongValue
{
	return atol(myText);
}

/**/
- (int) mapXPosition: (int) aPos
{
	//assert(myWidth > 0);
	if (myWidth == 0) return 0;
	return aPos % myWidth;
}

/**/
- (int) mapYPosition: (int) aPos
{
	assert(myHeight > 0);
	if (myWidth == 0) return 0;
	return aPos / myWidth;
}

/**/
- (void) doDraw: (JGRAPHIC_CONTEXT) aGraphicContext
{
	int len, usedLen;
  char auxText[255];
  
	assert(aGraphicContext != NULL);

  
	len = [self getComponentArea];
  
  strcpy(auxText, "");
  
  if (![self isVisible] ) {

		memset(auxText, ' ', len);
		auxText[len] = '\0';

    [aGraphicContext printString: auxText
									atPosX: myXPosition + [self mapXPosition: 0] 
									atPosY: myYPosition + [self mapYPosition: 0]];
    return;
    
  }
  
	usedLen = strlen(myText);
	if (usedLen > myMaxLen)
		THROW( UI_VALUE_TOO_BIG_EX );


	/* Prints the current value of the control */
	if (myIsPasswordMode) {
		memset(auxText, JComponent_PASSWORD_CHAR, usedLen);
		auxText[usedLen] = '\0';
	} else {
		strcpy(auxText, &myText[myFirstVisibleChar]);
	}

	if (!myReadOnly) {
		memset(&auxText[usedLen], JComponent_FILL_CHAR, len - usedLen);
		auxText[len] = '\0';
	}

	[aGraphicContext printString: auxText
									atPosX: myXPosition + [self mapXPosition: 0] 
									atPosY: myYPosition + [self mapYPosition: 0]];

/*  for (i = 0, string = &myText[myFirstVisibleChar]; *string != '\0' && i < len; i++, string++)
        
       [aGraphicContext printChar: myIsPasswordMode ? JComponent_PASSWORD_CHAR : *string
									atPosX: myXPosition + [self mapXPosition: i] 
									atPosY: myYPosition + [self mapYPosition: i]];
	*/
	/* Prints aditional underscore to fill the size */
/*	if (!myReadOnly) 
		for ( ; i < len; i++ )						
	 		[aGraphicContext printChar: JComponent_FILL_CHAR
												atPosX: myXPosition + [self mapXPosition: i] 
												atPosY: myYPosition + [self mapYPosition: i]];
*/
}

/**/
- (void) doDrawCursor: (JGRAPHIC_CONTEXT) aGraphicContext
{
	int pos;
	
	assert(aGraphicContext != NULL);
	
	if (myReadOnly) 
		return;
		
  pos = myCurrentPosition;
  
	[aGraphicContext blinkCursorAtPosX: myXPosition + [self mapXPosition: pos]
																		atPosY: myYPosition + [self mapYPosition: pos]];
}

/**/
- (BOOL) doKeyPressed: (int) aKey isKeyPressed: (BOOL) isPressed
{
	int result;

	if (myReadOnly)
		return FALSE;

	result = FALSE;
	
	switch (aKey) {	 
	 
	 			case JComponent_TAB:										/* TAB */
	
								if (!myReadOnly)
									[self validateComponent];
									
								result = FALSE;
								break;		
	 
				case JComponent_SHIFT_TAB:				 			/* SHIFT TAB */
	
								if (!myReadOnly)
									[self validateComponent];
									
								result = FALSE;
								break;		
			
				case 	JText_KEY_LEFT:									/* Cursor izquierda */
											
								result = [self setLeftKeyPressed];
								break;
		
			case JText_KEY_RIGHT:									/* Cursor derecha */
			case JText_XLATE_SPECIAL_KEY:
									
								result = [self setRightKeyPressed];
								break;
		
			case JText_KEY_DELETE:							/* Delete */
								
								result = [self setDeleteKeyPressed];								
								break;

			case '^':														/* Cambio el case */
								[[InputKeyboardManager getInstance] invertCaseMode];
								result = TRUE;
								break;

			case UserInterfaceDefs_KEY_FNC_2:								
								return FALSE;
								
			case UserInterfaceDefs_KEY_MANUAL_DROP:								
								return FALSE;
                
			case UserInterfaceDefs_KEY_DEPOSIT:								
								return FALSE;
                
			case UserInterfaceDefs_KEY_REPORTS:								
								return FALSE;
                
			case UserInterfaceDefs_KEY_VALIDATED_DROP:								
								return FALSE;                                          								

			default:
								result = [self setNewKeyPressed: aKey];
								break;
			}
	
		[self setNewCursorPosition];
					
		return result;
}

/**/
- (void ) setNewCursorPosition
{
		int area = [self getComponentArea];
    
		/* cuando va para atras al principio de la ultima linea */
		if (myCurrentPosition < myFirstVisibleChar) 
      myFirstVisibleChar = myCurrentPosition;
		
		/* esto se da al agregar un char al final de la ultima linea */
		else if (myCurrentPosition > myFirstVisibleChar + [self getComponentArea])  
            myFirstVisibleChar = myCurrentPosition - area;
		
    /* esto se da cuando elimina un caracter y esta al principio de la primer linea y 
		   hay mas chars a la izquierda*/
		else if (myFirstVisibleChar > 0 && myText[myFirstVisibleChar] == '\0') {
            myFirstVisibleChar--;
						myCurrentPosition--;
		}		
    /*if (myCurrentPosition == myMaxLen)
			myCurrentPosition--;*/
		
    if (myCurrentPosition == myMaxLen) 
      myCurrentPosition--;			
      
    /* Alexia Se agrego esta parte ya que sino, cuando llegaba al limite del texto el
       cursor se iba de los limtes.*/
    if (myCurrentPosition == [self getComponentArea]) 
      myCurrentPosition = [self getComponentArea] - 1;
    
}


/**/
- (BOOL) setDeleteKeyPressed
{
	int tlen, area;
	
	myIsNewPosition = TRUE;
	
	/* Desplaza toda la cadena a izquierda */
	tlen = strlen(myText);
	area = [self getComponentArea];
	
	if (myCurrentPosition < tlen - 1) {
		memmove(myText + myCurrentPosition, myText + myCurrentPosition + 1, 
																												tlen - myCurrentPosition);
	
	} else {
		
		if (myText[myCurrentPosition] == '\0' && myCurrentPosition > 0) 
      myCurrentPosition--;
			
		myText[myCurrentPosition] = '\0';
	}
	
	myText[sizeof(myText) - 1] = '\0';	

	[self executeOnChangeAction];

	return TRUE;
}

/**/
- (BOOL) setNewKeyPressed: (unsigned char) aKey
{
	int tlen, area;
  
	/*
	if (!isprint(aKey) || (myIsNumericMode && !isdigit(aKey)))
		return FALSE;	
	*/

	area = [self getComponentArea];

	if (aKey < ' ' || (myIsNumericMode && myNumericType == JTextNumericType_NORMAL && !isdigit(aKey)))
		return FALSE;

	tlen = strlen(myText);

  /********************************************************************************
    Alexia: Se comento ya que de otra manera si se tenia por ejemplo:
    21 en un edit text, y uno se paraba en la primera posicion y presionaba
    un 3 me corria todo a la derecha, es decir me quedaba 32. En cambio se decidio
    sobreescribir el numero y no pasarlo a la derecha solo si es numeric mode.
   *********************************************************************************/

	if ( (myCurrentPosition < tlen - 1 && myIsNewPosition) && !(myIsNumericMode) )  {
		memmove(myText + myCurrentPosition + 1, 
						myText + myCurrentPosition,
						tlen - myCurrentPosition + 1);
		myText[myCurrentPosition + 1] = myText[myCurrentPosition];
	}	

	myText[myCurrentPosition] = aKey;
	myText[myMaxLen] = '\0';
	myText[area] = '\0';
	myIsNewPosition = FALSE;

	/** si es modo numerico pasa directo al caracter de al lado */
	if (myIsNumericMode)
		[self setRightKeyPressed];

	[self executeOnChangeAction];

	return TRUE;
}


/**/
- (BOOL) setRightKeyPressed
{
  /* Alexia Se agrego esta linea, para que no sume 1 si llego al limite del tamano del 
            componente */
	if ( (myCurrentPosition < strlen(myText)) && (myCurrentPosition < [self getComponentArea]) ) 
      myCurrentPosition++;	

      
	myIsNewPosition = TRUE;
	return TRUE;
}

/**/
- (BOOL) setLeftKeyPressed
{				
	if (myCurrentPosition > 0) 
    myCurrentPosition--;
		
	myIsNewPosition = TRUE;
	return TRUE;
}
				

/**/
- (void) doFocus
{
	[super doFocus];

	if (myIsNumericMode) {

		if (myNumericType == JTextNumericType_MODEM_PHONE)
			[[InputKeyboardManager getInstance] setNumericModemPhoneMode];

		else if (myNumericType == JTextNumericType_PHONE)
			[[InputKeyboardManager getInstance] setNumericPhoneMode];
      
    else if (myNumericType == JTextNumericType_IP)
      [[InputKeyboardManager getInstance] setNumericIPMode];

    else if (myNumericType == JTextNumericType_CODE)
      [[InputKeyboardManager getInstance] setNumericCodeMode];

		else [[InputKeyboardManager getInstance] setNumericMode];
		
	} else {
		if (!myIsAlphaNumericLoginMode)
			[[InputKeyboardManager getInstance] setAlphaNumericMode];
		else [[InputKeyboardManager getInstance] setAlphaNumericLoginMode];
	}

}


/**/
- (void) doValidate
{
	int value;

	/* Controls the min and max value */
	if (myIsNumericMode) {
		value = atol(myText);
		if (value > myMaxValue) THROW( UI_MAX_VALUE_EX );
		if (value < myMinValue) THROW( UI_MIN_VALUE_EX );
	}

	if (myIsMandatoryMode && strlen(myText) == 0)
		THROW( UI_NULL_VALUE_EX );

	if (myIsFullMandatoryMode && strlen(myText) != myWidth )
		THROW( UI_NULL_VALUE_EX );
}

@end

