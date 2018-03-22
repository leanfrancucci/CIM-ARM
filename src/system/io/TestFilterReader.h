#ifndef TEST_FILTER_READER_H
#define TEST_FILTER_READER_H

#define TEST_FILTER_READER id

#include <Object.h>
#include "IOExcepts.h"	
#include "FilterReader.h"

/**
 *	Esta clase es un filtro de lectura de prueba. Lo que hace es sumar en 1 cada byte
 *	que se lee del buffer.
 */
@interface TestFilterReader : FilterReader
{
}

- (int) read: (char *)aBuf qty:(int) aQty;

@end

#endif
