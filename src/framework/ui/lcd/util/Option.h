#ifndef OPTION_H
#define OPTION_H

#define OPTION id

#include <Object.h>

/**
 *	doc template
 */
@interface Option : Object
{
	int myKey;
	char myValue[51];
}

/**/
+ newOption: (int) aKey value: (char *) aValue;
- (int) getKeyOption;
- (char *) getValue;

@end

#endif
