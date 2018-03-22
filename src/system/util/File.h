#ifndef FILE_H
#define FILE_H


#include <Object.h>
#include "Collection.h"

/**
 *	doc template
 */
@interface File : Object
{

}

/**
 *	Devuelve una coleccion de (char *) con los nombres de los archivos encontrados
 *	en el path y con la extension especificada.
 *	Por ejemplo: especificando tec, obtendra todos   archivos que tengan tec en
 *	.tec en su extension.
 *	Es responsabilidad del que llama a este metodo liberar las cadenas dentro de la lista
 *	cuando ya no se utilicen mas.
 */
+ (COLLECTION) findFilesByExt: (char*) aPath extension: (char*) anExtension
							 caseSensitive: (BOOL) aCaseSensitive;

+ (COLLECTION) findFilesByExt: (char*) aPath extension: (char*) anExtension
							 caseSensitive: (BOOL) aCaseSensitive startsWith: (char *) aStartsWith;

/**
 *	Devuelve el nombre de archivo y la extension sin el path completo.
 *	Devuelve un puntero a algun lugar de la cadena pasada por parametro.
 */							 
+ (char*) extractFileName: (char *) aPath;

/**
 *	Verifica si existe el archivo pasado por parametro.
 *	@Devuelve TRUE si existe, FALSE en caso contrario
 */
+ (BOOL) existsFile: (char*) aPath;


/**
 *	Crea el directorio pasada por parametro.
 */
+ (BOOL) makeDir: (char*) aPath;

/**
 *	Devuelve la longitud del archivo pasada por parametro.
 *	@return la longitud del archivo o -1 si no lo encuentra.
 */	
+ (long) getFileSize: (char*) aPath;

@end

#endif
