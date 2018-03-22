#ifndef CLIENTSOCKET_H
#define CLIENTSOCKET_H

#define CLIENT_SOCKET id

#include <Object.h>
#include "NetExcepts.h"
#include "system/io/all.h"

#define HOST_SIZE 255

/**
 *	Esta clase implementa client sockets.
 *	Un socket es un punto de conexion entre dos maquinas.
 *	
 */
@interface ClientSocket : Object
{
	int  			myHandle;
	char 			myHost[HOST_SIZE];
	unsigned int 	myPort;
	
	int				myReadTimeout;
	int				myWriteTimeout;	
	
	READER 			myReader;
	WRITER 			myWriter;
	char			myRemoteIPAddr[255];
	char			myRemoteHostName[255];
}

/**
 *	Inicializa un socket con un handle de un socket ya conectado.
 *	Normalmente esta funcion es utilizada por ServerSocket unicamente, no deberia
 *	ser llamada directamente.
 */
- initWithHandle: (int) aHandle;

/**
 *	Inicializa el socket con el host (numero de IP) y puerto pasada como parametro.
 */
- initWithHost: (char*) aHost port: (int) aPort;

- (void) setReadTimeout: (int) aReadTimeout;
- (void) setWriteTimeout: (int) aWriteTimeout;
	
/**
 *	Se conecta al socket.
 *	@return TRUE si la conexion tuvo exito, FALSE en caso contrario.
 *
 *	@throws SOCKET_HOST_NAME_EX si no puede resolver el host.
 *	@throws	SOCKET_CONNECT_EX si no se puede conectar por alguna razon.
 *
 */
- (BOOL) connect;

/**
 *	Escribe en el socket.
 *	Si bien se puede utilizar este metodo directamente, es preferible escribir en el 
 *	socket a traves de un Writer, llamando al metodo getWriter de este objeto
 *	para obtenerlo.
 */
- (int) write: (char*) aBuf qty: (int) aQty;

/**
 *	Lee desde el socket.
 *	Si bien se puede utilizar este metodo directamente, es preferible leer desde el 
 *	socket a traves de un Reader, llamando al metodo getReader de este objeto
 *	para obtenerlo.
 */
- (int) read: (char*)aBuf qty: (int) aQty;

/**
 *	Cierra el socket.
 */
- (void) close;

/**
 *	Devuelve el Writer para este Socket.
 */
- (WRITER) getWriter;

/**
 *	Devuelve el Reader para este Socket.
 */
- (READER) getReader;


/**
 *	Devuelve el numero de ip remoto.
 */
- (char *) getRemoteIPAddr;

/**
 *	Devuelve el nombre del host remoto.
 */
- (char *) getRemoteHostName;


/**
 *	Libera el socket.
 */
- free;

@end

#endif
