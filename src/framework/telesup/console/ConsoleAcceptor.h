#ifndef CONSOLE_ACCEPTOR_H
#define CONSOLE_ACCEPTOR_H

#define CONSOLE_ACCEPTOR id

#include <Object.h>
#include "ctapp.h"
#include "system/net/all.h"
#include "system/os/all.h"
#include "TelesupDefs.h"
#include "RemoteConsole.h"

/**
 *	Espera una conexion entrante y larga una supervision una vez que se conecta.
 *	
 */
@interface ConsoleAcceptor : OThread
{
    SERVER_SOCKET ssocket;
	int port;
    REMOTE_CONSOLE myRemoteConsole;
}
/**/
+ new;

/**/
- initialize;

/**
 *	Configura el puerto pasado por parametro.
 */
- (void) setPort: (int) aPort;

/**
 * Trata la conexion entrante
 */
- (void) incommingConnection: (SSL_CLIENT_SOCKET) aSocket;


@end

#endif
