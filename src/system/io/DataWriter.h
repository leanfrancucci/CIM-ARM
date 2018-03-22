#ifndef DATA_WRITER_H
#define DATA_WRITER_H

#define DATA_WRITER id

#include <Object.h>
#include "IOExcepts.h"
#include "FilterWriter.h"

/**
 *	Un Writer que lee datos de mas alto nivel, por ejemplo byte, integer, lineas, etc..
 *
 */
@interface DataWriter : FilterWriter
{
	BOOL myBigEndian;
}

/**
 *	Configura que los datos escritos deben estar en formato Big Endian.
 */
- (void) setBigEndian: (BOOL) aBigEndian;

/**
 *	Escribe la linea pasada como parametro y agrega un '\n'.
 *	Escribe solo aQty bytes o hasta un \0
 */
- (int) writeLine: (char*) aBuf qty: (int) aQty;
- (int) writeLine: (char*) aBuf;

/**
 *	Escribe un entero.
 */
- (int) writeShort: (short) aShort;

/**
 *	Escribe un long.
 */
- (int) writeLong: (long) aLong ;

/**
 *	Escribe un char.
 */
- (int) writeChar: (char) aChar;

/**
 *	Escribe un money con el formato (mantise x 10 ^ exp) (ocupando un byte para el exp y 4 para la mantisa).
 */
- (int) writeMoney2: (money_t) aValue;


@end

#endif
