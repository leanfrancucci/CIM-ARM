#ifndef GENERIC_MOCK_H
#define GENERIC_MOCK_H

#define GENERIC_MOCK id

#include <Object.h>
#include "ctapp.h"

/**
 *	doc template
 */
@interface GenericMock : Object
{
	char myMockName[255];
	char myLastMethod[255];
}

- (void) setMockName: (char *) aName;
- (char *) getLastMethod;
- (void) resetMock;


@end

#endif
