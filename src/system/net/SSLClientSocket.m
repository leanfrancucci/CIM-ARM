#include "SSLClientSocket.h"
#include "SocketWriter.h"
#include "SocketReader.h"


#include "system/lang/all.h"

#include "NetExcepts.h"

#include <types.h>
#include <socketapi.h>
#include <inet.h>

#include <netdb.h>
#include <unistd.h>
#include "util.h"
#include "assert.h"

@implementation SSLClientSocket


+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myReader = [[SocketReader new] initWithSocket: self];
	myWriter = [[SocketWriter new] initWithSocket: self];
	ssl = NULL;
	return self;
}

/**/
- initSocket
{
	myHandle = sock_socket();	

	return self;

}

/**/
- initWithHandle: (int) aHandle ssl: (SSL*) aSsl
{	
	ssl = aSsl;
	myHandle = aHandle;	
	return self;

}

/**/
- initWithHost: (char*) aHost port: (int) aPort
{

	if ( strlen(aHost) >= HOST_SIZE ) THROW(MAX_LEN_EX);
	
	strcpy(myHost, aHost);
	myPort = aPort;
	return [self initSocket];

}

/**/
- (void) setReadTimeout: (int) aReadTimeout
{
	myReadTimeout = aReadTimeout;
	sock_set_read_timeout(myHandle, aReadTimeout);
}

/**/
- (void) setWriteTimeout: (int) aWriteTimeout
{
	myWriteTimeout = aWriteTimeout;
	sock_set_write_timeout(myHandle, aWriteTimeout);
}

/**/
- (BOOL) connect
{
	char  *str;

//	 doLog(0,"connect\n");

  //Create an SSL_METHOD structure (choose an SSL/TLS protocol version) 
  meth = SSLv3_method();
 
  //Create an SSL_CTX structure 
  ctx = SSL_CTX_new(meth);                        

	THROW_NULL(ctx);

	if (sock_connect(myHandle, myPort, myHost) == -1)
		THROW_CODE(SOCKET_CONNECT_EX, errno);

   // An SSL structure is created 
   ssl = SSL_new(ctx);
   THROW_NULL(ssl);
 
   // Assign the socket into the SSL structure (SSL and socket without BIO) 
   SSL_set_fd(ssl, myHandle);

 	// Perform SSL Handshake on the SSL client 
  // doLog(0,"Perform SSL Handshake on the SSL server\n");  

   if (SSL_connect(ssl) == -1)
		 THROW_CODE(GENERAL_IO_EX, errno);
 
   // Informational output (optional) 
  // doLog(0,"SSL connection using %s\n", SSL_get_cipher (ssl));
 
   // Get the server's certificate (optional) 
 //  doLog(0,"Get the server's certificate\n");  
   server_cert = SSL_get_peer_certificate (ssl);    
 
   if (server_cert != NULL) {
     
	//	doLog(0,"Server certificate:\n");

    str = X509_NAME_oneline(X509_get_subject_name(server_cert),0,0);
    THROW_NULL(str);
      
	//	doLog(0,"\t subject: %s\n", str);
    free (str);
 
    str = X509_NAME_oneline(X509_get_issuer_name(server_cert),0,0);
    THROW_NULL(str);
    
	//	doLog(0,"\t issuer: %s\n", str);
    free(str);
 
    X509_free(server_cert);

   } //else doLog(0,"The SSL server does not have certificate.\n");


	return TRUE;	
}

/**/
- (int) write: (char*) aBuf qty: (int) aQty
{
	int n;

//	doLog(0,"ssl write: %s\n", aBuf); 
	if ((n = SSL_write(ssl, aBuf, aQty)) == -1) 
		THROW_CODE(GENERAL_IO_EX, errno);
	
	return n;

}

/**/
- (int) read: (char*) aBuf qty: (int) aQty
{
	int n;

	if ((n = SSL_read(ssl, aBuf, aQty)) == -1)                     
		THROW_CODE(GENERAL_IO_EX, errno);

	return n;
}

/**/
- (WRITER) getWriter
{
	return myWriter;
}

/**/
- (READER) getReader
{
	return myReader;
}

/**/
- (void) close
{
	if (ssl != NULL) {
		SSL_shutdown(ssl);
	}

	sock_shutdown(myHandle,2);
	sock_close(myHandle);	

}

/**/
- (char *) getRemoteIPAddr
{
/*
	if (sock_get_remote_ip_addr(myHandle, myRemoteIPAddr)) return myRemoteIPAddr;
*/
	return NULL;
}

/**/
- (char *) getRemoteHostName
{
/*
	if (sock_get_remote_host_name(myHandle, myRemoteHostName)) return myRemoteHostName;
*/
	return NULL;
}

/**/
- free
{
	if (ssl != NULL) {

		SSL_free(ssl);
	 
		// Free the SSL_CTX structure 
		SSL_CTX_free(ctx);

	}

	[myWriter free];
	[myReader free];
	return [super free];

}

@end
