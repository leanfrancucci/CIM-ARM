#include "sysio.h"

int main(void)
{
	char callType;
	char phone2[50];
	char name[50];
		
	FILE_READER fin;
	DATA_READER in;
	
	fin = [[FileReader new] initWithFileName:"destinos.dat"];
	in =  [[DataReader new] initWithReader: fin];
	
	callType = [in readChar];
	[in readBCD: phone2 qty:16];
	[in read:name qty:20];
	
	//doLog(0,"Destination\n");
	//doLog(0,"-----------------------------------------------------\n");
	//doLog(0,"%d %s %s\n", callType, phone, name);
	
	return 0;
}
