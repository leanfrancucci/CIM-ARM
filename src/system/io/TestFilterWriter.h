#ifndef TEST_FILTER_WRITER_H
#define TEST_FILTER_WRITER_H

#define TEST_FILTER_WRITER id

#include <Object.h>
#include "IOExcepts.h"
#include "FilterWriter.h"

/**
 *	Esta clase es un filtro de escritura de prueba. Lo que hace es sumar en 1 cada byte
 *	que se escribe en el buffer.
 */
@interface TestFilterWriter : FilterWriter
{
}

- (int) write: (char *)aBuf qty:(int) aQty;

@end

#endif
