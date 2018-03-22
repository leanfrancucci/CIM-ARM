#ifndef MAP_H
#define MAP_H

#define MAP id

#include <Object.h>
#include "Collection.h"

#define MAX_MAP_VALUE		255

/**
 *	Define un item de configuracion. Tiene un nombre y un valor.
 */
typedef struct {
	char name[150];
	/*ale*/ 
	char *text;
	char value[MAX_MAP_VALUE]; 
} MapItem;

/**
 *	Mantiene una coleccion con configuraciones del tipo nombre valor.
 *	Contiene metodos para pedir los valores de un determinado campo como string, long, short, etc.
 */
@interface Map : Object
{
	COLLECTION items;
  char doc[16535];		
}

/**/
- (int) getItemCount;

/**/
- (char *) getItemNameAt: (int) anIndex;

/**/
- (void) addParamAsDateTime: (char*) aName value: (datetime_t) aValue;
- (void) addParamAsLong: (char*) aName value: (long) aValue;
- (void) addParamAsInteger: (char*) aName value: (int) aValue;
- (void) addParamAsString: (char*) aName value: (char*) aValue;
- (void) addParamAsCurrency: (char *) aName value: (money_t) aValue;
- (void) addParamAsCurrency: (char *) aName value: (money_t) aValue decimals: (int) aDecimals;
- (void) addParamAsFloat: (char *)aName value: (float) aValue;
- (void) addParamAsBoolean: (char *)aName value: (BOOL) aValue;
/*ale*/
- (void) addParamAsText: (char*) aName value: (char*) aValue;

- (char*) getParamAsString: (char*) aName;
- (long) getParamAsLong: (char*) aName;
- (short) getParamAsShort: (char*) aName;
- (int) getParamAsInteger: (char*) aName;
- (float) getParamAsFloat: (char*) aName;
- (BOOL) getParamAsBoolean: (char*) aName;
/*ale*/
- (char*) getParamAsText: (char*) aName; 

- (char*) getParamAsString: (char*) aName default: (char*) aDefault;
- (long) getParamAsLong: (char*) aName default: (long) aDefault;
- (short) getParamAsShort: (char*) aName default: (short) aDefault;
- (int) getParamAsInteger: (char*) aName default: (int) aDefault;
- (float) getParamAsFloat: (char*) aName default: (float) aDefault;
- (BOOL) getParamAsBoolean: (char*) aName default: (BOOL) aDefault;

@end

#endif
