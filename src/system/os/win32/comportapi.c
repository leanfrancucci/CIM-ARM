#include <windows.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "comportapi.h"
#include "OSExcepts.h"
#include "log.h"

#define printd(args...)

/**/
static int BaudRateMap[] = 
{
	0, 50, 75, 110,	134, 150, 200, 300, 600, 1200, 1800, 2400, 4800, 9600, 19200, 38400, 57600, 115200, 230400 
};

/**/
static char ParityMap[] = { 'N', 'O', 'E' };


/**/
OS_HANDLE com_open(int portNumber, ComPortConfig *config)
{
   DCB dcbCommPort;
   COMMTIMEOUTS ctmoNew = {0}, ctmoOld;
 	 char name[30];
	 char config_str[30];
	 HANDLE myHandle;

	 sprintf(name, "\\\\.\\COM%d", portNumber);

   myHandle = CreateFile(name,
                         GENERIC_READ | GENERIC_WRITE,
                          0, 0, 
													OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_WRITE_THROUGH | FILE_FLAG_NO_BUFFERING, 0);

	 if (!myHandle || myHandle == INVALID_HANDLE_VALUE) THROW_MSG(CANNOT_OPEN_DEVICE_EX, name);
													
   GetCommTimeouts(myHandle, &ctmoOld);
   ctmoNew.ReadIntervalTimeout = 0;
   ctmoNew.ReadTotalTimeoutConstant = config->readTimeout;
   ctmoNew.ReadTotalTimeoutMultiplier = 1;
   ctmoNew.WriteTotalTimeoutMultiplier = 1;
   ctmoNew.WriteTotalTimeoutConstant = config->writeTimeout;
   SetCommTimeouts(myHandle, &ctmoNew);

   dcbCommPort.DCBlength = sizeof(DCB);
   GetCommState(myHandle, &dcbCommPort);//
	 memset(&dcbCommPort, sizeof(dcbCommPort), 0 );
   sprintf(config_str, "%d,%c,%d,%d", BaudRateMap[config->baudRate], ParityMap[config->parity], config->dataBits, config->stopBits);
	 printd("COM PORT CONFIG: %s\n", config_str);
	 BuildCommDCB(config_str, &dcbCommPort);
	 dcbCommPort.fBinary = 1;		//binary mode
	 dcbCommPort.fDtrControl = DTR_CONTROL_ENABLE;		// Enable DTR monitoring
	 SetCommState(myHandle, &dcbCommPort);
	 SetupComm(myHandle, 2048, 128);
	 com_flush(myHandle);

	 return myHandle;
}

/**/
int com_read(OS_HANDLE handle, char *buffer, int qty, int timeout)
{
/*	unsigned long nReaded;
	ReadFile( handle, buffer, qty, &nReaded, NULL);
  //doLog(0,"leyo %d bytes\n", nReaded);
  return(nReaded);
*/
	unsigned long ticks = getTicks();
	int nReaded = 0;
	unsigned long result;
	
	while ( getTicks() - ticks <= timeout ) {
    ReadFile( handle, &buffer[nReaded], qty-nReaded, &result, NULL);
  //result = read(handle, &buffer[nReaded], qty - nReaded);
		if (result == -1) {
		//	doLog(0,"Error reading com port\n");
			return 0;
		}
		nReaded += result;
		if (nReaded >= qty) return nReaded;
		msleep(1);
	}

	return nReaded;

}


/**/
int com_write(OS_HANDLE handle, char *buffer, int qty)
{
	unsigned long nWritten;
	WriteFile(handle, buffer, qty, &nWritten, NULL);
  //doLog(0,"escribio %d bytes\n", nWritten);
	return nWritten;
}


/**/
void com_close(OS_HANDLE handle)
{
	CloseHandle(handle);
}


/**/
void com_flush(OS_HANDLE handle)
{
	PurgeComm( handle,  PURGE_TXABORT | PURGE_TXCLEAR | PURGE_RXABORT | PURGE_RXCLEAR);
}

