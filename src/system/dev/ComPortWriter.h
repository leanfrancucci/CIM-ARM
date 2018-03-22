#ifndef COM_WRITER_H
#define COM_WRITER_H

#define COM_WRITER id 

#include <Object.h>
#include "system/io/all.h"
#include "ComPort.h"

/**
 *	Writer para escribir en un Com. 
 *	Tiene internamente un atributo de tipo Com para realizar las escrituras.
 *
 *	No deberia crearse esta clase directamente, sino obtenerse a traves del metodo
 *	getWriter del Com.
 */
@interface ComPortWriter : Writer
{
	COM_PORT 	myComPort;
}

/**
 *	Inicializa el Writer con el Com pasado como parametro.
 */	
- initWithComPort: (COM_PORT) aComPort;

/**
 *	Escribe los datos pasados como parametro en el Com.
 */
- (int) write: (char*)aBuf qty: (int)aQty;

@end

#endif
