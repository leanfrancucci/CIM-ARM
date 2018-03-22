#include "ServerSocket.h"
#include "socketapi.h"
#include "netdefs.h"
#include <assert.h>

@implementation ServerSocket

+ new
{
	return [[super new] initialize];
}

- initialize
{
	myHandle = sock_socket();
    printf("myHandle = %d\n", myHandle);
	assert(myHandle > 0);
	return self;
}

- (CLIENT_SOCKET) accept
{
	int newHandle;
	printf("accept 1\n");
	assert(myHandle > 0);
    printf("accept 2\n");
	if ((newHandle = sock_accept(myHandle)) == -1)
		THROW( SOCKET_EX );
    printf("accept 3\n");
	return [[ClientSocket new] initWithHandle: newHandle];
    
}

- (void) bind: (char*) anAddress port: (int) aPort
{
    printf("bind 1\n");
	assert(myHandle > 0);
    printf("bind 2\n");
	if (sock_bind( myHandle, aPort) == -1)
		THROW( SOCKET_EX );
	printf("bind 3\n");
	if (sock_listen( myHandle, SERVER_SOCKET_CONNECTIONS ) == -1)
		THROW( SOCKET_EX );
    printf("bind 4\n");
}

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
