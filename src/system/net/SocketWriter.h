#ifndef SOCKET_WRITER_H
#define SOCKET_WRITER_H

#define SOCKET_WRITER id

#include <Object.h>
#include "NetExcepts.h"
#include "system/io/all.h"
#include "ClientSocket.h"

/**
 *	Writer para escribir en un Socket. 
 *	Tiene internamente un atributo de tipo Socket para realizar las escrituras.
 *
 *	No deberia crearse esta clase directamente, sino obtenerse a traves del metodo
 *	getWriter del Socket.
 */
@interface SocketWriter : Writer
{
	CLIENT_SOCKET mySocket;
}

/**
 *	Inicializa el Writer con el Socket pasado como parametro.
 */	
- initWithSocket: (CLIENT_SOCKET) aSocket;

/**
 *	Escribe los datos pasados como parametro en el Socket.
 */
- (int) write: (char*)aBuf qty: (int)aQty;

@end

#endif
