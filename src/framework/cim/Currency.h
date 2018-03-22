#ifndef CURRENCY_H
#define CURRENCY_H

#define CURRENCY id

#include "Object.h"

/**
 *	Define una moneda, junto con su identificador, nombre y abreviatura.
 */
@interface Currency :  Object
{
	int myCurrencyId;
	char myName[71];
	char myCurrencyCode[6];
}

/**/
- (void) setCurrencyId: (int) aCurrencyId;
- (int) getCurrencyId;
					
/**/
- (void) setName: (char *) aName;
- (char *) getName;
					
/**/
- (void) setCurrencyCode: (char *) aValue;
- (char *) getCurrencyCode;
	

@end

#endif

