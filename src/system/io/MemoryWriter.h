#ifndef MEMORY_WRITER_H
#define MEMORY_WRITER_H

#define MEMORY_WRITER id

#include <Object.h>
#include "IOExcepts.h"
#include "Writer.h"

/**
 *	Un Writer que proporciona escrituras a memoria.
 */
@interface MemoryWriter : Writer
{
	char *myStart;			/** el comienzo del buffer en memoria */
	char *myPos;				/** un puntero a la posicion actual en el buffer */
	int   mySize;				/** el tamaño del buffer */
}

/**
 *	Inicializa el Writer con un puntero pasado como parametro.
 *
 *	@param pointer un puntero a memoria.
 */
- initWithPointer: (char*) aPointer size: (int) aSize;


@end

#endif
