/* ========================================================================== */
/*                                                                            */
/*   Filename.c                                                               */
/*   (c) 2001 Author                                                          */
/*                                                                            */
/*   Description                                                              */
/*                                                                            */
/* ========================================================================== */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "logComm.h"
#include "log.h"
#include "system/util/all.h"
#include "system/dev/all.h"
#include "Configuration.h"

static int 	osHandle;
static unsigned char writeBuf[570];
static unsigned char readBuf[270];
unsigned short framesQty;
static int useSocketCommunication = 0;
static int lastlen;
static unsigned char lastdev;

/**/
int read_data_from_socket(OS_HANDLE handle, unsigned char *bufPtr, int qty, int timeout)
{
	int n = 0, res, error;
	
	sock_set_read_timeout(handle, (timeout / 1000) + 5);
	do {
		error = 0;
		res = sock_read(handle, &bufPtr[n], qty);
		if (res < 0) {
			error = errno;
			//************************* logcoment
            //doLog(0,"Error en lectura de socket, errno=%d, %s, %d\n", error, strerror(error), EINTR);
		} else n += res;
	} while (error == EINTR);

	return n;
}

/*
	Calcula la suma de los campos [2] a n y le aplica el complemento a dos
*/
unsigned char calcChksumC2( unsigned char *data, int n )
{
  unsigned short i;
  unsigned short sum;
  
  sum = 0;
  // no sumo el inicio de trama:
  for  ( i = 1; i < n; ++ i){
    sum += data[i];
  }
  //complemento a dos :
  return ( 256 - sum);
}

/**/
static void socketReconnect(void)
{
	int port;
	char host[255];

	strcpy(host, [[Configuration getDefaultInstance] getParamAsString: "CIM_SOCKET_HOST" default: "127.0.0.1"]);
	port = [[Configuration getDefaultInstance] getParamAsInteger: "CIM_SOCKET_PORT" default: 9999];

//************************* logcoment
    //doLog(0,"Conectando a %s:%d...\n", host, port);	
	osHandle = sock_socket();
	while (sock_connect(osHandle, port, host) == -1) {
	//************************* logcoment
        //doLog(0,"No se puede conectar al %s:%d, reintentando...\n", host, port);
		msleep(1000);
	}

	sock_set_read_timeout(osHandle, 10);

}

/*
	Abre el puerto pasado por parametro, inicializando la comunicacion con la placa.
	Retorna 1 si la apertura de puerto fue exitosa y 0 en caso contrario
*/
char safeBoxCommOpen( char portNumber )
{
	ComPortConfig config;
    int tries = 0;
    
	openConfigFile();
	
	if (strcmp([[Configuration getDefaultInstance] getParamAsString: "USE_CIM_SOCKET" default: "no"], "yes") == 0) {
		useSocketCommunication = 1;

	}

	if (useSocketCommunication) {

		socketReconnect();

	} else {
			config.baudRate = BR_38400;
			config.readTimeout = 1000;
			config.writeTimeout = 1000;
			config.parity = CT_PARITY_NONE;
			config.dataBits = 8;
			config.stopBits = 1;
		    osHandle = com_open(portNumber, &config);
            printf("ComPort CIM osHandle Result %d!!! \n", osHandle);
            while (( osHandle == -1 ) && (tries < 3)){
               printf("ComPort CIM not ready YET! Retrying!!! \n");
               msleep(1000);
               tries++;
                osHandle = com_open(portNumber, &config);
            }
    }

  	if ( osHandle != -1 ) 
  	   return 1;

    return 0;
}

/*
	Cierre del puerto
*/
void safeBoxCommClose( void )
{
	if (useSocketCommunication) {
		sock_shutdown(osHandle,2);
		sock_close(osHandle);	
} else {
  	com_close( osHandle );
	}
}


