#ifndef FILTER_READER_H
#define FILTER_READER_H

#define FILTER_READER id

#include <Object.h>
#include "IOExcepts.h"
#include "Reader.h"

/**
 *
 */
@interface FilterReader : Reader
{
	READER myReader;
}

- initWithReader: (READER) aReader;
- (void) close;
- (int) read: (char *)aBuf qty:(int) aQty;

@end

#endif
