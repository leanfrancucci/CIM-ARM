#ifndef MEMORY_READER_H
#define MEMORY_READER_H

#define MEMORY_READER id

#include <Object.h>
#include "IOExcepts.h"
#include "Reader.h"

/**
 *	Un Reader que proporciona lectura desde memoria.
 */
@interface MemoryReader : Reader
{
	char *myStart;			/** el comienzo del buffer en memoria */
	char *myPos;				/** un puntero a la posicion actual en el buffer */
	int   mySize;				/** el tamaño del buffer */
}

/**
 *	Inicializa el Reader con un puntero pasado como parametro.
 *
 *	@param pointer un puntero a memoria.
 */
- initWithPointer: (char*) aPointer size: (int) aSize;


@end

#endif
