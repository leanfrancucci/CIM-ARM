#ifndef SSL_SERVER_SOCKET_H
#define SSL_SERVER_SOCKET_H

#define SSL_SERVER_SOCKET id

#include <Object.h>
#include "NetExcepts.h"
#include "SSLClientSocket.h"

#include "openssl/ssl.h"
#include "openssl/crypto.h"

/**
 *	Esta clase implementa los SSLServerSockets.
 */
@interface SSLServerSocket : Object
{
	int myHandle;
  SSL_CTX  *ctx;
	SSL_METHOD *meth;

  SSL *ssl;
  
  X509 *server_cert;
  EVP_PKEY *pkey;
}


/**
 *	Espera hasta que alguien se conecta.
 *	Una vez conectado, devuelve un socket con la conexion establecida.
 *	Es un metodo bloqueante.
 */
- (SSL_CLIENT_SOCKET) accept;

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
