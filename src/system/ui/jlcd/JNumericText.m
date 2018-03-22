#include <stdio.h>
#include <assert.h>
#include <ctype.h>
#include <limits.h>
#include <math.h>

#include "util.h"
#include "UserInterfaceExcepts.h"
#include "InputKeyboardManager.h"
#include "JNumericText.h"

//#define printd(args...) doLog(args)
#define printd(args...)

@implementation  JNumericText


/**/
- (void) initComponent
{
 [super initComponent];

	myValue = 0;
		
	myMinDoubleValue = (double)LONG_MIN;
 	myMaxDoubleValue = (double)LONG_MAX;
	
	myDecimalDigits = JNumericText_DEFAULT_DECIMAL_DIGITS;
	myDecimalSeparator = JNumericText_DEFAULT_DECIMAL_SEPARATOR;
	
	myCanFocus = TRUE;
	
	myIsNumericMode = TRUE;
        
        strncpy(myValuePrefix, "", sizeof(myValuePrefix));
}

/**/
- (void) setWidth: (int) aWidth
{
	[super setWidth: aWidth];
	[self setNewCursorPosition];
	[self paintComponent];
}

/**/
- (void) setHeight: (int) aHeight
{
	[super setHeight: aHeight];
	[self setNewCursorPosition];
	[self paintComponent];
}


/**/
- (void) setMinValueAsDouble: (double) aValue { myMinDoubleValue = aValue; }
- (double) getMinValueAsDouble { return myMinDoubleValue; }

/**/
- (void) setMaxValueAsDouble: (double) aValue { myMaxDoubleValue = aValue; }
- (double) getMaxValueAsDouble { return myMaxDoubleValue; }

/**/
- (void) setDecimalDigits: (int) aValue { myDecimalDigits = aValue; }
- (int) getDecimalDigits { return myDecimalDigits; }


/**/
- (void) setDecimalSeparator: (char) aValue { myDecimalSeparator = aValue; }
- (char) getDecimalSeparator { return myDecimalSeparator; }


/**/
- (void) setIntegerValue: (int) aValue
{
	myValue = (long long)  aValue;
	
	[self configureTextValue];
	[self paintComponent];
}

/**/
- (int) getIntegerValue
{
	return (int) myValue;
}

/**/
- (void) setLongValue: (long) aValue
{
	myValue = aValue;
	
	[self configureTextValue];
	[self paintComponent];
}

/**/
- (long) getLongValue
{
	return myValue;
}

/**/
- (void) setFloatValue: (float) aValue
{ 	
 	myValue = (long long ) (aValue * pow(10, myDecimalDigits));
	
	[self configureTextValue];
	[self paintComponent];
}

/**/
- (float) getFloatValue
{
	return (float) myValue / pow(10, myDecimalDigits);
}
/**/
- (void) setDoubleValue: (double) aValue
{	
 	myValue = (long long ) (aValue * pow(10, myDecimalDigits));
	
	[self configureTextValue];
	[self paintComponent];
	
}

/**/
- (void) setMoneyValue: (money_t) aValue
{
	myValue = (long long ) (aValue / pow(10, MONEY_DECIMAL_DIGITS - myDecimalDigits));
	[self configureTextValue];
	[self paintComponent];
}

/**/
- (money_t) getMoneyValue
{
	money_t value;
	value = (myValue * pow(10, MONEY_DECIMAL_DIGITS - myDecimalDigits));
	return value;
}

/**/
- (double) getDoubleValue
{
	return (double) myValue / pow(10, myDecimalDigits);
}

/**/
- (void) configureTextValue
{		
	char sdecimal[10];
	int i, len, area;
	long long intValue, decValue;
  char auxText[ JText_MAX_LEN + 1 ];
																
	area = [self getComponentArea];
        
	/* Parte entera */
	intValue = (long long)(myValue / (int)pow(10, myDecimalDigits));
	snprintf(auxText, sizeof(auxText) - 1, "%lld", intValue);
	
	/* Parte decimal */
	decValue = (long long)(myValue % (int)pow(10, myDecimalDigits));
	snprintf(sdecimal, sizeof(sdecimal) - 1, "%lld", decValue);
	
	if (myDecimalDigits > 0) {
		len = strlen(auxText);
		auxText[len] = myDecimalSeparator; 
		auxText[len + 1] = '\0';
		
		for (i = 0; i < myDecimalDigits - strlen(sdecimal); i++) 
			strcat(auxText, "0");
		
		strcat(auxText, sdecimal);
	}	

	/* el prefijo */
	if (strlen(auxText) + strlen(myValuePrefix) > JText_MAX_LEN)
		stringcpy(myText, auxText);
	else {	
		strcpy(myText, myValuePrefix);
		strcat(myText, auxText);
	}
	
	[self setNewCursorPosition];

}

   /**/
- (void) doDraw: (JGRAPHIC_CONTEXT) aGraphicContext
{	
	int i;
	int area;
		
	assert(aGraphicContext != NULL);
	
	area = [self getComponentArea];
	for (i = 0; i < area; i++) 
			[aGraphicContext printChar: myReadOnly ? ' ' : JComponent_FILL_CHAR 
			 atPosX: myXPosition + [self mapXPosition: i] 
			 atPosY: myYPosition + [self mapYPosition: i]];

	[aGraphicContext printString: myText
	   atPosX: myXPosition + [self mapXPosition: i + area - strlen(myText)]
	   atPosY: myYPosition];
}

/**/
- (void) setNewCursorPosition
{
	myCurrentPosition = [self getComponentArea] - 1;
}

/**/
- (BOOL) setDeleteKeyPressed
{						
	myValue = myValue / 10;
	[self configureTextValue];
	
	return TRUE;
}

/**/
- (BOOL) setNewKeyPressed: (char) aKey
{	
	long long value;
	
	/* too many digits ? */						
	if (aKey < '0' ||aKey > '9' || strlen(myText) > [self getComponentArea] - 1)
		return FALSE;

	value = myValue * 10 + (int) (aKey - '0');
	
	if (value < 0)
		return TRUE;
	else
		myValue = value;
		
	[self configureTextValue];

	[self executeOnChangeAction];
		
	return TRUE;
}

/**/
- (BOOL) setRightKeyPressed
{
	return TRUE;	
}

/**/
- (BOOL) setLeftKeyPressed
{
	return TRUE;	
}

- (BOOL) isValid
{
	if (myValue > myMaxDoubleValue || myValue < myMinDoubleValue) return FALSE;
	return TRUE;
}
/**/
- (void) doValidate
{
	/* Controls the min and max value */
	//if (myValue > myMaxDoubleValue) THROW( UI_MAX_VALUE_EX );
	//if (myValue < myMinDoubleValue) THROW( UI_MIN_VALUE_EX );
}

- (void) setValuePrefix: (char*) aValuePrefix
{
  stringcpy(myValuePrefix, aValuePrefix);
}

/**/
- (void) doFocus
{
	[super doFocus];

	[[InputKeyboardManager getInstance] setNumericMode];
}

@end

