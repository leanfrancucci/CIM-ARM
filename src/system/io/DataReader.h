#ifndef DATA_READER_H
#define DATA_READER_H

#define DATA_READER id

#include <Object.h>
#include "IOExcepts.h"
#include "FilterReader.h"

/**
 *	Un Reader que lee datos de mas alto nivel, por ejemplo byte, integer, lineas, etc..
 *
 */
@interface DataReader : FilterReader
{
	BOOL myBigEndian;
}

/**
 *	Configura que los datos leidos estan en formato Big Endian y por lo tanto quizas tengan que convertirse.
 */
- (void) setBigEndian: (BOOL) aBigEndian;

/**
 *	Lee una linea (hasta el caracter \n) o hasta leer aQty bytes.
 *	Almacena el resultado en el buffer pasado como parametro. 
 *	Devuelve este mismo buffer para poder encadenar funciones.
 *  Almacena un \0 despues del \n si lee menos de aQty, o lo pone después del ultimo caracter leido si lee aQty bytes.
 *	
 *	Warning: El buffer pasado como parametro debe ser lo suficientemente grande
 *	para almacenar la cadena leida.
 */
- (char*) readLine: (char*) aBuf qty: (int) aQty;

/**
 *	Lee caracteres en BCD del stream, y los devuelve en ASCII.
 *
 *	@param buf un buffer donde se colocaran los resultados.
 *	@param qty la cantidad de caracteres ASCII a leer.
 *	@return un puntero a buf.
 */
- (char*) readBCD: (char*) aBuf qty: (int) aQty;

/**
 *	Lee un short del Reader y lo devuelve.
 */
- (short) readShort;

/**
 *	Lee un long del Reader y lo devuelve.
 */
- (long) readLong;

/**
 *	Lee un caracter del reader y lo devuelve.
 */
- (int) readChar;

/**
 *	Lee un tipo de datos money con el formato (mantise x 10 ^ exp) (ocupando un byte para el exp y 4 para la mantisa).
 */
- (money_t) readMoney2;

@end

#endif
