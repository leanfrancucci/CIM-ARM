#include "system/lang/all.h"
#include "ClientSocket.h"
#include "SocketWriter.h"
#include "SocketReader.h"
#include "NetExcepts.h"
#include "socketapi.h"

@implementation ClientSocket


+ new
{
	return [[super new] initialize];
}

- initialize
{
	myReader = [[SocketReader new] initWithSocket: self];
	myWriter = [[SocketWriter new] initWithSocket: self];
	return self;
}

- initSocket
{
	myHandle = sock_socket();	
	return self;
}

- initWithHandle: (int) aHandle
{	
	myHandle = aHandle;	
	return self;
}

- initWithHost: (char*) aHost port: (int) aPort
{
	if ( strlen(aHost) >= HOST_SIZE ) THROW(MAX_LEN_EX);
	
	strcpy(myHost, aHost);
	myPort = aPort;
	return [self initSocket];
}

- (void) setReadTimeout: (int) aReadTimeout
{
	myReadTimeout = aReadTimeout;
	sock_set_read_timeout(myHandle, aReadTimeout);
};

- (void) setWriteTimeout: (int) aWriteTimeout
{
	myWriteTimeout = aWriteTimeout;
	sock_set_write_timeout(myHandle, aWriteTimeout);
};

- (BOOL) connect
{
	if (sock_connect(myHandle, myPort, myHost) == -1)
		THROW_CODE(SOCKET_CONNECT_EX, errno);
	
	return TRUE;	
}

- (int) write: (char*) aBuf qty: (int) aQty
{
	int n;
	
	if ((n = sock_write(myHandle, aBuf, aQty)) == -1)
		THROW_CODE(GENERAL_IO_EX, errno);
	return n;
}

- (int) read: (char*) aBuf qty: (int) aQty
{
	int n;
	if ((n = sock_read(myHandle, aBuf, aQty)) == -1)
		THROW_CODE(GENERAL_IO_EX, errno);
	return n;
}

- (WRITER) getWriter
{
	return myWriter;
}

- (READER) getReader
{
	return myReader;
}

- (void) close
{
	sock_shutdown(myHandle,2);
	sock_close(myHandle);	
}

- (char *) getRemoteIPAddr
{
	if (sock_get_remote_ip_addr(myHandle, myRemoteIPAddr)) return myRemoteIPAddr;
	return NULL;
}

- (char *) getRemoteHostName
{
	if (sock_get_remote_host_name(myHandle, myRemoteHostName)) return myRemoteHostName;
	return NULL;
}

- free
{
	[myWriter free];
	[myReader free];
	return [super free];
	
}

@end
