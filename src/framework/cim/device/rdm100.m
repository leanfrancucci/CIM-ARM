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
#include "rdm100.h"
#include "system/util/all.h"
#include "system/dev/all.h"
#include "Configuration.h"

static unsigned char writeBuf[570];
static unsigned char readBuf[570];
static unsigned char readCtrlSignalsBuff[4];
//static int lastlen;
//static unsigned char lastdev;


/*
	Abre el puerto pasado por parametro, inicializando la comunicacion con la placa.
	Retorna 1 si la apertura de puerto fue exitosa y 0 en caso contrario
*/
int rdmCommOpen( char portNumber )
{
	ComPortConfig config;
	
    config.baudRate = BR_38400;
    config.readTimeout = 1000;
    config.writeTimeout = 1000;
    config.parity = CT_PARITY_EVEN;
    config.dataBits = 8;
    config.stopBits = 1;
    strcpy(config.ttyStr, [[Configuration getDefaultInstance] getParamAsString: "TTY_VALIDATORS" default: "/dev/ttyUSB"]);
    return com_open(portNumber, &config);

}

/*
	Cierre del puerto
*/
void rdmCommClose( int aHandle )
{
  	com_close( aHandle );
}


// CRC16CCITT  x^16+x^12+x^5+1
static unsigned char m_Crc1Tbl[256] =
{
	0x00, 0x89, 0x12, 0x9b, 0x24, 0xad, 0x36, 0xbf,
	0x48, 0xc1, 0x5a, 0xd3, 0x6c, 0xe5, 0x7e, 0xf7,
	0x81, 0x08, 0x93, 0x1a, 0xa5, 0x2c, 0xb7, 0x3e,
	0xc9, 0x40, 0xdb, 0x52, 0xed, 0x64, 0xff, 0x76,
	0x02, 0x8b, 0x10, 0x99, 0x26, 0xaf, 0x34, 0xbd,
	0x4a, 0xc3, 0x58, 0xd1, 0x6e, 0xe7, 0x7c, 0xf5,
	0x83, 0x0a, 0x91, 0x18, 0xa7, 0x2e, 0xb5, 0x3c,
	0xcb, 0x42, 0xd9, 0x50, 0xef, 0x66, 0xfd, 0x74,
	0x04, 0x8d, 0x16, 0x9f, 0x20, 0xa9, 0x32, 0xbb,
	0x4c, 0xc5, 0x5e, 0xd7, 0x68, 0xe1, 0x7a, 0xf3,
	0x85, 0x0c, 0x97, 0x1e, 0xa1, 0x28, 0xb3, 0x3a,
	0xcd, 0x44, 0xdf, 0x56, 0xe9, 0x60, 0xfb, 0x72,
	0x06, 0x8f, 0x14, 0x9d, 0x22, 0xab, 0x30, 0xb9,
	0x4e, 0xc7, 0x5c, 0xd5, 0x6a, 0xe3, 0x78, 0xf1,
	0x87, 0x0e, 0x95, 0x1c, 0xa3, 0x2a, 0xb1, 0x38,
	0xcf, 0x46, 0xdd, 0x54, 0xeb, 0x62, 0xf9, 0x70,
	0x08, 0x81, 0x1a, 0x93, 0x2c, 0xa5, 0x3e, 0xb7,
	0x40, 0xc9, 0x52, 0xdb, 0x64, 0xed, 0x76, 0xff,
	0x89, 0x00, 0x9b, 0x12, 0xad, 0x24, 0xbf, 0x36,
	0xc1, 0x48, 0xd3, 0x5a, 0xe5, 0x6c, 0xf7, 0x7e,
	0x0a, 0x83, 0x18, 0x91, 0x2e, 0xa7, 0x3c, 0xb5,
	0x42, 0xcb, 0x50, 0xd9, 0x66, 0xef, 0x74, 0xfd,
	0x8b, 0x02, 0x99, 0x10, 0xaf, 0x26, 0xbd, 0x34,
	0xc3, 0x4a, 0xd1, 0x58, 0xe7, 0x6e, 0xf5, 0x7c,
	0x0c, 0x85, 0x1e, 0x97, 0x28, 0xa1, 0x3a, 0xb3,
	0x44, 0xcd, 0x56, 0xdf, 0x60, 0xe9, 0x72, 0xfb,
	0x8d, 0x04, 0x9f, 0x16, 0xa9, 0x20, 0xbb, 0x32,
	0xc5, 0x4c, 0xd7, 0x5e, 0xe1, 0x68, 0xf3, 0x7a,
	0x0e, 0x87, 0x1c, 0x95, 0x2a, 0xa3, 0x38, 0xb1,
	0x46, 0xcf, 0x54, 0xdd, 0x62, 0xeb, 0x70, 0xf9,
	0x8f, 0x06, 0x9d, 0x14, 0xab, 0x22, 0xb9, 0x30,
	0xc7, 0x4e, 0xd5, 0x5c, 0xe3, 0x6a, 0xf1, 0x78
};

