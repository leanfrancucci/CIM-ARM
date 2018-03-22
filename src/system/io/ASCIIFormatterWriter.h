#ifndef ASCII_FORMATTER_WRITER_H
#define ASCII_FORMATTER_WRITER_H

#define ASCII_FORMATTER_WRITER id

#include <Object.h>

#include "IOExcepts.h"
#include "FilterWriter.h"

/**
 *	Decora un Writer para formatear datos ASCII o binarios en formato ASCII legible
 *  enviando lo formateado al Writer configurado.
 * 
 *	Los ASCII los deja como estan entre " y reemplazando los \n por "\n"
 *  Los no ASCII los reemplaza por 0xAB 
 */

@interface ASCIIFormatterWriter: FilterWriter
{
	int				myIndex;
	char			myBuffer[1024];
		
	WRITER			myLogWriter;
}

/**
 * Configura el Writer decorado.
 */
- initWithWriter: (WRITER) aWriter;

/**/
- (int) write: (char *)aBuf qty:(int) aQty;

@end

#endif