/*
	Realiza el entramado de los datos pasados por parametro y envia los datos por el puerto
	que se haya inicializado..
*/
void safeBoxCommWrite( unsigned char dev, unsigned char cmd, unsigned char * data, int dataLen )
{
    writeBuf[0] = 0xF8;
    writeBuf[1] = dev;
    writeBuf[2] = cmd;

	//longitud de 2 bytes
    *((unsigned short *)&writeBuf[3]) = SHORT_TO_B_ENDIAN( dataLen );
    memcpy(&writeBuf[5], data, dataLen);
    writeBuf[5 + dataLen] = calcChksumC2( writeBuf, dataLen + 5 );
		if (useSocketCommunication) {
			if (sock_write(osHandle, writeBuf, dataLen + 6 ) == -1) {
//************************* logcoment
                //doLog(0,"safeBoxComm -> error al escribir\n");
				socketReconnect();
			}

		} else {
    	com_write( osHandle, writeBuf, dataLen + 6 );
		}

	//para loguear lo agrego:
	lastdev = dev;
	lastlen = dataLen + 6;
	//logFrame( dev, writeBuf, dataLen + 6, 1 );
	/*
	//longitud 1 byte
    writeBuf[3] = dataLen;
    memcpy(&writeBuf[4], data, dataLen);
    writeBuf[4 + dataLen] = calcChksumC2( writeBuf, dataLen + 4 );
    com_write( osHandle, writeBuf, dataLen + 5 );
    logFrame( dev, writeBuf, dataLen + 5, 1 );
    */
}

/*
	Intenta leer una trama valida, verificando su checksum.
	En caso de encontrarla retorna un puntero a los datos leidos a partir de la posicion
	[1], descarta la marca de inicio de trama.
	En caso contrario ( datos leidos == 0, inicio de trama no encontrado, checksum invalido )retorna NULL. 
*/
unsigned char * safeBoxCommRead( int timeout )
{
    int qty, len;
    unsigned char *bufPtr = readBuf;
    unsigned char chkVal;

	if (useSocketCommunication) {
		qty = read_data_from_socket(osHandle, bufPtr, 6, timeout);
	} else {
   		qty = com_read( osHandle, bufPtr, 6,  timeout );
	}

    if ( qty == 6 ){
    	while ( *bufPtr != 0xF8 && bufPtr < &readBuf[6] )
    		++bufPtr;
    	if ( bufPtr < &readBuf[6] ) {
    		if ( bufPtr != readBuf ){
					if (useSocketCommunication) {
						qty += read_data_from_socket(osHandle, &readBuf[6], bufPtr-readBuf, 2000);
					} else {
		    		    qty += com_read(osHandle, &readBuf[6], bufPtr-readBuf,  200 );
					}
   	    	} 
	     
			len = SHORT_TO_B_ENDIAN(*((unsigned short*) &bufPtr[3]));
			if (useSocketCommunication) {
				qty += read_data_from_socket(osHandle, &bufPtr[6], len, 5000);
			} else {	   
				qty += com_read(osHandle, &bufPtr[6], len,  200 );
			}//************************* logcoment
			/*      
			if ( qty < len ){
					doLog(0,"qty < len %d %d \n", qty, len);fflush(stdout);
			}
	*/
			chkVal = calcChksumC2( bufPtr, len + 5 );
			if ( chkVal == bufPtr[len + 5 ]){
				if (( getLogType() == FULL_LOG ) || ( getLogType() == FULL_LOG_SCREEN )) {
					logFrame( lastdev, writeBuf, lastlen, 1 );
					logFrame( bufPtr[1], readBuf, qty, 0 );
				}
				return &bufPtr[1];                        
			} else {
				logFrame( lastdev, writeBuf, lastlen, 1 );
				logFrame( 253, readBuf, qty, 0 );
					//doLog(0,"checksum wrong %d %d \n", chkVal, bufPtr[len + 5 ]);fflush(stdout);
			}
		} else {
				logFrame( lastdev, writeBuf, lastlen, 1 );
				logFrame( 254, readBuf, qty, 0 );
				//doLog(0,"i > qty \n");fflush(stdout);
			}
    } else {
        logFrame( lastdev, writeBuf, lastlen, 1 );
        logFrame( 255, bufPtr, qty, 0 );
		//doLog(0,"qty es CERO %d\n", qty);fflush(stdout);
	}

	msleep(10);
	if (useSocketCommunication) {
	} else {
		com_flush( osHandle );
	}
    return NULL;
}

#if 0
int TEST_SAFE_BOX_COM( char portNumber )
{
  static unsigned char data[255];
  unsigned char *dataRta;
  
  doLog(0,"TEST SAFE BOX COM:");fflush(stdout);
  data[0] = 0xFC;
  data[1] =  5;
  data[2] = 0x11;
  data[3] = 0x27;
  data[4] = 0x56;
  
  if ( safeBoxCommOpen( portNumber )) {
    safeBoxCommWrite( 1, 0, data, 5 );
    while (( dataRta = safeBoxCommRead())!= NULL )  {
      sleep(1000);
      safeBoxCommWrite( 1, 0, data, 5 );
    }
    doLog(0,"  OKK ");fflush(stdout);
  } else
    doLog(0,"  error ");fflush(stdout);

  return 1;
}
#endif
