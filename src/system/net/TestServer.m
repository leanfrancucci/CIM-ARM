#include "sysnet.h"

int main(void) 
{
	char buf[100];
	SERVER_SOCKET server;
	SOCKET socket;
	READER sin;
	DATA_READER in;
	
	server = [ServerSocket new];
	[server bind:"" port:8454];
	socket = [server accept];
	
	sin = [socket getReader];
	in = [[DataReader new] initWithReader: sin];
	
	[in readLine: buf];
	//doLog(0,"%s\n", buf);
	[in readLine: buf];
	//doLog(0,"%s\n", buf);
	[in readLine: buf];
//	doLog(0,"%s\n", buf);
	[in readLine: buf];
//	doLog(0,"%s\n", buf);
//	doLog(0,"%c", [in readChar]);
//	doLog(0,"%c", [in readChar]);
//	doLog(0,"%d\n", [in readInt]);
			
		
	[socket close];
	[server close];

	return 0;
	
}

