#include "ComPort.h"
#include "ComPortReader.h"
#include "ComPortWriter.h"
#include "Configuration.h"
#include "Modem.h"
#include "util.h"


@implementation ComPort 

/**/
- (void) loadPortConfig: (int) aComPort;

/**/
+ new
{
	return [[super new] initialize];
}

/**/
- initialize
{
	myBaudRate = BR_19200;
	myStopBits = 1;
	myPortNumber = 1;
	myReadTimeout = 150;
	myWriteTimeout = 100;
	myParity = CT_PARITY_NONE;
	myDataBits = 8;
	myHandle = -1;
	myReader = [[ComPortReader new] initWithComPort: self];				 
	myWriter = [[ComPortWriter new] initWithComPort: self];
	
	return self ;
}

/**/
- free 
{
	[myReader free];
	[myWriter free];
	return self;
}

/**/
- (int) getPortNumber
{
	return myPortNumber;
}

/**/
- (void) setBaudRate: (BaudRateType) aBaudRate
{
	myBaudRate = aBaudRate;
}

/**/
- (void) setDataBits: (int)aDataBits
{
	myDataBits = aDataBits;
}

/**/
- (void) setParity: (ParityType) aParity
{
	myParity = aParity;
}

/**/
- (void) setStopBits: (int)aStopBits
{
	myStopBits = aStopBits;
}

/**/
- (void) setPortNumber: (int) aPortNumber
{
	myPortNumber = aPortNumber;
}

/**/
- (void) setReadTimeout: (int)aTimeout
{
	myReadTimeout = aTimeout;
}

/**/
- (void) setWriteTimeout: (int)aTimeout
{
	myWriteTimeout = aTimeout;
}

/**/
- (void) open
{
	ComPortConfig config;
	char comPortName[50];
	
	[self loadPortConfig: myPortNumber];

	sprintf(comPortName, "COM PORT %d", myPortNumber);
	
	config.baudRate = myBaudRate;
	config.readTimeout = myReadTimeout;
	config.writeTimeout = myWriteTimeout;
	config.parity = myParity;
	config.dataBits = myDataBits;
	config.stopBits = myStopBits;

/*	doLog(0,"Datos del puerto al hacer el open: baudRate: %d  | stopBits: %d  | dataBits: %d  | parity: %d  | readTimeout: %d  | writeTimeout: %d \n",  myBaudRate, myStopBits,  myDataBits, myParity, myReadTimeout, myWriteTimeout);*/
	
	myHandle = com_open(myPortNumber, &config);
	
	if (myHandle == -1) THROW_MSG(CANNOT_OPEN_DEVICE_EX, comPortName);
	
}

/**/
- (void) close
{
	com_close(myHandle);
}

/**/
- (int)  read:(char *)aBuf qty: (int) aQty
{
	return com_read(myHandle, aBuf, aQty, myReadTimeout);
}

/**/
- (int)  write:(char *)aBuf qty: (int) aQty
{
	return com_write(myHandle, aBuf, aQty);
}

/**/
- (void) flush
{
	com_flush(myHandle);
}

/**/
- (WRITER) getWriter
{
	return myWriter;
};

/**/
- (READER) getReader
{
	return myReader;
};

/**/
- (OS_HANDLE) getHandle
{
	return myHandle;
}

/**/
- (void) loadPortConfig: (int) aComPort
{
	volatile CONFIGURATION portFile;
	char portFileName[30];
	volatile BOOL error = FALSE;
	volatile int bRate;
	volatile int sBits;
	volatile int dBits;
	volatile int par;
	volatile int rTimeout;
	volatile int wTimeout;

	//doLog(0,"Analiza si toma la configuracion de los puertos desde archivos externos\n");

	sprintf(portFileName, "ttyS%dConfig.ini", aComPort - 1);

	TRY

		portFile = [[Configuration new] initWithFileName: portFileName];

	CATCH

	//	doLog(0,"Archivo de configuracion del puerto %s no encontrado ...\n", portFileName);
		error = TRUE;

	END_TRY

	if (error) return;

	error = FALSE;

	TRY

		bRate = [portFile getParamAsInteger: "BaudRate"];
		sBits = [portFile getParamAsInteger: "StopBits"];
		dBits = [portFile getParamAsInteger: "DataBits"];
		par = [portFile getParamAsInteger: "Parity"];
		rTimeout = [portFile getParamAsInteger: "ReadTimeout"];
		wTimeout = [portFile getParamAsInteger: "WriteTimeout"];

	/*	doLog(0,"Datos del puerto %s tomados del archivo: baudRate: %d  | stopBits: %d  | dataBits: %d  | parity: %d  | readTimeout: %d  | writeTimeout: %d \n", portFileName, bRate, sBits,  dBits, par, rTimeout, wTimeout);*/

	CATCH

	//	doLog(0,"Archivo de configuracion del puerto %s incompleto no se aplicaran los valores ...\n", portFileName);
		error = TRUE;
		ex_printfmt();

	END_TRY

	if (error) return;

	myBaudRate = bRate;
	myStopBits = sBits;
	myReadTimeout = rTimeout;
	myWriteTimeout = wTimeout;
	myParity = par;
	myDataBits = dBits;		

}

@end
