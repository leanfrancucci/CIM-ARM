#ifndef LOG_WRITER_H
#define LOG_WRITER_H

#define LOG_WRITER id

#include <Object.h>

#include "IOExcepts.h"
#include "FilterWriter.h"

/**
 *	Decora un Writer para loguear lo que escribe en un Writer configurado para
 *  tal fin.
 *  Ademas de redirigir los datos a escribir al Writer configurado.
 *  Se configura el Writer con otro Writer que es en donde se escribe
 *  todos los datos leidos.
 */

@interface LogWriter : FilterWriter
{
	WRITER			myLogWriter;
	char			myBuffer[1024];
}

/* Configura el Writer a donde se envian los datos escritos.
 * Los datos se envian formateados.
 * El LogWriter puede ser un FileWriter, un ASCIIFormatterWriter u otro.
 */
- initWithLogWriter: (WRITER) aLogWriter;

/**/
- (int) write: (char *)aBuf qty:(int) aQty;
- (void) seek: (int)aQty from: (int) aFrom; 
- (void) close;


@end

#endif