static unsigned char m_Crc2Tbl[256] =
{
	0x00, 0x11, 0x23, 0x32, 0x46, 0x57, 0x65, 0x74,
	0x8c, 0x9d, 0xaf, 0xbe, 0xca, 0xdb, 0xe9, 0xf8,
	0x10, 0x01, 0x33, 0x22, 0x56, 0x47, 0x75, 0x64,
	0x9c, 0x8d, 0xbf, 0xae, 0xda, 0xcb, 0xf9, 0xe8,
	0x21, 0x30, 0x02, 0x13, 0x67, 0x76, 0x44, 0x55,
	0xad, 0xbc, 0x8e, 0x9f, 0xeb, 0xfa, 0xc8, 0xd9,
	0x31, 0x20, 0x12, 0x03, 0x77, 0x66, 0x54, 0x45,
	0xbd, 0xac, 0x9e, 0x8f, 0xfb, 0xea, 0xd8, 0xc9,
	0x42, 0x53, 0x61, 0x70, 0x04, 0x15, 0x27, 0x36,
	0xce, 0xdf, 0xed, 0xfc, 0x88, 0x99, 0xab, 0xba,
	0x52, 0x43, 0x71, 0x60, 0x14, 0x05, 0x37, 0x26,
	0xde, 0xcf, 0xfd, 0xec, 0x98, 0x89, 0xbb, 0xaa,
	0x63, 0x72, 0x40, 0x51, 0x25, 0x34, 0x06, 0x17,
	0xef, 0xfe, 0xcc, 0xdd, 0xa9, 0xb8, 0x8a, 0x9b,
	0x73, 0x62, 0x50, 0x41, 0x35, 0x24, 0x16, 0x07,
	0xff, 0xee, 0xdc, 0xcd, 0xb9, 0xa8, 0x9a, 0x8b,
	0x84, 0x95, 0xa7, 0xb6, 0xc2, 0xd3, 0xe1, 0xf0,
	0x08, 0x19, 0x2b, 0x3a, 0x4e, 0x5f, 0x6d, 0x7c,
	0x94, 0x85, 0xb7, 0xa6, 0xd2, 0xc3, 0xf1, 0xe0,
	0x18, 0x09, 0x3b, 0x2a, 0x5e, 0x4f, 0x7d, 0x6c,
	0xa5, 0xb4, 0x86, 0x97, 0xe3, 0xf2, 0xc0, 0xd1,
	0x29, 0x38, 0x0a, 0x1b, 0x6f, 0x7e, 0x4c, 0x5d,
	0xb5, 0xa4, 0x96, 0x87, 0xf3, 0xe2, 0xd0, 0xc1,
	0x39, 0x28, 0x1a, 0x0b, 0x7f, 0x6e, 0x5c, 0x4d,
	0xc6, 0xd7, 0xe5, 0xf4, 0x80, 0x91, 0xa3, 0xb2,
	0x4a, 0x5b, 0x69, 0x78, 0x0c, 0x1d, 0x2f, 0x3e,
	0xd6, 0xc7, 0xf5, 0xe4, 0x90, 0x81, 0xb3, 0xa2,
	0x5a, 0x4b, 0x79, 0x68, 0x1c, 0x0d, 0x3f, 0x2e,
	0xe7, 0xf6, 0xc4, 0xd5, 0xa1, 0xb0, 0x82, 0x93,
	0x6b, 0x7a, 0x48, 0x59, 0x2d, 0x3c, 0x0e, 0x1f,
	0xf7, 0xe6, 0xd4, 0xc5, 0xb1, 0xa0, 0x92, 0x83,
	0x7b, 0x6a, 0x58, 0x49, 0x3d, 0x2c, 0x1e, 0x0f
};

