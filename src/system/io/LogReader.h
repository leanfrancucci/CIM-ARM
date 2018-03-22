#ifndef LOG_READER_H
#define LOG_READER_H

#define LOG_READER id

#include <Object.h>
#include "IOExcepts.h"
#include "FilterReader.h"
#include "Writer.h"

/**
 *	Decora un Reader para loguear lo que lee del Reader configurado en 
 *  un Writer configurado para tal fin.
 *  Se configura el Reader con un Writer en donde se escribe
 *  todos los datos leidos.
 */
@interface LogReader : FilterReader
{
	WRITER			myLogWriter;
	char			myBuffer[1024];
}

/**
 * Configura el Writer a donde se envian los datos escritos.
 * Los datos se envian formateados.
 * El LogWriter puede ser un FileWriter, un ASCIIFormatterWriter u otro.
 */
- initWithLogWriter: (WRITER) aLogWriter;

/**/
- (int) read: (char *)aBuf qty:(int) aQty;
- (void) seek: (int)aQty from: (int) aFrom; 
- (void) close;

@end

#endif
