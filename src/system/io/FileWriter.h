#ifndef FILE_WRITER_H
#define FILE_WRITER_H

#define FILE_WRITER id

#include <Object.h>
#include "IOExcepts.h"
#include "Writer.h"

/**
 *	Un Writer que proporciona lectura de un archivo.
 */
@interface FileWriter : Writer
{
	FILE *myFile;		
}

/**
 *	Inicializa el Writer con el archivo pasado como parametro.
 *  El archivo debe estar abierto previamente.
 *
 *	@param file un puntero a una estructura standard de C para el manejo de archivos.
 */
- initWithFile: (FILE*) aFile;

/**
 *	Inicializa el Writer con un nombre de archivo.
 *
 *	@param name el nombre del archivo que se desea abrir.
 */
- initWithFileName: (char*) aFileName;

/**
 *	Cierra el archivo.
 */
- (void) close;

/**
 *	Escribe al archivo la cantidad especificada como parametro.
 *
 *	@param buf el buffer para almacenar los datos leidos.
 *	@param qyu la cantidad de datos a leer.
 *	@return la cantidad de bytes que realmente escribio.
 */
- (int) write: (char *)aBuf qty:(int) aQty;



@end

#endif
