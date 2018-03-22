#include "SocketReader.h"

@implementation SocketReader

- initWithSocket: (CLIENT_SOCKET) aSocket
{
	mySocket = aSocket;
	return self;
}

- (int) read: (char*)aBuf qty: (int)aQty
{
	return [mySocket read: aBuf qty: aQty];
}


@end
