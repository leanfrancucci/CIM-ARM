#include "Socket.h"
#include "SocketWriter.h"
#include "DataWriter.h"

int main(void)
{
	SOCKET mySocket = [Socket new];
	SOCKET_WRITER sout;
	DATA_WRITER out;
	
	[mySocket initWithHost:"192.168.0.214" port:8454];
	[mySocket write:"sss" qty:3];
	[mySocket connect];
	sout = [mySocket getWriter];
	out = [[DataWriter new] initWithWriter: sout];
	[out writeLine:"HOLA MUNDO"];
	[out writeLine:"1234567890"];
	[out writeLine:"5555555555"];
	[out writeLine:"444444444"];			
	[out writeChar:'a'];
	[out writeChar:'\n'];
	[out writeInt:65];	
	[mySocket close];
	
	return 0;
}