/*
unsigned short makeCRC(unsigned char* pbuf, int len)
{
	unsigned short m_Crc16work = 0; 
    int ii;
    unsigned char work, temp;

	for( ii=0; ii < len; ii++)
	{
        temp = pbuf[ii];   
        work =  temp ^ ((m_Crc16work) >> 8);
        m_Crc16work = ((m_Crc16work^m_Crc1Tbl[work]) << 8) | m_Crc2Tbl[work];        
	}

	return m_Crc16work;
}
*/

unsigned short makeCRC(unsigned char* pbuf, int len)
{
    unsigned short m_Crc16work = 0; 
    int ii;
    unsigned char work, temp;

	for( ii=0; ii < len; ii++)
	{
		//ignoro un 0x10 de escape
		if ((pbuf[ii] == 0x10) && (pbuf[ii+1] == 0x10))
			ii++;
        	temp = pbuf[ii];   
        	work =  temp ^ ((m_Crc16work) >> 8);
        	m_Crc16work = ((m_Crc16work^m_Crc1Tbl[work]) << 8) | m_Crc2Tbl[work];        
	}

	return m_Crc16work;
}


/*
 * 
 * 
void rdmWriteFrame(unsigned char *data, int dataLen)
{
        unsigned short crcval;
        
        memcpy(writeBuf, sntFrameEnc, 4);
        memcpy(&writeBuf[4], data, dataLen);
        writeBuf[dataLen + 4]= 0x03;
        crcval = makeCRC( writeBuf+2, dataLen + 3);
        memcpy(&writeBuf[dataLen + 4], etxCmd, 2);
       *((unsigned short*) &writeBuf[dataLen + 6]) = SHORT_TO_L_ENDIAN(crcval);
        
        com_write( osHandleR, writeBuf, dataLen + 8 );

        logFrame( 0, writeBuf, dataLen + 8, 1 );        

}

*/

void rdmWriteFrame(int aHandle, unsigned char hardwareId, unsigned char *data, int dataLen)
{
        int i, j, len;
        unsigned short crcval;
        
        memcpy(writeBuf, sntFrameEnc, 4);
        len = dataLen;
        for ( i = 4, j = 0; j < len; i++, j++){ 
            writeBuf[i] = data[j];
            if ( data[j] == 0x10 ){
                    i++;
                    writeBuf[i] = 0x10;
                    dataLen++;
            }
        }    
        writeBuf[dataLen + 4]= 0x03;
        crcval = makeCRC( writeBuf+2, dataLen + 3);
        memcpy(&writeBuf[dataLen + 4], etxCmd, 2);
       *((unsigned short*) &writeBuf[dataLen + 6]) = SHORT_TO_L_ENDIAN(crcval);
        
        com_write( aHandle, writeBuf, dataLen + 8 );

        logFrame( hardwareId, writeBuf, dataLen + 8, 1 );        

}

/*
	Realiza el entramado de los datos pasados por parametro y envia los datos por el puerto
	que se haya inicializado..
*/
void rdmWriteCtrlSignal( int aHandle, unsigned char hardwareId, unsigned char * data, int dataLen )
{
    memcpy(writeBuf, data, dataLen);
   	com_write( aHandle, writeBuf, dataLen );

	logFrame( hardwareId, writeBuf, dataLen, 1 );
}

unsigned char * rdmReadCtrlSignal( int aHandle, unsigned char hardwareId, int timeout )
{
    int qty, len;
    unsigned char *bufPtr = readCtrlSignalsBuff;

	qty = com_read( aHandle, bufPtr, 2,  300 );
//	doLog(0,"RDM QTY READ %d\n", qty); fflush(stdout);
	logFrame( hardwareId, readCtrlSignalsBuff, qty, 0 );

    if ( qty >= 2 ){
        return bufPtr;
    }
    return NULL;
}

