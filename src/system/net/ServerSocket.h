#ifndef SERVER_SOCKET_H
#define SERVER_SOCKET_H

#define SERVER_SOCKET id

#include <Object.h>
#include "NetExcepts.h"
#include "ClientSocket.h"

/**
 *	Esta clase implementa los ServerSockets.
 *	Un ServerSocket se queda escuchando en un puerto conexiones entrantes.
 *	Cuando se produce una nueva conexion devuelve un nuevo Socket con la conexion
 *	ya establecida.
 *
 */
@interface ServerSocket : Object
{
	int myHandle;
}


/**
 *	Espera hasta que alguien se conecta.
 *	Una vez conectado, devuelve un socket con la conexion establecida.
 *	Es un metodo bloqueante.
 */
- (CLIENT_SOCKET) accept;

/**
 *	Liga al ServerSocket a una direccion IP y puerto local.
 *	Tambien lo deja en modo listen para poder aceptar nuevas conexiones.
 */
- (void) bind: (char*) anAddress port: (int) aPort;

/**
 *	Cierra el ServerSocket.
 */
- (void) close;

/**
 *
 */
- (void) shutdown;

@end

#endif
