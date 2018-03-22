#include "SocketWriter.h"

@implementation SocketWriter

- initWithSocket: (CLIENT_SOCKET) aSocket
{
	mySocket = aSocket;
	return self;
}

- (int) write: (char*)aBuf qty: (int)aQty
{
	return [mySocket write: aBuf qty: aQty];
}


@end
