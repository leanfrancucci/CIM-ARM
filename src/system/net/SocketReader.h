#ifndef SOCKET_READER_H
#define SOCKET_READER_H

#define SOCKET_READER id

#include <Object.h>
#include "NetExcepts.h"
#include "system/io/all.h"
#include "ClientSocket.h"

/**
 *	Reader para leer desde un Socket. 
 *	Tiene internamente un atributo de tipo Socket para realizar las lecturas.
 *
 *	No deberia crearse esta clase directamente, sino obtenerse a traves del metodo
 *	getReader del Socket.
 */ 
@interface SocketReader : Reader
{
	CLIENT_SOCKET mySocket;
}

/**
 *	Inicializa SocketReader con el Socket pasado como parametro.
 */
- initWithSocket: (CLIENT_SOCKET) aSocket;

/**
 * 	Efectua la lectura del socket.
 */
- (int) read: (char*)aBuf qty: (int)aQty;

@end

#endif
