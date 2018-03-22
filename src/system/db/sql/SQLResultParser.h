#ifndef SQL_RESULT_PARSER_H
#define SQL_RESULT_PARSER_H

#include "system/util/all.h"

/**
 *	El objetivo de esta unit es parsear el resultado XML generado por una query (devuelve los metadatos y los datos).
 *	Devuelve los metadatos en una coleccion fields y los datos en una coleccion rows.
 */

/**
 *	Parsea los resultados de una query SQL (vienen en XML)
 *	@param buf el resultado de la consulta sql.
 *	@param len la longitud del resultado.
 *	@param fields coleccion donde se colocaran los fields que devuelva la consulta.
 *	@param rows coleccion donde se colocaran los rows devueltos.
 *	@note: Esta practicamente implementado en C porque las funciones expat para recorrer el arbol XML (tipo SAX)
 *	exigen funciones de callback escritas en C.
 */
int parseXMLResults(char *buf, int len, COLLECTION fields, COLLECTION rows);

/**
 *  Parsea los resultados de obtener las primary keys de una tabla.
 *  Las primary keys vienen listadas entre tags <1>nombre de la pk</1><2>nombre de la pk</2>...etc
 *  @param el buffer con el xml resultante de obtener las primary keys.
 *  @param len longitud de buffer.  
 *  @param fields los campos ya creados a los cuales se les configurara las primary key.
 */  
int parsePrimaryKeys(char *buf, int len, COLLECTION fields);

#endif