/*
	Intenta leer una trama valida, verificando su checksum.
	En caso de encontrarla retorna un puntero a los datos leidos a partir de la posicion
	[1], descarta la marca de inicio de trama.
	En caso contrario ( datos leidos == 0, inicio de trama no encontrado, checksum invalido )retorna NULL. 
*/
unsigned char * rdmReadFrame( int aHandle, unsigned char hardwareId, int timeout )
{
    int qty, len;
    unsigned char *bufPtr = readBuf;
    unsigned char *strFrame;
    unsigned char *bufPtrAux = readBuf;
    unsigned char *bufPtrRef;
    unsigned short crcval;
    unsigned short frameLen;

	qty = com_read( aHandle, bufPtr, 300,  300 );
//	printf("RDM QTY READ %d\n", qty); fflush(stdout);
	logFrame( hardwareId, readBuf, qty, 0 );

    	if ( qty >= 2 ){
           //si arranca con un eot, lo ignoro 
		if ( !memcmp(bufPtr, eotCmd, 2 )){
                bufPtr += 2;
                qty -= 2;
        	}
        
        
        //Calculo la longitud de la trama buscando el DLE ETX
        frameLen = 0;
        bufPtrAux = bufPtr;
        while (qty > 0 && !((*bufPtrAux == 0x10) && (*(bufPtrAux+1) == 0x03)) ){
            if ((*bufPtrAux == 0x10) && (*(bufPtrAux+1) == 0x10)){
                //sacar despues!!
                strFrame = getHexFrame(bufPtr, qty);
                printf("****************** logueando trama doble 0x10 %s\n", strFrame);
                ////////////
                bufPtrRef = bufPtrAux;
                while (!((*bufPtrRef == 0x10) && (*(bufPtrRef+1) == 0x03))) {
                    *bufPtrRef = *(bufPtrRef+1);
                    bufPtrRef++;
                }
                *bufPtrRef = *(bufPtrRef+1);
                bufPtrRef++;
                *bufPtrRef = *(bufPtrRef+1);
                bufPtrRef++;
                *bufPtrRef = *(bufPtrRef+1);
                bufPtrRef++;
                *bufPtrRef = *(bufPtrRef+1);
                bufPtrRef++;
		
                qty--;
                printf("ENCONTRE UNA TRAMA CON DOBLE 0X10, SUPRIMIENDO!\n");
            }
            qty--;
            bufPtrAux++;
            frameLen++;
        }        
        //encontro el DLE ETX:  
        if ( qty > 0 && frameLen > 8 ){
            if ( !memcmp(bufPtr, rcvdFrameEnc, 4 )){
                bufPtr[frameLen]= 0x03;
                crcval = makeCRC( bufPtr+2, frameLen - 1);
		if ( crcval == SHORT_TO_L_ENDIAN(*((unsigned short*) &bufPtr[frameLen + 2])))
                    return &bufPtr[4]; //returno a partir de blockNo
		else{
	   	   printf("crc mal %d %d\n", crcval, SHORT_TO_L_ENDIAN(*((unsigned short*) &bufPtr[frameLen + 2]))); 
		}
            }else{
		doLog(1,"bufptr != received frame \n"); fflush(stdout);
                logFrame( 12, bufPtr, frameLen, 1 );
                logFrame( 13, rcvdFrameEnc, 4, 1 );
            }
        } else
		doLog(1,"no encotnro el dle etx \n"); fflush(stdout);
        
    }
    
	msleep(10);
	com_flush( aHandle );

    return NULL;
}



int rdmInit( char portNumber )
{
    unsigned char * buf; 
    int aHandle;
    
    openConfigFile();
    printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>RDMINIT \n");
    if ((aHandle = rdmCommOpen( portNumber )) != -1 )
        printf("<<<<<<<<<<<>>>>>>>>>>>>><<<<<<<<<rdminit comm abuerti ok \n");
    else   
        printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Error al abrir el com solicitado xxxx\n");
    return aHandle;
}


