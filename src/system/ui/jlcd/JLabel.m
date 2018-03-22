#include <assert.h>
#include "JLabel.h"

#define printd(args...)// doLog(0,args)
//#define printd(args...)


@implementation  JLabel

/**/
- (void) initComponent
{
 [super initComponent];
 	
	myTokenizer = [StringTokenizer new];
	assert(myTokenizer != NULL);
	myMutex	= [OMutex new];
	myCaption[0] = '\0';
	myWordWrapMode = FALSE;	
	myAutoSize = TRUE;
	myWidth = 1;	
	myTextAlign = UTIL_AlignLeft;
	myFormatNumbersOfDigits = 0;
}


/**/
- free
{
	[myTokenizer free];
	[myMutex free];
	return [super free];
}

/**/
- initWithCaption: (char *)  aCaption
{
	[self setCaption: aCaption];
	return self;
}

/**/
- (void) setTextAlign: (UTIL_AlignType) aTextAlign { myTextAlign = aTextAlign; }
- (UTIL_AlignType) getTextAlign { return myTextAlign; }

/**/
- (void) setFormatNumbersOfDigits: (int) aValue { myFormatNumbersOfDigits = aValue; }
- (int) getFormatNumbersOfDigits { return myFormatNumbersOfDigits; }


/**
 * Redefinido
 */
- (void) setWidth: (int) aWidth 
{ 
		myAutoSize = FALSE;
		[super setWidth: aWidth];
}

/**/
- (void) setCaption: (char *) aValue
{
	if (aValue == NULL)
		myCaption[0] = '\0';
	else {
		stringcpy(myCaption, aValue);	
	}
	
	if (myAutoSize)
		myWidth = strlen(myCaption);
		
	[self paintComponent];
}

/**/
- (void) setAutoSize: (BOOL) aValue { myAutoSize = aValue; }
- (BOOL) isAutoSize {return myAutoSize; }

/**/
- (void) setWordWrap: (BOOL) aValue { myWordWrapMode = aValue; }
- (BOOL) isWordWrap { return myWordWrapMode; }


/**/
- (char *) getCaption
{
	return myCaption;
}

/**/
- (void) setIntegerValue: (int) aValue
{
	char format[10];
	
	if (myFormatNumbersOfDigits > 0)
		snprintf(format, sizeof(format) - 1, "%s%dd", "%0", myFormatNumbersOfDigits);
	else	
		snprintf(format, sizeof(format) - 1, "%s", "%d");
		
	snprintf(myAuxText, sizeof(myAuxText) - 1, format, aValue);
	[self setCaption: myAuxText];
}

/**/
- (int) getIntegerValue
{
	return atoi(myCaption);
}

/**/
- (void) setLongValue: (long) aValue
{
	char format[10];
	
	if (myFormatNumbersOfDigits > 0)
		snprintf(format, sizeof(format) - 1, "%s%dld", "%0", myFormatNumbersOfDigits);
	else	
		snprintf(format, sizeof(format) - 1, "%s", "%ld");
		
	snprintf(myAuxText, sizeof(myAuxText) - 1, format, aValue);
	[self setCaption: myAuxText];
}

/**/
- (long) getLongValue
{
	return atol(myCaption);
}



/**/
- (void) doDraw: (JGRAPHIC_CONTEXT) aGraphicContext
{
	char		auxCaption[ JComponent_MAX_LEN + 1 ];
	int x, y, n;
  char aux[ JComponent_MAX_LEN + 1 ];
	
	assert(aGraphicContext != NULL);
	assert(myTokenizer != NULL);

	x = y = 0;
  if (![self isVisible] ) aux[0] = '\0';
  else strcpy(aux, myCaption);
  
	if (!myWordWrapMode) {
	
			/* Imprime la palabra */
			
			n = min(myWidth, sizeof(auxCaption) - 1);      
			[aGraphicContext printString: alignString(auxCaption, aux, n, myTextAlign) 
																			atPosX: myXPosition 
																			atPosY: myYPosition];

      	
	} else { /* Hace word wrap */

		[myMutex lock];

		[myTokenizer initTokenizer: aux delimiter: " "];
		strcpy(aux, "");

		/* Recorre las palabras */
		while ([myTokenizer hasMoreTokens]) {

			[myTokenizer getNextToken: myAuxText];

			/* Si se pasa de linea la sig. palabra pasa a la sig. linea */
			if (strlen(myAuxText) + x > myWidth) {
				[aGraphicContext printString: aux atPosX: myXPosition atPosY: myYPosition + y];
				x = 0;
				y++;
				strcpy(aux, "");
			}				

			/* Imprime la primer palabra */	
			//[aGraphicContext printString: myAuxText atPosX: myXPosition + x atPosY: myYPosition + y];
			strcat(aux, myAuxText);
			
			x += strlen(myAuxText);		

			/* Imprime un espcacio */
			if (x < myWidth) {
				//[aGraphicContext printChar: ' ' atPosX: myXPosition + x atPosY: myYPosition + y];		
				strcat(aux, " ");
			}
			x++;
		}	
		[aGraphicContext printString: aux atPosX: myXPosition atPosY: myYPosition + y];
		
		[myMutex unLock];

	}
}

/**/
- (void) doDrawCursor: (JGRAPHIC_CONTEXT) aGraphicContext
{
	assert(aGraphicContext != NULL);
	
	[aGraphicContext setBlinkCursor: FALSE];		
}

@end

