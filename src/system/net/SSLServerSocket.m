#include "SSLServerSocket.h"
#include "socketapi.h"
#include "netdefs.h"
#include <assert.h>

#include <types.h>
#include <inet.h>

#include <netdb.h>
#include <unistd.h>
#include "util.h"

#define RSA_SERVER_CERT     "server.crt"
#define RSA_SERVER_KEY      "server.key"
 
@implementation SSLServerSocket

+ new
{
	return [[super new] initialize];
}

- initialize
{
  //Create an SSL_METHOD structure (choose an SSL/TLS protocol version) 
  meth = SSLv3_method();
 
  //Create an SSL_CTX structure 
  ctx = SSL_CTX_new(meth);                        

	THROW_NULL(ctx);

//  doLog(0,"Loading server certificate\n");
 // doLog(0,"name: %s \n",RSA_SERVER_CERT);

	if (SSL_CTX_use_certificate_file(ctx, RSA_SERVER_CERT, SSL_FILETYPE_PEM) <= 0) 
		THROW_CODE(GENERAL_IO_EX, errno);  
 
  //doLog(0,"Loading server p-key\n");
  if (SSL_CTX_use_PrivateKey_file(ctx, RSA_SERVER_KEY, SSL_FILETYPE_PEM) <= 0) 
    THROW_CODE(GENERAL_IO_EX, errno);
 
 // doLog(0,"Validation...\n");
  // Check if the server certificate and private-key matches 
  if (!SSL_CTX_check_private_key(ctx)) {
 //	 doLog(0,"Private key does not match the certificate public key\n");      
   THROW_CODE(GENERAL_IO_EX, errno);
  }

	myHandle = sock_socket();
	assert(myHandle > 0);

	return self;
}

/**/
- (SSL_CLIENT_SOCKET) accept
{
	int newHandle;
	
	assert(myHandle > 0);
	if ((newHandle = sock_accept(myHandle)) == -1)
		THROW(SOCKET_EX);

  /* ----------------------------------------------- */
  /* TCP connection is ready. */
  /* A SSL structure is created */

  ssl = SSL_new(ctx);
  THROW_NULL(ssl);
 
  /* Assign the socket into the SSL structure (SSL and socket without BIO) */
  SSL_set_fd(ssl, newHandle);

 	/* Perform SSL Handshake on the SSL server */
  if (SSL_accept(ssl) == -1) THROW(SOCKET_EX);

	return [[SSLClientSocket new] initWithHandle: newHandle ssl: ssl];
}

/**/
- (void) bind: (char*) anAddress port: (int) aPort
{
	assert(myHandle > 0);
	if (sock_bind( myHandle, aPort) == -1)
		THROW( SOCKET_EX );
	
	if (sock_listen( myHandle, SERVER_SOCKET_CONNECTIONS ) == -1)
		THROW( SOCKET_EX );
}

/**/
- (void) close
{
	assert(myHandle > 0);
	sock_close(myHandle);
}

/**/
- (void) shutdown
{
	sock_shutdown(myHandle, 2);
}


@end
