#include "sysio.h"

int main(void)
{
	char callType;
	char phone[50];
	char name[50];

	FILE_READER fin;
	DATA_READER in;
	
	fin = [[FileReader new] initWithFileName:"destinos.dat"];
	in =  [[DataReader new] initWithReader: fin];
	
//	doLog(0,"Destination\n");
	//doLog(0,"-----------------------------------------------------\n");
	
	[in seek:29 from: SEEK_SET];
	
	callType = [in readChar];
	[in readBCD:phone qty:(int)16];
	[in read:name qty:20];
	
//	doLog(0,"%d %-16s %-20s\n", callType, phone, name);

	callType = [in readChar];
	[in readBCD:phone qty:(int)16];
	[in read:name qty:20];

//	doLog(0,"%d %-16s %-20s\n", callType, phone, name);

	callType = [in readChar];
	[in readBCD:phone qty:(int)16];
	[in read:name qty:20];

//	doLog(0,"%d %-16s %-20s\n", callType, phone, name);
				
	return 0;
}
