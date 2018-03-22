 /* ========================================================================== */
/*                                                                            */
/*   jcmBillAcceptorComm.c                                                               */
/*   (c) 2001 Author                                                          */
/*                                                                            */
/*   Description                                                              */
/*                                                                            */
/* ========================================================================== */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "system/os/comportapi.h"
#include "system/os/osdef.h"
#include "system/util/endian.h"
#include "jcmBillAcceptorComm.h"
#include "safeBoxComm.h"
#include "logComm.h"

unsigned char sendBuf[570];

unsigned short calcCrc( unsigned short baseCrc, char * data, unsigned short n )
{
  unsigned short i, q, c;
  
  for ( i = 0; i < n; i++ ){
    c = data[i] & 0xFF;
    q = ( baseCrc ^ c ) & 0x0F;    
    baseCrc = ( baseCrc >> 4 )^( q * 0x1081 );
    q = ( baseCrc^( c >> 4 )) & 0x0F;
    baseCrc = ( baseCrc >> 4 )^( q*0x1081 );
  }
  return baseCrc;
}

/*
	Calcula la suma de los campos [2] a n y le aplica el complemento a dos
*/
unsigned char calcChksumXor( unsigned char *data, int n, int index )
{
  int i;
  unsigned char sum;
  
  sum = data[index];
  //LOG_INFO( LOG_DEVICES,"XOR n: %d index: %d data[i]: %d", n, index, sum );
  		
  for  ( i = index + 1; i <= n; ++ i){
    sum ^= data[i];
	//LOG_INFO( LOG_DEVICES,"XOR step data[i]: %d sum: %d", data[i], sum );
  }
  return sum;

}

void convertTo7Bit( unsigned char *data, int len )
{
  int i;
	
  for  ( i = 0; i <= len; ++i){
    data[i] = (data[i] & 0x7F);
  }

}

unsigned char lastDevice;
int lastLenDevice;
void jcmWrite( unsigned char dev, char protocol, unsigned char cmd, unsigned char * data, int dataLen )
{
    int baseLen = 0, baseOffset = 0;
	
	if (protocol <= 2 ){
		switch ( protocol ) {
			case 0:
				baseLen = 5;
				baseOffset = 3;
				sendBuf[0] = 0xFC;
				sendBuf[1] = 5 + dataLen;
				break;
			case 1:
				baseLen = 6;
				baseOffset = 4;
				sendBuf[0] = 0x02;
				sendBuf[1] = 0x03;
				if ( dataLen > 255 )
	    			sendBuf[2] = 0;
				else
					sendBuf[2] = 6 + dataLen;
				break;
		}
	
		sendBuf[baseOffset - 1] = cmd;
		memcpy(&sendBuf[baseOffset], data, dataLen);
		*((unsigned short*) &sendBuf[baseOffset + dataLen]) = SHORT_TO_L_ENDIAN(calcCrc(0,sendBuf, dataLen+baseOffset));
		safeBoxCommWrite( dev, 0, sendBuf, dataLen + baseLen );
		lastDevice = dev;
		lastLenDevice = dataLen + baseLen;

	} else {
		//esto es mei! 
		sendBuf[0] = 0x02;
		sendBuf[1] = 5 + dataLen;

	    sendBuf[2] = cmd;  //el valor ack calculado se realiza por fuera
    	memcpy(&sendBuf[3], data, dataLen);
    	sendBuf[3 + dataLen] = 0x03;
	
	    sendBuf[4 + dataLen] = calcChksumXor( sendBuf, dataLen + 2, 1 );
		safeBoxCommWrite( dev, 0, sendBuf, dataLen + 5 );
		lastDevice = dev;
		lastLenDevice = dataLen + 5;
	//	msleep(10);
	}

}

unsigned char *jcmRead( unsigned char *dev, char protocol, int *cmdDataLen )
{
    int len;
    unsigned short crcval;
    unsigned char *readFrame;
    unsigned char *rawData;
    
    //readFrame = safeBoxCommRead(500);		
    readFrame = safeBoxCommRead(1000);		
	if ( readFrame != NULL ){
	    rawData = &readFrame[4];
	    switch ( protocol ) {
		case 0:
			if ( *rawData == 0xFC ){
				*dev = readFrame[0];
				len = rawData[1];
				crcval = calcCrc( 0,rawData, len - 2);
				if ( crcval == SHORT_TO_L_ENDIAN(*((unsigned short*) &rawData[len - 2]))){
					*cmdDataLen = len - 5;
				//	logFrame( lastDevice, sendBuf, lastLenDevice, 1 );
				//	logFrame( lastDevice, rawData, len, 0 );
				return &rawData[2];                        
				} else {
					logFrame( lastDevice, sendBuf, lastLenDevice, 1 );
					logFrame( 253, rawData, len, 0 );
					return NULL;
				}
			} else{
				logFrame( lastDevice, sendBuf, lastLenDevice, 1 );
				logFrame( 254, rawData, 1, 0 );
			}
			return NULL;
		
		case 1:
			if ( *rawData == 0x02 ){
				*dev = readFrame[0];
				len = rawData[2];
				crcval = calcCrc( 0, rawData, len - 2);
				if ( crcval == SHORT_TO_L_ENDIAN(*((unsigned short*) &rawData[len - 2]))){
					*cmdDataLen = len - 6;
					//logFrame( lastDevice, sendBuf, lastLenDevice, 1 );
					//logFrame( lastDevice, rawData, len, 0 );
					return &rawData[3];                        
				} else {
					//doLog(" Error crc \n"); fflush(stdout);
					logFrame( lastDevice, sendBuf, lastLenDevice, 1 );
					logFrame( 253, rawData, len, 0 );
				}
			} else{
				logFrame( lastDevice, sendBuf, lastLenDevice, 1 );
				logFrame( 254, rawData, 1, 0 );
			}
			return NULL;
		case 4:
			if ( ( *rawData & 0x7F ) == 0x02 ){
				*dev = readFrame[0];
				len = ( rawData[1] & 0x7F );
				convertTo7Bit(rawData, len);
				if ( calcChksumXor( rawData, len - 3, 1 ) == rawData[len - 1] ){
					//para debugging version, sacar despues!
					if ( getLogType() == VALS_LOG ) {
						logFrame( lastDevice, sendBuf, lastLenDevice, 1 );
						logFrame( lastDevice, rawData, len, 0 );
					}
					*cmdDataLen = len - 5;
					return &rawData[2];                        
				} else {
					logFrame( lastDevice, sendBuf, lastLenDevice, 1 );
					logFrame( 253, rawData, len, 0 );
					//LOG_INFO( LOG_DEVICES,"mei read - check wrong!"); 
				}
			} else  {              
				logFrame( lastDevice, sendBuf, lastLenDevice, 1 );
				logFrame( 254, rawData, 1, 0 );
			}
			return NULL;
		}
	} 
	//read frame == NULL no leyo nada!
	logFrame( lastDevice, sendBuf, lastLenDevice, 1 );
	logFrame( 255, sendBuf, 0, 0 );
	return NULL;
}

char jcmInitComm( char portNumber, char protocol )
{
	return 0;
}


