#ifndef FILTER_WRITER_H
#define FILTER_WRITER_H

#define FILTER_WRITER id

#include <Object.h>
#include "IOExcepts.h"
#include "Writer.h"

/**
 *  Clase padre de todos los FilterWriters.
 */
@interface FilterWriter : Writer
{
	WRITER myWriter;
}

- initWithWriter: (WRITER) aWriter;
- (void) close;
- (int) write: (char *)aBuf qty:(int) aQty;

@end

#endif
