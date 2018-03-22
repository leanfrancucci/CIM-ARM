#ifndef FILE_READER_H
#define FILE_READER_H

#define FILE_READER id

#include <Object.h>
#include "IOExcepts.h"
#include "Reader.h"

/**
 *	Un Reader que proporciona lectura de un archivo.
 */
@interface FileReader : Reader
{
	FILE *myFile;		
}

/**
 *	Inicializa el Reader con el archivo pasado como parametro.
 *  El archivo debe estar abierto previamente.
 *
 *	@param file un puntero a una estructura standard de C para el manejo de archivos.
 */
- initWithFile: (FILE*) aFile;

/**
 *	Inicializa el Reader con un nombre de archivo.
 *	Abre el archivo como solo lectura.
 *
 *	@param name el nombre del archivo que se desea abrir.
 */
- initWithFileName: (char*) aFileName;

/**
 *	Cierra el archivo.
 */
- (void) close;

/**
 *	Lee del archivo la cantidad especificada como parametro.
 *
 *	@param buf el buffer para almacenar los datos leidos.
 *	@param qyu la cantidad de datos a leer.
 *	@return la cantidad de bytes que realmente leyo.
 */
- (int) read: (char *)aBuf qty:(int) aQty;



@end

#endif
