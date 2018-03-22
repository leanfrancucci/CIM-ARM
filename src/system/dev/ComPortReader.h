#ifndef COM_PORT_READER_H
#define COM_PORT_READER_H

#define COM_PORT_READER id 

#include <Object.h>
#include "system/io/all.h"
#include "ComPort.h"

/**
 *	Reader para leer desde un ComPort. 
 *	Tiene internamente un atributo de tipo Com para realizar las lecturas.
 *
 *	No deberia crearse esta clase directamente, sino obtenerse a traves del metodo
 *	getReader del Com.
 */ 
@interface ComPortReader : Reader
{
	COM_PORT myComPort;
}

/**
 *	Inicializa ComReader con el Com pasado como parametro.
 */
- initWithComPort: (COM_PORT) aCom;

/**
 * 	Efectua la lectura del Com.
 */
- (int) read: (char*)aBuf qty: (int)aQty;

@end

#endif
