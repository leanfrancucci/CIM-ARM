#include <string.h>
#include <stdlib.h>
#include "StringTokenizer.h"
#include "system/lang/all.h"
#include "util.h"
#include "UtilExcepts.h"

@implementation StringTokenizer

/**/
+ new
{
	return [[super new]initialize];
}

/**/
- initialize
{
	myTrimMode = TRIM_NONE;
	myText = NULL;
	return self;
} 

/**/
- initTokenizer: (char*) aText delimiter: (char*) aDelimiter
{
	[self setText:aText];
	[self setDelimiter:aDelimiter];
	return self;
}

/**/
- (void) setText: (char*)aText
{
	if (myText) free(myText);
	myText = malloc( strlen(aText) + 1 );
	THROW_NULL(myText);
	strcpy(myText, aText);
	myTextPtr = myText;
}

/**/
- (void) setDelimiter: (char*)aDelimiter
{
	strcpy(myDelimiter, aDelimiter);
}

/**/
- (void) setTrimMode: (TokenizerTrimMode) aValue
{
	myTrimMode = aValue;
}


/**/
- (void) restart
{
	myTextPtr = myText;
}

/**/
- (BOOL) hasMoreTokens
{
	char *p;
	
	p = myTextPtr;
	if (!(myText && myTextPtr < myText + strlen(myText))) return FALSE;
		
	while (*p != '\0') { 
		if ( myTrimMode == TRIM_NONE || myTrimMode == TRIM_LEFT || !isblankchar(*p) ) return TRUE;
		p++;
	}
	
	return FALSE;
	
	
}

/**/
- (char*) getNextToken: (char*) aToken
{
	char *toPtr, *p;
	
	if ( ![self hasMoreTokens] ) THROW_MSG(NO_MORE_TOKENS_EX, myText);
	
	toPtr = strstr(myTextPtr, myDelimiter);
	
	if (!toPtr) toPtr = strchr(myTextPtr, '\0');
	
	if (!toPtr) return NULL;
	p = toPtr;
	
	// Si remueve los elementos en blanco, quito todos los que hay al inicio
	if (myTrimMode == TRIM_ALL || myTrimMode == TRIM_LEFT) 
		while (*myTextPtr == ' ') myTextPtr++;

	// Si remueve los elementos en blanco, quito todos los que hay al final
	if (myTrimMode == TRIM_ALL || myTrimMode == TRIM_RIGHT) {
		
		while (toPtr >= myTextPtr) {
			toPtr--;
			if ( !isblankchar(*toPtr) ) break;
		}

		toPtr++;
	}

	// Copio al buffer que me da el usuario el token 
	memcpy(aToken, myTextPtr, toPtr - myTextPtr);
	aToken[toPtr - myTextPtr] = '\0';
	myTextPtr = p + strlen(myDelimiter);
	
	return aToken;

}

/**/
- free
{
	if (myText) free(myText);
	return [super free];
}

@end
